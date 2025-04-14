extends DataNodeStrict
const DataNodeStrict = preload("./base.gd")

var _data: Vector2

var x: float:
	set(value):
		render(Vector2(value, _data.y))
	get:
		return _data.x

var y: float:
	set(value):
		render(Vector2(_data.x, value))
	get:
		return _data.y

func _init(value: Vector2) -> void:
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
			"type": TYPE_FLOAT,
		},
		{
			"name": "y",
			"type": TYPE_FLOAT,
		},
	]