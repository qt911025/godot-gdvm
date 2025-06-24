extends ObserverPack
const ObserverPack = preload("../base.gd")
const Options = preload("./options.gd")
const Template = preload("./template.gd")

const ObserverNode = preload("../../../core/observer/node.gd")
const ObserverPropertyArray = preload("../../../core/observer/property_array.gd")
const ObserverPropertyDictionary = preload("../../../core/observer/property_dictionary.gd")
const ObserverProperty = preload("../../../core/observer/property.gd")

const DataNodeStruct = preload("../../../core/data_node/struct.gd")
const DataNodeNode = preload('../../../core/data_node/node.gd')
const DataNodeList = preload("../../../core/data_node/list.gd")
const DataNodeDict = preload("../../../core/data_node/dict.gd")

var _source_base: Object
var _template: Template

## 树状的观察者包
## opts 参数格式： { base: Object, options: Variant }
func _init(opts: Variant) -> void:
	assert(opts is Dictionary)
	assert(opts.has("base"))
	assert(opts.has("options"))
	_source_base = opts["base"]
	var options := Options.build(opts["options"])
	_template = Template.new(options)

func compile(root: DataNode) -> Array[Observer]:
	var result: Array[Observer]
	_bind_data_node_tree(_source_base, _template, root, result)
	return result

## 递归构建观察者树
## 包含了观察者绑定和元素节点生成器的构造
static func _bind_data_node_tree(source_base: Object, template: Template, target_root_node: DataNode, observer_bucket: Array[Observer]) -> void:
	for data_node_path: NodePath in template.data:
		var target_data_node: DataNode
		if data_node_path.is_empty():
			target_data_node = target_root_node
		elif target_root_node is DataNodeStruct:
			target_data_node = target_root_node.get_indexed_property(data_node_path)
		assert(is_instance_valid(target_data_node), "Observer tree: Unable to find DataNode at path %s." % data_node_path)

		var leaf := template.data[data_node_path]
		match leaf.type:
			Options.Type.NODE:
				assert(source_base is Node, "Observer tree: Source base must be a Node for NODE type.")
				var current_node := source_base as Node
				if not leaf.path.is_empty():
					assert(current_node.has_node(leaf.path), "Observer tree: Node %s does not have child node at path %s." % [current_node.name, leaf.path])
					current_node = current_node.get_node(leaf.path)
				if target_data_node is DataNodeNode:
					target_data_node = (target_data_node as DataNodeNode).children()
				assert(target_data_node is DataNodeList, "Observer tree: Target data node for node type must be a DataNodeList.")
				var allocator := _generate_sub_observer_allocator(leaf.children)
				var observer := ObserverNode.new(current_node, target_data_node, allocator)
				observer_bucket.append(observer)
			Options.Type.PROPERTY_ARRAY:
				assert(leaf.path.get_subname_count() > 0, "Observer tree: property type path must have at least one subname. (%s)" % leaf.path)
				assert(target_data_node is DataNodeList, "Observer tree: Target data node for array type must be a DataNodeList.")
				var current_target := source_base
				if current_target is Node and leaf.path.get_name_count() > 0:
					var node_path := NodePath(leaf.path.get_concatenated_names())
					assert((current_target as Node).has_node(node_path))
					current_target = (current_target as Node).get_node(node_path)
				var property_path := NodePath(leaf.path.get_concatenated_subnames()).get_as_property_path()
				var changed_signal := leaf.changed.call(source_base, leaf.path)
				var allocator := _generate_sub_observer_allocator(leaf.children)
				var observer := ObserverPropertyArray.new(current_target, property_path, target_data_node, changed_signal, allocator)
				observer_bucket.append(observer)
			Options.Type.PROPERTY_DICTIONARY:
				assert(leaf.path.get_subname_count() > 0, "Observer tree: property type path must have at least one subname. (%s)" % leaf.path)
				assert(target_data_node is DataNodeDict, "Observer tree: Target data node for dictionary type must be a DataNodeDict.")
				var current_target := source_base
				if current_target is Node and leaf.path.get_name_count() > 0:
					var node_path := NodePath(leaf.path.get_concatenated_names())
					assert((current_target as Node).has_node(node_path))
					current_target = (current_target as Node).get_node(node_path)
				var property_path := NodePath(leaf.path.get_concatenated_subnames()).get_as_property_path()
				var changed_signal := leaf.changed.call(source_base, leaf.path)
				var allocator := _generate_sub_observer_allocator(leaf.children)
				var observer := ObserverPropertyDictionary.new(current_target, property_path, target_data_node, changed_signal, allocator)
				observer_bucket.append(observer)
			Options.Type.PROPERTY:
				assert(leaf.path.get_subname_count() > 0, "Observer tree: property type path must have at least one subname. (%s)" % leaf.path)
				var current_target := source_base
				if current_target is Node and leaf.path.get_name_count() > 0:
					var node_path := NodePath(leaf.path.get_concatenated_names())
					assert((current_target as Node).has_node(node_path))
					current_target = (current_target as Node).get_node(node_path)
				var property_path := NodePath(leaf.path.get_concatenated_subnames()).get_as_property_path()
				var changed_signal := leaf.changed.call(source_base, leaf.path)
				var observer := ObserverProperty.new(current_target, property_path, target_data_node, changed_signal)
				observer_bucket.append(observer)
			var unexpected_type:
				push_error("Unexpected observer tree type: %s" % unexpected_type)

## 生成子观察者
## Node PropertyArray PropertyDictionary通用
static func _generate_sub_observer_allocator(children_template: Template) -> Callable:
	return func(source_element: Object, target_element: DataNode) -> Array[Observer]:
		var result: Array[Observer]
		_bind_data_node_tree(source_element, children_template, target_element, result)
		return result

## 观察者树配置
static func opts(opts: Dictionary) -> Options:
	return Options.new(opts)

const PROPERTY = Options.Type.PROPERTY
const PROPERTY_ARRAY = Options.Type.PROPERTY_ARRAY
const PROPERTY_DICTIONARY = Options.Type.PROPERTY_DICTIONARY
const NODE = Options.Type.NODE