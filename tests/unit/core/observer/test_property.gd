extends GutTest

signal changed

const ObserverProperty = Gdvm.ObserverProperty
const DataNodeStruct = Gdvm.DataNodeStruct
const DataNodeVariant = Gdvm.DataNodeVariant
const DataNodeInt = Gdvm.DataNodeInt
const DataNodeList = Gdvm.DataNodeList

class TestObj:
	var a: int

class ObjWithArray:
	var array: Array

# self
func test_observe_source_object_to_target_data_node() -> void:
	var source_obj := TestObj.new()
	var target_data_node := DataNodeStruct.new()
	target_data_node.add_property("a", DataNodeInt.new(0))
	assert_eq_deep(target_data_node.value(), {"a": 0})
	var _observer := ObserverProperty.new(source_obj, ^"", target_data_node, changed)
	
	source_obj.a = 1
	changed.emit()
	await wait_physics_frames(1)
	assert_eq_deep(target_data_node.value(), {"a": 1})

# properties
func test_observe_property() -> void:
	var source_obj := TestObj.new()
	var target_data_node := DataNodeVariant.new(null)
	assert_eq(target_data_node.value(), null)
	var _observer := ObserverProperty.new(source_obj, ^"a", target_data_node, changed)

	source_obj.a = 1
	changed.emit()
	assert_eq(target_data_node.value(), 1)

# array
func test_primitive_array() -> void:
	var source_obj := ObjWithArray.new()
	var target_data_node := DataNodeList.new(TYPE_INT, func(): return DataNodeInt.new(0))
	assert_eq_deep(target_data_node.value(), [])
	var _observer := ObserverProperty.new(source_obj, ^"array", target_data_node, changed)

	source_obj.array = [1, 2, 3]
	changed.emit()
	assert_eq_deep(target_data_node.value(), [1, 2, 3])