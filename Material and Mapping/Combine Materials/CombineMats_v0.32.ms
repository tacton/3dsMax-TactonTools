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
Combine Materials: Save your work before using!
This maxscript is meant to combine materials to a Multi/Sub-Object material. This allows one to
create what is essentially a library of materials. It will compare the materials applied to each
object in a selection, and if they do not already exist in the Multi/Sub-Object material defined
in the Master Material Position, it will add them. It will then reassign that Multi/Sub-Object
material to the object, and adjust the material IDs as needed.

WARNING: This script should be ran before assigning other modifiers such as deformers or UVW Maps
to the objects.

Another utility within it is Rename Similar Mats. This is for when materials come in with
generic names, but have the color/albedo/diffuse and other attributes assigned. It will attempt
to compare these attributes, and if they match, it will rename that material the same. After this
is done, Combine Mats & Assign can be run to add that object to the Multi/Sub-Object material with
the correct Material IDs.
*/

try(destroyDialog reorderMaterialIDsRollout)catch()
global newMat = undefined
global selectedAndDependents = #()

versionRMID = "Combine Materials v0.33"

-- =========================================================
-- Helpers (NEW / SAFE)
-- =========================================================

fn isMeshOrPolyNode o =
(
    if (isValidNode o) == false then false
    else
    (
        local base = classof o.baseObject
        (base == Editable_Mesh) or (base == Editable_Poly)
    )
)

fn isProcessableGeometryNode o =
(
    if (isValidNode o) == false then false
    else if (superClassOf o != GeometryClass) then false
    else if (isGroupHead o) then false
    else isMeshOrPolyNode o
)

-- Try old method first; if it throws "Cannot change mesh with modifiers present", we fall back to meshop.
fn canUseOldMeshFaceOps o =
(
    if (isValidNode o) == false then false
    else if (classof o.baseObject != Editable_Mesh) then false
    else if (o.modifiers.count > 0) then false
    else
    (
        -- Test a READ call. Some CAD derived objects allow read but fail on write,
        -- so the final protection is still the write-try in the remap loop.
        local ok = true
        try( if o.numfaces > 0 do (getFaceMatID o 1) ) catch(ok = false)
        ok
    )
)

fn getFaceMatID_MeshSmart o f useMeshOp =
(
    if useMeshOp then
        (try(meshop.getFaceMatID o f)catch(1))
    else
        (try(getFaceMatID o f)catch(1))
)

fn setFaceMatID_MeshSmart o f id useMeshOp =
(
    if useMeshOp then
        (try(meshop.setFaceMatID o f id)catch(false))
    else
        (try(setFaceMatID o f id; true)catch(false))
)

fn getMeshFaceCountSmart o useMeshOp =
(
    if useMeshOp then (try(meshop.getNumFaces o)catch(0))
    else (try(o.numfaces)catch(0))
)

-- Safe: open groups for selection (so closed groups won’t block access)
function openGroups mySelection =
(
    for obj2 in mySelection do
    (
        if isGroupHead obj2 then setGroupOpen obj2 true
    )
)

fn addInstancesToSel obj selectedAndDependents =
(
    selectedAndDependents = #()
    for obj in selection do
    (
        InstanceMgr.GetInstances obj &instances
        selectedAndDependents += instances
    )
    select selectedAndDependents
    selectedAndDependents = selection
    ForceCompleteRedraw()
)

-- =========================================================
-- Original functions (kept, only minor internal safety where needed)
-- =========================================================

-- Function to get a material by its name
fn getMaterialByName matName =
(
    for m in sceneMaterials where m.name == matName do return m
    undefined
)

-- Function to assign temporary material to empty slots
fn assignTempMatToEmptySlots newMat =
(
    local deleteMat = meditMaterials[19]

    if deleteMat == undefined or deleteMat.name != "DELETE_ME" then
    (
        deleteMat = standardMaterial name:"DELETE_ME"
        deleteMat.diffuse = color 255 0 255
        meditMaterials[19] = deleteMat
    )

    for i = 1 to newMat.numsubs do
    (
        if newMat[i] == undefined then newMat[i] = deleteMat
    )
)

-- Function to clear DELETE_ME material from the new Multi/Sub-Object material
fn clearAllMaterials newMat =
(
    for i = 1 to newMat.numsubs do
    (
        if newMat[i] != undefined and newMat[i].name == "DELETE_ME" then
            newMat[i] = undefined
    )
)

-- Function to add new sub-materials to the new material
-- (kept logic, but made mesh face-ID reads safe for CAD-derived mesh)
fn addNewSubMats oldMat newMat obj =
(
    if classOf oldMat == Multimaterial then
    (
        oldOrder = for i = 1 to oldMat.numsubs where oldMat[i] != undefined collect oldMat[i].name
        newOrder = for i = 1 to newMat.numsubs where newMat[i] != undefined collect newMat[i].name

        usedMatIDs = #{}

        if classOf obj.baseObject == Editable_Mesh then
        (
            local useMeshOp = not (canUseOldMeshFaceOps obj)
            local fc = getMeshFaceCountSmart obj useMeshOp
            for i = 1 to fc do
            (
                append usedMatIDs (getFaceMatID_MeshSmart obj i useMeshOp)
            )
        )
        if classOf obj.baseObject == Editable_Poly then
        (
            local fc = polyop.getNumFaces obj
            for i = 1 to fc do append usedMatIDs (polyop.getFaceMatID obj i)
        )

        for i = 1 to oldOrder.count do
        (
            oldSubMat = oldOrder[i]
            if findItem newOrder oldSubMat == 0 and usedMatIDs[i] then
            (
                newSubMat = copy oldMat[i]
                newSubMat.name = oldSubMat
                newMat.numsubs = newMat.numsubs + 1
                newMat[newMat.numsubs] = newSubMat
            )
        )
    )
    else
    (
        newOrder = for i = 1 to newMat.numsubs where newMat[i] != undefined collect newMat[i].name
        if findItem newOrder oldMat.name == 0 then
        (
            newSubMat = copy oldMat
            newSubMat.name = oldMat.name
            newMat.numsubs = newMat.numsubs + 1
            newMat[newMat.numsubs] = newSubMat
        )
    )
)

-- =========================================================
-- Reorder material IDs (only change: mesh uses old method unless it fails, then meshop)
-- =========================================================

fn reorderMatIDsEditableMesh obj newMat =
(
    oldMat = obj.material

    local preferOld = canUseOldMeshFaceOps obj
    local useMeshOp = not preferOld

    if classOf oldMat == Multimaterial then
    (
        addNewSubMats oldMat newMat obj

        oldOrder = for i = 1 to oldMat.numsubs where oldMat[i] != undefined collect oldMat[i].name
        newOrder = for i = 1 to newMat.numsubs where newMat[i] != undefined collect newMat[i].name

        idMap = #()
        for i = 1 to oldOrder.count do
        (
            oldSubMat = oldOrder[i]
            newID = findItem newOrder oldSubMat
            append idMap newID
        )

        -- FAST PATH: try old setFaceMatID if allowed; if it errors, retry with meshop
        local fc = getMeshFaceCountSmart obj useMeshOp

        local hadWriteError = false
        if not useMeshOp then
        (
            for i = 1 to fc while not hadWriteError do
            (
                oldID = getFaceMatID_MeshSmart obj i false
                if oldID <= idMap.count then
                (
                    if (setFaceMatID_MeshSmart obj i idMap[oldID] false) == false then
                        hadWriteError = true
                )
            )

            if hadWriteError then
            (
                -- Fall back to meshop for this object
                useMeshOp = true
                fc = getMeshFaceCountSmart obj true

                for i = 1 to fc do
                (
                    oldID = getFaceMatID_MeshSmart obj i true
                    if oldID <= idMap.count do
                        setFaceMatID_MeshSmart obj i idMap[oldID] true
                )
            )
        )
        else
        (
            -- meshop path from the start
            for i = 1 to fc do
            (
                oldID = getFaceMatID_MeshSmart obj i true
                if oldID <= idMap.count do
                    setFaceMatID_MeshSmart obj i idMap[oldID] true
            )
        )
    )
    else
    (
        addNewSubMats oldMat newMat obj
        newID = findItem (for i = 1 to newMat.numsubs collect newMat[i].name) oldMat.name

        if newID != 0 then
        (
            local fc = getMeshFaceCountSmart obj useMeshOp

            local hadWriteError = false
            if not useMeshOp then
            (
                for i = 1 to fc while not hadWriteError do
                (
                    if (setFaceMatID_MeshSmart obj i newID false) == false then hadWriteError = true
                )

                if hadWriteError then
                (
                    useMeshOp = true
                    fc = getMeshFaceCountSmart obj true
                    for i = 1 to fc do setFaceMatID_MeshSmart obj i newID true
                )
            )
            else
            (
                for i = 1 to fc do setFaceMatID_MeshSmart obj i newID true
            )
        )
    )
)

fn reorderMatIDsEditablePoly obj newMat =
(
    oldMat = obj.material

    if classOf oldMat == Multimaterial then
    (
        addNewSubMats oldMat newMat obj

        oldOrder = for i = 1 to oldMat.numsubs where oldMat[i] != undefined collect oldMat[i].name
        newOrder = for i = 1 to newMat.numsubs where newMat[i] != undefined collect newMat[i].name

        idMap = #()
        for i = 1 to oldOrder.count do
        (
            oldSubMat = oldOrder[i]
            newID = findItem newOrder oldSubMat
            append idMap newID
        )

        for i = 1 to polyOp.getNumFaces obj do
        (
            oldID = polyOp.getFaceMatID obj i
            if oldID <= idMap.count do polyOp.setFaceMatID obj i idMap[oldID]
        )
    )
    else
    (
        addNewSubMats oldMat newMat obj
        newID = findItem (for i = 1 to newMat.numsubs collect newMat[i].name) oldMat.name
        if newID != 0 then
        (
            for i = 1 to polyOp.getNumFaces obj do polyOp.setFaceMatID obj i newID
        )
    )
)

-- =========================================================
-- Compare Materials (unchanged)
-- =========================================================

fn compareMaterials mat1 mat2 useRoughness useMetalness =
(
    if (classof mat1 == PhysicalMaterial) and (classof mat2 == PhysicalMaterial) then
    (
        local baseColor1 = mat1.base_color / 255
        local baseColor2 = mat2.base_color / 255
        local roughnessMatch = true
        local metalnessMatch = true

        if useRoughness then roughnessMatch = (mat1.roughness == mat2.roughness)
        if useMetalness then metalnessMatch = (mat1.metalness == mat2.metalness)

        (baseColor1 == baseColor2) and roughnessMatch and metalnessMatch
    )
    else if (classof mat1 == StandardMaterial) and (classof mat2 == StandardMaterial) then
    (
        local diffuseMatch = (mat1.diffuse == mat2.diffuse)

        local specularLevelMatch = true
        local glossinessMatch = true

        if useMetalness then specularLevelMatch = (mat1.specularLevel == mat2.specularLevel)
        if useRoughness then glossinessMatch = (mat1.glossiness == mat2.glossiness)

        diffuseMatch and specularLevelMatch and glossinessMatch
    )
    else false
)

-- =========================================================
-- UI
-- =========================================================

rollout reorderMaterialIDsRollout versionRMID
(
	dotNetControl lblTitle "Label" pos:[2,2] width:196 height:30
	
    group "Combine Multi/Sub-Object Materials"
    (
        button btnCombineMSOMats "Combine Mats & Assign" width:160 height:24 align:#center offset:[0,0]
        tooltip:"Select object(s) that you want to assign the Multi/Sub-Object material in the first slot of the Material Editor. New materials will be added to the Multi/Sub-Object material. It will not add materials into empty slots."

        label type_spinnerMatPos "Master Material Position:" align:#left across:2
        tooltip:"Position of Multi/Sub-Object material in the Material Editor that new materials will be added to, and assigned to the selected objects and their instances."

        spinner matPosition "" width:30 height:16 range:[1,24,1] type:#integer scale:1 --pos:[142,52]
        tooltip:"Position of Multi/Sub-Object material in the Material Editor that new materials will be added to, and assigned to the selected objects and their instances."

        on btnCombineMSOMats pressed do
        (
            newMat = meditMaterials[matPosition.value]
            if classof newMat == Multimaterial then
            (
                undo "Combine Mats & Assign" on
                (
                    -- 1) Expand instances + open groups FIRST (so closed groups don't break processing)
                    local OGselection = selection as array

                    addInstancesToSel obj selectedAndDependents
                    openGroups selection
                    -- keep the original behavior of restoring then re-expanding
                    Select OGselection
                    addInstancesToSel obj selectedAndDependents

                    -- 2) Only process valid mesh/poly geometry nodes (skip helpers, group heads, etc.)
                    local procSel = for o in selection where isProcessableGeometryNode o collect o

                    if procSel.count == 0 then
                    (
                        messageBox "No Editable Mesh/Poly geometry objects found to process.\n(Helpers, group heads, and non-mesh objects are ignored.)"
                    )
                    else
                    (
                        -- Keep your DELETE_ME workflow; do it once per run (faster)
                        assignTempMatToEmptySlots newMat

                        for obj in procSel do
                        (
                            if classOf obj.baseObject == Editable_Mesh do
                            (
                                reorderMatIDsEditableMesh obj newMat
                            )

                            if classOf obj.baseObject == Editable_Poly do
                            (
                                reorderMatIDsEditablePoly obj newMat
                            )

                            update obj
                        )

                        clearAllMaterials newMat

                        -- 3) Assign master material to the processed objects (and their instances already in selection)
                        procSel.material = newMat

                        -- Keep your UI refresh behavior
                        deselect
                        redrawViews()
                        ForceCompleteRedraw()
                    )
                )
            )
            else
            (
                messageBox "Please select a position in the Compact Material Editor that has a Multi/Sub-Object material."
            )
        )

        on btn_SelInst pressed do undo on
        (
            local OGselection = selection as array
            addInstancesToSel obj selectedAndDependents
            openGroups selection
            Select OGselection
            addInstancesToSel obj selectedAndDependents
            redrawViews()
        )
    )

    group "Rename Similar Mats"
    (
        button btnCombineDup "Rename by Similar Material" width:160 height:24 align:#center offset:[0,0]
        tooltip:"Select object(s) that you want compared to a Multi/Sub-Object material in the slot defined below. Matching attributes will rename the material."

        label type_spinnerMatCmpPos "Multi/Sub-Object Position:" align:#left across:2
        tooltip:"Position in the Material Editor that the object's material is being compared to."

        spinner matCmpPosition "" width:30 height:16 range:[1,24,1] type:#integer scale:1 --pos:[142,125]
        tooltip:"Position in the Material Editor that the object's material is being compared to."

        label type_IgnorePhyMat "Ignore Attributes" align:#left
        checkbox chk_roughness "Ignore Roughness/Glossiness"
        tooltip:"Ignore Roughness (Physical) / Glossiness (Standard)."
        checkbox chk_metalness "Ignore Metalness/Specular"
        tooltip:"Ignore Metalness (Physical) / Specular (Standard)."

        on btnCombineDup pressed do
        (
            local selectedCmpMat = meditMaterials[matCmpPosition.value]
            if classof selectedCmpMat == Multimaterial then
            (
                for obj in selection do
                (
                    if obj.material != undefined then
                    (
                        local mat = obj.material
                        if classof mat == Multimaterial then
                        (
                            for subMat in mat.materialList do
                            (
                                for masterSubMat in selectedCmpMat.materialList do
                                (
                                    if compareMaterials subMat masterSubMat (not chk_roughness.checked) (not chk_metalness.checked) then
                                        subMat.name = masterSubMat.name
                                )
                            )
                        )
                        else
                        (
                            for masterSubMat in selectedCmpMat.materialList do
                            (
                                if compareMaterials mat masterSubMat (not chk_roughness.checked) (not chk_metalness.checked) then
                                    mat.name = masterSubMat.name
                            )
                        )
                    )
                )
            )
            else
            (
                messageBox "Please select a position in the Compact Material Editor that has a Multi/Sub-Object material."
            )
        )
    )

    group "Misc Utilies"
    (
        button btn_SelInst "Select Instances" width:160 height:24 align:#center offset:[0,0]
        tooltip:"Selecting the instances of selected objects. Opens any groups that instances are a part of."
    )
	
	fn defColor r g b = (dotNetClass "System.Drawing.Color").FromArgb r g b
    fn defFontB fName fSize = (dotNetObject "System.Drawing.Font" fName fSize ((dotNetClass "System.Drawing.FontStyle").bold))

    on reorderMaterialIDsRollout open do
    (
        lblTitle.text = "Tacton Tools"
        lblTitle.textAlign = lblTitle.textAlign.MiddleCenter
        lblTitle.font = defFontB "Verdana" 10
        lblTitle.backColor = defColor 77 77 240
        lblTitle.foreColor = defColor 255 255 255
    )
)

createDialog reorderMaterialIDsRollout 200 295
