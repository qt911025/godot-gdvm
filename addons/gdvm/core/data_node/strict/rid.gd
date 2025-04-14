extends DataNodeStrict
const DataNodeStrict = preload("./base.gd")

var _data: RID

func _init(value: RID) -> void:
	render(value)

func _set_value(value: Variant) -> bool:
	assert(typeof(value) & TYPE_RID)
	_data = value
	return true

func _get_value() -> Variant:
	return _data