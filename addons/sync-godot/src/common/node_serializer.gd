extends Node

var _resource_serializer = preload('./resource_serializer.gd')
# Helper to serialize and deserialize node trees to json objects.


# Takes a single node and serialize its contents and its children's content
# into a dictionary
static func serialize(root: Node) -> Dictionary:
	var res := {}
	if not root:
		return res

	res["name"] = root.name
	
	# This is important in order to render meshes on callback after generation.
	# See https://confusedgremlin.wordpress.com/?p=7523
	# Basically, this is passed to protongraph, protongraph appends this attribute to each and every relevant 
	# node on the generated scenetree, then on callback the Client knows where the original node was and can 
	# copy the mesh across to the new scenetree within itself.
	# (We pass this as nodeName: nodePath so that we can fetch the nodePath by nodeName within Protongraph.)
	res["node_path_input"] = { root.name: root.get_path() }

	#print("in the serialize function")
	if root is MeshInstance:
		res["type"] = "mesh"
		res["data"] = _serialize_mesh_instance(root)
		#print("what a mesh")
		#print(res["data"]["resource_path"]) #res://assets/fences/models/fence_planks.glb::2
	elif root is MultiMeshInstance:
		res["type"] = "multi_mesh"
		res["data"] = _serialize_multi_mesh(root)
	elif root is Path:
		res["type"] = "curve_3d"
		res["data"] = _serialize_curve_3d(root)
	elif root is Spatial or root is Position3D:
		res["type"] = "node_3d"
		res["data"] = _serialize_node_3d(root)
	
	if root.get_child_count() > 0:
		res["children"] = []
		for child in root.get_children():
			res["children"].append(serialize(child))

	return res


# Takes a dictionnary and recreates the Godot node tree from there. This is
# the inverse of serialize.
static func deserialize(data: Dictionary, resource_references: Array, child_transversal: Array) -> Node:
	var res
	#print("in the deserialize function")
	#print(data)
	match data["type"]:
		"node_3d":
			res = _deserialize_node_3d(data["data"])
		"mesh":
			res = _deserialize_mesh_instance(data["data"], resource_references, child_transversal)
		"multi_mesh":
			res = _deserialize_multi_mesh(data["data"], resource_references, child_transversal)
		"curve_3d":
			res = _deserialize_curve_3d(data["data"])
		_:
			print("Type ", data["type"], " is not supported")
			return null

	if data.has("children"):
		for child in data["children"]:
			var child_name = child.name as String
			child_transversal.append(child_name)
			res.add_child(deserialize(child, resource_references, child_transversal))

	if "name" in data:
		res.name = data["name"]

	return res


static func serialize_all(nodes: Array) -> Array:
	# print("in the serialize all function")
	var res = []
	for node in nodes:
		res.push_back(serialize(node))
	return res


static func deserialize_all(nodes: Array, resource_references: Array) -> Array:
	var res = []
	for node in nodes:
		res.push_back(deserialize(node, resource_references, []))
	return res


# -- Transform --

static func _serialize_transform(t: Transform) -> Dictionary:
	var data := {}
	var origin = t.origin
	var basis = t.basis

	data["pos"] = _vector_to_array(origin)
	data["basis"] = [
		_vector_to_array(basis.x),
		_vector_to_array(basis.y),
		_vector_to_array(basis.z)
	]
	return data


static func _deserialize_transform(data: Dictionary) -> Transform:
	var t = Transform()

	if "transform" in data:
		data = data["transform"]

	if "pos" in data:
		t.origin = _extract_vector(data["pos"])

	if "basis" in data:
		var basis: Array = data["basis"]
		t.basis.x = _extract_vector(basis[0])
		t.basis.y = _extract_vector(basis[1])
		t.basis.z = _extract_vector(basis[2])

	return t


# -- Node 3D --

static func _serialize_node_3d(node: Spatial) -> Dictionary:
	var data := {}
	data["transform"] = _serialize_transform(node.transform)
	return data


static func _deserialize_node_3d(data: Dictionary) -> Position3D:
	var node = Position3D.new()
	node.transform = _deserialize_transform(data)
	return node


# -- Mesh --

static func _serialize_mesh_instance(mesh_instance: MeshInstance) -> Array:
	var data = _serialize_node_3d(mesh_instance)
	data["mesh"] = {}
	var mesh = mesh_instance.mesh

	if mesh is PrimitiveMesh:
		data["mesh"][0] = _format_array(mesh.get_mesh_arrays())
	else:
		for i in mesh.get_surface_count():
			data["mesh"][i] = _format_array(mesh.surface_get_arrays(i))

	# Make sure that we pass a reference to the resource path of the associated mesh resource!
	if mesh_instance.has_node_and_resource(mesh_instance.get_path()):
		var resource = mesh_instance.get_node_and_resource(mesh_instance.get_path())[0]
		data["resource_path"] = str(resource.mesh.resource_path)

	return data


static func _deserialize_mesh_instance(data: Dictionary, resource_references: Array, child_transversal: Array) -> MeshInstance:
	print("in node_serializer#_deserialize_mesh_instance")
	print(resource_references)
	var mi = MeshInstance.new()
	mi.transform = _deserialize_transform(data)

	var mesh = load(resource_references[0]["remote_resource_path"])
	print(mesh)
	mi.mesh = mesh
	return mi


# -- MultiMesh --

static func _serialize_multi_mesh(mmi: MultiMeshInstance) -> Dictionary:
	var data: Dictionary = _serialize_node_3d(mmi)
	var multimesh: MultiMesh = mmi.multimesh

	var mesh_instance = MeshInstance.new()
	mesh_instance.mesh = multimesh.mesh
	data["mesh"] = _serialize_mesh_instance(mesh_instance)

	var count: int = multimesh.instance_count
	data["count"] = count
	data["instances"] = []
	for i in count:
		var transform: Transform = multimesh.get_instance_transform(i)
		data["instances"].push_back(_serialize_transform(transform))

	return data


static func _deserialize_multi_mesh(data: Dictionary, resource_references: Array, child_transversal: Array) -> Dictionary:
	var count = data["count"]

	var multimesh := MultiMesh.new()
	multimesh.instance_count = 0 # Set this to zero or you can't change the other values
	multimesh.mesh = _deserialize_mesh_instance(data["mesh"], resource_references, child_transversal).mesh
	multimesh.transform_format = 1
	multimesh.instance_count = count

	for i in count:
		var transform_data: Dictionary = data["instances"][i]
		var transform = _deserialize_transform(transform_data)
		multimesh.set_instance_transform(i, transform)

	var mmi = MultiMeshInstance.new()
	mmi.transform = _deserialize_transform(data)
	mmi.multimesh = multimesh
	return mmi


# -- Curve 3D --

static func _serialize_curve_3d(path: Path) -> Dictionary:
	var data = _serialize_node_3d(path)
	data["points"] = []

	var curve: Curve3D = path.curve
	for i in curve.get_point_count():
		var point = {}
		point["pos"] = _vector_to_array(curve.get_point_position(i))
		point["in"] = _vector_to_array(curve.get_point_in(i))
		point["out"] = _vector_to_array(curve.get_point_out(i))
		point["tilt"] = curve.get_point_tilt(i)
		data["points"].push_back(point)

	return data


static func _deserialize_curve_3d(data: Dictionary) -> Path:
	var curve = Curve3D.new()
	for i in data["points"].size():
		var point = data["points"][i]
		var p_pos = _extract_vector(point["pos"]) if "pos" in point else Vector3.ZERO
		var p_in = _extract_vector(point["in"]) if "in" in point else Vector3.ZERO
		var p_out = _extract_vector(point["out"]) if "out" in point else Vector3.ZERO
		var tilt = point["tilt"] if "tilt" in point else 0.0
		curve.add_point(p_pos, p_in, p_out)
		curve.set_point_tilt(i, tilt)

	var path = Path.new()
	path.transform = _deserialize_transform(data)
	path.curve = curve
	return path


# -- Utility functions

static func _extract_vector(data: Array) -> Vector3:
	var v = null
	if data.size() == 3:
		v = Vector3.ZERO
		v.x = data[0]
		v.y = data[1]
		v.z = data[2]

	elif data.size() == 2:
		v = Vector2.ZERO
		v.x = data[0]
		v.y = data[1]

	return v


static func _format_array(array: Array) -> Array:
	for i in array.size():
		if array[i] is PoolVector2Array or array[i] is PoolVector3Array:
			array[i] = _format_pool_vector_array(array[i])
	return array


static func _format_pool_vector_array(array) -> Array:
	var res = []
	for vec in array:
		res.append(_vector_to_array(vec))
	return res


static func _vector_to_array(vec) -> Array:
	if vec is Vector3:
		return [vec.x, vec.y, vec.z]
	if vec is Vector2:
		return [vec.x, vec.y]
	return []


static func _to_pool(array: Array):
	var tmp = []
	for vec in array:
		tmp.append(_extract_vector(vec))

	if tmp[0] is Vector2:
		return PoolVector2Array(tmp)

	return PoolVector3Array(tmp)

# This is an awful solution, but NodePath is missing an important method, so there's no great alternative that I've found.
# Try me with get_node_property(self, "Control/Spatial/CollisionShape2D:shape:extents:x")

func get_node_property(from: Node, path: NodePath):
	path = path as NodePath
	var node_path = get_as_node_path(path)
	var property_path = (path.get_concatenated_subnames() as NodePath).get_as_property_path()
	return from.get_node(node_path).get_indexed(property_path)

func get_as_node_path(path: NodePath) -> NodePath:
	path = path as NodePath
	var node_path = path as String
	var property_path = path.get_concatenated_subnames() as String
	node_path.erase((path as String).length() - property_path.length() - 1, property_path.length() + 1)
	return node_path as NodePath
