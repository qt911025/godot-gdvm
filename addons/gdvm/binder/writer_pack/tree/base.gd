extends WriterPack
const WriterPack = preload("../base.gd")

const Options = preload("./options.gd")
const Template = preload("./template.gd")

const Utils = preload('../../../utils.gd')

const DataNodeStruct = preload("../../../core/data_node/struct.gd")
const DataNodeNode = preload('../../../core/data_node/node.gd')
const DataNodeList = preload("../../../core/data_node/list.gd")
const DataNodeDict = preload("../../../core/data_node/dict.gd")

const Writer = preload('../../../core/writer/base.gd')
const WriterNode = preload('../../../core/writer/node.gd')
const WriterPropertyArray = preload('../../../core/writer/property_array.gd')
const WriterPropertyDictionary = preload('../../../core/writer/property_dictionary.gd')
const WriterProperty = preload('../../../core/writer/property.gd')

class SubWriter:
	var alloc: Callable = func(source_data_node: DataNode) -> Object: return null
	var drop: Callable = func(data: Object) -> bool: return false
	var children_template: Template

var _target_base: Object
var _template: Template

var _writers: Array[Writer]

## 树状写者包
## root: DataNode 绑定的根数据节点
## opts 参数 格式： { base: Object, options: Variant }
##   base: Object 目标基对象
##   options: Variant 写者选项
##   no_analyze: bool 禁用模板分析，将不会把关联节点的第一个子节点作为模板生成子写者
func _init(root: DataNode, opts: Variant) -> void:
	assert(opts is Dictionary)
	assert(opts.has("base") and opts["base"] is Object)
	assert(opts.has("options"))
	_source_root = root
	_target_base = opts["base"]
	var options := Options.build(opts["options"])
	_template = Template.new(options)
	if not opts.has("no_analyze") or not opts["no_analyze"]:
		_complement_sub_writer(_target_base, _template, _source_root)
	_bind_data_node_tree(_target_base, _template, _source_root, _writers)

## 递归地将子节点生成子写者（如果没有的话）（未来可能会删掉）
## 这个过程将删除作为模板的子节点，转换成子写者，并保存到template上，对target_base和template是有副作用的
static func _complement_sub_writer(target_base: Object, template: Template, source_root_node: DataNode) -> void:
	for data_node_path: NodePath in template.data:
		var leaf := template.data[data_node_path]
		if leaf.type == Options.Type.NODE:
			var source_data_node: DataNode
			if data_node_path.is_empty():
				source_data_node = source_root_node
			elif source_root_node is DataNodeStruct:
				source_data_node = source_root_node.get_indexed_property(data_node_path, true)
			assert(is_instance_valid(source_data_node), "Writer tree: Unable to find DataNode at path %s." % data_node_path)
			if source_data_node is DataNodeNode:
				source_data_node = (source_data_node as DataNodeNode).children()
			assert(source_data_node is DataNodeList, "Writer tree: Source data node for node type must be a DataNodeList.")
			
			assert(target_base is Node, "Writer tree: Target base must be a Node for NODE type.")
			var current_node := target_base as Node
			if not leaf.path.is_empty():
				assert(current_node.has_node(leaf.path), "Writer tree: Node %s does not have child node at path %s." % [current_node.name, leaf.path])
				current_node = current_node.get_node(leaf.path)
			var example_child_data_node := source_data_node._element_generator.call() as DataNode
			assert(is_instance_valid(example_child_data_node))
			
			# 构造子节点写者
			if leaf.sub_writer == null:
				# 无子写者，将唯一子节点作为模板创建子写者
				assert(current_node.get_child_count() == 1)
				var child_node := current_node.get_child(0)
				_complement_sub_writer(child_node, leaf.children, example_child_data_node)
				var child_scene := consume_and_pack_child_tree(current_node, child_node) # child_node已删
				leaf.sub_writer = Options.SubWriter.new()
				leaf.sub_writer.alloc = generate_node_alloc(child_scene)
				leaf.sub_writer.drop = default_node_drop
			else:
				# 有子写者，移除子节点
				var child_node = leaf.sub_writer.alloc.call(example_child_data_node)
				assert(child_node is Node)
				current_node.get_children().map(default_node_drop)
				current_node.add_child(child_node as Node)
				_complement_sub_writer(child_node, leaf.children, example_child_data_node)
				if not leaf.sub_writer.drop.call(child_node):
					default_node_drop(child_node)

## 递归构建DataNode树
## 包含了写者绑定和元素节点生成器的构造
static func _bind_data_node_tree(target_base: Object, template: Template, source_root_node: DataNode, writer_bucket: Array[Writer]) -> void:
	for data_node_path: NodePath in template.data:
		var source_data_node: DataNode
		if data_node_path.is_empty():
			source_data_node = source_root_node
		elif source_root_node is DataNodeStruct:
			source_data_node = source_root_node.get_indexed_property(data_node_path, true)
		assert(is_instance_valid(source_data_node), "Writer tree: Unable to find DataNode at path %s." % data_node_path)

		var leaf := template.data[data_node_path]
		match leaf.type:
			Options.Type.NODE:
				assert(target_base is Node, "Writer tree: Target base must be a Node for NODE type.")
				var current_node := target_base as Node
				if not leaf.path.is_empty():
					assert(current_node.has_node(leaf.path), "Writer tree: Node %s does not have child node at path %s." % [current_node.name, leaf.path])
					current_node = current_node.get_node(leaf.path)
				if source_data_node is DataNodeNode:
					source_data_node = (source_data_node as DataNodeNode).children()
				assert(source_data_node is DataNodeList, "Writer tree: Source data node for node type must be a DataNodeList.")
				var sub_writer := _generate_child_sub_writer(leaf.sub_writer.alloc, leaf.sub_writer.drop, leaf.children)
				var writer := WriterNode.new(current_node, source_data_node, sub_writer)
				writer_bucket.append(writer)
			Options.Type.PROPERTY_ARRAY:
				assert(leaf.path.get_subname_count() > 0, "Writer tree: property type path must have at least one subname. (%s)" % leaf.path)
				assert(source_data_node is DataNodeList, "Writer tree: Source data node for array type must be a DataNodeList.")
				var current_target := target_base
				if current_target is Node and leaf.path.get_name_count() > 0:
					var node_path := NodePath(leaf.path.get_concatenated_names())
					assert((current_target as Node).has_node(node_path))
					current_target = (current_target as Node).get_node(node_path)
				var property_path := NodePath(leaf.path.get_concatenated_subnames()).get_as_property_path()
				var sub_writer := _generate_array_element_sub_writer(leaf.sub_writer.alloc, leaf.sub_writer.drop, leaf.children)
				var writer := WriterPropertyArray.new(current_target, property_path, source_data_node, sub_writer)
				writer_bucket.append(writer)
			Options.Type.PROPERTY_DICTIONARY:
				assert(leaf.path.get_subname_count() > 0, "Writer tree: property type path must have at least one subname. (%s)" % leaf.path)
				assert(source_data_node is DataNodeDict, "Writer tree: Source data node for dictionary type must be a DataNodeDict.")
				var current_target := target_base
				if current_target is Node and leaf.path.get_name_count() > 0:
					var node_path := NodePath(leaf.path.get_concatenated_names())
					assert((current_target as Node).has_node(node_path))
					current_target = (current_target as Node).get_node(node_path)
				var property_path := NodePath(leaf.path.get_concatenated_subnames()).get_as_property_path()
				var sub_writer := _generate_dictionary_element_sub_writer(leaf.sub_writer.alloc, leaf.sub_writer.drop, leaf.children)
				var writer := WriterPropertyDictionary.new(current_target, property_path, source_data_node, sub_writer)
				writer_bucket.append(writer)
			Options.Type.PROPERTY:
				assert(leaf.path.get_subname_count() > 0, "Writer tree: property type path must have at least one subname. (%s)" % leaf.path)
				var current_target := target_base
				if current_target is Node and leaf.path.get_name_count() > 0:
					var node_path := NodePath(leaf.path.get_concatenated_names())
					assert((current_target as Node).has_node(node_path))
					current_target = (current_target as Node).get_node(node_path)
				var property_path := NodePath(leaf.path.get_concatenated_subnames()).get_as_property_path()
				var writer: Writer
				if source_data_node is DataNodeList:
					writer = WriterPropertyArray.new(current_target, property_path, source_data_node)
				elif source_data_node is DataNodeDict:
					writer = WriterPropertyDictionary.new(current_target, property_path, source_data_node)
				else:
					writer = WriterProperty.new(current_target, property_path, source_data_node)
				writer_bucket.append(writer)
			var unexpected_type:
				push_error("Unexpected writer tree type: %s" % unexpected_type)

## 生成元素子写者
## 用于所有对象的数组型目标
static func _generate_array_element_sub_writer(alloc: Callable, drop: Callable, children_template: Template) -> WriterPropertyArray.ElementSubWriter:
	return WriterPropertyArray.ElementSubWriter.new(
		alloc,
		func(source_data_node: DataNode, target_element: Object) -> Array[Writer]:
			var writers: Array[Writer]
			_bind_data_node_tree(target_element, children_template, source_data_node, writers)
			return writers
			,
		drop,
	)

## 生成字典元素子写者
## 用于所有对象的数组型目标
static func _generate_dictionary_element_sub_writer(alloc: Callable, drop: Callable, children_template: Template) -> WriterPropertyDictionary.ElementSubWriter:
	return WriterPropertyDictionary.ElementSubWriter.new(
		alloc,
		func(source_data_node: DataNode, target_element: Object) -> Array[Writer]:
			var writers: Array[Writer]
			_bind_data_node_tree(target_element, children_template, source_data_node, writers)
			return writers
			,
		drop,
	)

## 生成子节点子写者
## 用于节点
static func _generate_child_sub_writer(alloc: Callable, drop: Callable, children_template: Template) -> WriterNode.ChildSubWriter:
	return WriterNode.ChildSubWriter.new(
		alloc,
		func(source_data_node: DataNode, target_child: Node) -> Array[Writer]:
			var writers: Array[Writer]
			_bind_data_node_tree(target_child, children_template, source_data_node, writers)
			return writers
			,
		drop
	)

## 将一个节点的子树移除并打包
static func consume_and_pack_child_tree(parent_node: Node, child_node: Node) -> PackedScene:
	assert(child_node.get_parent() == parent_node)
	parent_node.remove_child(child_node)
	var result := Utils.pack_scene(child_node)
	child_node.queue_free()
	return result

## 创建一个简单的子节点生成器
static func generate_node_alloc(scene: PackedScene) -> Callable:
	return func(_source_data_node: DataNode) -> Object:
		return scene.instantiate()

## 通用节点销毁器
static func default_node_drop(data: Object) -> bool:
	assert(data is Node)
	var n := data as Node
	var p := n.get_parent()
	if p != null:
		p.remove_child(n)
	n.queue_free()
	return true

## 写者树配置
static func opts(opts: Dictionary) -> Options:
	return Options.new(opts)

const PROPERTY = Options.Type.PROPERTY
const PROPERTY_ARRAY = Options.Type.PROPERTY_ARRAY
const PROPERTY_DICTIONARY = Options.Type.PROPERTY_DICTIONARY
const NODE = Options.Type.NODE
