@abstract
extends RefCounted

## 写者
const DataNode = preload("../data_node/base.gd")

# 写者代表的是“DataNode -> 任何对象”，可作为MVVM的末端，也可作为DataNode到另一个DataNode的代理
# 直接观察data_node

var _target_ref: WeakRef
# var _data_node_ref: WeakRef

@abstract
func _init()
