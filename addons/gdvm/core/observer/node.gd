extends Observer
const Observer = preload("./base.gd")
const DataNodeList = preload("../data_node/list.gd")
const Utils = preload("../../utils.gd")

var _alloc_child_observer: Callable
var _child_map: Array[ChildInfo]

class ChildInfo:
	var source_child_id: int
	var target_element_id: int
	var binded_observers: Array[Observer]

	func _init(source_child_id: int, target_element_id: int, binded_observers: Array) -> void:
		self.source_child_id = source_child_id
		self.target_element_id = target_element_id
		self.binded_observers = Array(binded_observers, TYPE_OBJECT, "RefCounted", Observer)

## 观察节点的子节点
## 会创建子观察者
## 需要传入一个生成子观察者集合的回调函数，子观察者的改变信号需自行提供
## source: Node 源节点
## target_data_node_list: DataNodeList 绑定的目标DataNodeList
## alloc_element_observer_cb: Callable 生成子观察者的回调函数，格式为func(source_child: Node, target_element: DataNode) -> Array[Observer]
func _init(source: Node,
	target_data_node_list: DataNodeList,
	alloc_child_observer_cb: Callable
) -> void:
	super._init(source, target_data_node_list)
	_alloc_child_observer = alloc_child_observer_cb
	source.child_entered_tree.connect(_on_changed_notified)
	source.child_exiting_tree.connect(_on_changed_notified)
	source.child_order_changed.connect(_on_changed_notified)
	_on_changed_notified()

func _on_changed_notified() -> void:
	var source: Node = _source_ref.get_ref()
	assert(is_instance_valid(source)) # 按理说应该永远不会发生
	var target_data_node_list: DataNodeList = _target_data_node_ref.get_ref()
	if is_instance_valid(target_data_node_list):
		var source_children := source.get_children()
		var new_size := source.get_child_count()
		target_data_node_list.resize(new_size)
		_child_map.resize(new_size)

		for i in new_size:
			var source_child: Node = source.get_child(i)
			var source_child_id: int = source_child.get_instance_id()
			var target_element: DataNode = target_data_node_list.get_element_node(i)
			var target_element_id: int = target_element.get_instance_id()
			var child_info := _child_map[i]
			if child_info == null or child_info.source_child_id != source_child_id or child_info.target_element_id != target_element_id:
				var binded_observers: Array = _alloc_child_observer.call(source_child, target_element)
				_child_map[i] = ChildInfo.new(source_child_id, target_element_id, binded_observers)
	else:
		source.child_entered_tree.disconnect(_on_changed_notified)
		source.child_exiting_tree.disconnect(_on_changed_notified)
		source.child_order_changed.disconnect(_on_changed_notified)