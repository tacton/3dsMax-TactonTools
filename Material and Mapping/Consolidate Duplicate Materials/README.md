# Consolidate Duplicate Materials

Finds materials with the same name throughout the scene, consolidates them into a single material, and reassigns all affected objects. This is particularly useful after CAD imports, which often bring in multiple copies of identically named materials.

![](<Consolidate Duplicate Materials.jpg>)

The script also populates the Compact Material Editor slots with the consolidated materials — Multi/Sub-Object materials first, then single materials, both in alphabetical and numerical order. Materials beyond the 24-slot limit will still exist in the scene but will not appear in the Material Editor.

> **Previously named:** `lmDeleteDuplicateMaterials.ms`

## How to Use

Configure whether to consolidate from a selection only and/or include hidden objects, then run the script.

All materials sharing the same name will be instanced into one, and duplicate materials will be deleted.

> **Warning:** If two materials share the same name but have different attributes, one will be deleted. Verify material names before running if this could be a concern.

> **Note:** A file reload is required for the scene materials to fully update after consolidation.
