extends DataNodeStrict
const DataNodeStrict = preload("./base.gd")

var _data: Basis

var x: Vector3:
	set(value):
		render(Basis(value, _data.y, _data.z))
	get:
		return _data.x

var y: Vector3:
	set(value):
		render(Basis(_data.x, value, _data.z))
	get:
		return _data.y

var z: Vector3:
	set(value):
		render(Basis(_data.x, _data.y, value))
	get:
		return _data.z

func _init(value: Basis) -> void:
	render(value)

func _set_value(value: Variant) -> bool:
	assert(typeof(value) & TYPE_BASIS)
	_data = value
	return true

func _get_value() -> Variant:
	return _data

func _get_property_list() -> Array[Dictionary]:
	return [
		{
			"name": "x",
			"type": TYPE_VECTOR3,
		},
		{
			"name": "y",
			"type": TYPE_VECTOR3,
		},
		{
			"name": "z",
			"type": TYPE_VECTOR3,
		},
	]