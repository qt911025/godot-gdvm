## 结构节点
## 用于构建静态的树状结构
extends DataNode
const DataNode = preload("./base.gd")
const DataNodeStruct = preload("./struct.gd")

var _property_list: Array[Dictionary] = Array([], TYPE_DICTIONARY, "", null)
var _data: Dictionary[StringName, DataNode]
var _child_changed_informed: bool

func _get_property_list() -> Array[Dictionary]:
	return _property_list

func _set(property: StringName, value: Variant) -> bool:
	if _data.has(property):
		if value is DataNode:
			value = value.value()
		var data_property: DataNode = _data[property]
		data_property.render(value)
		return true
	return false

func _get(property: StringName) -> Variant:
	if _data.has(property):
		return _data[property]
	return null

# 创建 ======================================================================
func _init() -> void:
	pass
	
## 以字典作为数据模板创建
# static func from_dictionary(value: Dictionary) -> DataNodeStruct:
# 	var result := DataNodeStruct.new()
# 	for key: StringName in value.keys():
# 		result._property_list.append({
# 			"name": key,
# 			"type": TYPE_OBJECT,
# 			"class_name": &"RefCounted"
# 		})
# 		var data_node := DataNode.build_data_node(value[key])
# 		result._data[key] = data_node
# 		data_node.changed.connect(result._on_property_changed)
# 	result.render(value)
# 	return result

# 没有from_object，太复杂了没必要

## 改变 ======================================================================
# struct并不是dictionary，不会赋一个不存在的键时新增键
# 要想改变必须新增一个属性

## 添加一个属性
func add_property(key: StringName, data_node: DataNode) -> void:
	assert(not key.is_empty())
	if _data.has(key):
		push_warning("DataNodeStructure already has property", key, "removing...")
		remove_property(key)

	_property_list.append({
		"name": key,
		"type": TYPE_OBJECT,
		"class_name": &"RefCounted"
	})
	_data[key] = data_node
	# 通知writer是同步，通知父节点是异步。因为构造一个DataNode树总是最先绑定的，Writer总是后绑定，优先级不高。
	# 数据更新会导致父节点先通知Writer（深度优先的调用），因为子节点尚未更新，父节点的更新得到的还是老状态（如果父Writer获取的数据不是从DataNode来的）
	data_node.changed.connect(_on_property_changed)
	_on_property_changed(data_node)

## 移除一个属性
func remove_property(key: StringName) -> void:
	if _data.has(key):
		var erased_data := _data[key] as DataNode
		_data.erase(key)
		_property_list = _property_list.filter(func(p: Dictionary) -> bool: return p["name"] != key)
		erased_data.changed.disconnect(_on_property_changed)
		_on_property_changed(erased_data)

## 获取某个属性的data node
func get_property_data_node(key: StringName) -> DataNode:
	if _data.has(key):
		return _data[key]
	return null

## 行为 ======================================================================
func _set_value(value: Variant) -> bool:
	match typeof(value):
		TYPE_OBJECT:
			var keys := (value as Object).get_property_list().map(func(p: Dictionary) -> String: return p["name"])
			for key in keys:
				if _data.has(key): set(key, value.get(key)) # 忽略不存在的键，也避免赋值到私有的值
		TYPE_DICTIONARY:
			for key in value.keys():
				if _data.has(key): set(key, value[key])
		_:
			push_warning("DataNodeStruct mismatched: Unsupported type ----", typeof(value))
	return false # 修改叶子节点会连锁触发，不需要返回true

func _get_value() -> Variant:
	var result := {}
	for key in _data.keys():
		result[key] = _data[key].value()
	return result

func _on_property_changed(child: DataNode) -> void:
	if not _child_changed_informed:
		_child_changed_informed = true
		_defer_mark_changed.call_deferred()

func _defer_mark_changed() -> void:
	_child_changed_informed = false
	mark_changed()