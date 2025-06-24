## WriterPropertyDictionary
## 专门用于修改Dictionary
extends Writer
const Writer = preload("./base.gd")
const DataNodeDict = preload("../data_node/dict.gd")

var _dictionary_property: NodePath

var _sub_writer: ElementSubWriter

class ElementInfo:
	var source_element_id: int
	var target_element_id: int
	var binded_writers: Array[Writer]

	func _init(source_element_id: int, target_element_id: int, binded_writers: Array) -> void:
		self.source_element_id = source_element_id
		self.target_element_id = target_element_id
		self.binded_writers = Array(binded_writers, TYPE_OBJECT, "RefCounted", Writer)

class ElementSubWriter:
	## 申请元素回调，里面一般包括目标元素的构建，以及传入的DataNode的绑定
	var alloc_element: Callable
	var bind_writers: Callable
	var drop_element: Callable

	var element_map: Dictionary[Variant, ElementInfo] # 键是data_node以及目标共有的key

	func _init(
		alloc_element_cb: Callable = func(source_data_node: DataNode) -> Object: return null,
		bind_writers_cb: Callable = func(source_data_node: DataNode, target_element: Object) -> Array: return [],
		drop_element_cb: Callable = func(target_element: Object) -> void: return ,
	) -> void:
		alloc_element = alloc_element_cb
		bind_writers = bind_writers_cb
		drop_element = drop_element_cb

## 字典写者
## target: Object 要控制的目标对象
## dictionary_property: NodePath 要控制的目标字典，目标字典必须是某个对象的成员
## data_node: DataNode 上游DataNode
## element_sub_writer: ElementSubWriter 元素子写者，包含控制目标字典的值创建与释放的回调，只能用在元素是Object时
func _init(target: Object, dictionary_property: NodePath, data_node: DataNodeDict, element_sub_writer: ElementSubWriter = null) -> void:
	assert(is_instance_valid(target))
	assert(target.get_indexed(dictionary_property) is Dictionary)
	var target_dictionary: Dictionary = target.get_indexed(dictionary_property)
	assert(is_instance_valid(data_node))
	assert(not target_dictionary.is_typed_key() or data_node.is_same_typed_key_with_dictionary(target_dictionary))

	_target_ref = weakref(target)
	_dictionary_property = dictionary_property
	_sub_writer = element_sub_writer

	if _sub_writer == null:
		# 没有sub writer，用于元素是基础数据类型，或者元素不绑定任何Writer的时候，改变元素总是创建新元素
		assert(not target_dictionary.is_typed_value() or data_node.is_same_typed_value_with_dictionary(target_dictionary))
		data_node.changed.connect(_on_changed)
		_on_changed(data_node)
	else:
		# 有sub writer，用于元素是Object且绑定了Writer的时候，字典写者只关心元素对象有无的改变，而不关心元素属性的改变
		data_node.order_changed.connect(_on_changed_with_sub_writer)
		_on_changed_with_sub_writer(data_node)

func _on_changed(data_node: DataNode) -> void:
	var target: Object = _target_ref.get_ref()
	if is_instance_valid(target):
		var target_dictionary: Dictionary = target.get_indexed(_dictionary_property)
		var value_dictionary := data_node.value() as Dictionary
		for key in target_dictionary:
			if not value_dictionary.has(key):
				target_dictionary.erase(key)
		for key in value_dictionary:
			target_dictionary[key] = value_dictionary[key]
	else:
		data_node.changed.disconnect(_on_changed)
		
func _on_changed_with_sub_writer(data_node: DataNode) -> void:
	var target: Object = _target_ref.get_ref()
	if is_instance_valid(target):
		var data_node_dict := data_node as DataNodeDict
		var element_node_dictionary := data_node_dict.get_element_nodes()
		var target_dictionary: Dictionary = target.get_indexed(_dictionary_property)
		
		var element_map := _sub_writer.element_map

		for key in element_map:
			if not element_node_dictionary.has(key):
				element_map.erase(key)
		for key in target_dictionary:
			if not element_node_dictionary.has(key):
				_sub_writer.drop_element.call(target_dictionary[key])
				target_dictionary.erase(key)

		for key in element_node_dictionary:
			var source_element := element_node_dictionary[key] as DataNode
			var source_element_id: int = source_element.get_instance_id()
			var target_element: Object = target_dictionary.get_or_add(key, _sub_writer.alloc_element.call(source_element))
			var target_element_id: int = target_element.get_instance_id()

			var element_info := element_map.get(key)
			if element_info == null or \
			element_info.source_element_id != source_element_id or \
			element_info.target_element_id != target_element_id:
				element_map[key] = ElementInfo.new(
					source_element_id,
					target_element_id,
					_sub_writer.bind_writers.call(source_element, target_element)
				)
	else:
		data_node.order_changed.disconnect(_on_changed_with_sub_writer)
