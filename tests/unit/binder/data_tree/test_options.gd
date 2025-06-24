extends GutTest
const Utils = Gdvm.Utils
const DataTreeOptions = preload("res://addons/gdvm/binder/data_tree/options.gd")

func test_data_tree_options_simple_types():
	# Test primitive type handling
	var int_opts := DataTreeOptions.new({"data": 42})
	assert_eq(int_opts.node_type, DataTreeOptions.NodeType.STRICT)
	assert_eq(int_opts.data, 42)

	# Test string type
	var str_opts = DataTreeOptions.new({"data": "test"})
	assert_eq(str_opts.data_type, TYPE_STRING)

func test_struct_type_creation():
	# Test explicit struct type
	var struct_opts = DataTreeOptions.new({
		"type": DataTreeOptions.Struct,
		"data": {
			"name": DataTreeOptions.new({"type": TYPE_STRING})
		},
	})
	assert_eq(struct_opts.node_type, DataTreeOptions.NodeType.STRUCT)
	assert_true(struct_opts.data.properties.has("name"))

func test_list_type_handling():
	# Test typed array inference
	var list_opts = DataTreeOptions.new({
		"children": [
			DataTreeOptions.new({"type": TYPE_INT})
		]
	})
	assert_eq(list_opts.node_type, DataTreeOptions.NodeType.LIST)
	assert_true(Utils.type_is_type(list_opts.data[0].data_type, TYPE_INT))

func test_dict_type_handling():
	# Test dictionary with typed key/value
	var dict_opts = DataTreeOptions.new({
		"type": TYPE_DICTIONARY,
		"data": {
			"": DataTreeOptions.new({"type": TYPE_VECTOR2})
		}
	})
	assert_eq(dict_opts.node_type, DataTreeOptions.NodeType.DICT)
	assert_true(dict_opts.data.has(""))
	assert_true(dict_opts.data.keys()[0] is String)
	assert_true(dict_opts.data[""] is DataTreeOptions)
	assert_true(dict_opts.data[""].data_type == TYPE_VECTOR2)

func test_node_type_composition():
	# Test complex node structure
	var node_opts = DataTreeOptions.new({
		"children": [0],
		"properties": {
			"health": 0.0
		}
	})
	assert_eq(node_opts.node_type, DataTreeOptions.NodeType.NODE)
	assert_true(node_opts.data.has("children"))
	assert_true(node_opts.data.has("properties"))
	assert_true(node_opts.data["children"][0] is DataTreeOptions)
	assert_true(node_opts.data["properties"]["health"] is DataTreeOptions)