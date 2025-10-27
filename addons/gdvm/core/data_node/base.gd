@abstract
extends RefCounted

const DataNode = preload("./base.gd")
## 数据节点

# VM的核心组件
# 只存取数据
# 其他功能需要装饰数据节点来完成

signal changed(this: DataNode)

## 缓存数据是否已过期
var _outdated: bool = true
## 缓存数据
var _cached_data: Variant = null

@abstract
func _init() -> void

## 渲染
## 设置本节点的数据
func render(value: Variant) -> void:
	if value is DataNode:
		value = (value as DataNode).value()
	if _set_value(value):
		mark_changed()

## 设置值（渲染钩子）
## 返回值代表成功与否（失败但不算错误）
## 覆盖实现它
@abstract
func _set_value(value: Variant) -> bool

## 取值
## 获取本节点的数据
func value() -> Variant:
	if _outdated:
		_cached_data = _get_value()
		_outdated = false
	return _cached_data

## 取值钩子
## 覆盖实现它
@abstract
func _get_value() -> Variant

## 数据是否已过期
func is_outdated() -> bool:
	return _outdated

## 通知改变
## 数据改变后会通知，可以手动触发
func mark_changed() -> void:
	 # 即使outdated本来就是true，依然要发送，因为提醒的写者不一定会调动你的value()，只有调动value才会拨回来，这种情况就拨不回来
	_outdated = true
	changed.emit(self)

# static func build_data_node(value: Variant) -> DataNode:
# 	if value is DataNode:
# 		value = (value as DataNode).value()
# 	match typeof(value):
# 		TYPE_DICTIONARY:
# 			return preload("./struct.gd").from_dictionary(value) # 未来会加入其他复合的基础类型，如Vector2
# 		TYPE_ARRAY:
# 			return preload("./list.gd").new(value)
# 		_: # 包括Object的引用，单一数据
# 			return preload("./variant.gd").new(value) # 未来会加入强类型
