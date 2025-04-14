extends GutTest

const Utils = Gdvm.Utils

class TestClass:
	pass

# var TestClass = Gdvm.DataNodeBasis

func test_instance_get_type():
	# Test primitive type
	assert_eq(Utils.instance_get_type(42), TYPE_INT)
	# Test built-in class
	var t_obj := Object.new()
	assert_eq(Utils.instance_get_type(t_obj), &"Object")
	var t_node := Node.new()
	assert_eq(Utils.instance_get_type(t_node), &"Node")
	autoqfree(t_node)
	# Test scripted instance
	var t_instance := TestClass.new()
	assert_eq(Utils.instance_get_type(t_instance), TestClass)

func test_instance_is_type():
		var node = Node.new()
		# Test primitive type
		assert_true(Utils.instance_is_type(42, TYPE_INT))
		# Test built-in class
		assert_true(Utils.instance_is_type(node, "Node"))
		# Test script inheritance
		assert_true(Utils.instance_is_type(TestClass.new(), TestClass))
		autoqfree(node)

func test_type_get_default():
		# Test primitive defaults
		assert_eq(Utils.type_get_default(TYPE_INT), 0)
		assert_eq(Utils.type_get_default(TYPE_VECTOR3), Vector3())
		# Test object type
		assert_null(Utils.type_get_default(&"Node"))

func test_type_is_legal():
		# Valid types
		assert_true(Utils.type_is_legal(TYPE_INT))
		assert_true(Utils.type_is_legal(&"Node"))
		# Invalid types
		assert_false(Utils.type_is_legal("Node", true)) # Strict mode
		assert_false(Utils.type_is_legal(Vector3()))

func test_make_type_strict():
		assert_eq(Utils.make_type_strict("Node"), &"Node")
		assert_eq(Utils.make_type_strict(&"Node"), &"Node")

func test_type_get_string():
		# Test primitive
		assert_eq(Utils.type_get_string(TYPE_INT), "int")
		# Test built-in class
		assert_eq(Utils.type_get_string(&"Node"), "Node")
		# Test script
		assert_string_contains(Utils.type_get_string(Utils), "utils.gd")

func test_type_is_type():
		# Test inheritance
		assert_true(Utils.type_is_type(&"Node3D", &"Node"))
		# Test script inheritance
		var t_instance := TestClass.new()
		assert_true(Utils.type_is_type(t_instance.get_script(), TestClass))

func test_type_has_strict_data_node():
		assert_true(Utils.type_has_strict_data_node(TYPE_INT))
		assert_false(Utils.type_has_strict_data_node(&"Node"))

func test_type_is_array():
		assert_true(Utils.type_is_array(TYPE_ARRAY))
		assert_true(Utils.type_is_array(TYPE_PACKED_VECTOR3_ARRAY))
		assert_false(Utils.type_is_array(TYPE_INT))

func test_array_get_element_type():
		var typed_array = PackedVector3Array()
		assert_eq(Utils.array_get_element_type(typed_array), TYPE_VECTOR3)
		
		var untyped_array = []
		assert_null(Utils.array_get_element_type(untyped_array))

func test_node_path_is_empty():
		assert_true(Utils.node_path_is_empty(NodePath()))
		assert_true(Utils.node_path_is_empty(NodePath("/")))
		assert_false(Utils.node_path_is_empty(NodePath("test")))

func test_pack_scene():
		var node = Node.new()
		var scene = Utils.pack_scene(node)
		assert_is(scene, PackedScene)
		autoqfree(node)

# func test_assert_node_path_redirections():
# 		# Valid path
# 		expect("assert_node_path_has_no_redirections").to().call_with(NodePath("valid/path")).and_pass()
# 		# Invalid path
# 		expect("assert_node_path_has_no_redirections").to().call_with(NodePath("../invalid")).and_raise_error()
