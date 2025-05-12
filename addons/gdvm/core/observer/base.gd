## 监测者
const DataNode = preload("../data_node/base.gd")

# 监测者代表的是“非DataNode -> DataNode”，只作为MVVM的起始点
# 支持任何可以发出改变信号的对象，但是应该是输入事件伴随的信号，而非程序内部触发，避免循环

var _source_ref: WeakRef
var _target_data_node_ref: WeakRef

func _init(source: Object, target_data_node: DataNode) -> void:
	assert(is_instance_valid(source))
	assert(is_instance_valid(target_data_node))

	_source_ref = weakref(source)
	_target_data_node_ref = weakref(target_data_node)
