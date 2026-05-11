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

try (DestroyDialog shellCleanerRollout) catch()

-- Function: Get all unique materials in the scene
fn get_current_scenemtl =
(
	all_mat = #()
	for o in objects do
		appendifunique all_mat o.material
	all_mat
)

-- Function: Count how many Shell Materials exist
fn get_shell_count =
(
	smtl = get_current_scenemtl()
	shell_count = 0
	for m in smtl do
		if (classof m) == Shell_Material then
			shell_count += 1
	shell_count
)

-- Function: Clean all Shell Materials
fn clean_shells =
(
	smtl = get_current_scenemtl()
	for m in smtl do
	(
		if (classof m) == Shell_Material then
		(
			for o in objects where o.material == m do
				o.material = m.originalMaterial
			print o
		)
	)
)

-- Function: Repeatedly clean Shells until none remain
fn clean_shells_repeating =
(
	if (get_shell_count() != 0) then clean_shells()
	if (get_shell_count() != 0) then clean_shells_repeating()
)

-- Rollout UI
rollout shellCleanerRollout "Shell Material Cleaner"
(
	dotNetControl lblTitle "Label" pos:[2,2] width:296 height:30 -- Add Tacton Tools title block
	
	label lblInfo "Click the button to remove all Shell Materials."
	button btnClean "Remove Shell Materials" width:200

	on btnClean pressed do
	(
		undo "Remove Shell Materials" on
		(
			clean_shells_repeating()
			messageBox "All Shell Materials have been removed!" title:"Done" beep:true
		)
	)
	fn defColor r g b = (dotNetClass "System.Drawing.Color").FromArgb r g b
	fn defFontB fName fSize = (dotNetObject "System.Drawing.Font" fName fSize ((dotNetClass "System.Drawing.FontStyle").bold))
	on shellCleanerRollout open do
	(
		-- UI Setup for Tacton Tools title block
		lblTitle.text = "Tacton Tools"
        lblTitle.textAlign = lblTitle.textAlign.MiddleCenter
        lblTitle.font = defFontB "Verdana" 10
        lblTitle.backColor = defColor 77 77 240
        lblTitle.foreColor = defColor 255 255 255
	)
)

CreateDialog shellCleanerRollout width: 300

