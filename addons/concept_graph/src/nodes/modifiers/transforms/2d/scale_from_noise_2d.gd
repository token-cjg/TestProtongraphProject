tool
extends ConceptNode


func _init() -> void:
	unique_id = "scale_transforms_from_noise_2d"
	display_name = "Scale (Noise) 2D"
	category = "Modifiers/Transforms/2D"
	description = "Apply a random scaling to a set of nodes, based on a noise input"

	set_input(0, "Nodes", ConceptGraphDataType.NODE_2D)
	set_input(1, "Noise", ConceptGraphDataType.NOISE)
	set_input(2, "Amount", ConceptGraphDataType.VECTOR2)
	set_output(0, "", ConceptGraphDataType.NODE_2D)

	mirror_slots_type(0, 0)


func _generate_outputs() -> void:
	var nodes := get_input(0)
	var noise = get_input_single(1)
	var amount: Vector2 = get_input_single(2, null)

	if not nodes:
		return

	if not noise or not amount:
		output[0] = nodes
		return

	var rand: float

	for n in nodes:
		rand = noise.get_noise_2dv(n.transform.origin) * 0.5 + 0.5
		n.apply_scale(rand * amount)

	output[0] = nodes
