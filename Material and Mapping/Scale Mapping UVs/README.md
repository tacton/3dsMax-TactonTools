# Scale Mapping UVs

A comprehensive UV mapping utility for scaling and positioning UVW Map gizmos, as well as rescaling existing Unwrap UVW modifiers to match a target tileable map size.

![](<Scale Mapping.jpg>)

![](<Scale Mapping_Results.jpg>)

> **Previously known as:** `Scale Unwrap.ms` and `lmScaleUnwraps_2019.ms`

## Map Size

The **Map Size** spinner (in cm) is shared across all four tool groups and defines the target scale for all operations.

## UI Groups

### 1. Scale Mapping

**Scale Mapping on Selected** scales the UVs of the selected object(s) to match the target Map Size. Behavior depends on what is found in the modifier stack:

- **No UVW Map modifier** — Scales the existing Unwrap UVW to match the target Map Size. If no Unwrap UVW exists, one is added automatically.
- **Planar or Box UVW Map** — Sets the map's length and width (and height for Box) to the Map Size value.
- **Cylindrical UVW Map** — Updates the height to the Map Size and recalculates the U tiling from the existing fitted diameter.
- **Other UVW Map types** (Spherical, ShrinkWrap, etc.) — Prompts to collapse the modifier stack and then rescale the Unwrap UVW.

### 2. Apply UVW

Applies a UVW Map modifier to the selected object(s) with the chosen type, alignment axis, and Map Size. If a UVW Map modifier already exists, it is reused.

- **UVW Map Type** — Choose Planar, Cylindrical, or Box (Box is default).
- **Alignment** — Choose X, Y, or Z axis (Z is default). Changing the alignment radio button after applying will update the axis on any existing UVW Map in the selection immediately.

### 3. Transform Mapping

Rotates the UVW Map gizmo locally around the selected axis. Useful for adjusting map orientation without moving the gizmo center.

- **Rotation Angle** — Choose ±22.5°, ±45°, or ±90° increments.
- **-X / +X / -Y / +Y / -Z / +Z** — Rotate the gizmo in the chosen direction around that local axis.

Works with Planar, Box, and Cylindrical UVW Map modifiers.

### 4. Align UVW Map

Snaps the UVW Map gizmo edge to the object's local bounding box face on the chosen axis. Useful for precisely aligning a map to a surface edge.

- **-X / +X / -Y / +Y / -Z / +Z** — Moves the gizmo so that its edge on that side aligns with the corresponding bounding box face.
- **X / Y / Z** (center buttons) — Centers the gizmo on the object's bounding box along that axis.

Alignment is calculated in the object's local space and remains correct after rotations applied with Transform Mapping.
