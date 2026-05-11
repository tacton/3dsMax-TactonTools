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
© Copyright 2024 Tacton Systems AB

22/04/2024: V1.4 Added checkbox to exclude hidden objects, default is on. Added check box to use the FBX Export dialog to change settings if needed, default off. Added in a button to change the export directory so it does not have to be
			set every time the script is run or the button pressed. This allows the script to remain open, and just having to press the Export Layers button.
09/09/2025: V1.5 Added checkbox to do a gamma correction on export, sRGB Encode Colors (temp). This is for 3ds Max 2024 and newer with the new Color Management Mode which introduced Scene (linear colors) and Display (corrected colors).
			For example: if working	in Gamma 2.2, when exported it will use the Scene colors at Gamma 1.0, which ends up being too dark in VIZstudio. This will apply 2.2 gamma to the colors of materials without texture maps, are revert
			the colors back after the export is done.
*/

macroScript exportLayers
	category:"Tacton Tools"
	buttontext:"Exp Layers"
	tooltip:"Export Layers v1.7"

(
    try(DestroyDialog layerFBXexporter) catch()
    versionLE = "Layer FBX Exporter v1.7"

    /* ===== sRGB encode helpers (Physical + Standard) ================== */
    global __colBackups = #()
    global __processedMats = #()
	global __OpenPBR_Class = undefined
	global __progBarColor = yellow
	try ( __OpenPBR_Class = getClassByName "OpenPBR_Material" ) catch()

    struct ColBackup (mat, prop, value)

    fn srgbEncodeColor c =
    (
        local r = (amax 0 (amin 255 c.r))/255.0
        local g = (amax 0 (amin 255 c.g))/255.0
        local b = (amax 0 (amin 255 c.b))/255.0
        local gamma = 1.0/2.2
        color ((pow r gamma)*255.0) ((pow g gamma)*255.0) ((pow b gamma)*255.0)
    )

    fn encodeMaterialColor m =
    (
        -- process each unique material instance once
        if (findItem __processedMats m) != 0 do return()
        append __processedMats m

        if isKindOf m PhysicalMaterial then
        (
            local hasMap = false
            try ( if (m.base_color_map != undefined) then hasMap = true ) catch()
            if not hasMap do
            (
                append __colBackups (ColBackup m #base_color m.base_color)
                m.base_color = srgbEncodeColor m.base_color
            )
        )
        else if isKindOf m Standardmaterial then
        (
            local hasMap = false
            try (
                if (m.diffuseMap != undefined) and m.mapDiffuse do hasMap = true
            ) catch()
            if not hasMap do
            (
                append __colBackups (ColBackup m #diffuse m.diffuse)
                m.diffuse = srgbEncodeColor m.diffuse
            )
        )
		else if isKindOf m OpenPBR_Material then
		(
			local hasMap = false
			try (
				-- treat as mapped only if a map is assigned AND enabled
				if (m.base_color_map != undefined) and m.base_color_map_on do hasMap = true
			) catch()

			if not hasMap do
			(
				append __colBackups (ColBackup m #base_color m.base_color)
				m.base_color = srgbEncodeColor m.base_color
			)
		)

		
    )

    fn traverseAndEncode mats =
    (
        for m in mats where isKindOf m Material do
        (
            encodeMaterialColor m

            local n = 0
            try (n = getNumSubMtls m) catch()
            if n > 0 do
            (
                local subs = #()
                for i=1 to n do ( try (append subs (getSubMtl m i)) catch() )
                if subs.count > 0 do traverseAndEncode subs
            )
        )
    )

    fn rollbackColors =
    (
        for rec in __colBackups do
            try (setProperty rec.mat rec.prop rec.value) catch()
        __colBackups = #()
        __processedMats = #()
    )
    /* ================================================================== */

    global exportDir

    rollout layerFBXexporter versionLE
    (
		dotNetControl lblTitle "Label" pos:[2,2] width:456 height:30
		
        group "Export Layers"
        (
            
            checkbox cb_useFBXDialog "Use the FBX Export Dialog" align:#center offset:[0,0] across:2 tooltip:"Check this box if you need to change FBX settings on export."
            checkbox cb_excludeHidden "Exclude Hidden Objects" checked:true offset:[12,0] tooltip:"Keep this checked if you don't want objects hidden in the layers to be included in the exported FBX."
            checkbox cb_turnOffNo "Turn Off 'NO_' Layers" checked:true offset:[33,0]across:2 tooltip:"Automatically disable all layers prefixed with 'NO_' before exporting."
            checkbox cb_gammaEncode "sRGB Encode Colors (temp)" checked:false offset:[12,0] tooltip:"Temporarily encode Physical base color & Standard diffuse to sRGB for export (skips mapped slots), then restore."
			button btn_export "Export Layers" width:200 height:30
			progressbar pb_exportProgress "Progress" width:420 height:18 color:__progBarColor align:#center

        )
        group "Export Directory"
        (
            button btn_setDir "Set Export Directory" width:200 height:30
            label lbl_dir "Export Directory Not Set" width:420 align:#left
        )
        --label typeAbout01 versionLE

        on layerFBXexporter open do
        (
			pb_exportProgress.value = 0
            if exportDir != undefined then
            (
                lbl_dir.text = exportDir
                print ("Export Directory: " + lbl_dir.text)
            )
        )

        on btn_setDir pressed do
        (
            exportDir = getSavepath initialDir:"C:\\data_import_auto\\"
            if exportDir != undefined do lbl_dir.text = exportDir
        )

        on btn_export pressed do
        (
			--disableSceneRedraw()
            local needRollback = false
			local exportedLayers = 0
            try
            (
                -- Close conflicting dialogs
                if MatEditor.isOpen() do MatEditor.Close()
                if LayerManager.isDialogOpen() do
                (
                    LayerManager.closeDialog()
                    macros.run "Scene Explorer" "SELayerExplorer"
                )

                if exportDir == undefined then
                (
                    messagebox "Please set the export directory first!" title:"Layer Exporter Warning"
                    --return
                )

                -- Optionally disable NO_ layers
                if cb_turnOffNo.checked then
                (
                    for i = 1 to LayerManager.count do
                    (
                        local lay = LayerManager.getLayer i
                        if (lay != undefined) and matchPattern lay.name pattern:"NO_*" then
                            lay.on = false
                    )
                    redrawViews()
                    print "Disabled all 'NO_' layers."
                )

                -- Apply temporary sRGB encoding if requested
                if cb_gammaEncode.checked then
                (
                    __colBackups = #()
                    __processedMats = #()
                    traverseAndEncode (for m in scenematerials collect m)
                    needRollback = true
                    print "Applied temporary sRGB encoding to scene materials."
                )

                undo off
                local dir = exportDir
                print dir

                -- Collect visible layers
                local visibleLayers = #()
                for i = 1 to (LayerManager.count) do
                (
                    local layer = LayerManager.getLayer i
                    if layer != undefined and layer.on then append visibleLayers layer
                )

                print ("Number of visible layers: " + visibleLayers.count as string)

                if visibleLayers.count == 0 then
                (
                    messagebox "Please have at least one layer turned on!" title:"Layer Exporter Warning"
                    --return
                )

                -- Export each layer
                local useDialog = 0
                local cancelExport = false
				
				
				local totalLayers = visibleLayers.count
				local currentLayer = 0

				for layer in visibleLayers where not cancelExport do
				(
					currentLayer += 1
					pb_exportProgress.value = (currentLayer as float / totalLayers) * 100.0
               
					layer.select true
                    -- Gather objects based on visibility
                    local objs = if cb_excludeHidden.checked then
                        for o in selection where not o.isHidden collect o
                    else
                        selection

                    print ("'" + layer.name + "' visible objects to be exported = " + objs.count as string)
                    print ("'" + layer.name + "' hidden objects = " + (selection.count - objs.count) as string)

                    if objs.count > 0 then
                    (
                        select objs
                        local filename = dir + "\\" + layer.name + ".fbx"
                        print filename
						exportedLayers +=1

                        if useDialog < 1 and cb_useFBXDialog.checked then
                        (
                            useDialog += 1
                            if exportFile filename selectedOnly:true == false then
                            (
                                print "Export canceled by user."
                                cancelExport = true
                            )
                        ) else
                        (
                            if exportFile filename #noPrompt selectedOnly:true == false then
                            (
                                print "Export canceled by user."
                                cancelExport = true
                            )
                        )
                    ) else
                        print ("No visible objects to export in layer '" + layer.name + "'.")

                    clearSelection()
					
                )
				
            )
            catch
            (
                if needRollback do
                (
                    rollbackColors()
                    print "Error during export; restored original material colors."
                )
            )

            if needRollback do
            (
                rollbackColors()
                print "Restored original material colors."
            )
			--enableSceneRedraw()
			pb_exportProgress
			redrawViews()
			messageBox ("Export complete.\n\nLayers exported: " + exportedLayers as string) title:"Layer Export Done"
        )
		fn defColor r g b = (dotNetClass "System.Drawing.Color").FromArgb r g b
		fn defFontB fName fSize = (dotNetObject "System.Drawing.Font" fName fSize ((dotNetClass "System.Drawing.FontStyle").bold))

		on layerFBXexporter open do
		(
			lblTitle.text = "Tacton Tools"
			lblTitle.textAlign = lblTitle.textAlign.MiddleCenter
			lblTitle.font = defFontB "Verdana" 10
			lblTitle.backColor = defColor 77 77 240
			lblTitle.foreColor = defColor 255 255 255
			
		)
    )

    createDialog layerFBXexporter width:460
)
