tool
extends Node


signal build_completed


var _client
var _client_script = load(_get_current_folder() + "/client.gd")
var _node_serializer = load(_get_current_folder() + "/../common/node_serializer.gd")
var _queue := []


func _ready():
	_start_client()


func rebuild(template_path: String, inspector: Array, generator_payload: Array) -> void:
	var file = File.new()
	file.open(template_path, File.READ)
	var template_content = file.get_as_text()
	if not _client.is_connected_to_server():
		_start_client()
		_queue.append([template_path, inspector, generator_payload])
		return

	var msg := {}
	msg["command"] = "build"
	msg["tpgn"] = template_content
	msg["inspector"] = inspector
	msg["inputs"] = generator_payload
	_client.send(msg)


func _start_client() -> void:
	if not _client:
		_client = _client_script.new()
		add_child(_client)
		_client.connect("connection_etablished", self, "_on_connection_etablished")
		_client.connect("data_received", self, "_on_data_received")

	_client.start()


func _get_current_folder() -> String:
	var script: Script = get_script()
	var path: String = script.get_path()
	return path.get_base_dir()


# Client just connected to the server, send the queued requests
func _on_connection_etablished() -> void:
	# Don't use a while(pop_front) here to prevent an infinite loop if the
	# server is disconnected before we empty the queue.
	var count = _queue.size()
	for i in count:
		var args = _queue.pop_front()
		rebuild(args[0], args[1], args[2])


func _on_data_received(msg: Dictionary) -> void:
	print("in _on_data_received function")
	print(msg["data"]["resource_references"])
	if not msg.has("type"):
		return

	match msg["type"]:
		"build_completed":
			_on_build_completed(msg["data"])
		_:
			print("Unsupported message ", msg["type"])


func _on_build_completed(data: Dictionary) -> void:
	var res := []
	var resource_references = data["resource_references"]
	for dict in data["nodes"]:
		res.append(_node_serializer.deserialize(dict, resource_references, []))

	emit_signal("build_completed", res)


