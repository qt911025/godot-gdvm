观察者 （Observer） 入门
=====================================

**观察者** 是一种监听原版数据，并同步到数据节点的 :ref:`关系 <relationship>` 。

观察者观察目标对象的某个属性或者子节点，当观察对象发生改变，
并且向观察者发送信号通知改变时，观察者会读取被观察对象的数据，写入关联的数据节点。

所以一个观察者有三个基本要素，源数据、目标数据节点、改变信号。

改变信号是一个无参数信号。

观察者默认有四种类型，都继承自观察者基类 ``Observer``。

属性型（Property）
----------------------------

``ObserverProperty``

属性型只监听一个属性，既支持基础数据类型，也支持对象、字典和数组类型。

下面这个例子就是用一个DataNodeVariant来监听一个TestObj的 ``a`` 属性。

.. code:: gd

	signal changed

	class TestObj:
		var a: int

	# ...

	func _ready():
		var source_obj := TestObj.new()
		var target_data_node := DataNodeVariant.new(null)
		prints(target_data_node.value()) # null
		var _observer := ObserverProperty.new(source_obj, ^"a", target_data_node, changed)

		source_obj.a = 1
		changed.emit()
		prints(target_data_node.value()) # 1

监听的是对象时，属性监听的值是对这个对象引用的改变。

如果监听的属性留空，则监听的是这个对象本身，同步数据就是将对象本身渲染到目标数据节点上。

.. code:: gd

	func _ready():
		var source_obj := TestObj.new()
		var target_data_node := DataNodeStruct.new()
		target_data_node.add_property("a", DataNodeInt.new(0))
		prints(target_data_node.value()) # {"a": 0}
		var _observer := ObserverProperty.new(source_obj, ^"", target_data_node, changed)
		
		source_obj.a = 1
		changed.emit()
		await get_tree().process_frame # Struct updates asynchronously
		prints(target_data_node.value()) # {"a": 1}

如果监听的数组和字典的元素不需要加监听者，也用属性型来监听。

.. code:: gd
	
	signal changed
	class ObjWithArray:
		var array: Array

	func _ready():
		var source_obj := ObjWithArray.new()
		var target_data_node := DataNodeList.new(TYPE_INT, func(): return DataNodeInt.new(0))
		prints(target_data_node.value()) # []
		var _observer := ObserverProperty.new(source_obj, ^"array", target_data_node, changed)

		source_obj.array = [1, 2, 3]
		changed.emit()
		prints(target_data_node.value()) # [1, 2, 3]

这一般用于数组的元素以及字典的值不是对象时。如果是对象，应该用下面两种。

属性数组型（PropertyArray）
----------------------------

``ObserverPropertyArray``

属性字典型（PropertyDictionary）
----------------------------

``ObserverPropertyDictionary``

节点型（Node）
----------------------------

``ObserverNode``