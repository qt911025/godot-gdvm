extends DataNodeStrict
const DataNodeStrict = preload("./base.gd")

var _data: Projection

var w: Vector4:
	set(value):
		render(Projection(_data.x, _data.y, _data.z, value))
	get:
		return _data.w

var x: Vector4:
	set(value):
		render(Projection(value, _data.y, _data.z, _data.w))
	get:
		return _data.x

var y: Vector4:
	set(value):
		render(Projection(_data.x, value, _data.z, _data.w))
	get:
		return _data.y

var z: Vector4:
	set(value):
		render(Projection(_data.x, _data.y, value, _data.w))
	get:
		return _data.z

func _init(value: Projection) -> void:
	render(value)

func _set_value(value: Variant) -> bool:
	assert(typeof(value) & TYPE_PROJECTION)
	_data = value
	return true

func _get_value() -> Variant:
	return _data

func _get_property_list() -> Array[Dictionary]:
	return [
		{
			"name": "x",
			"type": TYPE_VECTOR4,
		},
		{
			"name": "y",
			"type": TYPE_VECTOR4,
		},
		{
			"name": "z",
			"type": TYPE_VECTOR4,
		},
		{
			"name": "w",
			"type": TYPE_VECTOR4,
		},
	]