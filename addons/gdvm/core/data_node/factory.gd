## Factory of DataNode
const DataNode = preload("./base.gd")
const DataNodeNode = preload("./node.gd")
const DataNodeList = preload("./list.gd")
const DataNodeStruct = preload("./struct.gd")
const DataNodeVariant = preload("./variant.gd")
const DataNodeStrict = preload("./strict/base.gd")

const DataNodeBool = preload("./strict/bool.gd")
const DataNodeInt = preload("./strict/int.gd")
const DataNodeFloat = preload("./strict/float.gd")
const DataNodeString = preload("./strict/string.gd")
const DataNodeVector2 = preload("./strict/vector2.gd")
const DataNodeVector2i = preload("./strict/vector2i.gd")
const DataNodeRect2 = preload("./strict/rect2.gd")
const DataNodeRect2i = preload("./strict/rect2i.gd")
const DataNodeVector3 = preload("./strict/vector3.gd")
const DataNodeVector3i = preload("./strict/vector3i.gd")
const DataNodeTransform2D = preload("./strict/transform2d.gd")
const DataNodeVector4 = preload("./strict/vector4.gd")
const DataNodeVector4i = preload("./strict/vector4i.gd")
const DataNodePlane = preload("./strict/plane.gd")
const DataNodeQuaternion = preload("./strict/quaternion.gd")
const DataNodeAABB = preload("./strict/aabb.gd")
const DataNodeBasis = preload("./strict/basis.gd")
const DataNodeTransform3D = preload("./strict/transform3d.gd")
const DataNodeProjection = preload("./strict/projection.gd")
const DataNodeColor = preload("./strict/color.gd")
const DataNodeStringName = preload("./strict/string_name.gd")
const DataNodeNodePath = preload("./strict/node_path.gd")
const DataNodeRID = preload("./strict/rid.gd")

const Utils = preload("../../utils.gd")

static func create_strict_data_node(data: Variant) -> DataNodeStrict:
	var result: DataNodeStrict
	match typeof(data):
		TYPE_BOOL:
			result = DataNodeBool.new(data)
		TYPE_INT:
			result = DataNodeInt.new(data)
		TYPE_FLOAT:
			result = DataNodeFloat.new(data)
		TYPE_STRING:
			result = DataNodeString.new(data)
		TYPE_VECTOR2:
			result = DataNodeVector2.new(data)
		TYPE_VECTOR2I:
			result = DataNodeVector2i.new(data)
		TYPE_RECT2:
			result = DataNodeRect2.new(data)
		TYPE_RECT2I:
			result = DataNodeRect2i.new(data)
		TYPE_VECTOR3:
			result = DataNodeVector3.new(data)
		TYPE_VECTOR3I:
			result = DataNodeVector3i.new(data)
		TYPE_TRANSFORM2D:
			result = DataNodeTransform2D.new(data)
		TYPE_VECTOR4:
			result = DataNodeVector4.new(data)
		TYPE_VECTOR4I:
			result = DataNodeVector4i.new(data)
		TYPE_PLANE:
			result = DataNodePlane.new(data)
		TYPE_QUATERNION:
			result = DataNodeQuaternion.new(data)
		TYPE_AABB:
			result = DataNodeAABB.new(data)
		TYPE_BASIS:
			result = DataNodeBasis.new(data)
		TYPE_TRANSFORM3D:
			result = DataNodeTransform3D.new(data)
		TYPE_PROJECTION:
			result = DataNodeProjection.new(data)
		TYPE_COLOR:
			result = DataNodeColor.new(data)
		TYPE_STRING_NAME:
			result = DataNodeStringName.new(data)
		TYPE_NODE_PATH:
			result = DataNodeNodePath.new(data)
		TYPE_RID:
			result = DataNodeRID.new(data)
		_:
			push_error("Create strict data node failed: Expected strict type, got %s." % Utils.type_get_string(Utils.instance_get_type(data)))
	return result

static func create_strict_data_node_by_type(type: Variant) -> DataNodeStrict:
	assert(Utils.type_has_strict_data_node(type))
	var result: DataNodeStrict
	match type:
		TYPE_BOOL:
			result = DataNodeBool.new(false)
		TYPE_INT:
			result = DataNodeInt.new(0)
		TYPE_FLOAT:
			result = DataNodeFloat.new(0.0)
		TYPE_STRING:
			result = DataNodeString.new("")
		TYPE_VECTOR2:
			result = DataNodeVector2.new(Vector2())
		TYPE_VECTOR2I:
			result = DataNodeVector2i.new(Vector2i())
		TYPE_RECT2:
			result = DataNodeRect2.new(Rect2())
		TYPE_RECT2I:
			result = DataNodeRect2i.new(Rect2i())
		TYPE_VECTOR3:
			result = DataNodeVector3.new(Vector3())
		TYPE_VECTOR3I:
			result = DataNodeVector3i.new(Vector3i())
		TYPE_TRANSFORM2D:
			result = DataNodeTransform2D.new(Transform2D())
		TYPE_VECTOR4:
			result = DataNodeVector4.new(Vector4())
		TYPE_VECTOR4I:
			result = DataNodeVector4i.new(Vector4i())
		TYPE_PLANE:
			result = DataNodePlane.new(Plane())
		TYPE_QUATERNION:
			result = DataNodeQuaternion.new(Quaternion())
		TYPE_AABB:
			result = DataNodeAABB.new(AABB())
		TYPE_BASIS:
			result = DataNodeBasis.new(Basis())
		TYPE_TRANSFORM3D:
			result = DataNodeTransform3D.new(Transform3D())
		TYPE_PROJECTION:
			result = DataNodeProjection.new(Projection())
		TYPE_COLOR:
			result = DataNodeColor.new(Color())
		TYPE_STRING_NAME:
			result = DataNodeStringName.new(&"")
		TYPE_NODE_PATH:
			result = DataNodeNodePath.new(^"")
		TYPE_RID:
			result = DataNodeRID.new(RID())
		_:
			push_error("Create strict data node failed: Expected strict type, got %s." % Utils.type_get_string(type))
	return result