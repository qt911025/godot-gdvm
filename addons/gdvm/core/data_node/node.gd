## 节点节点（DataNodeNode）
extends DataNodeStruct
const DataNodeStruct = preload("./struct.gd")
const DataNodeList = preload("./list.gd")
const DataNodeNode = preload("./node.gd")

# data =====================================================================================
class NodeDataBucket:
	var _data: Dictionary
	var _children: Array

	func _init(data: Dictionary, children: Array) -> void:
		_data = data
		_children = children

	func _set(property: StringName, value: Variant) -> bool:
		return _data.set(property, value)

	func _get(property: StringName) -> Variant:
		return _data.get(property)

	func _get_property_list() -> Array[Dictionary]:
		var result: Array = _data.keys().map(func(key) -> Dictionary:
			var data = self._data[key]
			var data_type = typeof(data)
			var result := {
				"name": key,
				"type": data_type,
			}
			if data_type == TYPE_OBJECT:
				result.class_name = (data as Object).get_class()
			return result
		)
		return Array(result, TYPE_DICTIONARY, &"", null)

	func data() -> Dictionary:
		return _data

	func children() -> Array:
		return _children

var _children: DataNodeList

# methods =================================================================================
func _init(element_type: Variant, element_generator: Callable) -> void:
	_children = DataNodeList.new(element_type, element_generator)
	_children.changed.connect(_on_property_changed)

func children() -> DataNodeList:
	return _children

func _set_value(value: Variant) -> bool:
	# 支持传入单独的字典或者数组，也支持都传入（用NodeDataBucket）
	var data_to_render
	var array_to_render
	if value is NodeDataBucket:
		data_to_render = value.data()
		array_to_render = value.children()
	elif Utils.type_is_array(typeof(value)):
		array_to_render = value
	elif TYPE_DICTIONARY == typeof(value) or TYPE_OBJECT == typeof(value):
		data_to_render = value
		if value is Node:
			array_to_render = value.get_children()

	if array_to_render != null:
		_children._set_value(array_to_render)

	if data_to_render != null:
		super._set_value(data_to_render)

	return false

func _get_value() -> Variant:
	return NodeDataBucket.new(super._get_value(), _children._get_value())