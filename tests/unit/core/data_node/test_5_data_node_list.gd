extends GutTest

const DataNode = Gdvm.DataNode
const DataNodeList = Gdvm.DataNodeList
const DataNodeString = Gdvm.DataNodeString
const DataNodeInt = Gdvm.DataNodeInt

var node_list: DataNodeList
var element_generator := func() -> DataNodeString:
	return DataNodeString.new("")

func before_each():
	node_list = DataNodeList.new(TYPE_STRING, element_generator)

func after_each():
	node_list = null

func test_initialization():
	assert_not_null(node_list)
	assert_eq(node_list.get_element_type(), TYPE_STRING)
	assert_true(node_list.is_typed())
	assert_true(node_list.is_empty())

func test_set_get_value():
	var test_data = ["Apple", "Banana"]
	node_list.render(test_data)
	assert_eq(node_list.size(), 2)
	assert_true(node_list.get_element(0) is String)
	assert_true(node_list.get_element(1) is String)

func test_push_back_and_size():
	node_list.push_back("Apple")
	assert_eq(node_list.size(), 1)
	node_list.push_back("Banana")
	assert_eq(node_list.size(), 2)

func test_pop_at():
	var n1 := "Apple"
	node_list.append_array([n1, "Banana"])
	assert_eq(node_list.pop_at(0), n1)
	assert_eq(node_list.size(), 1)

func test_insert():
	var n1 := "Apple"
	node_list.insert(0, n1)
	assert_eq(node_list.size(), 1)
	assert_eq(node_list.get_element(0), n1)

func test_order_changed_signal():
	watch_signals(node_list)
	node_list.push_back("Apple")
	assert_signal_emitted(node_list, "order_changed")
	node_list.reverse()
	assert_signal_emit_count(node_list, "order_changed", 2)

func test_element_modification_propagation():
	var test_node := "Apple"
	node_list.push_back(test_node)
	watch_signals(node_list)
	node_list.get_element_node(0).render("Banana")
	await wait_frames(1)
	assert_signal_emitted(node_list, "changed")

func test_typed_array_handling():
	var int_list = DataNodeList.new(TYPE_INT, func():
		return DataNodeInt.new(0)
	)
	int_list.render([1, 2, 3])
	assert_eq(int_list.value().get_typed_builtin(), TYPE_INT)