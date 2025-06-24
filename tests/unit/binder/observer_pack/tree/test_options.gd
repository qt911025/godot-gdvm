extends GutTest

const ObserverTreeOptions = preload("res://addons/gdvm/binder/observer_pack/tree/options.gd")

# var test_opts: ObserverTreeOptions

# func before_each():
# 	test_opts = null

func test_property_type_default_initialization():
	var test_opts := ObserverTreeOptions.new({})
	assert_eq(test_opts.type, ObserverTreeOptions.Type.PROPERTY)
	assert_true(test_opts.properties.is_empty())
	assert_null(test_opts.children)

func test_explicit_type_assignment():
	var test_opts := ObserverTreeOptions.new({
		"type": ObserverTreeOptions.Type.NODE,
		"children": ObserverTreeOptions.new({})
	})
	assert_eq(test_opts.type, ObserverTreeOptions.Type.NODE)
	assert_not_null(test_opts.children)

func test_node_path_normalization():
	var test_opts := ObserverTreeOptions.new({
		"path": "/root/subnode",
		"type": ObserverTreeOptions.Type.PROPERTY
	})
	assert_eq(str(test_opts.path), "root/subnode")

func test_property_configuration():
	var test_opts := ObserverTreeOptions.new({
		"type": ObserverTreeOptions.Type.PROPERTY,
		"properties": {
			"health": {},
			"name": {}
		}
	})
	assert_eq(test_opts.properties.size(), 2)
	assert_true(test_opts.properties.has("health"))
	assert_true(test_opts.properties.has("name"))

func test_complex_dictionary_builder():
	var built = ObserverTreeOptions.build({
		"": ObserverTreeOptions.new({"type": ObserverTreeOptions.Type.PROPERTY})
	})
	assert_eq(built.type, ObserverTreeOptions.Type.PROPERTY_DICTIONARY)
	assert_not_null(built.children)

func test_complex_array_builder():
	var built = ObserverTreeOptions.build([ObserverTreeOptions.new({
		"type": ObserverTreeOptions.Type.PROPERTY
	})])
	assert_eq(built.type, ObserverTreeOptions.Type.PROPERTY_ARRAY)
	assert_not_null(built.children)
