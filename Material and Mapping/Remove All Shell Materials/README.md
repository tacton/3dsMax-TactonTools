# Remove All Shell Materials

Removes all Shell Materials from the scene and replaces them with their Original Material.

![](<Remove All Shell Materials.jpg>)

## Overview

Shell Materials are created automatically by 3ds Max during render-to-texture (baking) workflows. They wrap two materials — an **Original Material** and a **Baked Material** — so both can coexist on an object. Once baking is complete, the Shell Material wrapper is often no longer needed.

This script scans all objects in the scene, finds any that have a Shell Material applied, and replaces it with the Original Material from within the shell. It repeats this process until no Shell Materials remain, handling cases where shells may be nested within one another.

## How to Use

Press **Remove Shell Materials**. A confirmation message will appear when all Shell Materials have been removed.
