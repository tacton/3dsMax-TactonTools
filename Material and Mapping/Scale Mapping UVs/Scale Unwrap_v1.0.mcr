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

macroScript exportLayers
	category:"Tacton Tools"
	buttontext:"Scale Unwrap"
	tooltip:"Scale Unwrap"
(
	try ( DestroyDialog UnwrapScaler ) catch()
	versionSU = "Scale Unwraps v1.0"
	global UnwrapScaler

	GlobalInterfaceType = dotNetClass "Autodesk.Max.GlobalInterface"
	Matrix3Class = dotNetClass "Autodesk.Max.IMatrix3"

	global GlobalInterface = GlobalInterfaceType.Instance
	global CoreInterface13 = GlobalInterface.COREInterface13

	function get_matrix_scale netMatrix =
	(
		print netMatrix
		
		xScale = (netMatrix.GetColumn 0).x
		yScale = (netMatrix.GetColumn 1).y
		zScale = (netMatrix.GetColumn 2).z
		
		if xScale != 1 OR yScale != 1 OR zScale != 1 then
		(
			true
			[xScale, yScale, zScale]
		)
		else
		(
			false
			[xScale, yScale, zScale]
		)
	)

	fn adjust_cad_unwraps target_size =
	(
		try
		(
			try
			(
				for o in objects do
				(
					the_handle = o.handle	
					the_inode = CoreInterface13.GetINodeByHandle the_handle
					Matrix3Value = the_inode.GetObjectTM 1 null
					
					the_scale = (get_matrix_scale Matrix3Value)
			
					if (classof o.baseobject) == Editable_Mesh do
					(
						if o.modifiers.count == 1 do
						(
							the_modifier = o.modifiers[1]
							
							if classof(the_modifier) == UVWMap do
							(						
								scale_x = the_scale.x
								scale_y = the_scale.y
								scale_z = the_scale.z
								
								the_modifier.axis = 2
								the_modifier.maptype = 4
								
								the_modifier.width = target_size / scale_x
								the_modifier.length = target_size / scale_y
								the_modifier.height = target_size / scale_z
							)
						)
					)
				)
			)
			catch
			(
				adjust_cad_unwraps target_size
			)
		)
		catch()
	)

	fn adjust_cad_unwraps_global target_size =
	(
		for o in objects do
		(
			print (classof o.baseobject)
			
			if (classof o.baseobject) == Editable_Mesh do
			(
				if o.modifiers.count == 1 do
				(
					the_modifier = o.modifiers[1]
					
					if classof(the_modifier) == UVWMap do
					(
						scale_x = o.scale.x
						scale_y = o.scale.y
						scale_z = o.scale.z
						
						the_modifier.axis = 2
						the_modifier.maptype = 4

						the_modifier.width = target_size / scale_x
						the_modifier.length = target_size / scale_y
						the_modifier.height = target_size / scale_z
					)
				)
			)
		)
	)

	fn scale_unwraps_to_cm target =
	(
		cm_decode = units.decodeValue "1cm"
		the_selection = getCurrentSelection()
		
		for o in the_selection do
		(
			if(classof o) != Editable_mesh and (classof o) != Editable_Poly and (classof o) != PolyMeshObject do
			(
				continue
			)
			
			select o
			
			unwrap_modifier = undefined
			
			for m in o.modifiers do
			(
				if (classof m) == Unwrap_UVW and unwrap_modifier == undefined do
				(
					if m.getMapChannel() == 0 do
					(
						unwrap_modifier = m
					)
				)
			)
			
			unwrap_area = 0
			face_area = 0

			for f = 1 to (o.faces.count) do
			(
				if unwrap_modifier == undefined do
				(
					unwrap_modifier = Unwrap_UVW()
					addModifier o unwrap_modifier
				)
				
				o.modifiers["Unwrap_UVW"].getArea (#(f) as BitArray) &x &y &width &height &areaUVW &areaGeom 
				face_area += areaGeom
				unwrap_area += areaUVW

				if (classof o) == Editable_Poly do
				(
					poly_area = (polyop.getFaceArea o f)
				)
				
				if (classof o) == Editable_Mesh do
				(
					mesh_area = (meshop.getFaceArea o f)
				)
			)
			
			current_ratio = unwrap_area / face_area
			if current_ratio == 0 do ( current_ratio = 1 )
			
			scale_factor = 1.0 / current_ratio
			scale_factor = sqrt scale_factor
			scale_factor = scale_factor / target
			scale_factor = scale_factor / cm_decode
			
			modPanel.setCurrentObject unwrap_modifier
			subobjectLevel = 3
			unwrap_modifier.selectFaces #{1..(o.faces.count)}
			unwrap_modifier.scaleSelectedCenter scale_factor 0
			subobjectLevel = 0
			
			select the_selection
		)
	)

	-- Define the rollout (must be before we create it)
	rollout UnwrapScaler "Scale Unwrap" width:232 
	(
		dotNetControl lblTitle "Label" pos:[2,2] width:296 height:30 -- Add Tacton Tools title block
		label lblInfo1 "Select an unwrapped object, select desired scale,"
		label lblInfo2 "then press 'Scale Selected'." offset:[-52,0]
		
		label lbl_scale "Target Scale:" offset:[50,1] across:3
		spinner cm_spinner "" width:60 range:[0.1,10000,10]
		label lbl_cm "cm" offset:[-30,1]
			
		button btn_scale_unwraps "Scale Selected" width:200 height:30 align:#center
		label typeAbout01 versionSU
		
		on btn_scale_unwraps pressed do
		(
			scale_unwraps_to_cm cm_spinner.value
		)
		fn defColor r g b = (dotNetClass "System.Drawing.Color").FromArgb r g b
		fn defFontB fName fSize = (dotNetObject "System.Drawing.Font" fName fSize ((dotNetClass "System.Drawing.FontStyle").bold))
		on UnwrapScaler open do
		(
			-- UI Setup for Tacton Tools title block
			lblTitle.text = "Tacton Tools"
			lblTitle.textAlign = lblTitle.textAlign.MiddleCenter
			lblTitle.font = defFontB "Verdana" 10
			lblTitle.backColor = defColor 255 140 0
			lblTitle.foreColor = defColor 255 255 255
		)
	)

	-- Create the dialog after rollout is defined
	createDialog UnwrapScaler width: 300
)