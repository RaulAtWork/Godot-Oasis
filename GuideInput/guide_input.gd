extends Node

# HOW TO ADD A NEW CONTEXT:
# 1. Create a GUIDEMappingContext resource in the Contexts/ folder and bind actions to it.
# 2. Add an @export var context_<name>: GUIDEMappingContext below.
# 3. Add a new entry to the CONTEXT enum.
# 4. Add an entry to the @onready contexts dict: CONTEXT.NAME: {"instance": context_<name>, "priority": PRIORITY.LOW/MEDIUM/HIGH/HIGHEST}
# 5. Assign the exported var in the Inspector (GuideInput node in the autoload scene).

# HOW TO ADD A NEW ACTION:
# 1. Create a GUIDEAction resource and add it to the relevant MappingContext .tres file.
# 2. Add an @export var <name>_action: GUIDEAction below.
# 3. Add a new entry to the INPUT_ACTION enum.
# 4. Add an entry to the @onready actions dict: INPUT_ACTION.NAME: <name>_action
# 5. Assign the exported var in the Inspector (GuideInput node in the autoload scene).

@export_category("Context")
@export var context_dev: GUIDEMappingContext
@export var context_global: GUIDEMappingContext


@export_category("Actions")
@export var pause_action: GUIDEAction
@export var guide_debugger_action: GUIDEAction


enum CONTEXT {
	GLOBAL,
	DEV,

}

enum INPUT_ACTION {
	PAUSE_ACTION,
	GUIDE_DEBUGGER,

}

var context_snapshot: Array = []

var PRIORITY = {
	"HIGHEST": 0,
	"HIGH": 10,
	"MEDIUM": 20,
	"LOW": 30,
}

@onready var actions: Dictionary = {
	INPUT_ACTION.PAUSE_ACTION: pause_action,
	INPUT_ACTION.GUIDE_DEBUGGER: guide_debugger_action,

}

@onready var contexts: Dictionary = {
	CONTEXT.DEV: {
		"instance": context_dev,
		"priority": PRIORITY.HIGHEST,
	},
	CONTEXT.GLOBAL: {
		"instance": context_global,
		"priority": PRIORITY.LOW,
	},
}

func _ready():
	if !context_global:
		push_error("[GuideInput] No global context configured!")
		return

	toggle_context(CONTEXT.GLOBAL, true)
	if Global.dev_mode: toggle_context(CONTEXT.DEV, true)


func get_action(action: INPUT_ACTION) -> GUIDEAction:
	return actions.get(action)


func toggle_context(context: CONTEXT, toggle: bool) -> void:
	var data: Dictionary = contexts.get(context, {})
	if data.is_empty():
		push_error("[GuideInput] Unknown context: %s" % context)
		return

	# We always need to defer the call to the Guide API, because the current actions needs to be resolve before the context is disabled.
	if toggle:
		(func(): GUIDE.enable_mapping_context(data["instance"], false, data["priority"])).call_deferred()
	else:
		(func(): GUIDE.disable_mapping_context(data["instance"])).call_deferred()

func get_context_actions(context: CONTEXT) -> Array[GUIDEAction]:
	var data: Dictionary = contexts.get(context, {})
	if data.is_empty():
		push_error("[GuideInput] Unknown context: %s" % context)
		return []

	var context_actions: Array[GUIDEAction] = []
	for mapping: GUIDEActionMapping in data["instance"].mappings:
		context_actions.append(mapping.action)

	return context_actions

func get_action_enum(action: GUIDEAction) -> INPUT_ACTION:
	return actions.find_key(action)

func is_context_active(context: CONTEXT) -> bool:
	var data: Dictionary = contexts.get(context, {})

	return GUIDE.is_mapping_context_enabled(data["instance"])


# ____ CONTEXT SNAPSHOT / RESTORE ____

func snapshot_contexts() -> void:
	context_snapshot.clear()
	var excluded: Array[CONTEXT] = [CONTEXT.DEV, CONTEXT.GLOBAL]
	for target_context: CONTEXT in contexts:
		if target_context in excluded:
			continue
		var data: Dictionary = contexts[target_context]
		if GUIDE.is_mapping_context_enabled(data["instance"]):
			context_snapshot.append(target_context)
			toggle_context(target_context, false)


func restore_contexts() -> void:
	for target_context: CONTEXT in context_snapshot:
		toggle_context(target_context, true)
	context_snapshot.clear()


# _________________________ HOOKS _________________________

func connect_to_trigger(action: INPUT_ACTION, action_trigger: Callable) -> void:
	get_action(action).triggered.connect(action_trigger)

func connect_to_ongoing(action: INPUT_ACTION, action_trigger: Callable) -> void:
	get_action(action).ongoing.connect(action_trigger)
