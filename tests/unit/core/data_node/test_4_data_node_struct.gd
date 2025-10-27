extends GutTest

const DataNode = Gdvm.DataNode
const DataNodeVariant = Gdvm.DataNodeVariant
const DataNodeStruct = Gdvm.DataNodeStruct

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
	await wait_physics_frames(1)
	assert_signal_emitted(struct, "changed")


func test_struct_should_set_correctly():
	var child1 = DataNodeVariant.new(0)
	var child2 = DataNodeVariant.new(0)
	struct.add_property("a", child1)
	struct.add_property("b", child2)
	
	struct.render({"a": 10, "b": "test"})
	assert_eq(child1.value(), 10)
	assert_eq(child2.value(), "test")

func test_struct_should_ignore_mismatched_data():
	var child1 = DataNodeVariant.new(0)
	struct.add_property("a", child1)
	
	struct.render({"a": 10, "b": "test"})
	assert_eq(child1.value(), 10)

# computed ===============================================================================================
func test_struct_computed_should_add_computed_properties():
	var a = DataNodeVariant.new(0)
	var b = DataNodeVariant.new(0)
	var a_plus_b = DataNodeVariant.new(0)
	var a_minus_b = DataNodeVariant.new(0)
	struct.add_property("a", a)
	struct.add_property("b", b)
	struct.add_computed_properties(
		["a", "b"],
		{
			"a_plus_b": a_plus_b,
			"a_minus_b": a_minus_b
		},
		func(dependencies: Dictionary, outputs: Dictionary) -> void:
			(outputs["a_plus_b"] as DataNode).render(dependencies["a"] + dependencies["b"])
			(outputs["a_minus_b"] as DataNode).render(dependencies["a"] - dependencies["b"])
	)
	a.render(10)
	b.render(5)
	assert_eq(a_plus_b.value(), 15)
	assert_eq(a_minus_b.value(), 5)

# get_indexed_property ===============================================================================================
func test_get_indexed_property_should_return_self_if_property_is_empty():
	var a = DataNodeVariant.new(0)
	var b = DataNodeVariant.new(0)
	struct.add_property("a", a)
	struct.add_property("b", b)
	assert_eq(struct.get_indexed_property(""), struct)

func test_get_indexed_property_should_return_length_1():
	var a = DataNodeVariant.new(0)
	var b = DataNodeVariant.new(0)
	struct.add_property("a", a)
	struct.add_property("b", b)
	assert_eq(struct.get_indexed_property("a"), a)

func test_get_indexed_property_should_return_long_length():
	var a = DataNodeStruct.new()
	var b = DataNodeStruct.new()
	var aa = DataNodeVariant.new(0)
	var ab = DataNodeVariant.new(0)
	var ba = DataNodeVariant.new(0)
	var bb = DataNodeVariant.new(0)
	struct.add_property("a", a)
	struct.add_property("b", b)
	a.add_property("a", aa)
	a.add_property("b", ab)
	b.add_property("a", ba)
	b.add_property("b", bb)
	assert_eq(struct.get_indexed_property("a/b"), ab)
	assert_eq(struct.get_indexed_property("b:a"), ba)

func test_get_indexed_property_should_return_null_if_mismatched():
	var a = DataNodeVariant.new(0)
	var b = DataNodeVariant.new(0)
	struct.add_property("a", a)
	struct.add_property("b", b)
	assert_eq(struct.get_indexed_property("c"), null)

func test_get_indexed_property_should_return_null_if_outranged():
	var a = DataNodeVariant.new(0)
	var b = DataNodeVariant.new(0)
	struct.add_property("a", a)
	struct.add_property("b", b)
	assert_eq(struct.get_indexed_property("a/b"), null)

func test_get_indexed_property_should_return_computed():
	var a = DataNodeVariant.new(0)
	var b = DataNodeVariant.new(0)
	var a_plus_b = DataNodeVariant.new(0)
	var a_minus_b = DataNodeVariant.new(0)
	struct.add_property("a", a)
	struct.add_property("b", b)
	struct.add_computed_properties(
		["a", "b"],
		{
			"a_plus_b": a_plus_b,
			"a_minus_b": a_minus_b
		},
		func(dependencies: Dictionary, outputs: Dictionary) -> void:
			(outputs["a_plus_b"] as DataNode).render(dependencies["a"] + dependencies["b"])
			(outputs["a_minus_b"] as DataNode).render(dependencies["a"] - dependencies["b"])
	)
	assert_eq(struct.get_indexed_property("a_plus_b"), null)
	assert_eq(struct.get_indexed_property("a_plus_b", true), a_plus_b)