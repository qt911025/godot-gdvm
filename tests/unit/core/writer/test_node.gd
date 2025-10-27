extends GutTest

const WriterNode = Gdvm.WriterNode
const WriterProperty = Gdvm.WriterProperty
const DataNodeList = Gdvm.DataNodeList
const DataNodeInt = Gdvm.DataNodeInt

class TestSuperNode extends Node:
	pass

class TestSubNode extends Node:
	var a: int

func test_observe_node() -> void:
	var target_obj := TestSuperNode.new()
	var source_data_node := DataNodeList.new(TYPE_INT, func(): return DataNodeInt.new(0))
	var _writer := WriterNode.new(
		target_obj,
		source_data_node,
		WriterNode.ChildSubWriter.new(
			func(chlid_data_node: DataNodeInt) -> Node:
				var result := TestSubNode.new()
				result.a = chlid_data_node.value()
				return result
				,
			func(chlid_data_node: DataNodeInt, target_node: Node) -> Array:
				return [WriterProperty.new(target_node, ^":a", chlid_data_node)]
				)
	)
	assert_eq(target_obj.get_child_count(), 0)
	source_data_node.append(1)
	await wait_physics_frames(1)
	assert_eq(target_obj.get_child_count(), 1)
	assert_eq(target_obj.get_child(0).a, 1)
	autoqfree(target_obj)