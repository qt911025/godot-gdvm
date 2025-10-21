Data Node 进阶
========================

严格型（Strict）
----------------------------

严格型有哪些类型？

在 `Variant.Type枚举 <https://docs.godotengine.org/en/4.4/classes/class_@globalscope.html#enum-globalscope-variant-type>`_ 里，
大于 ``TYPE_NIL`` 小于 ``TYPE_OBJECT`` 的类型，都是严格型。

可用 ``Gdvm.Utils`` 的 ``type_has_strict_data_node`` 和 ``instance_has_strict_data_node`` 判断类型或实例是否为严格型。

列表型（List）与字典型（Dict）
----------------------------

列表型与字典型都实现了数组与字典大部分方法，一些方法的命名会与原版有差异。

详见API注释。

结构型（Struct）
----------------------------

结构型将数据整合成结构体的方式是添加属性，添加属性之后才能分配其值。

.. code:: gd
	var a := Gdvm.DataNodeStruct.new()
	a.add_property("name", Gdvm.DataNodeString.new("hello"))

添加的属性可以移除。

.. code:: gd
	a.remove_property("name")

可以添加 **计算属性** 。

为了作区分，又称狭义的 **属性** 为 **数据属性** 。

.. code:: gd
	struct.add_computed_properties(
		["a", "b"],
		{
			"a_plus_b": a_plus_b,
			"a_minus_b": a_minus_b
		},
		func(dependencies: Dictionary, outputs: Dictionary) -> void:
			(outputs["a_plus_b"] as DataNode).render(dependencies["a"] + dependencies["b"])
			(outputs["a_minus_b"] as DataNode).render(dependencies["a"] - dependencies["b"])
	)

计算属性实现了类似Vue的computed功能，会随着所依赖属性的变化重新计算。

add_computed_properties 方法接受三个参数：
1. 依赖属性列表
2. 计算属性列表
3. 计算属性的计算函数

依赖属性必须已存在于结构体中。

计算属性接受一个字典，键是要定义的计算属性，值是计算属性的DataNode。

计算属性的计算函数接收两个参数：

第一个参数是所依赖属性的字典，键为依赖项，值为依赖项的值（不会暴露依赖项的DataNode，保证只读）；
第二个参数是计算属性的字典，键为计算属性，值为计算属性的DataNode，计算函数应当直接将结果渲染给计算属性。

**值**

结构型的 **值** 是一个字典，键为属性，值为属性的值。

取值会得到所有数据属性和计算属性，而渲染只会渲染数据属性。

节点型（Node）
----------------------------

节点型节点就是一个结构型节点聚合了一个列表型节点。

为了不与任何属性重名，节点的子节点列表是通过方法（ ``children()`` ）获取的。

节点的值是内部定义的 ``NodeDataBucket`` 类型。

渲染函数可接受 ``NodeDataBucket`` 类型，同时渲染属性和子节点；
也可仅接受字典或对象，仅渲染属性；
也可仅接受列表，仅渲染子节点。