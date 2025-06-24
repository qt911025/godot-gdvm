extends GutTest

const Utils = Gdvm.Utils
const DataTree = Gdvm.DataTree
const ObserverPackTree = Gdvm.ObserverPackTree

const DataNode = Gdvm.DataNode
const DataNodeStruct = Gdvm.DataNodeStruct
const DataNodeNode = Gdvm.DataNodeNode
const DataNodeList = Gdvm.DataNodeList
const DataNodeDict = Gdvm.DataNodeDict
const DataNodeString = Gdvm.DataNodeString
const DataNodeInt = Gdvm.DataNodeInt

class ObjWithArray:
	signal changed
	var array: Array

class ObjWithDictionary:
	signal changed
	var dictionary: Dictionary

# class SampleObj:
# 	var data: String = "init_data"

class ObjWithInt:
	signal changed
	var data: int:
		set(value):
			data = value
			changed.emit()

class ObjStruct:
	var a: ObjWithInt = ObjWithInt.new()
	var b: ObjWithInt = ObjWithInt.new()

class SuperNode extends Node:
	signal changed
	var data: String:
		set(value):
			data = value
			changed.emit()

class SubNode extends Node:
	signal changed
	var a: int:
		set(value):
			a = value
			changed.emit()

func test_observe_primitive() -> void:
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

	assert_eq(tree.is_observing(), true)
	var root := tree.get_root() as DataNodeInt
	assert_eq(root.value(), 0) # 尚未实现默认值
	assert_eq(source_obj.data, 0)
	source_obj.data = 42
	assert_eq(root.value(), 42)

func test_observe_struct() -> void:
	var source_obj := ObjStruct.new()
	var tree := DataTree.new({
		"foo": 0,
		"bar": 0,
	})

	var observer := ObserverPackTree.new({
		"base": source_obj,
		"options": {
			"foo": ObserverPackTree.opts({
				"path": ":a:data",
				"changed": func(source: Object, _property_path: NodePath) -> Signal:
					# 因为最近的一个“节点”是根，而a和b是从属性获取来的，所以真正的目标节点是用get_indexed获取
					# 需要注意的是，changed只在构建观察关系时调用，所以当属性被人为改变时，这将失效
					# 未来changed的含义会发生变化，会稳定绑定对应的节点
					return (source.a as ObjWithInt).changed
					}),
			"bar": ObserverPackTree.opts({
				"path": ":b:data",
				"changed": func(source: Object, _property_path: NodePath) -> Signal:
					return (source.b as ObjWithInt).changed
					}),
		}
	})

	tree.observe(observer)

	var root := tree.get_root() as DataNodeStruct
	assert_eq_deep(root.value(), {
		"foo": 0,
		"bar": 0,
	})
	source_obj.a.data = 42
	source_obj.b.data = 84
	await wait_frames(1)
	assert_eq_deep(root.value(), {
		"foo": 42,
		"bar": 84,
	})

func test_observe_array() -> void:
	var source_obj := ObjWithArray.new()
	var tree := DataTree.new(Array([], TYPE_INT, &"", null))
	var observer := ObserverPackTree.new({
		"base": source_obj,
		"options": ObserverPackTree.opts({
			"type": ObserverPackTree.PROPERTY_ARRAY,
			"path": ":array",
			"changed": func(source: Object, _property_path: NodePath) -> Signal:
				return (source as ObjWithArray).changed
				,
			"children": ObserverPackTree.opts({
				"type": ObserverPackTree.PROPERTY,
				"path": ":data",
				"changed": func(source: Object, _property_path: NodePath) -> Signal:
					return (source as ObjWithInt).changed # 作为子节点的根
					})
		})
	})
	tree.observe(observer)

	var root := tree.get_root() as DataNodeList
	assert_eq_deep(root.value(), [])
	var elm_1 := ObjWithInt.new()
	var elm_2 := ObjWithInt.new()
	source_obj.array.append(elm_1)
	source_obj.array.append(elm_2)
	source_obj.changed.emit()
	await wait_frames(1)
	assert_eq_deep(root.value(), [0, 0])
	elm_1.data = 42
	await wait_frames(1)
	assert_eq_deep(root.value(), [42, 0])

func test_observe_dictionary() -> void:
	var source_obj := ObjWithDictionary.new()
	var tree := DataTree.new(Dictionary({}, TYPE_STRING, &"", null, TYPE_INT, &"", null))
	var observer := ObserverPackTree.new({
		"base": source_obj,
		"options": ObserverPackTree.opts({
			"type": ObserverPackTree.PROPERTY_DICTIONARY,
			"path": ":dictionary",
			"changed": func(source: Object, _property_path: NodePath) -> Signal:
				return (source as ObjWithDictionary).changed
				,
			"children": ObserverPackTree.opts({
				"type": ObserverPackTree.PROPERTY,
				"path": ":data",
				"changed": func(source: Object, _property_path: NodePath) -> Signal:
					return (source as ObjWithInt).changed # 作为子节点的根
					})
		})
	})
	tree.observe(observer)
	var root := tree.get_root() as DataNodeDict
	assert_eq_deep(root.value(), {})
	var elm_1 := ObjWithInt.new()
	var elm_2 := ObjWithInt.new()
	source_obj.dictionary["foo"] = elm_1
	source_obj.dictionary["bar"] = elm_2
	source_obj.changed.emit()
	await wait_frames(1)
	assert_eq_deep(root.value(), {"foo": 0, "bar": 0})
	elm_1.data = 42
	await wait_frames(1)
	assert_eq_deep(root.value(), {"foo": 42, "bar": 0})

func test_observe_node() -> void:
	var source_obj := SuperNode.new()
	var tree := DataTree.new([0])
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
	tree.observe(observer)
	
	var root := tree.get_root() as DataNodeList
	assert_eq(root.size(), 0)
	var foo_child := SubNode.new()
	source_obj.add_child(foo_child)
	await wait_frames(1)
	assert_eq_deep(root.value(), [0])
	assert_eq(root.size(), 1)
	foo_child.a = 1
	await wait_frames(1)
	assert_eq_deep(root.value(), [1])
	autoqfree(source_obj)

func test_node_compound() -> void:
	var source_obj := SuperNode.new()
	var tree := DataTree.new(DataTree.opts({
		"properties": {
			"data": ""
		},
		"children": [0]
	}))
	# 关键信息够了，类型都可省
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
	tree.observe(observer)
	var root := tree.get_root() as DataNodeNode
	var children := root.children()
	assert_eq(children.size(), 0)
	assert_eq(root.get_data_property_data_node("data").value(), "")
	var foo_child := SubNode.new()
	source_obj.add_child(foo_child)
	source_obj.data = "foo"
	await wait_frames(1)
	assert_eq(source_obj.data, "foo")
	assert_eq_deep(children.value(), [0])
	assert_eq(children.size(), 1)
	foo_child.a = 1
	await wait_frames(1)
	assert_eq_deep(children.value(), [1])
	autoqfree(source_obj)
