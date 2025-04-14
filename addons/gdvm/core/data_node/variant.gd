## 泛类型数据节点
## 是VM树的叶子节点
extends DataNode
const DataNode = preload("./base.gd")

var _data: Variant

func _init(value: Variant) -> void:
	render(value)

## 渲染
## 设置本节点的数据
func _set_value(value: Variant) -> bool:
	# primitive是允许设置复杂数据的，用于不绑定的情况
	_data = value
	return true

## 取值
## 获取本节点的数据
func _get_value() -> Variant:
	return _data