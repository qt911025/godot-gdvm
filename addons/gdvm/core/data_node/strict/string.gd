extends DataNodeStrict
const DataNodeStrict = preload("./base.gd")

var _data: String

func _init(value: String) -> void:
	render(value)

func _set_value(value: Variant) -> bool:
	assert(typeof(value) & (TYPE_STRING | TYPE_STRING_NAME | TYPE_NODE_PATH))
	_data = str(value)
	return true

func _get_value() -> Variant:
	return _data