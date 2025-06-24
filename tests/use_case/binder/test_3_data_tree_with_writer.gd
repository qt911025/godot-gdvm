extends GutTest

const Utils = Gdvm.Utils
const DataTree = Gdvm.DataTree
const WriterPackTree = Gdvm.WriterPackTree

const DataNodeStruct = Gdvm.DataNodeStruct
const DataNode = Gdvm.DataNode
const DataNodeNode = Gdvm.DataNodeNode
const DataNodeList = Gdvm.DataNodeList
const DataNodeDict = Gdvm.DataNodeDict
const DataNodeString = Gdvm.DataNodeString
const DataNodeInt = Gdvm.DataNodeInt
const DataNodeVariant = Gdvm.DataNodeVariant

class ObjWithArray:
	var array: Array

class ObjWithDictionary:
	var dictionary: Dictionary

class ObjWithInt:
	var data: int

class ObjStruct:
	var a: ObjWithInt = ObjWithInt.new()
	var b: ObjWithInt = ObjWithInt.new()

class SuperNode extends Node:
	var data: String

class SubNode extends Node:
	var a: int

func test_write_primitive() -> void:
	var target_obj := ObjWithInt.new()
	var tree := DataTree.new(0)
	var root := tree.get_root() as DataNodeInt
	assert_eq(root.value(), 0)

	var __writer_tree := WriterPackTree.new(root, {
		"base": target_obj,
		"options": WriterPackTree.opts({
			"path": ":data"
		})
	})

	assert_eq(target_obj.data, 0)
	root.render(42)
	assert_eq(target_obj.data, 42)

func test_write_struct() -> void:
	var target_obj := ObjStruct.new()
	var apb := ObjWithInt.new()
	var amb := ObjWithInt.new()
	var tree := DataTree.new(DataTree.opts({
		"data": {
			"a": 0,
			"b": 0,
		},
		"computed": [ {
			"dependencies": ["a", "b"],
			"outputs": {
				"a_plus_b": 0, # 定义了类型
				"a_minus_b": 0
			},
			"computer": func(dependencies: Dictionary, outputs: Dictionary) -> void:
				(outputs["a_plus_b"] as DataNode).render(dependencies["a"] + dependencies["b"])
				(outputs["a_minus_b"] as DataNode).render(dependencies["a"] - dependencies["b"])
				}],
	}))
	var root := tree.get_root() as DataNodeStruct
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
	# 如果与根节点关系是固定的，完全可以这么写
	var _writer_tree_2 := WriterPackTree.new(root, {
		"base": apb,
		"options": {
			"a_plus_b": WriterPackTree.opts({
				"path": ":data"
			})
		}
	})
	var _writer_tree_3 := WriterPackTree.new(root, {
		"base": amb,
		"options": {
			"a_minus_b": WriterPackTree.opts({
				"path": ":data"
			})
		}
	})
	assert_eq(target_obj.a.data, 0)
	assert_eq(target_obj.b.data, 0)
	assert_eq(apb.data, 0)
	assert_eq(amb.data, 0)
	root.render({
		"a": 1,
		"b": 2,
	})
	# await wait_frames(1)
	assert_eq(target_obj.a.data, 1)
	assert_eq(target_obj.b.data, 2)
	assert_eq(apb.data, 3)
	assert_eq(amb.data, -1)

func test_write_primitive_array() -> void:
	var target_obj := ObjWithArray.new()
	var tree := DataTree.new(Array([], TYPE_INT, &"", null))
	var root := tree.get_root() as DataNodeList
	var _writer_tree := WriterPackTree.new(root, {
		"base": target_obj,
		"options": WriterPackTree.opts({
			"path": ":array",
		})
	})
	assert_eq_deep(target_obj.array, [])
	root.append(1)
	root.append(2)
	await wait_frames(1)
	assert_eq_deep(target_obj.array, [1, 2])
	root.get_element_node(0).render(42)
	await wait_frames(1)
	assert_eq_deep(target_obj.array, [42, 2])

func test_write_object_array() -> void:
	var target_obj := ObjWithArray.new()
	var tree := DataTree.new(Array([], TYPE_INT, &"", null))
	var root := tree.get_root() as DataNodeList
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
	assert_eq_deep(target_obj.array, [])
	root.append(1)
	root.append(2)
	await wait_frames(1)
	assert_eq(target_obj.array.size(), 2)
	assert_eq(target_obj.array[0].data, 1)
	assert_eq(target_obj.array[1].data, 2)
	root.get_element_node(0).render(42)
	assert_eq(target_obj.array[0].data, 42)
	assert_eq(target_obj.array[1].data, 2)

func test_write_primitive_dictionary() -> void:
	var target_obj := ObjWithDictionary.new()
	var tree := DataTree.new(Dictionary({}, TYPE_STRING, &"", null, TYPE_INT, &"", null))
	var root := tree.get_root() as DataNodeDict
	var _writer_tree := WriterPackTree.new(root, {
		"base": target_obj,
		"options": WriterPackTree.opts({
			"path": ":dictionary",
		})
	})
	assert_eq_deep(target_obj.dictionary, {})
	root.set_element("foo", 1)
	root.set_element("bar", 2)
	await wait_frames(1)
	assert_eq_deep(target_obj.dictionary, {"foo": 1, "bar": 2})
	root.get_element_node("foo").render(42)
	await wait_frames(1)
	assert_eq_deep(target_obj.dictionary, {"foo": 42, "bar": 2})

func test_write_object_dictionary() -> void:
	var target_obj := ObjWithDictionary.new()
	var tree := DataTree.new(Dictionary({}, TYPE_STRING, &"", null, TYPE_INT, &"", null))
	var root := tree.get_root() as DataNodeDict
	var _writer_tree := WriterPackTree.new(root, {
		"base": target_obj,
		"options": WriterPackTree.opts({
			"type": WriterPackTree.PROPERTY_DICTIONARY,
			"path": ":dictionary",
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
	assert_eq_deep(target_obj.dictionary, {})
	root.set_element("foo", 1)
	root.set_element("bar", 2)
	await wait_frames(1)
	assert_eq(target_obj.dictionary.size(), 2)
	assert_eq(target_obj.dictionary["foo"].data, 1)
	assert_eq(target_obj.dictionary["bar"].data, 2)
	root.get_element_node("foo").render(42)
	assert_eq(target_obj.dictionary["foo"].data, 42)
	assert_eq(target_obj.dictionary["bar"].data, 2)

func test_write_node() -> void:
	var target_obj := SuperNode.new()
	var tree := DataTree.new([0])
	var root := tree.get_root() as DataNodeList
	var _writer_tree := WriterPackTree.new(root, {
		"base": target_obj,
		"options": WriterPackTree.opts({
			"type": WriterPackTree.NODE,
			"alloc": func(element_data_node: DataNode) -> SubNode:
				var result := SubNode.new()
				result.a = element_data_node.value()
				return result
				,
			"children": WriterPackTree.opts({
				"path": ":a"
			})
		})
	})
	assert_eq(target_obj.get_child_count(), 0)
	root.append(1)
	await wait_frames(1)
	assert_eq(target_obj.get_child_count(), 1)
	assert_eq(target_obj.get_child(0).a, 1)
	root.get_element_node(0).render(2)
	await wait_frames(1)
	assert_eq(target_obj.get_child(0).a, 2)
	autoqfree(target_obj)

func test_write_node_templated() -> void:
	var target_obj := SuperNode.new()
	var example_child := SubNode.new()
	target_obj.add_child(example_child) # 使用唯一子节点作为模板
	var tree := DataTree.new([0])
	var root := tree.get_root() as DataNodeList
	var _writer_tree := WriterPackTree.new(root, {
		"base": target_obj,
		"options": WriterPackTree.opts({
			"type": WriterPackTree.NODE,
			"children": WriterPackTree.opts({
				"path": ":a"
			})
		})
	})
	assert_eq(target_obj.get_child_count(), 0)
	root.append(1)
	await wait_frames(1)
	assert_eq(target_obj.get_child_count(), 1)
	assert_eq(target_obj.get_child(0).a, 1)
	root.get_element_node(0).render(2)
	await wait_frames(1)
	assert_eq(target_obj.get_child(0).a, 2)
	autoqfree(target_obj)

func test_write_node_compound() -> void:
	var target_obj := SuperNode.new()
	var example_child := SubNode.new()
	target_obj.add_child(example_child) # 使用唯一子节点作为模板
	var tree := DataTree.new(DataTree.opts({
		"properties": {
			"data": ""
		},
		"children": [0]
	}))
	var root := tree.get_root() as DataNodeNode
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
	assert_eq(target_obj.get_child_count(), 0)
	assert_eq(target_obj.data, "")
	root.children().append(1)
	root.data.render("hello world")
	await wait_frames(1)
	assert_eq(target_obj.get_child_count(), 1)
	assert_eq(target_obj.get_child(0).a, 1)
	assert_eq(target_obj.data, "hello world")
	root.children().get_element_node(0).render(2)
	await wait_frames(1)
	assert_eq(target_obj.get_child(0).a, 2)
	autoqfree(target_obj)
