const DataTree = preload("./tree.gd")
const DataTreeTemplate = preload("./template.gd")
const DataNode = preload("../../core/data_node/base.gd")

const DataTreeOptions = preload("./options.gd")

const Struct = DataTreeOptions.Struct

const Observer = preload("../../core/observer/base.gd")
const ObserverPack = preload("../observer_pack/base.gd")

## 模板
var _template: DataTreeTemplate
## 根DataNode
var _root: DataNode

## 观察者包
## 包含被观察对象以及观察者模板
## 观察者包是与data_tree无关的，只有在需要时结合data_tree编译出观察者列表
var _observer_pack: ObserverPack
var _observers: Array[Observer]

## DataTree
## DataNode构成的树，包括了DataNode树以及绑定的Observer树
func _init(options) -> void:
	if options is DataTreeTemplate:
		_template = options
	else:
		_template = DataTreeTemplate.build(DataTreeOptions.build(options))
	_root = _template.to_data_node()

## 观察
## observer_pack: ObserverPack 所要观察的观察包
func observe(observer_pack: ObserverPack) -> void:
	_observers.clear()
	_observer_pack = observer_pack
	_observers = _observer_pack.compile(_root)

## 取消观察
func unobserve() -> void:
	_observer_pack = null
	_observers.clear()

## 是否正在观察
## 如果为false，表示这是一个孤立的DataTree
func is_observing() -> bool:
	return _observer_pack != null

## 复制
## include_observations: bool 是否包含观察树，如果包括，将复制一份观察树，保持对同一组数据的观察
func duplicate(include_observations: bool = false) -> DataTree:
	var result := DataTree.new(_template)
	if include_observations:
		if _observer_pack != null:
			assert(is_instance_valid(_observer_pack))
			result.observe(_observer_pack)
		else:
			push_warning("DataTree: Duplicate with observations, but this DataTree is not observing anything or observation is invalid.")
	return DataTree.new(_template)

func get_root() -> DataNode:
	return _root

## 数据树配置
static func opts(opts: Dictionary) -> DataTreeOptions:
	return DataTreeOptions.new(opts)

const VARIANT = DataTreeOptions.NodeType.VARIANT
const STRICT = DataTreeOptions.NodeType.STRICT
const STRUCT = DataTreeOptions.NodeType.STRUCT
const LIST = DataTreeOptions.NodeType.LIST
const DICT = DataTreeOptions.NodeType.DICT
const NODE = DataTreeOptions.NodeType.NODE
