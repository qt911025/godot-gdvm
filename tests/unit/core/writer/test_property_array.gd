extends GutTest

const WriterPropertyArray = Gdvm.WriterPropertyArray
const WriterProperty = Gdvm.WriterProperty
const DataNodeList = Gdvm.DataNodeList
const DataNodeInt = Gdvm.DataNodeInt

class TestSimpleList:
	var test_array: Array[int]

class TestList:
	var test_array: Array[TestObj]

class TestObj:
	var a: int

# simple list
func test_write_simple_list() -> void:
	var target_obj := TestSimpleList.new()
	var source_data_node := DataNodeList.new(TYPE_INT, func(): return DataNodeInt.new(0))
	var _writer := WriterPropertyArray.new(target_obj, ^":test_array", source_data_node)
	assert_eq_deep(target_obj.test_array, [])
	source_data_node.append(1)
	await wait_frames(1)
	assert_eq_deep(target_obj.test_array, [1])

# complex list
func test_write_complex_list() -> void:
	var target_obj := TestList.new()
	var source_data_node := DataNodeList.new(TYPE_INT, func(): return DataNodeInt.new(0))
	var _writer := WriterPropertyArray.new(
		target_obj,
		^":test_array",
		source_data_node,
		WriterPropertyArray.ElementSubWriter.new(
			func(element_data_node: DataNodeInt):
				var result := TestObj.new()
				result.a = element_data_node.value()
				return result
				,
			func(element_data_node: DataNodeInt, target_object: TestObj) -> Array:
				return [WriterProperty.new(target_object, ^":a", element_data_node)]
				)
	)
	assert_eq_deep(target_obj.test_array, [])
	source_data_node.append(1)
	await wait_frames(1)
	assert_eq(target_obj.test_array.size(), 1)
	assert_eq(target_obj.test_array[0].a, 1)