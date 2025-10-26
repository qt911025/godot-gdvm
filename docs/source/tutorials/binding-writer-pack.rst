写者包 （Writer Pack）
=====================================

写者包可以规范地建立起将数据树的数据同步到同构目标数据的关系。

写者包必须依赖已构建的数据树创建，且创建后不能改变，必须抛弃后重新创建。

GDVM默认实现了树型的写者包，即 ``WriterPackTree`` ，以下是 ``WriterPackTree`` 的文档。

构造函数
###########################

构造函数接受 **两个参数** ，第一个是数据树的 **根节点** ，第二个是 **配置项** 。

配置项，是一个字典，格式类似 ``ObserverPackTree`` 的配置项，有：

``base``
*********************************

目标对象

写入的目标是树状的数据结构，必须以对象为根。

``options``
*********************************

配置项

只接受内部定义的配置项对象类型，通过 ``WriterPackTree.opts()`` 创建。

.. code:: gd

    class ObjWithInt:
        var data: int

    # ...

	var target_obj := ObjWithInt.new()
	var tree := DataTree.new(0)
	var root := tree.get_root() as DataNodeInt

	var __writer_tree := WriterPackTree.new(root, {
		"base": target_obj,
		"options": WriterPackTree.opts({
			"path": ":data"
		})
	})

如果配置里只包含要绑定的属性，即配置项只有 ``properties`` ，可以直接简写为字典。

.. code:: gd

	var _writer_tree_1 := WriterPackTree.new(root, {
		"base": target_obj,
		"options": {
			"a": WriterPackTree.opts({
				"path": ":a:data",
			}),
			"b": WriterPackTree.opts({
				"path": ":b:data",
			}),
		}
	})

配置项有：

``properties``
+++++++++++++++++++++++++++++++

声明绑定的 ``DataNodeStruct`` 属性，可嵌套定义。

组织的树状结构应该与要绑定的数据树匹配。

.. code:: gd

	var _writer_tree := WriterPackTree.new(root, {
		"base": target_obj,
		"options": WriterPackTree.opts({
			"type": WriterPackTree.NODE,
			"properties": {
				"data": 0 # 随便写个简单数值占位都行，会自动补全参数的，类型是PROPERTY，path与对应data_node的属性同名
			},
			"children": WriterPackTree.opts({
				"path": ":a"
			})
		})
	})

这个例子声明了这个写者接受一个带 ``data`` 属性的 ``DataNodeNode`` 绑定，
数据节点的 ``data`` 会绑定到目标数据 **基对象** （即base指定的对象）的 ``data`` 属性（未指定path则自动寻找同名绑定）。

``children``
+++++++++++++++++++++++++++++++

声明绑定的子节点模板，用于数组、字典、节点。

格式同 ``properties`` 的某个属性。

.. code:: gd

	var _writer_tree := WriterPackTree.new(root, {
		"base": target_obj,
		"options": WriterPackTree.opts({
			"type": WriterPackTree.NODE,
			"children": WriterPackTree.opts({
				"path": ":a"
			})
		})
	})

``path``
+++++++++++++++++++++++++++++++

相对绑定路径

.. code:: gd

	var _writers := WriterPackTree.new(root, {
		base = get_tree().current_scene,
		options = {
			"left": WriterPackTree.opts({
				"path": "Panel/Label:text"
			}),
			"top_right": WriterPackTree.opts({
				"path": "Panel/Panel/LabelUpper:text"
			}),
			"bottom_right": WriterPackTree.opts({
				"path": "Panel/Panel/LabelLower:text"
			}),
		}
	})

这个相对路径是相对于最近显式定义的同一个 :doc:`小树 </theory/tree-like-data-structure>` 内的路径。
绝对路径就是将同一个小树的路径拼接成 **NodePath** 格式的路径。

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

- ``WriterPackTree.PROPERTY``
- ``WriterPackTree.PROPERTY_ARRAY``
- ``WriterPackTree.PROPERTY_DICTIONARY``
- ``WriterPackTree.NODE``

``alloc``
+++++++++++++++++++++++++++++++

目标元素的申请函数，用于数组、字典、节点。

.. code:: gd

    var _writer_tree := WriterPackTree.new(root, {
		"base": target_obj,
		"options": WriterPackTree.opts({
			"type": WriterPackTree.PROPERTY_ARRAY,
			"path": ":array",
			"alloc": func(element_data_node: DataNode) -> ObjWithInt:
				var result := ObjWithInt.new()
				result.data = element_data_node.value()
				return result
				,
			"children": WriterPackTree.opts({
				"path": ":data"
			})
		})
	})

函数格式如下：

.. code:: gd

    func(element_data_node: DataNode) -> ObjWithInt:
        var result := ObjWithInt.new()
        result.data = element_data_node.value()
        return result

函数接受一个参数 ``element_data_node`` ，数据树会先新建元素节点并初始化，再调用这个函数。

函数返回一个对象，返回类型应该和目标元素对象的类型一致。
返回的对象会加入目标数组/字典/节点中。

``drop``
+++++++++++++++++++++++++++++++

目标元素的释放函数，用于数组、字典、节点。

函数格式如下：

.. code:: gd

    func(element_object: Object): -> bool:
        element_object.queue_free()
        return true

如果目标节点需要手动释放，将调用这个函数。

返回值为表示目标元素是否已在回调内部销毁成功，如果为false，GDVM会尝试再次销毁（仅限Node）。

如果没有额外操作，只是想单纯销毁对象， ``RefCounted`` 和 ``Node`` 都无需实现这个函数。
``RefCounted`` 自动销毁，而GDVM会自动销毁 ``Node`` 。