extends GutTest

const WriterTreeTemplate = preload("res://addons/gdvm/binder/writer_pack/tree/template.gd")
const WriterTreeOptions = preload("res://addons/gdvm/binder/writer_pack/tree/options.gd")
const Utils = Gdvm.Utils

var dummy_alloc = func(_n): return RefCounted.new()
var dummy_drop = func(_n): return false

func test_node_type_root_creation():
	var opts = WriterTreeOptions.new({
		"type": WriterTreeOptions.Type.NODE,
		"path": ^"",
		"children": WriterTreeOptions.new({
			"type": WriterTreeOptions.Type.PROPERTY,
			"path": ^":child_prop"
		})
	})
	var template := WriterTreeTemplate.new(opts)
	
	assert_eq(template.data.size(), 1, "Should create root node entry")
	assert_eq(template.data[^""].type, WriterTreeOptions.Type.NODE, "Root should be NODE type")
	assert_not_null(template.data[^""].children, "Node type should have children template")

func test_property_path_generation():
	var opts = WriterTreeOptions.build({
		"parent": {
			"child": WriterTreeOptions.new({
				"type": WriterTreeOptions.Type.PROPERTY,
				"path": ^":child_prop"
			})
		}
	})
	var template := WriterTreeTemplate.new(opts)

	assert_true(template.data.has(^"parent/child"), "Should generate nested data node path")
	assert_eq(template.data[^"parent/child"].path, ^":child_prop", "Should concatenate property paths")

func test_complex_structure_with_subwriters():
	var opts = WriterTreeOptions.new({
		"type": WriterTreeOptions.Type.PROPERTY_ARRAY,
		"path": ^":foo_array",
		"alloc": dummy_alloc,
		"drop": dummy_drop,
		"children": WriterTreeOptions.new({
			"type": WriterTreeOptions.Type.PROPERTY,
			"path": ^":element"
		})
	})
	var template := WriterTreeTemplate.new(opts)
	
	assert_eq(template.data.size(), 1)
	assert_eq(template.data[^""].type, WriterTreeOptions.Type.PROPERTY_ARRAY)
	assert_eq(template.data[^""].sub_writer.alloc, dummy_alloc, "Should assign subwriter callbacks")

func test_path_normalization_rules():
	var opts = WriterTreeOptions.new({
		"type": WriterTreeOptions.Type.NODE,
		"path": "/absolute/node/path",
		"children": WriterTreeOptions.new({
			"type": WriterTreeOptions.Type.PROPERTY,
			"path": ^":child_prop"
		})
	})
	var template := WriterTreeTemplate.new(opts)
	
	assert_eq(template.data[^""].path, ^"absolute/node/path", "Should normalize absolute paths")
	assert_eq(template.data[^""].path.get_subname_count(), 0, "Node path should have no subnames")
