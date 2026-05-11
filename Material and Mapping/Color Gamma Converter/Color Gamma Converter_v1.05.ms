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
	Color Gamma Convert: This maxscript utility converts file gamma settings from gamma 2.2, to gamma 1.0, (and vice versa)
		and gamma adjust material colors to those scene gamma settings. It also allows converting materials that are applied to selected objects
		materials of objects that are visible, and all materials that are applied to objects.
	10/09/2025 v1.0 Inital release
	04/09/2026 v1.05 Added Tacton Tools header, removed About rollout
*/

try (destroyDialog gammaConverter) catch()
versionLE = "Color Gamma Converter v1.05"

-- === Globals ===
global __colBackups = #()
global __processedMats = #()
global __OpenPBR_Class = undefined
global gGammaVal = 2.2 -- default gamma

try (__OpenPBR_Class = getClassByName "OpenPBR_Material") catch()
struct ColBackup (mat, prop, value)

-- === Gamma Color Conversion Logic (v0.5 original) ===
fn srgbEncodeColor c gammaVal =
(
    local r = (amax 0 (amin 255 c.r))/255.0
    local g = (amax 0 (amin 255 c.g))/255.0
    local b = (amax 0 (amin 255 c.b))/255.0
    local gamma = 1.0/gammaVal
    color ((pow r gamma)*255.0) ((pow g gamma)*255.0) ((pow b gamma)*255.0)
)

fn srgbDecodeColor c gammaVal =
(
    local r = (amax 0 (amin 255 c.r))/255.0
    local g = (amax 0 (amin 255 c.g))/255.0
    local b = (amax 0 (amin 255 c.b))/255.0
    local gamma = gammaVal
    color ((pow r gamma)*255.0) ((pow g gamma)*255.0) ((pow b gamma)*255.0)
)

fn encodeMaterialColor m gammaVal =
(
    if (findItem __processedMats m) != 0 do return()
    append __processedMats m

    if isKindOf m PhysicalMaterial then
    (
        try if m.base_color_map == undefined do
        (
            append __colBackups (ColBackup m #base_color m.base_color)
            m.base_color = srgbEncodeColor m.base_color gammaVal
        ) catch()
        try if isProperty m #emit_color and m.emit_color_map == undefined do
        (
            append __colBackups (ColBackup m #emit_color m.emit_color)
            m.emit_color = srgbEncodeColor m.emit_color gammaVal
        ) catch()
    )
    else if isKindOf m StandardMaterial then
    (
        try if m.diffuseMap == undefined do
        (
            append __colBackups (ColBackup m #diffuse m.diffuse)
            m.diffuse = srgbEncodeColor m.diffuse gammaVal
        ) catch()
        try if isProperty m #selfIllumColor and m.selfIllumMap == undefined do
        (
            append __colBackups (ColBackup m #selfIllumColor m.selfIllumColor)
            m.selfIllumColor = srgbEncodeColor m.selfIllumColor gammaVal
        ) catch()
    )
    else if __OpenPBR_Class != undefined and isKindOf m OpenPBR_Material then
    (
        try if m.base_color_map_on == false do
        (
            append __colBackups (ColBackup m #base_color m.base_color)
            m.base_color = srgbEncodeColor m.base_color gammaVal
        ) catch()
        try if isProperty m #emission_color and m.emission_color_map_on == false do
        (
            append __colBackups (ColBackup m #emission_color m.emission_color)
            m.emission_color = srgbEncodeColor m.emission_color gammaVal
        ) catch()
    )
)

-- Material Color Decoding
fn decodeMaterialColor m gammaVal =
(
	if (findItem __processedMats m) != 0 do return()
	append __processedMats m

	if isKindOf m PhysicalMaterial then
	(
		local hasBaseMap = false
		local hasEmitMap = false
		try (if (m.base_color_map != undefined) then hasBaseMap = true) catch()
		try (if (m.emit_color_map != undefined) then hasEmitMap = true) catch()

		if not hasBaseMap do
		(
			append __colBackups (ColBackup m #base_color m.base_color)
			m.base_color = srgbDecodeColor m.base_color gammaVal
		)

		if not hasEmitMap and isProperty m #emit_color do
		(
			append __colBackups (ColBackup m #emit_color m.emit_color)
			m.emit_color = srgbDecodeColor m.emit_color gammaVal
		)
	)
	else if isKindOf m StandardMaterial then
	(
		local hasDiffMap = false
		local hasSelfIllumMap = false
		try (if (m.diffuseMap != undefined) and m.mapDiffuse do hasDiffMap = true) catch()
		try (if (m.selfIllumMap != undefined) and m.mapSelfIllum do hasSelfIllumMap = true) catch()

		if not hasDiffMap do
		(
			append __colBackups (ColBackup m #diffuse m.diffuse)
			m.diffuse = srgbDecodeColor m.diffuse gammaVal
		)

		if not hasSelfIllumMap and isProperty m #selfIllumColor do
		(
			append __colBackups (ColBackup m #selfIllumColor m.selfIllumColor)
			m.selfIllumColor = srgbDecodeColor m.selfIllumColor gammaVal
		)
	)
	else if __OpenPBR_Class != undefined and isKindOf m OpenPBR_Material then
	(
		local hasBaseMap = false
		local hasEmitMap = false
		try (if (m.base_color_map != undefined and m.base_color_map_on) do hasBaseMap = true) catch()
		try (if (m.emission_color_map != undefined and m.emission_color_map_on) do hasEmitMap = true) catch()

		if not hasBaseMap do
		(
			append __colBackups (ColBackup m #base_color m.base_color)
			m.base_color = srgbDecodeColor m.base_color gammaVal
		)

		if not hasEmitMap and isProperty m #emission_color do
		(
			append __colBackups (ColBackup m #emission_color m.emission_color)
			m.emission_color = srgbDecodeColor m.emission_color gammaVal
		)
	)
)

fn traverseAndConvert mats gammaVal direction =
(
    for m in mats where isKindOf m Material do
    (
        case direction of
        (
            #encode: encodeMaterialColor m gammaVal
            #decode: decodeMaterialColor m gammaVal
        )

        local n = 0
        try (n = getNumSubMtls m) catch()
        if n > 0 do
        (
            for i = 1 to n do
            (
                try (traverseAndConvert #(getSubMtl m i) gammaVal direction) catch()
            )
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

fn getMaterialsToProcess scopeIndex =
(
    local mats = #()
    local objs

    case scopeIndex of
    (
        1: (objs = selection as array)
        2: (objs = for o in objects where not o.isHidden collect o)
        3: (objs = objects as array)
        4:
        (
            -- Compact Material Editor: get current slot's material
            local m = undefined
            try m = medit.getCurMtl() catch()
            if (m != undefined) do mats = #(m)
            return mats
        )
		5:  -- All materials in editor
		(
			for i = 1 to meditMaterials.count do
			(
				local m = meditMaterials[i]
				if m != undefined do
				(
					if findItem mats m == 0 do append mats m
				)
			)
			return mats
		)
		6: -- All used + editor materials
        (
            -- First collect all object-assigned materials
            for obj in objects do
            (
                if isProperty obj #material and obj.material != undefined do
                (
                    local m = obj.material
                    if (findItem mats m) == 0 do append mats m
                )
            )

            -- Then add all editor slots
            for i = 1 to meditMaterials.count do
            (
                local m = meditMaterials[i]
                if m != undefined and (findItem mats m) == 0 do append mats m
            )
            return mats
        )

    )

    -- For cases 1-3, collect object materials
    if scopeIndex <= 3 do
    (
        for obj in objs do
        (
            if isProperty obj #material and obj.material != undefined do
            (
                local m = obj.material
                if findItem mats m == 0 do append mats m
            )
        )
    )
    return mats
)


-- === SUBROLLOUT: Manual Color Conversion ===
rollout gammaManualRollout "Manual Color Conversion"
(
	radioButtons rdoScope "Materials to Convert" labels:#(
    "1. Selected Objects Mats",
    "2. Visible Objects Mats",
    "3. All Used Mats",
    "4. Selected Mats in Editor",
    "5. All Mats in Editor",
	"6. All Used + Editor Mats"
	) default:6 columns:2 align:#center tooltip:"Convert colors of materials by 1. By selected objects. 2. By visible objects 3. All used mats 4. Selected in Editor 5. All Mats in Editor 6. All used mats and those in the Editor"


    button btnToLinear "Gamma TO Linear (1.0)" width:130 height:30 align:#center across:2
		tooltip:"Apply gamma so materials made for gamma corrected work in linear workflow."
    button btnToGamma  "Linear (1.0) TO Gamma" width:130 height:30 align:#center
		tooltip:"Apply gamma so materials made for linear work in gamma corrected workflow."
    button btnRollback "Undo - Rollback Previous Colors" width:268 height:26 align:#center offset:[0,10]

    on btnToLinear pressed do
    (
        __colBackups = #()
        __processedMats = #()
        local mats = getMaterialsToProcess rdoScope.state
        if mats.count == 0 then
            messageBox "No materials found for selected scope."
        else
        (
            -- Linear -> Gamma encode (use global gGammaVal)
            traverseAndConvert mats gGammaVal #encode
			redrawViews()
            messageBox ("Converted " + mats.count as string + " materials FROM Linear TO Gamma " + gGammaVal as string)
        )
    )

    on btnToGamma pressed do
    (
        __colBackups = #()
        __processedMats = #()
        local mats = getMaterialsToProcess rdoScope.state
        if mats.count == 0 then
            messageBox "No materials found for selected scope."
        else
        (
            -- Gamma -> Linear decode (use global gGammaVal)
            traverseAndConvert mats gGammaVal #decode
			redrawViews()
            messageBox ("Converted " + mats.count as string + " materials FROM Gamma " + gGammaVal as string + " TO Linear")
        )
    )

    on btnRollback pressed do
    (
        rollbackColors()
        messageBox "Material colors restored to original values."
    )
)


-- === SUBROLLOUT: Color Converter (RGB <-> Hex & Gamma) ===
rollout colorHexRollout "Color Converter"
(
    local linearOffsetX = -145
    local gammaOffsetY = -126
    local fieldWidth = 40

    label labelLinear "Linear Values" align:#right offset:[-40,0] across:2
    label labelGamma "Gamma Correct Values" align:#right offset:[-10,0]

    -- Integer RGB (Linear)
    spinner spnRed   "Red (0-255):   " range:[0,255,128] type:#integer align:#right fieldWidth:fieldWidth offset:[linearOffsetX,0]
    spinner spnGreen "Green (0-255): " range:[0,255,128] type:#integer align:#right fieldWidth:fieldWidth offset:[linearOffsetX,0]
    spinner spnBlue  "Blue (0-255):  " range:[0,255,128] type:#integer align:#right fieldWidth:fieldWidth offset:[linearOffsetX,0]

    -- Float RGB (Linear)
    spinner spnRedF   "Red (0.0-1.0):   " range:[0.0,1.0,0.5] type:#float align:#right scale:0.01 fieldWidth:fieldWidth offset:[linearOffsetX,0]
    spinner spnGreenF "Green (0.0-1.0): " range:[0.0,1.0,0.5] type:#float align:#right scale:0.01 fieldWidth:fieldWidth offset:[linearOffsetX,0]
    spinner spnBlueF  "Blue (0.0-1.0):  " range:[0.0,1.0,0.5] type:#float align:#right scale:0.01 fieldWidth:fieldWidth offset:[linearOffsetX,0]

    -- Integer RGB (Gamma Corrected)
    spinner spnRedG   "Red (0-255):   " range:[0,255,186] type:#integer align:#right fieldWidth:fieldWidth offset:[0,gammaOffsetY]
    spinner spnGreenG "Green (0-255): " range:[0,255,186] type:#integer align:#right fieldWidth:fieldWidth
    spinner spnBlueG  "Blue (0-255):  " range:[0,255,186] type:#integer align:#right fieldWidth:fieldWidth

    -- Float RGB (Gamma Corrected)
    spinner spnRedFG   "Red (0.0-1.0):   " range:[0.0,1.0,0.73] type:#float align:#right scale:0.01 fieldWidth:fieldWidth
    spinner spnGreenFG "Green (0.0-1.0): " range:[0.0,1.0,0.73] type:#float align:#right scale:0.01 fieldWidth:fieldWidth
    spinner spnBlueFG  "Blue (0.0-1.0):  " range:[0.0,1.0,0.73] type:#float align:#right scale:0.01 fieldWidth:fieldWidth

    -- Hex fields + previews
    editText txtHex "Hex #:" text:"BABABA" align:#right fieldWidth:50 offset:[linearOffsetX,0]
    colorPicker clrPreview "" color:(color 128 128 128) width:140 height:30 align:#right offset:[linearOffsetX,0] enabled:false

    editText txtHexG "Hex #:" text:"BABABA" align:#right fieldWidth:50 offset:[0,-57]
    colorPicker clrPreviewG "" color:(color 128 128 128) width:140 height:30 align:#right offset:[0,0]
		tooltip: "Do not open Color Picker without changing any values. 3ds max bug can change values on open. If opened by accident, click OK, Cancel will apply wrong colors."

    /* ---------- helpers ---------- */
    fn stripHexPrefixes s = (
        local t = substituteString (substituteString (substituteString (substituteString s " " "") "#" "") "0x" "") "0X" ""
        t
    )
    fn sanitizeHexString s = (
        local t = toUpper (stripHexPrefixes s)
        local valid = "0123456789ABCDEF"
        local out = ""
        for i = 1 to t.count do (
            local ch = substring t i 1
            if (findString valid ch) != undefined do if out.count < 6 do out += ch
        )
        out
    )
    fn safeHexToByte s = (try (bit.hexasInt s) catch (0))
    fn safeRound val = floor (val + 0.5)

    fn rgbToHex r g b = (
        local hex = ""
        for c in #(r, g, b) do (
            local h = bit.intAsHex c
            if h.count < 2 then h = "0" + h
            hex += toUpper h
        )
        hex
    )
    fn hexToRGB hexCode = (
        local h = sanitizeHexString hexCode
        while h.count < 6 do h += "0"
        #( safeHexToByte (substring h 1 2),
           safeHexToByte (substring h 3 2),
           safeHexToByte (substring h 5 2) )
    )

    /* ---------- gamma conversion (use global gGammaVal) ---------- */
    fn linearToGamma val = pow val (1.0 / gGammaVal)
    fn gammaToLinear val = pow val gGammaVal

    /* ---------- sync helpers ---------- */
    fn updatePreview r g b =
    (
        -- r,g,b are Linear 0-255 ints
        local rf = r/255.0
        local gf = g/255.0
        local bf = b/255.0

        local rc = pow rf gGammaVal
        local gc = pow gf gGammaVal
        local bc = pow bf gGammaVal

        clrPreview.color = color (rc*255.0) (gc*255.0) (bc*255.0)
    )

    fn updatePreviewGFromLinear =
    (
        local rf = spnRedF.value
        local gf = spnGreenF.value
        local bf = spnBlueF.value
        clrPreviewG.color = color (rf*255.0) (gf*255.0) (bf*255.0)
    )

    fn syncGammaFromLinear = (
        local rLin = spnRedF.value
        local gLin = spnGreenF.value
        local bLin = spnBlueF.value

        local rGam = linearToGamma rLin
        local gGam = linearToGamma gLin
        local bGam = linearToGamma bLin

        spnRedFG.value   = rGam
        spnGreenFG.value = gGam
        spnBlueFG.value  = bGam
        spnRedG.value    = safeRound (rGam * 255.0)
        spnGreenG.value  = safeRound (gGam * 255.0)
        spnBlueG.value   = safeRound (bGam * 255.0)

        txtHexG.text = rgbToHex spnRedG.value spnGreenG.value spnBlueG.value
        updatePreviewGFromLinear()
    )

    fn syncLinearFromGamma = (
        local rGam = spnRedFG.value
        local gGam = spnGreenFG.value
        local bGam = spnBlueFG.value

        local rLin = gammaToLinear rGam
        local gLin = gammaToLinear gGam
        local bLin = gammaToLinear bGam

        -- Update Linear Float
        spnRedF.value   = rLin
        spnGreenF.value = gLin
        spnBlueF.value  = bLin

        -- Update Linear Int
        spnRed.value    = safeRound (rLin * 255.0)
        spnGreen.value  = safeRound (gLin * 255.0)
        spnBlue.value   = safeRound (bLin * 255.0)

        -- Update Gamma Int
        spnRedG.value   = safeRound (rGam * 255.0)
        spnGreenG.value = safeRound (gGam * 255.0)
        spnBlueG.value  = safeRound (bGam * 255.0)

        txtHex.text = rgbToHex spnRed.value spnGreen.value spnBlue.value
        updatePreview spnRed.value spnGreen.value spnBlue.value

        -- Update Gamma Hex + Preview
        txtHexG.text = rgbToHex spnRedG.value spnGreenG.value spnBlueG.value
        updatePreviewGFromLinear()
    )

    fn syncFromInts = (
        txtHex.text = rgbToHex spnRed.value spnGreen.value spnBlue.value
        spnRedF.value   = spnRed.value   / 255.0
        spnGreenF.value = spnGreen.value / 255.0
        spnBlueF.value  = spnBlue.value  / 255.0
        updatePreview spnRed.value spnGreen.value spnBlue.value
        syncGammaFromLinear()
    )

    fn syncFromFloats = (
        spnRed.value   = safeRound (spnRedF.value   * 255.0)
        spnGreen.value = safeRound (spnGreenF.value * 255.0)
        spnBlue.value  = safeRound (spnBlueF.value  * 255.0)
        txtHex.text = rgbToHex spnRed.value spnGreen.value spnBlue.value
        updatePreview spnRed.value spnGreen.value spnBlue.value
        syncGammaFromLinear()
    )

    fn syncFromHex = (
        local rgb = hexToRGB txtHex.text
        spnRed.value   = rgb[1]; spnGreen.value = rgb[2]; spnBlue.value = rgb[3]
        spnRedF.value   = rgb[1] / 255.0; spnGreenF.value = rgb[2] / 255.0; spnBlueF.value  = rgb[3] / 255.0
        updatePreview rgb[1] rgb[2] rgb[3]
        syncGammaFromLinear()
    )

    fn syncFromHexG = (
        local rgb = hexToRGB txtHexG.text
        spnRedG.value   = rgb[1]; spnGreenG.value = rgb[2]; spnBlueG.value = rgb[3]
        spnRedFG.value   = rgb[1] / 255.0; spnGreenFG.value = rgb[2] / 255.0; spnBlueFG.value  = rgb[3] / 255.0
        updatePreviewGFromLinear()
        syncLinearFromGamma()
    )

    /* ---------- events ---------- */
    -- linear hex
    on txtHex changed txt do (local clean = sanitizeHexString txt; if clean != txt then txtHex.text = clean)
    on txtHex entered txt do syncFromHex()

    -- gamma hex
    on txtHexG changed txt do (local clean = sanitizeHexString txt; if clean != txt then txtHexG.text = clean)
    on txtHexG entered txt do syncFromHexG()

    -- swatch events
    on clrPreviewG changed col do
    (
        local rGam = col.r / 255.0
        local gGam = col.g / 255.0
        local bGam = col.b / 255.0

        spnRedF.value   = rGam
        spnGreenF.value = gGam
        spnBlueF.value  = bGam
        syncFromFloats()
    )

    -- linear ints
    on spnRed   changed val do syncFromInts()
    on spnGreen changed val do syncFromInts()
    on spnBlue  changed val do syncFromInts()

    -- linear floats
    on spnRedF   changed val do syncFromFloats()
    on spnGreenF changed val do syncFromFloats()
    on spnBlueF  changed val do syncFromFloats()

    -- gamma ints
    on spnRedG   changed val do (spnRedFG.value = spnRedG.value / 255.0; syncLinearFromGamma())
    on spnGreenG changed val do (spnGreenFG.value = spnGreenG.value / 255.0; syncLinearFromGamma())
    on spnBlueG  changed val do (spnBlueFG.value = spnBlueG.value / 255.0; syncLinearFromGamma())

    -- gamma floats
    on spnRedFG   changed val do syncLinearFromGamma()
    on spnGreenFG changed val do syncLinearFromGamma()
    on spnBlueFG  changed val do syncLinearFromGamma()
)

-- === MAIN Rollout ===
rollout gammaConverter versionLE width:340 height:526
(
	-- -----------------------------
	-- UI Header
	-- -----------------------------
	dotNetControl lblTitle "Label" pos:[2,2] width:336 height:30

    label lblColorMgmt "Current Mode: (loading...)" align:#center
    local buttonWidth = 130

    button btnSetGammaMode "Set Gamma Workflow" width:buttonWidth height:30 align:#center across:2
    button btnSetLinearMode "Set Linear Workflow" width:buttonWidth height:30 align:#center
    spinner spnGamma "Gamma:" range:[0.1,5.0,2.2] type:#float scale:0.1 fieldWidth:60 align:#center
	subRollout holder height:525


    fn updateButtonStates =
    (
        local cm = ColorPipelineMgr.Mode
        local cg = ColorPipelineMgr.DisplayGamma
        local tg = spnGamma.value
        btnSetGammaMode.enabled = not(cm==#Gamma and abs(cg-tg)<0.0001)
        btnSetLinearMode.enabled = not(cm==#Gamma and abs(cg-1.0)<0.0001)
    )

    fn updateColorMgmtLabel =
    (
        local modeText = case ColorPipelineMgr.Mode of
        (
            #Unmanaged:"Unmanaged"
            #Gamma:"Gamma Workflow ("+ColorPipelineMgr.DisplayGamma as string+")"
            #OCIO_Default:"OCIO Default"
            #OCIO_Custom:"OCIO Custom"
            default:"Unknown"
        )
        lblColorMgmt.text = "Current Mode: " + modeText
    )

	fn defColor r g b = (dotNetClass "System.Drawing.Color").FromArgb r g b
	fn defFontB fName fSize = (dotNetObject "System.Drawing.Font" fName fSize ((dotNetClass "System.Drawing.FontStyle").bold))

	on gammaConverter open do
	(
		lblTitle.text = "Tacton Tools"
		lblTitle.textAlign = lblTitle.textAlign.MiddleCenter
		lblTitle.font = defFontB "Verdana" 10
		lblTitle.backColor = defColor 77 77 240
		lblTitle.foreColor = defColor 255 255 255

		local ver = maxVersion()
		if ver[8] < 2024 then
		(
			messageBox "This script is not supported in versions earlier than 3ds Max 2024.\nIt requires the new Color Management system (OCIO support)."
			destroyDialog gammaConverter
		)
		else
		(
			addSubRollout holder gammaManualRollout rolledUp:false
			addSubRollout holder colorHexRollout rolledUp:false
			updateColorMgmtLabel()
			updateButtonStates()
		)
	)

    on spnGamma changed v do
	(
		gGammaVal = v
		try (colorHexRollout.syncGammaFromLinear()) catch()
		updateButtonStates()
	)

    on btnSetGammaMode pressed do
	(
		local currentMode = ColorPipelineMgr.Mode
		local currentGamma = ColorPipelineMgr.DisplayGamma
		local targetGamma = spnGamma.value
		-- Color Management already updated...
		updateColorMgmtLabel()
		updateButtonStates()

		-- Ask if user wants to convert scene materials
		if currentGamma == 1.0 then
		(
			local response = queryBox ("Would you like to convert all scene materials from Linear (1.0) to Gamma " + (targetGamma as string) + "?")
			if response then
			(
				try (ColorPipelineMgr.Locked = false) catch()
				try (ColorPipelineMgr.Mode = #Gamma) catch()
				try (ColorPipelineMgr.DisplayGamma = targetGamma) catch()

				__colBackups = #()
				__processedMats = #()
				traverseAndConvert (getMaterialsToProcess 3) targetGamma #decode

				updateColorMgmtLabel()
				updateButtonStates()
				redrawViews()

				messageBox ("Scene materials converted from Linear to Gamma.\nColor Management updated to Gamma Workflow " + targetGamma as string)
			)

			else
			(
				try (ColorPipelineMgr.Locked = false) catch()
				try (ColorPipelineMgr.Mode = #Gamma) catch()
				try (ColorPipelineMgr.DisplayGamma = targetGamma) catch()
				updateColorMgmtLabel()
				updateButtonStates()
				redrawViews()
				messageBox ("Color Management Mode set to Gamma Workflow  " + targetGamma as string)
			)
		)
		else
		(
			try (ColorPipelineMgr.Locked = false) catch()
			try (ColorPipelineMgr.Mode = #Gamma) catch()
			try (ColorPipelineMgr.DisplayGamma = targetGamma) catch()
			updateColorMgmtLabel()
			updateButtonStates()
			redrawViews()
			messageBox ("Color Management Mode set to Gamma Workflow  " + targetGamma as string)
		)
	)

    on btnSetLinearMode pressed do
	(
		local preGamma = ColorPipelineMgr.DisplayGamma
		local spinnerGamma = spnGamma.value

		-- Always switch to Gamma mode
		try (ColorPipelineMgr.Locked = false) catch()
		try (ColorPipelineMgr.Mode = #Gamma) catch()

		-- Ask about material conversion
		local doConvert = queryBox "Would you like to convert all scene materials from Gamma to Linear (1.0)?"

		if doConvert then
		(
			local gammaForConversion

			if abs(preGamma - spinnerGamma) < 0.0001 then
			(
				-- No ambiguity, use current display gamma
				gammaForConversion = preGamma
			)
			else
			(
				-- Ask which gamma to use for conversion
				local useSceneGamma = queryBox (
					"Scene gamma is currently " + (preGamma as string) +
					".\nWould you like to use that value for color conversion?\n\n" +
					"Yes = use scene gamma (" + (preGamma as string) + ")\n" +
					"No = use spinner gamma (" + (spinnerGamma as string) + ")"
				)
				gammaForConversion = if useSceneGamma then preGamma else spinnerGamma
			)

			-- Now do the conversion
			__colBackups = #()
			__processedMats = #()
			traverseAndConvert (getMaterialsToProcess 3) gammaForConversion #encode
				-- Finally set Display Gamma to 1.0
			try (ColorPipelineMgr.DisplayGamma = 1.0) catch()

			updateColorMgmtLabel()
			updateButtonStates()
			redrawViews()
			messageBox (
			"Color Management Mode set to Linear Workflow (Gamma 1.0)\n" +
			"Scene materials converted from Gamma " + (gammaForConversion as string) + " to Linear."
		)
		)

		else
		(
			-- Finally set Display Gamma to 1.0
			try (ColorPipelineMgr.DisplayGamma = 1.0) catch()

			updateColorMgmtLabel()
			updateButtonStates()
			redrawViews()
			messageBox "Color Management Mode set to Linear Workflow (Gamma 1.0)"
		)
	)
)

createDialog gammaConverter
