extends DataNodeStrict
const DataNodeStrict = preload("./base.gd")

var _data: int

func _init(value: int) -> void:
	render(value)

func _set_value(value: Variant) -> bool:
	assert(typeof(value) & (TYPE_INT | TYPE_BOOL | TYPE_FLOAT))
	_data = value
	return true

func _get_value() -> Variant:
	return _data