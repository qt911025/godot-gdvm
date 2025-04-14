extends GutTest

const DataNode = Gdvm.DataNode
const DataNodeVariant = Gdvm.DataNodeVariant
const DataNodeStruct = Gdvm.DataNodeStruct
# const DataNodeList = Gdvm.DataNodeList

var struct: DataNodeStruct

func before_each():
	struct = DataNodeStruct.new()

# struct ===============================================================================================
func test_should_create_a_struct_data_node():
	var data_node := DataNodeStruct.new()
	data_node.add_property("a", DataNodeVariant.new(1))
	assert_eq(data_node.a.value(), 1)

func test_add_property():
	var test_node = DataNodeVariant.new(0)
	struct.add_property("test", test_node)
	
	assert_true(struct._data.has("test"))
	assert_eq(struct._property_list.back()["name"], "test")
	assert_true(test_node.changed.is_connected(struct._on_property_changed))

func test_remove_property():
	var test_node = DataNodeVariant.new(0)
	struct.add_property("test", test_node)
	struct.remove_property("test")
	
	assert_false(struct._data.has("test"))
	assert_false(test_node.changed.is_connected(struct._on_property_changed))

func test_set_value_with_dictionary():
	var child1 = DataNodeVariant.new(0)
	var child2 = DataNodeVariant.new(0)
	struct.add_property("a", child1)
	struct.add_property("b", child2)
	
	struct.render({"a": 10, "b": "test"})
	assert_eq(child1.value(), 10)
	assert_eq(child2.value(), "test")

func test_get_value():
	var child1 = DataNodeVariant.new(0)
	var child2 = DataNodeVariant.new(0)
	child1.render(42)
	child2.render("hello")
	struct.add_property("num", child1)
	struct.add_property("str", child2)
	
	var result = struct.value()
	assert_eq(result["num"], 42)
	assert_eq(result["str"], "hello")

func test_property_change_propagation():
	var test_node = DataNodeVariant.new(0)
	struct.add_property("test", test_node)
	watch_signals(struct)
	
	test_node.render("new_value")
	await wait_frames(1)
	assert_signal_emitted(struct, "changed")

# func test_duplicate_property_add():
# 	var test_node1 = DataNodeVariant.new(0)
# 	var test_node2 = DataNodeVariant.new(0)
# 	struct.add_property("test", test_node1)
# 	struct.add_property("test", test_node2)
	
# 	assert_eq(warnings.size(), 1)
# 	assert_eq(struct._data["test"], test_node2)

# func test_struct_should_set_correctly():
# 	var data_node := DataNodeStruct.from_dictionary({
# 		"a": 1,
# 		"b": {
# 			"ba": 21,
# 			"bb": {
# 				"bba": 221,
# 			}
# 		}
# 	})
# 	assert_eq_deep(data_node.value(), {
# 		"a": 1,
# 		"b": {
# 			"ba": 21,
# 			"bb": {
# 				"bba": 221,
# 			}
# 		}
# 	})
# 	assert_eq_deep(data_node.a.value(), 1)
# 	assert_eq_deep(data_node.b.value(), {
# 		"ba": 21,
# 		"bb": {
# 			"bba": 221,
# 		}
# 	})
# 	assert_eq_deep(data_node.b.ba.value(), 21)
# 	assert_eq_deep(data_node.b.bb.value(), {
# 		"bba": 221,
# 	})
# 	assert_eq_deep(data_node.b.bb.bba.value(), 221)

# 	data_node.render({"a": 2})
# 	assert_eq_deep(data_node.value(), {
# 		"a": 2,
# 		"b": {
# 			"ba": 21,
# 			"bb": {
# 				"bba": 221,
# 			}
# 		}
# 	})

# func test_struct_should_ignore_mismatched_data():
# 	# 无视不匹配的数据
# 	var data_node := DataNodeStruct.from_dictionary({
# 		"a": 1,
# 		"b": {
# 			"ba": 21,
# 			"bb": {
# 				"bba": 221,
# 			}
# 		}
# 	})

# 	data_node.render({
# 		"a": {
# 			"aa": 11,
# 		},
# 		"b": 2,
# 		"c": 3,
# 	})
# 	assert_eq_deep(data_node.value(), {
# 		"a": {
# 			"aa": 11, # data_node_variant是弱类型，任何可以是Variant，所以这里不管
# 		},
# 		"b": {
# 			"ba": 21,
# 			"bb": {
# 				"bba": 221,
# 			}
# 		}
# 	})
