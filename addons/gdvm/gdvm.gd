class_name Gdvm

const Utils = preload("./utils.gd")
# const BindNode = preload("./bind_node/bind_node.gd")

const DataNode = preload("./core/data_node/base.gd")
const DataNodeVariant = preload("./core/data_node/variant.gd")
const DataNodeStruct = preload("./core/data_node/struct.gd")
const DataNodeList = preload("./core/data_node/list.gd")
const DataNodeNode = preload("./core/data_node/node.gd")

const DataNodeStrict = preload("./core/data_node/strict/base.gd")
const DataNodeBool = preload("./core/data_node/strict/bool.gd")
const DataNodeInt = preload("./core/data_node/strict/int.gd")
const DataNodeFloat = preload("./core/data_node/strict/float.gd")
const DataNodeString = preload("./core/data_node/strict/string.gd")
const DataNodeVector2 = preload("./core/data_node/strict/vector2.gd")
const DataNodeVector2i = preload("./core/data_node/strict/vector2i.gd")
const DataNodeRect2 = preload("./core/data_node/strict/rect2.gd")
const DataNodeRect2i = preload("./core/data_node/strict/rect2i.gd")
const DataNodeVector3 = preload("./core/data_node/strict/vector3.gd")
const DataNodeVector3i = preload("./core/data_node/strict/vector3i.gd")
const DataNodeTransform2D = preload("./core/data_node/strict/transform2d.gd")
const DataNodeVector4 = preload("./core/data_node/strict/vector4.gd")
const DataNodeVector4i = preload("./core/data_node/strict/vector4i.gd")
const DataNodePlane = preload("./core/data_node/strict/plane.gd")
const DataNodeQuaternion = preload("./core/data_node/strict/quaternion.gd")
const DataNodeAABB = preload("./core/data_node/strict/aabb.gd")
const DataNodeBasis = preload("./core/data_node/strict/basis.gd")
const DataNodeTransform3D = preload("./core/data_node/strict/transform3d.gd")
const DataNodeProjection = preload("./core/data_node/strict/projection.gd")
const DataNodeColor = preload("./core/data_node/strict/color.gd")
const DataNodeStringName = preload("./core/data_node/strict/string_name.gd")
const DataNodeNodePath = preload("./core/data_node/strict/node_path.gd")
const DataNodeRID = preload("./core/data_node/strict/rid.gd")

const FactoryOfDataNode = preload("./core/data_node/factory.gd")

const Writer = preload("./core/writer/base.gd")
const WriterProperty = preload("./core/writer/property.gd")
const WriterPropertyArray = preload("./core/writer/property_array.gd")
const WriterNode = preload("./core/writer/node.gd")

const Observer = preload("./core/observer.gd")

# binder
const Pin = preload("./binder/pin/raw.gd")
const Binder = preload("./binder/base.gd")