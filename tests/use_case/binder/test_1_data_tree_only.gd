extends GutTest

const Utils = Gdvm.Utils
const DataTree = Gdvm.DataTree

const DataNode = Gdvm.DataNode
const DataNodeStruct = Gdvm.DataNodeStruct
const DataNodeNode = Gdvm.DataNodeNode
const DataNodeList = Gdvm.DataNodeList
const DataNodeDict = Gdvm.DataNodeDict
const DataNodeInt = Gdvm.DataNodeInt
const DataNodeString = Gdvm.DataNodeString
const DataNodeVector2 = Gdvm.DataNodeVector2
const DataNodeColor = Gdvm.DataNodeColor

# 纯data tree

func test_primitive() -> void:
	var tree := DataTree.new(42)
	var root := tree.get_root()
	assert_true(Utils.instance_is_type(root, DataNodeInt))
	assert_eq(tree.is_observing(), false)

func test_struct() -> void:
	var tree := DataTree.new({
		"example_string": "example_string",
		"example_int": 1,
	})
	var root := tree.get_root()
	assert_true(Utils.instance_is_type(root, DataNodeStruct))
	assert_true((root as DataNodeStruct).has_data_property("example_string"))
	assert_true((root as DataNodeStruct).has_data_property("example_int"))
	var string_data_node := (root as DataNodeStruct).get_data_property_data_node("example_string")
	var int_data_node := (root as DataNodeStruct).get_data_property_data_node("example_int")
	assert_true(Utils.instance_is_type(string_data_node, DataNodeString))
	assert_true(Utils.instance_is_type(int_data_node, DataNodeInt))

func test_computed() -> void:
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
	var root := tree.get_root()
	assert_true(Utils.instance_is_type(root, DataNodeStruct))
	assert_true((root as DataNodeStruct).has_data_property("a"))
	assert_true((root as DataNodeStruct).has_data_property("b"))
	assert_true((root as DataNodeStruct).has_computed_property("a_plus_b"))
	assert_true((root as DataNodeStruct).has_computed_property("a_minus_b"))
	var a := (root as DataNodeStruct).get_data_property_data_node("a") as DataNodeString
	var b := (root as DataNodeStruct).get_data_property_data_node("b") as DataNodeInt
	var a_plus_b := (root as DataNodeStruct).get_computed_property_data_node("a_plus_b")
	var a_minus_b := (root as DataNodeStruct).get_computed_property_data_node("a_minus_b")
	a.render("aaa")
	b.render(1)
	await wait_frames(1)
	assert_eq(a_plus_b.value(), 4)
	assert_eq(a_minus_b.value(), 2)

func test_list() -> void:
	var tree := DataTree.new([1])
	var root := tree.get_root()
	assert_true(Utils.instance_is_type(root, DataNodeList))
	assert_eq((root as DataNodeList).get_element_type(), TYPE_INT)

func test_dict() -> void:
	var tree := DataTree.new({"": 1.0})
	var root := tree.get_root()
	assert_true(Utils.instance_is_type(root, DataNodeDict))
	assert_eq((root as DataNodeDict).get_key_type(), TYPE_STRING)
	assert_eq((root as DataNodeDict).get_value_type(), TYPE_FLOAT)

func test_node() -> void:
	var tree := DataTree.new(DataTree.opts({
		"properties": {
			"a": Vector2(),
			"b": Color(),
		},
		"children": PackedStringArray()
	}))
	var root := tree.get_root()
	assert_true(Utils.instance_is_type(root, DataNodeNode))
	assert_true((root as DataNodeNode).has_data_property("a"))
	assert_true((root as DataNodeNode).has_data_property("b"))
	var a_data_node := (root as DataNodeNode).get_data_property_data_node("a")
	var b_data_node := (root as DataNodeNode).get_data_property_data_node("b")
	assert_true(Utils.instance_is_type(a_data_node, DataNodeVector2))
	assert_true(Utils.instance_is_type(b_data_node, DataNodeColor))
	var children := (root as DataNodeNode).children()
	assert_eq(children.get_element_type(), TYPE_STRING)
