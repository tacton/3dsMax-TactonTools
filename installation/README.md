# Installation

Most Tacton Tools scripts can be run by dragging the script file directly into the 3ds Max viewport, or via **Scripting > Run Script** and selecting the file.

Some scripts are **macroscripts** and need to be added to a toolbar before they can be launched. These typically use the `.mcr` extension, though some `.ms` files may also be macroscripts. When you run a macroscript, nothing will appear to happen — it has been installed to 3ds Max but needs a toolbar button to launch from. Follow the steps below to set this up.
> **Note:** Tacton Tools MaxScripts were tested on 3ds Max 2024 and newer. Any MaxScripts requiring a newer version will be noted in the tool's documentation.

## Adding Macroscripts to a Toolbar

**1.** In the 3ds Max top menu, go to **Customize > Customize User Interface > Toolbars**.

![](<1_TactonTools_Installation_Customize User Interface.jpg>)

**2.** Create a new toolbar by pressing **New** on the right side.

![](<2_TactonTools_Installation_Press New Toolbar.jpg>)

**3.** A **New Toolbar** dialog will appear. Name it `Tacton Tools` and press **OK**.

![](<3_TactonTools_Installation_Name Toolbar.jpg>)

**4.** The new toolbar will appear floating in the center of the screen. It can be docked anywhere in the 3ds Max interface.

![](<4_TactonTools_Installation_Toolbar Created.jpg>)

**5.** Still in the **Customize User Interface > Toolbars** window, change the **Category** to `Tacton Tools`. This filters the list to show only Tacton Tools macroscripts.

![](<5_TactonTools_Installation_Category Tacton Tools.jpg>)

**6.** Drag the macroscript you installed to the toolbar you created.

![](<6_TactonTools_Installation_Drag Script to Toolbar.jpg>)

**7.** The macroscript button will now appear on the toolbar and can be launched by pressing it.

> **Note:** If the toolbar is docked on the left or right side, buttons may appear too narrow to read. To fix this, go to **Customize > Preference Settings > General** tab. In the **UI Display** section on the right, find **Fixed Width Text Buttons** and either increase the pixel count or uncheck it entirely — the buttons will then resize to fit the longest script name.
