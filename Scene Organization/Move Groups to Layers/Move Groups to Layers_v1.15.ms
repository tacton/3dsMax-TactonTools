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
Move Groups to Layers

This script makes quick work of moving grouped assemblies to their own layer named after the group head.
- Select the group or groups that you would like to be moved to layers named after the group.
- A Custom Layer Name may be chosen instead, which means all selected groups will move to that custom named
layer instead of their own layer.
- Create Layer Within Active Layer places newly created or matched target layers under the currently active layer.
- Turning on Hide Created Groups helps free up the viewport space, and makes it easier to keep track of
groups that have already been processed visually.
- Select the radio button for how you want to handle objects that are hidden within the group. The
default is Detach Hidden, Move w/ Group.
- Press Process once you have the selections set.

A quick tool to Ungroup Top-Most Group is also provided. This is useful in extreme cases where there's
thousands of objects within a group, which happens in CAD imports where every sub-assembly group is within
a main group upon import. That scenario can make it so that just selecting the group takes from a few
minutes to over 10 minutes.
- To use, do not select the group that you want to ungroup, instead make sure the layer that the group is in
is active, then press Ungroup Top-Most Group. It will remove the top most group for each group that is in
that active layer.
WARNING: Make sure you that only the group or groups you want to remove the top level group is in
the active layers.

13/03/2025 - v1.0 Initial release.
01/28/2026 - v1.05 Bug fix. When Hide Created Groups is checked and Detach Hidden, Move w/ Group is selected
			the previous version would not detach the hidden objects, and move them with the group to the
			new layer. It now correctly detaches the hidden objects and moves them to the new layer.
03/26/2026 - v1.15 Added Create Layer Within Active Layer option to parent processed layers under the current active layer.
*/

try (DestroyDialog moveGroupsRollout) catch()

versionDH = "Move Groups to Layers v1.15"

-- Arrays to store hidden and visible objects
hiddenObjects = #()
visibleObjects = #()

-- Array to store top-level group heads
groupHeads = #()

-- Function to recursively add all children of an object to a layer
fn addChildrenToLayer obj layer =
(
    for child in obj.children do
    (
        layer.addNode child
        addChildrenToLayer child layer
    )
)

-- Function to collect hidden objects
fn collectHiddenObjects obj hiddenObjects =
(
    if superclassof obj == groupHead then
    (
        -- Open the group to access its members
        maxOps.collapsedGroupExplode obj
        for child in obj.children do
        (
            collectHiddenObjects child hiddenObjects
        )
        -- Recreate the group after processing its members
        maxOps.collapsedGroupMakeFrom obj.children
    )
    if obj.isHiddenInVpt then
    (
        append hiddenObjects obj
    )
)

-- Iterate over the selection
fn doCollectHiddenObj hiddenObjects groupHeads =
(
	for obj in selection do
		(
			-- Collect hidden objects
			collectHiddenObjects obj hiddenObjects

			-- If the object is not hidden, add it to the visibleObjects array
			if not obj.isHiddenInVpt then
			(
				append visibleObjects obj
			)

			-- If the object is a top-level group head, add it to the groupHeads array
			if isGroupHead obj then
			(
				local parent = obj.parent
				if parent == undefined or not isGroupHead parent do
				(
					append groupHeads obj
					--print groupHeads
				)
			)
		)

	-- Print hidden and visible arrays
-- 	format "Hidden objects: %\n" hiddenObjects
-- 	format "Visible objects: %\n" visibleObjects
)


fn doMoveToLayer groupHeads customLayerName hideLayer createLayerWithinActiveLayer =
(
    local activeLayer = undefined
    if createLayerWithinActiveLayer then
    (
        activeLayer = LayerManager.current
    )

    for obj in groupHeads do
    (
        -- Check if the group head still exists in the scene
        if isValidNode obj then
        (
            local newLayer
            if customLayerName != "" then
            (
                -- If custom layer name is provided, check if a layer with that name already exists
                newLayer = LayerManager.getLayerFromName customLayerName
                if newLayer == undefined then
                (
                    -- If not, create a new layer with the custom name
                    newLayer = LayerManager.newLayerFromName customLayerName
                )
            )
            else
            (
                -- If no custom layer name is provided, use the name of the top-level group head
                newLayer = LayerManager.getLayerFromName obj.name
                if newLayer == undefined then
                (
                    -- If not, create a new layer
                    newLayer = LayerManager.newLayerFromName obj.name
                )
            )

            if newLayer != undefined then
            (
                -- Parent the target layer under the active layer when requested.
                if createLayerWithinActiveLayer and activeLayer != undefined and newLayer != activeLayer then
                (
                    newLayer.setParent activeLayer
                )

                -- Move the top-level group head and all of its children to the new layer
                newLayer.addNode obj
                addChildrenToLayer obj newLayer

                if hideLayer then
                (
                    newLayer.on = false
                )
            )
        )
    )
)

-- Function to detach hidden objects or their parent group if they are hidden
fn detachHiddenObjects obj =
(
    if obj.isHiddenInVpt then
    (
        local parent = obj.parent
        if parent != undefined and isGroupHead parent then
        (
            -- Check if the parent group is visible
            if not parent.isHiddenInVpt then
            (
                -- Open the group
                setGroupOpen parent true

                -- Detach the object from its parent group
                detachNodesFromGroup obj
            )
        )
        else
        (
            -- Detach the object from its parent
            obj.parent = undefined
        )
    )
)

function closeGroups mySelection = 
(
	--loop into selected object
	for obj2 = mySelection do
	(
		--to find group and close it
		if isGroupHead obj2 then setGroupOpen obj2 false
	)
)

-- Function to collect all nodes in a layer
fn collectLayerNodes layer recurse:on nodes:#() = 
(
	layer.nodes &nn
	join nodes nn

	if recurse do
	(
		for k = 1 to layer.getnumchildren() do 
		(
			collectLayerNodes (layer.getChild k) recurse:on nodes:nodes
		)
	)
	nodes
)

-- Function to check if a group is a top-most group
fn isTopMostGroup obj =
(
	return (isGroupHead obj and (obj.parent == undefined or not isGroupMember obj.parent))
)

fn isTopMostGroupB obj =
(
	return (isGroupHead obj and (obj.parent == undefined))
)

-- Create a rollout
rollout moveGroupsRollout versionDH
(
	dotNetControl lblTitle "Label" pos:[2,2] width:296 height:30 -- Add Tacton Tools title block
    Group"Group Options"
    (       
        -- Define checkbox
        checkBox moveGroupToLayer "Move Group to Layer" checked:true align: #left across:2
        tooltip:"Leave checked to move the selected group(s) to layers. Can be unchecked if you want to process the hidden objects in the layer they currently reside."
		checkBox hideCreatedGroup "Hide Created Groups" align: #right
		tooltip: "Created layers will be hidden after groups are moved to them."
        checkBox useActiveLayerChk "Create Layer Within Active Layer" align: #left
		tooltip:"Create or use the target layer, then place that layer under the currently active layer."
        checkBox customLayerNameChk "Custom Layer Name" align: #left
		tooltip:"Check this to use the custom layer name entered below."
		editText customLayerNameTxt "" align: #left text:"Processed" enabled:false
		tooltip:"Enter custom layer name to move groups to."
        label type_IgnorePhyMat  "-------------------------------------------------------------------" enabled:false align: #center
        -- Define radio buttons
        radioButtons taskType "What happens to hidden objects?" labels:#("Detach Hidden, Move w/ Group", "Detach Hidden, Location Stays", "Keep Hidden in Group", "Delete Hidden") default:1 align: #left
        tooltip: "Delete hidden objects, detach hidden objects from selected group(s), keep hidden within group(s), or detach and move hidden objects with group(s)."

        -- Define a button to execute the tasks
        button executeButton "Process" width: 160
		tooltip: "Choose from the options above and select at least one group before processing."

        -- Execute tasks
        on executeButton pressed do
        (
			local resultsMessage = ""
			local groupSelected = false -- Flag to track if a group object is selected

			-- Check each selected object
			for obj in selection do
			(
				if isGroupHead obj do
				(
					groupSelected = true
					exit -- Exit the loop if a group object is found
				)
			)
			if groupSelected == false then
			(
				messageBox "Pick at least one group before running!"
			)
			else
			(
				-- Collect hidden objects and group heads
				doCollectHiddenObj hiddenObjects groupHeads

				-- Perform operations based on task type
				case taskType.state of
				(
					
					1: (
							-- Detach Hidden, Move w/ Group
							for obj in hiddenObjects do
							(
								detachHiddenObjects obj
							)
							-- Close all groups in the selection
							closeGroups selection

							-- Now move the groups to layers (if requested)
							if moveGroupToLayer.state then
							(
								local customLayerName = if customLayerNameChk.state then customLayerNameTxt.text else ""
								doMoveToLayer groupHeads customLayerName hideCreatedGroup.state useActiveLayerChk.state
							)

							-- Finalize
							resultsMessage = (hiddenObjects.count as string + " hidden objects were detached from their group.")
							deselect selection
						)
						
					2: (for obj in hiddenObjects do -- Detach Hidden, Location Stays
						(
							detachHiddenObjects obj
						)
						-- Close all groups in the selection
						closeGroups selection
-- 						messageBox (hiddenObjects.count as string + " objects were detached.")
						resultsMessage = (hiddenObjects.count as string + " hidden objects were detached from their group.")
-- 						hiddenObjects = #()
						deselect selection
						if moveGroupToLayer.state then
							(
								local customLayerName = if customLayerNameChk.state then customLayerNameTxt.text else ""
								doMoveToLayer groupHeads customLayerName hideCreatedGroup.state useActiveLayerChk.state
							)
					)
					
					3: ( -- Keep Hidden in Group
						resultsMessage = (hiddenObjects.count as string + " hidden objects were moved with their respective group.")
						if moveGroupToLayer.state then
							(
								local customLayerName = if customLayerNameChk.state then customLayerNameTxt.text else ""
								doMoveToLayer groupHeads customLayerName hideCreatedGroup.state useActiveLayerChk.state
							)						
					)
					
					4: (delete hiddenObjects -- Delete Hidden
-- 						messageBox (hiddenObjects.count as string + " objects were deleted.")
						resultsMessage = (hiddenObjects.count as string + " hidden objects were deleted from their group.")
-- 						hiddenObjects = #()
						deselect selection
						if moveGroupToLayer.state then
							(
								local customLayerName = if customLayerNameChk.state then customLayerNameTxt.text else ""
								doMoveToLayer groupHeads customLayerName hideCreatedGroup.state useActiveLayerChk.state
							)
					)
				)

				-- Move groups to layers if checkbox is checked
				
				print resultsMessage
				-- Clear the arrays
				hiddenObjects = #()
				visibleObjects = #()
				groupHeads = #()
-- 				deselect selection
			)
        )
		-- UI enable check
		on moveGroupToLayer changed state do
		(
			useActiveLayerChk.enabled = moveGroupToLayer.checked
			if moveGroupToLayer.checked == true do
			(
				customLayerNameChk.enabled = true
				hideCreatedGroup.enabled = true
			)
			if moveGroupToLayer.checked == true and customLayerNameChk.checked == true do
			(
				customLayerNameChk.enabled = true
				customLayerNameTxt.enabled = true
			)
			if moveGroupToLayer.checked == false do
			(
				useActiveLayerChk.enabled = false
				hideCreatedGroup.enabled = false
				customLayerNameChk.enabled = false
				customLayerNameTxt.enabled = false
			)
			if moveGroupToLayer.checked == false and taskType.state == 3 then
			(
				executeButton.enabled = false
			)
			else
			(
				executeButton.enabled = true
			)
		)
		on useActiveLayerChk changed state do
		(
			if moveGroupToLayer.checked == true then customLayerNameTxt.enabled = customLayerNameChk.checked
		)
		on customLayerNameChk changed state do
		(
			if customLayerNameChk.checked == true and moveGroupToLayer.checked == true then
			(
				customLayerNameTxt.enabled = true
			)
			else
			(
				customLayerNameTxt.enabled = false
			)
		)
		on taskType changed state do
		(
			if moveGroupToLayer.checked == false and taskType.state == 3 then
			(
				executeButton.enabled = false
			)
			else
			(
				executeButton.enabled = true
			)
		)

    )
    Group"Ungroup Top Group: Use Caution"
	(

		button btn_UngroupGroupHeads "Ungroup Top-Most Group" width: 160
		tooltip: "Of a selected layer, ungroup the top most group heads in hierarchies."

		on btn_UngroupGroupHeads pressed do
		(
			-- Get the active layer
			local activeLayer = LayerManager.current
			local objectsInActiveLayer = collectLayerNodes activeLayer
			local groupsToUngroup = #() -- Array to store groups that need to be ungrouped
			local ungroupedGroups = #() -- Array to store names of ungrouped groups

			-- First loop to identify all top-most groups
			for obj in objectsInActiveLayer do
			(
				if isTopMostGroupB(obj) then
				(
					append groupsToUngroup obj -- Add the group to the list for ungrouping
				)
			)

			-- Second loop to ungroup the identified groups
			for group in groupsToUngroup do
			(
				if isTopMostGroupB(group) then -- Check again to ensure it's still a top-most group
				(
					append ungroupedGroups group.name -- Add the name to the list of ungrouped groups
					ungroup group -- Ungroup the group
				)
			)

			-- Manually build the message string
			local resultStr = ""
			for groupName in ungroupedGroups do
			(
				resultStr += groupName + "\n"
			)

			-- Display a message box with the names of ungrouped groups
			if resultStr != "" then
			(
				messageBox ("The following groups were ungrouped:\n" + resultStr) title:"Ungrouped Groups"
			)
			else
			(
				messageBox "No groups were ungrouped." title:"Ungrouped Groups"
			)
		)
	)
	fn defColor r g b = (dotNetClass "System.Drawing.Color").FromArgb r g b
	fn defFontB fName fSize = (dotNetObject "System.Drawing.Font" fName fSize ((dotNetClass "System.Drawing.FontStyle").bold))
	on moveGroupsRollout open do
	(
		-- UI Setup for Tacton Tools title block
		lblTitle.text = "Tacton Tools"
		lblTitle.textAlign = lblTitle.textAlign.MiddleCenter
		lblTitle.font = defFontB "Verdana" 10
		lblTitle.backColor = defColor 77 77 240
		lblTitle.foreColor = defColor 255 255 255
		useActiveLayerChk.enabled = moveGroupToLayer.checked
		hideCreatedGroup.enabled = moveGroupToLayer.checked
		customLayerNameChk.enabled = moveGroupToLayer.checked
		customLayerNameTxt.enabled = moveGroupToLayer.checked and customLayerNameChk.checked
	)
    
)
-- Create a dialog to contain the rollout
createDialog moveGroupsRollout width:300
