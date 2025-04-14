extends GutTest

const DataNode = Gdvm.DataNode
const DataNodeVariant = Gdvm.DataNodeVariant
const DataNodeStruct = Gdvm.DataNodeStruct
# const DataNodeList = Gdvm.DataNodeList

class SampleObject:
	var a: int

var sample_object := SampleObject.new()

# data node
# func test_should_create_correct_type_of_data_node():
# 	var int_data_node := DataNode.build_data_node(1)
# 	assert_is(int_data_node, DataNodeVariant)

# 	var float_data_node := DataNode.build_data_node(1.0)
# 	assert_is(float_data_node, DataNodeVariant)

# 	var string_data_node := DataNode.build_data_node("hello")
# 	assert_is(string_data_node, DataNodeVariant)

# 	var bool_data_node := DataNode.build_data_node(true)
# 	assert_is(bool_data_node, DataNodeVariant)

# 	var object_data_node := DataNode.build_data_node(sample_object)
# 	assert_is(object_data_node, DataNodeVariant)

# 	var struct_data_node := DataNode.build_data_node({"a": 1})
# 	assert_is(struct_data_node, DataNodeStruct)
# 	assert_is(struct_data_node.a, DataNodeVariant)

	# todo list
