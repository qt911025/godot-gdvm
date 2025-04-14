## WriterArray
## 专门用于修改Array
extends Writer
const Writer = preload("./base.gd")
const DataNodeList = preload("../data_node/list.gd")

var _array_property: NodePath

var _sub_writer: ElementSubWriter

class ElementInfo:
	var target_element: Object
	var binded_writers: Array[Writer]

	func _init(target_element: Object, binded_writers: Array) -> void:
		self.target_element = target_element
		self.binded_writers = Array(binded_writers, TYPE_OBJECT, "RefCounted", Writer)

class ElementSubWriter:
	## 申请元素回调，里面一般包括目标元素的构建，以及传入的DataNode的绑定
	var alloc_element: Callable
	var drop_element: Callable # must include unbind, if your writers has strong references

	var element_map := {} # 键是object id，作为弱引用，值是ElementInfo，是对target_element的强引用

	func _init(
		alloc_element_cb: Callable = func(element_data_node: DataNode) -> ElementInfo: return null,
		drop_element_cb: Callable = func(target_element_info: ElementInfo) -> void: return ,
	) -> void:
		alloc_element = alloc_element_cb
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
	assert(not target_array.is_typed() or data_node.is_same_typed_with_array(target_array))
	assert(is_instance_valid(data_node))

	_target_ref = weakref(target)
	_array_property = array_property
	_data_node_ref = weakref(data_node)
	_sub_writer = element_sub_writer

	if _sub_writer == null:
		# 没有sub writer，用于元素是基础数据类型，或者元素不绑定任何Writer的时候，改变元素总是创建新元素
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
		var target_array: Array = target.get_indexed(_array_property)
		var element_nodes: Array[DataNode] = data_node.get_element_nodes()
		var new_size := element_nodes.size()
		target_array.resize(element_nodes.size())
		
		var old_element_map := _sub_writer.element_map
		var new_element_map := {}

		for i in new_size:
			var element_data_node := element_nodes[i]
			var element_data_node_id: int = element_data_node.get_instance_id()
			var target_element_info: ElementInfo
			if old_element_map.has(element_data_node_id):
				target_element_info = old_element_map.get(element_data_node_id)
				old_element_map.erase(element_data_node_id)
			else:
				target_element_info = _sub_writer.alloc_element.call(element_data_node)
			target_array[i] = target_element_info.target_element
			new_element_map[element_data_node_id] = target_element_info

		for id_of_waste in old_element_map.keys():
			_sub_writer.drop_element.call(old_element_map[id_of_waste])
		
		_sub_writer.element_map = new_element_map
	else:
		data_node.changed.disconnect(_on_order_changed)
