extends DataNodeStrict
const DataNodeStrict = preload("./base.gd")

var _data: Vector3

var x: float:
	set(value):
		render(Vector3(value, _data.y, _data.z))
	get:
		return _data.x

var y: float:
	set(value):
		render(Vector3(_data.x, value, _data.z))
	get:
		return _data.y

var z: float:
	set(value):
		render(Vector3(_data.x, _data.y, value))
	get:
		return _data.z

func _init(value: Vector3) -> void:
	render(value)

func _set_value(value: Variant) -> bool:
	assert(typeof(value) & (TYPE_VECTOR3 | TYPE_VECTOR3I))
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
	]