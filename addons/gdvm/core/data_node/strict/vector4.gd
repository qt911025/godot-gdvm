extends DataNodeStrict
const DataNodeStrict = preload("./base.gd")

var _data: Vector4

var w: float:
	set(value):
		render(Vector4(_data.x, _data.y, _data.z, value))
	get:
		return _data.w

var x: float:
	set(value):
		render(Vector4(value, _data.y, _data.z, _data.w))
	get:
		return _data.x

var y: float:
	set(value):
		render(Vector4(_data.x, value, _data.z, _data.w))
	get:
		return _data.y

var z: float:
	set(value):
		render(Vector4(_data.x, _data.y, value, _data.w))
	get:
		return _data.z

func _init(value: Vector4) -> void:
	render(value)

func _set_value(value: Variant) -> bool:
	assert(typeof(value) & (TYPE_VECTOR4 | TYPE_VECTOR4I))
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
		{
			"name": "z",
			"type": TYPE_FLOAT,
		},
		{
			"name": "w",
			"type": TYPE_FLOAT,
		},
	]