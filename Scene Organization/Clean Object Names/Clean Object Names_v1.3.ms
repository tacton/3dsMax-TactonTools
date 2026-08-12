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
Clean Object Names: Script for cleaning up generic object names generally found with CAD imports, or long object names with random characters. Also removes .prt and _MultiBodies suffixes.
13/03/25 - v1.0 Initial release
25/09/25 - v1.1 Moved defaultNames variable to be global and at the top of the script to make it easier to add more default names that should be targetted for renaming.
26/01/26 - v1.2 Added global badCharReplacements for sanitizing unwanted characters (e.g. "/" -> "_").
26/01/26 - v1.3 Added "Replace Spaces" button to convert spaces to underscores for selected objects.
*/

try (destroyDialog ::CleanObjectNames) catch()

-- update the version in the variable below
versionCON = "Clean Object Names v1.3"

-- List of default names that should trigger renaming
global defaultNames = #("MAINBODY", "FILLET", "CHAMFER", "PARTBODY", "SOLID", "NONE", "BREP", "QUILT", "REVOLVE", "BODY", "Extrude", "MANIFOLD", "STITCH_RESULT", "MATERIAL", "CirPattern", "Imported", "Boss-Extrude", "Cut-Revolve", "Mirror", "Cut-Extrude")

/*
Add any undesirable character replacements here.
Each entry is: #("findThis","replaceWith")
*/
global badCharReplacements = #(
	#("/","_")
	,#("- - ","")
	,#(" - ","_")
	,#(":","_")
	,#("__","_")
	--,#("?","_")
	--,#("\"","_")
	--,#("<","_")
	--,#(">","_")
	--,#("|","_")
)

-- Persistent counter for the script
global globalCounter = if isKindOf globalCounter Integer then globalCounter else 1
global noGroupError = 0

rollout CleanObjectNames versionCON
(
	dotNetControl lblTitle "Label" pos:[2,2] width:296 height:30 -- Add Tacton Tools title block (wider to fit new button)
	
	group ""
	(
		button btnCleanNames "Clean Names" width:130 height:30 align:#left across:3
			tooltip:"Pressing this will clean up long names and generic names."
		label type_lenThresh "Length Threshold:" offset:[50,7]
			tooltip:"Objects named with more or equal than this threshold will be renamed after the group they belong to."
		spinner spnNameLength "" range:[3, 200, 60] fieldWidth:23 type:#integer offset:[0,6] align:#right
			tooltip:"Objects named with more than this threshold will be renamed after the group they belong to."
		button btnReplaceSpaces "Replace Spaces with '_'" width:130 height:30 align:#left
			tooltip:"Replace spaces with underscores for selected objects (undoable)."
		button btnResetCounter "Reset Trailing # Counter" width:130 align:#left across:2
			tooltip:"Pressing this will reset the incremental number added to the object renaming. The counter will automatically return to 0001 once it surpasses 9999."
		editText txtInfo "" width:130 height:30 readonly:true offset:[0,-5]
	)

	-- Replace any undesirable characters based on badCharReplacements
	fn sanitizeName nameStr =
	(
		if nameStr == undefined then return nameStr
		for p in badCharReplacements do
		(
			-- p[1] = find, p[2] = replace
			nameStr = substituteString nameStr p[1] p[2]
		)
		nameStr
	)

	-- Function to remove ".prt" from a name
	fn removePrtSuffix name =
	(
		local prtIndex = findString name ".prt"
		if prtIndex != undefined then
		(
			name = substring name 1 (prtIndex - 1) -- Remove ".prt"
		)
		name
	)

	-- Function to extract the base group name (removes the last "_xxxx" numeric suffix and ".prt")
	fn getBaseGroupName groupName =
	(
		local cleanedName = removePrtSuffix groupName -- First remove .prt suffix
		cleanedName = sanitizeName cleanedName -- sanitize group name early
		local underscorePos = 0

		-- Find the last underscore
		for i = cleanedName.count to 1 by -1 do
		(
			if (substring cleanedName i 1) == "_" then
			(
				underscorePos = i
				exit -- Stop searching after the last underscore is found
			)
		)

		if underscorePos > 0 and underscorePos < cleanedName.count then
		(
			local suffix = substring cleanedName (underscorePos + 1) -1
			local isNumericSuffix = false
			try (
				local num = suffix as integer
				isNumericSuffix = true
			) catch ()
			if isNumericSuffix then
			(
				cleanedName = substring cleanedName 1 (underscorePos - 1)
			)
		)

		cleanedName = sanitizeName cleanedName -- sanitize again after trimming
		cleanedName
	)

	-- Function to rename an object based on its parent group name
	fn renameObjectIfGrouped obj =
	(
		local groupName = if obj.parent != undefined and isGroupHead obj.parent then obj.parent.name else undefined

		if groupName != undefined then
		(
			local baseGroupName = getBaseGroupName groupName -- Get cleaned + sanitized group name
			local newName = baseGroupName + "_" + formattedPrint globalCounter format:".4d" -- Four-digit counter

			globalCounter += 1
			if globalCounter > 9999 then globalCounter = 1
			
			obj.name = sanitizeName newName -- final safety pass
		)
		else
		(
			if noGroupError == 0 then
			(
				messageBox "Object(s) in selection do not belong to a group and cannot be renamed. Please check listener for object names." title:"Error"
				noGroupError = 1
				print ("Object " + obj.name + " does not belong to a group.")
			)
			else
			(
				print ("Object " + obj.name + " does not belong to a group.")
			)
		)
	)

	-- Function to check if an object name should be cleaned
	fn shouldRenameObject objName =
	(
		objName = removePrtSuffix objName -- Remove .prt before checking conditions
		objName = sanitizeName objName

		if objName.count >= spnNameLength.value then return true -- Use spinner value as threshold

		for defaultName in defaultNames do
		(
			if matchPattern objName pattern:(defaultName + "*") ignoreCase:true then return true -- Matches default name
		)

		false
	)

	on btnResetCounter pressed do
	(
		globalCounter = 1
		messageBox "Global counter has been reset to 0001." title:"Reset Complete"
	)

	-- Main clean names button (existing behavior)
	on btnCleanNames pressed do
	(
		noGroupError = 0
		if selection.count > 0 then
		(
			undo "Clean Names" on -- Begin undo block
			(
				for obj in selection do
				(
					local name = obj.name

					-- Remove everything after ".prt"
					local prtIndex = findString name ".prt"
					if prtIndex != undefined then
					(
						name = substring name 1 (prtIndex - 1) + "_" + formattedPrint globalCounter format:".4d"
						globalCounter += 1
						if globalCounter > 9999 then globalCounter = 1
					)

					-- Remove everything after ".iam"
					prtIndex = findString name ".iam"
					if prtIndex != undefined then
					(
						name = substring name 1 (prtIndex - 1) + "_" + formattedPrint globalCounter format:".4d"
						globalCounter += 1
						if globalCounter > 9999 then globalCounter = 1
					)

					-- Remove everything after ".ipt"
					prtIndex = findString name ".ipt"
					if prtIndex != undefined then
					(
						name = substring name 1 (prtIndex - 1) + "_" + formattedPrint globalCounter format:".4d"
						globalCounter += 1
						if globalCounter > 9999 then globalCounter = 1
					)

					-- Remove everything after ".igs"
					prtIndex = findString name ".igs"
					if prtIndex != undefined then
					(
						name = substring name 1 (prtIndex - 1) + "_" + formattedPrint globalCounter format:".4d"
						globalCounter += 1
						if globalCounter > 9999 then globalCounter = 1
					)

					-- Remove everything after ".stp"
					prtIndex = findString name ".stp"
					if prtIndex != undefined then
					(
						name = substring name 1 (prtIndex - 1) + "_" + formattedPrint globalCounter format:".4d"
						globalCounter += 1
						if globalCounter > 9999 then globalCounter = 1
					)

					-- Remove "_MultiBodies"
					local multiBodiesIndex = findString name "_MultiBodies"
					if multiBodiesIndex != undefined then
					(
						name = substring name 1 (multiBodiesIndex - 1) + "_" + formattedPrint globalCounter format:".4d"
						globalCounter += 1
						if globalCounter > 9999 then globalCounter = 1
					)

					-- Sanitize unwanted characters (e.g. "/" -> "_")
					name = sanitizeName name

					obj.name = name

					if shouldRenameObject obj.name then
					(
						obj.name = sanitizeName (removePrtSuffix obj.name)
						renameObjectIfGrouped obj
					)
				)
			)
			messageBox "Name cleaning complete!" title:"Done"
		)
		else
		(
			messageBox "No objects selected!" title:"Error"
		)
	)

	-- New: Replace Spaces -> "_" button handler
	on btnReplaceSpaces pressed do
	(
		if selection.count > 0 then
		(
			undo "Replace Spaces With Underscores" on
			(
				for obj in selection do
				(
					-- Only operate if name contains a space
					if findString obj.name " " != undefined then
					(
						local newName = substituteString obj.name " " "_" -- replace spaces
						newName = sanitizeName newName -- run through sanitize to keep everything consistent
						-- assign new name
						obj.name = newName
						print ("Renamed: " + obj.name)
					)
				)
			)
			messageBox "Spaces replaced with underscores for selected objects." title:"Done"
		)
		else
		(
			messageBox "No objects selected!" title:"Error"
		)
	)

	fn defColor r g b = (dotNetClass "System.Drawing.Color").FromArgb r g b
	fn defFontB fName fSize = (dotNetObject "System.Drawing.Font" fName fSize ((dotNetClass "System.Drawing.FontStyle").bold))
	on CleanObjectNames open do
	(
		-- UI Setup for Tacton Tools title block
		lblTitle.text = "Tacton Tools"
		lblTitle.textAlign = lblTitle.textAlign.MiddleCenter
		lblTitle.font = defFontB "Verdana" 10
		lblTitle.backColor = defColor 77 77 240
		lblTitle.foreColor = defColor 255 255 255
		txtInfo.text = "This resets the trailing\n# counter value to 0001."
	)
)

-- Create the dialog
createDialog CleanObjectNames width:300
