extends DataNodeStrict
const DataNodeStrict = preload("./base.gd")

var _data: Vector2i

var x: int:
	set(value):
		render(Vector2i(value, _data.y))
	get:
		return _data.x

var y: int:
	set(value):
		render(Vector2i(_data.x, value))
	get:
		return _data.y

func _init(value: Vector2i) -> void:
	render(value)

func _set_value(value: Variant) -> bool:
	assert(typeof(value) & (TYPE_VECTOR2 | TYPE_VECTOR2I))
	_data = value
	return true

func _get_value() -> Variant:
	return _data

func _get_property_list() -> Array[Dictionary]:
	return [
		{
			"name": "x",
			"type": TYPE_INT,
		},
		{
			"name": "y",
			"type": TYPE_INT,
		},
	]