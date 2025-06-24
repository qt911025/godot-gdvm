extends GutTest

const ObserverTreeTemplate = preload("res://addons/gdvm/binder/observer_pack/tree/template.gd")
const ObserverTreeOptions = preload("res://addons/gdvm/binder/observer_pack/tree/options.gd")

static func changed_cb(_source: Object, _property_path: NodePath) -> Signal:
	return Signal()

func test_leaf_creation_with_node_type():
	var opts = ObserverTreeOptions.new({
		"type": ObserverTreeOptions.Type.NODE,
		"path": ^"",
		"children": {
			"a": ObserverTreeOptions.new({
				"type": ObserverTreeOptions.Type.PROPERTY,
				"changed": changed_cb
			}),
			"b": ObserverTreeOptions.new({
				"type": ObserverTreeOptions.Type.PROPERTY,
				"changed": changed_cb
			})
		}
	})
	var template := ObserverTreeTemplate.new(opts)
	
	assert_eq(template.data.size(), 1, "Should create root node leaf")
	assert_eq(template.data[^""].type, ObserverTreeOptions.Type.NODE, "Root node type should be NODE")

func test_property_path_generation():
	var opts = ObserverTreeOptions.build({
		"parent": {
			"child": ObserverTreeOptions.new({
				"type": ObserverTreeOptions.Type.PROPERTY,
				"changed": changed_cb
			})
		}
	})
	var template := ObserverTreeTemplate.new(opts)
	
	assert_true(template.data.has(^"parent/child"), "Should generate nested property path")

func test_complex_tree_structure():
	var opts = ObserverTreeOptions.new({
		"type": ObserverTreeOptions.Type.NODE,
		"path": ^"",
		"properties": {
			"child": ObserverTreeOptions.new({
				"type": ObserverTreeOptions.Type.PROPERTY_DICTIONARY,
				"changed": changed_cb,
				"children": ObserverTreeOptions.new({
					"path": ^":must_have_a_path",
					"type": ObserverTreeOptions.Type.PROPERTY,
					"changed": changed_cb
				})
			})
		},
		"children": {
			"a": ObserverTreeOptions.new({
				"type": ObserverTreeOptions.Type.PROPERTY,
				"changed": changed_cb
			}),
			"b": ObserverTreeOptions.new({
				"type": ObserverTreeOptions.Type.PROPERTY,
				"changed": changed_cb
			})
		}
	})
	var template := ObserverTreeTemplate.new(opts)
	assert_eq(template.data.size(), 2, "Should create both root and child entries")
	assert_eq(template.data[^"child"].type,
		ObserverTreeOptions.Type.PROPERTY_DICTIONARY,
		"Child type should be PROPERTY_DICTIONARY")