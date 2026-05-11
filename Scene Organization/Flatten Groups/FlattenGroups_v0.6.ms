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
Flatten Groups is a utility that will ungroup all sub-groups of a selected group and keep them a part of that selected group. The group can still be within another group or linked to a helper.
There is an option to Ungroup Orphans which will ungroup a selected group if it only has one object within it, and it will then attach it to any group that it is still a part of.
*/


try (destroyDialog roll_FlattenGroup) catch ()
versionFG = "Flatten Groups v0.6"

rollout roll_FlattenGroup versionFG
(
	dotNetControl lblTitle "Label" pos:[2,2] width:296 height:30 -- Add Tacton Tools title block
	
	group "" (
		checkbox chkUngroupOrphans "Ungroup Orphans (single-object groups)" checked:true
		button btnFlatten "Flatten Selected Group(s)" width:180 height:30
	)

    fn ungroupOrphanGroup orphanGroup =
    (
        if isValidNode orphanGroup and isGroupHead orphanGroup then
        (
            try
            (
                local members = orphanGroup.children
                if members.count == 1 then
                (
                    local child = members[1]
                    local parentGroup = orphanGroup.parent
                    ungroup orphanGroup
                    if isValidNode child and isValidNode parentGroup and isGroupHead parentGroup then
                    (
                        if isGroupMember child do detachNodesFromGroup #(child)
                        attachNodesToGroup #(child) parentGroup
                        format "Ungrouped orphan group: % and attached % to %\n" orphanGroup.name child.name parentGroup.name
                    )
                )
            )
            catch (format "Failed to process orphan group: %\n" orphanGroup)
        )
    )

    fn flattenGroup groupHead =
    (
        if not isValidNode groupHead or not isGroupHead groupHead do return ()

        setGroupOpen groupHead true

        local groupMembers = groupHead.children
        local flattenedObjs = #()

        for obj in groupMembers do
        (
            if not isValidNode obj do continue

            if isGroupHead obj then
            (
                try
                (
                    local innerMembers = if isValidNode obj then obj.children else #()
                    if innerMembers.count > 1 then
                    (
                        local safeMembers = for i in innerMembers where isValidNode i collect i
                        ungroup obj
                        for itm in safeMembers where isValidNode itm do append flattenedObjs itm
                        format "Ungrouped nested group: %\n" obj.name
                    )
                    else
                    (
                        if isValidNode obj do append flattenedObjs obj
                    )
                )
                catch (format "Failed to ungroup nested group: %\n" obj)
            )
            else
            (
                append flattenedObjs obj
            )
        )

        -- Only attach valid, non-group-member nodes
        local validToAttach = for obj in flattenedObjs where isValidNode obj and not isGroupMember obj collect obj

        if validToAttach.count > 0 and isValidNode groupHead and isOpenGroupHead groupHead do
        (
            attachNodesToGroup validToAttach groupHead
            format "Reattached % objects into %\n" validToAttach.count groupHead.name
        )

        setGroupOpen groupHead false
    )

    on btnFlatten pressed do
    (
        if selection.count == 0 then
        (
            messageBox "Please select one or more group heads to flatten."
            return ()
        )

        undo "Flatten Groups" on
        (
            local originalSelection = selection as array
            local validGroups = for obj in originalSelection where isValidNode obj and isGroupHead obj collect obj

            for groupHead in validGroups do
            (
                if isValidNode groupHead and isGroupHead groupHead then
                (
                    if chkUngroupOrphans.checked and (groupHead.children.count == 1) then
                    (
                        ungroupOrphanGroup groupHead
                    )
                    else
                    (
                        flattenGroup groupHead
                    )
                )
                else
                (
                    format "Skipping deleted or invalid group: %\n" groupHead
                )
            )
        )

        messageBox "Flattening complete."
    )
	fn defColor r g b = (dotNetClass "System.Drawing.Color").FromArgb r g b
	fn defFontB fName fSize = (dotNetObject "System.Drawing.Font" fName fSize ((dotNetClass "System.Drawing.FontStyle").bold))
	on roll_FlattenGroup open do
	(
		-- UI Setup for Tacton Tools title block
		lblTitle.text = "Tacton Tools"
		lblTitle.textAlign = lblTitle.textAlign.MiddleCenter
		lblTitle.font = defFontB "Verdana" 10
		lblTitle.backColor = defColor 77 77 240
		lblTitle.foreColor = defColor 255 255 255
		
	)
)

createDialog roll_FlattenGroup width:300
