extends DataNode

const Utils = preload("../../utils.gd")

const DataNode = preload("./base.gd")
const DataNodeList = preload("./list.gd")

var _data: Array[DataNode]
var _element_type: Variant
var _element_generator: Callable

## 次序改变信号
## 是changed信号的子集，且比changed先发送
signal order_changed(this: DataNodeList)

var _element_changed_informed: bool

## 列表类DataNode，代表所有带类型或不带类型的列表
## 需要传入一个元素生成器，生成含有默认值的DataNode
## 需要传入元素的类型，因为无法完全靠元素生成器生成的元素判断类型（继承关系、null等），创建后无法更改类型
## element_generator必须是一个纯函数，不能有任何副作用（比如计数等修改状态的行为，因为有很多预操作会尝试调用它，导致计数不准确）
func _init(element_type: Variant, element_generator: Callable) -> void:
	_element_type = Utils.make_type_strict(element_type)
	_element_generator = element_generator
	assert(Utils.assert_instance_match_array_type((_element_generator.call() as DataNode).value(), _element_type))
	mark_changed()

# 简单赋值 多退少补
func _set_value(value: Variant) -> bool:
	var value_array := Array(value)
	var new_size := value_array.size()
	var old_size := _data.size()
	for i in mini(new_size, old_size):
		assert(Utils.assert_instance_match_array_type(value_array[i], _element_type))
		_data[i].render(value_array[i])
	if new_size > old_size:
		_data.resize(new_size)
		for i in range(old_size, new_size):
			var new_data_node: DataNode = _element_generator.call()
			_data[i] = new_data_node
			assert(Utils.assert_instance_match_array_type(value_array[i], _element_type))
			new_data_node.render(value_array[i])
			new_data_node.changed.connect(_on_element_changed)
	elif new_size < old_size:
		for i in range(new_size, old_size):
			_data[i].changed.disconnect(_on_element_changed)
		_data.resize(new_size)
	return true

func _get_value() -> Variant:
	var result := _data.map(func(d: DataNode) -> Variant: return d.value())
	match typeof(_element_type):
		TYPE_INT: # primitive type
			result = Array(result, _element_type, &"", null)
		TYPE_STRING: # built-in class
			result = Array(result, TYPE_OBJECT, _element_type, null)
		TYPE_OBJECT:
			result = Array(result, TYPE_OBJECT, (_element_type as Script).get_instance_base_type(), _element_type)
	return result

func _on_element_changed(child: DataNode) -> void:
	if not _element_changed_informed:
		_element_changed_informed = true
		_defer_mark_changed.call_deferred()

func _defer_mark_changed() -> void:
	_element_changed_informed = false
	mark_changed()

## 提示顺序改变
func mark_order_changed() -> void:
	_outdated = true
	order_changed.emit(self)
	changed.emit(self)

# getters =======================================================================

## 获取所有元素节点
## 只是为了方便迭代，对返回的数组的修改不会改变列表节点本身
func get_element_nodes() -> Array[DataNode]:
	return _data.duplicate()

## 原数组is_typed方法
func is_typed() -> bool:
	return _element_type != null

## 原数组is_empty方法
func is_empty() -> bool:
	return _data.is_empty()

## 原数组is_typed_builtin方法
## 输出和原版相同，但Godot的规则与GDVM的规则不同，不建议使用
func get_typed_builtin() -> int:
	var result: int
	match (typeof(_element_type)):
		TYPE_NIL:
			result = TYPE_NIL
		TYPE_INT:
			result = _element_type
		_:
			result = TYPE_OBJECT
	return result

## 原数组get_typed_class_name方法
## 输出和原版相同，但Godot的规则与GDVM的规则不同，不建议使用
func get_typed_class_name() -> StringName:
	match typeof(_element_type):
		TYPE_STRING:
			return StringName(_element_type)
		TYPE_OBJECT:
			return (_element_type as Script).get_instance_base_type()
	return &""

## 原数组get_typed_script方法
## 输出和原版相同，但Godot的规则与GDVM的规则不同，不建议使用
func get_typed_script() -> Script:
	if typeof(_element_type) == TYPE_OBJECT:
		return _element_type
	else:
		return null

## 获取元素类型
## 元素类型是GDVM的规则
func get_element_type() -> Variant:
	return _element_type

## 原数组is_same_typed方法，与另一个DataNodeList判断
func is_same_typed(other: DataNodeList) -> bool:
	return _element_type == other.get_element_type()

## 原数组is_same_typed方法，与另一个数组判断
func is_same_typed_with_array(other: Array) -> bool:
	var result := false
	match typeof(_element_type):
		TYPE_NIL:
			result = !other.is_typed()
		TYPE_INT:
			result = _element_type == other.get_typed_builtin() # element type不可能是TYPE_OBJECT，不需要额外判定
		TYPE_STRING:
			result = (_element_type == other.get_typed_class_name() and other.get_typed_script() == null)
		TYPE_OBJECT:
			result = _element_type == other.get_typed_script()
	return result

# 列表与Array对应的一些方法 =====================================================================
# 一些读取操作以及map-reduce操作就不实现了
# 改变类型的接口不会实现
func get_element(index: int) -> Variant:
	assert(index >= 0 && index < _data.size(), "DataNodeList: Index out of range.")
	return _data[index].value()

func set_element(index: int, value: Variant) -> void:
	assert(index >= 0 && index < _data.size(), "DataNodeList: Index out of range.")
	assert(Utils.assert_instance_match_array_type(value, _element_type))
	_data[index].render(value)

## 替换元素
## 效果同set_element，但会销毁并创建新的DataNode，并触发order_changed
func replace_element(index: int, value: Variant) -> void:
	assert(index >= 0 && index < _data.size(), "DataNodeList: Index out of range.")
	assert(Utils.assert_instance_match_array_type(value, _element_type))
	var new_data_node: DataNode = _element_generator.call()
	new_data_node.render(value) # 先rander避免重复发送changed
	new_data_node.changed.connect(_on_element_changed)
	_data[index].changed.disconnect(_on_element_changed)
	_data[index] = new_data_node
	mark_order_changed()

func get_element_node(index: int) -> DataNode:
	assert(index >= 0 && index < _data.size(), "DataNodeList: Index out of range.")
	return _data[index]

func push_front(value: Variant) -> void:
	assert(Utils.assert_instance_match_array_type(value, _element_type))
	var new_data_node: DataNode = _element_generator.call()
	_data.push_front(new_data_node)
	new_data_node.render(value)
	new_data_node.changed.connect(_on_element_changed)
	mark_order_changed()

func push_back(value: Variant) -> void:
	assert(Utils.assert_instance_match_array_type(value, _element_type))
	var new_data_node: DataNode = _element_generator.call()
	_data.push_back(new_data_node)
	new_data_node.render(value)
	new_data_node.changed.connect(_on_element_changed)
	mark_order_changed()

func append(value: Variant) -> void:
	push_back(value)

func append_array(value_array: Array) -> void:
	var extend_size = value_array.size()
	var old_data_size = _data.size()
	if extend_size > 0:
		_data.resize(old_data_size + extend_size)
		for i in extend_size:
			assert(Utils.assert_instance_match_array_type(value_array[i], _element_type))
			var new_data_node: DataNode = _element_generator.call()
			_data[old_data_size + i] = new_data_node
			new_data_node.render(value_array[i])
			new_data_node.changed.connect(_on_element_changed)
		mark_order_changed()

func pop_front() -> Variant:
	var result = null
	if _data.size() > 0:
		var popped_data_node := _data.pop_front()
		popped_data_node.changed.disconnect(_on_element_changed)
		result = popped_data_node.value()
		mark_order_changed()
	return result

func pop_back() -> Variant:
	var result = null
	if _data.size() > 0:
		var popped_data_node := _data.pop_back()
		popped_data_node.changed.disconnect(_on_element_changed)
		result = popped_data_node.value()
		mark_order_changed()
	return result

func front() -> Variant:
	var result = null
	if _data.size() > 0:
		result = _data.front().value()
	return result

func back() -> Variant:
	var result = null
	if _data.size() > 0:
		result = _data.back().value()
	return result

func size() -> int:
	return _data.size()

func resize(size: int) -> int:
	var result := OK
	var old_size = _data.size()
	if size > old_size:
		result = _data.resize(size)
		for i in range(old_size, size):
			var new_data_node: DataNode = _element_generator.call()
			_data[i] = new_data_node
			new_data_node.changed.connect(_on_element_changed)
		mark_order_changed()
	elif size < old_size:
		for i in range(size, old_size):
			_data[i].changed.disconnect(_on_element_changed)
		result = _data.resize(size)
		mark_order_changed()
	return result

func fill(value: Variant) -> void:
	assert(Utils.assert_instance_match_array_type(value, _element_type))
	for i in _data.size():
		_data[i].render(value)

func insert(index: int, value: Variant) -> bool:
	assert(index >= 0 && index <= _data.size(), "DataNodeList: Index out of range.")
	assert(Utils.assert_instance_match_array_type(value, _element_type))
	var data_node := _element_generator.call()
	var result = _data.insert(index, data_node)
	data_node.render(value)
	data_node.changed.connect(_on_element_changed)
	mark_order_changed()
	return result

func pop_at(position: int) -> Variant:
	assert(position >= 0 && position < _data.size(), "DataNodeList: Index out of range.")
	var popped_data_node := _data.pop_at(position)
	popped_data_node.changed.disconnect(_on_element_changed)
	mark_order_changed()
	return popped_data_node.value()

func remove_at(index: int) -> void:
	assert(index >= 0 && index < _data.size(), "DataNodeList: Index out of range.")
	_data[index].changed.disconnect(_on_element_changed)
	_data.remove_at(index)
	mark_order_changed()

func reverse() -> void:
	_data.reverse()
	mark_order_changed()

func shuffle() -> void:
	_data.shuffle()
	mark_order_changed()

## sort ascending
## 升序排序
func sort() -> void:
	sort_custom(func(a, b) -> bool: return a < b)

func sort_custom(compare_func: Callable) -> void:
	_data.sort_custom(func(a: DataNode, b: DataNode) -> bool:
		return compare_func.call(a.value(), b.value())
	)
	mark_order_changed()