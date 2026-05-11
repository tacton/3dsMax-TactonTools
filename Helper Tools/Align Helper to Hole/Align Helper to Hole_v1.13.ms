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

-- Initialize the global markers array
global AlignHelperToHoleMarkers = #() -- Initialize globally

-- Structure to store marker data for drawing in the viewport
struct pointdata (pos, txt, col)

-- Function to draw the markers, text, and lines in the viewport
fn drawCoords =
(
	markers = AlignHelperToHoleMarkers
	if AlignHelperToHoleMarkers.count > 0 then
	(
		gw.setTransform (matrix3 1)
		-- Draw markers and text
		for i in markers do (
			p = gw.hTransPoint i.pos
			gw.hText p i.txt color:i.col
			gw.hMarker p #smallHollowBox color:[255,255,255]
		)
		-- Draw lines
		if markers.count > 1 then (
			gw.setColor #line [0,255,0] -- Green line for Y-axis
			gw.hPolyline #(gw.hTransPoint markers[1].pos, gw.hTransPoint markers[2].pos) false
		)
		if markers.count > 2 then (
			gw.setColor #line [255,0,0] -- Red line for X-axis
			local midpoint = (markers[1].pos + markers[2].pos) / 2
			gw.hPolyline #(gw.hTransPoint midpoint, gw.hTransPoint markers[3].pos) false
		)
		gw.enlargeUpdateRect #whole
		gw.updateScreen()
	)
	else
	(
		print "whoopsie"
	)
)

-- Function to calculate the midpoint between two points
fn calculateMidpoint p1 p2 =
(
    (p1 + p2) / 2
)

-- Function to align the helper based on selected vertices
fn alignHelperToHole helper p1 p2 p3 =
(
	undo on
	(
		-- Step 1: Calculate the average position for the helper's pivot
		local pivotPos = calculateMidpoint p1 p2
		helper.position = pivotPos

		-- Step 2: Align the Y-axis towards the first selected vertex (positive Y direction)
		local yAxisDir = normalize (p1 - p2)

		-- Step 3: Align the X-axis towards the third selected vertex (p3)
		local xAxisDir = normalize (p3 - pivotPos)

		-- Step 4: The Z-axis is perpendicular to the X- and Y-axes
		local zAxisDir = normalize (cross xAxisDir yAxisDir)

		-- Recalculate X-axis to ensure it is perpendicular to the Y and Z
		xAxisDir = normalize (cross yAxisDir zAxisDir)

		-- Construct the transformation matrix for the helper
		local alignMatrix = matrix3 xAxisDir yAxisDir zAxisDir pivotPos

		-- Apply the new transform to the helper
		helper.transform = alignMatrix
	)
)

-- Function to reverse the Z-axis by rotating the helper 180 degrees on the Y-axis using Euler angles
fn reverseZAxis helper =
(
    in coordsys local rotate helper (eulerAngles 0 180 0)  -- Rotate 180 degrees around Y-axis in local coordinates
)

-- Rollout UI
try(DestroyDialog alignHelperRollout) catch()
versionAHTH = "Align Helper To Hole V1.13"

rollout alignHelperRollout versionAHTH
(
	dotNetControl lblTitle "Label" pos:[2,2] width:296 height:30
	group ""
	(
		button btnAlign "Align Helper to Hole" width:160 offset:[0,-10] align:#center
	)
	--label typeAbout01 versionAHTH

    -- Action when the button is clicked
    on btnAlign pressed do
    (
        -- Clear any previous markers to avoid displaying old labels
        --AlignHelperToHoleMarkers = #()

        if selection.count == 1 and classOf selection[1] == Point then
        (
            local helper = selection[1]  -- The selected helper

            -- Enable 3D snapping for vertex selection
            local originalSnapMode = snapMode.active
            snapMode.active = true

            -- Register the viewport callback to draw the markers and lines
            unregisterRedrawViewsCallback drawCoords
            

            -- Step 1: Pick the first vertex (start of hole) with 3D snapping
            local p1 = pickPoint prompt:"Select first vertex (start of hole, positive Y direction)" snap:#3D
            if classOf p1 == Point3 then
            (
				
                -- Add marker for the first point
                append AlignHelperToHoleMarkers (pointdata pos:p1 txt:"Y Axis +" col:[0,255,0]) -- Green for positive Y axis
				registerRedrawViewsCallback drawCoords
                --redrawViews()  -- Force viewport redraw to show the text

                -- Step 2: Pick the second vertex (end of hole) with rubberBand from the first vertex
                local p2 = pickPoint prompt:"Select second vertex (end of hole, negative Y direction)" snap:#3D rubberBand:p1
                if classOf p2 == Point3 then
                (
                    -- Add marker for the second point
                    append AlignHelperToHoleMarkers (pointdata pos:p2 txt:"Y Axis -" col:[0,255,0]) -- Green for negative Y axis
                    --redrawViews()  -- Force viewport redraw to show the text and line

                    -- Step 3: Pick the third vertex (tangent to hole opening) with rubberBand from midpoint
                    local midpoint = calculateMidpoint p1 p2
                    local p3 = pickPoint prompt:"Select third vertex (for X-axis alignment)" snap:#3D rubberBand:midpoint
                    if classOf p3 == Point3 then
                    (
                        -- Add marker for the third point
                        append AlignHelperToHoleMarkers (pointdata pos:p3 txt:"X Axis" col:[255,0,0]) -- Red for X axis
                        --redrawViews()  -- Force viewport redraw to show the text and line

                        -- Align the helper based on the selected points
                        alignHelperToHole helper p1 p2 p3

                        -- Force the viewport to redraw and display the aligned helper
                        redrawViews()

                        -- Now that the helper is visible, ask if the user wants to reverse the Z-axis direction
                        local response = queryBox "Do you want to flip the Z-axis?" title:"Flip Z Axis?"
                        if response == true then
                        (
                            reverseZAxis helper
                            redrawViews()  -- Redraw after rotating
                            format "Z Axis reversed.\n"
                        )

                        -- Unregister the viewport callback and clear markers once done
                        unregisterRedrawViewsCallback drawCoords
                        AlignHelperToHoleMarkers = #()  -- Clear markers at the end
                        redrawViews()

                    )
					else
					(
                        messageBox "Invalid point selection for X-axis alignment. Aborting."
                    )
                )
				else
				(
                    messageBox "Invalid point selection for Y-axis negative direction. Aborting."
                )
            )
			else
			(
                messageBox "Invalid point selection for Y-axis positive direction. Aborting."
            )

            -- Restore snap settings
            snapMode.active = originalSnapMode
            unregisterRedrawViewsCallback drawCoords  -- Clean up the callback

        )
		else
		(
            messageBox "Please select one Point helper before running this script."
        )
    )
	fn defColor r g b = (dotNetClass "System.Drawing.Color").FromArgb r g b
	fn defFontB fName fSize = (dotNetObject "System.Drawing.Font" fName fSize ((dotNetClass "System.Drawing.FontStyle").bold))
	on alignHelperRollout open do
	(
		lblTitle.text = "Tacton Tools"
		lblTitle.textAlign = lblTitle.textAlign.MiddleCenter
		lblTitle.font = defFontB "Verdana" 10
		lblTitle.backColor = defColor 255 140 0
		lblTitle.foreColor = defColor 255 255 255
	)
)

-- Create and display the rollout in a floating window
createDialog alignHelperRollout width:300
