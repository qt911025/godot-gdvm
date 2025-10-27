extends GutTest

signal changed

const Observer = Gdvm.Observer
const ObserverProperty = Gdvm.ObserverProperty
const ObserverPropertyArray = Gdvm.ObserverPropertyArray
const DataNode = Gdvm.DataNode
const DataNodeList = Gdvm.DataNodeList
const DataNodeInt = Gdvm.DataNodeInt

class TestList:
	var test_array: Array[TestObj]

class TestObj:
	signal changed
	var a: int:
		set(value):
			a = value
			changed.emit()

func test_observe_array() -> void:
	var source_obj := TestList.new()
	var target_data_node := DataNodeList.new(TYPE_INT, func(): return DataNodeInt.new(0))
	var _observer := ObserverPropertyArray.new(
		source_obj,
		^":test_array",
		target_data_node,
		changed,
		func(source_element: Object, target_element: DataNode) -> Array:
			return [ObserverProperty.new(source_element, ^":a", target_element, source_element.changed)]
	)
	assert_eq(target_data_node.size(), 0)
	var foo_element := TestObj.new()
	source_obj.test_array.append(foo_element)
	changed.emit()
	await wait_physics_frames(1)
	assert_eq_deep(target_data_node.value(), [0])
	assert_eq(target_data_node.size(), 1)
	foo_element.a = 1
	await wait_physics_frames(1)
	assert_eq_deep(target_data_node.value(), [1])
