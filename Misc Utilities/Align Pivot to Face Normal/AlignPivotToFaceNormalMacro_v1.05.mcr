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

-- 18/09/2004: added Editable Mesh to maxscript
-- 12/08/2026: v1.05 added install-notification dialog (shown when the .mcr is dragged in / evaluated)

macroScript AlignPivotToFaceNormalMacro
category:"Tacton Tools"
toolTip:"Align Pivot to Selected Face's Normal"
buttonText:"Align Pivot to Face"

(
    -- Function to set the transformation of an object's pivot without affecting geometry
	fn setTM obj tm =
	(
		local newOffset = obj.objectTransform * (inverse tm) -- Calculate the offset in the target TM space
		obj.objectOffsetScale = newOffset.scale
		obj.objectOffsetRot = newOffset.rotationPart
		obj.objectOffsetPos = newOffset.pos
		obj.transform = tm
	)

	-- Main function to set pivot based on object type
	fn FB_SubobjPivot =
	(
		if selection.count == 1 then
		(
			obj = selection[1]
			
			-- Check if the object is Editable Poly or Editable Mesh
			if classOf obj == Editable_Poly then
			(
				-- Editable Poly Logic
				max modify mode
				currModifier = modPanel.getCurrentObject()

				Subobjmode = (getSelectionLevel obj)
				if Subobjmode != #face then
				(
					messageBox "Please select one or more faces first."
					return false
				)

				initShowEndResult = showEndResult
				NurmsPreview = undefined

				global FBpivot_previousCoordsys = getRefCoordSys()
				global FBpivot_previousCoordcenter = getCoordCenter()

				with redraw off
				(
					showEndResult = false
					try
					(
						NurmsPreview = (currModifier.surfSubdivide)
						currModifier.surfSubdivide = off
					)
					catch()

					selFaces = (polyop.getFaceSelection obj as array)

					if selFaces.count == 0 then
					(
						messageBox "No faces selected. Please select one or more faces."
						return false
					)

					local combinedPos = [0,0,0]
					local combinedNormal = [0,0,0]

					for currFace in selFaces do
					(
						combinedPos += polyop.getFaceCenter obj currFace
						combinedNormal += polyop.getFaceNormal obj currFace
					)
					pos = combinedPos / selFaces.count
					dir = normalize (combinedNormal / selFaces.count)

					connectedEdge = (polyop.getEdgesUsingFace obj selFaces[1] as Array)[1]
					connectedVerts = (polyop.getVertsUsingEdge obj connectedEdge) as array
					vert1pos = polyop.getVert obj connectedVerts[1]
					vert2pos = polyop.getVert obj connectedVerts[2]
					dirUp = normalize (vert2pos - vert1pos)

					p = point()
					p.dir = dir
					p.pos = pos

					if dirUp != undefined then
					(
						dirUp = ((dot dir dirUp) * -dir + dirUp)
						p.transform = orthogonalize (matrix3 (cross dirUp dir) dirUp dir pos)
					)

					WorkingPivot.editMode = true
					WorkingPivot.setTM p.transform
					WorkingPivot.UseMode = true
					setTM obj p.transform

					showEndResult = initShowEndResult
					try
					(
						currModifier.surfSubdivide = NurmsPreview
					)
					catch()

					delete p
					modPanel.setCurrentObject currModifier node:obj
					update obj
				)
			)
			else if classOf obj == Editable_mesh then
			(
				-- Editable Mesh Logic
				max modify mode
				currModifier = modPanel.getCurrentObject()

				Subobjmode = (getSelectionLevel obj)
				if Subobjmode != #face then
				(
					messageBox "Please select one or more faces first."
					return false
				)

				selFaces = undefined
				local faceSelBitArray = getFaceSelection obj

				if faceSelBitArray != undefined then
				(
					selFaces = (for i = 1 to faceSelBitArray.count where faceSelBitArray[i] == true collect i)
				)

				if selFaces.count == 0 then
				(
					messageBox "No faces selected. Please select one or more faces."
					return false
				)

				local combinedPos = [0,0,0]
				local combinedNormal = [0,0,0]

				for currFace in selFaces do
				(
					faceCenter = meshop.getFaceCenter obj currFace
					faceNormals = meshop.getFaceRNormals obj currFace
					
					local avgNormal = [0,0,0]
					for n in faceNormals do
					(
						avgNormal += n
					)
					avgNormal /= faceNormals.count
					
					combinedPos += faceCenter
					combinedNormal += avgNormal
				)

				pos = combinedPos / selFaces.count
				dir = normalize (combinedNormal / selFaces.count)

				connectedEdge = (meshop.getEdgesUsingFace obj selFaces[1] as Array)[1]
				connectedVerts = (meshop.getVertsUsingEdge obj connectedEdge) as array
				vert1pos = getVert obj connectedVerts[1]
				vert2pos = getVert obj connectedVerts[2]
				dirUp = normalize (vert2pos - vert1pos)

				p = point()
				p.dir = dir
				p.pos = pos

				if dirUp != undefined then
				(
					dirUp = ((dot dir dirUp) * -dir + dirUp)
					p.transform = orthogonalize (matrix3 (cross dirUp dir) dirUp dir pos)
				)

				WorkingPivot.editMode = true
				WorkingPivot.setTM p.transform
				WorkingPivot.UseMode = true
				setTM obj p.transform

				delete p
				update obj
			)
			else
			(
				messageBox "Selected object is neither Editable Poly nor Editable Mesh."
				return false
			)
		)
		else
		(
			messageBox "Please select an object."
			return false
		)
	)

	undo "FB Sub-Obj Pivot" on
	(
		if (undefined == getRefCoordSys() and (maxOps.pivotMode != #pivotOnly)) then
		(
			try
			(
				if (FBpivot_previousCoordsys != undefined) then
				(
					setrefCoordSys FBpivot_previousCoordsys
					setCoordCenter FBpivot_previousCoordcenter
				)
				else
				(
					toolMode.coordsys #view
					setCoordCenter FBpivot_previousCoordcenter
				)
				print "Reference Coord system reset"
			) 
			catch
			(
				print "FAILED to reset reference coordinate system"
			)
		)
		else
		(
			if selection.count == 1 then
			(
				if FB_SubobjPivot() == false then
				(
					print "FAILED to align pivot to sub-obj"
				)
				else print "FB Sub-obj Pivot successful"
			)
			else if selection.count > 1 then
			(
				print "Aborted: Too many objects selected, FB Sub-obj Pivot supports only 1 object at a time"
			)
		)
	)

)


-------------------------------------------------------------------------------
-- INSTALL NOTIFICATION
-- Runs only when this .mcr file is evaluated (dragged into a viewport or run
-- from the Scripting menu). Only the macroscript block above is persisted to
-- the usermacros folder, so this notice does NOT re-appear on every 3ds Max
-- startup -- it shows once, at install time.
-------------------------------------------------------------------------------
(
	rollout alignPivotInstallNotice "Macro Installed"
	(
		dotNetControl lblHdr "Label" pos:[4,4] width:312 height:28

		label lbl_done  "The 'Align Pivot to Face' macroscript was installed." align:#center offset:[0,8]
		label lbl_done2 "If it is not yet on a toolbar, you will need to add it:" align:#center offset:[0,2]

		group "Customize User Interface"
		(
			label lbl_step1 "1.   Customize  >  Customize User Interface" align:#left offset:[4,2]
			label lbl_step2 "2.   Open the 'Toolbars' tab" align:#left offset:[4,2]
			label lbl_step3 "3.   Set the Category to 'Tacton Tools'" align:#left offset:[4,2]
			label lbl_step4 "4.   Drag 'Align Pivot to Face' onto any toolbar" align:#left offset:[4,2]
		)

		button btn_close "Close" width:90 height:24 offset:[0,10]

		fn niceColor r g b = (dotNetClass "System.Drawing.Color").FromArgb r g b

		on alignPivotInstallNotice open do
		(
			lblHdr.text = "Align Pivot to Face Normal  v1.05"
			lblHdr.textAlign = lblHdr.textAlign.MiddleCenter
			lblHdr.font = dotNetObject "System.Drawing.Font" "Verdana" 10 ((dotNetClass "System.Drawing.FontStyle").bold)
			lblHdr.backColor = niceColor 77 77 240
			lblHdr.foreColor = niceColor 255 255 255
		)

		on btn_close pressed do ( DestroyDialog alignPivotInstallNotice )
	)

	try ( DestroyDialog alignPivotInstallNotice ) catch ()
	createDialog alignPivotInstallNotice width:320
)
