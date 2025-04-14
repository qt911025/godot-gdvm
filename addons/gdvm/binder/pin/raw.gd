const Utils = preload("../../utils.gd")
const RawPin = preload("./raw.gd")
const DataNode = preload("../../core/data_node/base.gd")

const DataNodeVariant = preload("../../core/data_node/variant.gd")
const DataNodeStruct = preload("../../core/data_node/struct.gd")
const DataNodeList = preload("../../core/data_node/list.gd")
const DataNodeNode = preload("../../core/data_node/node.gd")
const FactoryOfDataNode = preload("../../core/data_node/factory.gd")

## RawPin
## 原始Pin

## 节点类型
var node_type: NodeType
enum NodeType {
	VARIANT,
	STRICT,
	STRUCT,
	LIST,
	NODE,
}

## 数据的类型，用于决定创建什么DataNode以及什么Writer
## 这是这个RawPin所代表的节点的类型，如果为NIL则为Variant，Array -> List, Dictionary -> Struct, Node -> Node, 其他则为严格数据类型
var data_type

## 基本属性，定义简单数据节点
var data

## 定义列表节点
# 注意不要把这个变量改成带类型的数组，无类型的空数组代表这个RawPin不是数组，而其他类型的空数组代表这是一个数组，且类型确定。
# 参数的data或者children设置为一个带类型的空数组，不用显式嵌套元素RawPin
var children: Array

## 定义列表属性
var properties: Dictionary

# 所钉的路径，路径分为三类：
# 1. 开头有/的，在这里不是绝对路径，而是确定首段是一个节点
# 2. 开头有:的，为确定这是一个属性
# 3. 什么都没有的，则尚未确定，会在路径检查时根据上下文适配

## 以NodePath形式存储的pin路径
var _path: NodePath

## 以实际存在的节点作为pin路径，仅用于pin节点
var _pinning_node: Node # 临时存储节点作为路径，会在路径检查时转换成合法的path

## 默认为STRUCRT或NODE类型的节点的所有属性添加RawPin
## 这是为了方便，不然所有属性都要显式RawPin
## 仅限为叶子的属性，不然无法确定属性绑的是属性还是节点（非叶子的属性可能会绑到节点，当然，得是显式的）
var pin_leaf_properties: bool = false

# todo 此节点将视为引用，将强制视为Variant，不管子树是什么类型
# var is_reference: bool = false

var sub_writer: SubWriter
class SubWriter:
	## 供写者使用的子写者元素构造器
	var alloc: Callable = func(source_data_node: DataNode) -> Object: return null
	## 供写者使用的子写者元素销毁器
	var drop: Callable = func(data: Object) -> bool: return false

func _init(opts: Dictionary) -> void:
	if opts.has("path"):
		if (Utils.type_can_be_nodepath(Utils.instance_get_type(opts.path))):
			_path = NodePath(String(opts.path))
			assert(Utils.assert_node_path_has_no_redirections(_path))
			if _path.is_absolute():
				_path = NodePath(String(_path).substr(1))
		else:
			assert(opts.path is Node)
			_pinning_node = opts.path
	
	var original_children_array

	if opts.has("children"):
		assert(Utils.type_is_array(typeof(opts.children)))
		children = Array(opts.children)
		original_children_array = opts.children
	if opts.has("properties"):
		assert(opts.properties is Dictionary)
		properties = opts.properties

	if opts.has("data"):
		assert(not opts.data is RawPin) # 不能RawPin中RawPin
		if Utils.type_is_array(typeof(opts.data)):
			# 如果data是数组，children必定会被忽略掉
			children = Array(opts.data)
			original_children_array = opts.data
		elif opts.data is Dictionary:
			properties = opts.data
		else:
			# 视为简单数据类型
			children = []
			properties = {}
			data = opts.data
			if data == null:
				if opts.has("type"):
					# 不为Object也合法，创建严格类型DataNode不指定初值即可
					data_type = opts.type
				# 如果没有则视为Variant
			else:
				data_type = Utils.instance_get_type(data)
	elif not opts.has("children") and not opts.has("properties"):
		assert(opts.has("type"), "RawPin: if pin has nothing, it should have a type field at least")
		data_type = opts.type

	# 识别数组元素类型，为数组创建元素类型的元素pin，包括无类型的数组（data和type皆为null）
	if original_children_array != null and children.is_empty():
		var default_element_pin := create_default_element_pin(original_children_array)
		if default_element_pin != null:
			children = [default_element_pin]

	# 构造子RawPin树并确定node_type
	if not children.is_empty():
		assert(children.size() == 1, "RawPin: list children should only have one element as template")
		children = [build(children[0])]
		# 元素节点必须指定数据类型，除了variant和node外会隐式分配一个。所以node需要显式指定一个类型（可以是非RefCounted，比如Node，但其释放后果自负）
		# 暂时禁止Variant，后面再考虑添加弱类型List的支持
		if not properties.is_empty():
			node_type = NodeType.NODE
			data_type = DataNodeNode.NodeDataBucket # 无视另外指定的类型
			for key in properties:
				properties[key] = build(properties[key])
		else:
			node_type = NodeType.LIST
			# 拧紧阶段才检查元素和目标数组类型是否匹配，而非检查元素是否和DataNodeList匹配
			if data_type == null or !Utils.type_is_array(data_type):
				data_type = TYPE_ARRAY
	elif not properties.is_empty():
		for key in properties:
			properties[key] = build(properties[key])
		node_type = NodeType.STRUCT
		data_type = TYPE_DICTIONARY
	elif Utils.type_has_strict_data_node(data_type):
		node_type = NodeType.STRICT
	else:
		node_type = NodeType.VARIANT

	if opts.has("alloc"):
		assert(opts.alloc is Callable)
		if sub_writer == null:
			sub_writer = SubWriter.new()
		sub_writer.alloc = opts.alloc
	
	if opts.has("drop"):
		assert(opts.drop is Callable)
		if sub_writer == null:
			sub_writer = SubWriter.new()
		sub_writer.drop = opts.drop

	if opts.has("pin_leaf_properties"):
		assert(opts.pin_leaf_properties is bool)
		if node_type == NodeType.NODE or node_type == NodeType.STRUCT:
			pin_leaf_properties = opts.pin_leaf_properties

## 由代入创建Binder的参数封装成全PinTree的形式
static func build(data_opts: Variant) -> RawPin:
	# 因为尚未知晓基对象是什么类型，所以先不处理路径
	# RawPin树与DataNode树是同构的，可以确定每个RawPin节点对应的DataNode树是什么类型，但这个阶段暂不创建DataNode树
	var result: RawPin
	match Utils.instance_get_type(data_opts):
		RawPin:
			result = data_opts
		TYPE_DICTIONARY:
			result = RawPin.new({
				properties = data_opts
			})
		var array_type when Utils.type_is_array(array_type):
			result = RawPin.new({
				children = data_opts
			})
		_:
			result = RawPin.new({
				data = data_opts
			})
	return result

## 根据传入的数组的特征创建默认的元素RawPin
static func create_default_element_pin(array: Variant) -> RawPin:
	assert(Utils.type_is_array(Utils.instance_get_type(array)), "RawPin: create_default_element_pin should be called with an array")
	var element_type = Utils.array_get_element_type(array)
	return RawPin.new({
		"data": Utils.type_get_default(element_type),
		"type": element_type,
	})
