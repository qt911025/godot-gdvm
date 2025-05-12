## WriterProperty
## 专门用于修改object的单个属性
extends Writer
const Writer = preload("./base.gd")
const WriterProperty = preload("./property.gd")

var _property: NodePath

## 属性写者
## target: Object 要控制的目标对象
## property: NodePath 要控制的目标对象的属性
## data_node: DataNode 上游DataNode
func _init(target: Object, property: NodePath, data_node: DataNode) -> void:
	assert(is_instance_valid(target))
	assert(is_instance_valid(data_node))

	_target_ref = weakref(target)
	_property = property
	# _data_node_ref = weakref(data_node)
	data_node.changed.connect(_on_data_node_changed)
	_on_data_node_changed(data_node)

func _on_data_node_changed(data_node: DataNode) -> void:
	var target: Object = _target_ref.get_ref()
	if is_instance_valid(target):
		target.set_indexed(_property, data_node.value())
	else:
		data_node.changed.disconnect(_on_data_node_changed)
