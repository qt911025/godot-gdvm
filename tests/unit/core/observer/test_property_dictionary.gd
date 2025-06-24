extends GutTest

signal changed

const Observer = Gdvm.Observer
const ObserverProperty = Gdvm.ObserverProperty
const ObserverPropertyDictionary = Gdvm.ObserverPropertyDictionary
const DataNode = Gdvm.DataNode
const DataNodeDict = Gdvm.DataNodeDict
const DataNodeInt = Gdvm.DataNodeInt

class TestDict:
	var test_dictionary: Dictionary[StringName, TestObj]

class TestObj:
	signal changed
	var a: int:
		set(value):
			a = value
			changed.emit()

func test_observe_dictionary() -> void:
	var source_obj := TestDict.new()
	var target_data_node := DataNodeDict.new(TYPE_STRING_NAME, TYPE_INT, func(): return DataNodeInt.new(0))
	var _observer := ObserverPropertyDictionary.new(
		source_obj,
		^":test_dictionary",
		target_data_node,
		changed,
		func(source_element: Object, target_element: DataNode) -> Array:
			return [ObserverProperty.new(source_element, ^":a", target_element, source_element.changed)]
	)
	assert_eq(target_data_node.size(), 0)
	var foo_element := TestObj.new()
	source_obj.test_dictionary["new_element"] = foo_element
	changed.emit()
	await wait_frames(1)
	assert_eq_deep(target_data_node.value(), {&"new_element": 0})
	assert_eq(target_data_node.size(), 1)
	foo_element.a = 1
	await wait_frames(1)
	assert_eq_deep(target_data_node.value(), {&"new_element": 1})
