tool
extends ConceptNode

"""
Generates a curve object made of a single line
"""


func _init() -> void:
	unique_id = "curve_generator_line"
	display_name = "Create Line 3D"
	category = "Generators/Curves/3D"
	description = "Creates a line curve"

	set_input(0, "Length", ConceptGraphDataType.SCALAR, {"value": 1.0, "min": 0, "allow_lesser": false})
	set_input(1, "Centered", ConceptGraphDataType.BOOLEAN, {"value": false})
	set_input(2, "Local Axis", ConceptGraphDataType.VECTOR3)
	set_input(3, "Origin", ConceptGraphDataType.VECTOR3)
	set_output(0, "", ConceptGraphDataType.CURVE_3D)


func _generate_outputs() -> void:
	var length: float = get_input_single(0, 1)
	var centered: bool = get_input_single(1, false)
	var axis: Vector3 = get_input_single(2, Vector3.UP).normalized()
	var origin: Vector3 = get_input_single(3, Vector3.ZERO)


	var start = Vector3.ZERO
	var end = axis * length
	if centered:
		var offset = axis * length * 0.5
		start -= offset
		end -= offset

	var path = Path.new()
	path.curve = Curve3D.new()
	path.curve.add_point(start)
	path.curve.add_point(end)
	path.translation = origin

	output[0] = path

