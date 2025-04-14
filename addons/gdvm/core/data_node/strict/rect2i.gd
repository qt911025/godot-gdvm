extends DataNodeStrict
const DataNodeStrict = preload("./base.gd")

var _data: Rect2i

var end: Vector2i:
	set(value):
		render(Rect2i(_data.position, value - _data.position))
	get:
		return _data.end

var position: Vector2i:
	set(value):
		render(Rect2i(value, _data.size))
	get:
		return _data.position

var size: Vector2i:
	set(value):
		render(Rect2i(_data.position, value))
	get:
		return _data.size

func _init(value: Rect2i) -> void:
	render(value)

func _set_value(value: Variant) -> bool:
	assert(typeof(value) & (TYPE_RECT2 | TYPE_RECT2I))
	_data = value
	return true

func _get_value() -> Variant:
	return _data

func _get_property_list() -> Array[Dictionary]:
	return [
		{
			"name": "end",
			"type": TYPE_VECTOR2I,
		},
		{
			"name": "position",
			"type": TYPE_VECTOR2I,
		},
		{
			"name": "size",
			"type": TYPE_VECTOR2I,
		},
	]