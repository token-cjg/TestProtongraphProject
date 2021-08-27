tool
extends ConceptNode


func _init() -> void:
	unique_id = "copy_transform_2d"
	display_name = "Replace Transform 2D"
	category = "Modifiers/Transforms/2D"
	description = "Replace the target's transform by the source's transform"

	set_input(0, "Target", ConceptGraphDataType.NODE_3D)
	set_input(1, "Source", ConceptGraphDataType.NODE_3D)
	set_output(0, "", ConceptGraphDataType.NODE_3D)

	mirror_slots_type(0, 0)


func _generate_outputs() -> void:
	var nodes := get_input(0)
	var reference: Node2D = get_input_single(1)

	if not nodes:
		return

	var t = reference.transform
	for i in nodes.size():
		nodes[i].transform = t

	output[0] = nodes
