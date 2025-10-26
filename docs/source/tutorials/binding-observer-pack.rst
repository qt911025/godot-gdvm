观察者包 （Observer Pack）
=====================================

观察者包可以规范地建立起对一个数据结构的观察关系。

观察者包的存在仅依赖于其观察的数据，与关联的数据树相互独立。

观察者包创建后无法改变，要修改必须重新创建。

GDVM默认实现了树型的观察者包，即 ``ObserverPackTree`` ，以下是 ``ObserverPackTree`` 的文档。

构造函数
###########################

构造函数接受一个字典作为参数，用字典的键指定配置项。

配置项有：

``base``
*********************************

被观察对象

观察的目标是树状的数据结构，必须以对象为根。

``options``
*********************************

配置项

只接受内部定义的配置项对象类型，通过 ``ObserverPackTree.opts()`` 创建。

.. code:: gd

    var observer := ObserverPackTree.new({
		"base": source_obj,
		"options": ObserverPackTree.opts({
			"path": ":data",
			"changed": func(source: Object, _property_path: NodePath) -> Signal:
				return (source as ObjWithInt).changed
				})
	})

如果配置里只包含要绑定的属性，即配置项只有 ``properties`` ，可以直接简写为字典。

.. code:: gd

	var observer := ObserverPackTree.new({
		"base": source_obj,
		"options": {
			"foo": ObserverPackTree.opts({
				"path": ":a:data",
				"changed": func(source: Object, _property_path: NodePath) -> Signal:
					return (source.a as ObjWithInt).changed
					}),
			"bar": ObserverPackTree.opts({
				"path": ":b:data",
				"changed": func(source: Object, _property_path: NodePath) -> Signal:
					return (source.b as ObjWithInt).changed
					}),
		}
	})

配置项有：

``properties``
+++++++++++++++++++++++++++++++

声明绑定的 ``DataNodeStruct`` 属性，可嵌套定义。

组织的树状结构应该与要绑定的数据树匹配。

.. code:: gd

    var observer := ObserverPackTree.new({
		"base": source_obj,
		"options": ObserverPackTree.opts({
			"properties": {
				"data": ObserverPackTree.opts({
					"changed": func(source: Object, _property_path: NodePath) -> Signal:
						return (source as SuperNode).changed
						}),
			},
			"children": ObserverPackTree.opts({
				"path": ":a",
				"changed": func(source: Object, _property_path: NodePath) -> Signal:
					return (source as SubNode).changed
					})
		})
	})

这个例子声明了这个观察者接受一个带 ``data`` 属性的 ``DataNodeNode`` 绑定，
数据节点的 ``data`` 会绑定到源数据 **基对象** （即base指定的对象）的 ``data`` 属性（未指定path则自动寻找同名绑定）。

``children``
+++++++++++++++++++++++++++++++

声明绑定的子节点模板，用于数组、字典、节点。

格式同 ``properties`` 的某个属性。

.. code:: gd

	var observer := ObserverPackTree.new({
		"base": source_obj,
		"options": ObserverPackTree.opts({
			"type": ObserverPackTree.NODE,
			"children": ObserverPackTree.opts({
				"type": ObserverPackTree.PROPERTY,
				"path": ":a",
				"changed": func(source: Object, _property_path: NodePath) -> Signal:
					return (source as SubNode).changed
					})
		})
	})

``path``
+++++++++++++++++++++++++++++++

相对绑定路径

.. code:: gd

	var observer := ObserverPackTree.new({
		"base": source_obj,
		"options": ObserverPackTree.opts({
			"path": ":data",
			"changed": func(source: Object, _property_path: NodePath) -> Signal:
				return (source as ObjWithInt).changed
				})
	})

这个相对路径是相对于最近显式定义的同一个 :doc:`小树 </theory/tree-like-data-structure>` 内的路径。
绝对路径就是将同一个:doc:`小树 </theory/tree-like-data-structure>`的路径拼接成 **NodePath** 格式的路径。

路径的开头可以是 ``/`` 或者 ``:``，如果不写的话，GDVM会根据特定的规则
（上级的最后是属性则为 ``:`` ，其他情况为 ``/`` ）补全。

为了避免歧义，建议尽量显式写明开头。

``type``
+++++++++++++++++++++++++++++++

节点类型

仅 :doc:`小树 </theory/tree-like-data-structure>` **叶子** 节点，需要指定类型。

如果提供的配置信息充足， ``type`` 会自动根据识别的数据结构补全。

如果需要自行定义，需要显式指定。

节点类型有：

- ``ObserverPackTree.PROPERTY``
- ``ObserverPackTree.PROPERTY_ARRAY``
- ``ObserverPackTree.PROPERTY_DICTIONARY``
- ``ObserverPackTree.NODE``

``changed``
+++++++++++++++++++++++++++++++

改变信号获取回调

列表、字典、节点的元素并不是一开始就有的，只有在创建时才会得到其实例，而改变信号往往在这些实例中。
所以需要一个回调来动态获取。

回调是这种形式的：

.. code:: gd

	func(source: Object, _property_path: NodePath) -> Signal:
		return (source.b as ObjWithInt).changed

第一个参数（ ``source`` ）是源对象（小树的根），
第二个参数（ ``property_path`` ）是绝对绑定路径（本小树），当然也可以不用这个路径，而是自行索引到小树内的另一个路径。