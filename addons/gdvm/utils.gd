# 类型
# type: 约定为四种形式：
# 0. null: 无类型，视为不限定类型，即Variant。注意null不是0，所以null区别于TYPE_NIL。会视为所有类型，包括Object与非Object的父类
# 1. int: 基础数据类型 如：TYPE_INT
# 2. StringName: Godot原生对象类 如：&"Node"（支持代入String，但所有返回值以及存储值都是StringName）
# 3. Script: 派生类 即实例所绑定的Script对象

# 注意这并不是is_instance_of能接受的格式，而是typed array构造函数能接受的格式

## 获取实例的类型
## 不可能得到Variant，以及TYPE_OBJECT（即使是Object获得的也是"Object"）
static func instance_get_type(instance: Variant) -> Variant:
	var result = typeof(instance)
	if result == TYPE_OBJECT:
		result = (instance as Object).get_script()
		if result == null:
			result = StringName((instance as Object).get_class())
	return result

## 判断实例是否为目标类型及其派生
static func instance_is_type(instance: Variant, type: Variant) -> bool:
	var result := false
	match typeof(type):
		TYPE_INT: # primitive type
			result = is_instance_of(instance, type)
		TYPE_STRING, TYPE_STRING_NAME: # built-in class
			result = (instance is Object) and (instance as Object).is_class(String(type))
		TYPE_OBJECT:
			assert(type is Script, "instance_is_type error: _element_should be a script, got %s. It should not happen!" % [(type as Object).get_class()])
			result = is_instance_of(instance, type)
		TYPE_NIL:
			result = true
		var unexpected_type: # scripted class
			push_error("instance_is_type error: Element type is a %s. It should not happen!" % [type_string(unexpected_type)])
	return result

## 获取类型的默认值
static func type_get_default(type: Variant) -> Variant:
	var result
	match typeof(type):
		TYPE_INT: # primitive type
			match type:
				TYPE_NIL:
					result = null
				TYPE_BOOL:
					result = false
				TYPE_INT:
					result = 0
				TYPE_FLOAT:
					result = 0.0
				TYPE_STRING:
					result = ""
				TYPE_VECTOR2:
					result = Vector2()
				TYPE_VECTOR2I:
					result = Vector2i()
				TYPE_RECT2:
					result = Rect2()
				TYPE_RECT2I:
					result = Rect2i()
				TYPE_VECTOR3:
					result = Vector3()
				TYPE_VECTOR3I:
					result = Vector3i()
				TYPE_TRANSFORM2D:
					result = Transform2D()
				TYPE_VECTOR4:
					result = Vector4()
				TYPE_VECTOR4I:
					result = Vector4i()
				TYPE_PLANE:
					result = Plane()
				TYPE_QUATERNION:
					result = Quaternion()
				TYPE_AABB:
					result = AABB()
				TYPE_BASIS:
					result = Basis()
				TYPE_TRANSFORM3D:
					result = Transform3D()
				TYPE_PROJECTION:
					result = Projection()
				TYPE_COLOR:
					result = Color()
				TYPE_STRING_NAME:
					result = &""
				TYPE_NODE_PATH:
					result = ^""
				TYPE_RID:
					result = RID()
				TYPE_OBJECT:
					result = null
				TYPE_CALLABLE:
					result = Callable()
				TYPE_SIGNAL:
					result = Signal()
				TYPE_DICTIONARY:
					result = {}
				TYPE_ARRAY:
					result = []
				TYPE_PACKED_BYTE_ARRAY:
					result = PackedByteArray()
				TYPE_PACKED_INT32_ARRAY:
					result = PackedInt32Array()
				TYPE_PACKED_INT64_ARRAY:
					result = PackedInt64Array()
				TYPE_PACKED_FLOAT32_ARRAY:
					result = PackedFloat32Array()
				TYPE_PACKED_FLOAT64_ARRAY:
					result = PackedFloat64Array()
				TYPE_PACKED_STRING_ARRAY:
					result = PackedStringArray()
				TYPE_PACKED_VECTOR2_ARRAY:
					result = PackedVector2Array()
				TYPE_PACKED_VECTOR3_ARRAY:
					result = PackedVector3Array()
				TYPE_PACKED_COLOR_ARRAY:
					result = PackedColorArray()
				TYPE_PACKED_VECTOR4_ARRAY:
					result = PackedVector4Array()
				var unexpected_type:
					push_error("type_get_default error: %d doesn't exist!" % unexpected_type)
		TYPE_STRING, TYPE_STRING_NAME, TYPE_OBJECT, TYPE_NIL: # built-in class
			result = null
		var unexpected_type: # scripted class
			push_error("type_get_default error: Element type is a %s. It should not happen!" % [type_string(unexpected_type)])
	return result

## 判断类型是否符合约定的形式
## strict为严格判定，将只允许StringName
static func type_is_legal(type: Variant, strict: bool = false) -> bool:
	var result := false
	match typeof(type):
		TYPE_INT:
			# Object必会转为StringName或者String
			result = (type >= 0 and type < TYPE_OBJECT) or (type > TYPE_OBJECT and type < TYPE_MAX)
		TYPE_STRING_NAME, TYPE_NIL:
			result = true
		TYPE_STRING:
			result = !strict
		TYPE_OBJECT:
			result = type is Script
	return result

## 将非严格合法的类型转成严格合法的类型
static func make_type_strict(type: Variant) -> Variant:
	assert(type_is_legal(type), "type_make_strict error: parameter \"type\" (%s) should be a legal type." % type)
	if type is String:
		return StringName(type)
	return type

## 获取类型用于打印的字符串
static func type_get_string(type: Variant) -> String:
	var result := ""
	match typeof(type):
		TYPE_INT:
			result = type_string(type)
		TYPE_STRING, TYPE_STRING_NAME:
			result = String(type)
		TYPE_OBJECT:
			assert(type is Script, "type_get_string error: _element_should be a script, got %s. It should not happen!" % [(type as Object).get_class()])
			result = String((type as Script).get_global_name())
			if result.is_empty():
				result = (type as Script).resource_path
		TYPE_NIL:
			result = "Variant"
		var unexpected_type:
			push_error("type_get_string error: Element type is a %s. It should not happen!" % [type_string(unexpected_type)])
	return result

## 判断第一个类型是否为第二个类型或继承了第二个类型
static func type_is_type(sub_type: Variant, super_type: Variant) -> bool:
	var result := false
	match typeof(super_type):
		TYPE_INT: # primitive type
			result = (sub_type is int and sub_type == super_type)
		TYPE_STRING, TYPE_STRING_NAME: # built-in class
			if sub_type is String or sub_type is StringName:
				result = ClassDB.is_parent_class(sub_type, super_type)
			elif sub_type is Script:
				sub_type = (sub_type as Script).get_global_name()
				result = ClassDB.is_parent_class(sub_type, super_type)
		TYPE_OBJECT:
			assert(super_type is Script, "instance_is_type error: _element_should be a script, got %s. It should not happen!" % [(super_type as Object).get_class()])
			var parent_script := sub_type as Script
			while parent_script != null:
				if sub_type == super_type:
					result = true
					break
				parent_script = parent_script.get_base_script()
		TYPE_NIL:
			result = true
		var unexpected_type: # scripted class
			push_error("instance_is_type error: Element type is a %s. It should not happen!" % [type_string(unexpected_type)])
	return result

## 判断这个类型是否有严格类型数据节点
## 一些基础数据类型是可以创建严格类型数据节点的，这种节点不是Variant，其他类型只能存在Variant里
static func type_has_strict_data_node(type: Variant) -> bool:
	return type is int and type > TYPE_NIL and type < TYPE_OBJECT

## 判断实例的类型是否有严格类型的数据节点
static func instance_has_strict_data_node(instance: Variant) -> bool:
	var type := typeof(instance)
	return type > TYPE_NIL and type < TYPE_OBJECT

## 判断是否为数组型数据
static func type_is_array(type: Variant) -> bool:
	return type is int and type >= TYPE_ARRAY and type < TYPE_MAX

## 判断实例是否为数组型数据
static func instance_is_array(instance: Variant) -> bool:
	var type := typeof(instance)
	return type >= TYPE_ARRAY and type < TYPE_MAX

## 判断能否转换为NodePath
static func type_can_be_nodepath(type: Variant) -> bool:
	return type is int and type & (TYPE_STRING | TYPE_STRING_NAME | TYPE_NODE_PATH)

## 获取数组的元素类型 无类型将返回null（并不是TYPE_NIL）
static func array_get_element_type(array: Variant) -> Variant:
	assert(type_is_array(instance_get_type(array)), "array_get_element_type error: parameter \"array\" should be an array.")
	var element_type
	match typeof(array):
		TYPE_ARRAY:
			var arr: Array = array
			if arr.is_typed():
				element_type = arr.get_typed_builtin()
				if element_type == TYPE_OBJECT:
					element_type = arr.get_typed_script()
					if element_type == null:
						element_type = arr.get_typed_class_name()
			else:
				element_type = null
		TYPE_PACKED_BYTE_ARRAY, TYPE_PACKED_INT32_ARRAY, TYPE_PACKED_INT64_ARRAY:
			element_type = TYPE_INT
		TYPE_PACKED_FLOAT32_ARRAY, TYPE_PACKED_FLOAT64_ARRAY:
			element_type = TYPE_FLOAT
		TYPE_PACKED_STRING_ARRAY:
			element_type = TYPE_STRING
		TYPE_PACKED_VECTOR2_ARRAY:
			element_type = TYPE_VECTOR2
		TYPE_PACKED_VECTOR3_ARRAY:
			element_type = TYPE_VECTOR3
		TYPE_PACKED_COLOR_ARRAY:
			element_type = TYPE_COLOR
		TYPE_PACKED_VECTOR4_ARRAY:
			element_type = TYPE_VECTOR4
	return element_type

## 判断某类型是否可以作为一个数组的元素
static func type_can_be_element(type: Variant, array: Variant) -> bool:
	var element_type = array_get_element_type(array)
	if element_type == null: # Variant
		return true
	if type == TYPE_NIL: # null
		return element_type == TYPE_NIL or \
		element_type == TYPE_OBJECT or \
		element_type is StringName or \
		element_type is Script
	return type_is_type(type, element_type)

## 判断某类型是否可以作为一个类型的数组的元素
## 这个判定是不严格的，因为无法代入typed_array的类型
static func type_can_be_element_of_array_of_type(type: Variant, array_type: Variant) -> bool:
	assert(type_is_array(array_type), "type_can_be_element_of_array_of_type error: parameter \"array_type\" should be an array type.")
	var result := false
	match array_type:
		TYPE_ARRAY:
			result = true
		TYPE_PACKED_BYTE_ARRAY, TYPE_PACKED_INT32_ARRAY, TYPE_PACKED_INT64_ARRAY:
			result = type == TYPE_INT
		TYPE_PACKED_FLOAT32_ARRAY, TYPE_PACKED_FLOAT64_ARRAY:
			result = type == TYPE_FLOAT
		TYPE_PACKED_STRING_ARRAY:
			result = type == TYPE_STRING
		TYPE_PACKED_VECTOR2_ARRAY:
			result = type == TYPE_VECTOR2
		TYPE_PACKED_VECTOR3_ARRAY:
			result = type == TYPE_VECTOR3
		TYPE_PACKED_COLOR_ARRAY:
			result = type == TYPE_COLOR
		TYPE_PACKED_VECTOR4_ARRAY:
			result = type == TYPE_VECTOR4
	return result

## 判断类型是否为对象
## 注意null不是
static func type_is_object(type: Variant) -> bool:
	return type == TYPE_OBJECT or type is String or type is StringName or type is Script

## 提取类型对应的内置类
## 如果是variant的话会返回TYPE_NIL
static func type_to_builtin(type: Variant) -> int:
	var result: int
	match typeof(type):
		TYPE_NIL:
			result = TYPE_NIL
		TYPE_INT:
			result = type
		_:
			result = TYPE_OBJECT
	return result

## 提取类型对应的Godot原生类名
static func type_to_class_name(type: Variant) -> StringName:
	match typeof(type):
		TYPE_STRING_NAME:
			return type as StringName
		TYPE_STRING:
			return StringName(type)
		TYPE_OBJECT:
			return (type as Script).get_instance_base_type()
	return &""

## 提取类型对应的脚本
static func type_to_script(type: Variant) -> Script:
	if typeof(type) == TYPE_OBJECT:
		return type
	else:
		return null

## 打包提取类型对应的三个值
static func type_from_gdvm_to_godot_style(type: Variant) -> Array:
	return [
		type_to_builtin(type),
		type_to_class_name(type),
		type_to_script(type)
	]

## 将godot三值转成gdvm格式的
## 其中TYPE_NIL代表无类型（Variant）
static func type_from_godot_to_gdvm_style(builtin: int, cls_name: StringName, script: Script) -> Variant:
	# cls_name即class_name，因为是保留字所以简写
	var result = null
	if builtin == TYPE_NIL:
		result = null
	elif builtin == TYPE_OBJECT:
		if script == null:
			result = cls_name
		else:
			result = script
	else:
		result = builtin
	return result

## 判断NodePath是否为空
## 这是特殊规则，会把"/"视为空
static func node_path_is_empty(node_path: NodePath) -> bool:
	return node_path.get_name_count() == 0 and node_path.get_subname_count() == 0

## 判断一个字典的形式是否为结构体配置，否则只是一个字典
static func dictionary_is_struct(dictionary: Dictionary) -> bool:
	var result := false
	var size := dictionary.size()
	if size > 1:
		result = true
	elif size == 1:
		var key_of_data = dictionary.keys()[0]
		var type_of_key_of_data = instance_get_type(key_of_data)
		if (type_of_key_of_data == TYPE_STRING or \
		type_of_key_of_data == TYPE_STRING_NAME) and \
		not (key_of_data as String).is_empty():
			result = true
	return result

# tools ============================================================
static func pack_scene(node: Node) -> PackedScene:
	if not node.scene_file_path.is_empty():
		return load(node.scene_file_path) as PackedScene
	if node.get_parent() != null:
		push_warning("Pack scene warning: the node tree to be packed (%s) has a parent." % node)
	var iter_queue: Array[Node]
	node.owner = null
	iter_queue.append(node)
	while iter_queue.size() > 0:
		var current_node := iter_queue.pop_front() as Node
		if current_node.scene_file_path.is_empty():
			for child in current_node.get_children():
				child.owner = node
				iter_queue.append(child)
	var result := PackedScene.new()
	result.pack(node)
	return result

## 连接数据节点路径
## 分隔符统一为“/”，强制转为相对路径
static func connect_data_node_path(current: NodePath, extra: NodePath, spliter: StringName = &"/") -> NodePath:
	var result_array := []
	var current_name_lenth := current.get_name_count()
	var current_subname_lenth := current.get_subname_count()
	var extra_name_lenth := extra.get_name_count()
	var extra_subname_lenth := extra.get_subname_count()
	result_array.resize(current_name_lenth + current_subname_lenth + extra_name_lenth + extra_subname_lenth)
	var offset := 0
	for i in current_name_lenth:
		result_array[i] = current.get_name(i)
	offset += current_name_lenth
	for i in current_subname_lenth:
		result_array[offset + i] = current.get_subname(i)
	offset += current_subname_lenth
	for i in extra_name_lenth:
		result_array[offset + i] = extra.get_name(i)
	offset += extra_name_lenth
	for i in extra_subname_lenth:
		result_array[offset + i] = extra.get_subname(i)
	return NodePath(spliter.join(result_array))

## 连接关联路径（观察者路径或写者路径）
static func connect_link_path(current: NodePath, extra: NodePath) -> NodePath:
	if node_path_is_empty(current):
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

## 将路径转为纯属性路径
static func convert_node_path_into_full_property_path(node_path: NodePath) -> NodePath:
	return connect_data_node_path(^"", node_path, &":").get_as_property_path()
# Debug ============================================================
# 打包断言，只能在assert里用

## 断言实例是否是这个类型
## 效果同instance_is_type，但会抛出具体的断言错误
static func assert_instance_is_type(instance: Variant, type: Variant) -> bool:
	match typeof(type):
		TYPE_INT: # primitive type
			assert(is_instance_of(instance, type), "Type assertion error: Element type mismatch. expect %s, got %s" % [type_string(type), type_string(typeof(instance))])
		TYPE_STRING, TYPE_STRING_NAME: # built-in class
			if instance == null: # null 是TYPE_NIL，但可以是一个以对象为元素的数组的元素
				return true
			assert(instance is Object, "Type assertion error: Element type mismatch. expect %s, got %s" % [type, type_string(typeof(instance))])
			assert((instance as Object).is_class(type), "Type assertion error: Element type mismatch. expect %s, got %s" % [type, (instance as Object).get_class()])
		TYPE_OBJECT:
			assert(type is Script, "Type assertion error: _element_should be a script, got %s. It should not happen!" % [(type as Object).get_class()])
			if instance == null:
				return true
			assert(instance is Object, "Type assertion error: Element type mismatch. expect %s, got %s" % [type, type_string(typeof(instance))])
			
			var expected_class_name := String((type as Script).get_global_name())
			if expected_class_name.is_empty():
				expected_class_name = (type as Script).resource_path
			var actual_script = (instance as Object).get_script()
			var actual_class_name: String
			if actual_script == null:
				actual_class_name = (instance as Object).get_class()
			else:
				actual_class_name = String((actual_script as Script).get_global_name())
				if actual_class_name.is_empty():
					actual_class_name = (actual_script as Script).resource_path
			assert(is_instance_of(instance, type), "Type assertion error: Element type mismatch. expect %s, got %s" % [expected_class_name, actual_class_name])
		TYPE_NIL:
			return true
		var unexpected_type: # scripted class
			push_error("Type assertion error: Element type is a %s. It should not happen." % [type_string(unexpected_type)])
	return true

## 路径名不能包含“..”、"."这些重定向字段
static func assert_node_path_has_no_redirections(node_path: NodePath) -> bool:
	var name_count := node_path.get_name_count()
	var subname_count := node_path.get_subname_count()
	for i in name_count:
		var name := node_path.get_name(i)
		assert(name != ".", "NodePath shouldn't have redirections: %s" % node_path)
		assert(name != "..", "NodePath shouldn't have redirections: %s" % node_path)
	for i in subname_count:
		var subname := node_path.get_subname(i)
		assert(subname != ".", "NodePath shouldn't have redirections: %s" % node_path)
		assert(subname != "..", "NodePath shouldn't have redirections: %s" % node_path)
	return true
