/*
MIT License

Copyright (c) 2021 Tacton Systems

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
Material Sorting by Prefix
© Copyright 2024 Tacton Systems AB


Material Sorting by Prefix. The purpose of this Maxscript is to place a folder structure prefix in front of the material name. It is used
for importing into Tacton VIZstudio, where the material will be placed into the directory according to the folder index in the material name.
It can also be used to add any other styled prefix, but note that Remove Prefix will only remove prefixes with a folder structure,
ie "materials/metal/AnodizedAluminum" will turn into "AnodizedAluminum", it won't do anything to materials named "materials_metal_AnodizedAluminum".

List Unused Sub-Materials purpose is to sort through Multi/Sub-Object materials with large amounts of Sub-Materials. It will display a popup with
all of the Sub-Materials that are not used. Please noted that it can take a while to run on larger scenes, as it needs to evaluate all objects and
Sub-Materials to find the IDs that are not used. Adding the UNUSED/ prefix is recommended for when importing the results into Tacton VIZstudio,
as it will then put these materials that will get imported into that folder that then can be easily deleted. The UNUSED/ prefix can be quickly
removed by selecting the material with the prefix, and clicking the Remove UNUSED/ button.

Version History

v1.0 - 21/06/2025 Initial release.
v1.1 - 26/09/2025 Change the location where the list is stored to where the script is located. This is so that it can be used across mutliple
			versions of 3ds Max instead of finding it in the user directory for each version of 3ds Max. Sorting now is case agnostic.

*/

try(DestroyDialog prefixRollout) catch()
try(DestroyDialog UnusedMaterialsRollout) catch()
-- Global variable to store the current file path
global currentFilePath = ""
global multiMatName
versionMSbP = "Material Sorting by Prefix v1.2"

-- Function to save the dropdown list items to a file
fn saveDropdownListItems ddl_prefixes filePath =
(
    -- Open the file for writing
    file = createfile filePath

    -- Write each item to the file
    for item in ddl_prefixes.items do
    (
        format "%\n" item to:file
    )

    -- Close the file
    close file
)

-- Function to load the dropdown list items from a file
fn loadDropdownListItems ddl_prefixes filePath =
(
    -- Check if the file exists
    if (doesFileExist filePath) then
    (
        -- Open the file for reading
        file = openfile filePath

        -- Clear the existing items
        ddl_prefixes.items = #()

        -- Read each line from the file
        while not eof file do
        (
            -- Read the line
            line = readline file

            -- Add the line to the dropdown list items
            append ddl_prefixes.items line
        )

        -- Close the file
        close file

        -- Update the dropdown list UI
        ddl_prefixes.items = ddl_prefixes.items
    )
    else
    (
        -- If the file does not exist, create it
        saveDropdownListItems ddl_prefixes filePath
    )
)

-- Function to determine which Material Editor is in use
fn getMaterialEditorType =
(
    if (sme.isOpen()) then
        return "Slate"
    else if (MatEditor.isOpen()) then
        return "Compact"
    else
        return undefined
)

-- Function to get the selected material in the Compact Material Editor
fn getSelectedMaterialCompact =
(
    medit.GetCurMtl()
)

-- Function to get the selected material in the Slate Material Editor
fn getSelectedMaterialSlate =
(
    -- Get the active view
    viewNode = sme.GetView(sme.activeView)
    
    -- Get the selected nodes
    selectedNodes = viewNode.GetSelectedNodes()
    
    -- Get the first selected node
    firstSelectedNode = if selectedNodes.count > 0 then selectedNodes[1] else undefined
    
    -- Access the reference of the first selected node
    if firstSelectedNode != undefined then
        return firstSelectedNode.reference
    else
        return undefined
)

-- Function to get the selected sub-material index within a Multi/Sub-Object material
fn getSelectedSubMaterialIndex mat selectedMat =
(
    if (classof mat == Multimaterial) then (
        for i = 1 to mat.numsubs do (
            if (mat.materialList[i] == selectedMat) then (
                return i
            )
        )
    )
    return undefined
)

-- Main function to get the selected material
fn getSelectedMaterial =
(
    editorType = getMaterialEditorType()
    
    if (editorType == "Compact") then
        return getSelectedMaterialCompact()
    else if (editorType == "Slate") then
        return getSelectedMaterialSlate()
    else
        return undefined
)

fn getSubMaterialByName multiMat matName =
(
    for i = 1 to multiMat.numsubs do
    (
        if multiMat[i] != undefined and multiMat[i].name == matName then
        (
            return multiMat[i]
        )
    )
    undefined
)
fn caseInsensitiveCompare a b =
(
    if a == "UNUSED/" then false -- DON'T swap a if it's UNUSED/ (keep it before b)
    else if b == "UNUSED/" then true -- DO swap if b is UNUSED/ (push it before a)
    else (toLower a > toLower b) -- standard A–Z
)



-- Function to sort the dropdown list items alphabetically
fn sortDropdownListItems ddl_prefixes filePath =
(
    -- Store the name of the currently selected item
    selectedItemName = ddl_prefixes.selected

    -- Ensure we’re dealing with a real array
    sortedItems = for i in ddl_prefixes.items collect i

    -- Sort the items case-insensitively
    qsort sortedItems caseInsensitiveCompare

    -- Update the dropdown list UI
    ddl_prefixes.items = sortedItems

    -- Find the new index of the previously selected item
    newIndex = findItem ddl_prefixes.items selectedItemName

    -- Reselect the previously selected item
    if newIndex != 0 then
    (
        ddl_prefixes.selection = newIndex
    )

    -- Save the dropdown list items to the current file path
    if filePath != "" then
    (
        saveDropdownListItems ddl_prefixes filePath
    )
)



-- Rollout
rollout prefixRollout versionMSbP
(
	dotNetControl lblTitle "Label" pos:[2,2] width:296 height:30 -- Add Tacton Tools title block
	
    -- Dropdown list (ComboBox)
    dropdownlist ddl_prefixes "Select Prefix to Apply to Selected Material" items:#() -- Initialize with an empty array
    tooltip: "Select the desired prefix. If it does not exist, one can be added below. This list can also be edited in a text editor, and then loaded."
    button btn_applyPrefix "Apply Prefix" width: 130 align:#left across:2
	tooltip: "Apply the selected prefix from the list to the selected material. Works in the Compact and Slate Material Editors."
    button btn_removePrefix "Remove Prefix" width: 130 align:#right
    tooltip: "This will only remove prefixes formatted as folder structure, ie materials/metal/Iron_Cast-Fine."

    group "Edit Prefix List" (
        button btn_newList "New Prefix List" width: 85 align:#left across:3
		tooltip: "Start with a new blank list by picking a location and save name."
        button btn_loadPrefixes "Load Prefix List" width: 85 align:#center
		tooltip: "Load an existing Prefix List that is either created using this utility, or in a text editor."
        button btn_saveAs "Save List As" width: 85 align:#right
		tooltip: "Saves a copy of the currently Prefix List. Adding a Prefix automatically saves the list, so there's no need to overwrite the currently loaded list."
        button btn_addPrefix "Add Prefix" width: 85 align:#left across:2
        tooltip: "Add a new prefix by entering it here and then clicking Add Prefix. This will automatically save to the Prefix List file that is currently loaded. The user must have write privileges to add a prefix."
        -- Text field for user input
        edittext et_prefix "" width: 190 align:#right offset:[0,2] 
        tooltip: "Add a new prefix by entering it here and then clicking Add Prefix."
		button btn_sortPrefixes "Sort Prefix List" width: 85 align:#center
		tooltip:"This will sort the list by case and alphabetically, and then save the list."

		
    )
    group "List Unused Sub-Materials"
    (
        button btn_analyzeMultiSubMat "Analyze MultiSub Material of Select Object" width:273 align:#center
        tooltip: "This will list the unused Sub-Materials in a Multi/Sub-Object material that is applied to the selected object. Larger scenes will take longer to compute and will appear to hang."
        checkbox chkAddPrefix "Add UNUSED/ Prefix" checked:false offset: [0,2.5]across:2
        tooltip: "Check this box to add UNUSED/ to the front of the material name. This helps with organizing imported materials that are not used in other software, but you don't want to remove it from the Multi/Sub-Object material."
        button btnRemoveUnused "Remove UNUSED/" width:130 align:#right
		tooltip: "If the selected material has an UNUSED/ prefix or part of the prefix, it will remove only that portion of the prefix."
        checkbox chkPreservePrefix "Keep existing Prefix" checked:true enabled:false offset:[15,0]
        tooltip: "Leave this checked if you want to preserve a file path prefix and add UNUSED/ in front. Helpful if the material could be used later."
    )    
    -- label typeAbout01 versionMSbP
	

    -- Button pressed event for applying prefix
    on btn_applyPrefix pressed do
    (
        selectedMaterial = getSelectedMaterial()
        if selectedMaterial != undefined then 
        (
            -- First remove any existing prefix
            materialName = selectedMaterial.name
            if findString materialName "/" != undefined then
            (
                materialName = getFilenameFile materialName
            )
            
            -- Apply the new prefix
            selectedPrefix = ddl_prefixes.selected
            if selectedPrefix != undefined then
            (
                selectedMaterial.name = selectedPrefix + materialName
                format "Applied Prefix: % to Material: %\n" selectedPrefix selectedMaterial.name
            )
            else
            (
                format "No prefix selected.\n"
            )
        ) 
        else 
        (
            format "No material is selected.\n"
        )
    )
    
    -- Button pressed event for removing prefix
    on btn_removePrefix pressed do
    (
        selectedMaterial = getSelectedMaterial()
        if selectedMaterial != undefined then
        (
            materialName = selectedMaterial.name
            -- Remove the prefix (everything before the last "/")
            if findString materialName "/" != undefined then
            (
                newName = getFilenameFile materialName
                selectedMaterial.name = newName
                format "Removed Prefix: New Material Name: %\n" newName
            )
            else
            (
                format "No prefix found to remove.\n"
            )
        )
        else
        (
            format "No material is selected.\n"
        )
    )

-- ** Edit Prefix List Group **	
	
    -- Button pressed event for adding a new prefix to the list
    on btn_addPrefix pressed do
    (
        -- Get the current text in the edittext field
        currentText = et_prefix.text

        -- Check if the text is not empty and not already in the list
        if (currentText != "" and findItem ddl_prefixes.items currentText == 0) then
        (
            -- Add the text to the dropdown list
            append ddl_prefixes.items currentText

            -- Update the dropdown list
            ddl_prefixes.items = ddl_prefixes.items
            
            -- Set the newly added item as the selected item in the dropdown list
            ddl_prefixes.selection = ddl_prefixes.items.count

            -- Save the dropdown list items to the current file path
            if currentFilePath != "" then
            (
                saveDropdownListItems ddl_prefixes currentFilePath
            )
            et_prefix.text = ""
        )
    )

	-- Button pressed event for creating a new list
    on btn_newList pressed do
    (
        -- Clear the current dropdown list items
        ddl_prefixes.items = #()

        -- Update the dropdown list UI
        ddl_prefixes.items = ddl_prefixes.items

        -- Set the default directory for the file save dialog
        userScriptsDir = getDir #userScripts
        defaultDirectory = if currentFilePath == "" then userScriptsDir else getFilenamePath currentFilePath

        -- Open file save dialog to select the save location and name
        filePath = getSaveFileName caption:"Please Select A Location And Save New Prefix List As" types:"Text Files (*.txt)|*.txt|All Files (*.*)|*.*" initialDir:defaultDirectory

        -- If a file path was selected
        if filePath != undefined do
        (
            -- Save the new (empty) dropdown list items to the new file path
            saveDropdownListItems ddl_prefixes filePath
            currentFilePath = filePath
        )
    )
	
    -- Button pressed event for loading prefix list
    on btn_loadPrefixes pressed do
    (
        -- Set the default directory for the file open dialog
        userScriptsDir = getDir #userScripts
        defaultDirectory = if currentFilePath == "" then userScriptsDir else getFilenamePath currentFilePath

        -- Open file open dialog to select the file
        filePath = getOpenFileName caption:"Load Prefix List" types:"Text Files (*.txt)|*.txt|All Files (*.*)|*.*" initialDir:defaultDirectory

        -- If a file was selected
        if filePath != undefined do
        (
            -- Load the dropdown list items from the file
            loadDropdownListItems ddl_prefixes filePath
            currentFilePath = filePath
        )
    )

    -- Button pressed event for saving the list as a new file
    on btn_saveAs pressed do
    (
        -- Set the default directory for the file save dialog
        userScriptsDir = getDir #userScripts
        defaultDirectory = if currentFilePath == "" then userScriptsDir else getFilenamePath currentFilePath

        -- Open file save dialog to select the save location and name
        filePath = getSaveFileName caption:"Save Prefix List As" types:"Text Files (*.txt)|*.txt|All Files (*.*)|*.*" initialDir:defaultDirectory

        -- If a file path was selected
        if filePath != undefined do
        (
            -- Save the current dropdown list items to the new file path
            saveDropdownListItems ddl_prefixes filePath
            currentFilePath = filePath
        )
    )
	
	-- Button pressed event for sorting prefixes
	on btn_sortPrefixes pressed do
(
    sortDropdownListItems ddl_prefixes currentFilePath
)
	-- functions for defining Tacton Tools title block color and font
	fn defColor r g b = (dotNetClass "System.Drawing.Color").FromArgb r g b
	fn defFontB fName fSize = (dotNetObject "System.Drawing.Font" fName fSize ((dotNetClass "System.Drawing.FontStyle").bold))
    -- Load the dropdown list items when the rollout is opened
	on prefixRollout open do
	(
		-- Get the path to the folder the script was run from
		scriptFilePath = getSourceFileName()
		scriptDir = getFilenamePath scriptFilePath

		-- Compose the full path to the prefix list file
		filePath = scriptDir + "SortingPrefixes_dropdownListItems.txt"

		-- Check if the default file exists and load it, or create it if it doesn't exist
		loadDropdownListItems ddl_prefixes filePath

		-- Update the global file path
		currentFilePath = filePath

		-- UI Setup for Tacton Tools title block
		lblTitle.text = "Tacton Tools"
		lblTitle.textAlign = lblTitle.textAlign.MiddleCenter
		lblTitle.font = defFontB "Verdana" 10
		lblTitle.backColor = defColor 77 77 240
        lblTitle.foreColor = defColor 255 255 255
	)
	
-- ** List Unused Sub-Materials utility **	

    on chkAddPrefix changed NewState do
    (
        if chkAddPrefix.checked == true do
        (
            chkPreservePrefix.enabled = true
        )
        if chkAddPrefix.checked == false do
        (
            chkPreservePrefix.enabled = false
        )
    )
	
	-- Button pressed event for removing UNUSED/ prefix
    on btnRemoveUnused pressed do
    (
        selectedMaterial = getSelectedMaterial()
        if selectedMaterial != undefined then
        (
            materialName = selectedMaterial.name
            -- Check if the material name starts with UNUSED/
            if matchPattern materialName pattern:"UNUSED/*" then
            (
                -- Remove the UNUSED/ prefix
                newName = substituteString materialName "UNUSED/" ""
                selectedMaterial.name = newName
                format "Removed 'UNUSED/' Prefix: New Material Name: %\n" newName
            )
            else
            (
                format "The material name does not start with 'UNUSED/'.\n"
            )
        )
        else
        (
            format "No material is selected.\n"
        )
    )

    on btn_analyzeMultiSubMat pressed do
    (
        selectedObj = selection[1]
        if selection.count != 0 and classof selectedObj.material == MultiMaterial then
        (
            with undo on
            (
                try(DestroyDialog UnusedMaterialsRollout) catch()

                -- Store the Multi/Sub-Object material of the selected object
                multiMat = selectedObj.material
                multiMatName = multiMat.name
                format "Selected Multi-Material: %\n" multiMatName

                -- Find the unused sub-materials in the scene
                unusedMtls = #()
                MMClean.findAll &unusedMtls

                -- Store the IDs and names of all sub-materials before cleaning
                beforeCleaning = for mtl in unusedMtls collect
                (
                    for i = 1 to mtl.numsubs collect 
                    (
                        if mtl[i] != undefined then #(i, mtl[i].name) else #(i, "undefined")
                    )
                )

                for i = 1 to unusedMtls.count do
                (
                    usedSubMtls = #() -- Assuming we have a way to determine used sub-materials
                )

                -- Clean the materials, removes unused materials and added to array.
                MMClean.fix unusedMtls prompt:false

                -- Store the IDs and names of all sub-materials after cleaning
                afterCleaning = for mtl in unusedMtls collect
                (
                    for i = 1 to mtl.numsubs collect 
                    (
                        if mtl[i] != undefined then #(i, mtl[i].name) else #(i, "undefined")
                    )
                )

                -- Find the difference between the two arrays and print out the unused sub-materials
                unusedSubMtls = #()
                for i = 1 to beforeCleaning.count do
                (
                    for j = 1 to beforeCleaning[i].count do
                    (
                        local beforeItem = beforeCleaning[i][j]
                        local afterItem = (if j <= afterCleaning[i].count then afterCleaning[i][j] else #(j, "undefined"))
                        if beforeItem[2] != "undefined" and afterItem[2] == "undefined" do
                        (
                            append unusedSubMtls #(unusedMtls[i].name, beforeItem)
                        )
                    )
                )

                -- Declare resultsStr as a global variable
                global resultsStr = ""
                for mtlInfo in unusedSubMtls where mtlInfo[1] == multiMatName do
                (
                    resultsStr += ("Material ID: " + (mtlInfo[2][1] as string) + " - Name: " + mtlInfo[2][2] + "\n")
                )
                
                -- Display the rollout with a list of unused sub-materials.
                rollout UnusedMaterialsRollout "Unused Sub-Materials" width:380
                (
                    label lblResults "Unused Sub-Mats for Multi-Material:" across:2
                    label lblMultiMatName multiMatName offset:[-40,0]
                    dotNetControl edtResults "System.Windows.Forms.TextBox" height:200 width:350
                    button btnClose "Close" width:100 align:#center

                    on UnusedMaterialsRollout open do
                    (
                        edtResults.Multiline = true
                        edtResults.ScrollBars = edtResults.ScrollBars.Both
                        edtResults.WordWrap = false
                        edtResults.Text = substituteString resultsStr "\n" "\r\n" -- Replace \n with \r\n
                        edtResults.ReadOnly = true
                    )

                    on btnClose pressed do
                    (
                        destroyDialog UnusedMaterialsRollout
                    )
                )
                createDialog UnusedMaterialsRollout
            )
            -- Undo the cleaning operation to restore the unused sub-materials
            max undo
            
            if chkAddPrefix.checked then
            (
                for mtlInfo in unusedSubMtls where mtlInfo[1] == multiMatName do
                (
                    local mtl = getSubMaterialByName multiMat mtlInfo[2][2]
                    if mtl != undefined then
                    (
                        if chkPreservePrefix.checked and not matchPattern mtl.name pattern:"UNUSED/*" then
                        (
                            -- If chkPreservePrefix is checked and the material name doesn't already start with "UNUSED/",
                            -- prepend "UNUSED/" to the existing name
                            mtl.name = "UNUSED/" + mtl.name
                        )
                        else if not chkPreservePrefix.checked then
                        (
                            -- If chkPreservePrefix is not checked, remove the existing prefix and add "UNUSED/"
                            local newName = getFilenameFile mtl.name -- Remove the existing prefix
                            mtl.name = "UNUSED/" + newName
                        )
                    )
                )
            )
            
        )
        else
        (
            messageBox "Please select an object with a Multi/Sub-Object material." title:"Error"
        )
        
    )
	
)

-- Create a new dialog with the rollout
createdialog prefixRollout width: 300
