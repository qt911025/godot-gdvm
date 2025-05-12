extends Observer
const Observer = preload("./base.gd")

var _changed_signal: Signal
var _property: NodePath

func _init(source: Object, property: NodePath, target_data_node: DataNode, changed_signal: Signal) -> void:
	super._init(source, target_data_node)
	assert(not changed_signal.is_null())
	_changed_signal = changed_signal
	_property = property
	if _property.is_empty():
		_changed_signal.connect(_on_changed_notified_self)
		_on_changed_notified_self()
	else:
		_changed_signal.connect(_on_changed_notified_property)
		_on_changed_notified_property()

func _on_changed_notified_self() -> void:
	var source: Object = _source_ref.get_ref()
	var target_data_node: DataNode = _target_data_node_ref.get_ref()
	if is_instance_valid(source) and is_instance_valid(target_data_node):
		target_data_node.render(source)
	else:
		_changed_signal.disconnect(_on_changed_notified_self)

func _on_changed_notified_property() -> void:
	var source: Object = _source_ref.get_ref()
	var target_data_node: DataNode = _target_data_node_ref.get_ref()
	if is_instance_valid(source) and is_instance_valid(target_data_node):
		target_data_node.render(source.get_indexed(_property))
	else:
		_changed_signal.disconnect(_on_changed_notified_property)