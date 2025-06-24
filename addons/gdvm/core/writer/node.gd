# WriterNode
# 关联一个数组，专门用于修改Node的子节点
extends Writer
const Writer = preload("./base.gd")
const DataNodeList = preload("../data_node/list.gd")

var _sub_writer: ChildSubWriter

class ChildInfo:
	var source_child_id: int
	var target_element_id: int
	var binded_writers: Array[Writer]

	func _init(source_child_id: int, target_element_id: int, binded_writers: Array) -> void:
		self.source_child_id = source_child_id
		self.target_element_id = target_element_id
		self.binded_writers = Array(binded_writers, TYPE_OBJECT, "RefCounted", Writer)

class ChildSubWriter:
	var alloc_node: Callable
	var bind_writers: Callable
	var drop_node: Callable

	var child_map: Array[ChildInfo]

	## 子节点写者
	## alloc_node_cb: Callable 子节点生成函数，应返回对应生成的子节点
	## bind_writers_cb: Callable 子节点绑定写者函数，返回值是绑定的写者数组
	## drop_node_cb: Callable 子节点释放函数，返回值若为true，则提示子节点已经在回调里释放（或标记释放），否则为未释放，系统会执行默认的释放操作
	func _init(
		alloc_node_cb: Callable = func(source_data_node: DataNode) -> Node: return null,
		bind_writers_cb: Callable = func(source_data_node: DataNode, target_child: Node) -> Array: return [],
		drop_node_cb: Callable = func(target_child: Node) -> bool: return false,
	) -> void:
		alloc_node = alloc_node_cb
		bind_writers = bind_writers_cb
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
	_sub_writer = child_sub_writer
	data_node.changed.connect(_on_data_node_changed)
	_on_data_node_changed(data_node)

func _on_data_node_changed(data_node: DataNode) -> void:
	var target: Node = _target_ref.get_ref()
	if is_instance_valid(target):
		var source_element_nodes: Array[DataNode] = data_node.get_element_nodes()
		var new_size := source_element_nodes.size()
		_sub_writer.child_map.resize(new_size)
		var target_size := target.get_child_count()

		if target_size < new_size:
			for i in range(target_size, new_size):
				target.add_child(_sub_writer.alloc_node.call(source_element_nodes[i]))

		if target_size > new_size:
			for i in range(new_size, target_size):
				var child_to_be_removed := target.get_child(i)
				if not _sub_writer.drop_node.call(child_to_be_removed):
					child_to_be_removed.queue_free()
				if target.has_child(child_to_be_removed):
					target.remove_child(child_to_be_removed)

		var different_index: Dictionary[int, Dictionary]

		for i in new_size:
			var source_element: DataNode = source_element_nodes[i]
			var source_element_id: int = source_element.get_instance_id()
			var target_child: Node = target.get_child(i)
			var target_child_id: int = target_child.get_instance_id()
			var child_info := _sub_writer.child_map[i]
			if not (child_info != null and \
			child_info.source_child_id == source_element_id and \
			child_info.target_element_id == target_child_id):
				var new_info := {
					s = source_element,
					sid = source_element_id,
					t = target_child,
					tid = target_child_id,
				}
				different_index[i] = new_info
				_sub_writer.child_map[i] = null
		for i in different_index:
			var new_info := different_index[i]
			_sub_writer.child_map[i] = ChildInfo.new(
				new_info.sid,
				new_info.tid,
				_sub_writer.bind_writers.call(new_info.s, new_info.t)
			)
	else:
		data_node.changed.disconnect(_on_data_node_changed)