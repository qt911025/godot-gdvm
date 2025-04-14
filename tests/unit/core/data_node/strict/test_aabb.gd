extends GutTest

const DataNodeAABB = Gdvm.DataNodeAABB

func test_should_create_aabb():
	var dn_aabb := DataNodeAABB.new(AABB(Vector3(0, 0, 0), Vector3(1, 1, 1)))
	assert_eq(dn_aabb.value(), AABB(Vector3(0, 0, 0), Vector3(1, 1, 1)))

func test_should_set_aabb_position():
	var dn_aabb := DataNodeAABB.new(AABB(Vector3(0, 0, 0), Vector3(1, 1, 1)))
	dn_aabb.position = Vector3(0.5, 0.5, 0.5)
	assert_eq(dn_aabb.value(), AABB(Vector3(0.5, 0.5, 0.5), Vector3(1, 1, 1)))

func test_should_set_aabb_size():
	var dn_aabb := DataNodeAABB.new(AABB(Vector3(0, 0, 0), Vector3(1, 1, 1)))
	dn_aabb.size = Vector3(2, 2, 2)
	assert_eq(dn_aabb.value(), AABB(Vector3(0, 0, 0), Vector3(2, 2, 2)))

func test_should_set_aabb_end():
	var dn_aabb := DataNodeAABB.new(AABB(Vector3(1, 1, 1), Vector3(3, 3, 3)))
	dn_aabb.end = Vector3(2, 2, 2)
	assert_eq(dn_aabb.value(), AABB(Vector3(1, 1, 1), Vector3(1, 1, 1)))
