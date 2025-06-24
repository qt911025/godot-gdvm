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