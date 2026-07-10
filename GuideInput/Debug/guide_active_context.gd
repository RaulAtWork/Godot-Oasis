extends Control

@onready var context_container: VBoxContainer = %ContextContainer

func _ready() -> void:
	GUIDE.input_mappings_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	Utils.queue_free_children_from_node(context_container)
	var sorted := GUIDE.get_enabled_mapping_contexts()
	sorted.sort_custom(func(a, b): return GUIDE._active_contexts[a][0] < GUIDE._active_contexts[b][0])
	for context: GUIDEMappingContext in sorted:
		var label := Label.new()
		var name_str := context.display_name if not context.display_name.is_empty() else context.resource_path.get_file()
		var priority: int = GUIDE._active_contexts[context][0]
		label.text = "[%d] %s" % [priority, name_str]
		context_container.add_child(label)
