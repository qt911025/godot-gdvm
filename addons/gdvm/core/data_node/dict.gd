extends DataNode

const Utils = preload("../../utils.gd")

const DataNode = preload("./base.gd")
const DataNodeDict = preload("./dict.gd")

# 字典类DataNode
# 和struct的区别是，字典可以更自由地增删键值对，可以绑定字典类observer和writer
# struct只能以StringName为键，字典可以用任何类型作键

var _data: Dictionary

var _key_type: Variant
var _value_type: Variant
var _value_data_node_generator: Callable

## 次序改变信号
## 是changed信号的子集，且比changed先发送
signal order_changed(this: DataNodeDict)

var _changed_informed: bool
var _should_emit_order_changed: bool

## 字典类DataNode，代表所有带类型或不带类型的字典
## 需要传入一个元素生成器，生成含有默认值的DataNode
## 需要传入元素的类型，因为无法完全靠元素生成器生成的元素判断类型（继承关系、null等），创建后无法更改类型
## value_data_node_generator必须是一个纯函数，不能有任何副作用（比如计数等修改状态的行为，因为有很多预操作会尝试调用它，导致计数不准确）
func _init(key_type: Variant, value_type: Variant, value_data_node_generator: Callable) -> void:
	_key_type = Utils.make_type_strict(key_type)
	var key_type_3 := Utils.type_from_gdvm_to_godot_style(_key_type)
	_data = Dictionary({}, key_type_3[0], key_type_3[1], key_type_3[2], TYPE_OBJECT, "RefCounted", DataNode)
	
	_value_type = Utils.make_type_strict(value_type)
	_value_data_node_generator = value_data_node_generator
	assert(Utils.assert_instance_is_type((_value_data_node_generator.call() as DataNode).value(), _value_type))
	mark_order_changed()

# 简单赋值 多退少补
func _set_value(value: Variant) -> bool:
	assert(value is Dictionary, "DataNodeList: value must be a Dictionary.")
	var value_dictionary := value as Dictionary

	for key in _data:
		if not value_dictionary.has(key):
			_data[key].changed.disconnect(_on_element_changed)
			_data.erase(key)
			mark_order_changed()

	for key in value_dictionary:
		if _data.has(key):
			_data[key].render(value_dictionary[key])
		else:
			assert(Utils.assert_instance_is_type(key, _key_type))
			assert(Utils.assert_instance_is_type(value_dictionary[key], _value_type))
			var new_data_node: DataNode = _value_data_node_generator.call()
			_data[key] = new_data_node
			new_data_node.render(value_dictionary[key])
			new_data_node.changed.connect(_on_element_changed)
			mark_order_changed()
	return true

func _get_value() -> Variant:
	var result := Dictionary({},
		Utils.type_to_builtin(_key_type),
		Utils.type_to_class_name(_key_type),
		Utils.type_to_script(_key_type),
		Utils.type_to_builtin(_value_type),
		Utils.type_to_class_name(_value_type),
		Utils.type_to_script(_value_type)
	)
	for key in _data:
		result[key] = _data[key].value()
	return result
	
func _on_element_changed(child: DataNode) -> void:
	if not _changed_informed:
		_changed_informed = true
		_defer_mark_changed.call_deferred()

func mark_order_changed() -> void:
	_should_emit_order_changed = true
	if not _changed_informed:
		_changed_informed = true
		_defer_mark_changed.call_deferred()

func _defer_mark_changed() -> void:
	_outdated = true
	if _should_emit_order_changed:
		_should_emit_order_changed = false
		order_changed.emit(self)
	changed.emit(self)
	_changed_informed = false

# getters =======================================================================

## 获取所有元素节点
## 只是为了方便迭代，对返回的数组的修改不会改变列表节点本身
func get_element_nodes() -> Dictionary:
	return _data.duplicate()

## 原数组is_typed方法
func is_typed() -> bool:
	return _key_type != null or _value_type != null

## 原数组is_typed_key方法
func is_typed_key() -> bool:
	return _key_type != null

## 原数组is_typed_value方法
func is_typed_value() -> bool:
	return _value_type != null

## 原数组is_empty方法
func is_empty() -> bool:
	return _data.is_empty()

## 原数组is_typed_key_builtin方法
## 输出和原版相同，但Godot的规则与GDVM的规则不同，不建议使用
func get_typed_key_builtin() -> int:
	return Utils.type_to_builtin(_key_type)

## 原数组get_typed_key_class_name方法
## 输出和原版相同，但Godot的规则与GDVM的规则不同，不建议使用
func get_typed_class_name() -> StringName:
	return Utils.type_to_class_name(_key_type)

## 原数组get_typed_key_script方法
## 输出和原版相同，但Godot的规则与GDVM的规则不同，不建议使用
func get_typed_script() -> Script:
	return Utils.type_to_script(_key_type)

## 原数组get_typed_value_builtin方法
## 输出和原版相同，但Godot的规则与GDVM的规则不同，不建议使用
func get_typed_value_builtin() -> int:
	return Utils.type_to_builtin(_value_type)

## 原数组get_typed_value_class_name方法
## 输出和原版相同，但Godot的规则与GDVM的规则不同，不建议使用
func get_typed_value_class_name() -> StringName:
	return Utils.type_to_class_name(_value_type)

## 原数组get_typed_value_script方法
## 输出和原版相同，但Godot的规则与GDVM的规则不同，不建议使用
func get_typed_value_script() -> Script:
	return Utils.type_to_script(_value_type)

## 获取键的类型
## 键的类型是GDVM的规则
func get_key_type() -> Variant:
	return _key_type

## 获取值的类型
## 值的类型是GDVM的规则
func get_value_type() -> Variant:
	return _value_type

# 原字典is_same_typed方法，与另一个DataNodeDict判断
func is_same_typed(other: DataNodeDict) -> bool:
	return _key_type == other.get_key_type() and _value_type == other.get_value_type()

## 原字典is_same_typed方法，与另一个字典判断
func is_same_typed_with_dictionary(other: Dictionary) -> bool:
	var result := true
	match typeof(_key_type):
		TYPE_NIL:
			if other.is_typed_key():
				result = false
		TYPE_INT:
			if other.get_typed_key_builtin() != _key_type:
				result = false
		TYPE_STRING_NAME:
			if other.get_typed_key_class_name() != _key_type or other.get_typed_key_script() != null:
				result = false
		TYPE_OBJECT:
			if other.get_typed_key_script() != _key_type:
				result = false
	match typeof(_value_type):
		TYPE_NIL:
			if other.is_typed_value():
				result = false
		TYPE_INT:
			if other.get_typed_value_builtin() != _value_type:
				result = false
		TYPE_STRING_NAME:
			if other.get_typed_value_class_name() != _value_type or other.get_typed_value_script() != null:
				result = false
		TYPE_OBJECT:
			if other.get_typed_value_script() != _value_type:
				result = false
	return result

## 原字典is_same_typed_key方法，与另一个DataNodeDict判断
func is_same_typed_key(other: DataNodeDict) -> bool:
	return _key_type == other.get_key_type()

## 原字典is_same_typed_key方法，与另一个字典判断
func is_same_typed_key_with_dictionary(other: Dictionary) -> bool:
	var result := true
	match typeof(_key_type):
		TYPE_NIL:
			if other.is_typed_key():
				result = false
		TYPE_INT:
			if other.get_typed_key_builtin() != _key_type:
				result = false
		TYPE_STRING_NAME:
			if other.get_typed_key_class_name() != _key_type or other.get_typed_key_script() != null:
				result = false
		TYPE_OBJECT:
			if other.get_typed_key_script() != _key_type:
				result = false
	return result

## 原字典is_same_typed_value方法，与另一个DataNodeDict判断
func is_same_typed_value(other: DataNodeDict) -> bool:
	return _value_type == other.get_value_type()

## 原字典is_same_typed_value方法，与另一个字典判断
func is_same_typed_value_with_dictionary(other: Dictionary) -> bool:
	var result := true
	match typeof(_value_type):
		TYPE_NIL:
			if other.is_typed_value():
				result = false
		TYPE_INT:
			if other.get_typed_value_builtin() != _value_type:
				result = false
		TYPE_STRING_NAME:
			if other.get_typed_value_class_name() != _value_type or other.get_typed_value_script() != null:
				result = false
		TYPE_OBJECT:
			if other.get_typed_value_script() != _value_type:
				result = false
	return result

func keys() -> Array:
	return _data.keys()

func values() -> Array:
	return (value() as Dictionary).values()

func value_data_nodes() -> Array:
	return _data.values()

func hash() -> int:
	return (value() as Dictionary).hash()

func recursive_equal(dictionary: Dictionary, recursion_count: int) -> bool:
	return (value() as Dictionary).recursive_equal(dictionary, recursion_count)

func size() -> int:
	return _data.size()

func find_key(value: Variant) -> Variant:
	if Utils.instance_is_type(value, _value_type):
		for key in _data:
			if _data[key].value() == value:
				return key
	return null

func has(key: Variant) -> bool:
	return _data.has(key)

func has_all(keys: Array) -> bool:
	return keys.all(_data.has)

# 元素操作 ========================================================
## get方法，对应dictionary的get
## 叫get_element是因为避免和DataNode的get撞名
func get_element(key: Variant, default: Variant = null) -> Variant:
	assert(Utils.assert_instance_is_type(key, _key_type))
	if not _data.has(key):
		return default
	return _data[key].value()

## set方法，对应dictionary的set
## 叫set_element是因为避免和DataNode的set撞名
func set_element(key: Variant, value: Variant) -> void:
	assert(Utils.assert_instance_is_type(key, _key_type))
	assert(Utils.assert_instance_is_type(value, _value_type))
	if not _data.has(key):
		var new_data_node: DataNode = _value_data_node_generator.call()
		new_data_node.changed.connect(_on_element_changed)
		_data[key] = new_data_node
		mark_order_changed()
	_data[key].render(value)

## 替换元素
## 效果同set_element，但会销毁并创建新的DataNode
func replace_element(key: Variant, value: Variant) -> void:
	assert(Utils.assert_instance_is_type(key, _key_type))
	assert(Utils.assert_instance_is_type(value, _value_type))
	var new_data_node: DataNode = _value_data_node_generator.call()
	new_data_node.render(value)
	new_data_node.changed.connect(_on_element_changed)
	if _data.has(key):
		_data[key].changed.disconnect(_on_element_changed)
	_data[key] = new_data_node
	mark_order_changed()

## 获取一个元素，没有则添加
## 效果同Dictionary的get_or_add
func get_or_add(key: Variant, default: Variant = null) -> Variant:
	return get_or_add_element_node(key, default).value()

func get_element_node(key: Variant) -> DataNode:
	assert(Utils.assert_instance_is_type(key, _key_type))
	return _data.get(key)

func get_or_add_element_node(key: Variant, default: Variant = null) -> DataNode:
	assert(Utils.assert_instance_is_type(key, _key_type))
	assert(default == null or Utils.assert_instance_is_type(default, _value_type))
	var result: DataNode = get_element_node(key)
	if result == null:
		result = _value_data_node_generator.call()
		if default != null:
			result.render(default)
		result.changed.connect(_on_element_changed)
		_data[key] = result
		mark_order_changed()
	return result

func erase(key: Variant) -> void:
	if _data.has(key):
		_data[key].changed.disconnect(_on_element_changed)
		_data.erase(key)
		mark_order_changed()

# 字典操作 =====================================================================
func clear() -> void:
	for key in _data:
		_data[key].changed.disconnect(_on_element_changed)
	_data.clear()
	mark_order_changed()

func assign(dictionary: Dictionary) -> void:
	render(dictionary)

func merge(dictionary: Dictionary, overwrite: bool = false) -> void:
	for key in dictionary:
		if not _data.has(key) or overwrite:
			set_element(key, dictionary[key])

func sort() -> void:
	_data.sort()
	mark_order_changed()

# 等要实现duplicate之后再实现
# duplicate(deep: bool = false) const
# merged(dictionary: Dictionary, overwrite: bool = false) const
