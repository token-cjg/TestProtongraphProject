tool
extends ConceptNode


func _init() -> void:
	unique_id = "scale_along_curve_2d"
	display_name = "Scale Along Curve 2D"
	category = "Modifiers/Transforms/2D"
	description = "Scales nodes along a curve"

	set_input(0, "Nodes", ConceptGraphDataType.NODE_2D)
	set_input(1, "Path curve", ConceptGraphDataType.CURVE_2D)
	set_input(2, "Scale curve", ConceptGraphDataType.CURVE_FUNC)
	set_output(0, "", ConceptGraphDataType.NODE_2D)

	mirror_slots_type(0, 0)


func _generate_outputs() -> void:
	var nodes := get_input(0)
	var curve_path: Path2D = get_input_single(1)
	var scale_curve: Curve = get_input_single(2)

	if not nodes or nodes.size() == 0:
		return

	for i in range(nodes.size()):
		# Get position of node local to the curve
		var origin = nodes[i].transform.origin
		if nodes[i].is_inside_tree():
			origin = nodes[i].global_transform.origin # Not available if the node isn't in the tree
		var local_position = curve_path.transform.xform(origin)
		var pixels_along_curve = curve_path.curve.get_closest_offset(local_position)

		# Convert pixels along curve to a value from 0.0 - 1.0
		var percent_along_curve_path = pixels_along_curve / curve_path.curve.get_baked_length()

		# Get this point along our 2D curve as a scale value
		var curve_point = scale_curve.interpolate_baked(percent_along_curve_path)

		# Scale the node transform basis (size) only
		# The transform origin is unaffected so the node doesn't change location
		nodes[i].transform.basis = nodes[i].transform.basis.scaled(curve_point)

	output[0] = nodes
