extends DataNodeStrict
const DataNodeStrict = preload("./base.gd")

var _data: Vector3i

var x: int:
	set(value):
		render(Vector3i(value, _data.y, _data.z))
	get:
		return _data.x

var y: int:
	set(value):
		render(Vector3i(_data.x, value, _data.z))
	get:
		return _data.y

var z: int:
	set(value):
		render(Vector3i(_data.x, _data.y, value))
	get:
		return _data.z

func _init(value: Vector3i) -> void:
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
	]