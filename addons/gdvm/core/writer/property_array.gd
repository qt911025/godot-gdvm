## WriterPropertyArray
## 专门用于修改Array
extends Writer
const Writer = preload("./base.gd")
const DataNodeList = preload("../data_node/list.gd")

var _array_property: NodePath

var _sub_writer: ElementSubWriter

class ElementInfo:
	var source_element_id: int
	var target_element_id: int
	var binded_writers: Array[Writer]

	func _init(source_element_id: int, target_element_id: int, binded_writers: Array) -> void:
		self.source_element_id = source_element_id
		self.target_element_id = target_element_id
		self.binded_writers = Array(binded_writers, TYPE_OBJECT, "RefCounted", Writer)

class ElementSubWriter:
	## 申请元素回调，里面一般包括目标元素的构建，以及传入的DataNode的绑定
	var alloc_element: Callable
	var bind_writers: Callable
	var drop_element: Callable

	var element_map: Array[ElementInfo]

	func _init(
		alloc_element_cb: Callable = func(source_data_node: DataNode) -> Object: return null,
		bind_writers_cb: Callable = func(source_data_node: DataNode, target_element: Object) -> Array: return [],
		drop_element_cb: Callable = func(target_element: Object) -> void: return ,
	) -> void:
		alloc_element = alloc_element_cb
		bind_writers = bind_writers_cb
		drop_element = drop_element_cb

## 数组写者
## target: Object 要控制的目标对象
## array_property: NodePath 要控制的目标数组，目标数组必须是某个对象的成员
## data_node: DataNode 上游DataNode
## element_sub_writer: ElementSubWriter 元素子写者，包含控制目标数组元素创建与释放的回调，只能用在元素是Object时
func _init(target: Object, array_property: NodePath, data_node: DataNodeList, element_sub_writer: ElementSubWriter = null) -> void:
	# 目标数组必须是某个对象的成员（因为无法弱引用数组）
	assert(is_instance_valid(target))
	assert(target.get_indexed(array_property) is Array)
	var target_array: Array = target.get_indexed(array_property)
	assert(is_instance_valid(data_node))

	_target_ref = weakref(target)
	_array_property = array_property
	_sub_writer = element_sub_writer

	if _sub_writer == null:
		# 没有sub writer，用于元素是基础数据类型，或者元素不绑定任何Writer的时候，改变元素总是创建新元素
		assert(not target_array.is_typed() or data_node.is_same_typed_with_array(target_array))
		data_node.changed.connect(_on_element_changed)
		_on_element_changed(data_node)
	else:
		# 有sub writer，用于元素是Object且绑定了Writer的时候，数组写者只关心元素对象次序、有无的改变，而不关心元素属性的改变
		data_node.order_changed.connect(_on_order_changed)
		_on_order_changed(data_node)

func _on_element_changed(data_node: DataNode) -> void:
	var target: Object = _target_ref.get_ref()
	if is_instance_valid(target):
		var target_array: Array = target.get_indexed(_array_property)
		var value_array := Array(data_node.value())
		var new_size := value_array.size()
		target_array.resize(new_size)
		for i in new_size:
			target_array[i] = value_array[i]
	else:
		data_node.changed.disconnect(_on_element_changed)

func _on_order_changed(data_node: DataNode) -> void:
	var target: Object = _target_ref.get_ref()
	if is_instance_valid(target):
		var source_element_nodes: Array[DataNode] = data_node.get_element_nodes()
		var new_size := source_element_nodes.size()
		_sub_writer.element_map.resize(new_size)
		var target_array: Array = target.get_indexed(_array_property)

		var old_size := target_array.size()
		if old_size < new_size:
			target_array.resize(new_size)
			for i in range(old_size, new_size):
				target_array[i] = _sub_writer.alloc_element.call(source_element_nodes[i])

		if old_size > new_size:
			for i in range(new_size, old_size):
				var element_to_be_removed: Object = target_array[i]
				_sub_writer.drop_element.call(element_to_be_removed)
			target_array.resize(new_size)

		var different_index: Dictionary[int, Dictionary]

		for i in new_size:
			var source_element: DataNode = source_element_nodes[i]
			var source_element_id: int = source_element.get_instance_id()
			var target_element: Object = target_array[i]
			var target_element_id: int = target_element.get_instance_id()
			var element_info := _sub_writer.element_map[i]
			if not (element_info != null and \
			element_info.source_child_id == source_element_id and \
			element_info.target_element_id == target_element_id):
				var new_info := {
					s = source_element,
					sid = source_element_id,
					t = target_element,
					tid = target_element_id,
				}
				different_index[i] = new_info
				_sub_writer.element_map[i] = null
		for i in different_index:
			var new_info := different_index[i]
			_sub_writer.element_map[i] = ElementInfo.new(
				new_info.sid,
				new_info.tid,
				_sub_writer.bind_writers.call(new_info.s, new_info.t)
			)
	else:
		data_node.order_changed.disconnect(_on_order_changed)
