extends DataNodeStrict
const DataNodeStrict = preload("./base.gd")

var _data: Transform2D

var origin: Vector2:
	set(value):
		render(Transform2D(_data.x, _data.y, value))
	get:
		return _data.origin

var x: Vector2:
	set(value):
		render(Transform2D(value, _data.y, _data.origin))
	get:
		return _data.x

var y: Vector2:
	set(value):
		render(Transform2D(_data.x, value, _data.origin))
	get:
		return _data.y

func _init(value: Transform2D) -> void:
	render(value)

func _set_value(value: Variant) -> bool:
	assert(typeof(value) & TYPE_TRANSFORM2D)
	_data = value
	return true

func _get_value() -> Variant:
	return _data

func _get_property_list() -> Array[Dictionary]:
	return [
		{
			"name": "origin",
			"type": TYPE_VECTOR2,
		},
		{
			"name": "x",
			"type": TYPE_VECTOR2,
		},
		{
			"name": "y",
			"type": TYPE_VECTOR2,
		},
	]