extends GutTest

const DataNodeBasis = Gdvm.DataNodeBasis

func test_initialization():
	var basis_node := DataNodeBasis.new(Basis.IDENTITY)
	assert_eq(basis_node.value(), Basis.IDENTITY)

func test_x_property_setter():
	var basis_node := DataNodeBasis.new(Basis.IDENTITY)
	var new_x = Vector3(1, 2, 3)
	basis_node.x = new_x
	assert_eq(basis_node.x, new_x)
	assert_eq(basis_node.y, Vector3(0, 1, 0))
	assert_eq(basis_node.z, Vector3(0, 0, 1))

func test_y_property_setter():
	var basis_node := DataNodeBasis.new(Basis.IDENTITY)
	var new_y = Vector3(3, 2, 1)
	basis_node.y = new_y
	assert_eq(basis_node.y, new_y)
	assert_eq(basis_node.x, Vector3(1, 0, 0))
	assert_eq(basis_node.z, Vector3(0, 0, 1))

func test_z_property_setter():
	var basis_node := DataNodeBasis.new(Basis.IDENTITY)
	var new_z = Vector3(2, 3, 1)
	basis_node.z = new_z
	assert_eq(basis_node.z, new_z)
	assert_eq(basis_node.x, Vector3(1, 0, 0))
	assert_eq(basis_node.y, Vector3(0, 1, 0))

func test_set_value_with_valid_basis():
	var basis_node := DataNodeBasis.new(Basis.IDENTITY)
	var new_basis = Basis(Vector3.RIGHT, Vector3.UP, Vector3.BACK)
	assert_true(basis_node._set_value(new_basis))
	assert_eq(basis_node.value(), new_basis)
