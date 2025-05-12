const Compiler = preload("./compiler.gd")
const ExtraPin = preload("./pin/extra.gd")

const PurePin = preload("./pin/pure.gd")

const Utils = preload('../utils.gd');

const DataNode = preload('../core/data_node/base.gd')
const DataNodeNode = preload('../core/data_node/node.gd')
const DataNodeList = preload("../core/data_node/list.gd")
const DataNodeStruct = preload("../core/data_node/struct.gd")

const Writer = preload('../core/writer/base.gd')
const WriterProperty = preload('../core/writer/property.gd')
const WriterPropertyArray = preload('../core/writer/property_array.gd')
const WriterNode = preload('../core/writer/node.gd')

var data: DataNode
var writers: Array[Writer]

func _init(base: Object, extra_pin: ExtraPin, data_node: DataNode) -> void:
	data = data_node
	_bind_data_node_tree(base, extra_pin, data, writers)

## 递归构建DataNode树
## 包含了写者绑定和元素节点生成器的构造
static func _bind_data_node_tree(base: Object, extra_pin: ExtraPin, data_node: DataNode, writer_bucket: Array[Writer]) -> void:
	# List和Node一定会绑定Writer
	var pure_pin := extra_pin.pure_pin
	match Utils.instance_get_type(pure_pin):
		PurePin.PurePinVariant, PurePin.PurePinStrict: # 都算叶子
			if extra_pin.pathed_trait != null:
				var pathed_trait := extra_pin.pathed_trait
				var current_target := base
				if current_target is Node and pathed_trait.path.get_name_count() > 0:
					var node_path := NodePath(pathed_trait.path.get_concatenated_names())
					assert((current_target as Node).has_node(node_path))
					current_target = (current_target as Node).get_node(node_path)
				assert(pathed_trait.type() == ExtraPin.PinType.PROPERTY)
				var property_path := NodePath(pathed_trait.path.get_concatenated_subnames()).get_as_property_path()
				var writer := WriterProperty.new(current_target, property_path, data_node)
				writer_bucket.append(writer)
		PurePin.PurePinStruct: # 都不算叶子
			assert(extra_pin.structed_trait != null)
			assert(data_node is DataNodeStruct)
			var data_node_struct := data_node as DataNodeStruct
			var properties := extra_pin.structed_trait.properties
			for key: StringName in properties:
				assert(is_instance_valid(data_node_struct.get_data_node(key)))
				_bind_data_node_tree(base, properties[key], data_node_struct.get_data_node(key), writer_bucket)
		PurePin.PurePinList: # 都算叶子
			assert(data_node is DataNodeList)
			if extra_pin.pathed_trait != null:
				var pathed_trait := extra_pin.pathed_trait
				var current_target := base
				if current_target is Node and pathed_trait.path.get_name_count() > 0:
					var node_path := NodePath(pathed_trait.path.get_concatenated_names())
					assert((current_target as Node).has_node(node_path))
					current_target = (current_target as Node).get_node(node_path)
				match pathed_trait.type():
					ExtraPin.PinType.NODE:
						assert(extra_pin.listed_trait != null)
						var target_sub_writer := _generate_child_sub_writer(extra_pin.listed_trait)
						var this_writer := WriterNode.new(current_target, data_node, target_sub_writer)
						writer_bucket.append(this_writer)
					ExtraPin.PinType.PROPERTY:
						var property_path := NodePath(pathed_trait.path.get_concatenated_subnames()).get_as_property_path()
						var target_sub_writer: WriterPropertyArray.ElementSubWriter
						if extra_pin.listed_trait != null:
							target_sub_writer = _generate_element_sub_writer(extra_pin.listed_trait)
						var this_writer := WriterPropertyArray.new(current_target, property_path, data_node, target_sub_writer)
						writer_bucket.append(this_writer)
		PurePin.PurePinNode:
			assert(base is Node)
			assert(extra_pin.structed_trait != null)
			assert(data_node is DataNodeNode)
			var data_node_node := data_node as DataNodeNode
			var properties := extra_pin.structed_trait.properties
			for key: StringName in properties:
				assert(is_instance_valid(data_node_node.get_data_node(key)))
				_bind_data_node_tree(base, properties[key], data_node_node.get_data_node(key), writer_bucket)
			# children
			var children_data_node := data_node_node.children()
			var pathed_trait := extra_pin.pathed_trait
			var listed_trait := extra_pin.listed_trait
			if pathed_trait != null and listed_trait != null:
				var current_node := base as Node
				if not Utils.node_path_is_empty(pathed_trait.path):
					assert(current_node.has_node(pathed_trait.path))
					current_node = current_node.get_node(pathed_trait.path)
				var target_sub_writer := _generate_child_sub_writer(listed_trait)
				var this_writer := WriterNode.new(current_node, children_data_node, target_sub_writer)
				writer_bucket.append(this_writer)
		var unexpected_type:
			push_error("Unexpected pure pin type: %s" % unexpected_type)

## 生成元素子写者
## 用于所有对象的数组型目标
static func _generate_element_sub_writer(listed_trait: ExtraPin.Listed) -> WriterPropertyArray.ElementSubWriter:
	var alloc_element_cb := func(element_data_node: DataNode) -> WriterPropertyArray.ElementInfo:
		var target_element := listed_trait.element_alloc.call(element_data_node) as Object
		var element_compiler := Compiler.new(target_element, listed_trait.element_pin, element_data_node)
		return WriterPropertyArray.ElementInfo.new(target_element, element_compiler.writers)
	var drop_element_cb := func(target_element_info: WriterPropertyArray.ElementInfo) -> void:
		target_element_info.binded_writers.clear()
		var elem_obj := target_element_info.target_element
		if not (listed_trait.element_drop.call(elem_obj) or elem_obj is RefCounted):
			elem_obj.queue_free()
	return WriterPropertyArray.ElementSubWriter.new(alloc_element_cb, drop_element_cb)

## 生成子节点子写者
## 用于节点
static func _generate_child_sub_writer(listed_trait: ExtraPin.Listed) -> WriterNode.ChildSubWriter:
	var alloc_child_cb := func(child_data_node: DataNode) -> WriterNode.ChildInfo:
		var target_child := listed_trait.element_alloc.call(child_data_node) as Node
		var child_compiler := Compiler.new(target_child, listed_trait.element_pin, child_data_node)
		return WriterNode.ChildInfo.new(target_child, child_compiler.writers)
	var drop_child_cb := func(target_child_info: WriterNode.ChildInfo) -> bool:
		target_child_info.binded_writers.clear()
		return listed_trait.element_drop.call(target_child_info.target_child)
	return WriterNode.ChildSubWriter.new(alloc_child_cb, drop_child_cb)
