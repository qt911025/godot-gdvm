GDVM风格的数据类型定义
=====================================

截至4.4版本，Godot原生的类型API定义混乱，连通性不足。

比如 ``is_instance_of`` 函数，第二个参数如果是原生对象类型，则需要代入类的引用，如 ``is_instance_of(n, Node)`` ，
而Godot并没有提供动态获取类引用的方法，最接近的如 ``get_class`` 函数，返回的是String，而非类引用。

原生的API数据只能这么流转：

.. mermaid::
    graph LR
        get_script-->is_instance_of
        type_of-->is_instance_of
        type_of-->type_string
        type_string-->prints
        get_class-->is_class

GDVM用了另一套数据类型定义规则，涵盖了所有的 ``get`` 和 ``is`` 实现。

约定：

#. null: 无类型，视为不限定类型，即Variant。注意null不是0，所以null区别于TYPE_NIL。会视为所有类型，包括Object与非Object的父类
#. int: 基础数据类型 如：TYPE_INT
#. StringName: Godot原生对象类 如：&"Node"（支持代入String，但所有返回值以及存储值都是StringName）
#. Script: 派生类 即实例所绑定的Script对象

相关方法在 ``Gdvm.Utils`` 实现，且不限于在GDVM内使用。