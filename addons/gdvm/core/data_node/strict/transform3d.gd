extends DataNodeStrict
const DataNodeStrict = preload("./base.gd")

var _data: Transform3D

var basis: Basis:
	set(value):
		render(Transform3D(value, _data.origin))
	get:
		return _data.basis

var origin: Vector3:
	set(value):
		render(Transform3D(_data.basis, value))
	get:
		return _data.origin

func _init(value: Transform3D) -> void:
	render(value)

func _set_value(value: Variant) -> bool:
	assert(typeof(value) & TYPE_TRANSFORM3D)
	_data = value
	return true

func _get_value() -> Variant:
	return _data

func _get_property_list() -> Array[Dictionary]:
	return [
		{
			"name": "basis",
			"type": TYPE_BASIS,
		},
		{
			"name": "origin",
			"type": TYPE_VECTOR3,
		},
	]