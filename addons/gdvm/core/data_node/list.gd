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

var _changed_informed: bool
var _should_emit_order_changed: bool

## 列表类DataNode，代表所有带类型或不带类型的列表
## 需要传入一个元素生成器，生成含有默认值的DataNode
## 需要传入元素的类型，因为无法完全靠元素生成器生成的元素判断类型（继承关系、null等），创建后无法更改类型
## element_generator必须是一个纯函数，不能有任何副作用（比如计数等修改状态的行为，因为有很多预操作会尝试调用它，导致计数不准确）
func _init(element_type: Variant, element_generator: Callable) -> void:
	_element_type = Utils.make_type_strict(element_type)
	_element_generator = element_generator
	assert(Utils.assert_instance_is_type((_element_generator.call() as DataNode).value(), _element_type))
	mark_order_changed()

# 简单赋值 多退少补
func _set_value(value: Variant) -> bool:
	var value_array := Array(value)
	var new_size := value_array.size()
	var old_size := _data.size()
	for i in mini(new_size, old_size):
		assert(Utils.assert_instance_is_type(value_array[i], _element_type))
		_data[i].render(value_array[i])
	if new_size > old_size:
		_data.resize(new_size)
		for i in range(old_size, new_size):
			var new_data_node: DataNode = _element_generator.call()
			_data[i] = new_data_node
			assert(Utils.assert_instance_is_type(value_array[i], _element_type))
			new_data_node.render(value_array[i])
			new_data_node.changed.connect(_on_element_changed)
		mark_order_changed()
	elif new_size < old_size:
		for i in range(new_size, old_size):
			_data[i].changed.disconnect(_on_element_changed)
		_data.resize(new_size)
		mark_order_changed()
	return true

func _get_value() -> Variant:
	var result := _data.map(func(d: DataNode) -> Variant: return d.value())
	match typeof(_element_type):
		TYPE_INT: # primitive type
			result = Array(result, _element_type, &"", null)
		TYPE_STRING_NAME: # built-in class
			result = Array(result, TYPE_OBJECT, _element_type, null)
		TYPE_OBJECT:
			result = Array(result, TYPE_OBJECT, (_element_type as Script).get_instance_base_type(), _element_type)
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
## 获取某个索引的元素节点
func get_element_node(index: int) -> DataNode:
	assert(index >= 0 && index < _data.size(), "DataNodeList: Index out of range.")
	return _data[index]

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
	return Utils.type_to_builtin(_element_type)

## 原数组get_typed_class_name方法
## 输出和原版相同，但Godot的规则与GDVM的规则不同，不建议使用
func get_typed_class_name() -> StringName:
	return Utils.type_to_class_name(_element_type)

## 原数组get_typed_script方法
## 输出和原版相同，但Godot的规则与GDVM的规则不同，不建议使用
func get_typed_script() -> Script:
	return Utils.type_to_script(_element_type)

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
		TYPE_STRING_NAME:
			result = (_element_type == other.get_typed_class_name() and other.get_typed_script() == null)
		TYPE_OBJECT:
			result = _element_type == other.get_typed_script()
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

func count(value: Variant) -> int:
	var result := 0
	for element in _data:
		if value == element.value():
			result += 1
	return result

## 原数组bsearch方法
func bsearch(value: Variant, before: bool = true) -> int:
	var l := 0
	var r := _data.size()
	if before:
		while l < r:
			var m := (l + r) / 2
			if _data[m].value() < value:
				l = m + 1
			else:
				r = m
	else:
		while l < r:
			var m := (l + r) / 2
			if value < _data[m].value():
				r = m
			else:
				l = m + 1
	return l

## 原数组bsearch_custom方法
func bsearch_custom(value: Variant, compare_func: Callable, before: bool = true) -> int:
	var l := 0
	var r := _data.size()
	if before:
		while l < r:
			var m := (l + r) / 2
			if compare_func.call(_data[m].value(), value):
				l = m + 1
			else:
				r = m
	else:
		while l < r:
			var m := (l + r) / 2
			if compare_func.call(value, _data[m].value()):
				r = m
			else:
				l = m + 1
	return l

## 切片
## 相比原Array方法，没有deep
func slice(begin: int, end: int = 2147483647, step: int = 1) -> Array:
	return _data.slice(begin, end, step).map(func(d: DataNode) -> Variant: return d.value())

## 原数组filter方法
func filter(method: Callable) -> Array:
	var result := []
	result.resize(_data.size())
	var matched_count := 0
	for element: DataNode in _data:
		var value = element.value()
		if method.call(value):
			result[matched_count] = value
			matched_count += 1
	result.resize(matched_count)
	return result

## 原数组pick_random方法
func pick_random() -> Variant:
	return _data.pick_random().value()

## 原数组find方法
func find(value: Variant, from: int = 0) -> int:
	var result := -1
	if _data.size() > 0:
		from = from % _data.size()
		while from < _data.size():
			if _data[from].value() == value:
				result = from
				break
			from += 1
	return result

## 原数组find_custom方法
func find_custom(value: Variant, method: Callable, from: int = 0) -> int:
	var result := -1
	if _data.size() > 0:
		from = from % _data.size()
		while from < _data.size():
			if method.call(_data[from].value(), value):
				result = from
				break
			from += 1
	return result

## 原数组rfind方法
func rfind(value: Variant, from: int = -1) -> int:
	var result := -1
	if _data.size() > 0:
		from = from % _data.size()
		while from >= 0:
			if _data[from].value() == value:
				result = from
				break
			from -= 1
	return result

## 原数组rfind_custom方法
func rfind_custom(value: Variant, method: Callable, from: int = -1) -> int:
	var result := -1
	if _data.size() > 0:
		from = from % _data.size()
		while from >= 0:
			if method.call(_data[from].value(), value):
				result = from
				break
			from -= 1
	return result

## 原数组hash方法
func hash() -> int:
	return (value() as Array).hash()

func max() -> Variant:
	return (value() as Array).max()

func min() -> Variant:
	return (value() as Array).min()

# 单个元素写 ==========================================================
## 获取一个元素
## 对应Array的get
func get_element(index: int) -> Variant:
	assert(index >= 0 && index < _data.size(), "DataNodeList: Indexoutofrange.")
	return _data[index].value()

## 设置一个元素
## 对应Array的set
func set_element(index: int, value: Variant) -> void:
	assert(index >= 0 && index < _data.size(), "DataNodeList: Indexoutofrange.")
	assert(Utils.assert_instance_is_type(value, _element_type))
	_data[index].render(value)

## 替换元素
## 效果同set_element，但会销毁并创建新的DataNode，并触发order_changed
func replace_element(index: int, value: Variant) -> void:
	assert(index >= 0 && index < _data.size(), "DataNodeList: Indexoutofrange.")
	assert(Utils.assert_instance_is_type(value, _element_type))
	var new_data_node: DataNode = _element_generator.call()
	new_data_node.render(value) # 先render避免重复发送changed
	new_data_node.changed.connect(_on_element_changed)
	_data[index].changed.disconnect(_on_element_changed)
	_data[index] = new_data_node
	mark_order_changed()

func push_front(value: Variant) -> void:
	assert(Utils.assert_instance_is_type(value, _element_type))
	var new_data_node: DataNode = _element_generator.call()
	_data.push_front(new_data_node)
	new_data_node.render(value)
	new_data_node.changed.connect(_on_element_changed)
	mark_order_changed()

func push_back(value: Variant) -> void:
	assert(Utils.assert_instance_is_type(value, _element_type))
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
			assert(Utils.assert_instance_is_type(value_array[i], _element_type))
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

func insert(index: int, value: Variant) -> bool:
	assert(index >= 0 && index <= _data.size(), "DataNodeList: Indexoutofrange.")
	assert(Utils.assert_instance_is_type(value, _element_type))
	var data_node := _element_generator.call()
	var result = _data.insert(index, data_node)
	data_node.render(value)
	data_node.changed.connect(_on_element_changed)
	mark_order_changed()
	return result

func pop_at(position: int) -> Variant:
	assert(position >= 0 && position < _data.size(), "DataNodeList: Indexoutofrange.")
	var popped_data_node := _data.pop_at(position)
	popped_data_node.changed.disconnect(_on_element_changed)
	mark_order_changed()
	return popped_data_node.value()

func remove_at(index: int) -> void:
	assert(index >= 0 && index < _data.size(), "DataNodeList: Indexoutofrange.")
	_data[index].changed.disconnect(_on_element_changed)
	_data.remove_at(index)
	mark_order_changed()

func erase(value: Variant) -> void:
	if value is DataNode:
		value = value.value()
	for i in _data.size():
		if _data[i].value() == value:
			remove_at(i)
			return
			
# 对整个数组的操作 ========================================================
func clear() -> void:
	resize(0)

## 与原版assign不同的是这既接受DataNodeList也接受Array
func assign(value: Variant) -> void:
	render(value)

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
	assert(Utils.assert_instance_is_type(value, _element_type))
	for i in _data.size():
		_data[i].render(value)

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

# 一些map-reduce方法 =====================================================================
func any(method: Callable) -> bool:
	for element in _data:
		if method.call(element.value()):
			return true
	return false

func all(method: Callable) -> bool:
	for element in _data:
		if !method.call(element.value()):
			return false
	return true

func map(method: Callable) -> Array:
	var result = []
	result.resize(_data.size())
	for i in _data.size():
		result[i] = method.call(_data[i].value())
	return result

func reduce(method: Callable, accum: Variant = null) -> Variant:
	if _data.size() == 0:
		return null
	if accum == null:
		accum = _data[0].value()
		for i in range(1, _data.size()):
			accum = method.call(accum, _data[i].value())
	else:
		for element in _data:
			accum = method.call(accum, element.value())
	return accum

# todo duplicate先不实现，可能所有DataNode都要实现
