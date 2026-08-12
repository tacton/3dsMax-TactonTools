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

macroScript TempMerge
category:"Tacton Tools"
tooltip:"Temp Merge: Copy and paste between max instances."
buttonText:"Temp Merge"
(
	global tactonTmpMergeRollout

	rollout tactonTmpMergeRollout "Tacton Temp Merge Tool" width:300 height:120
	(
		dotNetControl lblTitle "Label" pos:[2,2] width:296 height:30

		button btnSave "Save Selection to Slot" pos:[50,45] width:200 height:26
		button btnLoad "Load Objects from Slot" pos:[50,80] width:200 height:26

		local scriptDir = getDir #userScripts
		local maxPath = scriptDir + "\\tmpMerge\\tempSlot1.max"

		fn removeBuggyTrackViewControllers =
		(
			undo off
			(
				try
				(
					t = trackviewnodes
					n = t[#Retimer_Manager]
					deleteTrackViewController t n.controller
					gc()

					t = trackviewnodes
					n = t[#Max_MotionClip_Manager]
					deleteTrackViewController t n.controller
					gc()
				)
				catch()
			)
		)

		fn saveToSlot =
		(
			removeBuggyTrackViewControllers()
			makedir (scriptDir + "\\tmpMerge") all:true

			if selection.count != 0 then
			(
				saveNodes selection maxPath
			)
			else
			(
				messageBox "No objects selected."
			)
		)

		fn loadFromSlot =
		(
			removeBuggyTrackViewControllers()

			if doesFileExist maxPath then
			(
				local preMergeHandles = for o in objects collect o.inode.handle
				mergeMAXFile maxPath
				local postMerge = for o in objects where (findItem preMergeHandles o.inode.handle == 0) collect o
				select postMerge
			)
			else
			(
				messageBox "Slot is empty."
			)
		)

		fn defColor r g b = (dotNetClass "System.Drawing.Color").FromArgb r g b
		fn defFontB fName fSize = (dotNetObject "System.Drawing.Font" fName fSize ((dotNetClass "System.Drawing.FontStyle").bold))

		on tactonTmpMergeRollout open do
		(
			lblTitle.text = "Tacton Tools"
			lblTitle.textAlign = lblTitle.textAlign.MiddleCenter
			lblTitle.font = defFontB "Verdana" 10
			lblTitle.backColor = defColor 77 77 240
			lblTitle.foreColor = defColor 255 255 255
		)

		on btnSave pressed do saveToSlot()
		on btnLoad pressed do loadFromSlot()
	)

	on execute do
	(
		try(destroyDialog tactonTmpMergeRollout)catch()
		createDialog tactonTmpMergeRollout
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
	rollout tempMergeInstallNotice "Macro Installed"
	(
		dotNetControl lblHdr "Label" pos:[4,4] width:312 height:28

		label lbl_done  "The 'Temp Merge' macroscript was installed." align:#center offset:[0,8]
		label lbl_done2 "If it is not yet on a toolbar, you will need to add it:" align:#center offset:[0,2]

		group "Customize User Interface"
		(
			label lbl_step1 "1.   Customize  >  Customize User Interface" align:#left offset:[4,2]
			label lbl_step2 "2.   Open the 'Toolbars' tab" align:#left offset:[4,2]
			label lbl_step3 "3.   Set the Category to 'Tacton Tools'" align:#left offset:[4,2]
			label lbl_step4 "4.   Drag 'Temp Merge' onto any toolbar" align:#left offset:[4,2]
		)

		button btn_close "Close" width:90 height:24 offset:[0,10]

		fn niceColor r g b = (dotNetClass "System.Drawing.Color").FromArgb r g b

		on tempMergeInstallNotice open do
		(
			lblHdr.text = "Temp Merge  v1.05"
			lblHdr.textAlign = lblHdr.textAlign.MiddleCenter
			lblHdr.font = dotNetObject "System.Drawing.Font" "Verdana" 10 ((dotNetClass "System.Drawing.FontStyle").bold)
			lblHdr.backColor = niceColor 77 77 240
			lblHdr.foreColor = niceColor 255 255 255
		)

		on btn_close pressed do ( DestroyDialog tempMergeInstallNotice )
	)

	try ( DestroyDialog tempMergeInstallNotice ) catch ()
	createDialog tempMergeInstallNotice width:320
)
