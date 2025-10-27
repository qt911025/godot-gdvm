@abstract
extends RefCounted

const DataTreeTemplate = preload("./template.gd")
const DataTreeOptions = preload("./options.gd")
const Utils = preload("../../utils.gd")

const DataNode = preload("../../core/data_node/base.gd")
const DataNodeVariant = preload("../../core/data_node/variant.gd")
const DataNodeStruct = preload("../../core/data_node/struct.gd")
const DataNodeList = preload("../../core/data_node/list.gd")
const DataNodeDict = preload("../../core/data_node/dict.gd")
const DataNodeNode = preload("../../core/data_node/node.gd")
const FactoryOfDataNode = preload("../../core/data_node/factory.gd")

## DataTreeTemplate
## 创建DataNode树的模板
## 只包含数据，不包含绑定

## 从DataTreeOptions配置构建DataTreeTemplate
@abstract
func from_tree_options(tree_opts: DataTreeOptions) -> void

## 递归地创建对应的DataNode实例
@abstract
func to_data_node() -> DataNode

## 由绑定的根目标和DataTreeOptions构建DataTreeTemplate
static func build(tree_opts: DataTreeOptions) -> DataTreeTemplate:
	var result: DataTreeTemplate
	match tree_opts.node_type:
		DataTreeOptions.NodeType.VARIANT:
			result = TemplateVariant.new()
		DataTreeOptions.NodeType.STRICT:
			result = TemplateStrict.new()
		DataTreeOptions.NodeType.STRUCT:
			result = TemplateStruct.new()
		DataTreeOptions.NodeType.LIST:
			result = TemplateList.new()
		DataTreeOptions.NodeType.DICT:
			result = TemplateDict.new()
		DataTreeOptions.NodeType.NODE:
			result = TemplateNode.new()
		var unexpected_node_type:
			push_error("build_template failed: unexpected node type %s" % tree_opts.node_type)
	result.from_tree_options(tree_opts)
	return result

class TemplateVariant extends DataTreeTemplate:
	var data
	func from_tree_options(tree_opts: DataTreeOptions) -> void:
		data = tree_opts.data
	func to_data_node() -> DataNode:
		return DataNodeVariant.new(data)

class TemplateStrict extends DataTreeTemplate:
	var data
	func from_tree_options(tree_opts: DataTreeOptions) -> void:
		assert(Utils.type_has_strict_data_node(tree_opts.data_type))
		if Utils.instance_is_type(tree_opts.data, tree_opts.data_type):
			data = tree_opts.data
		else:
			data = Utils.type_get_default(tree_opts.data_type)
	func to_data_node() -> DataNode:
		return FactoryOfDataNode.create_strict_data_node(data)

class TemplateStruct extends DataTreeTemplate:
	var properties: Dictionary[StringName, DataTreeTemplate]
	var computed: Array[Dictionary]
	func from_tree_options(tree_opts: DataTreeOptions) -> void:
		var data = tree_opts.data
		properties.clear()
		if data.has("properties"):
			for key in data.properties:
				properties[StringName(key)] = build(data.properties[key])
		
		computed.clear()
		if data.has("computed"):
			var computed_size := (data.computed as Array).size()
			computed.resize(computed_size)
			for i in computed_size:
				var comp_options := data.computed[i] as Dictionary
				var outputs := {}
				for key in comp_options.outputs as Dictionary:
					outputs[StringName(key)] = build(comp_options.outputs[key])
				computed[i] = {
					dependencies = comp_options.dependencies.duplicate(),
					outputs = outputs,
					computer = Callable(comp_options.computer),
				}

	func to_data_node() -> DataNode:
		var result = DataNodeStruct.new()
		for key: StringName in properties:
			result.add_property(key, properties[key].to_data_node())
		for comp: Dictionary in computed:
			var outputs := {}
			for key in comp.outputs:
				outputs[StringName(key)] = comp.outputs[key].to_data_node()
			result.add_computed_properties(comp.dependencies, outputs, comp.computer)
		return result

class TemplateList extends DataTreeTemplate:
	var element_type
	var element_template: DataTreeTemplate
	func from_tree_options(tree_opts: DataTreeOptions) -> void:
		assert(tree_opts.data is Array and tree_opts.data.size() == 1)
		var element_tree_opts := tree_opts.data[0] as DataTreeOptions
		element_type = element_tree_opts.data_type
		element_template = build(element_tree_opts)
	func to_data_node() -> DataNode:
		return DataNodeList.new(element_type, func() -> DataNode:
			return element_template.to_data_node()
		)

class TemplateDict extends DataTreeTemplate:
	var key_type
	var element_type
	var element_template: DataTreeTemplate
	func from_tree_options(tree_opts: DataTreeOptions) -> void:
		assert(tree_opts.data is Dictionary and tree_opts.data.size() == 1)
		for key in tree_opts.data as Dictionary:
			key_type = Utils.instance_get_type(key)
			var element_tree_opts := tree_opts.data[key] as DataTreeOptions
			element_type = element_tree_opts.data_type
			element_template = build(element_tree_opts)
			break
	func to_data_node() -> DataNode:
		return DataNodeDict.new(key_type, element_type, func() -> DataNode:
			return element_template.to_data_node()
		)

class TemplateNode extends TemplateStruct:
	var child_type
	var child_template: DataTreeTemplate
	func from_tree_options(tree_opts: DataTreeOptions) -> void:
		var data = tree_opts.data
		assert(data is Dictionary and data.children is Array and data.children.size() == 1)
		var element_tree_opts := data.children[0] as DataTreeOptions
		child_type = element_tree_opts.data_type
		child_template = build(element_tree_opts)
		super.from_tree_options(tree_opts)
	func to_data_node() -> DataNode:
		var result = DataNodeNode.new(child_type, func() -> DataNode:
			return child_template.to_data_node()
		)
		for key: StringName in properties:
			result.add_property(key, properties[key].to_data_node())
		for comp: Dictionary in computed:
			var outputs := {}
			for key in comp.outputs:
				outputs[StringName(key)] = comp.outputs[key].to_data_node()
			result.add_computed_properties(comp.dependencies, outputs, comp.computer)
		return result
