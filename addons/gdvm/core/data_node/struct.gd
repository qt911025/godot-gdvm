## 结构节点
## 用于构建静态的树状结构
extends DataNode
const DataNode = preload("./base.gd")
const DataNodeStruct = preload("./struct.gd")
const Utils = preload("../../utils.gd")

var _property_list: Array[Dictionary] = Array([], TYPE_DICTIONARY, "", null)
var _data: Dictionary[StringName, DataNode]

var _computed: Dictionary[StringName, Computed] # key: output, value: Computed
var _computed_dependencies: Dictionary[StringName, Dictionary] # key: dependency, value: {output: null}

var _child_changed_informed: bool

class Computed:
	var _dependency_keys: Dictionary[DataNode, StringName]
	var _dependency_values: Dictionary[StringName, Variant]
	var _outputs: Dictionary[StringName, DataNode]
	var _computer: Callable

	func _init(dependencies: Dictionary, outputs: Dictionary, computer: Callable) -> void:
		_outputs.assign(outputs)
		_outputs.make_read_only()
		_computer = computer

		for key in dependencies:
			assert(dependencies[key] is DataNode, "DataNodeStruct: Computed dependency must be DataNode")
			var dep_data_node := dependencies[key] as DataNode
			_dependency_keys[dep_data_node] = key
			_dependency_values[key] = dep_data_node.value()
			dep_data_node.changed.connect(_on_dependency_changed)

		_computer.call(_dependency_values, _outputs)

	func _on_dependency_changed(changed_node: DataNode) -> void:
		_dependency_values[_dependency_keys[changed_node]] = changed_node.value()
		_computer.call(_dependency_values, _outputs)
	
	func get_output(key: StringName) -> DataNode:
		if _outputs.has(key):
			return _outputs[key]
		return null
	func get_output_keys() -> Array[StringName]:
		return _outputs.keys()

func _get_property_list() -> Array[Dictionary]:
	return _property_list

func _set(property: StringName, value: Variant) -> bool:
	if _data.has(property):
		_data[property].render(value)
		return true
	return false

func _get(property: StringName) -> Variant:
	if _data.has(property):
		return _data[property]
	elif _computed.has(property):
		return _computed[property].get_output(property)
	return null

# 创建 ======================================================================
func _init() -> void:
	pass

## 改变 ======================================================================
# struct并不是dictionary，不会赋一个不存在的键时新增键
# 要想改变必须新增一个属性

## 添加一个属性
func add_property(key: StringName, data_node: DataNode) -> void:
	assert(not key.is_empty())
	assert(not _data.has(key) and not _computed.has(key), "DataNodeStruct: property or computed property (%s) already exists." % key)

	_property_list.append({
		"name": key,
		"type": TYPE_OBJECT,
		"class_name": &"RefCounted"
	})
	_data[key] = data_node
	# 通知writer是同步，通知父节点是异步。
	# 如此设计是因为构造一个DataNode树总是最先绑定的，Writer总是后绑定，优先级不高。
	# 如果通知父节点也是同步，数据更新会导致父节点先通知Writer（深度优先的调用），因为子节点尚未更新，父节点的更新得到的还是老状态（如果父Writer获取的数据不是从DataNode来的）
	data_node.changed.connect(_on_property_changed)
	_on_property_changed(data_node)

## 移除一个属性或计算属性
## 这会删除掉所有依赖这个属性的计算属性
func remove_property(key: StringName) -> void:
	# 删属性
	if _data.has(key):
		var erased_data := _data[key] as DataNode
		_data.erase(key)
		_property_list = _property_list.filter(func(p: Dictionary) -> bool: return p["name"] != key)
		erased_data.changed.disconnect(_on_property_changed)
		_on_property_changed(erased_data)
	
	# 删计算属性以及所有依赖
	var computed_properties_to_remove := [key]
	while computed_properties_to_remove.size() > 0:
		var computed_property := computed_properties_to_remove.pop_front()
		if _computed_dependencies.has(computed_property): # 广度优先遍历进入删除队列
			computed_properties_to_remove.append_array(_computed_dependencies[computed_property].keys())
			_computed_dependencies.erase(computed_property)
		if _computed.has(computed_property):
			var erased_computed := _computed[computed_property] as Computed
			for property_to_erase in erased_computed.get_output_keys():
				# 如果多个计算属性是一起被添加（属于同一个计算函数）的，
				# 删掉其中一个计算属性会导致同属一个计算函数的其他计算属性都被删除
				if property_to_erase != computed_property:
					computed_properties_to_remove.append(property_to_erase)
				_computed.erase(computed_property)
			# 删掉上游对本计算属性的引用，清理垃圾
			for dependency in erased_computed._dependency_keys.values():
				_computed_dependencies[dependency].erase(computed_property)

## 获取某个属性或者计算属性的data node
func get_property_data_node(key: StringName) -> DataNode:
	if _data.has(key):
		return _data[key]
	elif _computed.has(key):
		return _computed[key].get_output(key)
	return null

## 添加一个计算属性
## 计算属性类似Vue的computed，会同步更新值
## 依赖和输出都可以是多个，它们可以共用一个计算函数，只要有一个依赖改动都会触发计算函数
## dependencies: Array 依赖列表，里面所有元素都应该是StringName，且必须已经是本DataNode的属性或计算属性
## outputs: Dictionary 计算属性列表，键为计算属性，值为一个已经准备好的DataNode，和add_property一样
## computer: Callable 计算函数，第一个参数是一个字典，键为依赖项（依赖项既可以是属性也可以是计算属性），值为这个依赖项的值；
##   第二个参数也是一个字典，键为所添加的计算属性，值为这个计算属性的DataNode
## 为了更高的性能，Gdvm不会禁止手动修改计算属性的DataNode，也会直接传入原始的数据而非拷贝。请自觉保持参数的只读，只渲染计算属性的DataNode，只绑定Writer
func add_computed_properties(dependencies: Array, outputs: Dictionary, computer: Callable) -> void:
	assert(__assert_validate_add_computed(dependencies, outputs))
	var dependencies_dict := {}
	for dependency in dependencies:
		var computed_dependency := _computed_dependencies.get_or_add(dependency, {}) as Dictionary
		for output_key in outputs:
			computed_dependency[output_key] = null
		if _data.has(dependency):
			dependencies_dict[dependency] = _data[dependency]
		elif _computed.has(dependency):
			dependencies_dict[dependency] = _computed[dependency].get_output(dependency)
		else:
			push_error("DataNodeStruct: dependency (%s) not found, it should not happen!" % dependency)
		assert(dependencies_dict[dependency] is DataNode, "DataNodeStruct: Computed dependency must be DataNode")
	var computed := Computed.new(dependencies_dict, outputs, computer)
	for output in outputs:
		_computed[output] = computed

func __assert_validate_add_computed(dependencies: Array, outputs: Dictionary) -> bool:
	for key in dependencies:
		assert(not key.is_empty())
		assert(_data.has(key) or _computed.has(key),
		"DataNodeStruct: Add computed property failed, dependency (%s) not found." % key)
	for key in outputs:
		assert(not key.is_empty())
		assert(not _data.has(key) and not _computed.has(key),
		"DataNodeStruct: Add computed property failed, output (%s) already exists." % key)
		assert(outputs[key] is DataNode, "DataNodeStruct: Computed output must be DataNode")
	return true

## 行为 ======================================================================
func _set_value(value: Variant) -> bool:
	## 只接受属性的渲染，忽略计算属性
	match typeof(value):
		TYPE_OBJECT:
			var keys := (value as Object).get_property_list().map(func(p: Dictionary) -> String: return p["name"])
			for key in keys:
				if _data.has(key): _data[key].render(value.get(key)) # 忽略不存在的键，也避免赋值到私有的值
		TYPE_DICTIONARY:
			for key in value.keys():
				if _data.has(key): _data[key].render(value[key])
		_:
			push_warning("DataNodeStruct mismatched: Unsupported type ----", Utils.type_get_string(Utils.instance_get_type(value)))
	return false # 修改叶子节点会连锁触发，不需要返回true

func _get_value() -> Variant:
	var result := {}
	for key in _data.keys():
		result[key] = _data[key].value()
	for key in _computed.keys():
		result[key] = _computed[key].get_output(key).value()
	return result

func _on_property_changed(child: DataNode) -> void:
	if not _child_changed_informed:
		_child_changed_informed = true
		_defer_mark_changed.call_deferred()

func _defer_mark_changed() -> void:
	_child_changed_informed = false
	mark_changed()