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
Docking Point Tools

Docking Point Tools is a collection of tools for creating, modifying, and copying Docking Points for use with Tacton CPQ Visualization.
Read the tooltips to learn the function of each button.

A high level overview of the set of tools is that it will create Parent and Child Docking Points that are used for Tacton VIZstudio.
- With an object or helper selected, click Create Docking Points. A dialog will appear where you can name the Docking Point without having
to enter the DP_ prefix or P_ and C_ sub-prefixes. It will set the displays of the Child and Parent Docking Points with what is set above
in the Child DP Display and Parent DP Display. If you are creating a Docking Point from an existing P_ or C_ Docking Point, it will only
create the missing P_ or C_ Docking Point.
- Duplicate DP makes it handy to make instances of selected Docking Points into the active layer without adding the trailing incremental #.
It will also remove any hierarchy from the newly created Docking Points.
- There's some handy selection methods of the Docking Points, a few that will select the Parents or Children of the selection. It does this by
analyzing the name, so make sure your names are correct. In the case that Docking Points were manually copied and a trailing # is added, this
will select those Docking Points, where you can then remove the trailing # using the Misc Utility found at the bottom.
- Another helpful tool is Align Helper to Hole. Handy when you have a hole that is not aligned to any axis.
It is a 3 point alignment: The first two points should be across from each other on the hole, this is the Y axis. The third point aligns the
X axis to the hole. The Z axis should no point out of or into the hole depending on the selection order. Press Flip Z-Axis to quickly flip
if needed.

29-08-2024 v1.0 Initial release. Enjoy!
06-09-2024 v1.1 Bug fixes.
23-09-2024 v1.2 Added in Align Helper. Aligns helper or Docking Point to a hole. It works by selecting three vertices. The first picks the +Y direction,
	the second picks the -Y direction, and the third picks the plane that X will be aligned to. This allows Z to point away from the hole. Use Flip Z-Axis
	if the Z-Axis is pointing in the wrong direction.
24-09-2024 v1.3 Added checked state to Align Helper to know that it has been pressed. Also changed how modifying Docking Point display properties works.
	If a DP_C_ or DP_P_ prefix named helper is selected, it will change the display settings on the fly without pressing Modify Docking Points.
	The Modify Docking Points button is still useful if the desired display settings is set and you want to apply them to a new selection.
26-09-2024 v1.4 Fixed bug with variable not inheriting a global variable for drawing labels on screen with the Align Helper to Hole command.
	Changed how colors are assigned. Added in Retrieve Docking Point Attributes. This allows the settings to be updated from existing Docking PointSelection
	with prefixes of DP_C_ and DP_P_.
17-03-2025 v1.5 Fixed Duplicate DP, it will duplicate the complete selection of Docking Points instead of just the first one in the selection.
	Fixed error when a DP_P_xxx Docking Point is selected and Create Docking Points is pressed. It will now create a child Docking Point as expected.
	Change nme of script from CreateDockingPoints to Docking Point Tools.
29-04-2025 V1.55 Changed behavior of setting the Child DP Display to also affect DIM Docking Points
13-05-2025 V1.6 Add Create Group button
24-07-2025 V1.7 Add button that selects Docking Points that have a tailing number. Example DP_C_Manifold001 or DP_P_Axle042
25-09-2025 V1.9 Bug fixes. Having a helper with a prefix named DP_ created DP_C_DP_ and DP_P_DP_ and a helper named DP_C_ would create the child as DP_C_DP_C_
	when Create Docking Points was selected. It will now correctly create the DP_C_ and DP_P_ Docking Points.
04-12-2025 V2.0 Overhauled the items in a selction. If a group that is closed is selected, it will only make DP for the group, not the objects within the closed group.
	This prevents the accidental result of many DP being created for all objects within a group.
20-02-2025 V2.05 Added ability to turn on and off Draw On Top in the Misc Utilites. Works with selection, or a checkbox to do it scene wide, hidden or not.
01-07-2026 V2.15 Added "Duplicate to Visible Layers" checkbox to Duplicate DP. When checked, it also duplicates the selected Docking Point(s) into every other
	visible layer, skipping any layer that has no objects directly assigned to it (so parent layers that only hold sub-layers are ignored) and skipping any
	layer that already contains a Docking Point with that exact name.
01-07-2026 V2.20 Added "DP Auto Hierarchy" button. For the current layer (or every visible layer, if Duplicate to Visible Layers is checked), it finds the
	DP_C_ Docking Point(s) directly in that layer, picks the alphabetically-first one as the layer's top parent, and reparents every other unparented
	top-level node in that layer (objects, group heads, other DP_C_ points, and DP_P_ points) underneath it. Existing hierarchies (groups, manual parenting)
	are preserved since only unparented nodes are touched, and cross-layer parenting is never created or broken.
02-07-2026 V2.25 Added "Affect 'NO_' Layers" checkbox logic. The checkbox is only enabled when "Affect all Visible Layers" is checked. When "Affect all Visible
	Layers" is checked and "Affect 'NO_' Layers" is unchecked, Duplicate DP and DP Auto Hierarchy skip layers whose name starts with "NO_". Checking both
	includes the NO_ layers again. In current-layer mode (Affect all Visible Layers unchecked) no NO_ filtering is applied.
02-07-2026 V2.30 Fixed long-standing Create Docking Points bugs: selecting a regular object no longer renames that object to the entered name (only the new
	Docking Points get the name; a selected Point helper is still renamed since it becomes the Docking Point itself). Entering a name that already has a
	DP_C_, DP_P_, DP_DIM_, or DP_ prefix no longer doubles the prefix (DP_C_MotorMount now creates DP_C_MotorMount, not DP_C_DP_C_MotorMount); entering
	DP_P_Name on a Point helper makes it the parent and creates the missing child. Renamed the naming dialog rollout from "Rename and Confirm" to
	"Name Docking Point".
09-07-2026 V2.35 Added "Convert Dummy" button to Misc Utilities. FBX reimport turns Point helpers into Dummy objects; this converts Dummies named DP_C_,
	DP_P_, or DP_DIM_ back into Point helpers by swapping the base object, so name, transform, hierarchy, layer, and wire color are all kept. DP_C_/DP_DIM_
	get the Child DP Display settings and size, DP_P_ gets the Parent DP Display settings and size. Works on the selection; if the selection has no DP
	Dummies it offers to convert the whole scene. Group heads are never touched (they are Dummies too, but lack the DP_ prefix).
09-07-2026 V2.40 Convert Dummy now converts ANY Dummy with a DP_ prefix (DP_SF_, DP_ST_, etc.), not just DP_C_/DP_P_/DP_DIM_. Only DP_C_/DP_DIM_ (child)
	and DP_P_ (parent) get the display settings from the UI; other DP_ prefixes keep the default Point helper display.
*/

try (DestroyDialog helperRollout) catch()
try (closeRolloutFloater nameDialog) catch()

global nameDialog -- Declare nameDialog as global so it can be accessed within the button event handlers
global currentObj -- Declare currentObj as global to store the current object being renamed
global selectedObjects -- Declare selectedObjects as global to access it in btnOK
global helperRolloutRef -- Declare a global reference to the helperRollout
global AlignHelperToHoleMarkers = #() -- Initialize globally as an empty array

global groupNameEntered = undefined
global groupNameDialogOpen = false
global groupNameDefault = ""


versionCDP = "Docking Point Tools v2.40"
defaultHelperSize = 20

-- Structure to store marker data for drawing in the viewport
struct vertexData (pos, txt, col)

rollout grpNameRollout "Enter Group Name"
(
    editText txtGrpName "Group Name:" text:""
    button btnConfirm "OK"

    on grpNameRollout open do
    (
        txtGrpName.text = groupNameDefault
    )

    on btnConfirm pressed do
    (
        if txtGrpName.text != "" then
        (
            groupNameEntered = txtGrpName.text
            groupNameDialogOpen = false
            destroyDialog grpNameRollout
        )
    )
)


-- Function to draw the markers, text, and lines in the viewport
fn drawCoords  =
(
	markers = AlignHelperToHoleMarkers
    gw.setTransform (matrix3 1)
    if markers != undefined and markers.count > 0 then (
        -- Proceed with drawing markers and lines
        for i in markers do (
            p = gw.hTransPoint i.pos
            gw.hText p i.txt color:i.col
            gw.hMarker p #smallHollowBox color:[255,255,255]
        )
        -- Draw lines
		if markers.count > 1 then (
			gw.setColor #line [0,255,0] -- Green line for Y-axis
			gw.hPolyline #(gw.hTransPoint markers[1].pos, gw.hTransPoint markers[2].pos) false
		)
		if markers.count > 2 then (
			gw.setColor #line [255,0,0] -- Red line for X-axis
			local midpoint = (markers[1].pos + markers[2].pos) / 2
			gw.hPolyline #(gw.hTransPoint midpoint, gw.hTransPoint markers[3].pos) false
		)
		gw.enlargeUpdateRect #whole
		gw.updateScreen()
    )
	else
	(
		--print "Something went wrong. No coordinates found"
	)
)

-- Function to calculate the midpoint between two points
fn calculateMidpoint p1 p2 =
(
    (p1 + p2) / 2
)

-- Function to align the helper based on selected vertices
fn alignHelperToHole helper p1 p2 p3 =
(
	undo on
	(
		-- Step 1: Calculate the average position for the helper's pivot
		local pivotPos = calculateMidpoint p1 p2
		helper.position = pivotPos

		-- Step 2: Align the Y-axis towards the first selected vertex (positive Y direction)
		local yAxisDir = normalize (p1 - p2)

		-- Step 3: Align the X-axis towards the third selected vertex (p3)
		local xAxisDir = normalize (p3 - pivotPos)

		-- Step 4: The Z-axis is perpendicular to the X- and Y-axes
		local zAxisDir = normalize (cross xAxisDir yAxisDir)

		-- Recalculate X-axis to ensure it is perpendicular to the Y and Z
		xAxisDir = normalize (cross yAxisDir zAxisDir)

		-- Construct the transformation matrix for the helper
		local alignMatrix = matrix3 xAxisDir yAxisDir zAxisDir pivotPos

		-- Apply the new transform to the helper
		helper.transform = alignMatrix
	)
)

-- Function to reverse the Z-axis by rotating the helper 180 degrees on the Y-axis using Euler angles
fn reverseZAxis helper =
(
    in coordsys local rotate helper (eulerAngles 0 180 0)  -- Rotate 180 degrees around Y-axis in local coordinates
)

-- Remove sequence of numbers at end of object
fn trimNonChar txt = (
	local regex = dotnetobject "System.Text.RegularExpressions.Regex" @"[_-]*\d{2,}$"	-- search for 1 or more digits at the end, optionally preceeded by one ore more _ or - characters
	local match = regex.matches txt
	if match.count == 1 then (
		substring txt 1 (txt.count - match.item[0].length)		-- trim away end
	) else txt
)
-- Function to generate a random color
fn getRandomColor = 
(
	local col = red
	col.hue = random 0 255
	col.saturation = random 140 245
	col.value = random 128 255
	wireColor = col
)

fn setDockingPointProperties obj size centerMarker axisTripod cross box drawOnTop wireColor = 
(
	obj.size = size
	obj.centerMarker = centerMarker
	obj.axisTripod = axisTripod
	obj.cross = cross
	obj.box = box
	obj.drawontop = drawOnTop
	obj.wireColor = wireColor
)

fn createDockingPoint name position transform size centerMarker axisTripod cross box drawOnTop wireColor =
(
	local dp = point name:name pos:position transform:transform
	setDockingPointProperties dp size centerMarker axisTripod cross box drawOnTop wireColor
	dp
)

fn modifyDockingPoints helperSize parentSize chkParentCenterMarkerState chkParentAxisTripodState chkParentCrossState chkParentBoxState chkParentDrawTopState chkChildCenterMarkerState chkChildAxisTripodState chkChildCrossState chkChildBoxState chkChildDrawTopState =
(
    local prefixChild = "DP_C_"
    local prefixParent = "DP_P_"
	local prefixDIM = "DP_DIM_"
	/*
	if (classof currentObj == Dummy) then
	(
		local pnt = point size:20
		currentObj.baseObject = pnt.baseObject
		currentObj.axistripod = on
		currentObj.name = substituteString obj.name "DM_" "PT_"
		currentObjobj.wirecolor = (color 14 255 2)
		delete pnt
	)
    */
    for obj in selection where (isKindOf obj Point) do
    (
        if (matchPattern obj.name pattern:(prefixParent + "*")) then
        (
            setDockingPointProperties obj parentSize chkParentCenterMarkerState chkParentAxisTripodState chkParentCrossState chkParentBoxState chkParentDrawTopState obj.wireColor
        )
        else if (matchPattern obj.name pattern:(prefixChild + "*")) then
        (
            setDockingPointProperties obj helperSize chkChildCenterMarkerState chkChildAxisTripodState chkChildCrossState chkChildBoxState chkChildDrawTopState obj.wireColor
            redrawviews()
        )
		else if (matchPattern obj.name pattern:(prefixDIM + "*")) then
        (
            setDockingPointProperties obj helperSize chkChildCenterMarkerState chkChildAxisTripodState chkChildCrossState chkChildBoxState chkChildDrawTopState obj.wireColor
            redrawviews()
        )
        else
        (
           -- messageBox "No Docking Points with DP_C_ or DP_P_ prefixes selected"
        )
    )
)

-- Walk up parent chain until we hit a group head (or nothing).
fn getImmediateGroupHead node =
(
    local n = node.parent
    while (n != undefined and not isGroupHead n) do
        n = n.parent
    n  -- may be undefined
)

-- Alphabetical comparator for qsort, used to pick the top DP_C_ Docking Point in a layer.
fn compareNodeNames a b =
(
    if a.name < b.name then -1
    else if a.name > b.name then 1
    else 0
)

-- Reparents unparented top-level nodes in a layer under its alphabetically-first DP_C_ Docking Point.
-- Returns true if the layer had a DP_C_ Docking Point and was organized, false if it was skipped.
fn organizeLayerHierarchy lyr =
(
    local prefixChild = "DP_C_"
    local layerNodes = #()
    lyr.nodes &layerNodes  -- only nodes directly assigned to this layer

    local dpcNodes = for n in layerNodes where (isKindOf n Point and matchPattern n.name pattern:(prefixChild + "*")) collect n
    if dpcNodes.count == 0 then
        false
    else
    (
        qsort dpcNodes compareNodeNames
        local topParent = dpcNodes[1]

        for n in layerNodes where (n != topParent and n.parent == undefined) do
            n.parent = topParent

        topParent
    )
)

-- Define the nameRollout before btnCreateDP button is used
rollout nameRollout "Name Docking Point"
(
    editText txtName "Name: " text:""
    button btnOK "OK"
    
    on btnOK pressed do
	(
		undo "Create/Modify Docking Points" on
		(
			local newName = txtName.text
			if newName != "" then
			(
				-- Create or modify docking points using the entered name
				local helperSize = helperRolloutRef.spnHelperSize.value
				local parentSize = helperRolloutRef.spnHelperSize.value * helperRolloutRef.spnParentMult.value
				local prefixChild = "DP_C_"
				local prefixParent = "DP_P_"
				local prefixDIM = "DP_DIM_"
				local prefixIncomplete = "DP_"

				-- Strip any DP prefix the user typed so it never gets doubled up (DP_C_MotorMount -> MotorMount)
				local baseName = newName
				if matchPattern baseName pattern:(prefixChild + "*") then baseName = substring baseName (prefixChild.count + 1) baseName.count
				else if matchPattern baseName pattern:(prefixParent + "*") then baseName = substring baseName (prefixParent.count + 1) baseName.count
				else if matchPattern baseName pattern:(prefixDIM + "*") then baseName = substring baseName (prefixDIM.count + 1) baseName.count
				else if matchPattern baseName pattern:(prefixIncomplete + "*") then baseName = substring baseName (prefixIncomplete.count + 1) baseName.count

				local helperColor
				local helperParentColor = red
				local defaultDPColor = color 14 255 2
				case helperRolloutRef.rbColorOptions.state of
				(

					1: -- Object Wire Color
					(
						if selection.count > 0 then
						(
							local objWireCol  = currentObj.wireColor
							local objDisplayCol = (try currentObj.color catch objWireCol)  -- safe fallback

							if (objWireCol == black or objDisplayCol == black) then
							(
								-- If object is effectively black, force default DP color
								helperColor = defaultDPColor
								helperParentColor = defaultDPColor
-- 								format "Object color is black -> using default DP color: %\n" helperColor
							)
							else
							(
								helperColor = objWireCol
								helperParentColor = helperColor
-- 								format "Object Color applied: %\n" helperColor
							)
						)
						else
						(
							messageBox "No object selected. Please select an object."
						)
					)
					
					2: -- Random Color (wireColor)
					(
						helperColor = getRandomColor()
						helperParentColor = helperColor
-- 						format "Random Color applied: %\n" helperColor
					)

					3: -- Default Color
					(
						helperColor = color 14 255 2
						helperParentColor = helperColor
-- 						format "Default Color applied: %\n" helperColor
					)
				)
				
				if (isKindOf currentObj Point) then
				(
					-- The selected point itself becomes the Docking Point, so renaming it IS intended here.
					if (matchPattern newName pattern:(prefixParent + "*")) then
					(
						currentObj.name = prefixParent + baseName
						local hlprName = prefixChild + baseName
						createDockingPoint hlprName currentObj.pos currentObj.transform helperSize helperRolloutRef.chkChildCenterMarker.checked helperRolloutRef.chkChildAxisTripod.checked helperRolloutRef.chkChildCross.checked helperRolloutRef.chkChildBox.checked helperRolloutRef.chkChildDrawTop.checked helperColor
						setDockingPointProperties currentObj parentSize off on off on helperRolloutRef.chkParentDrawTop.checked helperParentColor
					)
					else if (matchPattern newName pattern:(prefixDIM + "*")) then
					(
						currentObj.name = prefixDIM + baseName
						setDockingPointProperties currentObj helperSize helperRolloutRef.chkChildCenterMarker.checked helperRolloutRef.chkChildAxisTripod.checked helperRolloutRef.chkChildCross.checked helperRolloutRef.chkChildBox.checked helperRolloutRef.chkChildDrawTop.checked helperColor
					)
					else
					(
						currentObj.name = prefixChild + baseName
						setDockingPointProperties currentObj helperSize helperRolloutRef.chkChildCenterMarker.checked helperRolloutRef.chkChildAxisTripod.checked helperRolloutRef.chkChildCross.checked helperRolloutRef.chkChildBox.checked helperRolloutRef.chkChildDrawTop.checked helperColor
					)
				)
				else
				(
					-- Regular object: create the child Docking Point from the entered name, leave the object's own name alone.
					local hlprName = prefixChild + baseName
					createDockingPoint hlprName currentObj.pos currentObj.transform helperSize helperRolloutRef.chkChildCenterMarker.checked helperRolloutRef.chkChildAxisTripod.checked helperRolloutRef.chkChildCross.checked helperRolloutRef.chkChildBox.checked helperRolloutRef.chkChildDrawTop.checked helperColor
				)

				if helperRolloutRef.chkParent.checked and not (matchPattern currentObj.name pattern:(prefixParent + "*")) then
				(
					local hlprParentName = prefixParent + baseName
					createDockingPoint hlprParentName currentObj.pos currentObj.transform parentSize helperRolloutRef.chkParentCenterMarker.checked helperRolloutRef.chkParentAxisTripod.checked helperRolloutRef.chkParentCross.checked helperRolloutRef.chkParentBox.checked helperRolloutRef.chkParentDrawTop.checked helperParentColor
				)
			)
			
			local currentIndex = findItem selectedObjects currentObj
			if currentIndex < selectedObjects.count then
			(
				currentObj = selectedObjects[currentIndex + 1]
				select currentObj
				txtName.text = currentObj.name
			)
			else
			(
				closeRolloutFloater nameDialog
			)
		)
	)
)

rollout helperRollout versionCDP width:300
(
-- Create and Modify Docking Points
	dotNetControl lblTitle "Label" pos:[2,2] width:296 height:30 -- Add Tacton Tools title block
    group ""
	(
		--label dividerLabel1 "-------------------------------   ---------------------------------" height:12 align:#center enabled:false
		label typeChildDP "Child DP Display" enabled:false across:2 offset:[0,-6]
		label typeParentDP "Parent DP Display" enabled:false offset:[0,-6]
		label dividerLabel2 "-------------------------------   ---------------------------------" height:18 align:#center enabled:false offset:[0,-5]
		
		checkbox chkChildCenterMarker "Center Marker" checked:false across:2
		checkbox chkParentCenterMarker "Center Marker" checked:false
		
		checkbox chkChildAxisTripod "Axis Tripod" checked:false across:2
		checkbox chkParentAxisTripod "Axis Tripod" checked:true
		
		checkbox chkChildCross "Cross" checked:false across:2
		checkbox chkParentCross "Cross" checked:false
		
		checkbox chkChildBox "Box" checked:true across:2
		checkbox chkParentBox "Box" checked:true
		
		checkbox chkChildDrawTop "Draw On Top" checked:true across:2
		checkbox chkParentDrawTop "Draw On Top" checked:true
		
		spinner spnHelperSize "Helper Size:" range:[1,1000,defaultHelperSize] type:#float fieldwidth:40 align: #left across: 2
			tooltip:"Sets the size of the Child Docking Point."
		spinner spnParentMult "Parent Size Multiplier:" range:[0.1,5,0.75] type:#float fieldwidth:30
			tooltip:"The Parent Docking Point size is a multiple of the Helper Size."
		
		-- Radio buttons group with three options: Random Color, Object Color, Default Color
		radiobuttons rbColorOptions "                           Docking Point Color" labels:#("Obj Wire Color", "Random Color", "Default Color") columns:3 align:#center
        tooltip:"Wire color of selected object assigned to Docking Points. Random will assign the Parent and Child the same random color, and will not affect Modify Docking Points. Default Color is the green we all love in our point helpers."
		label typeBlank "-------------------------------------------------------------------" enabled:false
		-- Buttons to create or modify Docking Points
		checkbox chkParent "Create Parent DP" checked:true align:#right offset:[-43,0]
			tooltip:"When checked, a parent Docking Point will be created if it is not the currently selected object with a DP_P_ prefix."
		button btnCreateDP "Create Docking Points" width:270 height:30
			tooltip: "Select an object or helper and create Docking Points from the location and orientation."
		button btnModifyDP "Modify Docking Points" width:130 height:30 align:#center across:2
			tooltip: "This will modify the Size and Display of selected Docking Points to the values above. Colors will not be changed, if that is wanted use the Docking Point Color Assignment utilities below."
		button btnGetDP "Retrieve Docking        Point Attributes" width:130 height:30 align:#center
			tooltip: "Retrieve the display settings of child and/or parent Docking Points and set them above. It will only retrieve from the first of each child and parent. Parent Size Multiplier will only change if at least one parent and child is in the selection."
	)
	
	on btnGetDP pressed do
	(
		selectedObjects = selection as Array
		selectedCDP = #()
		selectedPDP = #()
		local prefixChild = "DP_C_"
		local prefixParent = "DP_P_"
		local prefixDIM = "DP_DIM_"
    
		-- Loop through selected objects and categorize them into Child and Parent arrays
		for obj in selectedObjects where (isKindOf obj Point) do
		(
			if (matchPattern obj.name pattern:(prefixParent + "*")) then
			(
				append selectedPDP obj
			)
			else if (matchPattern obj.name pattern:(prefixChild + "*")) then
			(
				append selectedCDP obj
			)
			else if (matchPattern obj.name pattern:(prefixDIM + "*")) then
			(
				append selectedCDP obj
			)
		)
		
		-- If Child Docking Points found, apply values from the first one
		if selectedCDP.count > 0 then
		(
			local cdp = selectedCDP[1]  -- First Child Docking Point
			-- Update rollout checkboxes and spinner for Child DP
			chkChildCenterMarker.checked = cdp.centermarker  -- Example for a property, adjust according to your settings
			chkChildAxisTripod.checked = cdp.axistripod
			chkChildCross.checked = cdp.cross
			chkChildBox.checked = cdp.Box
			chkChildDrawTop.checked = cdp.drawontop
			spnHelperSize.value = cdp.size
		)
		
		-- If Parent Docking Points found, apply values from the first one
		if selectedPDP.count > 0 then
		(
			local pdp = selectedPDP[1]  -- First Parent Docking Point
			-- Update rollout checkboxes for Parent DP
			chkParentCenterMarker.checked = pdp.centermarker
			chkParentAxisTripod.checked = pdp.axistripod
			chkParentCross.checked = pdp.cross
			chkParentBox.checked = pdp.Box
			chkParentDrawTop.checked = pdp.drawontop
        -- If there are Child Docking Points, calculate the Parent Multiplier
			
			if selectedCDP.count > 0 then
			(
				local cdp = selectedCDP[1]  -- First Child Docking Point (for comparison)
				spnParentMult.value = pdp.size / cdp.size
			)
			else -- this assumes the default multiplier is used
			(
				spnHelperSize.value = pdp.size / spnParentMult.value
			)
		)

		-- Show a message if no valid Docking Points were found
		if selectedCDP.count == 0 and selectedPDP.count == 0 then
		(
			messageBox "No Docking Points with DP_C_ or DP_P_ prefixes selected"
		)
		
	)
	
	on btnCreateDP pressed do undo on
	(
		selectedObjects = #()
			
		local OG_Selection   = selection as array
		local YES_Selection  = #()
		local NO_Selection   = #()
		local objsToAddDP    = #()

-- 		format "\n============================================\n"
-- 		format "Closed Group Detection via Selection-Expansion\n"
-- 		format "Original selection count: %\n\n" OG_Selection.count

		if OG_Selection.count == 0 then
		(
			format "Nothing selected.\n"
			format "============================================\n\n"
			return()
		)

		-------------------------------
		-- Phase 1: YES / NO detection
		-------------------------------
		for obj in OG_Selection do
		(
			select obj
			local checkSelection = selection as array

			if checkSelection.count > 1 then
			(
				-- Object is part of (or itself) a closed group.
				for o in checkSelection do
					appendIfUnique NO_Selection o
			)
			else
			(
				appendIfUnique YES_Selection obj
			)
		)

		-- Restore original selection
		select OG_Selection

-- 		format "YES_Selection (not in closed groups) - % object(s):\n" YES_Selection.count
-- 		for o in YES_Selection do
-- 			format "  YES: % (class: %)\n" o.name (classof o)

		---------------------------------------
		-- Phase 2: find closed group hierarchy
		---------------------------------------

		-- All group heads that are in NO_Selection
		local closedGroupHeads = for o in NO_Selection where isGroupHead o collect o

		-- Identify HERO vs IGNORED among closed group heads:
		local heroClosedGroups    = #()
		local ignoredClosedGroups = #()

		for gh in closedGroupHeads do
		(
			local parentHead = getImmediateGroupHead gh

			if parentHead != undefined and (findItem closedGroupHeads parentHead) != 0 then
			(
				append ignoredClosedGroups gh
			)
			else
			(
				append heroClosedGroups gh
			)
		)

-- 		format "\nHERO CLOSED GROUPS (topmost closed groups): %\n" heroClosedGroups.count
-- 		for gh in heroClosedGroups do
-- 			format "  HERO GROUP: %\n" gh.name

-- 		format "============================================\n\n"

		-- Build final list of objects to process
		objsToAddDP = heroClosedGroups + YES_Selection

-- 		format "objsToAddDP count: %\n" objsToAddDP.count
-- 		for i in objsToAddDP do print i

		-- Now feed that into your rename/DP creation workflow
		selectedObjects = objsToAddDP

		if selectedObjects.count > 0 then
		(
			currentObj = selectedObjects[1]
			nameDialog = newRolloutFloater "Enter Name" 200 100
			addRollout nameRollout nameDialog
			nameRollout.txtName.text = currentObj.name
			select currentObj
			redrawviews()
		)
		else
		(
			messageBox "No objects selected!" title:"Warning"
		)
	)

	-- Attach event handlers to call modifyDockingPoints when a checkbox or spinner changes
	on chkParentCenterMarker changed state do
		modifyDockingPoints spnHelperSize.value (spnHelperSize.value * spnParentMult.value) chkParentCenterMarker.checked chkParentAxisTripod.checked chkParentCross.checked chkParentBox.checked chkParentDrawTop.checked \
		chkChildCenterMarker.checked chkChildAxisTripod.checked chkChildCross.checked chkChildBox.checked chkChildDrawTop.checked

	on chkParentAxisTripod changed state do
		modifyDockingPoints spnHelperSize.value (spnHelperSize.value * spnParentMult.value) chkParentCenterMarker.checked chkParentAxisTripod.checked chkParentCross.checked chkParentBox.checked chkParentDrawTop.checked \
		chkChildCenterMarker.checked chkChildAxisTripod.checked chkChildCross.checked chkChildBox.checked chkChildDrawTop.checked

	on chkParentCross changed state do
		modifyDockingPoints spnHelperSize.value (spnHelperSize.value * spnParentMult.value) chkParentCenterMarker.checked chkParentAxisTripod.checked chkParentCross.checked chkParentBox.checked chkParentDrawTop.checked \
		chkChildCenterMarker.checked chkChildAxisTripod.checked chkChildCross.checked chkChildBox.checked chkChildDrawTop.checked

	on chkParentBox changed state do
		modifyDockingPoints spnHelperSize.value (spnHelperSize.value * spnParentMult.value) chkParentCenterMarker.checked chkParentAxisTripod.checked chkParentCross.checked chkParentBox.checked chkParentDrawTop.checked \
		chkChildCenterMarker.checked chkChildAxisTripod.checked chkChildCross.checked chkChildBox.checked chkChildDrawTop.checked

	on chkParentDrawTop changed state do
		modifyDockingPoints spnHelperSize.value (spnHelperSize.value * spnParentMult.value) chkParentCenterMarker.checked chkParentAxisTripod.checked chkParentCross.checked chkParentBox.checked chkParentDrawTop.checked \
		chkChildCenterMarker.checked chkChildAxisTripod.checked chkChildCross.checked chkChildBox.checked chkChildDrawTop.checked

	on chkChildCenterMarker changed state do
		modifyDockingPoints spnHelperSize.value (spnHelperSize.value * spnParentMult.value) chkParentCenterMarker.checked chkParentAxisTripod.checked chkParentCross.checked chkParentBox.checked chkParentDrawTop.checked \
		chkChildCenterMarker.checked chkChildAxisTripod.checked chkChildCross.checked chkChildBox.checked chkChildDrawTop.checked

	on chkChildAxisTripod changed state do
		modifyDockingPoints spnHelperSize.value (spnHelperSize.value * spnParentMult.value) chkParentCenterMarker.checked chkParentAxisTripod.checked chkParentCross.checked chkParentBox.checked chkParentDrawTop.checked \
		chkChildCenterMarker.checked chkChildAxisTripod.checked chkChildCross.checked chkChildBox.checked chkChildDrawTop.checked

	on chkChildCross changed state do
		modifyDockingPoints spnHelperSize.value (spnHelperSize.value * spnParentMult.value) chkParentCenterMarker.checked chkParentAxisTripod.checked chkParentCross.checked chkParentBox.checked chkParentDrawTop.checked \
		chkChildCenterMarker.checked chkChildAxisTripod.checked chkChildCross.checked chkChildBox.checked chkChildDrawTop.checked

	on chkChildBox changed state do
		modifyDockingPoints spnHelperSize.value (spnHelperSize.value * spnParentMult.value) chkParentCenterMarker.checked chkParentAxisTripod.checked chkParentCross.checked chkParentBox.checked chkParentDrawTop.checked \
		chkChildCenterMarker.checked chkChildAxisTripod.checked chkChildCross.checked chkChildBox.checked chkChildDrawTop.checked
	
	on chkChildDrawTop changed state do
		modifyDockingPoints spnHelperSize.value (spnHelperSize.value * spnParentMult.value) chkParentCenterMarker.checked chkParentAxisTripod.checked chkParentCross.checked chkParentBox.checked chkParentDrawTop.checked \
		chkChildCenterMarker.checked chkChildAxisTripod.checked chkChildCross.checked chkChildBox.checked chkChildDrawTop.checked
	
	on spnHelperSize changed val do
		modifyDockingPoints spnHelperSize.value (spnHelperSize.value * spnParentMult.value) chkParentCenterMarker.checked chkParentAxisTripod.checked chkParentCross.checked chkParentBox.checked chkParentDrawTop.checked \
		chkChildCenterMarker.checked chkChildAxisTripod.checked chkChildCross.checked chkChildBox.checked chkChildDrawTop.checked

	on spnParentMult changed val do
		modifyDockingPoints spnHelperSize.value (spnHelperSize.value * spnParentMult.value) chkParentCenterMarker.checked chkParentAxisTripod.checked chkParentCross.checked chkParentBox.checked chkParentDrawTop.checked \
		chkChildCenterMarker.checked chkChildAxisTripod.checked chkChildCross.checked chkChildBox.checked chkChildDrawTop.checked

	-- Modify Docking Points button used when you want to apply values to a new selection.
	on btnModifyDP pressed do undo on
	(
		modifyDockingPoints spnHelperSize.value (spnHelperSize.value * spnParentMult.value) chkParentCenterMarker.checked chkParentAxisTripod.checked chkParentCross.checked chkParentBox.checked chkParentDrawTop.checked \
		chkChildCenterMarker.checked chkChildAxisTripod.checked chkChildCross.checked chkChildBox.checked chkChildDrawTop.checked
	)
	
-- Duplicate Docking Points
	group "Duplicate Docking Points"
	(
	checkbox chkDupAllVisibleLayers "Affect all Visible Layers" checked:false align:#left offset:[2,0] across:2
			tooltip:"When checked, Duplicate DP will duplicate the selection into every other visible layer. Layers with no objects directly in them and layers that already have a Docking Point of that exact name, are skipped. Will also make DP Auto Hierarchy organize visible layers."
	checkbox chkDupNoLayers "Affect 'NO_' Layers" checked:false enabled:false align:#center offset:[2,0]
			tooltip:"Only available when 'Affect all Visible Layers' is checked. When checked, Duplicate DP and DP Auto Hierarchy will also affect layers with 'NO_' prefix. Otherwise these layers will be ignored."
	button btnDuplicateDP "Duplicate DP" width:270 height:30
		tooltip:"This will duplicate the currently selected Docking Point or helper into the currently selected Layer unless Affect all Visible Layers is checked. It will not add sequence number to end of name, and will unlink it from any existing hierarchy."
	button btnAutoHierarchy "DP Auto Hierarchy" width:270 height:30 align:#center
		tooltip:"Attempts to arrange the hierarchy of objects and DPs. Works on active layer unless 'Affect all Visible Layers' in checked."
	)
	-- 'Affect NO_ Layers' only applies in all-visible-layers mode, so it is disabled otherwise.
	on chkDupAllVisibleLayers changed state do
		chkDupNoLayers.enabled = state

	-- NO_ layers are skipped in all-visible-layers mode unless chkDupNoLayers opts them in.
	fn skipNoLayer lyr =
	(
		(not chkDupNoLayers.checked) and (matchPattern lyr.name pattern:"NO_*")
	)

	on btnDuplicateDP pressed do undo on
	(
		local OGselection = selection as array  -- capture the original selection
		local newDockingPoints = #()             -- initialize an empty array for new instances

		local prefixChild = "DP_C_"
		local prefixParent = "DP_P_"
		local prefixDIM = "DP_DIM_"

		local donorObjs = for obj in OGselection where (isKindOf obj Helper or classof obj == Dummy) and
		(
		matchPattern obj.name pattern:(prefixChild + "*") or
		matchPattern obj.name pattern:(prefixParent + "*") or
		matchPattern obj.name pattern:(prefixDIM + "*")
		)
		collect obj

		if chkDupAllVisibleLayers.checked then
		(
			-- Duplicate into every OTHER visible layer that has objects in it and doesn't
			-- already contain a Docking Point with the exact same name. The currently active
			-- layer is skipped entirely in this mode.
			local currentLayerName = layerManager.current.name

			for donorObj in donorObjs do
			(
				local dpName = donorObj.name
				local helperColor = donorObj.wireColor

				for li = 0 to (layerManager.count - 1) do
				(
					local lyr = layerManager.getLayer li

					if lyr.name != currentLayerName and not lyr.isHidden and not (skipNoLayer lyr) do
					(
						local layerNodes = #()
						lyr.nodes &layerNodes  -- only nodes directly assigned to this layer, not sub-layers

						if layerNodes.count > 0 do
						(
							local alreadyExists = false
							for n in layerNodes where n.name == dpName do alreadyExists = true

							if not alreadyExists do
							(
								local hlprInstance = instance donorObj

								hlprInstance.name = dpName
								hlprInstance.wireColor = helperColor
								hlprInstance.parent = undefined
								lyr.addNode hlprInstance

								append newDockingPoints hlprInstance
							)
						)
					)
				)
			)
		)
		else
		(
			-- Default behavior: duplicate into the currently active layer only.
			for donorObj in donorObjs do
			(
				local helperColor = donorObj.wireColor
				local hlprName = donorObj.name  -- you could append a sequence number if needed
				local hlprInstance = instance donorObj

				append newDockingPoints hlprInstance  -- add the new instance to our array

				hlprInstance.name = hlprName
				hlprInstance.wireColor = helperColor
				hlprInstance.parent = undefined
				-- Notice: no "select" call inside the loop!
			)
		)

		select newDockingPoints  -- select all the new docking points at once
		redrawviews()
	)

	on btnAutoHierarchy pressed do undo on
	(
		local layersToProcess = #()

		if chkDupAllVisibleLayers.checked then
		(
			for li = 0 to (layerManager.count - 1) do
			(
				local lyr = layerManager.getLayer li
				if not lyr.isHidden and not (skipNoLayer lyr) do append layersToProcess lyr
			)
		)
		else
		(
			append layersToProcess layerManager.current
		)

		local topParents = #()
		for lyr in layersToProcess do
		(
			local result = organizeLayerHierarchy lyr
			if result != false do append topParents result
		)

		if topParents.count == 0 then
		(
			messageBox "No DP_C_ Docking Point found in the layer(s) to organize." title:"DP Auto Hierarchy"
		)
		else
		(
			select topParents
			redrawviews()
			format "DP Auto Hierarchy organized % layer(s).\n" topParents.count
		)
	)

-- Docking Point selection utilities
	group "Docking Point Selection"
	(
		button btnSelFamily "Select Family" width:130 height:30 across: 2
			tooltip:"This will select the Parent Docking Point, and all Sibling Docking Points."
		button btnSelParent "Select Parent(s)" width:130 height:30
			tooltip:"This will select the Parent Docking Point of the selection."
		button btnSelSiblings "Select Children" width:130 height:30 across: 2
			tooltip:"This will select the Sibling and/or Child Docking Points of the selection."
		button btnSelHelperColor "Select Color" width:130 height:30
			tooltip:"This will select all Docking Points and Helpers with the same color of the selection."
		checkbox chkIncludeHidden "Include Hidden" across: 2
			tooltip:"Check this if you want the selections to include hidden items."
		button btnSelectDPWithNumber "Select DP with Sequence" width:130 height:30
			tooltip:"Selects Docking Point helpers that have end with a number, which happens when a copy or instance is made using the default 3ds Max tools."
		checkbox chkExactMatch "Use Exact Match Only" checked:true offset:[0,-19]
			tooltip:"When checked, only exact Docking Point names will be selected. Uncheck to include suffixes like _Turnout or _001."
	)

	on btnSelectDPWithNumber pressed do undo on
	(
		local dpHelpersWithNumbers = #()
		local includeHidden = chkIncludeHidden.checked
		-- require names that start with DP_ and END with 3 or more digits
		local regex = dotNetObject "System.Text.RegularExpressions.Regex" @"^DP_.*\d{2,}$"

		for obj in helpers where isKindOf obj Point do
		(
			if (regex.IsMatch obj.name) and (includeHidden or not obj.isHidden) do
			(
				append dpHelpersWithNumbers obj
			)
		)

		if dpHelpersWithNumbers.count > 0 then
		(
			select dpHelpersWithNumbers
			format "Selected % helper(s) with DP_ prefix and 3+ digit sequence at the end.\n" dpHelpersWithNumbers.count
		)
		else
		(
			messageBox "No matching Docking Point helpers found." title:"Info"
		)
	)

	on btnSelFamily pressed do undo on
	(
		for obj in selection where ((isKindOf obj Helper or classof obj == Dummy)) do
		(
			if (matchPattern obj.name pattern:"DP_C_*" or matchPattern obj.name pattern:"DP_P_*") then
			(
				local baseName = substituteString (substituteString obj.name "DP_C_" "") "DP_P_" ""
				local matchingHelpers = #()

				local includeHidden = chkIncludeHidden.checked
				for h in helpers where ((isKindOf h Helper or classof h == Dummy) and (includeHidden or not h.isHidden)) do
				(
					if chkExactMatch.checked then
					(
						if h.name == ("DP_C_" + baseName) or h.name == ("DP_P_" + baseName) do
							appendIfUnique matchingHelpers h
					)
					else
					(
						if matchPattern h.name pattern:("DP_C_" + baseName + "*") or matchPattern h.name pattern:("DP_P_" + baseName + "*") do
							appendIfUnique matchingHelpers h
					)
				)

				if matchingHelpers.count > 0 then select matchingHelpers
			)
		)
	)
	on btnSelParent pressed do undo on
	(
		local allMatchingParents = #()

		for obj in selection where ((isKindOf obj Helper or classof obj == Dummy)) do
		(
			if (matchPattern obj.name pattern:"DP_C_*" or matchPattern obj.name pattern:"DP_P_*") then
			(
				local baseName = substituteString (substituteString obj.name "DP_C_" "") "DP_P_" ""

				local includeHidden = chkIncludeHidden.checked
				for h in helpers where ((isKindOf h Helper or classof h == Dummy) and (includeHidden or not h.isHidden)) do
				(
					if chkExactMatch.checked then
					(
						if h.name == ("DP_P_" + baseName) do appendIfUnique allMatchingParents h
					)
					else
					(
						if matchPattern h.name pattern:("DP_P_" + baseName + "*") do appendIfUnique allMatchingParents h
					)
				)
			)
		)

		if allMatchingParents.count > 0 then
			select allMatchingParents
		else
			messageBox "No parent helpers found for the selected children."
	)
	on btnSelSiblings pressed do undo on
	(
		local allMatchingHelpers = #()

		for obj in selection where ((isKindOf obj Helper or classof obj == Dummy)) do
		(
			if (matchPattern obj.name pattern:"DP_C_*" or matchPattern obj.name pattern:"DP_P_*") then
			(
				local baseName = substituteString (substituteString obj.name "DP_C_" "") "DP_P_" ""

				local includeHidden = chkIncludeHidden.checked
				for h in helpers where ((isKindOf h Helper or classof h == Dummy) and (includeHidden or not h.isHidden)) do
				(
					if chkExactMatch.checked then
					(
						if h.name == ("DP_C_" + baseName) do appendIfUnique allMatchingHelpers h
					)
					else
					(
						if matchPattern h.name pattern:("DP_C_" + baseName + "*") do appendIfUnique allMatchingHelpers h
					)
				)
			)
		)

		if allMatchingHelpers.count > 0 then
			select allMatchingHelpers
	)

	on btnSelHelperColor pressed do undo on
	(
		local obj = selection[1]
		local wirecolor = obj.wireColor

		for obj in selection where ((isKindOf obj Helper or classof obj == Dummy)) do
		(
			local wc = obj.wireColor
			local includeHidden = chkIncludeHidden.checked
			for o in objects where (o.wireColor == wc) and (isKindOf o Helper or classof o == Dummy) and (includeHidden or not o.isHidden) do
			(
				selectMore o
			)
		)
	)	
	
-- Docking Point color assignment
	group "Docking Point Color Assignment"
	(
		button btnAssignRandomColor "Same Random Color" width:130 height:30 across: 2
			tooltip: "Assign the same random color to selection."
		button btnAssignDefaultColor "Default Color" width:130 height:30
			tooltip: "Assign the default helper color to selection."
		button btnAssignColorOfFirstSel "Color Of 1st Selected" width: 270 height:30
			tooltip: "This will assign the color of the first selected object to the rest of the Docking Points."
	)
	on btnAssignRandomColor pressed do undo on
	(
		helperColor = getRandomColor()
		for obj in selection do
		(
			if (isKindOf obj Point) do
			(
				obj.wireColor = helperColor
			)
		)
	)
	
	on btnAssignDefaultColor pressed do undo on
	(
		helperColor = color (14) (255) (2)
		for obj in selection do
		(
			if (isKindOf obj Point) do
			(
				obj.wireColor = helperColor
			)
		)
	)
	
	on btnAssignColorOfFirstSel pressed do undo on
	(
		local donorObj = selection[1]
		local helperColor = donorObj.wireColor
		for obj in selection do
		(
			if (isKindOf obj Point) do
			(
				obj.wireColor = helperColor
			)
		)
	)
	
-- Align helper to hole
	group "Align Helper"
	(
		checkbutton btnAlign "Align Helper to Hole" width:130 height:30 align:#center across: 2
			tooltip: "Select 3 vertices to align helper to hole. 1st vertex is +Y, 2nd is -Y, and the 3rd is the plane X Axis will align to."
		button btnFlipZ "Flip Z-Axis" width:130 height:30 align:#center
			tooltip: "This will flip the Z-Axis in the case that aligning the helper has Z in the wrong direction."
	)
	
	on btnAlign changed state do
	(
		-- Clear any previous markers to avoid displaying old labels
		global AlignHelperToHoleMarkers = #()

		-- Ensure correct selection first, and run the main logic inside the if block
		if selection.count == 1 and classOf selection[1] == Point then
		(
			local helper = selection[1]  -- The selected helper

			-- Enable 3D snapping for vertex selection
			local originalSnapMode = snapMode.active
			snapMode.active = true

			-- Register the viewport callback to draw the markers and lines
			unregisterRedrawViewsCallback drawCoords
			registerRedrawViewsCallback drawCoords

			-- Step 1: Pick the first vertex (start of hole) with 3D snapping
			local p1 = pickPoint prompt:"Select first vertex (start of hole, positive Y direction)" snap:#3D
			if classOf p1 == Point3 then
			(
				-- Add marker for the first point
				append AlignHelperToHoleMarkers (vertexData pos:p1 txt:"Y Axis +" col:[0,255,0]) -- Green for positive Y axis
				redrawViews()  -- Force viewport redraw to show the text

				-- Step 2: Pick the second vertex (end of hole) with rubberBand from the first vertex
				local p2 = pickPoint prompt:"Select second vertex (end of hole, negative Y direction)" snap:#3D rubberBand:p1
				if classOf p2 == Point3 then
				(
					-- Add marker for the second point
					append AlignHelperToHoleMarkers (vertexData pos:p2 txt:"Y Axis -" col:[0,255,0]) -- Green for negative Y axis
					redrawViews()  -- Force viewport redraw to show the text and line

					-- Step 3: Pick the third vertex (tangent to hole opening) with rubberBand from midpoint
					local midpoint = calculateMidpoint p1 p2

					-- Move helper to midpoint after selecting -Y vertex
					(
						-- Temporary definition of p3 to move helper to midpoint
						local p3 = [0, 0, 0]

						-- Align the helper based on the selected points
						alignHelperToHole helper p1 p2 p3

						-- Force move tool and local coordinate system
						actionMan.executeAction 0 "50001"  -- Tools: Select and Move
						macros.run "Coordinate System" "Coordsys_Local"

						-- Force the viewport to redraw and display the aligned helper
						redrawViews()
					)

					local p3 = pickPoint prompt:"Select third vertex (for X-axis alignment)" snap:#3D rubberBand:midpoint
					if classOf p3 == Point3 then
					(
						-- Add marker for the third point
						append AlignHelperToHoleMarkers (vertexData pos:p3 txt:"X Axis" col:[255,0,0]) -- Red for X axis
						redrawViews()  -- Force viewport redraw to show the text and line

						-- Align the helper based on the selected points
						alignHelperToHole helper p1 p2 p3

						-- Restore snap settings
						snapMode.active = originalSnapMode

						-- Force the viewport to redraw and display the aligned helper
						redrawViews()

						-- Unregister the viewport callback and clear markers once done
						unregisterRedrawViewsCallback drawCoords
						AlignHelperToHoleMarkers = #()  -- Clear markers at the end
						redrawViews()
					)
					else
					(
						-- Error handling if third vertex is not valid
						messageBox "Invalid point selection for X-axis alignment. Aborting."
					)
				)
				else
				(
					-- Error handling if second vertex is not valid
					messageBox "Invalid point selection for Y-axis negative direction. Aborting."
				)
			)
			else
			(
				-- Error handling if first vertex is not valid
				messageBox "Invalid point selection for Y-axis positive direction. Aborting."
			)

			-- Clean up the snap settings and unregister the viewport callback
			snapMode.active = originalSnapMode
			unregisterRedrawViewsCallback drawCoords
		)
		else
		(
			-- Error handling for incorrect selection
			messageBox "Please select one Point helper before running this script."
		)

		btnAlign.checked = false
	)
	
	on btnFlipZ pressed do
	(
		if selection.count != 1 or classOf selection[1] != Point then
        (
            messageBox "Please select one Point helper!"
        )
		else
		(
			local helper = selection[1]
			reverseZAxis helper
			redrawViews()  -- Redraw after rotating
		)
	)
	
-- Remove number sequence from name
	group "Misc Utilities"
	(
		button btnRemoveSequence "Remove trailing # from Docking Point name" width: 130 height:30 across:2 align:#center
			tooltip:"WARNING: This will remove the numerical sequence from the end of helper's name."
		
		button btnCreateGroupFromSel "Create Group from Selection" width:130 height:30 align:#center
			tooltip:"Creates a group from the current selection and allows naming it."
		
		button btnDrawOnTopOn  "Turn Draw On Top ON"  width:130 height:30 across:2 align:#center
		button btnDrawOnTopOff "Turn Draw On Top OFF" width:130 height:30 align:#center
		checkbox chkAll "Affect ALL Helpers (Draw On Top) in Scene" checked:false align:#center
			tooltip:"If enabled, applies to every Helper in the scene. If disabled, affects selected Helpers only."

		button btnConvertDummy "Convert Dummy" width:270 height:30 align:#center
			tooltip:"Converts Dummy objects with a DP_ prefix back into Point helpers (FBX reimport turns Point helpers into Dummies). Name, position, hierarchy, layer, and wire color are kept. DP_C_/DP_DIM_ get the Child DP Display settings, DP_P_ gets the Parent DP Display settings, and other DP_ prefixes (DP_SF_, DP_ST_, etc.) keep the default Point display. Works on selection; if no DP Dummies are selected it can convert the whole scene."
	)
	fn getTargetHelpers =
    (
        if chkAll.checked then
            for o in objects where superclassof o == Helper collect o
        else
            for o in selection where superclassof o == Helper collect o
    )

    fn setDrawOnTop state =
    (
        local targets = getTargetHelpers()

        for obj in targets do
        (
            if isProperty obj #drawOnTop then
            (
                try
                (
                    obj.drawOnTop = state
                )
                catch()
            )
        )
    )
    on btnDrawOnTopOn pressed do ( setDrawOnTop true )
    on btnDrawOnTopOff pressed do ( setDrawOnTop false )

	-- Collects Dummy objects with a DP_ prefix (DP_C_, DP_P_, DP_DIM_, DP_SF_, DP_ST_, etc.).
	-- Group heads are Dummies too, so the name filter is what keeps this from destroying groups.
	fn getDPDummies sourceObjs =
	(
		for o in sourceObjs where
		(
			classof o == Dummy and not isGroupHead o and
			matchPattern o.name pattern:"DP_*"
		) collect o
	)

	on btnConvertDummy pressed do undo "Convert Dummy" on
	(
		local targetDummies = getDPDummies selection

		if targetDummies.count == 0 do
		(
			if queryBox "No DP_ Dummy objects in the selection.\n\nConvert every DP_ Dummy in the scene?" title:"Convert Dummy" then
				targetDummies = getDPDummies objects
			else
				return()
		)

		if targetDummies.count == 0 then
		(
			messageBox "No Dummy objects with a DP_ prefix found." title:"Convert Dummy"
		)
		else
		(
			local childSize = spnHelperSize.value
			local parentSize = spnHelperSize.value * spnParentMult.value

			for d in targetDummies do
			(
				-- Swap the base object to a Point so the node keeps its name, transform,
				-- hierarchy, layer, and wire color. A fresh point per Dummy avoids
				-- accidentally instancing them all together.
				local pnt = point()
				d.baseObject = pnt.baseObject
				delete pnt

				-- Only child/DIM/parent DPs get the display settings from the UI. Other DP_
				-- prefixes (DP_SF_, DP_ST_, ...) keep the default Point helper display.
				if matchPattern d.name pattern:"DP_P_*" then
					setDockingPointProperties d parentSize chkParentCenterMarker.checked chkParentAxisTripod.checked chkParentCross.checked chkParentBox.checked chkParentDrawTop.checked d.wireColor
				else if (matchPattern d.name pattern:"DP_C_*" or matchPattern d.name pattern:"DP_DIM_*") then
					setDockingPointProperties d childSize chkChildCenterMarker.checked chkChildAxisTripod.checked chkChildCross.checked chkChildBox.checked chkChildDrawTop.checked d.wireColor
			)

			select targetDummies
			redrawviews()
			format "Converted % Dummy object(s) to Point helpers.\n" targetDummies.count
		)
	)

	on btnRemoveSequence pressed do
	(
		-- Display a warning dialog
		if queryBox "This will remove the numerical sequence from the end of the helper's name. Do you want to continue?" title:"Warning" do
		(
			-- If the user clicks "Yes", run the code inside this block
			undo "Remove Number Sequence" on
			(
				for obj in selection where (isKindOf obj Point) do
				(
					local newName = trimNonChar obj.name
					format "Renaming % to %\n" obj.name newName
					obj.name = newName
				)
			)
		)
		-- If the user clicks "No", nothing happens and the script does not run
	)
	on btnCreateGroupFromSel pressed do undo on
	(
		local toGrpArray = selection as array
		if toGrpArray.count == 0 then
		(
			messagebox "Please select at least one object to group."
			return()
		)

		local firstObj = toGrpArray[1]
		local invalidObjects = #()

		for obj in toGrpArray do
		(
			if isGroupMember obj or obj.parent != undefined do
			(
				append invalidObjects obj
			)
		)

		if invalidObjects.count > 0 do
		(
			local answer = yesNoCancelBox "Some object(s) are children. Yes to unlink, No to exclude, or Cancel the group creation" Title:"Objects with parents detected!" beep:false
			case answer of
			(   
				(#yes): for obj in invalidObjects do
				(
					setGroupMember obj false
					obj.parent = undefined
				)
				(#no): toGrpArray = for obj in toGrpArray where (obj.parent == undefined) collect obj
				(#cancel): return()
			)
		)

		groupNameEntered = undefined
		groupNameDialogOpen = true
		groupNameDefault = firstObj.name

		try (destroyDialog grpNameRollout) catch()
		createDialog grpNameRollout 250 80 style:#(#style_titlebar, #style_sysmenu)

		while groupNameDialogOpen do (windows.processPostedMessages())

		if groupNameEntered == undefined then return()

		local groupName = groupNameEntered
		sphere radius:10 name:"TEMP" segs:12 isSelected:on
		local newGroup = group $ name:groupName

		newGroup.transform = firstObj.transform
		attachNodesToGroup toGrpArray newGroup
		delete $TEMP
		setGroupOpen newGroup true
		setGroupOpen newGroup false
		select newGroup

		messagebox ("Created group \"" + groupName + "\" with " + toGrpArray.count as string + " objects.") beep:false
	)
	

	fn defColor r g b = (dotNetClass "System.Drawing.Color").FromArgb r g b
	fn defFontB fName fSize = (dotNetObject "System.Drawing.Font" fName fSize ((dotNetClass "System.Drawing.FontStyle").bold))
	on helperRollout open do
	(
		-- UI Setup for Tacton Tools title block
		lblTitle.text = "Tacton Tools"
		lblTitle.textAlign = lblTitle.textAlign.MiddleCenter
		lblTitle.font = defFontB "Verdana" 10
		lblTitle.backColor = defColor 77 77 240
		lblTitle.foreColor = defColor 255 255 255
		
	)

)

helperRolloutRef = helperRollout -- Store a reference to the helperRollout
createDialog helperRollout
