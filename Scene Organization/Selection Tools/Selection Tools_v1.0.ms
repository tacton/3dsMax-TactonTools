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

/*
Selection Tools
24-07-2025 - V0.5 Inital BETA release.
30-01-2026 - V0.8 Bug fixes and speed improvements for Add Instances to Sel
12-02_2026 - V1.0 Added Sel By Material, and checkbox to open groups of the selection. This allows the selection of the objects without selecting the
				closed groups they belong to.
*/


try (DestroyDialog selectionToolsRollout) catch()

versionST = "Selection Tools v1.0"


function openGroups mySelection = 
(
	--loop into selected object
	for obj2 = mySelection do
	(
		--to find group end open it
		if isGroupHead obj2 then setGroupOpen obj2 true
	)
)

fn removeHidden =
(
	local visibleSelection = for obj in selection where (isValidNode obj and (obj.isHidden == false)) collect obj
	select visibleSelection
)


fn CalculateVolume obj =
(
	try
	(
		local volume = 0.0
		local theMesh = snapshotasmesh obj
		local numFaces = theMesh.numfaces

		for i = 1 to numFaces do
		(
			local f = getFace theMesh i
			local v0 = getVert theMesh f.x
			local v1 = getVert theMesh f.y
			local v2 = getVert theMesh f.z
			local dV = dot (cross (v1 - v0) (v2 - v0)) v0
			volume += dV
		)

		delete theMesh
		abs (volume / 6)
	)
	catch (0)
)

-- FIX: don't rely on rollout-local includeHidden; pass it in as a parameter
fn addInstances2Sel sourceNodes includeHiddenFlag:false =
(
	local result = #()

	for n in sourceNodes where isValidNode n do
	(
		local instances = #()
		InstanceMgr.getInstances n &instances

		for inst in instances where isValidNode inst do
		(
			if (includeHiddenFlag == true) or (inst.isHidden == false) then
			(
				if (findItem result inst) == 0 do append result inst
			)
		)
	)

	select result
	result
)


rollout selectionToolsRollout versionST 
(
	local buttonWidth = 110
	local includeHidden = false
	dotNetControl lblTitle "Label" pos:[2,2] width:276 height:30 -- Add Tacton Tools title block
	
	group "Selection Options"
	(
		checkbox chkIncludeHidden "Include Hidden" align:#left offset:[6,0] across: 2
			tooltip: "Includes hidden objects when selection buttons are pressed."
		checkbox chkKeepSelection "Keep Current Selection" align:#right offset:[6,0] 
			tooltip: "Keeps the currently selected objects in the selection when adding more to the selection from in the 'Select by Object' group."
		checkbox chkOpenGroups "Open Groups of Sel" align:#left offset:[6,0] checked:true
			tooltip: "This will open up the groups of a selection so only the objected wanted to be selected, will be. When off it will select the group that a selected object is apart of if the group is closed."
	)
	
	group "Selection by Object"
	(
		button btnAddInstances "Add Instances to Sel" width:buttonWidth height:20 align:#center across:2 offset:[0,0]
			tooltip: "Adds any instances that belong to any object in the selection."
		button btnRemInstances "Remove Instances" width:buttonWidth height:20 align:#center
			tooltip: "Removes instances selection, keeping one of each selected."
		
		button btnSelEditablePoly "Sel Editable Poly" width:buttonWidth height:20 align:#center across: 2
			tooltip: "Select Editable Poly objects."
		button btnSelEditableMesh "Sel Editable Mesh" width:buttonWidth height:20 align:#center
			tooltip: "Select Editable Mesh objects."
		
		button btnSelEditableSpline "Sel Spline" width:buttonWidth height:20 align:#center across: 2
			tooltip: "Select Spline objects, includes Line, Spline Shape, and Editable Spline"
		button btnRemSplines "Remove Splines"  width:buttonWidth height:20 align:#center
			tooltip: "Removes splines from selection."
		
		button btnSelHelper "Sel Helper" width:buttonWidth height:20 align:#center across: 2
			tooltip: "Select Editable Mesh objects."
		button btnRemHelpers "Remove Helpers"  width:buttonWidth height:20 align:#center offset:[0,0]
			tooltip: "Removes helpers from selection."
	)

	on chkIncludeHidden changed state do includeHidden = state
	
	on btnAddInstances pressed do undo on
	(
		if selection.count == 0 then
		(
			messageBox "Select at least one object first."
		)
		else
		(
			local OGselection = selection as array

			
			-- FIX: pass includeHidden into the function
			addInstances2Sel OGselection includeHiddenFlag:includeHidden
			
			-- Optionally filter hidden out first if includeHidden is off
			if not includeHidden then
			(
				removeHidden()
			)
			if chkOpenGroups.state do (
			-- FIX: $selection is not correct here; use actual selection array
			actionMan.executeAction 0 "63561"
			--openGroups (selection as array)
			)

			-- Restore original selection (so instances are based on what user had)
			select OGselection

			-- FIX: pass includeHidden into the function
			addInstances2Sel OGselection includeHiddenFlag:includeHidden

			-- If includeHidden is off, remove hidden again after instance expand
			if not includeHidden then
			(
				removeHidden()
			)

			redrawViews()
		)
	)

	on btnRemInstances pressed do undo on
	(
		local objs = selection as array
		local uniqueObjs = #()

		while objs.count > 0 do
		(
			local baseObj = objs[1]
			local instances = #()  -- <-- add this
			InstanceMgr.getInstances baseObj &instances
			append uniqueObjs baseObj

			-- Remove all found instances from objs *safely*
			for inst in instances do
			(
				local idx = findItem objs inst
				if idx > 0 do deleteItem objs idx
			)
		)

		select uniqueObjs
		redrawViews()
	)
	
	on btnSelEditablePoly pressed do
	(
		local objs = if includeHidden then
			(for obj in objects where classof obj == Editable_Poly collect obj)
		else
			(for obj in objects where classof obj == Editable_Poly and not obj.isHidden collect obj)

		if chkKeepSelection.state then
		(
			for obj in objs do selectMore obj
		)
		else
		(
			select objs
		)
		if chkOpenGroups.checked then
		(
			actionMan.executeAction 0 "63561"
			--openGroups (selection as array)
			select objs
		)
		redrawViews()
	)

	on btnSelEditableMesh pressed do
	(
		local objs = if includeHidden then
			(for obj in objects where classof obj == Editable_mesh collect obj)
		else
			(for obj in objects where classof obj == Editable_mesh and not obj.isHidden collect obj)

		if chkKeepSelection.state then
		(
			for obj in objs do selectMore obj
		)
		else
		(
			select objs
		)
		if chkOpenGroups.checked then
		(
			actionMan.executeAction 0 "63561"
			--openGroups (selection as array)
			select objs
		)
		redrawViews()
	)

	on btnSelEditableSpline pressed do
	(
		local validSplineClasses = #(Line, SplineShape, Editable_Spline)
		local objs = if includeHidden then
			(for obj in objects where findItem validSplineClasses (classof obj) != 0 collect obj)
		else
			(for obj in objects where findItem validSplineClasses (classof obj) != 0 and not obj.isHidden collect obj)

		if chkKeepSelection.state then
		(
			for obj in objs do selectMore obj
		)
		else
		(
			select objs
		)
		if chkOpenGroups.checked then
		(
			actionMan.executeAction 0 "63561"
			--openGroups (selection as array)
			select objs
		)
		redrawViews()
	)

	on btnRemSplines pressed do undo on
	(
		select (for obj in selection where classof obj != Line and classof obj != SplineShape collect obj)
		redrawViews()
	)

	on btnSelHelper pressed do
	(
		local objs = if includeHidden then
			(for obj in helpers where isKindOf obj Point collect obj)
		else
			(for obj in helpers where isKindOf obj Point and not obj.isHidden collect obj)

		if chkKeepSelection.state then
		(
			for obj in objs do selectMore obj
		)
		else
		(
			select objs
		)
		redrawViews()
	)

	on btnRemHelpers pressed do undo on
	(
		select (for obj in selection where not (isKindOf obj Helper or classof obj == Dummy) collect obj)
		redrawViews()
	)

	group "Selection by Wire Color or Material"
	(
		button selObjColor "Sel By Wire Color" width:buttonWidth height:20 align:#center across:2
			tooltip: "Selects objects of the same colors as the selection. Use checkbox Include Hidden to include hidden objects."
		button selHelperColor "Sel By Helper Colors" width:buttonWidth height:20 align:#center
			tooltip: "Selects helpers of the same colors as the selection."
		button btnSelByMaterial "Sel By Material" width:buttonWidth height:20 align:#center across:2
			tooltip: "Selects objects with the same material applied."
		button btnSelNoMaterial "Sel No Material" width:buttonWidth height:20 align:#center 
			tooltip: "Selects objects with no material applied."
		
	)

	on btnSelByMaterial pressed do undo on
	(
		if selection.count == 0 then
		(
			messageBox "Select at least one object first."
		)
		else
		(
			-- Collect unique, non-undefined materials from the current selection
			local mats = #()
			for n in selection where (isValidNode n) do
			(
				local m = n.material
				if (m != undefined) then
				(
					if (findItem mats m) == 0 do append mats m
				)
			)

			if mats.count == 0 then
			(
				messageBox "None of the selected objects have a material assigned."
			)
			else
			(
				local result = #()
				for o in objects where isValidNode o do
				(
					if (includeHidden == true) or (o.isHidden == false) then
					(
						if not (isKindOf o Helper or classof o == Dummy) then
						(
							if (o.material != undefined) and ((findItem mats o.material) != 0) then
							(
								append result o
							)
						)
					)
				)

				select result

				-- NEW: open any groups that are in the resulting selection
				
				if chkOpenGroups.checked then
				(
					actionMan.executeAction 0 "63561"
					--openGroups (selection as array)
					select result
				)
				

				redrawViews()
			)
		)
	)

	on btnSelNoMaterial pressed do
	(
		local validClasses = #(Editable_Mesh, Editable_Poly, Body_Object, Line, SplineShape)
		local objs = if includeHidden then
			(for obj in objects where obj.material == undefined and findItem validClasses (classof obj) != 0 collect obj)
		else
			(for obj in objects where obj.material == undefined and not obj.isHidden and findItem validClasses (classof obj) != 0 collect obj)

		select objs
		if chkOpenGroups.checked then
		(
			actionMan.executeAction 0 "63561"
			--openGroups (selection as array)
			select objs
		)
		redrawViews()
	)

	on selObjColor pressed do undo on
	(
		if selection.count > 0 then
		(
			local wc = selection[1].wireColor
			local objs = if includeHidden then
				(for o in objects where o.wireColor == wc and not (isKindOf o Helper or classof o == Dummy) collect o)
			else
				(for o in objects where o.wireColor == wc and not o.isHidden and not (isKindOf o Helper or classof o == Dummy) collect o)
			select objs
			if chkOpenGroups.checked then
			(
				actionMan.executeAction 0 "63561"
				--openGroups (selection as array)
				select objs
			)
		)
		redrawViews()
	)

	on selHelperColor pressed do undo on
	(
		if selection.count > 0 then
		(
			local wc = selection[1].wireColor
			local objs = if includeHidden then
				(for o in objects where o.wireColor == wc and (isKindOf o Helper or classof o == Dummy) collect o)
			else
				(for o in objects where o.wireColor == wc and not o.isHidden and (isKindOf o Helper or classof o == Dummy) collect o)
			select objs
			if chkOpenGroups.checked then
			(
				actionMan.executeAction 0 "63561"
				--openGroups (selection as array)
				select objs
			)
		)
		redrawViews()
	)
	
	group "Misc Selection"
	(
		button btnSelectLessTris "Select <= Tris" width:80 height:20 align:#left across:3
			tooltip:"Select mesh objects with triangle count less than or equal to the value."
		spinner spnTris "" range:[0,100000,500] type:#integer fieldwidth:60 align:#center
			tooltip:"Enter a triangle count threshold."
		button btnSelectMoreTris "Select >= Tris" width:80 height:20 align:#right
			tooltip:"Select mesh objects with triangle count greater than or equal to the value."
		
		button btnSelectLessVol "Sel <= Volume" width:80 height:20 align:#left across:3
			tooltip:"Select mesh objects with volume less than or equal to the value."
		spinner spnVolume "" range:[0,1e7,1000] type:#float fieldwidth:60 align:#center scale:10
			tooltip:"Enter a volume threshold."
		button btnSelectMoreVol "Sel >= Volume" width:80 height:20 align:#right
			tooltip:"Select mesh objects with volume greater than or equal to the value."
	)

	on btnSelectLessTris pressed do
	(
		local maxTris = spnTris.value
		local objs = if includeHidden then objects else (for o in objects where not o.isHidden collect o)
		local result = for obj in objs where (isProperty obj #numfaces and obj.numfaces <= maxTris) collect obj

		if result.count > 0 then select result
		else messageBox "No mesh objects found with fewer or equal amount of triangles."
		redrawViews()
	)

	on btnSelectMoreTris pressed do
	(
		local minTris = spnTris.value
		local objs = if includeHidden then objects else (for o in objects where not o.isHidden collect o)
		local result = for obj in objs where (isProperty obj #numfaces and obj.numfaces >= minTris) collect obj

		if result.count > 0 then select result
		else messageBox "No mesh objects found with greater or equal amount of triangles."
		redrawViews()
	)

	on btnSelectLessVol pressed do
	(
		local maxVol = spnVolume.value
		local objs = if includeHidden then objects else (for o in objects where not o.isHidden collect o)
		local result = #()

		for obj in objs where (isKindOf obj GeometryClass) do
		(
			local vol = CalculateVolume obj
			if vol <= maxVol do append result obj
		)

		if result.count > 0 then select result
		else messageBox "No objects found with volume less than or equal to the threshold."
		redrawViews()
	)

	on btnSelectMoreVol pressed do
	(
		local minVol = spnVolume.value
		local objs = if includeHidden then objects else (for o in objects where not o.isHidden collect o)
		local result = #()

		for obj in objs where (isKindOf obj GeometryClass) do
		(
			local vol = CalculateVolume obj
			if vol >= minVol do append result obj
		)

		if result.count > 0 then select result
		else messageBox "No objects found with volume greater than or equal to the threshold."
		redrawViews()
	)

	fn defColor r g b = (dotNetClass "System.Drawing.Color").FromArgb r g b
	fn defFontB fName fSize = (dotNetObject "System.Drawing.Font" fName fSize ((dotNetClass "System.Drawing.FontStyle").bold))
	on selectionToolsRollout open do
	(
		-- UI Setup for Tacton Tools title block
		lblTitle.text = "Tacton Tools"
		lblTitle.textAlign = lblTitle.textAlign.MiddleCenter
		lblTitle.font = defFontB "Verdana" 10
		lblTitle.backColor = defColor 77 77 240
        lblTitle.foreColor = defColor 255 255 255
	)
)

createDialog selectionToolsRollout width:280 
