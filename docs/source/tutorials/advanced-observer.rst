Observer 进阶
========================

一个observer只观察一个属性

Node型以外的观察者必须要有一个外源信号，否则无法得知源数据的改变。

属性数组型（PropertyArray）和属性字典型（PropertyDictionary）
----------------------------

绑定了这两种类型的观察者需要定义 **子观察者** 。

观察者与子观察者构成了观察者树，观察者成员的增删会创建与释放子观察者。
所以需要回调函数定义如何构造子观察者。

.. code:: gd
    var _observer := ObserverPropertyArray.new(
		source_obj,
		^":test_array",
		target_data_node,
		changed,
		func(source_element: Object, target_element: DataNode) -> Array:
			return [ObserverProperty.new(source_element, ^":a", target_element, source_element.changed)]
	)

这个构造函数接受五个n参数：源对象、源属性、目标数据节点、源数据改变信号、子观察者构造回调。

子观察者构造回调的第一个参数是新建的源元素。源元素必须是一个对象，如果不是对象，就不需要这样的观察者，属性型的就够用了。
（注意属性型的只能用在元素类型是基础数据类型的数组或字典上，这也意味着数组与字典的相互嵌套是无法实现的。）

第二个参数是目标数据节点新建的元素数据节点。

需要返回的是创建的子观察者列表，同一个元素对可以有多个观察者，都放在这个列表里就行。

需要注意的是子观察者需要的改变信号，应当是源元素专属的。

如果是字典，则对应数组元素的是字典的值。

节点型（Node）
----------------------------

节点型同上，只不过不需要指定绑定的属性和改变信号，因为节点就是绑定节点本身，且自带改变信号。