建立双向数据绑定注意事项
========================================

基本数据类型的的读写是同步执行的，只有向 :doc:`大小树 </theory/tree-like-data-structure>` 的上级更新状态才是异步的。

这也意味着直接同时对一个原始数据绑定观察者和写者，会导致死锁。

.. code:: gd

	extends Node

	const Utils = Gdvm.Utils
	const DataTree = Gdvm.DataTree
	const ObserverPackTree = Gdvm.ObserverPackTree
	const WriterPackTree = Gdvm.WriterPackTree

	const DataNode = Gdvm.DataNode
	const DataNodeInt = Gdvm.DataNodeInt

	class ObjWithInt:
		signal changed
		var data: int:
			set(value):
				data = value # !!!!!!!!!!!!!!!!!
				changed.emit()

	func _ready() -> void:
		var obj := ObjWithInt.new()
		var data_tree := DataTree.new(0)
		var observer := ObserverPackTree.new({
			"base": obj,
			"options": ObserverPackTree.opts({
				"path": ":data",
				"changed": func(source: Object, _property_path: NodePath) -> Signal:
					return (source as ObjWithInt).changed
					})
		})
		data_tree.observe(observer)
		var root := data_tree.get_root() as DataNodeInt
		var _writer := WriterPackTree.new(root, {
			"base": obj,
			"options": WriterPackTree.opts({
				"path": ":data"
				})
		})
		prints("Initial data node value:", root.value()) # 0
		prints("Initial target value:", obj.data) # 0
		root.render(1)
		prints("Root rendered node value:", root.value()) # 1
		prints("Root rendered target value:", obj.data) # 1
		obj.data = 2
		prints("Target changed node value:", root.value()) # 2
		prints("Target changed target value:", obj.data) # 2

为此，你应该额外写一个卫士来防止重复修改，把 ``data`` 属性改成这样：

.. code:: gd

	var data: int:
		set(value):
			if value != data:
				# 防死循环设计
				data = value
				changed.emit()

单项数据绑定是GDVM的核心规则之一，所以不太推荐有双向数据绑定需求的场景使用它。