const Binder = preload("./base.gd")

const DataNode = preload('../core/data_node/base.gd')
const Writer = preload('../core/writer/base.gd')

const RawPin = preload('./pin/raw.gd')
const ExtraPin = preload('./pin/extra.gd')
const Compiler = preload('./compiler.gd')

# const Utils = preload('../../utils.gd');

var _base: Object
var base: Object:
	set(value):
		pass
	get:
		return _base

var _data: DataNode
var data: DataNode:
	set(value):
		pass
	get:
		return _data

var _writers: Array[Writer]

func _init(object: Object, options: Dictionary) -> void:
	# assert(not has_gdvm(node), "Node: %s has already registered a gdvm" % [node])
	_base = object

	# data
	assert(options.has("data"))

	var raw_pin := RawPin.build(options.data)
	var extra_pin := ExtraPin.build(_base, raw_pin)
	_data = extra_pin.pure_pin.to_data_node()
	var compiler := Compiler.new(_base, extra_pin, _data)
	_writers = compiler.writers
