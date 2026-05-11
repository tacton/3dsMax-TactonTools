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
			lblTitle.backColor = defColor 255 140 0
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
