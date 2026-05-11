# Clean Object Names

Renames objects with generic or randomly generated names — common after CAD imports — by inheriting the name of the group they belong to.

## Overview

CAD packages often import objects with generic names such as `PARTBODY` or `SOLID`, or in some cases the object names fail to import entirely and are replaced with randomly generated strings. In either case, the object is typically part of a group that carries the correct name. This script uses that group name to rename the objects within it.

## How to Use

**1.** Select the objects you want the script to check.

![](<Clean Object Names_ObjSelection.jpg>)

**2.** Press **Clean Names**. The script will rename any object that matches a name in the default names list, or whose name meets or exceeds the **Length Threshold**, using the group name with a trailing `#` suffix (e.g. `EngineBlock_0001`). The suffix counter increments by 1 for each renamed object, resets to `0001` after `9999`, or can be manually reset with **Reset Trailing # Counter**.

![](<Clean Object Names_CleanNames.jpg>)

> **Note:** Only objects that belong to a group can be renamed, as the new name is taken from the group. Do not ungroup anything until renaming is complete.

## Default Names List

The script checks object names against the following built-in list:

```
global defaultNames = #("MAINBODY", "FILLET", "CHAMFER", "PARTBODY", "SOLID", "NONE", "BREP", "QUILT", "REVOLVE", "BODY", "Extrude", "MANIFOLD", "STITCH_RESULT", "MATERIAL", "CirPattern")
```

To add names, edit the `defaultNames` global variable in the script directly. Each entry must be in quotes and separated by a comma.
