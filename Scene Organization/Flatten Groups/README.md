# Flatten Groups

Ungroups all sub-groups within a selected group while keeping their objects as part of that top-level group. Reducing the number of nested groups improves performance in large scenes, as each group is its own object in 3ds Max. The top-level group can still be part of another group or linked to a helper.

> **Note:** There are known bugs in this script. It will not always remove all sub-groups, but it will reliably remove groups belonging to orphan objects in the hierarchy — cases where each individual object has its own group wrapper.

## How to Use

**1.** Select the group(s) you want to flatten.

![](<Flatten Groups_GroupsSelected.jpg>)

**2.** Press **Flatten Groups**. All sub-groups within the selection will be ungrouped, with their objects moved up into the top-level group.

![](<Flatten Groups_GroupsFlattened.jpg>)

## Ungroup Orphans

When **Ungroup Orphans** is enabled, any selected group that contains only a single object will be ungrouped entirely, and that object will be attached to any parent group it still belongs to.
