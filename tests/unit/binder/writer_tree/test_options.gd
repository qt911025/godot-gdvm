extends GutTest

const WriterTreeOptions = preload("res://addons/gdvm/binder/writer_pack/tree/options.gd")
const DataNode = Gdvm.DataNode

func test_property_type_initialization():
	var test_opts := WriterTreeOptions.new({
		"type": WriterTreeOptions.Type.PROPERTY,
		"path": "test_path"
	})
	assert_eq(test_opts.type, WriterTreeOptions.Type.PROPERTY)
	assert_eq(test_opts.path, ^"test_path")

func test_subwriter_callbacks():
	var alloc_fn := func(_n): return RefCounted.new()
	var drop_fn := func(_n): return false
	
	var test_opts := WriterTreeOptions.new({
		"type": WriterTreeOptions.Type.PROPERTY_ARRAY,
		"alloc": alloc_fn,
		"drop": drop_fn,
		"children": WriterTreeOptions.new({
			"path": ^":foo", # 必填，只不过不在这个阶段报错
			"type": WriterTreeOptions.Type.PROPERTY
		})
	})
	
	assert_eq(test_opts.sub_writer.alloc, alloc_fn)
	assert_eq(test_opts.sub_writer.drop, drop_fn)

func test_build_dictionary():
	var built = WriterTreeOptions.build({
		"": WriterTreeOptions.new({
			"path": ^":foo", # 必填，只不过不在这个阶段报错
			"type": WriterTreeOptions.Type.PROPERTY
		})
	})
	assert_eq(built.type, WriterTreeOptions.Type.PROPERTY_DICTIONARY)

func test_build_method_with_complex_array():
	var built = WriterTreeOptions.build([
		WriterTreeOptions.new({
			"path": ^":foo", # 必填，只不过不在这个阶段报错
			"type": WriterTreeOptions.Type.PROPERTY
		})
	])
	assert_eq(built.type, WriterTreeOptions.Type.PROPERTY_ARRAY)
	assert_not_null(built.children)

func test_path_normalization():
	var test_opts = WriterTreeOptions.new({
		"type": WriterTreeOptions.Type.PROPERTY,
		"path": "/absolute/path"
	})
	assert_eq(test_opts.path, ^"absolute/path")