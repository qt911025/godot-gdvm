## 监测者
const DataNode = preload("./data_node/base.gd")

# 监测者代表的是“非DataNode -> DataNode”，只作为MVVM的起始点
# 支持任何可以发出改变信号的对象，但是应该是输入事件伴随的信号，而非程序内部触发，避免循环

var _source_ref: WeakRef
var _property: NodePath
var _target_data_node_ref: WeakRef

var _changed_signal: Signal

func _init(source: Object, property: NodePath, target_data_node: DataNode, changed_signal: Signal) -> void:
	assert(is_instance_valid(source))
	assert(is_instance_valid(target_data_node))
	assert(changed_signal != null)

	_source_ref = weakref(source)
	_property = property
	_target_data_node_ref = weakref(target_data_node)
	_changed_signal = changed_signal
	_changed_signal.connect(_on_changed_notified)
	_on_changed_notified()

func _on_changed_notified() -> void:
	var source: Object = _source_ref.get_ref()
	var target_data_node: DataNode = _target_data_node_ref.get_ref()
	if is_instance_valid(source) and is_instance_valid(target_data_node):
		if _property.is_empty():
			target_data_node.render(source)
		else:
			target_data_node.render(source.get_indexed(_property))
	else:
		_changed_signal.disconnect(_on_changed_notified)