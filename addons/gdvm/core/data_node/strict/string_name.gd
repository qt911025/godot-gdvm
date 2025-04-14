extends DataNodeStrict
const DataNodeStrict = preload("./base.gd")

var _data: StringName

func _init(value: StringName) -> void:
	render(value)

func _set_value(value: Variant) -> bool:
	assert(typeof(value) & (TYPE_STRING | TYPE_STRING_NAME | TYPE_NODE_PATH))
	_data = str(value)
	return true

func _get_value() -> Variant:
	return _data