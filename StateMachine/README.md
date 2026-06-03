# StateMachine

A generic, node-based hierarchical state machine for Godot 4.

---

## Overview

Two classes work together:

- **`StateMachineNode`** — manages the active state and delegates engine callbacks to it.
- **`StateNode`** — virtual base class for individual states.

States are child nodes of the `StateMachineNode`. The machine automatically discovers them at startup and sets itself as their `state_machine` reference.

---

## StateMachineNode

### Exports

| Property | Type | Description |
|---|---|---|
| `initial_state` | `NodePath` | Path to the child `StateNode` that is active at startup. Set in the inspector. |

### Signals

| Signal | Description |
|---|---|
| `transitioned(state_name: String)` | Emitted after every successful state transition, carrying the new state's node name. |

### API

| Method | Description |
|---|---|
| `transition_to(target_state_name: String, msg: Dictionary = {})` | Exits the current state, switches to the named child state, and calls its `enter(msg)`. Emits `transitioned`. If the target name is not found, a warning is pushed and the transition is skipped silently. |

### Engine callbacks

`StateMachineNode` forwards `_unhandled_input`, `_process`, and `_physics_process` to the active state's corresponding virtual methods each frame.

---

## StateNode

Virtual base class. Extend this to implement each state.

### Properties

| Property | Type | Description |
|---|---|---|
| `state_machine` | `StateMachineNode` | Set automatically by the machine on `_ready`. Use it to call `state_machine.transition_to()` from within a state. |

### Virtual methods to override

| Method | Engine callback | Description |
|---|---|---|
| `enter(msg: Dictionary = {})` | — | Called when this state becomes active. Use `msg` to receive data from the previous state. |
| `exit()` | — | Called just before the machine leaves this state. Use it to clean up. |
| `handle_input(event: InputEvent)` | `_unhandled_input` | Handle input events. |
| `update(delta: float)` | `_process` | Per-frame logic. |
| `physics_update(delta: float)` | `_physics_process` | Physics-step logic. |

---

## Setup

1. Add a `StateMachineNode` as a child of the entity that owns the state machine (e.g. a player, enemy, or door).
2. Add one `StateNode`-derived script per state as children of the `StateMachineNode`.
3. Set `initial_state` in the inspector to point to the starting state node.
4. In each state, call `state_machine.transition_to("StateName")` to switch states, optionally passing a `msg` dictionary.

```
Player
└── StateMachineNode       ← initial_state = "Idle"
    ├── Idle  (StateNode)
    ├── Run   (StateNode)
    └── Jump  (StateNode)
```

---

## Notes

- The machine waits for `owner.ready` before initializing, so states can safely reference sibling nodes.
- Transitions to unknown state names emit a warning rather than crashing, making it safe to reuse state scripts across different machines that may not share the same state set.
