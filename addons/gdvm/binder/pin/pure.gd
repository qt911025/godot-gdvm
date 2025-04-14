const PurePin = preload("./pure.gd")
const Pin = preload("./raw.gd")
const Utils = preload("../../utils.gd")

const DataNode = preload("../../core/data_node/base.gd")
const DataNodeVariant = preload("../../core/data_node/variant.gd")
const DataNodeStruct = preload("../../core/data_node/struct.gd")
const DataNodeList = preload("../../core/data_node/list.gd")
const DataNodeNode = preload("../../core/data_node/node.gd")
const FactoryOfDataNode = preload("../../core/data_node/factory.gd")

## PurePin
## 纯净Pin
## 只包含数据，不包含绑定

## 从原始Pin配置构建纯净Pin
func from_pin(pin: Pin) -> void:
	push_error("abstract method")

## 递归地创建对应的DataNode实例
func to_data_node() -> DataNode:
	push_error("abstract method")
	return DataNode.new()

## 由绑定的根目标和Pin构建纯净Pin
static func build(pin: Pin) -> PurePin:
	var result: PurePin
	match pin.node_type:
		Pin.NodeType.VARIANT:
			result = PurePinVariant.new()
		Pin.NodeType.STRICT:
			result = PurePinStrict.new()
		Pin.NodeType.STRUCT:
			result = PurePinStruct.new()
		Pin.NodeType.LIST:
			result = PurePinList.new()
		Pin.NodeType.NODE:
			result = PurePinNode.new()
		var unexpected_node_type:
			push_error("build_pure_pin failed: unexpected node type %s" % pin.node_type)
	result.from_pin(pin)
	return result

class PurePinVariant extends PurePin:
	var data
	func from_pin(pin: Pin) -> void:
		data = pin.data
	func to_data_node() -> DataNode:
		return DataNodeVariant.new(data)

class PurePinStrict extends PurePin:
	var data
	func from_pin(pin: Pin) -> void:
		assert(Utils.type_has_strict_data_node(pin.data_type))
		if Utils.instance_is_type(pin.data, pin.data_type):
			data = pin.data
		else:
			data = Utils.type_get_default(pin.data_type)
	func to_data_node() -> DataNode:
		return FactoryOfDataNode.create_strict_data_node(data)

class PurePinStruct extends PurePin:
	var properties: Dictionary[StringName, PurePin]
	func from_pin(pin: Pin) -> void:
		properties.clear()
		for key in pin.properties:
			properties[StringName(key)] = build(pin.properties[key])
	func to_data_node() -> DataNode:
		var result = DataNodeStruct.new()
		for key: StringName in properties:
			result.add_property(key, properties[key].to_data_node())
		return result

class PurePinList extends PurePin:
	var element_type
	var element_pure_pin: PurePin
	func from_pin(pin: Pin) -> void:
		var element_pin := pin.children[0] as Pin
		element_type = element_pin.data_type
		element_pure_pin = build(element_pin)
	func to_data_node() -> DataNode:
		return DataNodeList.new(element_type, func() -> DataNode:
			return element_pure_pin.to_data_node()
		)

class PurePinNode extends PurePin:
	var child_type
	var child_pure_pin: PurePin
	var properties: Dictionary[StringName, PurePin]
	func from_pin(pin: Pin) -> void:
		properties.clear()
		var element_pin := pin.children[0] as Pin
		child_type = element_pin.data_type
		child_pure_pin = build(element_pin)
		for key in pin.properties:
			properties[StringName(key)] = build(pin.properties[key])
	func to_data_node() -> DataNode:
		var result = DataNodeNode.new(child_type, func() -> DataNode:
			return child_pure_pin.to_data_node()
		)
		for key: StringName in properties:
			result.add_property(key, properties[key].to_data_node())
		return result
	func to_data_node_without_properties() -> DataNodeNode:
		return DataNodeNode.new(child_type, func() -> DataNode:
			return child_pure_pin.to_data_node()
		)
