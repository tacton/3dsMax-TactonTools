# Select UV Island

A macroscript that expands the current face selection to full UV islands within an Unwrap UVW modifier. Select one face per island and press the button — the entire island is selected.

## Installation

After running the script, add the button to a toolbar manually:

1. Go to **Customize > Customize User Interface > Toolbars**.
2. Set **Group** to `Main UI` and **Category** to `Tacton Tools`.
3. Drag **Expand Selection to the UV Island** onto a toolbar. It will appear as **Sel UV Island**.

## How to Use

**1.** Enter the **Polygon** sub-object mode of an Unwrap UVW modifier and select at least one face on each UV island you want fully selected.

![](<Select UV Island_PreSelection.jpg>)

**2.** Press **Sel UV Island**. The selection will expand to cover all faces on each UV island that had a face selected.

![](<Select UV Island_PostSelection.jpg>)
