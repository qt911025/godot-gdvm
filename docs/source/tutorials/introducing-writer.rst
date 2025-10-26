写者 （Writer） 入门
====================================

**写者** 是一种将数据节点的数据同步到原版数据的 :doc:`关系 </theory/relationship>` 。

写者观察数据节点，绑定目标数据，当观察的数据节点发生改变，
写者会读取数据节点的数据，写入目标数据。

数据节点自带改变信号，所以一个写者有两个基本要素，源数据节点、目标数据。

写者默认有四种类型，都继承自写者基类 ``Writer``。

属性型（Property）
----------------------------

``WriterProperty``

属性型只同步一个属性，有别于属性型观察者，属性型写者只支持基础数据类型。

下面这个例子就是用一个DataNodeInt来将数据同步到TestObj的 ``a`` 属性。

.. code:: gd

	class TestObj:
		var a: int

	# ...

	func _ready():
		var target_obj := TestObj.new()
		var source_data_node := DataNodeInt.new(0)
		prints(target_obj.a) # 0

		var _writer := WriterProperty.new(target_obj, ^"a", source_data_node)
		source_data_node.render(1)
		prints(target_obj.a) # 1

属性数组型（PropertyArray）
----------------------------

``WriterPropertyArray``

将数组型数据节点同步到目标对象的数组类型成员。

简单数组，也就是元素是基本数据类型的数组，无需指定子写者。

.. code:: gd

	class TestSimpleList:
		var test_array: Array[int]

	# ...

	func _ready() -> void:
		var target_obj := TestSimpleList.new()
		var source_data_node := DataNodeList.new(TYPE_INT, func(): return DataNodeInt.new(0))

		var _writer := WriterPropertyArray.new(target_obj, ^":test_array", source_data_node)
		prints(target_obj.test_array) # []
		source_data_node.append(1)
		await get_tree().process_frame # Struct updates asynchronously
		prints(target_obj.test_array) # [1]

元素是对象的数组，需要指定子写者。

.. code:: gd

	class TestList:
		var test_array: Array[TestObj]

	class TestObj:
		var a: int

	# ...

	func _ready() -> void:
		var target_obj := TestList.new()
		var source_data_node := DataNodeList.new(TYPE_INT, func(): return DataNodeInt.new(0))
		var _writer := WriterPropertyArray.new(
			target_obj,
			^":test_array",
			source_data_node,
			WriterPropertyArray.ElementSubWriter.new(
				func(element_data_node: DataNodeInt):
					var result := TestObj.new()
					result.a = element_data_node.value()
					return result
					,
				func(element_data_node: DataNodeInt, target_object: TestObj) -> Array:
					return [WriterProperty.new(target_object, ^":a", element_data_node)]
					)
		)

		prints(target_obj.test_array) # []
		source_data_node.append(1)

		await get_tree().process_frame # Struct updates asynchronously
		prints(target_obj.test_array.size()) # 1
		prints(target_obj.test_array[0].a) # 1


属性字典型（PropertyDictionary）
----------------------------

 ``WriterPropertyDictionary``

 将字典型数据节点同步到目标对象的字典类型成员。

 简单字典，也就是元素是基本数据类型的字典，无需指定子写者。

 .. code:: gd

	class TestSimpleDictionary:
		var test_dictionary: Dictionary[StringName, int]

	# ...

	func _ready() -> void:
		var target_obj := TestSimpleDictionary.new()
		var source_data_node := DataNodeDict.new(TYPE_STRING_NAME, TYPE_INT, func(): return DataNodeInt.new(0))

		var _writer := WriterPropertyDictionary.new(target_obj, ^":test_dictionary", source_data_node)
		prints(target_obj.test_dictionary) # {}
		source_data_node.set_element(&"new_element", 1)

		await get_tree().process_frame # Struct updates asynchronously
		prints(target_obj.test_dictionary) # {&"new_element": 1}

值是对象的字典，需要指定子写者。键没有子写者。

.. code:: gd
	
	class TestDictionary:
		var test_dictionary: Dictionary[StringName, TestObj]

	class TestObj:
		var a: int

	# ...

	func _ready() -> void:
		var target_obj := TestDictionary.new()
		var source_data_node := DataNodeDict.new(TYPE_STRING_NAME, TYPE_INT, func(): return DataNodeInt.new(0))
		var _writer := WriterPropertyDictionary.new(
			target_obj,
			^":test_dictionary",
			source_data_node,
			WriterPropertyDictionary.ElementSubWriter.new(
				func(element_data_node: DataNodeInt):
					var result := TestObj.new()
					result.a = element_data_node.value()
					return result
					,
				func(element_data_node: DataNodeInt, target_object: TestObj) -> Array:
					return [WriterProperty.new(target_object, ^":a", element_data_node)]
					)
		)
		prints(target_obj.test_dictionary) # {}
		source_data_node.set_element(&"new_element", 1)
		await get_tree().process_frame # Struct updates asynchronously
		prints(target_obj.test_dictionary.size()) # 1
		prints(target_obj.test_dictionary[&"new_element"].a) # 1

节点型（Node）
----------------------------

``WriterNode``

将节点型数据节点同步到目标节点。

只负责子节点的增删排序。

.. code:: gd

	class TestSuperNode extends Node:
		pass

	class TestSubNode extends Node:
		var a: int

	# ...

	func _ready() -> void:
		var target_obj := TestSuperNode.new()
		var source_data_node := DataNodeList.new(TYPE_INT, func(): return DataNodeInt.new(0))
		var _writer := WriterNode.new(
			target_obj,
			source_data_node,
			WriterNode.ChildSubWriter.new(
				func(chlid_data_node: DataNodeInt) -> Node:
					var result := TestSubNode.new()
					result.a = chlid_data_node.value()
					return result
					,
				func(chlid_data_node: DataNodeInt, target_node: Node) -> Array:
					return [WriterProperty.new(target_node, ^":a", chlid_data_node)]
					)
		)
		prints(target_obj.get_child_count()) # 0
		source_data_node.append(1)
		await get_tree().process_frame # Struct updates asynchronously
		prints(target_obj.get_child_count()) # 1
		prints(target_obj.get_child(0).a) # 1
		target_obj.queue_free()