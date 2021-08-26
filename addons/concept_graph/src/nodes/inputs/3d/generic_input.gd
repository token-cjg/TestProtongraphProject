tool
extends ConceptNode

"""
This node references a child of the ConceptGraph. Exposed as a generic Spatial node
"""


var _input_name: LineEdit


func _init() -> void:
	unique_id = "input_generic"
	display_name = "Input Generic 3D"
	category = "Inputs/Nodes/3D"
	description = "Exposes a Node3D from the scene tree to the graph editor. Must be a child of the Input node."

	set_input(0, "", ConceptGraphDataType.STRING, {"placeholder": "Input node"})
	set_input(1, "Children only", ConceptGraphDataType.BOOLEAN)
	set_output(0, "", ConceptGraphDataType.NODE_3D)


func _generate_outputs() -> void:
	var node_name: String = get_input_single(0, "")
	var children_only: bool = get_input_single(1, false)
	if not node_name or node_name == "":
		return

	var node = get_editor_input(node_name)
	if not node:
		return

	if node is ConceptGraph:
		node = node.get_child(1)

	if children_only:
		output[0] = node.get_children()
	else:
		output[0] = node
