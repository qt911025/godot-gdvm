extends DataNodeStrict
const DataNodeStrict = preload("./base.gd")

var _data: Color

var a: float:
	set(value):
		render(Color(_data, value))
	get:
		return _data.a

var a8: int:
	set(value):
		var result := _data
		_data.a8 = value
		render(result)
	get:
		return _data.a8

var r: float:
	set(value):
		render(Color(value, _data.g, _data.b, _data.a))
	get:
		return _data.r

var r8: int:
	set(value):
		var result := _data
		_data.r8 = value
		render(result)
	get:
		return _data.r8

var g: float:
	set(value):
		render(Color(_data.r, value, _data.b, _data.a))
	get:
		return _data.g

var g8: int:
	set(value):
		var result := _data
		_data.g8 = value
		render(result)
	get:
		return _data.g8

var b: float:
	set(value):
		render(Color(_data.r, _data.g, value, _data.a))
	get:
		return _data.b

var b8: int:
	set(value):
		var result := _data
		_data.b8 = value
		render(result)
	get:
		return _data.b8

var h: float:
	set(value):
		var result := _data
		_data.h = value
		render(result)
	get:
		return _data.h

var s: float:
	set(value):
		var result := _data
		_data.s = value
		render(result)
	get:
		return _data.s

var v: float:
	set(value):
		var result := _data
		_data.v = value
		render(result)
	get:
		return _data.v

var ok_hsl_h: float:
	set(value):
		var result := _data
		_data.ok_hsl_h = value
		render(result)
	get:
		return _data.ok_hsl_h

var ok_hsl_s: float:
	set(value):
		var result := _data
		_data.ok_hsl_s = value
		render(result)
	get:
		return _data.ok_hsl_s

var ok_hsl_l: float:
	set(value):
		var result := _data
		_data.ok_hsl_l = value
		render(result)
	get:
		return _data.ok_hsl_l
		
func _init(value: Color) -> void:
	render(value)

func _set_value(value: Variant) -> bool:
	assert(typeof(value) & TYPE_COLOR)
	_data = value
	return true

func _get_value() -> Variant:
	return _data

func _get_property_list() -> Array[Dictionary]:
	return [
		{
			"name": "a",
			"type": TYPE_FLOAT,
		},
		{
			"name": "r8",
			"type": TYPE_INT,
		},
		{
			"name": "r",
			"type": TYPE_FLOAT,
		},
		{
			"name": "r8",
			"type": TYPE_INT,
		},
		{
			"name": "g",
			"type": TYPE_FLOAT,
		},
		{
			"name": "g8",
			"type": TYPE_INT,
		},
		{
			"name": "b",
			"type": TYPE_FLOAT,
		},
		{
			"name": "b8",
			"type": TYPE_INT,
		},
		{
			"name": "h",
			"type": TYPE_FLOAT,
		},
		{
			"name": "s",
			"type": TYPE_FLOAT,
		},
		{
			"name": "v",
			"type": TYPE_FLOAT,
		},
		{
			"name": "ok_hsl_h",
			"type": TYPE_FLOAT,
		},
		{
			"name": "ok_hsl_s",
			"type": TYPE_FLOAT,
		},
		{
			"name": "ok_hsl_l",
			"type": TYPE_FLOAT,
		},
	]