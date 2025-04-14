extends DataNodeStrict
const DataNodeStrict = preload("./base.gd")

var _data: Vector4i

var w: int:
	set(value):
		render(Vector4i(_data.x, _data.y, _data.z, value))
	get:
		return _data.w

var x: int:
	set(value):
		render(Vector4i(value, _data.y, _data.z, _data.w))
	get:
		return _data.x

var y: int:
	set(value):
		render(Vector4i(_data.x, value, _data.z, _data.w))
	get:
		return _data.y

var z: int:
	set(value):
		render(Vector4i(_data.x, _data.y, value, _data.w))
	get:
		return _data.z

func _init(value: Vector4i) -> void:
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
			"type": TYPE_INT,
		},
		{
			"name": "y",
			"type": TYPE_INT,
		},
		{
			"name": "z",
			"type": TYPE_INT,
		},
		{
			"name": "w",
			"type": TYPE_INT,
		},
	]