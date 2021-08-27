tool
extends ConceptNode

"""
Creates an array of transforms
"""


func _init() -> void:
	unique_id = "create_point_array"
	display_name = "Create Points Array"
	category = "Generators/Transforms/3D"
	description = "Creates an array of points"

	set_input(0, "Count", ConceptGraphDataType.SCALAR, {"step": 1, "allow_lesser": false})
	set_input(1, "Offset", ConceptGraphDataType.VECTOR3)
	set_output(0, "", ConceptGraphDataType.NODE_3D)


func _generate_outputs() -> void:
	var count: int = get_input_single(0, 0)
	var offset: Vector3 = get_input_single(1, Vector3.ONE)

	for i in range(count):
		var p = Position3D.new()
		p.transform.origin = offset * i
		output[0].append(p)
