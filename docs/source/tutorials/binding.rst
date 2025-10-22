绑定 （Binding）
========================

学习了数据节点、观察者、写者之后，你会发现仅仅是绑定少数几个属性都需要编写大量代码，
还不如不用这个框架。

别急，以上只是提供了基本的绑定框架，让你可以更自由地自定义绑定形式。
如果你想要更方便、代码更少的绑定，GDVM提供了更高级的封装。

Godot通过子节点与属性构建出树状的数据结构，GDVM也使用了相配套的组织形式。
数据节点、观察者和写者将构建成三棵树，与Godot的树建立绑定。

示例7（ ``examples/_7_pure_script`` ）提供了一个完整的例子，无需编辑场景，单Node场景就能运行如下代码。

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
				if value != data:
					# 防死循环设计
					data = value
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