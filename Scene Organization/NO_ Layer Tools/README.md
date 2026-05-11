# NO_ Layer Tools

A set of utilities for managing layers prefixed with `NO_`. Layers with this prefix can be toggled on and off without deleting their contents, making them useful for reference objects, assembly parts that are not needed on their own, or any objects you want to exclude temporarily. The `NO_` prefix is also recognized by [Layer FBX Exporter](../../Import%20and%20Export%20Tools/Layer%20FBX%20Exporter), which will skip those layers during export.

## Functions

### Turn Off NO_ Layers

Turns off all layers with a `NO_` prefix.

![](<NO_ Layer Functions_NO_ Layers ON.jpg>)

![](<NO_ Layer Functions_NO_ Layers OFF.jpg>)

### Turn On NO_ Layers

Turns on all layers with a `NO_` prefix.

### Add NO_ to Marked

Adds the `NO_` prefix to any layer whose **Render** property is turned off (the teapot icon in the Layer Manager).

![](<NO_ Layer Functions_Marked Layer.jpg>)

![](<NO_ Layer Functions_Marked Layer NO_.jpg>)

### Add NO_ to Active

Adds the `NO_` prefix to the currently active layer.

![](<NO_ Layer Functions_Active Layer.jpg>)

![](<NO_ Layer Functions_Active Layer NO_.jpg>)

### Select Visible NO_ Layers

Selects all objects within `NO_` layers that are currently turned on.
