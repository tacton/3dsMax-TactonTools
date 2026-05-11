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
Consolidate Duplicate Materials:
This script goes through the scene, either from selection and/or including hidden objects, consolidates materials with
the same name into one material and reassigns objects with the consolidated materials. This is useful in the case of
CAD imports where they have materials imported in with the same name. This can vastly reduce the labor required for
finding objects and reassigning materials manually.

This script will also populate the Material Editor slots with these materials. It first populates the
Multi/Sub-Object materials used, and then single materials. This is also done in alphabetical and numerical order. Any
materials after the 24 materials slots have been populated will still exist in the scene, they just will not be displayed
within the Material Editor.
*/


try (destroyDialog consolidateMatRollout) catch()
versionCDM = "Consolidate Duplicate Materials v1.36"

-- =========================================================
-- Helpers
-- =========================================================

fn appendIfUniqueByRef arr item =
(
    if item == undefined then false
    else if (findItem arr item) == 0 then (append arr item; true)
    else false
)

fn isMultiSubMat m =
(
    if m == undefined then false
    else ((classof m == MultiMaterial) or (classof m == Multimaterial))
)

fn isDefaultSlotMaterialName mat =
(
    if mat == undefined then false
    else (matchPattern (mat.name as string) pattern:"* - Default")
)

-- Comparator (must not be nested in some Max versions)
fn _matNameCompare a b =
(
    local an = ""
    local bn = ""

    try (an = toLower (a.name as string)) catch (an = "")
    try (bn = toLower (b.name as string)) catch (bn = "")

    if an < bn then -1 else if an > bn then 1 else 0
)

fn sortMaterialsByName mats =
(
    qsort mats _matNameCompare
    mats
)

fn getMESlotCountSafe =
(
    local slotCount = 24
    try (slotCount = meditMaterials.count) catch (slotCount = 24)
    slotCount
)

fn nodeIsHiddenSafe n =
(
    if (isValidNode n) == false then false
    else if (isProperty n #isHidden) then n.isHidden
    else false
)

-- Option A scope:
-- If useSelection==true -> use selection, else use all objects.
-- If includeHidden==false -> skip hidden nodes.
fn getWorkingObjects useSelection includeHidden =
(
    local arr = #()
    local src = if useSelection then (selection as array) else (objects as array)

    for o in src do
    (
        if (isValidNode o) then
        (
            if includeHidden then
            (
                append arr o
            )
            else
            (
                if (nodeIsHiddenSafe o) == false then append arr o
            )
        )
    )
    arr
)

-- Materials used by ANY object in the scene (protect ME slots from overwrite)
fn getUsedObjectMaterialsTopLevel_AllScene =
(
    local used = #()
    for o in objects do
    (
        if (isValidNode o) then
        (
            local m = o.material
            if (isKindOf m Material) then
            (
                if (findItem used m) == 0 then append used m
            )
        )
    )
    used
)

-- Get ME materials (unique) and ME keepers by name (first occurrence wins)
fn getMEKeepersByName =
(
    local slotCount = getMESlotCountSafe()
    local meMats = #()
    local nameList = #()
    local keeperList = #()

    for i = 1 to slotCount do
    (
        local sm = meditMaterials[i]
        if (isKindOf sm Material) then
        (
            appendIfUniqueByRef meMats sm

            local nm = sm.name as string
            local idx = findItem nameList nm
            if idx == 0 then
            (
                append nameList nm
                append keeperList sm
            )
        )
    )

    #(meMats, nameList, keeperList)
)

-- Build eligible slot indices to replace (Rules #1/#2/#3)
fn buildReplaceableSlotIndices usedObjMats slotCount =
(
    local slots = #()

    for i = 1 to slotCount do
    (
        local sm = meditMaterials[i]

        if sm == undefined then
        (
            append slots i
        )
        else
        (
            -- RULE #1 safety: if slot currently holds a MAP, do NOT touch it
            if (isKindOf sm TextureMap) then
            (
                -- skip
            )
            else
            (
                if (isKindOf sm Material) then
                (
                    -- RULE #2: if this slot's material is used by ANY object in scene, protect it
                    if (findItem usedObjMats sm) != 0 then
                    (
                        -- protect
                    )
                    else
                    (
                        -- RULE #3: replace only if it's a default-named slot material
                        if isDefaultSlotMaterialName sm then
                        (
                            append slots i
                        )
                        else
                        (
                            -- Non-default, not used: conservative skip
                        )
                    )
                )
                else
                (
                    -- Unknown content: conservative skip
                )
            )
        )
    )
    slots
)

-- Unique top-level materials from object list only (materials only)
fn getUniqueTopLevelMaterialsFromObjects objArr =
(
    local mats = #()
    for o in objArr do
    (
        if (isValidNode o) and (isProperty o #material) then
        (
            local m = o.material
            if (isKindOf m Material) then
            (
                if (findItem mats m) == 0 then append mats m
            )
        )
    )
    mats
)

-- Unique Multi/Sub materials from object list (top-level only)
fn getUniqueMultiSubsFromObjects objArr =
(
    local multis = #()
    for o in objArr do
    (
        if (isValidNode o) and (isProperty o #material) then
        (
            local m = o.material
            if isMultiSubMat m then appendIfUniqueByRef multis m
        )
    )
    multis
)

-- Build keeper-by-name arrays:
-- 1) ME keepers first
-- 2) scope top-level object materials
-- 3) (optional safety) sub-materials found inside scope Multi/Subs, if not already present
fn buildKeeperByName_ForScope objArr =
(
    local keeperNames = #()
    local keeperMats  = #()

    -- 1) Prefer ME keepers
    local meData = getMEKeepersByName()
    local meKeeperNames = meData[2]
    local meKeeperMats  = meData[3]

    for i = 1 to meKeeperNames.count do
    (
        append keeperNames meKeeperNames[i]
        append keeperMats  meKeeperMats[i]
    )

    -- 2) Add scope top-level object mats
    local scopeMats = getUniqueTopLevelMaterialsFromObjects objArr
    for m in scopeMats do
    (
        local nm = m.name as string
        if (findItem keeperNames nm) == 0 then
        (
            append keeperNames nm
            append keeperMats  m
        )
    )

    -- 3) Add sub-mats from scope Multi/Subs (prevents “lucky” cases)
    local multis = getUniqueMultiSubsFromObjects objArr
    for mm in multis do
    (
        local ns = 0
        try (ns = mm.numsubs) catch (ns = 0)

        for i = 1 to ns do
        (
            local sm = undefined
            try (sm = mm[i]) catch (sm = undefined)

            if (isKindOf sm Material) then
            (
                local nm = sm.name as string
                if (findItem keeperNames nm) == 0 then
                (
                    append keeperNames nm
                    append keeperMats  sm
                )
            )
        )
    )

    #(keeperNames, keeperMats)
)

-- Signature for Multi/Sub: numsubs + token per slot based on sub-material name
fn getMultiSig mm =
(
    local ns = 0
    try (ns = mm.numsubs) catch (ns = 0)

    local sig = (ns as string)
    for i = 1 to ns do
    (
        local sm = undefined
        try (sm = mm[i]) catch (sm = undefined)

        local token = "<none>"
        if sm == undefined then
        (
            token = "<none>"
        )
        else if (isKindOf sm Material) then
        (
            token = (sm.name as string)
        )
        else
        (
            token = ("<" + (classof sm as string) + ">")
        )

        sig += ("|" + token)
    )
    sig
)

-- =========================================================
-- Consolidate Materials (NOW ALSO consolidates Multi/Subs)
-- =========================================================
fn lmConsolidateMaterials useSelection includeHidden =
(
    if useSelection and selection.count == 0 then
    (
        messageBox "Use Selection is ON, but nothing is selected." title:"Nothing Selected" beep:true
        false
    )
    else
    (
        local objArr = getWorkingObjects useSelection includeHidden
        if objArr.count == 0 then
        (
            messageBox "No objects found in scope (selection/scene + hidden filter)." title:"Nothing To Do" beep:true
            false
        )
        else
        (
            -- Build keeper map (ME -> scope top-level -> scope Multi/Sub subs)
            local keeperData = buildKeeperByName_ForScope objArr
            local keeperNames = keeperData[1]
            local keeperMats  = keeperData[2]

            -- A) Consolidate top-level object materials by name (scope)
            local scopeMats = getUniqueTopLevelMaterialsFromObjects objArr
            local totalMatInstances = scopeMats.count

            -- Stats duplicates by name (within scope top-level)
            local nameList  = #()
            local nameCount = #()
            for m in scopeMats do
            (
                local nm = m.name as string
                local idx = findItem nameList nm
                if idx == 0 then
                (
                    append nameList nm
                    append nameCount 1
                )
                else
                (
                    nameCount[idx] += 1
                )
            )

            local dupTotal = 0
            local dupGroups = 0
            for i = 1 to nameList.count do
            (
                if nameCount[i] > 1 then
                (
                    dupTotal  += (nameCount[i] - 1)
                    dupGroups += 1
                )
            )

            local changed = 0
            for o in objArr do
            (
                if (isProperty o #material) then
                (
                    local om = o.material
                    if (isKindOf om Material) then
                    (
                        local idx = findItem keeperNames (om.name as string)
                        if idx != 0 then
                        (
                            local km = keeperMats[idx]
                            if km != undefined and km != om then
                            (
                                o.material = km
                                changed += 1
                            )
                        )
                    )
                )
            )

            -- B) Normalize Multi/Sub sub-materials by keeper name (scope)
            local multiList = getUniqueMultiSubsFromObjects objArr
            local subSlotsUpdated = 0

            for mm in multiList do
            (
                local ns = 0
                try (ns = mm.numsubs) catch (ns = 0)

                for i = 1 to ns do
                (
                    local sm = undefined
                    try (sm = mm[i]) catch (sm = undefined)

                    if (isKindOf sm Material) then
                    (
                        local idx = findItem keeperNames (sm.name as string)
                        if idx != 0 then
                        (
                            local km = keeperMats[idx]
                            if km != undefined and km != sm then
                            (
                                mm[i] = km
                                subSlotsUpdated += 1
                            )
                        )
                    )
                )
            )

            -- C) Consolidate Multi/Sub materials by signature (scope)
            local sigKeys = #()
            local sigKeepers = #()
            local multisReplaced = 0

            for mm in multiList do
            (
                local sig = getMultiSig mm
                local idx = findItem sigKeys sig

                if idx == 0 then
                (
                    append sigKeys sig
                    append sigKeepers mm
                )
                else
                (
                    local keeper = sigKeepers[idx]
                    if keeper != undefined and keeper != mm then
                    (
                        replaceInstances mm keeper
                        multisReplaced += 1
                    )
                )
            )

            local msg =
                "Scope: " + (if useSelection then "Selection" else "Scene") + (if includeHidden then " (incl. hidden)" else " (visible only)") + "\n\n" +
                "Top-level unique material instances in scope: " + (totalMatInstances as string) + "\n" +
                "Top-level duplicates by name in scope: " + (dupTotal as string) + " across " + (dupGroups as string) + " name group(s)\n" +
                "Objects updated (top-level materials): " + (changed as string) + "\n\n" +
                "Multi/Subs found (unique, top-level in scope): " + (multiList.count as string) + "\n" +
                "Sub-material slots normalized to keepers: " + (subSlotsUpdated as string) + "\n" +
                "Multi/Subs consolidated (replaceInstances): " + (multisReplaced as string) + "\n\n" +
                "Keeper preference order: ME slot instance -> scope top-level -> scope Multi/Sub sub-materials."

            messageBox msg title:"Consolidation Done" beep:true
            true
        )
    )
)

-- =========================================================
-- Put Materials into ME Slots (scope-aware, ruled, no duplicates)
-- =========================================================
fn fillMaterialEditorSlotsWithScopeMats_Ruled useSelection includeHidden =
(
    if useSelection and selection.count == 0 then
    (
        messageBox "Use Selection is ON, but nothing is selected." title:"Nothing Selected" beep:true
        false
    )
    else
    (
        local objArr = getWorkingObjects useSelection includeHidden
        if objArr.count == 0 then
        (
            messageBox "No objects found in scope (selection/scene + hidden filter)." title:"Nothing To Do" beep:true
            false
        )
        else
        (
            local mats = getUniqueTopLevelMaterialsFromObjects objArr
            if mats.count == 0 then
            (
                messageBox "No materials found on objects in scope." title:"Nothing To Do" beep:true
                false
            )
            else
            (
                local meData = getMEKeepersByName()
                local meMatsUnique = meData[1]

                -- Filter out anything already in ME slots (by reference)
                local filtered = #()
                for m in mats do
                (
                    if (findItem meMatsUnique m) == 0 then append filtered m
                )

                if filtered.count == 0 then
                (
                    messageBox "All scope materials already exist in the Material Editor slots.\nNothing new to place." title:"Nothing To Do" beep:true
                    false
                )
                else
                (
                    local multiMats = #()
                    local otherMats = #()

                    for m in filtered do
                    (
                        if isMultiSubMat m then append multiMats m
                        else append otherMats m
                    )

                    sortMaterialsByName multiMats
                    sortMaterialsByName otherMats
                    local ordered = join multiMats otherMats

                    local slotCount = getMESlotCountSafe()
                    local usedObjMats = getUsedObjectMaterialsTopLevel_AllScene()
                    local replaceableSlots = buildReplaceableSlotIndices usedObjMats slotCount

                    if replaceableSlots.count == 0 then
                    (
                        messageBox "No eligible Material Editor slots to replace.\n(All slots are protected, non-default, or contain maps.)" title:"No Slots Available" beep:true
                        false
                    )
                    else
                    (
                        local fillCount = amin ordered.count replaceableSlots.count
                        for k = 1 to fillCount do
                        (
                            local slotIndex = replaceableSlots[k]
                            meditMaterials[slotIndex] = ordered[k]
                            try (updateMTLInMedit ordered[k]) catch()
                        )

                        local msg =
                            "Scope: " + (if useSelection then "Selection" else "Scene") + (if includeHidden then " (incl. hidden)" else " (visible only)") + "\n\n" +
                            "New materials placed: " + (fillCount as string) + "\n" +
                            "Eligible slots found: " + (replaceableSlots.count as string) + "\n" +
                            "Multi/Sub queued: " + (multiMats.count as string) + " (sorted)\n" +
                            "Other queued: " + (otherMats.count as string) + " (sorted)\n" +
                            (if ordered.count > replaceableSlots.count then
                                ("\nNote: " + ((ordered.count - replaceableSlots.count) as string) + " material(s) didn’t fit in eligible slots.")
                             else "") + "\n\n" +
                            "Rules applied:\n" +
                            "1) Never overwrite slots containing maps.\n" +
                            "2) Never overwrite slots whose material is used by ANY object in the scene.\n" +
                            "3) Default '* - Default' slot materials are replaceable only if not used.\n" +
                            "Also: materials already present in ME were not duplicated."

                        messageBox msg title:"Material Editor Updated" beep:true
                        true
                    )
                )
            )
        )
    )
)

-- =========================================================
-- UI Rollout
-- =========================================================
rollout consolidateMatRollout versionCDM
(
    dotNetControl lblTitle "Label" pos:[2,2] width:296 height:30

    group ""
    (
        checkbox chkUseSelection "Use Selection" checked:false
            tooltip:"If ON: acts only on selected objects.\nIf OFF: acts on whole scene."

        checkbox chkIncludeHidden "Include Hidden Objects" checked:false
            tooltip:"If ON: includes hidden objects in the chosen scope.\nIf OFF: hidden objects are ignored."

        button btnConsolidate "Consolidate Materials" width:200
            tooltip:"Consolidates duplicate materials by NAME within scope, then normalizes/consolidates Multi/Sub-Object materials."

        button btnFillMEdit "Put Materials into ME Slots (1-24)" width:200
            tooltip:"Places scope materials into ME slots using rules:\n- Multi/Sub first (alphabetical)\n- Never overwrite map slots\n- Skip ME slots whose material is used by any object\n- Replace default '* - Default' if not used\n- Don't duplicate materials already in ME"
    )

    fn defColor r g b = (dotNetClass "System.Drawing.Color").FromArgb r g b
    fn defFontB fName fSize = (dotNetObject "System.Drawing.Font" fName fSize ((dotNetClass "System.Drawing.FontStyle").bold))

    on consolidateMatRollout open do
    (
        lblTitle.text = "Tacton Tools"
        lblTitle.textAlign = lblTitle.textAlign.MiddleCenter
        lblTitle.font = defFontB "Verdana" 10
        lblTitle.backColor = defColor 77 77 240
        lblTitle.foreColor = defColor 255 255 255
    )

    on btnConsolidate pressed do
    (
        undo "Consolidate Materials + Multi/Subs (Scoped)" on
        (
            lmConsolidateMaterials chkUseSelection.checked chkIncludeHidden.checked
        )
    )

    on btnFillMEdit pressed do
    (
        undo "Fill Material Editor Slots (Scoped, Ruled)" on
        (
            fillMaterialEditorSlotsWithScopeMats_Ruled chkUseSelection.checked chkIncludeHidden.checked
        )
    )
)

createDialog consolidateMatRollout width:300 --height:190
