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

try (DestroyDialog BOTurnOff2SidedMeshes) catch()

rollout BOTurnOff2SidedMeshes "Turn Off 2-Sided Mesh" width:230 height:230
(
		-- -----------------------------
	-- UI Header
	-- -----------------------------
	dotNetControl lblTitle "Label" pos:[2,2] width:226 height:30
  -- Add a label with instructions
    label instructions "This script allows you to change the 2-Sided Mesh property of a selected Body Object. To use it, select a single Body Object in the scene and click the 'Two Sided Off' button." align:#left offset:[5,1] width:200 height:65  
	label warning "If the triangle total is not changing in the on screen statistics, which can happen if the Body Object was copied, save and reload and the triangle count should be correct." align:#left offset:[5,1] width:200 height:80
	-- Add a button to the rollout
    button runButton "Two Sided Off" width:140 height:30 pos:[45,190]
    
    -- Define what happens when the button is clicked
    on runButton pressed do
    (
        -- Check if more than one object is selected
        if selection.count != 1 then
		(
            messageBox "Please select only one Body Object at a time when running this script."
        )
		else
		(
            -- Get the selected object
            selectedObj = selection[1]

            -- Check if the object is a Body_Object
            if classOf selectedObj != Body_Object then
			(
                messageBox "The selected object must be a Body Object, with all faces or elements selected."
            )
			else
			(
                -- Change the TwoSidedMeshesOP property
                selectedObj.TwoSidedMeshesOP = false

                -- Force a redraw of all views
                redrawViews()
            )
        )
    )
	
	fn defColor r g b = (dotNetClass "System.Drawing.Color").FromArgb r g b
	fn defFontB fName fSize = (dotNetObject "System.Drawing.Font" fName fSize ((dotNetClass "System.Drawing.FontStyle").bold))
	
	on BOTurnOff2SidedMeshes open do
	(
		lblTitle.text = "Tacton Tools"
		lblTitle.textAlign = lblTitle.textAlign.MiddleCenter
		lblTitle.font = defFontB "Verdana" 10
		lblTitle.backColor = defColor 77 77 240
		lblTitle.foreColor = defColor 255 255 255
	)

)

-- Create a new dialog to contain the rollout
createDialog BOTurnOff2SidedMeshes
SetDialogPos BOTurnOff2SidedMeshes [300, 150]

-- setCommandPanelTaskMode #modify
-- subObjectLevel = 3
-- max select all