extends GutTest

const DataNodeVariant = Gdvm.DataNodeVariant

# primitives ===========================================================================================
func test_should_create_a_primitive_data_node():
	var data_node := DataNodeVariant.new(1)
	assert_eq(data_node.value(), 1)

func test_primitive_should_set_correctly():
	var data_node := DataNodeVariant.new(1)
	data_node.render(2)
	assert_eq(data_node.value(), 2)
