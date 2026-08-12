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

/*  Scale Mapping v0.45

	Changes from v0.40:
	- Converted from a .ms script into a .mcr macroscript (category "Tacton Tools",
	  button "Scale Mapping"). Tool logic is unchanged.
	- Added install-notification dialog (shown when the .mcr is dragged in / evaluated).

	Changes from v0.30:
	- Cylindrical UVW Map: no longer computes diameter from bbox.
	  When a UVW Map modifier is applied, 3ds Max auto-fits it to the object.
	  We only set axis, height (= mapSize), and recalculate utile from the
	  existing width (the fitted diameter). This works correctly for any rotation.
	- Planar UVW Map: only sets length and width (not height).
	- Box UVW Map: still sets length, width, and height.
	- Removed getCylinderDiameter helper (no longer needed).

/*  Scale Mapping v0.30

	Changes from v0.20:
	- Added "Align UVW Map" group with 6 buttons (-X +X -Y +Y -Z +Z)
	- Pressing a button snaps the corresponding edge of the UVW gizmo to
	  the object's world bounding box face on that axis.
	- Half-extent is read from the actual modifier dimensions (width/length/height).
	  The function checks which gizmo local axis is most aligned to the pressed
	  world axis (via dot products on the gizmo matrix rows) so it stays correct
	  after 90-degree rotations from the Transform Mapping buttons.

	Groups:
	1) Scale Mapping
	   - Cylindrical UVW Map => recalculate utile from bbox + map size
	   - Planar/Box UVW Map  => set L/W/H to spinner value
	   - No UVW Map          => run scale_unwraps_to_cm
	   - Other types         => prompt collapse, then scale_unwraps_to_cm

	2) Apply UVW
	   - Radio: Planar / Cylindrical / Box  (Box default)
	   - Radio: Alignment X / Y / Z         (Z default)
	   - Apply UVW Map: adds or reuses existing UVW Map modifier,
	     sets type, alignment, and size/tiling

	3) Transform Mapping
	   - 6 buttons: -X +X -Y +Y -Z +Z
	   - Rotates UVW gizmo LOCALLY for Planar/Cylindrical/Box

	4) Align UVW Map
	   - 6 buttons: -X +X -Y +Y -Z +Z
	   - Moves gizmo centre so the chosen edge aligns with the object LOCAL bbox face.
	   - Half-extent uses actual modifier dimensions matched to the local axis.
	   - Local bounds computed via snapshotasmesh vertex iteration (works in Max 2026).
*/

macroScript ScaleMapping
	category:"Tacton Tools"
	buttontext:"Scale Mapping"
	tooltip:"Scale Mapping v0.45"
(
try(destroyDialog ScaleMappingDialog)catch()
global ScaleMappingDialog

versionSM = "Scale Mapping v0.45"

rollout ScaleMappingDialog versionSM width:300
(
	-- -----------------------------
	-- UI Header
	-- -----------------------------
	dotNetControl lblTitle "Label" pos:[2,2] width:296 height:30
	label lblInfo1 "Select object(s), set desired scale, then use the tools below."

	-- Shared scale spinner
	label lbl_scale "Map Size:" offset:[60,2] across:3
	spinner cm_spinner "" width:60 range:[0.1,10000,100]
	label lbl_cm "cm" offset:[-25,2]

	local xOffset = 5

	-- -----------------------------
	-- GROUP 1: Scale Mapping
	-- -----------------------------
	group "Scale Mapping"
	(
		button btn_scale "Scale Mapping on Selected" width:200 height:30
	)

	-- -----------------------------
	-- GROUP 2: Apply UVW
	-- -----------------------------
	group "Apply UVW"
	(
		radiobuttons rb_mapType "UVW Map Type" labels:#("Planar","Cylindrical","Box") default:3 columns:3
		radiobuttons rb_alignment "Alignment" labels:#("X","Y","Z") default:3 columns:3
		button btn_applyUVW "Apply UVW Map" width:200 height:30
		label lblApplyHint "Applies chosen UVW type, alignment + size." width:280 height:18
	)

	-- -----------------------------
	-- GROUP 3: Transform Mapping
	-- -----------------------------
	group "Transform Mapping"
	(
		label lblXformHint "Rotate UVW gizmo (local) ±90°"
		radiobuttons rb_uvwDegree "Rotation Angle" labels:#("±22.5°","±45°","±90°") default:3 columns:3
		button btn_mx "-X" width:45 height:24 align:#right offset:[-xOffset,0] across:2
		button btn_px "+X" width:45 height:24 align:#left offset:[xOffset,0]
		button btn_my "-Y" width:45 height:24 align:#right offset:[-xOffset,0] across:2
		button btn_py "+Y" width:45 height:24 align:#left offset:[xOffset,0]
		button btn_mz "-Z" width:45 height:24 align:#right offset:[-xOffset,0] across:2
		button btn_pz "+Z" width:45 height:24 align:#left offset:[xOffset,0]
	)

	-- -----------------------------
	-- GROUP 4: Align UVW Map
	-- -----------------------------
	group "Align UVW Map"
	(
		label lblAlignHint "                  Snap gizmo edge to bbox face; \n                  center button centers on axis." width:280 height:28
		button btn_amx "-X" width:60 height:24 align:#right across:3
		button btn_cx  "X"  width:60 height:24
		button btn_apx "+X" width:60 height:24 align:#left
		button btn_amy "-Y" width:60 height:24 align:#right across:3
		button btn_cy  "Y"  width:60 height:24
		button btn_apy "+Y" width:60 height:24 align:#left
		button btn_amz "-Z" width:60 height:24 align:#right across:3
		button btn_cz  "Z"  width:60 height:24
		button btn_apz "+Z" width:60 height:24 align:#left
	)

	-- -----------------------------
	-- Helpers
	-- -----------------------------
	fn defColor r g b = (dotNetClass "System.Drawing.Color").FromArgb r g b
	fn defFontB fName fSize = (dotNetObject "System.Drawing.Font" fName fSize ((dotNetClass "System.Drawing.FontStyle").bold))

	fn getFirstModifierOfClass obj theClass =
	(
		for m in obj.modifiers where (classof m == theClass) do (return m)
		undefined
	)

	/* UVWMap.maptype:
	   0=Planar, 1=Cylindrical, 2=Spherical, 3=ShrinkWrap, 4=Box, 5=Face
	*/
	fn isPlanarOrBox uvwMapMod =
	(
		(uvwMapMod.maptype == 0) or (uvwMapMod.maptype == 4)
	)

	fn isCylindrical uvwMapMod =
	(
		uvwMapMod.maptype == 1
	)

	fn uvwMapTypeName mapTypeInt =
	(
		local names = #("Planar","Cylindrical","Spherical","ShrinkWrap","Box","Face")
		if mapTypeInt >= 0 and mapTypeInt < names.count then names[mapTypeInt+1] else ("Type:"+mapTypeInt as string)
	)

	-- Sets length+width (always) and height (Box only, not Planar).
	fn setUVWMapSize uvwMapMod cmVal includeHeight =
	(
		uvwMapMod.length = cmVal
		uvwMapMod.width  = cmVal
		if includeHeight do uvwMapMod.height = cmVal
	)

	fn getOrAddUVWMap obj =
	(
		local uvw = getFirstModifierOfClass obj UVWMap
		if uvw == undefined then
		(
			uvw = UVWMap()
			addModifier obj uvw
		)
		uvw
	)

	-- Returns 0=X, 1=Y, 2=Z from the alignment radio button
	fn getAlignmentInt = (rb_alignment.state - 1)

	-- Applies cylindrical-specific settings to a UVW Map modifier.
	-- Does NOT set length/width (diameter) — 3ds Max auto-fits those when the
	-- modifier is applied. We only set axis, height (= mapSize), and recalculate
	-- utile = (fitted_diameter * PI) / mapSize. vtile stays 1.0, cap = on.
	-- Sets axis, height (= mapSize), and recalculates utile from the fitted width.
	-- length/width come from Max auto-fit when the modifier is applied to a single object.
	fn setCylindricalUVWSettings uvwMapMod axisInt mapSize =
	(
		uvwMapMod.axis   = axisInt
		uvwMapMod.height = mapSize
		uvwMapMod.utile  = (uvwMapMod.width * PI) / mapSize
		uvwMapMod.vtile  = 1.0
		uvwMapMod.cap    = true
	)

	fn applyUVWMapToSelection mapTypeInt axisInt cmVal =
	(
		local sel = selection as array
		if sel.count == 0 then
		(
			messageBox "Please select at least one object." title:"Apply UVW"
			return undefined
		)

		for o in sel do
		(
			if (isValidNode o) == false do continue
			if superclassof o != GeometryClass do continue

			local uvw = getOrAddUVWMap o
			uvw.maptype = mapTypeInt

			if mapTypeInt == 1 then  -- Cylindrical
			(
				-- Select the object alone so Max auto-fits the modifier diameter correctly.
				select o
				setCylindricalUVWSettings uvw axisInt cmVal
			)
			else  -- Planar (0) or Box (4)
			(
				uvw.axis = axisInt
				setUVWMapSize uvw cmVal (mapTypeInt == 4)  -- Box includes height; Planar does not
			)
		)
		-- Restore original selection (cylindrical branch selects one at a time)
		if mapTypeInt == 1 do select sel
	)

	-- Called when the Alignment radio button changes.
	-- Updates the axis on any existing UVW Map modifier in the selection.
	-- For Cylindrical, also recalculates utile from the new axis.
	fn updateAlignmentOnSelection axisInt =
	(
		local sel = selection as array
		if sel.count == 0 do return undefined

		local cmVal = cm_spinner.value

		for o in sel do
		(
			if (isValidNode o) == false do continue
			if superclassof o != GeometryClass do continue

			local uvw = getFirstModifierOfClass o UVWMap
			if uvw != undefined then
			(
				if (isCylindrical uvw) then
					setCylindricalUVWSettings uvw axisInt cmVal
				else
					uvw.axis = axisInt
			)
		)
	)

	-- Rotate UVW gizmo around its OWN local axis (not world axis).
	-- We read the gizmo's local axis from the matrix rows, build a quat rotation
	-- around that world-space direction, post-multiply, then restore the
	-- translation so the gizmo centre does not drift.
	fn rotateUVWGizmoLocal uvwMapMod axisChar angleDeg =
	(
		try
		(
			local m = uvwMapMod.gizmo.value
			local pos = m.row4

			-- Gizmo's local axis expressed in world space
			local rotAxis = case axisChar of
			(
				#x: (normalize m.row1)
				#y: (normalize m.row2)
				#z: (normalize m.row3)
			)

			-- Rotation around that local axis
			local r = (quat angleDeg rotAxis) as matrix3

			-- Post-multiply rotates each axis vector of m by r (local rotation).
			-- Restore row4 (translation) so the gizmo centre stays in place.
			local new_m = m * r
			new_m.row4 = pos
			uvwMapMod.gizmo.value = new_m
		)
		catch
		(
			messageBox ("Could not rotate UVW gizmo for modifier:\n" + uvwMapMod.name) title:"Transform Mapping"
		)
	)

	fn rotateUVWForSelection axisChar angleDeg =
	(
		local sel = selection as array
		if sel.count == 0 then
		(
			messageBox "Please select at least one object." title:"Transform Mapping"
			return undefined
		)

		local skipped = #()
		for o in sel do
		(
			if (isValidNode o) == false do continue
			if superclassof o != GeometryClass do continue

			local uvw = getFirstModifierOfClass o UVWMap
			if uvw != undefined then
			(
				if (isPlanarOrBox uvw) or (isCylindrical uvw) then
					rotateUVWGizmoLocal uvw axisChar angleDeg
				else
					append skipped (o.name + " (" + (uvwMapTypeName uvw.maptype) + ")")
			)
		)

		if skipped.count > 0 then
		(
			local msg = "Skipped objects with non-Planar/Box UVW Map:\n\n"
			for s in skipped do msg += ("- " + s + "\n")
			messageBox msg title:"Transform Mapping"
		)
	)

	-- Returns the object bounding box in LOCAL (object) space.
	-- snapshotasmesh returns vertices in WORLD space, so we convert each vertex
	-- to local space via inverse(obj.transform). This matches the coordinate space
	-- of gizmo.value.row4, making alignment math correct for any position/rotation.
	-- Returns #(lmin, lmax) as Point3 values.
	fn getObjectLocalBounds obj =
	(
		local tmesh = snapshotasmesh obj
		if tmesh == undefined then return #([0,0,0], [0,0,0])
		local nv = tmesh.numverts
		if nv == 0 then ( delete tmesh; return #([0,0,0], [0,0,0]) )
		local invTM = inverse obj.transform
		local p0   = (getVert tmesh 1) * invTM
		local lmin = copy p0
		local lmax = copy p0
		for i = 2 to nv do
		(
			local p = (getVert tmesh i) * invTM
			if p.x < lmin.x do lmin.x = p.x
			if p.y < lmin.y do lmin.y = p.y
			if p.z < lmin.z do lmin.z = p.z
			if p.x > lmax.x do lmax.x = p.x
			if p.y > lmax.y do lmax.y = p.y
			if p.z > lmax.z do lmax.z = p.z
		)
		delete tmesh
		#(lmin, lmax)
	)

	-- Returns the half-extent of the UVW Map gizmo along the specified object-local axis.
	-- Everything stays in local space: gizmo rows are local, axis is local.
	-- The gizmo may itself be rotated (by Transform Mapping), so we dot its rows
	-- against the local axis to find which modifier dimension (width/length/height)
	-- is most aligned. Local axis mapping: row1 ~ width, row2 ~ length, row3 ~ height.
	fn getUVWHalfExtent uvwMapMod axisChar =
	(
		local m = uvwMapMod.gizmo.value
		local localAxis = case axisChar of
		(
			#x: [1.0, 0.0, 0.0]
			#y: [0.0, 1.0, 0.0]
			#z: [0.0, 0.0, 1.0]
		)
		local dX = abs (dot (normalize m.row1) localAxis)
		local dY = abs (dot (normalize m.row2) localAxis)
		local dZ = abs (dot (normalize m.row3) localAxis)

		if dX >= dY and dX >= dZ then
			uvwMapMod.width  / 2.0  -- row1 (local X) most aligned: use width
		else if dY >= dX and dY >= dZ then
			uvwMapMod.length / 2.0  -- row2 (local Y) most aligned: use length
		else
			uvwMapMod.height / 2.0  -- row3 (local Z) most aligned: use height
	)

	-- Moves the UVW Map gizmo centre so the specified edge aligns with the
	-- object's LOCAL bounding box face on that axis.
	-- isNeg=true  => align the negative edge to the local min face
	-- isNeg=false => align the positive edge to the local max face
	-- All arithmetic stays in object local space; no world conversion needed.
	fn alignUVWEdge uvwMapMod obj axisChar isNeg =
	(
		try
		(
			local halfExt = getUVWHalfExtent uvwMapMod axisChar
			local bounds  = getObjectLocalBounds obj
			local lmin    = bounds[1]
			local lmax    = bounds[2]

			local m   = uvwMapMod.gizmo.value
			local pos = m.row4  -- already in object local space

			case axisChar of
			(
				#x: pos.x = if isNeg then (lmin.x + halfExt) else (lmax.x - halfExt)
				#y: pos.y = if isNeg then (lmin.y + halfExt) else (lmax.y - halfExt)
				#z: pos.z = if isNeg then (lmin.z + halfExt) else (lmax.z - halfExt)
			)

			m.row4 = pos
			uvwMapMod.gizmo.value = m
		)
		catch
		(
			messageBox ("Could not align UVW gizmo:
" + uvwMapMod.name) title:"Align UVW Map"
		)
	)


	-- Centres the UVW Map gizmo on the specified axis within the object's local bbox.
	fn centerUVWOnAxis uvwMapMod obj axisChar =
	(
		try
		(
			local bounds = getObjectLocalBounds obj
			local lmin   = bounds[1]
			local lmax   = bounds[2]
			local m      = uvwMapMod.gizmo.value
			local pos    = m.row4
			case axisChar of
			(
				#x: pos.x = (lmin.x + lmax.x) / 2.0
				#y: pos.y = (lmin.y + lmax.y) / 2.0
				#z: pos.z = (lmin.z + lmax.z) / 2.0
			)
			m.row4 = pos
			uvwMapMod.gizmo.value = m
		)
		catch
		(
			messageBox ("Could not centre UVW gizmo:\n" + uvwMapMod.name) title:"Align UVW Map"
		)
	)

	fn centerUVWForSelection axisChar =
	(
		local sel = selection as array
		if sel.count == 0 then
		(
			messageBox "Please select at least one object." title:"Align UVW Map"
			return undefined
		)

		for o in sel do
		(
			if (isValidNode o) == false do continue
			if superclassof o != GeometryClass do continue

			local uvw = getFirstModifierOfClass o UVWMap
			if uvw != undefined then
			(
				if (isPlanarOrBox uvw) or (isCylindrical uvw) then
					centerUVWOnAxis uvw o axisChar
			)
		)
	)

	fn alignUVWForSelection axisChar isNeg =
	(
		local sel = selection as array
		if sel.count == 0 then
		(
			messageBox "Please select at least one object." title:"Align UVW Map"
			return undefined
		)

		for o in sel do
		(
			if (isValidNode o) == false do continue
			if superclassof o != GeometryClass do continue

			local uvw = getFirstModifierOfClass o UVWMap
			if uvw != undefined then
			(
				if (isPlanarOrBox uvw) or (isCylindrical uvw) then
					alignUVWEdge uvw o axisChar isNeg
			)
		)
	)

	-- -----------------------------
	-- Unwrap scaling (unchanged from v0.10)
	-- -----------------------------
	fn scale_unwraps_to_cm target =
	(
		local cm_decode = units.decodeValue "1cm"
		local the_selection = selection as array
		if the_selection.count == 0 do
		(
			messageBox "Nothing selected." title:"Scale Mapping"
			return undefined
		)

		for o in the_selection do
		(
			if (isValidNode o) == false do continue

			if (classof o) != Editable_mesh and (classof o) != Editable_Poly and (classof o) != PolyMeshObject then
			(
				continue
			)

			select o

			local unwrap_modifier = undefined

			for m in o.modifiers do
			(
				if (classof m) == Unwrap_UVW and unwrap_modifier == undefined then
				(
					if m.getMapChannel() == 0 then
					(
						unwrap_modifier = m
					)
				)
			)

			local unwrap_area = 0.0
			local face_area   = 0.0

			for f = 1 to (o.faces.count) do
			(
				if unwrap_modifier == undefined then
				(
					unwrap_modifier = Unwrap_UVW()
					addModifier o unwrap_modifier
				)

				o.modifiers["Unwrap_UVW"].getArea (#(f) as BitArray) &x &y &width &height &areaUVW &areaGeom
				face_area   += areaGeom
				unwrap_area += areaUVW
			)

			local current_ratio = unwrap_area / face_area
			if current_ratio == 0 do current_ratio = 1

			local scale_factor = 1.0 / current_ratio
			scale_factor = sqrt scale_factor
			scale_factor = scale_factor / target
			scale_factor = scale_factor / cm_decode

			modPanel.setCurrentObject unwrap_modifier
			subobjectLevel = 3
			unwrap_modifier.selectFaces #{1..(o.faces.count)}
			unwrap_modifier.scaleSelectedCenter scale_factor 0
			subobjectLevel = 0
		)

		select the_selection
	)

	fn getRotationAngleFromUI =
	(
		case rb_uvwDegree.state of
		(
			1: 22.5
			2: 45.0
			3: 90.0
			default: 90.0
		)
	)

	-- -----------------------------
	-- GROUP 1: Scale Mapping
	-- -----------------------------
	on btn_scale pressed do
	(
		max modify mode
		local sel = selection as array
		if sel.count == 0 then
		(
			messageBox "Please select at least one object." title:"Scale Mapping"
		)
		else
		(
			local cmVal = cm_spinner.value

			local objsWithUVW         = #()
			local objsWithCylindrical = #()
			local objsWithPlanarBox   = #()
			local objsWithOtherUVW    = #()

			for o in sel do
			(
				if (isValidNode o) == false do continue
				local uvw = getFirstModifierOfClass o UVWMap
				if uvw != undefined then
				(
					append objsWithUVW #(o, uvw)
					if (isCylindrical uvw) then
						append objsWithCylindrical #(o, uvw)
					else if (isPlanarOrBox uvw) then
						append objsWithPlanarBox #(o, uvw)
					else
						append objsWithOtherUVW #(o, uvw)
				)
			)

			if objsWithUVW.count == 0 then
			(
				-- No UVW Map at all => scale Unwrap UVWs
				scale_unwraps_to_cm cmVal
			)
			else
			(
				-- Cylindrical: recalculate utile using the modifier's own axis,
				-- not the radio button, then update height to new map size.
				for pair in objsWithCylindrical do
				(
					local uvw     = pair[2]
					local axisInt = try(uvw.axis) catch(2)  -- read from modifier; default Z
					setCylindricalUVWSettings uvw axisInt cmVal
				)

				-- Planar: resize length+width only.  Box: resize all three.
				for pair in objsWithPlanarBox do
				(
					local uvw = pair[2]
					setUVWMapSize uvw cmVal (uvw.maptype == 4)
				)

				-- Other types (Spherical, ShrinkWrap, etc.): prompt collapse
				if objsWithOtherUVW.count > 0 then
				(
					local msg = "One or more selected objects have a UVW Map that is NOT Planar/Box/Cylindrical.\n\n"
					msg += "Collapse those object(s) and run Scale Unwraps instead?\n\nObjects found:\n"

					for pair in objsWithOtherUVW do
						msg += ("- " + pair[1].name + " : " + (uvwMapTypeName pair[2].maptype) + "\n")

					local doCollapse = queryBox msg title:"Scale Mapping"
					if doCollapse then
					(
						for pair in objsWithOtherUVW do
						(
							local o = pair[1]
							if isValidNode o then try(collapseStack o)catch()
						)
						scale_unwraps_to_cm cmVal
					)
				)
			)
		)
	)

	-- -----------------------------
	-- GROUP 2: Apply UVW
	-- -----------------------------
	on btn_applyUVW pressed do
	(
		local cmVal   = cm_spinner.value
		local axisInt = getAlignmentInt()

		local chosen =
			case rb_mapType.state of
			(
				1: 0  -- Planar
				2: 1  -- Cylindrical
				3: 4  -- Box
				default: 4
			)

		applyUVWMapToSelection chosen axisInt cmVal
	)

	-- Alignment radio changed => update existing UVW Maps on selection
	on rb_alignment changed newState do
	(
		updateAlignmentOnSelection (newState - 1)
	)

	-- -----------------------------
	-- GROUP 3: Transform Mapping
	-- -----------------------------
	on btn_mx pressed do (rotateUVWForSelection #x -(getRotationAngleFromUI()))
	on btn_px pressed do (rotateUVWForSelection #x  (getRotationAngleFromUI()))

	on btn_my pressed do (rotateUVWForSelection #y -(getRotationAngleFromUI()))
	on btn_py pressed do (rotateUVWForSelection #y  (getRotationAngleFromUI()))

	on btn_mz pressed do (rotateUVWForSelection #z -(getRotationAngleFromUI()))
	on btn_pz pressed do (rotateUVWForSelection #z  (getRotationAngleFromUI()))

	-- -----------------------------
	-- GROUP 4: Align UVW Map
	-- -----------------------------
	on btn_amx pressed do (alignUVWForSelection #x true)
	on btn_cx  pressed do (centerUVWForSelection #x)
	on btn_apx pressed do (alignUVWForSelection #x false)

	on btn_amy pressed do (alignUVWForSelection #y true)
	on btn_cy  pressed do (centerUVWForSelection #y)
	on btn_apy pressed do (alignUVWForSelection #y false)

	on btn_amz pressed do (alignUVWForSelection #z true)
	on btn_cz  pressed do (centerUVWForSelection #z)
	on btn_apz pressed do (alignUVWForSelection #z false)

	on ScaleMappingDialog open do
	(
		lblTitle.text = "Tacton Tools"
		lblTitle.textAlign = lblTitle.textAlign.MiddleCenter
		lblTitle.font = defFontB "Verdana" 10
		lblTitle.backColor = defColor 77 77 240
		lblTitle.foreColor = defColor 255 255 255
	)
)

createDialog ScaleMappingDialog
)


-------------------------------------------------------------------------------
-- INSTALL NOTIFICATION
-- Runs only when this .mcr file is evaluated (dragged into a viewport or run
-- from the Scripting menu). Only the macroscript block above is persisted to
-- the usermacros folder, so this notice does NOT re-appear on every 3ds Max
-- startup -- it shows once, at install time.
-------------------------------------------------------------------------------
(
	rollout scaleMapInstallNotice "Macro Installed"
	(
		dotNetControl lblHdr "Label" pos:[4,4] width:312 height:28

		label lbl_done  "The 'Scale Mapping' macroscript was installed." align:#center offset:[0,8]
		label lbl_done2 "If it is not yet on a toolbar, you will need to add it:" align:#center offset:[0,2]

		group "Customize User Interface"
		(
			label lbl_step1 "1.   Customize  >  Customize User Interface" align:#left offset:[4,2]
			label lbl_step2 "2.   Open the 'Toolbars' tab" align:#left offset:[4,2]
			label lbl_step3 "3.   Set the Category to 'Tacton Tools'" align:#left offset:[4,2]
			label lbl_step4 "4.   Drag 'Scale Mapping' onto any toolbar" align:#left offset:[4,2]
		)

		button btn_close "Close" width:90 height:24 offset:[0,10]

		fn niceColor r g b = (dotNetClass "System.Drawing.Color").FromArgb r g b

		on scaleMapInstallNotice open do
		(
			lblHdr.text = "Scale Mapping  v0.45"
			lblHdr.textAlign = lblHdr.textAlign.MiddleCenter
			lblHdr.font = dotNetObject "System.Drawing.Font" "Verdana" 10 ((dotNetClass "System.Drawing.FontStyle").bold)
			lblHdr.backColor = niceColor 77 77 240
			lblHdr.foreColor = niceColor 255 255 255
		)

		on btn_close pressed do ( DestroyDialog scaleMapInstallNotice )
	)

	try ( DestroyDialog scaleMapInstallNotice ) catch ()
	createDialog scaleMapInstallNotice width:320
)
