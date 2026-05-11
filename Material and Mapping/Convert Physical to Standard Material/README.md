# Convert Physical to Standard Material

Converts Physical Materials to Standard (Legacy) materials quickly.

![](<Convert Physical Mat to Standard Mat.jpg>)

## Overview

Large numbers of Physical Materials — especially when used within Multi/Sub-Object materials — export slower and produce larger FBX files. Converting to Standard (Legacy) materials before export can significantly improve performance when exporting many FBX files from 3ds Max.

> **Note:** A future version will support converting back to Physical Materials.

## Options

- **Add `_STD` suffix** — Appends `_STD` to converted material names. Off by default.
- **Convert entire scene** — When enabled, converts all Physical Materials in the scene. When disabled, converts only the material currently selected in the Compact or Slate Material Editor.
