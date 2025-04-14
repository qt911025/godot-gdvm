extends GutTest
const Binder = Gdvm.Binder
const Pin = Gdvm.Pin

func test_no_binding() -> void:
	# variant
	var node_1 := Node.new()
	var binder_1 := Binder.new(node_1, {
		"data": "example_string",
	})
	assert_true(binder_1.data is Gdvm.DataNodeString)
	assert_eq(binder_1.data.value(), "example_string")
	autoqfree(node_1)
	# struct
	var node_2 := Node.new()
	var binder_2 := Binder.new(node_2, {
		"data": {
			"example_string": "example_string",
			"example_int": 1,
		},
	})
	assert_true(binder_2.data is Gdvm.DataNodeStruct)
	assert_true(binder_2.data.example_string is Gdvm.DataNodeString)
	assert_true(binder_2.data.example_int is Gdvm.DataNodeInt)
	assert_eq_deep(binder_2.data.value(), {
		"example_string": "example_string",
		"example_int": 1,
	})
	autoqfree(node_2)

func test_bind_primitive() -> void:
	var node_1 := Label.new()
	var binder_1 := Binder.new(node_1, {
		"data": Pin.new({
			"data": "example_string",
			"path": ":text",
		})
	})
	assert_true(binder_1.data is Gdvm.DataNodeString)
	assert_eq(binder_1.data.value(), "example_string")
	assert_eq(node_1.text, "example_string")
	autoqfree(node_1)

func test_bind_struct() -> void:
	var node_1 := Control.new()
	node_1.name = "Foo"
	var node_2 := Label.new()
	node_2.name = "Bar"
	node_1.add_child(node_2)
	var binder_1 := Binder.new(node_1, {
		"data": Pin.new({
			"path": "Bar",
			"data": {
				"sub": Pin.new({
					"path": ":text",
					"data": "example_string",
				}),
			},
		})
	})
	assert_true(binder_1.data is Gdvm.DataNodeStruct)
	assert_true(binder_1.data.sub is Gdvm.DataNodeString)
	assert_eq(binder_1.data.sub.value(), "example_string")
	assert_eq_deep(binder_1.data.value(), {
		"sub": "example_string",
	})
	assert_eq(node_2.text, "example_string")
	autoqfree(node_1)

func test_bind_struct_auto_bind_children() -> void:
	var node_1 := Control.new()
	node_1.name = "Foo"
	var node_2 := Label.new()
	node_2.name = "Bar"
	node_1.add_child(node_2)
	var binder_1 := Binder.new(node_1, {
		"data": Pin.new({
			"path": "Bar",
			"pin_leaf_properties": true,
			"data": {
				"text": "example_string",
				"lang": Pin.new({
					"path": ":language",
					"data": "zh_Hans_CN",
				}),
			},
		})
	})
	assert_true(binder_1.data is Gdvm.DataNodeStruct)
	assert_true(binder_1.data.text is Gdvm.DataNodeString)
	assert_eq_deep(binder_1.data.value(), {
		"text": "example_string",
		"lang": "zh_Hans_CN",
	})
	assert_eq(node_2.text, "example_string")
	assert_eq(node_2.language, "zh_Hans_CN")
	autoqfree(node_1)
