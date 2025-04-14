extends GutTest

const RawPin = Gdvm.Pin

func test_build_with_simple_data():
	var pin = RawPin.build(42)
	assert_eq(pin.node_type, RawPin.NodeType.STRICT)
	assert_eq(pin.data, 42)
	assert_eq(pin.data_type, TYPE_INT)

func test_build_with_dictionary():
	var pin = RawPin.build({"key": 10})
	assert_eq(pin.node_type, RawPin.NodeType.STRUCT)
	assert_true(pin.properties.has("key"))
	assert_eq(pin.data_type, TYPE_DICTIONARY)
	var property_pin = pin.properties["key"]
	assert_eq(property_pin.data, 10)
	assert_eq(property_pin.data_type, TYPE_INT)
	assert_eq(property_pin.node_type, RawPin.NodeType.STRICT)

func test_build_with_array():
	var pin = RawPin.build([1])
	assert_eq(pin.node_type, RawPin.NodeType.LIST)
	assert_eq(pin.children.size(), 1)
	assert_eq(pin.data_type, TYPE_ARRAY)
	var element_pin = pin.children[0]
	assert_eq(element_pin.data, 1)
	assert_eq(element_pin.data_type, TYPE_INT)
	assert_eq(element_pin.node_type, RawPin.NodeType.STRICT)

func test_build_with_typed_array():
	var pin = RawPin.build(PackedColorArray())
	assert_eq(pin.node_type, RawPin.NodeType.LIST)
	assert_eq(pin.children.size(), 1)
	assert_eq(pin.data_type, TYPE_ARRAY)
	var element_pin = pin.children[0]
	assert_eq(element_pin.data, Color())
	assert_eq(element_pin.data_type, TYPE_COLOR)
	assert_eq(element_pin.node_type, RawPin.NodeType.STRICT)

func test_build_with_reference():
	var obj := RefCounted.new()
	var pin = RawPin.build(obj)
	assert_eq(pin.node_type, RawPin.NodeType.VARIANT)
	assert_eq(pin.data_type, "RefCounted")

func test_create_default_element_pin():
	var arr: Array[RefCounted]
	var element_pin = RawPin.create_default_element_pin(arr)
	assert_eq(element_pin.data_type, "RefCounted")
	assert_eq(element_pin.data, null)

func test_node_path_initialization():
	var pin = RawPin.new({
		"type": null,
		"path": "test/path"
	})
	assert_eq(str(pin._path), "test/path")

func test_pinning_node_initialization():
	var node = Node.new()
	var pin = RawPin.new({
		"type": null,
		"path": node
	})
	assert_eq(pin._pinning_node, node)
	autoqfree(node)

func test_properties_initialization():
	var pin = RawPin.new({
		"properties": {
			"prop1": 10,
			"prop2": "text"
		}
	})
	assert_eq(pin.node_type, RawPin.NodeType.STRUCT)
	assert_eq(pin.properties.size(), 2)

func test_children_initialization():
	var pin = RawPin.new({
		"children": [ {"data": 10}]
	})
	assert_eq(pin.node_type, RawPin.NodeType.LIST)
	assert_eq(pin.children.size(), 1)

func test_node_initialization():
	var pin = RawPin.new({
		"properties": {
			"foo": 42,
		},
		"children": [ {"data": 10}]
	})
	assert_eq(pin.node_type, RawPin.NodeType.NODE)
	assert_eq(pin.properties.size(), 1)
	assert_eq(pin.properties["foo"].data, 42)
	assert_eq(pin.children.size(), 1)

func test_strict_type_initialization():
	var pin = RawPin.new({
		"type": TYPE_VECTOR2
	})
	assert_eq(pin.node_type, RawPin.NodeType.STRICT)
	assert_eq(pin.data_type, TYPE_VECTOR2)

func test_subwriter_initialization():
	var test_alloc = func(_n): return null
	var pin = RawPin.new({
		"type": null,
		"alloc": test_alloc,
		"drop": func(_n): return true
	})
	assert_not_null(pin.sub_writer)
	assert_eq(pin.sub_writer.alloc, test_alloc)
