# Godot View Model by GDScript

[![Documentation Status](https://readthedocs.org/projects/godot-gdvm/badge/?version=latest)](https://godot-gdvm.readthedocs.io/zh-cn/latest/)
[![GitHub License](https://img.shields.io/github/license/qt911025/godot-gdvm)](https://github.com/qt911025/godot-gdvm/blob/main/LICENSE)
## 支持的版本

|GDVM|Godot|
|----|----|
|~0.2|^4.4|
|~0.3|^4.5|

## 这是啥

一个 Godot 的插件

一个单向数据绑定工具集，可实现MVVM/MVC

Gdvm不是围绕Godot的UI设计的，它与UI完全无关，所以Godot的任何节点都可以用

支持列表！

惰性求值！

可扩展！

**Gdvm现在还处于测试版，API尚未稳定，在1.0发布前的更新都是颠覆性的，慎用！**

**1.0正式版将在Godot Asset Store正式版发布后发布在Godot Asset Store。届时旧的Godot Asset Library将不再更新。**

## 上手

创建一个空的场景，根节点是Node，并绑定如下脚本。

```gdscript
extends Node

const Utils = Gdvm.Utils
const DataTree = Gdvm.DataTree
const ObserverPackTree = Gdvm.ObserverPackTree
const WriterPackTree = Gdvm.WriterPackTree

const DataNode = Gdvm.DataNode
const DataNodeInt = Gdvm.DataNodeInt

class ObjWithInt:
	signal changed
	var data: int:
		set(value):
			if value != data:
				# 防死循环设计
				data = value
				changed.emit()

func _ready() -> void:
	var obj := ObjWithInt.new()
	var data_tree := DataTree.new(0)
	var observer := ObserverPackTree.new({
		"base": obj,
		"options": ObserverPackTree.opts({
			"path": ":data",
			"changed": func(source: Object, _property_path: NodePath) -> Signal:
				return (source as ObjWithInt).changed
				})
	})
	data_tree.observe(observer)
	var root := data_tree.get_root() as DataNodeInt
	var _writer := WriterPackTree.new(root, {
		"base": obj,
		"options": WriterPackTree.opts({
			"path": ":data"
			})
	})
	prints("Initial data node value:", root.value()) # 0
	prints("Initial target value:", obj.data) # 0
	root.render(1)
	prints("Root rendered node value:", root.value()) # 1
	prints("Root rendered target value:", obj.data) # 1
	obj.data = 2
	prints("Target changed node value:", root.value()) # 2
	prints("Target changed target value:", obj.data) # 2
```

这个例子也在examples/_7_pure_script里可以看到

## 简单原理介绍

### 基础组成要素

Gdvm针对Godot的数据类型，定义了一套DataNode。

DataNode通过结构化组织成树，并添加观察者（Observer）与写者（Writer）绑定，将改动从来源同步到DataNode，并同步到目标数据。

观察者与写者是原子化的，实例化的关系，都是RefCounted，并且关系不拥有对目标对象与DataNode的强引用。绑定的数据一旦消失，关系也自动失效。

同样地，观察者与写者都是RefCounted，解除关系也只需要抛弃关系实例即可。

### 更复杂的组织

每个基本的DataNode、观察者与写者组织监听关系，规模扩大会让代码十分臃肿。

Gdvm提供了更简洁的配置方式——Binder，通过将三类基础部件构建成三大集合，建立集合与集合之间的监听关系。

|Core|Binder|
|----|----|
|DataNode|DataTree|
|Observer|ObserverPack|
|Writer|WriterPack|


可以建立多重监听关系，让多个不同的DataTree观察同一个数据来源，同一个DataTree可以建立多个不同的写者，同步到多个不同的目标。

## Gdvm的适用场景

Gdvm将数据武装到牙齿，为每一个基础数据类型包装了一层复杂的结构，包括信号、缓存值等，会大大提高数据所占据的空间。

对数据量以及效率要求不大时，DataNode本身可以作为数据模型用。而数据量有一定规模后，应该自行定义数据结构与读写锁，只在表现层构建Gdvm来观察它。