extends GutTest

const DataNode = Gdvm.DataNode
const DataNodeDict = Gdvm.DataNodeDict
const DataNodeInt = Gdvm.DataNodeInt

var node_dict: DataNodeDict
var element_generator := func() -> DataNodeInt:
	return DataNodeInt.new(0)

func before_each():
	node_dict = DataNodeDict.new(TYPE_STRING, TYPE_INT, element_generator)

# Test initialization
func test_typed_dict_initialization():
	assert_eq(node_dict.get_key_type(), TYPE_STRING, "Should have string key type")
	assert_eq(node_dict.get_value_type(), TYPE_INT, "Should have int value type")
	assert_true(node_dict.is_empty(), "New dict should be empty")

# Test basic element operations
func test_set_get_element():
	watch_signals(node_dict)
	node_dict.set_element("test", 42)
	assert_eq(node_dict.get_element("test"), 42, "Should get correct value")
	assert_eq(node_dict.size(), 1, "Size should update")
	await wait_physics_frames(1)
	assert_signal_emitted(node_dict, "order_changed")
	assert_signal_emitted(node_dict, "changed")

# Test element replacement
func test_replace_element():
	node_dict.set_element("key", 10)
	var origingal_data_node := node_dict.get_element_node("key")
	assert_eq(node_dict.size(), 1)
	assert_eq(node_dict.get_element("key"), 10, "Value should be updated")
	node_dict.replace_element("key", 20)
	assert_ne(node_dict.get_element_node("key"), origingal_data_node, "Data node should not be the same")
	assert_eq(node_dict.get_element("key"), 20, "Value should be updated")
	assert_eq(node_dict.size(), 1)

# Test merge functionality
func test_merge_dictionaries():
	node_dict.set_element("a", 1)
	var merge_dict = {"b": 2, "c": 3}
	node_dict.merge(merge_dict)
	assert_eq(node_dict.size(), 3, "Should merge all elements")
	assert_eq(node_dict.get_element("b"), 2, "Merged value should exist")

# Test deletion and clear
func test_erase_and_clear():
	watch_signals(node_dict)
	node_dict.set_element("to_delete", 99)
	
	node_dict.erase("to_delete")
	assert_false(node_dict.has("to_delete"), "Element should be deleted")
	await wait_physics_frames(1)
	assert_signal_emitted(node_dict, "changed")

# Test dictionary operations
func test_sort_and_find():
	node_dict.set_element("c", 3)
	node_dict.set_element("a", 1)
	node_dict.set_element("b", 2)
	
	node_dict.sort()
	assert_eq(node_dict.keys(), ["a", "b", "c"], "Should sort keys alphabetically")
	assert_eq(node_dict.find_key(2), "b", "Should find correct key")