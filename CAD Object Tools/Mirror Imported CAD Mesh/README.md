# Mirror Imported CAD Mesh

Mirrors a CAD-imported object with explicit normals without destroying them.

![](<Mirror CAD Imported Mesh.jpg>)

## Overview

When mirroring objects with explicit normals in 3ds Max, one of the axes will result in a value of `-100`. Correcting this typically requires resetting the transforms, which destroys the explicit normals.

The standard manual workaround is to apply a Symmetry modifier with **Slice Along Mirror** and **Weld Seam** unchecked, then apply an additional modifier to select and delete the unwanted element. This utility automates those steps.

## How to Use

**1.** Select the object you want to mirror.

**2.** Set the axis you would like to mirror on and press **Apply Symmetry**. A Symmetry modifier will be applied to the object.

**3.** Adjust the **Symmetry Axis** as needed to confirm the mirror direction is correct.

> **Note:** The pre-mirrored geometry will still be visible at this point.

**4.** When ready, press **Commit Mirror**. The result will be the mirrored object with correct explicit normals.

The **Mirror UV's** option is also available and is on by default.

## Opposite Placement

Moves the selection to the opposite side of the world on a chosen axis. For example, an object at `+1.435` on X can be sent to `-1.435` on X with a single button press.

**1.** Select the object(s) you want to reposition.

**2.** Set the **Placement Axis** (X, Y, or Z) — the world axis the selection should be flipped across.

**3.** Press **Move Opposite**. The selection moves to the opposite side of the world on that axis.

> **Note:** When multiple objects are selected, they are flipped together as a group around their shared average position, preserving their relative spacing.
