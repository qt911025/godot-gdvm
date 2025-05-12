extends Observer
const Observer = preload("./base.gd")
const DataNodeDict = preload("../data_node/dict.gd")
const Utils = preload("../../utils.gd")

var _changed_signal: Signal

var _dictionary_property: NodePath
var _alloc_element_observer: Callable
var _element_map: Dictionary[Variant, ElementInfo]

class ElementInfo:
	var source_element_id: int
	var target_element_id: int
	var binded_observers: Array[Observer]

	func _init(source_element_id: int, target_element_id: int, binded_observers: Array) -> void:
		self.source_element_id = source_element_id
		self.target_element_id = target_element_id
		self.binded_observers = Array(binded_observers, TYPE_OBJECT, "RefCounted", Observer)

## 观察以对象为元素的字典
## 会创建子观察者，如果字典本身没有变化，只有对象有变化，只会触发子观察者
## 需要传入一个生成子观察者集合的回调函数，子观察者的改变信号需自行提供
## source: Object 源对象，字典是这个对象的成员
## dictionary_property: NodePath 源字典在源对象的路径
## target_data_node_dictionary: DataNodeDict 绑定的目标DataNodeDict
## changed_signal: Signal 源字典发生改变时的信号，元素的改变不需要发这个信号
## alloc_element_observer_cb: Callable 生成子观察者的回调函数，格式为func(source_element: Object, target_element: DataNode) -> Array[Observer]
func _init(source: Object,
	dictionary_property: NodePath,
	target_data_node_dictionary: DataNodeDict,
	changed_signal: Signal,
	alloc_element_observer_cb: Callable
) -> void:
	super._init(source, target_data_node_dictionary)
	assert(not changed_signal.is_null())
	assert(not dictionary_property.is_empty())
	assert(Utils.assert_instance_is_type(source.get_indexed(dictionary_property), TYPE_DICTIONARY))
	_dictionary_property = dictionary_property
	_alloc_element_observer = alloc_element_observer_cb
	_changed_signal = changed_signal
	_changed_signal.connect(_on_changed_notified)
	_on_changed_notified()

func _on_changed_notified() -> void:
	var source: Object = _source_ref.get_ref()
	var target_data_node_dict: DataNodeDict = _target_data_node_ref.get_ref()
	if is_instance_valid(source) and is_instance_valid(target_data_node_dict):
		var source_dictionary: Dictionary = source.get_indexed(_dictionary_property)
		for key in target_data_node_dict:
			if not source_dictionary.has(key):
				target_data_node_dict.erase(key)
		for key in _element_map:
			if not source_dictionary.has(key):
				_element_map.erase(key)
		for key in source_dictionary:
			var source_element: Object = source_dictionary[key]
			var source_element_id: int = source_element.get_instance_id()
			var target_element: DataNode = target_data_node_dict.get_or_add_element_node(key)
			var target_element_id: int = target_element.get_instance_id()
			var element_info := _element_map.get(key)
			if element_info == null or element_info.source_element_id != source_element_id or element_info.target_element_id != target_element_id:
				var binded_observers: Array = _alloc_element_observer.call(source_element, target_element)
				_element_map[key] = ElementInfo.new(source_element_id, target_element_id, binded_observers)
	else:
		_changed_signal.disconnect(_on_changed_notified)