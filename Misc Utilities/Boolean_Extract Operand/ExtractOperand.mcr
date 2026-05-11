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

macroScript Boolean_Extract_SelOperand
	buttonText:"Booleans - Extract Selected Operand"
	tooltip:"Booleans - Extract Selected Operand"
	category:"Tacton Tools"
(
try(DestroyDialog Boolean_Extract_SelOperand) catch()

rollout Boolean_Extract_SelOperand "Boolean Extract Selected Operand" 
(
	local LB_GETSEL = 0x187
	local LB_GETCOUNT = 0x18B
	local iGlobal = (dotNetClass "Autodesk.Max.GlobalInterface").Instance
	
	fn getListBoxItemCount hWnd =
		windows.sendMessage hWnd LB_GETCOUNT 0 0

	fn isListBoxItemSelected hWnd index =
		windows.sendMessage hWnd LB_GETSEL index 0 > 0

	fn isValidBoolObj obj = isKindOf obj Boolean3 or isKindOf obj ShapeBooleanObject
		
	dotNetControl lblTitle "Label" pos:[2,2] width:296 height:30
	button btn1 "Booleans - Extract Selected Operand"
		tooltip:"Extract selected operand from Boolean Compound Object."
	
	on btn1 pressed do if isValidBoolObj  (modPanel.getCurrentObject()) then
	(
		local obj = modPanel.getCurrentObject()
		local cpHWnd = iGlobal.UtilGetCoreInterface.CommandPanelRollup.HWnd
		local cpChildren = windows.getChildrenHWnd cpHWnd
		local listBoxHWnd = for child in cpChildren
			where UIAccessor.getWindowResourceID child[1] == 1020 do
				exit with child[1]

		if isKindOf listBoxHWnd Number do
		(
			local objs = obj.objects
			local TMs = obj.operand_tm
			local opName, itemCount = getListBoxItemCount listBoxHWnd

			local selectedItems = for i = 0 to itemCount - 1
			where isListBoxItemSelected listBoxHWnd i collect
					(obj.GetOperandName (i+1) &opName; opName)
			
			local selItems = for i = 0 to itemCount - 1 where isListBoxItemSelected listBoxHWnd i collect i + 1
			
			local extractedObjs = for i in selItems collect mesh baseObject:objs[i][1].value transform:(TMs[i].value * $.objectTransform)
			for i = 1 to extractedObjs.count do 
			(
				extractedObjs[i].name = ("Extracted_" + selectedItems[i])
			)
			select extractedObjs
		)
	)
	
	else
	(
		messageBox "Please select an operand within a valid boolean object (not ProBoolean)!" title: "Invalid Object Selected!"
	)
	fn defColor r g b = (dotNetClass "System.Drawing.Color").FromArgb r g b
	fn defFontB fName fSize = (dotNetObject "System.Drawing.Font" fName fSize ((dotNetClass "System.Drawing.FontStyle").bold))
	on Boolean_Extract_SelOperand open do
	(
		lblTitle.text = "Tacton Basic Scripts"
		lblTitle.textAlign = lblTitle.textAlign.MiddleCenter
		lblTitle.font = defFontB "Verdana" 10
		lblTitle.backColor = defColor 255 140 0
		lblTitle.foreColor = defColor 255 255 255
	)
)

createdialog Boolean_Extract_SelOperand width: 300
)