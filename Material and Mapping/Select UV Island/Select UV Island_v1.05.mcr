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

macroScript selectUVisland
	category:"Tacton Tools"
	buttontext:"Sel UV Island"
	tooltip:"Expand Selection to the UV Island. v1.05"

(
	(
		--//function to convert selected subObjects to shell
		fn expandToShell =
		(
			--//Get the modifier, exit if not unwrap
			uv = ModPanel.getCurrentObject()
			if classof uv != Unwrap_UVW do return false
	 
			uv.selectElement()
			uv.updateview()
		)
	 
		
		undo "To Element" on (
			expandToShell()
		)
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
	rollout uvislandInstallNotice "Macro Installed"
	(
		dotNetControl lblHdr "Label" pos:[4,4] width:312 height:28

		label lbl_done  "The 'Select UV Island' macroscript was installed." align:#center offset:[0,8]
		label lbl_done2 "If it is not yet on a toolbar, you will need to add it:" align:#center offset:[0,2]

		group "Customize User Interface"
		(
			label lbl_step1 "1.   Customize  >  Customize User Interface" align:#left offset:[4,2]
			label lbl_step2 "2.   Open the 'Toolbars' tab" align:#left offset:[4,2]
			label lbl_step3 "3.   Set the Category to 'Tacton Tools'" align:#left offset:[4,2]
			label lbl_step4 "4.   Drag 'Sel UV Island' onto any toolbar" align:#left offset:[4,2]
		)

		button btn_close "Close" width:90 height:24 offset:[0,10]

		fn niceColor r g b = (dotNetClass "System.Drawing.Color").FromArgb r g b

		on uvislandInstallNotice open do
		(
			lblHdr.text = "Select UV Island  v1.05"
			lblHdr.textAlign = lblHdr.textAlign.MiddleCenter
			lblHdr.font = dotNetObject "System.Drawing.Font" "Verdana" 10 ((dotNetClass "System.Drawing.FontStyle").bold)
			lblHdr.backColor = niceColor 77 77 240
			lblHdr.foreColor = niceColor 255 255 255
		)

		on btn_close pressed do ( DestroyDialog uvislandInstallNotice )
	)

	try ( DestroyDialog uvislandInstallNotice ) catch ()
	createDialog uvislandInstallNotice width:320
)
