extends GutTest

const Observer = Gdvm.Observer
const ObserverProperty = Gdvm.ObserverProperty
const ObserverNode = Gdvm.ObserverNode
const DataNode = Gdvm.DataNode
const DataNodeList = Gdvm.DataNodeList
const DataNodeInt = Gdvm.DataNodeInt

class TestSuperNode extends Node:
	pass

class TestSubNode extends Node:
	signal changed
	var a: int:
		set(value):
			a = value
			changed.emit()

func test_observe_node() -> void:
	var source_obj := TestSuperNode.new()
	var target_data_node := DataNodeList.new(TYPE_INT, func(): return DataNodeInt.new(0))
	var _observer := ObserverNode.new(
		source_obj,
		target_data_node,
		func(source_child: Object, target_element: DataNode) -> Array:
			return [ObserverProperty.new(source_child, ^":a", target_element, source_child.changed)]
	)
	assert_eq(target_data_node.size(), 0)
	var foo_child := TestSubNode.new()
	source_obj.add_child(foo_child)
	await wait_physics_frames(1)
	assert_eq_deep(target_data_node.value(), [0])
	assert_eq(target_data_node.size(), 1)
	foo_child.a = 1
	await wait_physics_frames(1)
	assert_eq_deep(target_data_node.value(), [1])
	autoqfree(source_obj)
