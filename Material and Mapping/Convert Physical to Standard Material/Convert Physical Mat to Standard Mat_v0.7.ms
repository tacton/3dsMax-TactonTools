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

/* Physical ? Standard (legacy) converter
   - Uses replaceInstances to preserve all references (objects, ME slots, Slate, etc.)
   - Optional "_STD" suffix via checkbox (OFF by default)
   - Works on Material Editor selection (Compact or Slate), or entire scene if checkbox is enabled
*/


try (destroyDialog ms_ConvertPhysicalToStandard_MeditRollout) catch()

versionCPtS = "Convert Physical Mat to Standard Mat v0.7"

/* ---------- Utilities ---------- */

fn _getIf owner propName defaultVal =
(
    if isProperty owner propName then (getProperty owner propName) else defaultVal
)

fn _clamp01 v =
(
    amax 0.0 (amin 1.0 v)
)

-- cache helpers (array of #(handle, stdMat))
fn cacheFind cache handle =
(
    for p in cache where p[1] == handle do (return p[2])
    undefined
)

fn cacheAdd cache handle stdMat =
(
    append cache #(handle, stdMat)
)

-- helper: add Physical material to array by unique handle
fn addPhysUnique arr mat =
(
    local h = undefined
    try (h = getHandleByAnim mat) catch()
    if h == undefined then
    (
        append arr mat
    )
    else
    (
        local found = false
        for m in arr while not found do
        (
            local h2 = undefined
            try (h2 = getHandleByAnim m) catch()
            if h2 == h then found = true
        )
        if not found then append arr mat
    )
)

-- recursively gather Physical materials used by a material tree
fn gatherPhysicalMatsInMat mat physArr =
(
    if mat == undefined then
    (
        undefined
    )
    else if isKindOf mat PhysicalMaterial then
    (
        addPhysUnique physArr mat
        undefined
    )
    else if classof mat == Multimaterial then
    (
        for i = 1 to mat.numsubs do
        (
            if mat[i] != undefined then gatherPhysicalMatsInMat mat[i] physArr
        )
        undefined
    )
    else
    (
        undefined
    )
)

/* Gather Material Editor selection (Compact / Slate) */
fn _getMaterialEditorType =
(
    if (try (sme.isOpen()) catch(false)) then "Slate"
    else if (try (MatEditor.isOpen()) catch(false)) then "Compact"
    else undefined
)

fn _getSelectedMaterialsCompact =
(
    local m = undefined
    try (m = medit.GetCurMtl()) catch()
    if isKindOf m Material then #(m) else #()
)

fn _getSelectedMaterialsSlate =
(
    local out = #()
    if (try (sme.isOpen()) catch(false)) then
    (
        local v = sme.GetView (sme.activeView)
        if v != undefined then
        (
            local nodes = v.GetSelectedNodes()
            for n in nodes do
            (
                local r = try (n.reference) catch(undefined)
                if isKindOf r Material then append out r
            )
        )
    )
    out
)

fn getSelectedMaterialsInEditor =
(
    case (_getMaterialEditorType()) of
    (
        "Compact": _getSelectedMaterialsCompact()
        "Slate":   _getSelectedMaterialsSlate()
        default:   #()
    )
)

/* Build a Standard from a Physical. Uses cache to avoid duplicates. */
fn convertPhysicalToStandard physMat cache addSuffixFlag =
(
    local h = undefined
    try (h = getHandleByAnim physMat) catch()
    if h != undefined then
    (
        local cached = cacheFind cache h
        if cached != undefined then return cached
    )

    local baseName = physMat.name
    local finalName = if addSuffixFlag then (baseName + "_STD") else baseName
    local std = standardMaterial name:finalName

    /* Base color / map */
    std.diffuse = _getIf physMat #base_color (color 128 128 128)
    local baseMap = _getIf physMat #base_color_map undefined
    if baseMap != undefined then
    (
        std.diffuseMap = baseMap
        try (showTextureMap std std.diffuseMap true) catch()
    )

    /* Roughness (0..1) -> Glossiness (0..100) */
    local rough = _clamp01 (_getIf physMat #roughness 0.4)
    std.glossiness = (1.0 - rough) * 100.0
    local roughMap = _getIf physMat #roughness_map undefined
    if roughMap != undefined then
    (
        std.glossinessMap = roughMap
    )

    /* Metalness (0..1) -> Specular Level (0..100) */
    local metal = _clamp01 (_getIf physMat #metalness 0.0)
    std.specularLevel = metal * 100.0
    local metalMap = _getIf physMat #metalness_map undefined
    if metalMap != undefined then
    (
        std.specularLevelMap = metalMap
    )

    /* Transparency (0..1, 0=opaque) -> Opacity (0..100, 100=opaque) */
    local hasTransp = isProperty physMat #transparency
    local transpVal = if hasTransp then _getIf physMat #transparency 0.0 else 0.0
    transpVal = _clamp01 transpVal
    std.opacity = (1.0 - transpVal) * 100.0
    local transpMap = _getIf physMat #transparency_map undefined
    if transpMap != undefined then
    (
        std.opacityMap = transpMap
    )

    /* Bump: copy map + amount only (0..1 -> 0..100) */
    local bumpMap = _getIf physMat #bump_map undefined
    if bumpMap != undefined then
    (
        std.bumpMap = bumpMap
        local bumpAmt = 1.0
        if isProperty physMat #bump_map_amount then bumpAmt = _getIf physMat #bump_map_amount 1.0
        else if isProperty physMat #bump_map_weight then bumpAmt = _getIf physMat #bump_map_weight 1.0
        bumpAmt = _clamp01 bumpAmt
        if isProperty std #bumpMapAmount then std.bumpMapAmount = bumpAmt * 100.0
        else if isProperty std #bump then std.bump = bumpAmt * 100.0
    )

    /* Emission (best-effort) */
    local emiMap   = _getIf physMat #emission_color_map undefined
    local emiColor = if isProperty physMat #emit_color then physMat.emit_color else (color 0 0 0)

    if emiMap != undefined then
    (
        std.selfIllumAmount = 100
        std.selfIllumMap = emiMap
    )

    if emiColor != (color 0 0 0) then
    (
        std.useSelfIllumColor = on
        std.selfIllumColor = emiColor
    )

    -- Print each unique conversion once
    format "Converted Physical material: '%' -> Standard: '%'\n" physMat.name std.name

    if h != undefined then cacheAdd cache h std
    std
)

/* ---------- UI ---------- */

rollout ms_ConvertPhysicalToStandard_MeditRollout versionCPtS
(
    dotNetControl lblTitle "Label" pos:[2,2] width:316 height:30
    group ""
    (
        checkbox chkAllScene "Convert ALL Physical materials in scene" checked:false
            tooltip: "If unchecked, converts only the selected material(s) in the Material Editor."
        checkbox chkAddSuffix "Append \"_STD\" suffix to converted materials" checked:false
            tooltip: "Adds _STD suffix to the converted material name. Default = off."
    )

    button btnConvert "Run Conversion" width:260 height:40

    -- Built-in MaxScript progress bar + status text
    progressbar pb_convert "" color:(color 0 176 240) width:300 height:15 range:[0,100] value:0
    label lblStatus "Ready." width:300 align:#left

    on btnConvert pressed do
    (
        local wantSuffix = chkAddSuffix.checked

        if chkAllScene.checked then
        (
            -- SCENE MODE: convert all Physical materials used in scene + ME via replaceInstances
            undo "Convert Physical ? Standard (Scene)" on
            (
                local physArray = #()
                local cache = #()

                -- Gather Physicals from sceneMaterials
                for m in sceneMaterials do
                (
                    if m != undefined then gatherPhysicalMatsInMat m physArray
                )

                -- Also gather from ME slots (to catch library-only Physicals)
                local slotCount = try (meditMaterials.count) catch (24)
                for i = 1 to slotCount do
                (
                    local sm = meditMaterials[i]
                    if sm != undefined then gatherPhysicalMatsInMat sm physArray
                )

                local totalPhys = physArray.count
                if totalPhys == 0 then
                (
                    pb_convert.value = 0
                    lblStatus.text = "Ready."
                    messageBox "No Physical materials found to convert in scene or ME." title:"Nothing To Do"
                )
                else
                (
                    lblStatus.text = "Converting Physical materials in scene..."
                    pb_convert.value = 0
                    windows.processPostedMessages()

                    local idx = 0
                    for phys in physArray do
                    (
						if keyboard.escPressed then
						(
							format "Conversion cancelled by user.\n"
							exit
						)
						
                        idx += 1
                        local pct = (idx as float / totalPhys) * 100.0
                        pb_convert.value = pct
                        if (mod idx 5 == 0) then windows.processPostedMessages()

                        local std = convertPhysicalToStandard phys cache wantSuffix
                        -- This is the key: rewire ALL references from phys ? std in one go
                        replaceInstances phys std
                    )

                    pb_convert.value = 0
                    lblStatus.text = "Ready."

                    messageBox ("Converted " + totalPhys as string + " unique Physical material(s) in scene/ME.") title:"Done"
                )
            )
        )
        else
        (
            -- ME SELECTION MODE: convert only Physicals reachable from selected ME materials
            local selMats = getSelectedMaterialsInEditor()
            if selMats.count == 0 then
            (
                messageBox "No material(s) selected in the Material Editor (Compact or Slate)." title:"Nothing Selected"
            )
            else
            (
                undo "Convert Physical ? Standard (Material Editor Selection)" on
                (
                    local physArray = #()
                    local cache = #()

                    -- Gather Physicals only from selected materials (and their subs)
                    for m in selMats do
                    (
                        gatherPhysicalMatsInMat m physArray
                    )

                    local totalPhys = physArray.count
                    if totalPhys == 0 then
                    (
                        pb_convert.value = 0
                        lblStatus.text = "Ready."
                        messageBox "No Physical materials found in selected material(s)." title:"Nothing To Do"
                    )
                    else
                    (
                        lblStatus.text = "Converting selected Physical materials..."
                        pb_convert.value = 0
                        windows.processPostedMessages()

                        local idx = 0
                        for phys in physArray do
                        (
							if keyboard.escPressed then
							(
								format "Conversion cancelled by user.\n"
								exit
							)
                            idx += 1
                            local pct = (idx as float / totalPhys) * 100.0
                            pb_convert.value = pct
                            if (mod idx 5 == 0) then windows.processPostedMessages()

                            local std = convertPhysicalToStandard phys cache wantSuffix
                            -- Again: rewire ALL references (objects, ME slots, Slate) from phys ? std
                            replaceInstances phys std
                        )

                        pb_convert.value = 0
                        lblStatus.text = "Ready."

                        messageBox ("Conversion complete.\nConverted unique Physical(s): " + totalPhys as string) title:"Done"
                    )
                )
            )
        )
    )

    -- Tacton header styling
    fn defColor r g b =
    (
        (dotNetClass "System.Drawing.Color").FromArgb r g b
    )
    fn defFontB fName fSize =
    (
        dotNetObject "System.Drawing.Font" fName fSize ((dotNetClass "System.Drawing.FontStyle").bold)
    )
    on ms_ConvertPhysicalToStandard_MeditRollout open do
    (
        lblTitle.text = "Tacton Tools"
        lblTitle.textAlign = lblTitle.textAlign.MiddleCenter
        lblTitle.font = defFontB "Verdana" 10
        lblTitle.backColor = defColor 77 77 240
		lblTitle.foreColor = defColor 255 255 255

        pb_convert.value = 0
        lblStatus.text = "Ready."
    )
)

createDialog ms_ConvertPhysicalToStandard_MeditRollout width:320
