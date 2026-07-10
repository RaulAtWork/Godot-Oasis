# GuideInput

An autoload wrapper around the [GUIDE](https://github.com/ideasfromjson/godot-guide) input plugin for Godot 4, providing a central place to register mapping contexts and actions, toggle contexts by priority, and snapshot/restore context state.

---

## Overview

`GuideInput` (`guide_input.tscn`) is meant to be added as an autoload. It exposes `GUIDEMappingContext` and `GUIDEAction` resources as typed exports, then indexes them behind two enums (`CONTEXT`, `INPUT_ACTION`) so the rest of the codebase can refer to input by name instead of holding direct resource references.

Contexts are enabled/disabled through GUIDE with an explicit priority, so higher-priority contexts (e.g. a dev/debug context) can shadow lower-priority ones (e.g. gameplay) without either side needing to know about the other.

---

## Exports

| Category | Property         | Type                  | Description                                                |
| -------- | ---------------- | --------------------- | ---------------------------------------------------------- |
| Context  | `context_<name>` | `GUIDEMappingContext` | One export per mapping context, assigned in the Inspector. |
| Actions  | `<name>_action`  | `GUIDEAction`         | One export per action, assigned in the Inspector.          |

---

## API

| Method                                                                       | Description                                                                                                                                        |
| ---------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| `get_action(action: INPUT_ACTION) -> GUIDEAction`                            | Looks up the `GUIDEAction` resource for an enum entry.                                                                                             |
| `get_action_enum(action: GUIDEAction) -> INPUT_ACTION`                       | Reverse lookup: resource → enum entry.                                                                                                             |
| `toggle_context(context: CONTEXT, toggle: bool) -> void`                     | Enables/disables a mapping context at its configured priority. The GUIDE call is deferred so in-flight actions resolve before the context changes. |
| `is_context_active(context: CONTEXT) -> bool`                                | Returns whether a context is currently enabled.                                                                                                    |
| `get_context_actions(context: CONTEXT) -> Array[GUIDEAction]`                | Returns all actions bound within a context's mappings.                                                                                             |
| `snapshot_contexts() -> void`                                                | Disables and remembers every currently-enabled context except `GLOBAL`/`DEV`. Used to temporarily clear gameplay input (e.g. opening a menu).      |
| `restore_contexts() -> void`                                                 | Re-enables whatever `snapshot_contexts()` most recently captured.                                                                                  |
| `connect_to_trigger(action: INPUT_ACTION, action_trigger: Callable) -> void` | Connects a callable to an action's `triggered` signal.                                                                                             |
| `connect_to_ongoing(action: INPUT_ACTION, action_trigger: Callable) -> void` | Connects a callable to an action's `ongoing` signal.                                                                                               |

### Priority

Contexts are enabled with one of four priority tiers, higher priority wins when contexts overlap:

```
PRIORITY.HIGHEST = 0
PRIORITY.HIGH    = 10
PRIORITY.MEDIUM  = 20
PRIORITY.LOW     = 30
```

`GLOBAL` runs at `LOW` and `DEV` at `HIGHEST` by default; `DEV` is only enabled when `Global.dev_mode` is true.

---

## Adding a new context

1. Create a `GUIDEMappingContext` resource in a `Contexts/` folder and bind actions to it.
2. Add an `@export var context_<name>: GUIDEMappingContext` in `guide_input.gd`.
3. Add a new entry to the `CONTEXT` enum.
4. Add an entry to the `contexts` dict: `CONTEXT.NAME: {"instance": context_<name>, "priority": PRIORITY.LOW/MEDIUM/HIGH/HIGHEST}`.
5. Assign the exported var in the Inspector on the `GuideInput` node in the autoload scene.

## Adding a new action

1. Create a `GUIDEAction` resource and add it to the relevant `MappingContext` `.tres` file.
2. Add an `@export var <name>_action: GUIDEAction` in `guide_input.gd`.
3. Add a new entry to the `INPUT_ACTION` enum.
4. Add an entry to the `actions` dict: `INPUT_ACTION.NAME: <name>_action`.
5. Assign the exported var in the Inspector on the `GuideInput` node in the autoload scene.

---

## Debug/

A debugger panel that lists currently active mapping contexts, sorted by priority.

- **`guide_active_context.gd`** — Populates a `VBoxContainer` with one label per enabled `GUIDEMappingContext`, showing `[priority] context_name`. Refreshes on `GUIDE.input_mappings_changed`.
- **`debug_custom_guide.tscn`** — A `Control` scene combining the built-in `guide/debugger/guide_debugger.gd` panel (actions/inputs/priorities) with the active-context list above, styled via `guide_debug_theme.tres`.

---

## Notes

- `guide_input.tscn` is the autoload scene; every context and action export must be wired to a resource before `_ready()` runs, since it calls `push_error` and bails if `context_global` is unset.
- `toggle_context` defers its call to the GUIDE API to let the currently-resolving action finish before its context is disabled.
