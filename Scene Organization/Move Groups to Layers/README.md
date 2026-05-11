# Move Groups to Layers

Moves selected groups to layers named after each group, making it easy to organize large scenes into a clean layer structure.

![](<Move Groups to Layers_PreSelection.jpg>)

## How to Use

**1.** Select the group(s) you want to move to layers. If there are many groups, it is recommended to process a handful at a time.

![](<Move Groups to Layers_GroupsSelected.jpg>)

**2.** Configure the options below to suit your needs, then press **Process**. Each selected group will be moved to a layer named after it. If a layer with that name already exists, the group will be moved into it without creating a duplicate.

![](<Move Groups to Layers_LayersCreated_Unsorted.jpg>)

When **Create Layer Within Active Layer** is checked, new layers are created as sub-layers of the currently active layer rather than at the top level.

![](<Move Groups to Layers_GroupsSelected_CreateLayerWithinActiveLayerChecked.jpg>)

![](<Move Groups to Layers_LayersCreated_Sorted.jpg>)

Once moved, layers can be renamed as needed.

## Options

### Group Options

| Option | Default | Description |
|---|---|---|
| Move Groups to Layer | On | Moves each selected group to a layer named after it. Uncheck if you only want to process hidden objects within the group's current layer. |
| Hide Created Groups | Off | Hides newly created layers after groups are moved to them. Useful when processing many groups — hidden layers indicate which ones are done. |
| Create Layer Within Active Layer | Off | Creates new layers as sub-layers of the currently active layer. Useful when organizing large assemblies into parent layers. |
| Custom Layer Name | Off | When enabled, all selected groups are moved to a single layer using the name entered in the text field. |

### Hidden Object Handling

| Option | Description |
|---|---|
| Delete Hidden | Deletes any hidden objects within the group. |
| Detach Hidden | Leaves hidden objects in their current layer; they are not moved with the group. |
| Keep Hidden in Group | Hidden objects remain hidden and move with the group. Not recommended — certain actions may unexpectedly unhide them. |
| Detach Hidden, Move with Group | Hidden objects are detached from the group but still moved to the new layer. **Default.** Least destructive — allows hidden objects to be reviewed and manually deleted if not needed. |

### Ungroup Top Group

> **Use with caution.** Intended for very large imports where selecting a group takes an extended amount of time. Removes the topmost group in the currently active layer — if more than one group exists in that layer, all will be affected. Only use this when the groups within a group are the assemblies that need their own individual layers.
