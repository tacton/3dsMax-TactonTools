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
NO_ Layer Tools: Script for cleaning up generic object names generally found with CAD imports, or long object names with random characters. Also removes .prt and _MultiBodies suffixes.
01/10/2025 - v1.0 Release
12/08/2026 - v1.05 Added install-notification dialog (shown when the .mcr is dragged in / evaluated).
*/

macroscript NoLayers
	category:"Tacton Tools"
	buttontext:"NO_ Layer Tools"
	tooltip:"NO_ Layer Tools - Toggle Visibility"

(
	try (DestroyDialog toggleNOLayers) catch()
	versionTNL = "Toggle NO_ Layers v1.05"
	dialogWidth = 300
	buttonWidth = 130

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

	fn toggleLayersWithPrefix prefix state =
	(
		local layerCount = LayerManager.count
		local foundLayer = false
		for i = 1 to layerCount do
		(
			local layer = LayerManager.getLayer i
			if (layer != undefined) and matchPattern layer.name pattern:(prefix + "*") then
			(
				layer.on = state
				foundLayer = true
			)
		)
		
		if not foundLayer then
		(
			messageBox ("Create or rename a layer with a prefix of \"" + prefix + "\". Example: NO_MainBody.") title:"No Layer Found"
		)
		else
		(
			redrawviews()  -- Redraw the views once after all layers have been toggled
		)
	)

	fn selVisibleObjNoLayer prefix =
	(
		local layerCount = LayerManager.count
		local noLayers = #()
		local visibleNoObjects = #()
		
		for i = 1 to layerCount do
		(
			local layer = LayerManager.getLayer i
			if (layer != undefined) and matchPattern layer.name pattern:(prefix + "*") then
			(
				append noLayers layer.name
				-- Collect visible objects in this layer and its children
				local allNodes = collectLayerNodes layer recurse:on
				for obj in allNodes do
				(
					if obj.isHidden == false do
					(
						append visibleNoObjects obj
					)
				)
			)
		)
		
		if noLayers.count == 0 then
		(
			messageBox ("Create or rename a layer with a prefix of \"" + prefix + "\". Example: NO_MainBody.") title:"No Layer Found"
		)
		else if visibleNoObjects.count == 0 then
		(
			messageBox ("No visible objects found in layers that begin with a prefix \"" + prefix + "\".") title:"No Object Found"
		)
		else
		(
			select visibleNoObjects  -- Select the visible objects in the layers
			redrawviews()  -- Redraw the views after selecting objects
		)
	)

	rollout toggleNOLayers versionTNL
	(
		dotNetControl lblTitle "Label" pos:[2,2] width:(dialogWidth-4) height:30 -- Add Tacton Tools title block
		group""
		(
			button btnTurnOff "Turn Off NO_ Layers" width:buttonWidth align:#left across:2
				tooltip:"Turn off layers with the prefix NO_."
			button btnTurnOn "Turn On NO_ Layers" width:buttonWidth align:#right
				tooltip:"Turn on layers with the prefix NO_."
			button btnAddNoToLayer "Add NO_ to Marked" width: buttonWidth align:#left across:2
				tooltip: "This adds a prefix of NO_ to the layers that have Renderable set to FALSE."
			button btnAddNoToActive "Add NO_ to Active" width:buttonWidth align:#right
				tooltip:"Adds NO_ prefix to the currently active layer."
			button btnSelVisibleObjNoLayer "Select Visible NO_ Layer" width:buttonWidth align:#center
				tooltip:"Select visible objects in layers with a NO_ prefix."
		)
		-- label typeAbout01 versionTNL

		on btnTurnOff pressed do
		(
			toggleLayersWithPrefix "NO_" false
			
		)

		on btnTurnOn pressed do
		(
			toggleLayersWithPrefix "NO_" true
		)

		on btnSelVisibleObjNoLayer pressed do
		(
			selVisibleObjNoLayer "NO_"
		)
		
		on btnAddNoToLayer pressed do
		(
			undo "Add NO_ Prefix to Marked Layers" on
			(
				local renamedCount = 0
				for i = 1 to LayerManager.count do
				(
					local layer = LayerManager.getLayer i
					if layer != undefined and isProperty layer #renderable and not layer.renderable then
					(
						if not matchPattern layer.name pattern:"NO_*" ignoreCase:true then
						(
							local realLayer = LayerManager.getLayerFromName layer.name
							if realLayer != undefined do
							(
								realLayer.setName ("NO_" + layer.name)
								renamedCount += 1
							)
						)
					)
				)
				messageBox (renamedCount as string + " layers renamed with 'NO_' prefix.")
			)
		)
		on btnAddNoToActive pressed do
		(
			undo "Add NO_ Prefix to Active Layer" on
			(
				local currentLayer = LayerManager.current
				if currentLayer != undefined then
				(
					if not matchPattern currentLayer.name pattern:"NO_*" ignoreCase:true then
					(
						local newName = "NO_" + currentLayer.name

						-- Ensure no duplicate layer name
						if LayerManager.getLayerFromName newName == undefined then
						(
							currentLayer.setName newName
							messageBox ("Active layer renamed to: " + newName)
						)
						else
						(
							messageBox ("A layer named '" + newName + "' already exists. Rename skipped.")
						)
					)
					else
					(
						messageBox ("Active layer already has a 'NO_' prefix.")
					)
				)
				else
				(
					messageBox "No active layer found."
				)
			)
		)


		
		fn defColor r g b = (dotNetClass "System.Drawing.Color").FromArgb r g b
		fn defFontB fName fSize = (dotNetObject "System.Drawing.Font" fName fSize ((dotNetClass "System.Drawing.FontStyle").bold))
		on toggleNOLayers open do
		(
			-- UI Setup for Tacton Tools title block
			lblTitle.text = "Tacton Tools"
			lblTitle.textAlign = lblTitle.textAlign.MiddleCenter
			lblTitle.font = defFontB "Verdana" 10
			lblTitle.backColor = defColor 77 77 240
			lblTitle.foreColor = defColor 255 255 255
		)
	)

	createDialog toggleNOLayers width:dialogWidth height:140
)


-------------------------------------------------------------------------------
-- INSTALL NOTIFICATION
-- Runs only when this .mcr file is evaluated (dragged into a viewport or run
-- from the Scripting menu). Only the macroscript block above is persisted to
-- the usermacros folder, so this notice does NOT re-appear on every 3ds Max
-- startup -- it shows once, at install time.
-------------------------------------------------------------------------------
(
	rollout noLayersInstallNotice "Macro Installed"
	(
		dotNetControl lblHdr "Label" pos:[4,4] width:312 height:28

		label lbl_done  "The 'NO_ Layer Tools' macroscript was installed." align:#center offset:[0,8]
		label lbl_done2 "If it is not yet on a toolbar, you will need to add it:" align:#center offset:[0,2]

		group "Customize User Interface"
		(
			label lbl_step1 "1.   Customize  >  Customize User Interface" align:#left offset:[4,2]
			label lbl_step2 "2.   Open the 'Toolbars' tab" align:#left offset:[4,2]
			label lbl_step3 "3.   Set the Category to 'Tacton Tools'" align:#left offset:[4,2]
			label lbl_step4 "4.   Drag 'NO_ Layer Tools' onto any toolbar" align:#left offset:[4,2]
		)

		button btn_close "Close" width:90 height:24 offset:[0,10]

		fn niceColor r g b = (dotNetClass "System.Drawing.Color").FromArgb r g b

		on noLayersInstallNotice open do
		(
			lblHdr.text = "NO_ Layer Tools  v1.05"
			lblHdr.textAlign = lblHdr.textAlign.MiddleCenter
			lblHdr.font = dotNetObject "System.Drawing.Font" "Verdana" 10 ((dotNetClass "System.Drawing.FontStyle").bold)
			lblHdr.backColor = niceColor 77 77 240
			lblHdr.foreColor = niceColor 255 255 255
		)

		on btn_close pressed do ( DestroyDialog noLayersInstallNotice )
	)

	try ( DestroyDialog noLayersInstallNotice ) catch ()
	createDialog noLayersInstallNotice width:320
)