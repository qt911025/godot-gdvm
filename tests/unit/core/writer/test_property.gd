extends GutTest

const WriterProperty = Gdvm.WriterProperty
const DataNodeInt = Gdvm.DataNodeInt

class TestObj:
	var a: int

# properties
func test_write_property() -> void:
	var target_obj := TestObj.new()
	var source_data_node := DataNodeInt.new(0)
	assert_eq(target_obj.a, 0)
	var _writer := WriterProperty.new(target_obj, ^"a", source_data_node)
	source_data_node.render(1)
	assert_eq(target_obj.a, 1)
