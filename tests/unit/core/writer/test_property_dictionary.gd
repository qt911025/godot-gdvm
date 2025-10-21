extends GutTest

const WriterPropertyDictionary = Gdvm.WriterPropertyDictionary
const WriterProperty = Gdvm.WriterProperty
const DataNodeDict = Gdvm.DataNodeDict
const DataNodeInt = Gdvm.DataNodeInt

class TestSimpleDictionary:
	var test_dictionary: Dictionary[StringName, int]

class TestDictionary:
	var test_dictionary: Dictionary[StringName, TestObj]

class TestObj:
	var a: int

# simple list
func test_write_simple_dict() -> void:
	var target_obj := TestSimpleDictionary.new()
	var source_data_node := DataNodeDict.new(TYPE_STRING_NAME, TYPE_INT, func(): return DataNodeInt.new(0))
	var _writer := WriterPropertyDictionary.new(target_obj, ^":test_dictionary", source_data_node)
	assert_eq_deep(target_obj.test_dictionary, {})
	source_data_node.set_element(&"new_element", 1)
	await wait_frames(1)
	assert_eq_deep(target_obj.test_dictionary, {&"new_element": 1})

# complex list
func test_write_complex_dict() -> void:
	var target_obj := TestDictionary.new()
	var source_data_node := DataNodeDict.new(TYPE_STRING_NAME, TYPE_INT, func(): return DataNodeInt.new(0))
	var _writer := WriterPropertyDictionary.new(
		target_obj,
		^":test_dictionary",
		source_data_node,
		WriterPropertyDictionary.ElementSubWriter.new(
			func(element_data_node: DataNodeInt):
				var result := TestObj.new()
				result.a = element_data_node.value()
				return result
				,
			func(element_data_node: DataNodeInt, target_object: TestObj) -> Array:
				return [WriterProperty.new(target_object, ^":a", element_data_node)]
				)
	)
	assert_eq_deep(target_obj.test_dictionary, {})
	source_data_node.set_element(&"new_element", 1)
	await wait_frames(1)
	assert_eq(target_obj.test_dictionary.size(), 1)
	assert_eq(target_obj.test_dictionary[&"new_element"].a, 1)