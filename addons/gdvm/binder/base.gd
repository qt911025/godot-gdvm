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

	# node.set_meta("__gdvm__", self)

# todo 
# 1. 自动绑observer，observer挂载在data node上
# 1.1 新的observer(node:观察子节点创建；array；dictionary；)
# 2. computed (data node) 是一个复合struct，包括若干入口值（读写），若干出口值（只读）
# 3. callable (writer) 是一个多入口写者，缓存所有参数值，观察多个data node，只要有一个data node改变就触发callable
# 4. 向外暴露属性，看看gut的double是怎么实现的
# 5. 强制从某个节点开始不绑
# *. vue还有啥？