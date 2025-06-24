const WriterPack = preload("./base.gd")
const DataNode = preload("../../core/data_node/base.gd")

var _source_root: DataNode

## 写者包
## opts 参数，格式由各个观察者包策略自行定义
func _init(root: DataNode, opts: Variant) -> void:
	_source_root = root