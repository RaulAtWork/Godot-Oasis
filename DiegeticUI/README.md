# DiegeticUI

A collection of components for building diegetic (in-world) UI in Godot 4.

---

## MouseInputToNodeViewComponent

Bridges 3D mouse/touch input on an `Area3D` to a `Viewport`, enabling a flat mesh to act as an interactive UI surface inside the 3D world.

### How it works

1. The component listens for input events on an `Area3D` that sits over a `PlaneMesh` or `QuadMesh`.
2. It converts the 3D hit position into the 2D coordinate space of a `Viewport` (range `0 → viewport.size`).
3. It calculates relative movement and velocity for motion/drag events.
4. It forwards the remapped event to the viewport via `push_input()`, so any Control nodes inside it receive mouse input as if the user were clicking directly on a flat screen.

### Exports

| Property | Type | Description |
|---|---|---|
| `input_area` | `Area3D` | The collision area that captures 3D mouse events. |
| `mesh` | `MeshInstance3D` | The mesh the UI is rendered on. Must use `PlaneMesh` or `QuadMesh`. |
| `viewport_node` | `Viewport` | The viewport whose Control nodes should receive the remapped input. |

### API

| Method | Description |
|---|---|
| `enable()` | Activates input forwarding. |
| `disable()` | Suspends input forwarding (events are ignored). |

The component starts in `DISABLED` mode and must be explicitly enabled.

### Setup

1. Add a `SubViewport` to your scene and build your UI inside it.
2. Apply the viewport's texture to a `PlaneMesh` or `QuadMesh` via a `StandardMaterial3D`.
3. Place an `Area3D` (with a matching `CollisionShape3D`) over the mesh.
4. Add `MouseInputToNodeViewComponent` as a child node and assign the three exports.
5. Call `enable()` when the UI should accept input.

### Limitations

- Only `PlaneMesh` and `QuadMesh` are supported (the component reads `mesh.size`).
- Billboard mode is not currently supported (see `TODO` in source).
