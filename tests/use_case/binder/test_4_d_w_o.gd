extends GutTest

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


func test_simple_two_way_data_binding() -> void:
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
	assert_eq(root.value(), 0)
	assert_eq(obj.data, 0)
	root.render(1)
	assert_eq(root.value(), 1)
	assert_eq(obj.data, 1)
	obj.data = 2
	# 注意改变信号应该确定是外部输入，或者说是手动改变的，而非监视数据本身的改变，否则这就是死循环
	assert_eq(root.value(), 2)
	assert_eq(obj.data, 2)
