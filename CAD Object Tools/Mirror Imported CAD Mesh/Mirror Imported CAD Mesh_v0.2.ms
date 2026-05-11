/*
MIT License

Copyright (c) 2026 Tacton Systems

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

try (DestroyDialog mirrorCADObject)catch()
versionMCO = "Mirror Imported CAD Mesh V0.2"

-- Create a global array to store the names of the objects that were originally Editable Poly
global originalEditablePolyObjects = #()

rollout mirrorCADObject versionMCO width:230
(
	-- -----------------------------
	-- UI Header
	-- -----------------------------
	dotNetControl lblTitle "Label" pos:[2,2] width:226 height:30
    group "Symmetry Stuff"(
	--button btn_delete "Delete First Element"
    button btn_symmetry "Apply Symmetry" width: 120
		tooltip: "Apply a Symmetry Modifier if one has not been applied yet."
    radioButtons rb_axis "Symmetry Axis" labels:#("X", "Y", "Z")
		tooltip: "The local axis the object should be mirrored on."
	--checkbox chk_flip "Flip Axis"
	)
	group""
	(
		checkbox chk_flipUVW "Mirror UVs" checked: true
		button btn_commit "Commit Mirror"  width: 120
	)
	
	
    -- Define a function to delete faces
    fn deleteFaces obj =
    (
        if isKindOf obj Editable_Poly then
        (
            totalFaces = polyOp.getNumFaces obj
            halfFaces = floor (totalFaces / 2)
            format "Total Faces: %\n" totalFaces
            format "Half Faces: %\n" halfFaces
            faceSel = #{}
            for i = 1 to halfFaces do
            (
                faceSel[i] = true
            )
            polyOp.deleteFaces obj faceSel
            update obj
            --messagebox ("Deleted the first half of the faces of the Editable Poly: " + obj.name)
        )
        else if isKindOf obj Editable_Mesh then
        (
            totalFaces = getNumFaces obj
            halfFaces = floor (totalFaces / 2)
            format "Total Faces: %\n" totalFaces
            format "Half Faces: %\n" halfFaces
            faceSel = #{}
            for i = 1 to halfFaces do
            (
                faceSel[i] = true
            )
            setFaceSelection obj faceSel
            subobjectLevel = 4
            actionMan.executeAction 0 "40020"
            subobjectLevel = 0

            update obj
            --messagebox ("Selected the first half of the faces of the Editable Mesh: " + obj.name)
        )
        else
        (
            messagebox ("Please select an Editable Poly or Editable Mesh object. The current object, " + obj.name + ", is not an Editable Poly or Editable Mesh.")
        )
    )
    -- Define a function to update the Symmetry modifier
    fn updateSymmetry obj =
    (
        if classOf (modPanel.getCurrentObject()) == Symmetry then
        (
            mod = modPanel.getCurrentObject()
            case rb_axis.state of -- Set the symmetry axis based on the radio button state
            (
                1: mod.axis = 0 -- X axis
                2: mod.axis = 1 -- Y axis
                3: mod.axis = 2 -- Z axis
            )
			mod.slice = 0
			mod.weld = 0

            --mod.flip = chk_flip.state -- Set the flip property based on the checkbox state
        )
    )	
/*
    on btn_delete pressed do
    (
        if selection.count != 0 then
        (
            objs = for obj in selection collect obj
            deselect $ -- Deselect the currently selected object
            for obj in objs do
            (
                select obj -- Select the current object
                deleteFaces obj -- Call the deleteFaces function
            )
        )
        else
        (
            messagebox "Please select an object."
        )
    )
*/
	
	on rb_axis changed state do
    (
        if selection.count != 0 then
        (
            obj = selection[1] -- Get the first object in the selection
            updateSymmetry obj -- Call the updateSymmetry function
        )
    )

    on chk_flip changed state do
    (
        if selection.count != 0 then
        (
            obj = selection[1] -- Get the first object in the selection
            updateSymmetry obj -- Call the updateSymmetry function
        )
    )
	
    on btn_symmetry pressed do
    (
        if selection.count != 0 then
        (
            obj = selection[1] -- Get the first object in the selection
			
			-- If the object was originally an Editable Poly, store its name in the array
			if isKindOf obj Editable_Poly then
			(
				append originalEditablePolyObjects obj.name
			)
			
			convertToMesh obj
            mod = Symmetry() -- Create a new Symmetry modifier
            case rb_axis.state of -- Set the symmetry axis based on the radio button state
            (
                1: mod.axis = 0 -- X axis
                2: mod.axis = 1 -- Y axis
                3: mod.axis = 2 -- Z axis
            )
			--mod.flip = chk_flip.state -- Set the flip property based on the checkbox state
			mod.slice = 0
			mod.weld = 0
            addModifier obj mod -- Add the Symmetry modifier to the object
            --messagebox ("Applied a Symmetry modifier to the object: " + obj.name)
            --convertToMesh obj
			--deleteFaces obj -- Call the deleteFaces function
        )
        else
        (
            messagebox "Please select an object."
        )
    )
	on btn_commit pressed do
	(
		if selection.count != 0 then
		(
			obj = selection[1] -- Get the first object in the selection
			-- Check if the object has a Symmetry modifier applied to it
			if findItem (for m in obj.modifiers collect classOf m) Symmetry != 0 then
			(
				deselect $
				select obj
				convertToMesh obj -- Convert the object to an Editable Mesh
				deleteFaces obj -- Call the deleteFaces function

				-- If the chk_flipUVW checkbox is checked, apply a UVW XForm modifier with U_Tile set to -1 and the U_Offset set to 1.0
				if chk_flipUVW.state then
				(
					uvwXformMod = UVW_XForm() -- Create a new UVW XForm modifier
					uvwXformMod.U_Tile = -1 -- Set U_Tile to -1
					uvwXformMod.U_Offset = 1.0 -- Set U_Offset to 1.0
					addModifier obj uvwXformMod -- Add the UVW XForm modifier to the object
					convertToMesh obj
				)

				-- If the name of the object is in the array, convert it back to Editable Poly and remove the name from the array
				if findItem originalEditablePolyObjects obj.name != 0 then
				(
					convertToPoly obj
					deleteItem originalEditablePolyObjects (findItem originalEditablePolyObjects obj.name)
				)
			)
			else
			(
				messagebox "Please select an object with a Symmetry modifier applied."
			)
		)
		else
		(
			messagebox "Please select an object."
		)
	)
	fn defColor r g b = (dotNetClass "System.Drawing.Color").FromArgb r g b
	fn defFontB fName fSize = (dotNetObject "System.Drawing.Font" fName fSize ((dotNetClass "System.Drawing.FontStyle").bold))
	
	on mirrorCADObject open do
	(
		lblTitle.text = "Tacton Tools"
		lblTitle.textAlign = lblTitle.textAlign.MiddleCenter
		lblTitle.font = defFontB "Verdana" 10
		lblTitle.backColor = defColor 77 77 240
		lblTitle.foreColor = defColor 255 255 255
	)

)
createdialog mirrorCADObject
