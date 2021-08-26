tool
extends ConceptNode

"""
Discard all the nodes within a certain distance from the origin
"""


func _init() -> void:
	unique_id = "exclude_nodes_by_distance_2d"
	display_name = "Exclude by Distance 2D"
	category = "Modifiers/Nodes/2D"
	description = "Discard all the objects within a radius from the given position"

	set_input(0, "Nodes", ConceptGraphDataType.NODE_2D)
	set_input(1, "Origin", ConceptGraphDataType.VECTOR2)
	set_input(2, "Radius", ConceptGraphDataType.SCALAR, {"min": 0.0, "allow_lesser": false})
	set_input(3, "Invert", ConceptGraphDataType.BOOLEAN)
	set_output(0, "", ConceptGraphDataType.NODE_2D)

	mirror_slots_type(0, 0)


func _generate_outputs() -> void:
	var nodes := get_input(0)
	var origin: Vector2 = get_input_single(1, Vector2.ZERO)
	var radius: float = get_input_single(2, 0.0)
	var invert: bool = get_input_single(3, false)

	var radius2 = pow(radius, 2)

	for node in nodes:
		var pos = node.transform.origin
		if node.is_inside_tree():
			pos = node.global_transform.origin
		var dist2 = origin.distance_squared_to(pos)
		if not invert and dist2 > radius2:
			output[0].append(node)
		elif invert and dist2 <= radius2:
			output[0].append(node)
