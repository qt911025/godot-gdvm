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

监听对象的数组属性，这会为数组的每一个元素创建对应的子观察者。

.. code:: gd
	
	signal changed

	class TestList:
		var test_array: Array[TestObj]

	class TestObj:
		signal changed
		var a: int:
			set(value):
				a = value
				changed.emit()

	func _ready():
		var source_obj := TestList.new()
		var target_data_node := DataNodeList.new(TYPE_INT, func(): return DataNodeInt.new(0))
		var _observer := ObserverPropertyArray.new(
			source_obj,
			^":test_array",
			target_data_node,
			changed,
			func(source_element: Object, target_element: DataNode) -> Array:
				return [ObserverProperty.new(source_element, ^":a", target_element, source_element.changed)]
		)
		prints(target_data_node.size()) # 0
		var foo_element := TestObj.new()
		source_obj.test_array.append(foo_element)
		changed.emit()
		await get_tree().process_frame # 异步，等一帧
		prints(target_data_node.value()) # [0]
		prints(target_data_node.size()) # 1
		foo_element.a = 1
		await get_tree().process_frame # 异步，等一帧
		prints(target_data_node.value()) # [1]

属性字典型（PropertyDictionary）
----------------------------

``ObserverPropertyDictionary``

监听对象的字典属性，这会为字典的每一个值创建对应的子观察者。

.. code:: gd
	
	signal changed

	class TestDict:
		var test_dictionary: Dictionary[StringName, TestObj]

	class TestObj:
		signal changed
		var a: int:
			set(value):
				a = value
				changed.emit()

	func _ready() -> void:
		var source_obj := TestDict.new()
		var target_data_node := DataNodeDict.new(TYPE_STRING_NAME, TYPE_INT, func(): return DataNodeInt.new(0))
		var _observer := ObserverPropertyDictionary.new(
			source_obj,
			^":test_dictionary",
			target_data_node,
			changed,
			func(source_element: Object, target_element: DataNode) -> Array:
				return [ObserverProperty.new(source_element, ^":a", target_element, source_element.changed)]
		)
		prints(target_data_node.size()) # 0
		var foo_element := TestObj.new()
		source_obj.test_dictionary["new_element"] = foo_element
		changed.emit()
		await get_tree().process_frame # 异步，等一帧
		prints(target_data_node.value()) # {&"new_element": 0}
		prints(target_data_node.size()) # 1
		foo_element.a = 1
		await get_tree().process_frame # 异步，等一帧
		prints(target_data_node.value()) # {&"new_element": 1}

节点型（Node）
----------------------------

``ObserverNode``

监听节点的子节点，会为每一个子节点创建观察者。

因为节点自带子节点变化的信号，所以不需要手动指定变化信号。

.. code:: gd

	class TestSuperNode extends Node:
		pass

	class TestSubNode extends Node:
		signal changed
		var a: int:
			set(value):
				a = value
				changed.emit()

	func _ready() -> void:
		var source_obj := TestSuperNode.new()
		var target_data_node := DataNodeList.new(TYPE_INT, func(): return DataNodeInt.new(0))
		var _observer := ObserverNode.new(
			source_obj,
			target_data_node,
			func(source_child: Object, target_element: DataNode) -> Array:
				return [ObserverProperty.new(source_child, ^":a", target_element, source_child.changed)]
		)
		prints(target_data_node.size()) # 0
		var foo_child := TestSubNode.new()
		source_obj.add_child(foo_child)
		await get_tree().process_frame # 异步，等一帧
		prints(target_data_node.value()) # [0]
		prints(target_data_node.size()) # 1
		foo_child.a = 1
		await get_tree().process_frame # 异步，等一帧
		prints(target_data_node.value()) # [1]
		source_obj.queue_free()
