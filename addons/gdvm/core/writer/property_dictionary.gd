## WriterPropertyDictionary
## 专门用于修改Dictionary
extends Writer
const Writer = preload("./base.gd")
const DataNodeDict = preload("../data_node/dict.gd")

var _dictionary_property: NodePath

var _sub_writer: ElementSubWriter

class ElementInfo:
	var target_element: Object
	var binded_writers: Array[Writer]

	func _init(target_element: Object, binded_writers: Array) -> void:
		self.target_element = target_element
		self.binded_writers = Array(binded_writers, TYPE_OBJECT, "RefCounted", Writer)

class ElementSubWriter:
	## 申请元素回调，里面一般包括目标元素的构建，以及传入的DataNode的绑定
	var alloc_element: Callable
	var drop_element: Callable # must include unbind, if your writers has strong references

	var element_map: Dictionary[int, ElementInfo] # 键是DataNode的object id，作为弱引用，值是ElementInfo，是对target_element的强引用

	func _init(
		alloc_element_cb: Callable = func(element_data_node: DataNode) -> ElementInfo: return null,
		drop_element_cb: Callable = func(target_element_info: ElementInfo) -> void: return ,
	) -> void:
		alloc_element = alloc_element_cb
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
	assert(not target_dictionary.is_typed_value() or data_node.is_same_typed_value_with_dictionary(target_dictionary))

	_target_ref = weakref(target)
	_dictionary_property = dictionary_property
	# _data_node_ref = weakref(data_node)
	_sub_writer = element_sub_writer

	if _sub_writer == null:
		# 没有sub writer，用于元素是基础数据类型，或者元素不绑定任何Writer的时候，改变元素总是创建新元素
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
		
		var old_element_map := _sub_writer.element_map
		var new_element_map := {}

		for key in target_dictionary:
			if not element_node_dictionary.has(key):
				target_dictionary.erase(key)
		for key in element_node_dictionary:
			var element_data_node := element_node_dictionary[key] as DataNode
			var element_data_node_id: int = element_data_node.get_instance_id()
			var target_element_info: ElementInfo
			if old_element_map.has(element_data_node_id):
				target_element_info = old_element_map.get(element_data_node_id)
				old_element_map.erase(element_data_node_id)
			else:
				target_element_info = _sub_writer.alloc_element.call(element_data_node)
			target_dictionary[key] = target_element_info.target_element
			new_element_map[element_data_node_id] = target_element_info

		for key_of_waste in old_element_map:
			_sub_writer.drop_element.call(old_element_map[key_of_waste])
		
		_sub_writer.element_map = new_element_map
	else:
		data_node.order_changed.disconnect(_on_changed_with_sub_writer)
