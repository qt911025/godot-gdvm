extends GutTest

signal changed

const ObserverProperty = Gdvm.ObserverProperty
const DataNodeVariant = Gdvm.DataNodeVariant

class TestObj:
	var a: int

# self
func test_observe_source_object_to_target_data_node() -> void:
	var source_obj := TestObj.new()
	var target_data_node := DataNodeVariant.new(null)
	assert_eq(target_data_node.value(), null)
	var _observer := ObserverProperty.new(source_obj, ^"", target_data_node, changed)
	changed.emit()
	assert_eq(target_data_node.value(), source_obj)

# properties
func test_observe_property() -> void:
	var source_obj := TestObj.new()
	var target_data_node := DataNodeVariant.new(null)
	assert_eq(target_data_node.value(), null)
	var _observer := ObserverProperty.new(source_obj, ^"a", target_data_node, changed)

	source_obj.a = 1
	changed.emit()
	assert_eq(target_data_node.value(), 1)
