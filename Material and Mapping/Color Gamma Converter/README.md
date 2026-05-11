# Color Gamma Converter

A tool for converting material color gamma values in 3ds Max 2024 and later, which introduced a new Color Management system.

Its main purpose is to convert from the specified gamma to 1.0 gamma (linear space), or vice-versa. This may be required when exporting to FBX for other DCC software or interactive engines where correct RGB values need to be preserved.

![](<Color Gamma Converter.jpg>)

## UI Areas

### 1. Current Mode

Displays the Color Management color space currently set in **Rendering > Color Management Settings > Color Management Mode** at the time the script is launched. Use **Set Gamma Workflow** or **Set Linear Workflow** to switch between the two — a prompt will appear offering to apply the gamma change to all scene materials.

Gamma 2.2 is the default. The **Gamma** spinner can be adjusted for other workflows.

> **Note:** If the current mode is set to something other than Gamma 2.2 or Linear when the script launches, you will be able to set it to one of those. Once set, you can only toggle between the two.

### 2. Manual Color Conversion

Converts the RGB values on the **Base Color/Diffuse** and **Emission/Self-Illumination** channels of the specified materials. Currently works only with **Physical** and **Standard (Legacy)** materials.

Select which materials to convert:

| Option | Description |
|---|---|
| 1. Selected Objects Mats | Converts materials applied to objects in the current selection. |
| 2. Visible Objects Mats | Converts materials applied to visible objects in the scene. |
| 3. All Used Mats | Converts all materials applied to any object in the scene. |
| 4. Selected Mats in Editor | Converts the material currently selected in the Compact Material Editor. Does not work with the Slate Material Editor. |
| 5. All Mats in Editor | Converts all materials in the Compact Material Editor slots. |
| 6. All Used + Editor Mats | Converts all materials applied to objects in the scene plus all materials in the Compact Material Editor slots. If materials exist in the Slate Material Editor node view but are not assigned to an object, instance them to the Sample Slots first so they will be included. |

Press **Gamma TO Linear (1.0)** or **Linear (1.0) TO Gamma** to perform the conversion. Use **Undo - Rollback Previous Colors** to revert.

### 3. Color Converter

A utility to visually convert colors between gamma and linear space. Changing a value in any spinner will update both sides simultaneously, allowing you to experiment with given color values — such as client brand colors — to determine whether they are Linear or Gamma Corrected values in 3ds Max.

> **Note:** There is a known bug in 3ds Max where clicking the color swatch may display values that differ from those shown in the Color Converter. Always double-check the **Hex #** field and update it manually if necessary.
