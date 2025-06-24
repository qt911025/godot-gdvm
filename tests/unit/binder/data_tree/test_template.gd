extends GutTest

const Utils = Gdvm.Utils

const DataTreeOptions = preload("res://addons/gdvm/binder/data_tree/options.gd")
const DataTreeTemplate = preload("res://addons/gdvm/binder/data_tree/template.gd")

const DataNodeNode = Gdvm.DataNodeNode
const DataNodeStruct = Gdvm.DataNodeStruct
const DataNodeVariant = Gdvm.DataNodeVariant
const DataNodeInt = Gdvm.DataNodeInt

# var test_opts: DataTreeOptions
# var test_template: DataTreeTemplate

# func before_each():
# 	test_opts = DataTreeOptions.new()
# 	test_template = null

func test_variant_template_creation():
	var test_opts := DataTreeOptions.new({
		type = DataTreeOptions.NodeType.VARIANT,
		data = 42,
	})
	var test_template := DataTreeTemplate.build(test_opts)
	
	assert_true(test_template is DataTreeTemplate.TemplateVariant)
	var node := test_template.to_data_node()
	# todo 以后再实现默认值
	assert_true(node is DataNodeVariant)

func test_strict_template_creation():
	var test_opts := DataTreeOptions.build(42)
	var test_template := DataTreeTemplate.build(test_opts)
	
	assert_true(test_template is DataTreeTemplate.TemplateStrict)
	var node := test_template.to_data_node()
	# todo 以后再实现默认值
	assert_true(node is DataNodeInt)

func test_struct_template_properties():
	var test_opts := DataTreeOptions.build({
		"health": 0,
		"name": "",
	})
	var test_template := DataTreeTemplate.build(test_opts)
	assert_true(Utils.instance_is_type(test_template, DataTreeTemplate.TemplateStruct))
	assert_true(test_template.properties.has("health"))
	assert_true(test_template.properties.has("name"))

	var node = test_template.to_data_node()
	assert_true(Utils.instance_is_type(node, DataNodeStruct))
	assert_eq(node.has_data_property("health"), true)
	assert_eq(node.has_data_property("name"), true)

func test_list_template_factory():
	var test_opts := DataTreeOptions.build([0.0])
	var test_template := DataTreeTemplate.build(test_opts)
	
	var node := test_template.to_data_node()
	assert_true(node is DataTreeTemplate.DataNodeList)
	assert_eq(node.size(), 0)
	node.append(3.14)
	assert_eq(node.size(), 1)
	assert_eq_deep(node.value(), [3.14])

func test_node_template_child_creation():
	var test_opts := DataTreeOptions.new({
		"properties": {
			"health": 0,
			"name": ""
		},
		"children": [0.0]
	})
	var test_template := DataTreeTemplate.build(test_opts)
	assert_true(test_template is DataTreeTemplate.TemplateNode)

	var node = test_template.to_data_node()
	assert_true(Utils.instance_is_type(node, DataNodeNode))
	assert_eq(node.has_data_property("health"), true)
	assert_eq(node.has_data_property("name"), true)
