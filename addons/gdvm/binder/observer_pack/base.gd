@abstract
extends RefCounted

const DataNode = preload("../../core/data_node/base.gd")
const Observer = preload("../../core/observer/base.gd")

## 观察者包
## opts 参数，格式由各个观察者包策略自行定义
@abstract
func _init(opts: Variant) -> void

## 编译
## 代入根data_node，生成观察者列表
@abstract
func compile(root: DataNode) -> Array[Observer]