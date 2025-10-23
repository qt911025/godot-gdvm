Writer 进阶
=====================================

一个Writer只写一个属性。

属性数组型（PropertyArray）和属性字典型（PropertyDictionary）
----------------------------

绑定了这两种类型的写者， **如果元素是对象** ，则需要定义 **子写者** 。

写者与子写者构成了写者树，写者成员的增删会创建与释放子写者，同步元素对象的生灭。
所以需要回调函数定义如何构造子写者。

.. code:: gd
	
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

这个构造函数接受四个参数：目标对象、目标属性、源数据节点、元素子写者。

子写者需要现场构造，接受三个回调：

1. 目标元素对象申请回调：会传入新生成的源元素数据节点，需要创建目标元素对象并返回。
2. 子写者构造回调：会传入源元素数据节点和目标元素对象，应返回创建的子写者列表。
3. 目标元素对象释放回调（可选）：如果需要手动释放目标元素对象，则需要定义它。

如果是字典，则对应数组元素的是字典的值。

**注意：目标元素对象的申请和释放的过程完全由回调函数定义，回调函数外不会有任何额外的操作。**

如果目标元素对象既不是 ``RefCounted`` 也不是 ``Node`` ，则必须实现释放回调。

申请回调和释放回调也可以实现为池的形式。

.. code:: gd

	var _writer := WriterPropertyArray.new(
		target_obj,
		^":test_array",
		source_data_node,
		WriterPropertyArray.ElementSubWriter.new(
			func(element_data_node: DataNodeInt):
				var result := get_from_pool()
				result.a = element_data_node.value()
				return result
				,
			func(element_data_node: DataNodeInt, target_object: TestObj) -> Array:
				return [WriterProperty.new(target_object, ^":a", element_data_node)]
                ,
			func(target_object: TestObj) -> void:
				release_to_pool(target_object)
                )
	)

节点型（Node）
----------------------------

节点型同上，只不过不需要指定绑定的属性，因为节点就是绑定节点本身，且自带改变信号。

.. code:: gd

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

此外，释放回调函数应该有一个bool返回值，提示GDVM是否已经释放了这个子节点。