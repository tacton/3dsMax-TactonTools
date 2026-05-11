# Combine Materials

Merges the materials from a selected object's Multi/Sub-Object material into a master Multi/Sub-Object material, then reassigns it to the object with corrected material IDs.

![](<Combine Materials.jpg>)

> **Note:** This script is in **BETA** and may not be updated. A known issue exists where empty ID slots in either the Master or Donor Multi/Sub-Object materials may cause materials to be added in the wrong order and IDs to be reassigned incorrectly. This should not be an issue if used immediately after an import.

## Combine Mats & Assign

Ensure your **Master Multi/Sub-Object material** is in slot **#1** of the Compact Material Editor, or set the **Master Material Position** spinner to the correct slot number (slots are ordered 6 left to right, 4 top to bottom, for a total of 24 possible slots).

Select the object you want to apply the Master material to and press **Combine Mats & Assign**. The script will:
1. Analyze the selected object's current Multi/Sub-Object material.
2. Add any materials not already present in the Master material (the Donor materials).
3. Reassign the Master material to the object.
4. Reorder the material IDs on the object's faces so that the correct materials remain applied.

## Rename by Similar Material

Currently works with **Physical Materials** only. Select the object(s) whose materials you want compared against the Multi/Sub-Object material in slot #1 of the Material Editor. If matching attributes are found in **Base Color**, **Roughness**, and **Metalness**, the material will take on the matching name from the Master material.

This can be useful when materials are imported with default or randomly generated names, which occurs with some CAD imports.

## Select Instances

Selects all instances of the currently selected object to confirm that the same material is applied across all of them.
