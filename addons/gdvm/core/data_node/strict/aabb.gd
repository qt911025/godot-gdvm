extends DataNodeStrict
const DataNodeStrict = preload("./base.gd")

var _data: AABB

var end: Vector3:
	set(value):
		render(AABB(_data.position, value - _data.position))
	get:
		return _data.end

var position: Vector3:
	set(value):
		render(AABB(value, _data.size))
	get:
		return _data.position

var size: Vector3:
	set(value):
		render(AABB(_data.position, value))
	get:
		return _data.size

func _init(value: AABB) -> void:
	render(value)

func _set_value(value: Variant) -> bool:
	assert(typeof(value) & TYPE_AABB)
	_data = value
	return true

func _get_value() -> Variant:
	return _data

func _get_property_list() -> Array[Dictionary]:
	return [
		{
			"name": "end",
			"type": TYPE_VECTOR3,
		},
		{
			"name": "position",
			"type": TYPE_VECTOR3,
		},
		{
			"name": "size",
			"type": TYPE_VECTOR3,
		},
	]