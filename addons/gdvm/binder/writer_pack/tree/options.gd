const WriterTreeOptions = preload("./options.gd")
const DataNode = preload("../../../core/data_node/base.gd")

const Utils = preload("../../../utils.gd")

## WriterTreeOptions

## 写者树节点的配置类型
## PROPERTY要么是主干节点，要么是叶子节点，只有叶子节点会绑Property写者
var type: Type
enum Type {
	PROPERTY, # 默认，包括Struct、Variant、Strict、简单数组、简单字典、以及Node的属性
	PROPERTY_ARRAY, # 含子写者的数组
	PROPERTY_DICTIONARY, # 含子写者的字典
	NODE, # Node
}

## 目标相对于目标基对象的路径
var path: NodePath

## 属性，用于Node、Struct
var properties: Dictionary[StringName, WriterTreeOptions]

## 子节点配置
var children: WriterTreeOptions

var sub_writer: SubWriter
class SubWriter:
	## 供写者使用的子写者元素构造器
	var alloc: Callable = func(source_data_node: DataNode) -> Object: return null
	## 供写者使用的子写者元素销毁器 返回值为销毁器是否自带销毁目标对象的处理
	var drop: Callable = func(data: Object) -> bool: return false

func _init(opts: Dictionary) -> void:
	opts = opts.duplicate()

	# 有限补全
	if not opts.has("type"):
		if opts.has("properties") and opts.has("children"):
			opts.type = Type.NODE # 注意，如果显式指定为NODE，没有properties也是合法的
		elif opts.has("children"):
			push_error("WriterTreeOptions: only has children, unable to determine whether the type is node, list or dict")
		else:
			opts.type = Type.PROPERTY

	assert(opts.has("type"), "WriterTreeOptions must assign type explicitly.")
	assert(__assert_validate(opts)) # 检查显式指定类型的格式
	type = opts.type

	if opts.has("path"):
		assert(Utils.type_can_be_nodepath(Utils.instance_get_type(opts.path)))
		path = NodePath(String(opts.path))
		assert(Utils.assert_node_path_has_no_redirections(path))
		if path.is_absolute():
			path = NodePath(String(path).substr(1))

	if opts.has("properties"):
		assert(opts.properties is Dictionary)
		for key in opts.properties:
			assert((Utils.instance_is_type(key, TYPE_STRING) or Utils.instance_is_type(key, TYPE_STRING_NAME)) and \
			not key.is_empty())
			properties[StringName(key)] = WriterTreeOptions.build(opts.properties[key])

	if opts.has("children"):
		children = WriterTreeOptions.build(opts.children)

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
	
static func build(data_opts: Variant) -> WriterTreeOptions:
	var result: WriterTreeOptions
	match Utils.instance_get_type(data_opts):
		WriterTreeOptions:
			result = data_opts
		TYPE_DICTIONARY:
			if Utils.dictionary_is_struct(data_opts):
				result = WriterTreeOptions.new({
					type = Type.PROPERTY,
					properties = data_opts,
				})
			else:
				var opts := {}
				if (data_opts as Dictionary).size() < 1:
					opts.type = Type.PROPERTY
				else:
					var children_opts = (data_opts as Dictionary).values()[0]
					if typeof(children_opts) <= TYPE_OBJECT and Utils.instance_get_type(children_opts) != WriterTreeOptions:
						# 简单字典，值是基础数据类型，以及对象（的引用）
						opts.type = Type.PROPERTY
					else:
						opts.type = Type.PROPERTY_DICTIONARY
						opts.children = children_opts
				result = WriterTreeOptions.new(opts)
		var array_type when Utils.type_is_array(array_type):
			var opts := {
				type = Type.PROPERTY,
			}
			if typeof(data_opts) == TYPE_ARRAY and (data_opts as Array).size() == 1:
				var children_opts = (data_opts as Array)[0]
				if typeof(children_opts) > TYPE_OBJECT or Utils.instance_get_type(children_opts) == WriterTreeOptions:
					# 元素类型为以上情形，数组是复杂数组
					opts.type = Type.PROPERTY_ARRAY
					opts.children = children_opts
			result = WriterTreeOptions.new(opts)
		_:
			# todo 基础数据类型以及对象（的引用），直接作为叶子节点，这么写是否健壮？这是必须绑定路径的，是否自动绑定或正确报错？
			result = WriterTreeOptions.new({
				type = Type.PROPERTY,
			})
	return result

static func __assert_validate(opts: Dictionary) -> bool:
	match opts.type:
		Type.PROPERTY:
			assert(not opts.has("children"))
		Type.PROPERTY_ARRAY, Type.PROPERTY_DICTIONARY:
			assert(not opts.has("properties"))
			assert(opts.has("children"))
		Type.NODE:
			assert(opts.has("children"))
		_:
			push_error("WriterTreeOptions: illegal type %s" % opts.type)
	return true