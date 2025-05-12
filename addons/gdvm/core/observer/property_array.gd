extends Observer
const Observer = preload("./base.gd")
const DataNodeList = preload("../data_node/list.gd")
const Utils = preload("../../utils.gd")

var _changed_signal: Signal

var _array_property: NodePath
var _alloc_element_observer: Callable
var _element_map: Array[ElementInfo]

class ElementInfo:
	var source_element_id: int
	var target_element_id: int
	var binded_observers: Array[Observer]

	func _init(source_element_id: int, target_element_id: int, binded_observers: Array) -> void:
		self.source_element_id = source_element_id
		self.target_element_id = target_element_id
		self.binded_observers = Array(binded_observers, TYPE_OBJECT, "RefCounted", Observer)

## 观察以对象为元素的数组
## 会创建子观察者，如果数组本身没有变化，只有对象有变化，只会触发子观察者
## 需要传入一个生成子观察者集合的回调函数，子观察者的改变信号需自行提供
## source: Object 源对象，数组是这个对象的成员
## array_property: NodePath 源数组在源对象的路径
## target_data_node_list: DataNodeList 绑定的目标DataNodeList
## changed_signal: Signal 源数组发生改变时的信号，元素的改变不需要发这个信号
## alloc_element_observer_cb: Callable 生成子观察者的回调函数，格式为func(source_element: Object, target_element: DataNode) -> Array[Observer]
func _init(source: Object,
	array_property: NodePath,
	target_data_node_list: DataNodeList,
	changed_signal: Signal,
	alloc_element_observer_cb: Callable
) -> void:
	super._init(source, target_data_node_list)
	assert(not changed_signal.is_null())
	assert(not array_property.is_empty())
	assert(Utils.instance_get_type(source.get_indexed(array_property)) == TYPE_ARRAY,
	"ObserverPropertyArray: the source property should be an array containing object.")
	_array_property = array_property
	_alloc_element_observer = alloc_element_observer_cb
	_changed_signal = changed_signal
	_changed_signal.connect(_on_changed_notified)
	_on_changed_notified()

func _on_changed_notified() -> void:
	var source: Object = _source_ref.get_ref()
	var target_data_node_list: DataNodeList = _target_data_node_ref.get_ref()
	if is_instance_valid(source) and is_instance_valid(target_data_node_list):
		var source_array: Array = source.get_indexed(_array_property)
		var new_size := source_array.size()
		target_data_node_list.resize(new_size)
		_element_map.resize(new_size)

		for i in new_size:
			var source_element: Object = source_array[i]
			var source_element_id: int = source_element.get_instance_id()
			var target_element: DataNode = target_data_node_list.get_element_node(i)
			var target_element_id: int = target_element.get_instance_id()
			var element_info := _element_map[i]
			if element_info == null or element_info.source_element_id != source_element_id or element_info.target_element_id != target_element_id:
				var binded_observers: Array = _alloc_element_observer.call(source_element, target_element)
				_element_map[i] = ElementInfo.new(source_element_id, target_element_id, binded_observers)
	else:
		_changed_signal.disconnect(_on_changed_notified)