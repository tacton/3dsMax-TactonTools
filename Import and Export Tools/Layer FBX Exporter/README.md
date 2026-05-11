# Layer FBX Exporter

Exports individual layers as separate FBX files with a single operation.

![](<Layer FBX Exporter.jpg>)

## How to Use

**1.** Click **Set Export Directory** to choose a destination folder. The selected path will appear below the button once set.

**2.** Configure the export options:

| Option | Default | Description |
|---|---|---|
| Use the FBX Export Dialog | Off | Opens the FBX export dialog before each export. Turn on if you are unsure whether FBX settings have been previously configured correctly — the exporter otherwise recalls the last used settings. |
| Exclude Hidden Objects | On | Excludes hidden objects from layers that are currently on. Layers that are turned off will not be exported regardless of this setting. |
| Turn off NO_ layers | On | Any layer beginning with `NO_` (e.g. `NO_Drone_Body`) will be turned off before exporting begins, causing it to be ignored by the exporter. |
| sRGB Encode Colors | Off | Converts material color gamma on export. As of 3ds Max 2024, the Color Management System exports colors at Gamma 1.0 even when working in Gamma 2.2, causing colors to appear too dark in other DCC applications. Enable this to correct that. |

**3.** Press **Export Layers**. The script will iterate through each visible layer and export an FBX file named after the layer to the selected directory.

> **Note:** Layers may be nested within other layers. If a layer contains no geometry but has sub-layers, the empty parent layer will not be exported — but its sub-layers will be.
