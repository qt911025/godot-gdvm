extends DataNodeStrict
const DataNodeStrict = preload("./base.gd")

var _data: Plane

var d: float:
	set(value):
		render(Plane(_data.normal, value))
	get:
		return _data.d

var normal: Vector3:
	set(value):
		render(Plane(value, _data.d))
	get:
		return _data.normal

var x: float:
	set(value):
		render(Plane(Vector3(value, _data.y, _data.z), _data.d))
	get:
		return _data.x

var y: float:
	set(value):
		render(Plane(Vector3(_data.x, value, _data.z), _data.d))
	get:
		return _data.y

var z: float:
	set(value):
		render(Plane(Vector3(_data.x, _data.y, value), _data.d))
	get:
		return _data.z

func _init(value: Plane) -> void:
	render(value)

func _set_value(value: Variant) -> bool:
	assert(typeof(value) & TYPE_PLANE)
	_data = value
	return true

func _get_value() -> Variant:
	return _data

func _get_property_list() -> Array[Dictionary]:
	return [
		{
			"name": "d",
			"type": TYPE_FLOAT,
		},
		{
			"name": "normal",
			"type": TYPE_VECTOR3,
		},
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
	]