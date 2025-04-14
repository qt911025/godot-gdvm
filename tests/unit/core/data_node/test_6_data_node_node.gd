extends GutTest
const DataNodeNode = Gdvm.DataNodeNode
const DataNodeList = Gdvm.DataNodeList
const DataNodeVariant = Gdvm.DataNodeVariant

var node: DataNodeNode

func before_each():
	node = DataNodeNode.new(null, func(): return DataNodeVariant.new(null))

func after_each():
	node = null

func test_initialization():
	assert_not_null(node.children())
	assert_true(node.children() is DataNodeList)

func test_set_value_with_node_data_bucket():
	node.add_property("a", DataNodeVariant.new(null))
	var test_data = {"a": 1}
	var test_children = ["Apple", "Banana"]
	var bucket = DataNodeNode.NodeDataBucket.new(test_data, test_children)
	
	node.render(bucket)
	
	assert_eq(node.a.value(), 1)
	assert_eq(node.children().value(), test_children)

func test_set_value_with_dictionary():
	node.add_property("b", DataNodeVariant.new(null))
	var test_data = {"b": 2}
	node.render(test_data)
	assert_eq(node.b.value(), 2)
	assert_eq(node.children().value(), [])

func test_set_value_with_array():
	var test_array = ["Apple", "Banana"]
	node.render(test_array)
	assert_eq(node.children().value(), test_array)
	assert_eq(node._property_list.size(), 0)

func test_get_value_returns_data_bucket():
	var result = node.value()
	assert_not_null(result)
	assert_true(result is DataNodeNode.NodeDataBucket)
	assert_eq(result.data(), {})
	assert_eq(result.children(), [])
