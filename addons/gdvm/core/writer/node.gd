# WriterNode
# 关联一个数组，专门用于修改Node的子节点
extends Writer
const Writer = preload("./base.gd")
const DataNodeList = preload("../data_node/list.gd")

var _sub_writer: ChildSubWriter

class ChildInfo:
	var target_child: Node
	var binded_writers: Array[Writer]

	func _init(target_child: Node, binded_writers: Array) -> void:
		self.target_child = target_child
		self.binded_writers = Array(binded_writers, TYPE_OBJECT, "RefCounted", Writer)

class ChildSubWriter:
	var alloc_node: Callable
	var drop_node: Callable

	var element_map := {} # 键是object id，作为弱引用，值是ChildInfo，是对target_child的强引用

	## 子节点写者
	## alloc_node_cb: Callable 子节点生成函数，应返回一个ChildInfo
	## drop_node_cb: Callable 子节点释放函数，返回值若为true，则提示子节点已经在回调里释放（或标记释放），否则为未释放，系统会执行默认的释放操作
	func _init(
		alloc_node_cb: Callable = func(child_data_node: DataNode) -> ChildInfo: return null,
		drop_node_cb: Callable = func(target_child_info: ChildInfo) -> bool: return false,
	) -> void:
		alloc_node = alloc_node_cb
		drop_node = drop_node_cb

## 节点写者
## target: Node 要控制的目标节点
## data_node: DataNodeList 上游DataNode
## child_sub_writer: ChildSubWriter 子节点写者
func _init(target: Node, data_node: DataNodeList, child_sub_writer: ChildSubWriter) -> void:
	assert(is_instance_valid(target))
	assert(is_instance_valid(data_node))
	assert(is_instance_valid(child_sub_writer))

	_target_ref = weakref(target)
	# _data_node_ref = weakref(data_node)
	_sub_writer = child_sub_writer
	data_node.changed.connect(_on_data_node_changed)
	_on_data_node_changed(data_node)

func _on_data_node_changed(data_node: DataNode) -> void:
	var target: Node = _target_ref.get_ref()
	if is_instance_valid(target):
		var element_nodes: Array = data_node.get_element_nodes()
		var new_size := element_nodes.size()
		var source_element_nodes: Array[DataNode] = data_node.get_element_nodes()

		# 一些意料之外增加的节点，不在element_map中的，会有基本的删除操作
		var old_element_map := _sub_writer.element_map
		var new_element_map := {}

		for i in new_size:
			var source_element_node: DataNode = source_element_nodes[i]
			var source_element_node_id: int = source_element_node.get_instance_id()
			var target_child_info: ChildInfo
			if old_element_map.has(source_element_node_id):
				target_child_info = old_element_map.get(source_element_node_id)
				old_element_map.erase(source_element_node_id)
				if not is_instance_valid(target_child_info.target_child) or target_child_info.target_child.get_parent() != target:
					# 如果被外部删除了，就当不存在。那么如果没删除只是被移出，也当不存在，两者都只需要抛弃child_info，抛弃child_info即抛弃所有绑定的写者
					# 不会执行释放钩子，写者不会“追杀”已经离开的节点。擅自移出后果自负
					target_child_info = null
			if target_child_info == null:
				target_child_info = _sub_writer.alloc_node.call(source_element_node)
				target.add_child(target_child_info.target_child)
			new_element_map[source_element_node_id] = target_child_info
			target.move_child(target_child_info.target_child, i)

		for id_of_waste in old_element_map.keys():
			var info: ChildInfo = old_element_map[id_of_waste]
			target.remove_child(info.target_child)
			if not _sub_writer.drop_node.call(info):
				info.target_child.queue_free()

		# 删掉意料之外的新子节点
		while target.get_child_count() > new_size:
			var child_to_be_removed: Node = target.get_child(new_size)
			target.remove_child(child_to_be_removed)
			child_to_be_removed.queue_free()

		_sub_writer.element_map = new_element_map
	else:
		data_node.changed.disconnect(_on_data_node_changed)