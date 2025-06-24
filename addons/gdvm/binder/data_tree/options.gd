const Utils = preload("../../utils.gd")
const DataTreeOptions = preload("./options.gd")
const DataNode = preload("../../core/data_node/base.gd")

const DataNodeVariant = preload("../../core/data_node/variant.gd")
const DataNodeStruct = preload("../../core/data_node/struct.gd")
const DataNodeList = preload("../../core/data_node/list.gd")
const DataNodeDict = preload("../../core/data_node/dict.gd")
const DataNodeNode = preload("../../core/data_node/node.gd")
const FactoryOfDataNode = preload("../../core/data_node/factory.gd")

## DataTreeOptions

## Struct类型标注
## DataNodeStruct本身不保存数据，当需要显式指定节点的数据类型时，使用这个类型，来与字典作区分
class Struct:
	pass

## 节点类型
var node_type: NodeType
enum NodeType {
	VARIANT,
	STRICT,
	STRUCT,
	LIST,
	DICT,
	NODE,
}

## 数据的类型，用于决定创建什么DataNode以及什么Writer
var data_type

## 基本属性，定义简单数据节点（Data不能是TreeOptions）
## 约定格式：
## Node： {children: [...], properties: {...}, computed: [...]} --> 即数组与struct的并集
## 数组： [元素配置]
## 字典： {key: 值配置} 其中 key的值的类型决定这个配置的key类型。无类型用null，只有一个键值对
## struct: {properties: {属性: 值配置} computed: [{dependencies: [], outputs: {属性:值配置}, computer: Callable}]}
##         由于属性必须是非空StringName，所以以StringName为键的字典，键只能用空StringName
## 其他类型：直接用值配置
var data

func _init(opts: Dictionary) -> void:
	opts = opts.duplicate()
	if opts.has("data"):
		# 数组、字典、Struct类型的data自动转移到properties或children
		var type_of_data = Utils.instance_get_type(opts.data)
		match type_of_data:
			TYPE_DICTIONARY:
				if Utils.dictionary_is_struct(opts.data):
					if not opts.has("properties"):
						opts.properties = opts.data
				else:
					if not opts.has("children"):
						opts.children = opts.data
				opts.erase("data")
			var array_type when Utils.type_is_array(array_type):
				if not opts.has("children"):
					opts.children = opts.data
				opts.erase("data")
			DataTreeOptions:
				push_error("DataTreeOptions: nested data tree options is not permitted. In options %s" % opts)

	if not opts.has("type"):
		# 隐式类型自动补全
		if opts.has("children") and opts.has("properties"):
			opts.type = DataNodeNode.NodeDataBucket
		elif opts.has("properties"):
			opts.type = Struct
		elif opts.has("children"):
			var type_of_children = Utils.instance_get_type(opts.children)
			if Utils.type_is_array(type_of_children) or Utils.type_is_type(type_of_children, TYPE_DICTIONARY):
				opts.type = type_of_children
			else:
				push_error("DataTreeOptions: Children field should be an array or a dictionary. In options %s" % opts)
		elif opts.has("data"):
			var type_of_data = Utils.instance_get_type(opts.data)
			if Utils.type_has_strict_data_node(type_of_data):
				opts.type = type_of_data
			else:
				opts.type = null

	assert(Utils.type_is_legal(opts.type))
	var type = Utils.make_type_strict(opts.type)
	if typeof(type) == TYPE_INT:
		if Utils.type_is_array(type):
			node_type = NodeType.LIST
			data_type = TYPE_ARRAY
			if opts.has("children") and Utils.instance_is_array(opts.children):
				if opts.children.size() == 1:
					data = [build(opts.get("children")[0])]
				else:
					data = [create_default_array_data(opts.children)]
			else:
				data = [create_default_array_data(Utils.type_get_default(type))]
		elif type == TYPE_DICTIONARY:
			node_type = NodeType.DICT
			data_type = TYPE_DICTIONARY
			if opts.has("children") and Utils.instance_is_type(opts.children, TYPE_DICTIONARY):
				if opts.children.size() == 1:
					var default_key = Utils.type_get_default(Utils.instance_get_type(opts.children.keys()[0]))
					var default_value = build(opts.children.values()[0])
					data = {default_key: default_value}
				else:
					data = create_default_dictionary_data(opts.children)
			else:
				data = create_default_dictionary_data()
		elif Utils.type_has_strict_data_node(type):
			node_type = NodeType.STRICT
			data_type = type
			if opts.has("data") and Utils.instance_is_type(opts.data, type):
				data = opts.data
			else:
				data = Utils.type_get_default(type)
		else: # 只剩Callable 和 Signal了
			node_type = NodeType.VARIANT
			data_type = type
			if opts.has("data") and Utils.instance_is_type(opts.data, type):
				data = opts.data
			else:
				data = Utils.type_get_default(type)
	elif Utils.type_is_type(type, DataNodeNode.NodeDataBucket) or Utils.type_is_type(type, "Node"):
		# Node
		# 显式指定，node_type应该根据children、properties的有无决定NodeType
		var temp_data := {}
		if opts.has("children") and Utils.instance_is_array(opts.children):
			if opts.children.size() == 1:
				temp_data.children = [build(opts.get("children")[0])]
			else:
				temp_data.children = [create_default_array_data(opts.children)]
		if opts.has("properties") and Utils.instance_is_type(opts.properties, TYPE_DICTIONARY) and not opts.properties.is_empty():
			temp_data.properties = {}
			for key in opts.properties:
				assert(key is StringName or key is String, "DataTreeOptions: properties key %s should be StringName or String" % key)
				temp_data.properties[StringName(key)] = build(opts.properties[key])
		if temp_data.has("children") and temp_data.has("properties"):
			node_type = NodeType.NODE
			data_type = DataNodeNode.NodeDataBucket
			data = temp_data
		elif temp_data.has("children"):
			node_type = NodeType.LIST
			data_type = TYPE_ARRAY
			data = temp_data.children
		elif temp_data.has("properties"):
			node_type = NodeType.STRUCT
			data_type = Struct
			data = {
				properties = temp_data.properties
			}
		else:
			push_error("DataTreeOptions: node configuration cannot be empty, in options  %s", opts)
	elif Utils.type_is_type(type, Struct):
		# struct
		if opts.has("properties") and Utils.instance_is_type(opts.properties, TYPE_DICTIONARY):
			node_type = NodeType.STRUCT
			data_type = Struct
			var props := {}
			assert(not opts.properties.is_empty(), "DataTreeOptions: properties cannot be empty, in options  %s" % opts)
			for key in opts.properties:
				assert(key is StringName or key is String, "DataTreeOptions: properties key %s should be StringName or String" % key)
				props[StringName(key)] = build(opts.properties[key])
			data = {
				properties = props
			}
	else:
		node_type = NodeType.VARIANT
		data_type = type
		if opts.has("data") and Utils.instance_is_type(opts.data, type):
			data = opts.data
		else:
			data = Utils.type_get_default(type)

	# add computed configurations to struct
	if opts.has("computed"):
		assert(Utils.instance_get_type(opts.computed) == TYPE_ARRAY)
		assert(node_type == NodeType.NODE or node_type == NodeType.STRUCT, "DataTreeOptions: Only Node and Struct can config computed. in options %s" % opts)
		# 检查依赖，按依赖排序
		var confirmed_properties := {}
		var unconfirmed_computed := (opts.computed as Array).duplicate()
		var sorted_computed := []
		(data.properties as Dictionary).keys().map(func(key: StringName) -> void: confirmed_properties[key] = null)
		var unconfirmed_computed_check_count := 0
		while unconfirmed_computed_check_count < unconfirmed_computed.size(): # 相等时，要么全遍历了一遍，要么为0
			var computed_opts: Dictionary = unconfirmed_computed[unconfirmed_computed_check_count]
			assert(computed_opts is Dictionary and computed_opts.has("dependencies") and computed_opts.dependencies is Array and \
			computed_opts.has("outputs") and computed_opts.outputs is Dictionary and \
			computed_opts.has("computer") and computed_opts.computer is Callable)
			var unconfirmed := false
			for dependency in computed_opts.dependencies:
				assert(dependency is StringName or dependency is String, "DataTreeOptions: computed dependency %s should be StringName or String" % dependency)
				if not confirmed_properties.has(dependency):
					unconfirmed = true
					break
			if unconfirmed:
				unconfirmed_computed_check_count += 1
			else:
				var dependencies := []
				dependencies.resize(computed_opts.dependencies.size())
				for i in computed_opts.dependencies.size():
					dependencies[i] = (StringName(computed_opts.dependencies[i]))

				var outputs := {}
				for output_key in computed_opts.outputs:
					confirmed_properties[output_key] = null
					outputs[StringName(output_key)] = build(computed_opts.outputs[output_key])

				var constructed_computed_opts := {
					dependencies = dependencies,
					outputs = outputs,
					computer = computed_opts.computer
				}
				sorted_computed.append(constructed_computed_opts)
				unconfirmed_computed.remove_at(unconfirmed_computed_check_count)
				unconfirmed_computed_check_count = 0
		if unconfirmed_computed.size() > 0:
			push_error("DataTreeOptions: computed cannot be resolved, computed: %s has invalid dependencies. in options %s" % [unconfirmed_computed, opts])
		else:
			data.computed = sorted_computed

## 由语法糖创建完整的DataTreeOptions
static func build(data_opts: Variant) -> DataTreeOptions:
	var result: DataTreeOptions
	if Utils.instance_is_type(data_opts, DataTreeOptions):
		result = data_opts
	else:
		result = DataTreeOptions.new({
			data = data_opts
		})
	return result

## 根据传入的数组的特征创建默认的元素DataTreeOptions
static func create_default_array_data(array: Variant = []) -> DataTreeOptions:
	assert(Utils.instance_is_array(array), "DataTreeOptions: create_default_array_data should be called with an array")
	var element_type = Utils.array_get_element_type(array)
	return DataTreeOptions.new({
		"data": Utils.type_get_default(element_type),
		"type": element_type,
	})

## 根据传入的字典的特征创建默认的元素DataTreeOptions
static func create_default_dictionary_data(dict: Dictionary = {}) -> Dictionary:
	var kb := dict.get_typed_key_builtin()
	var kc := dict.get_typed_key_class_name()
	var ks := dict.get_typed_key_script()
	var vb := dict.get_typed_value_builtin()
	var vc := dict.get_typed_value_class_name()
	var vs := dict.get_typed_value_script()
	var default_key_type = Utils.type_from_godot_to_gdvm_style(kb, kc, ks)
	var default_key = Utils.type_get_default(default_key_type)
	var default_value_type = Utils.type_from_godot_to_gdvm_style(vb, vc, vs)
	var default_value = Utils.type_get_default(default_value_type)
	var result := Dictionary({}, kb, kc, ks, TYPE_OBJECT, "RefCounted", DataTreeOptions)
	result[default_key] = DataTreeOptions.new({
		"data": default_value,
		"type": default_value_type,
	})
	return result
