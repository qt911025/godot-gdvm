const ExtraPin = preload("./extra.gd")
const PurePin = preload("./pure.gd")
const Pin = preload("./raw.gd")

# const SubWriter = preload("./sub_writer.gd")

const Utils = preload("../../utils.gd")

const DataNode = preload("../../core/data_node/base.gd")
const DataNodeVariant = preload("../../core/data_node/variant.gd")
const DataNodeStruct = preload("../../core/data_node/struct.gd")
const DataNodeList = preload("../../core/data_node/list.gd")
const DataNodeNode = preload("../../core/data_node/node.gd")
const FactoryOfDataNode = preload("../../core/data_node/factory.gd")


enum PinType {
	NODE,
	PROPERTY
}

var pure_pin: PurePin
var pathed_trait: Pathed
var structed_trait: Structed
var listed_trait: Listed

# func to_data_node() -> DataNode:
# 	return pure_pin.to_data_node()

## 这个Pin所具有的特质
class ExtraPinTraits:
	pass

## 绑定了路径的
class Pathed extends ExtraPinTraits:
	var path: NodePath # 不包含type，因为可以根据path内容得知
	func type() -> PinType:
		if path.get_subname_count() == 0:
			return PinType.NODE
		else:
			return PinType.PROPERTY

## 有子节点的
class Structed extends ExtraPinTraits:
	var properties: Dictionary[StringName, ExtraPin]

## 有子写者的
class Listed extends ExtraPinTraits:
	var element_alloc: Callable = func(source_data_node: DataNode) -> Object: return null
	var element_drop: Callable = func(data: Object) -> bool: return false
	var element_pin: ExtraPin

## 由原始Pin构建ExtraPin 基对象为Object
## 这个过程包括了路径合法性检查、元素生成
# static func build_by_object(base: Object, pin: Pin) -> ExtraPin:

## 由原始Pin构建ExtraPin 基对象为Node
## 这个过程包括了路径合法性检查、元素生成
## 注意，这将改变基对象！
static func build(base: Object, pin: Pin) -> ExtraPin:
	var whole_pure_pin := PurePin.build(pin)
	if base is Node:
		return _link_pure_pin_node_root(base, pin, whole_pure_pin)
	else:
		return _link_pure_pin_object_root(base, pin, whole_pure_pin)

static func _link_pure_pin_node_root(base: Node, pin: Pin, pure_pin: PurePin) -> ExtraPin:
	var result := ExtraPin.new()
	result.pure_pin = pure_pin
	var current_path: NodePath
	match pin.node_type:
		Pin.NodeType.NODE:
			assert(pure_pin is PurePin.PurePinNode)
			var pure_pin_node := pure_pin as PurePin.PurePinNode
			if is_instance_valid(pin._pinning_node):
				if not base == pin._pinning_node: # 同节点必绑
					assert(base.is_ancestor_of(pin._pinning_node), "Extra Pin: node %s should be child of base: %s." % [pin._pinning_node, base])
					current_path = base.get_path_to(pin._pinning_node)
			else:
				assert(pin._path.get_subname_count() == 0, "Extra Pin: pinning path should point to a node")
				if not Utils.node_path_is_empty(pin._path):
					current_path = NodePath(pin._path.get_concatenated_names())
					assert(base.has_node(current_path), "Extra Pin: Cannot find node %s at base: %s" % [current_path, base])
			_bind_path(result, current_path)
			_bind_list(result, base, pin.children[0], pure_pin_node.child_pure_pin)
			_bind_struct(result, base, current_path, pin.pin_leaf_properties, pin.properties, pure_pin_node.properties)
		Pin.NodeType.LIST:
			assert(pure_pin is PurePin.PurePinList)
			var pure_pin_list := pure_pin as PurePin.PurePinList
			if is_instance_valid(pin._pinning_node):
				if not base == pin._pinning_node:
					assert(base.is_ancestor_of(pin._pinning_node), "Extra Pin: node %s should be child of base: %s." % [pin._pinning_node, base])
					current_path = base.get_path_to(pin._pinning_node)
			else:
				if not Utils.node_path_is_empty(pin._path):
					current_path = pin._path
			_bind_path(result, current_path)
			_bind_list(result, base, pin.children[0], pure_pin_list.element_pure_pin)
		Pin.NodeType.STRUCT:
			assert(pure_pin is PurePin.PurePinStruct)
			var pure_pin_struct := pure_pin as PurePin.PurePinStruct
			if is_instance_valid(pin._pinning_node):
				if not base == pin._pinning_node:
					assert(base.is_ancestor_of(pin._pinning_node), "Extra Pin: node %s should be child of base: %s." % [pin._pinning_node, base])
					current_path = base.get_path_to(pin._pinning_node)
			else:
				if not Utils.node_path_is_empty(pin._path):
					current_path = pin._path
			_bind_struct(result, base, current_path, pin.pin_leaf_properties, pin.properties, pure_pin_struct.properties)
		Pin.NodeType.STRICT, Pin.NodeType.VARIANT:
			assert(not is_instance_valid(pin._pinning_node), "Extra Pin: primitive type should not pin node")
			current_path = pin._path
			if not Utils.node_path_is_empty(current_path):
				assert(current_path.get_subname_count() > 0, "Extra Pin: path should be a property to pin primitive, got %s at %s" % [current_path, base])
				_bind_path(result, current_path)
		var unexpected_node_type:
			push_error("Extra Pin: unexpected node type %s. Current base is a DataNode." % unexpected_node_type)
	return result

static func _link_pure_pin_object_root(base: Object, pin: Pin, pure_pin: PurePin) -> ExtraPin:
	var result := ExtraPin.new()
	result.pure_pin = pure_pin
	assert(not is_instance_valid(pin._pinning_node), "Extra Pin: object property should not pin node")
	assert(pin._path.get_name_count() < 2 and not pin._path.is_absolute(), "Extra Pin: extra_path should not start with /")
	var current_path := pin._path.get_as_property_path()
	match pin.node_type:
		Pin.NodeType.LIST:
			assert(pure_pin is PurePin.PurePinList)
			var pure_pin_list := pure_pin as PurePin.PurePinList
			# 数组类型不能是根节点，根节点必须是对象，包含着目标数组
			assert(not Utils.node_path_is_empty(current_path), "Extra Pin: element list should not be the root of the whole data structure or element of a list")
			_bind_path(result, current_path)
			_bind_list(result, base, pin.children[0], pure_pin_list.element_pure_pin)
		Pin.NodeType.STRUCT:
			assert(pure_pin is PurePin.PurePinStruct)
			var pure_pin_struct := pure_pin as PurePin.PurePinStruct
			_bind_struct(result, base, current_path, pin.pin_leaf_properties, pin.properties, pure_pin_struct.properties)
		Pin.NodeType.STRICT, Pin.NodeType.VARIANT:
			if not Utils.node_path_is_empty(current_path):
				_bind_path(result, current_path)
		var unexpected_node_type:
			push_error("Extra Pin: unexpected node type %s. Current base is a DataNode." % unexpected_node_type)
	return result

## 对有属性的（Node和Struct），递归构建ExtraPin
## base: 基对象
## branch_path: 主干DataNode映射的目标，根据NodePath类型判断目标是节点还是属性
## pin_leaf_key_name: 自动绑定属性的键名。是否为所有未绑定的属性添加绑定，这个值应为主干Pin的 (pin_leaf_properties && 已绑定)，只有为叶子的且未绑定的属性才会自动添加（所以主干应先确定是否已绑定）
## (property_)pin: 属性pin
## (property_)pure_pin: 属性对应的PurePin
static func _link_property_pin(base: Object, branch_path: NodePath, pin_leaf_key_name: StringName, pin: Pin, pure_pin: PurePin) -> ExtraPin:
	assert(not branch_path.is_absolute())
	var result := ExtraPin.new()
	result.pure_pin = pure_pin
	var current_path := branch_path
	var should_bind_path := false
	match pin.node_type:
		Pin.NodeType.NODE:
			assert(pure_pin is PurePin.PurePinNode)
			var pure_pin_node := pure_pin as PurePin.PurePinNode
			var binding_path: NodePath # 这个节点既有struct又有list，作为list，受父节点的pin_leaf_properties作用，但绑定key的同时，不能破坏递归函数的current_path传递性
			if is_instance_valid(pin._pinning_node):
				assert(base.is_ancestor_of(pin._pinning_node), "Extra Pin: node %s should be child of base: %s." % [pin._pinning_node, base])
				current_path = base.get_path_to(pin._pinning_node)
				binding_path = current_path
				should_bind_path = true
			else:
				assert(branch_path.get_subname_count() == 0, "Extra Pin: branch path should point to a node")
				assert(pin._path.get_subname_count() == 0, "Extra Pin: pinning path should point to a node")
				if not Utils.node_path_is_empty(pin._path):
					current_path = connect_path(branch_path, pin._path)
					binding_path = current_path
					assert(base.has_node(binding_path), "Extra Pin: Cannot find node %s at base: %s" % [current_path, base])
					should_bind_path = true
				elif not pin_leaf_key_name.is_empty():
					binding_path = connect_path(branch_path, NodePath(pin_leaf_key_name).get_as_property_path())
					should_bind_path = true
			if should_bind_path:
				assert(base.has_node(binding_path), "Extra Pin: Cannot find node %s at base: %s" % [current_path, base])
				_bind_path(result, binding_path)
				_bind_list(result, base, pin.children[0], pure_pin_node.child_pure_pin)
			_bind_struct(result, base, current_path, pin.pin_leaf_properties and should_bind_path, pin.properties, pure_pin_node.properties)
		Pin.NodeType.LIST:
			assert(pure_pin is PurePin.PurePinList)
			var pure_pin_list := pure_pin as PurePin.PurePinList
			if is_instance_valid(pin._pinning_node):
				assert(base.is_ancestor_of(pin._pinning_node), "Extra Pin: node %s should be child of base: %s." % [pin._pinning_node, base])
				current_path = base.get_path_to(pin._pinning_node)
				should_bind_path = true
			elif not Utils.node_path_is_empty(pin._path):
				current_path = connect_path(branch_path, pin._path)
				should_bind_path = true
			elif not pin_leaf_key_name.is_empty():
				current_path = connect_path(branch_path, NodePath(pin_leaf_key_name).get_as_property_path())
				should_bind_path = true
			if should_bind_path:
				_bind_path(result, current_path)
				_bind_list(result, base, pin.children[0], pure_pin_list.element_pure_pin)
		Pin.NodeType.STRUCT:
			assert(pure_pin is PurePin.PurePinStruct)
			var pure_pin_struct := pure_pin as PurePin.PurePinStruct
			if is_instance_valid(pin._pinning_node):
				assert(base.is_ancestor_of(pin._pinning_node), "Extra Pin: node %s should be child of base: %s." % [pin._pinning_node, base])
				current_path = base.get_path_to(pin._pinning_node)
				should_bind_path = true
			elif not Utils.node_path_is_empty(pin._path):
				current_path = connect_path(branch_path, pin._path)
				should_bind_path = true
			_bind_struct(result, base, current_path, pin.pin_leaf_properties and should_bind_path, pin.properties, pure_pin_struct.properties)
		Pin.NodeType.STRICT, Pin.NodeType.VARIANT:
			assert(not is_instance_valid(pin._pinning_node), "Extra Pin: primitive type should not pin node")
			if not Utils.node_path_is_empty(pin._path):
				current_path = connect_path(branch_path, pin._path)
				assert(current_path.get_subname_count() > 0, "Extra Pin: path should be a property to pin primitive, got %s at %s" % [current_path, base])
				should_bind_path = true
			elif not pin_leaf_key_name.is_empty():
				current_path = connect_path(branch_path, NodePath(pin_leaf_key_name).get_as_property_path())
				should_bind_path = true
			if should_bind_path:
				_bind_path(result, current_path)
		var unexpected_node_type:
			push_error("Extra Pin: unexpected node type %s. Current base is a DataNode." % unexpected_node_type)
	return result

# builders =========================================================================================
## 绑定路径
static func _bind_path(extra_pin: ExtraPin, binding_path: NodePath) -> void:
	var pathed_trait := Pathed.new()
	pathed_trait.path = binding_path
	extra_pin.pathed_trait = pathed_trait

## 迭代属性
## bind_struct本身并不负责绑定，只负责拓展属性分支，传进来的extra_path是继续传给子节点的
static func _bind_struct(extra_pin: ExtraPin, base: Object, extra_path: NodePath, pin_leaf_properties: bool, pin_properties: Dictionary, pure_pin_node_properties: Dictionary) -> void:
	var structed_trait := Structed.new()
	extra_pin.structed_trait = structed_trait
	for key in pin_properties:
		var property_pure_pin := pure_pin_node_properties[key] as PurePin
		var property_extra_pin := _link_property_pin(base, extra_path, StringName(key) if pin_leaf_properties else &"", pin_properties[key], property_pure_pin)
		structed_trait.properties[key] = property_extra_pin

## 绑定列表
## 不保证构造list_trait
## 需要这个节点(extra_pin)有绑定路径，所以必须要在_bind_path之后执行
## 而有pathed_trait也是有list_trait的必要条件
static func _bind_list(extra_pin: ExtraPin, base: Object, element_pin: Pin, element_pure_pin: PurePin) -> void:
	assert(extra_pin.pathed_trait != null, "Extra Pin: _bind_list requires _bind_path")
	var binding_path := extra_pin.pathed_trait.path
	if base is Node and binding_path.get_subname_count() == 0:
		# 绑定与构造子节点写者
		var current_node := base as Node
		if binding_path.get_name_count() > 0:
			assert(current_node.has_node(binding_path), "Extra Pin: Cannot find node %s at base: %s" % [binding_path, current_node])
			current_node = current_node.get_node(binding_path)
		var listed_trait := Listed.new()
		extra_pin.listed_trait = listed_trait
		var child_extra_pin: ExtraPin
		if element_pin.sub_writer != null:
			# 有子写者，移除子节点
			var example_node = element_pin.sub_writer.alloc.call(element_pure_pin.to_data_node())
			assert(example_node is Node)
			current_node.get_children().map(default_node_drop)
			current_node.add_child(example_node as Node)
			child_extra_pin = _link_pure_pin_node_root(example_node as Node, element_pin, element_pure_pin) # 新开端，子数组子节点
			listed_trait.element_pin = child_extra_pin
			listed_trait.element_alloc = element_pin.sub_writer.alloc
			listed_trait.element_drop = element_pin.sub_writer.drop
			if not listed_trait.element_drop:
				default_node_drop(example_node as Node)
		else:
			# 无子写者，将唯一子节点作为模板创建子写者
			assert(current_node.get_child_count() == 1)
			var child_node := current_node.get_child(0)
			child_extra_pin = _link_pure_pin_node_root(child_node, element_pin, element_pure_pin) # 新开端，子数组子节点
			listed_trait.element_pin = child_extra_pin
			var child_scene := consume_and_pack_child_tree(current_node, child_node) # child_node已删
			listed_trait.element_alloc = generate_node_alloc(child_scene)
			listed_trait.element_drop = default_node_drop
	else:
		var target_array
		if base is Node:
			assert(binding_path.get_subname_count() > 0, "Extra Pin: List should be a property, got: %s at %s" % [binding_path, base])
			var current_node := base as Node
			if binding_path.get_name_count() > 0:
				assert(current_node.has_node(binding_path), "Extra Pin: Cannot find node %s at base: %s" % [binding_path, current_node])
				current_node = current_node.get_node(binding_path) # get_node无视subname
			var property_path := NodePath(binding_path.get_concatenated_subnames())
			target_array = current_node.get_indexed(property_path)
		else:
			assert(binding_path.get_name_count() == 0 and binding_path.get_subname_count() > 0, "Extra Pin: List should be a property, got: %s at %s" % [binding_path, base])
			target_array = base.get_indexed(binding_path)
		assert(Utils.type_is_array(Utils.instance_get_type(target_array)))

		# 一个普通数组的元素如果还是一个DataNodeList，那么它不能以数组的形式包含在元素根节点（也就是不能数组套数组，只能数组套对象套数组）
		# 必须包含的是根节点的子写者
		assert(not element_pin.node_type == Pin.NodeType.LIST or element_pin.sub_writer != null, "Extra Pin: property binded list should have sub_writer")

		if element_pin.sub_writer != null:
			# 子写者只能用于对象
			var example_object: Object = element_pin.sub_writer.alloc.call(element_pure_pin.to_data_node())
			assert(Utils.type_can_be_element(Utils.instance_get_type(example_object), target_array))
			var element_extra_pin := _link_pure_pin_object_root(example_object, element_pin, element_pure_pin) # 新开端，子数组子节点
			var listed_trait := Listed.new()
			extra_pin.listed_trait = listed_trait
			listed_trait.element_pin = element_extra_pin
			listed_trait.element_alloc = element_pin.sub_writer.alloc
			listed_trait.element_drop = element_pin.sub_writer.drop
			if not (element_pin.sub_writer.drop.call(example_object) or example_object is RefCounted):
				example_object.queue_free()
		else:
			assert(Utils.type_can_be_element(element_pin.data_type, target_array),
			"Extra Pin: type of element (%s) doesn't match target array (%s)" %
			[Utils.type_get_string(element_pin.data_type), Utils.type_get_string(Utils.array_get_element_type(target_array))])

# utils ===========================================================================================
static func connect_path(extra: NodePath, current: NodePath) -> NodePath:
	if Utils.node_path_is_empty(current):
		return extra
	var path_str := [current]
	var connect_char: String
	if current.is_absolute(): # 开头为/的，确定第一个字段是节点
		assert(extra.get_subname_count() == 0, "Pin: extra_path should be a node")
		current = NodePath(String(current).substr(1))
		connect_char = "/"
	elif current.get_name_count() == 0: # 全属性或者空
		connect_char = ""
	elif extra.get_subname_count() == 0: # 前段全是节点，后段首个字段开头没有:视为一个节点
		assert(current.get_concatenated_subnames().find("/") == -1, "Pin: the property part of current path (%s) should not contain \"/\" , got: %s" % [current, current.get_concatenated_subnames()])
		connect_char = "/"
	else:
		assert(String(current).find("/") == -1, "Pin: current path (%s) should not contain \"/\"." % current)
		connect_char = ":"
	if extra.get_name_count() > 0 or extra.get_subname_count() > 0:
		path_str.push_front(extra)
	return NodePath(connect_char.join(path_str))

## 将一个节点的子树移除并打包
static func consume_and_pack_child_tree(parent_node: Node, child_node: Node) -> PackedScene:
	assert(child_node.get_parent() == parent_node)
	parent_node.remove_child(child_node)
	var result := Utils.pack_scene(child_node)
	child_node.queue_free()
	return result

## 创建一个简单的子节点生成器
static func generate_node_alloc(scene: PackedScene) -> Callable:
	return func(_source_data_node: DataNode) -> Object:
		return scene.instantiate()

## 通用节点销毁器
static func default_node_drop(data: Object) -> bool:
	assert(data is Node)
	var n := data as Node
	var p := n.get_parent()
	if p != null:
		p.remove_child(n)
	n.queue_free()
	return true
