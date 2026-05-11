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

macroScript CAD_Detach
	buttonText:"CAD Detach"
	tooltip:"Detach Element or Explode CAD Objects"
	category:"Tacton Tools"
(
	fn explodeObjectElements =
	(
		undo off
		suspendEditing()
		cFaceSelection= #()

		for cObj in (getcurrentselection()) do
		(
			if (cObj != undefined) do
			(
			-- 	polyop.getElementsUsingFace <Poly poly> <facelist> fence:<fence_facelist>

				if (classof cObj) == editable_poly  do
				(
					cFaceSelection = polyop.getElementsUsingFace cObj 1

					while (((-cFaceSelection) as Array).count) != 0 do
					(
						cFaceSelection = polyop.getElementsUsingFace cObj 1

						maxOps.CloneNodes cObj cloneType: #copy newNodes:&theNode

						polyop.deleteFaces cObj (cFaceSelection)

					-- 	max select invert
						polyop.deleteFaces theNode[1] (-cFaceSelection)
						clearUndoBuffer()
					)

				)

				if (classof cObj) == Editable_mesh  do
				(


					cFaceSelection = meshop.getElementsUsingFace cObj 1

					while (((-cFaceSelection) as Array).count) != 0 do
					(
						cFaceSelection = meshop.getElementsUsingFace cObj 1

						maxOps.CloneNodes cObj cloneType: #copy newNodes:&theNode

						meshop.deleteFaces cObj (cFaceSelection)

					-- 	max select invert
						meshop.deleteFaces theNode[1] (-cFaceSelection)
						clearUndoBuffer()
					)

				)
			)
		)
		resumeEditing()
	)


	fn detachCADfromSelection =
	(
		undo off
		suspendEditing()
		cFaceSelection= #()

		if (getcurrentselection()).count != 0 do
		(
			cObj = (getcurrentselection())[1]


			if subObjectLevel == 4 do
			(
				cObj.EditablePoly.ConvertSelection #Element #Face
				subObjectLevel == 3
			)


			if (classof cObj) == editable_poly  do
			(
				if ((polyop.getFaceSelection $) as Array).count != 0 do
				(
					cFaceSelection = (polyop.getFaceSelection cObj)

					maxOps.CloneNodes cObj cloneType: #copy newNodes:&theNode

					polyop.deleteFaces cObj (cFaceSelection)
				-- 	max select invert
					polyop.deleteFaces theNode[1] (-cFaceSelection)
					clearUndoBuffer()
				)
			)

			if (classof cObj) == Editable_mesh  do
			(
				cFaceSelection = (getFaceSelection cObj)

				maxOps.CloneNodes cObj cloneType: #copy newNodes:&theNode



				meshop.deleteFaces cObj (cFaceSelection)
			-- 	max select invert
				meshop.deleteFaces theNode[1] (-cFaceSelection)
				clearUndoBuffer()
			)
		)
		resumeEditing()
	)

	fn lmDetachCADfromSelectionFunction =
	(
		try
		(
			detachCADfromSelection()
		)
		catch
		(
			Messagebox("An unknown error has occured")
		)
	)

	fn lmDetachCADExplodeElementsFunction =
	(
		try
		(
			explodeObjectElements()
		)
		catch
		(
			Messagebox("An unknown error has occured")
		)
	)


	try (DestroyDialog lmCADDetach) catch()
	versionLMCAD = "CAD Detach Tools V0.1"

	rollout lmCADDetach versionLMCAD width:240
	(
		-- -----------------------------
		-- UI Header
		-- -----------------------------
		dotNetControl lblTitle "Label" pos:[2,2] width:236 height:30

		group "Detach Tools"
		(
			button btn_detach "Detach CAD from Selection" width:200
				tooltip: "Detach the selected face/element selection into a separate object."
			button btn_explode "Explode Elements" width:200
				tooltip: "Explode all elements of each selected object into separate objects."
		)

		on btn_detach pressed do
		(
			lmDetachCADfromSelectionFunction()
		)

		on btn_explode pressed do
		(
			lmDetachCADExplodeElementsFunction()
		)

		fn defColor r g b = (dotNetClass "System.Drawing.Color").FromArgb r g b
		fn defFontB fName fSize = (dotNetObject "System.Drawing.Font" fName fSize ((dotNetClass "System.Drawing.FontStyle").bold))

		on lmCADDetach open do
		(
			lblTitle.text = "Tacton Tools"
			lblTitle.textAlign = lblTitle.textAlign.MiddleCenter
			lblTitle.font = defFontB "Verdana" 10
			lblTitle.backColor = defColor 77 77 240
			lblTitle.foreColor = defColor 255 255 255
		)
	)
	createdialog lmCADDetach
)
