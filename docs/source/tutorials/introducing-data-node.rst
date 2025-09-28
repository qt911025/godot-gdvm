数据节点 （Data Node） 入门
====================================

GDVM的核心是构建VM，并建立VM与自定义的Model和View之间的关系，
而 **数据节点（Data Node）** 就是构建VM的组件。

所有数据节点都继承自 ``DataNode``。

数据节点是一组封装好的数据结构，主要分为6种类型：

变体型（Variant）
----------------------------

``DataNodeVariant``

变体型包含一个Variant空间，如果是基础数据类型则保存的是其本身，如果是对象、字典、数组类则保存的是其引用。

Godot的Variant能保存什么，DataNodeVariant就能保存什么。

.. code:: gd

	var a := Gdvm.DataNodeVariant.new("hello world")

构造函数代入的值就是其初始值。

如果不需要跟踪内容的变化，变体型也可以保存对象、字典和数组。

严格型（Strict）
----------------------------

``DataNode[Type]``

一个Variant的存储空间是20字节，对于大多数基础数据类型并无必要。

所以对于基础数据类型，应该用类型对应的严格型DataNode保存。

严格型只支持基础数据类型，而不支持对象、字典、数组类型。

严格型的DataNode即 ``DataNode[类型]``，如： ``DataNodeInt`` ``DataNodeVector2`` 等。

所有严格型都继承自 ``DataNodeStrict``。

.. code:: gd

	var a := Gdvm.DataNodeInt.new(100)

列表型（List）
----------------------------

``DataNodeList``

如果需要跟踪列表元素的变化，可以使用 ``DataNodeList``。

``DataNodeList``的元素也是DataNode，每个元素都跟踪其变化。

创建DataNodeList需要显式指定元素的类型（ :ref:`GDVM风格的 <gdvm_style_data_type>` ），以及一个元素DataNode的工厂函数。

.. code:: gd

	var a := Gdvm.DataNodeList.new(TYPE_INT, func():
		return Gdvm.DataNodeInt.new(0)
	)

字典型（Dict）
----------------------------

``DataNodeDict``

如果需要跟踪字典元素的变化，可以使用 ``DataNodeDict``。

``DataNodeDict``的元素也是DataNode，每个元素都跟踪其变化。

创建DataNodeDict需要显式指定键的类型、值的类型，以及一个值DataNode的工厂函数。

.. code:: gd

	var a := Gdvm.DataNodeDict.new(null, TYPE_INT, func():
		return Gdvm.DataNodeInt.new(0)
	)

这里的键类型可以是 ``null`` ，代表不限定键的类型，即键是一个Variant，值也可以这么设置。

结构型（Struct）
----------------------------

``DataNodeStruct``

结构型是将数据型节点整合成树的关键类型，会将数据组合成结构体。

有别于字典型，字典型可以随意增删成员，且类型固定。
而结构型增删成员会更麻烦些，且结构型的“键”（属性）只能是String或StringName类型的
（是StringName，String会隐式转换成StringName）。

.. code:: gd

	var a := Gdvm.DataNodeStruct.new()
	a.add_property("name", Gdvm.DataNodeString.new("hello"))
	a.add_property("age", Gdvm.DataNodeInt.new(18))
	
	var b := Gdvm.DataNodeStruct.new()
	b.add_property("info", a)
	b.add_property("score", Gdvm.DataNodeFloat.new(99.5))

节点型（Node）
----------------------------

``DataNodeNode``

节点型是专门用于绑定节点的，因为节点既有属性也有子节点，所以需要同时具有结构型和列表型的特性。

``DataNodeNode`` 继承自 ``DataNodeStruct``，可以使用 ``DataNodeStruct`` 的所有方法。

如果要获取子节点的数据结构，可以调用 ``children()`` 获取。
得到的是一个 ``DataNodeList`` 。

``DataNodeNode`` 的构造函数需要指定子节点的数据类型和一个工厂函数，用于子节点的生成。

.. code:: gd

	var a := Gdvm.DataNodeNode.new(TYPE_INT, func():
		return Gdvm.DataNodeInt.new(0)
	)

	a.add_property("name", Gdvm.DataNodeString.new("hello"))
	a.add_property("age", Gdvm.DataNodeInt.new(18))
	
	# 获取子节点
	var children := b.children()

读与写
----------------------------

写入数据节点的方法是 ``render()``，读取数据节点的方法是 ``value()``。

写入时需要自行确定数据类型是否匹配。

.. code:: gd

	var a := Gdvm.DataNodeInt.new(100)
	a.render(200)  # 写入数据
	var b := a.value()  # 读取数据
	prints(b)  # 输出：200

	# a.render("hello")  # 错误：类型不匹配

可将一整套组织好的数据，以字典的形式写入一个DataNodeStruct。

.. code:: gd

	var a := Gdvm.DataNodeStruct.new()
	a.add_property("name", Gdvm.DataNodeString.new("hello"))
	a.add_property("age", Gdvm.DataNodeInt.new(18))
	a.render({
		"name": "Zhang San",
		"age": 30,
	})

	var b := a.value()  # 读取数据
	prints(b)  # 输出：{"name": "Zhang San", "age": 30}