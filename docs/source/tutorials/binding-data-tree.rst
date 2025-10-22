数据树 （Data Tree）
=====================================

在Binder里，以 ``DataNodeStruct`` 聚合起来的树状数据模型会被封装成 ``DataTree`` ，通过配置可快速构建。

.. code:: gd

	var tree := DataTree.new(DataTree.opts({
		"properties": {
			"a": Vector2(),
			"b": Color(),
		},
		"children": PackedStringArray()
	}))

构造函数
###########################

DataTree的构造函数接受三种参数：

样板
**************************

当代入的是除 ``DataTreeOptions`` 和 ``DataTreeTemplate`` 外的任意类型时，参数会被视为样板。

样板的值作为数据树的初始值，样板的数据结构会被解析为对应结构的数据树。

.. code:: gd

	var tree := DataTree.new({
		"example_string": "example_string",
		"example_int": 1,
	})

这个例子会被解析为一个带有两个数据属性的``DataNodeStruct``,
其中 ``example_string`` 是 ``DataNodeString`` ， ``example_int`` 是 ``DataNodeInt`` 。

一般带类型的基础数据类型都会被识别为严格型，如果想要 ``DataNodeVariant`` ，请用 ``null``或者对象。

数组以及其他PackedArray会被识别为 ``DataNodeList``。

字典则分情况，像上面这种有以 **非空** ``String`` 或 ``StringName`` 为键的字典会被识别为 ``DataNodeStruct`` ，
其他字典会被识别为 ``DataNodeDict`` 。

DataTreeOptions
**************************

当不需要传入其他信息，只需要传入数据结构定义时，用样板即可。

如果要定义 ``DataNodeNode`` ，则需要传入额外信息，需要显式构造配置对象（ ``DataTreeOptions`` ）。

直接用 ``DataTreeOptions.new()`` 太长，可以用 ``DataTree.opts()`` 简写。

构造函数接受一个字典作为参数，用字典的键指定配置项。

.. code:: gd

	var tree := DataTree.new(DataTree.opts({
		"properties": {
			"a": Vector2(),
			"b": Color(),
		},
		"children": PackedStringArray()
	}))

配置项有：

``properties``
+++++++++++++++++++++++++++++++

数据属性

只接受以字符串为键的字典，定义为 ``DataNodeStruct`` 。值为样板或 ``DataTreeOptions`` ，可嵌套定义。

``children``
+++++++++++++++++++++++++++++++

子节点

只接受数组，数组类型会被解析为指定类型的 ``DataNodeList`` 或 ``DataNodeNode`` 。

如果数组是无类型的，一般需要包含一个元素来定义子节点，可以是样板或 ``DataTreeOptions``，可嵌套定义。

.. code:: gd

	var test_opts := DataTreeOptions.new({
		"properties": {
			"health": 0,
			"name": ""
		},
		"children": [0.0]
	})

这个例子里， ``children`` 内包含了 ``0.0`` 这个样板，创建的 ``DataNodeNode`` 的子节点 ``DataNodeList`` 的元素数据节点会是 ``DataNodeFloat``。

``data``
+++++++++++++++++++++++++++++++

数据

接受任何样板格式，即使是单个 ``int`` 都行。

如果被识别为 ``properties`` 或者 ``children`` 类型，会被指派到对应配置项。
也就是说只要格式匹配， ``data`` 会代替 ``properties`` 或者 ``children``。

``type``
+++++++++++++++++++++++++++++++

节点类型

大多数情况下， ``type`` 会自动根据识别的数据结构补全。
如果需要自行定义，需要显式指定。

节点类型有：

- ``DataTree.VARIANT``
- ``DataTree.STRICT``
- ``DataTree.STRUCT``
- ``DataTree.LIST``
- ``DataTree.DICT``
- ``DataTree.NODE``

``computed``
+++++++++++++++++++++++++++++++

计算属性

是一个列表，每一个元素是 ``DataNodeStruct`` 添加计算属性所需的参数。

所依赖的数据属性都会事先定义，而依赖的计算属性无需关心定义的先后。
GDVM会自动排序，也会自动识别错误依赖。

.. code:: gd

	var tree := DataTree.new(DataTree.opts({
		"data": {
			"a": "aaa",
			"b": 1,
		},
		"computed": [ {
			"dependencies": ["a", "b"],
			"outputs": {
				"a_plus_b": 0, # 定义了类型
				"a_minus_b": 0
			},
			"computer": func(dependencies: Dictionary, outputs: Dictionary) -> void:
				(outputs["a_plus_b"] as DataNode).render(dependencies["a"].length() + dependencies["b"])
				(outputs["a_minus_b"] as DataNode).render(dependencies["a"].length() - dependencies["b"])
				}],
	}))

``DataTreeTemplate``
********************************

前两种形式会自动创建 ``DataTreeTemplate`` ，如果你需要自定义构建它，或者复用，可以代入 ``DataTreeTemplate`` 。

获取根数据节点
###########################

调用 ``get_root()`` 方法获取根部 ``DataNode``。

观察
################

调用``observe()``方法建立观察关系，代入的参数是已创建的 :ref:`观察者包 <binding_observer_pack>` 。

.. code:: gd

	class ObjWithInt:
		signal changed
		var data: int:
			set(value):
				data = value
				changed.emit()

	# ...

	func _ready() -> void:
		var source_obj := ObjWithInt.new()
		var tree := DataTree.new(42)
		var observer := ObserverPackTree.new({
			"base": source_obj,
			"options": ObserverPackTree.opts({
				"path": ":data",
				"changed": func(source: Object, _property_path: NodePath) -> Signal:
					return (source as ObjWithInt).changed
					})
		})
		tree.observe(observer)

调用 ``unobserve()`` 方法取消观察关系。

调用 ``is_observing()`` 方法检查是否正在观察。

复制
################

调用 ``duplicate()`` 方法复制数据树。

接受一个参数 ``include_observations`` ，决定是否复制观察关系。