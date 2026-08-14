# QMap Godot

**Lightweight loader & editor for Quake & Source style Maps, Wads, and FGDs**

[![Godot](https://img.shields.io/badge/Godot-4.6%2B-478cbf?logo=godot-engine&logoColor=white)](https://godotengine.org/download)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Status](https://img.shields.io/badge/status-WIP-orange)](#roadmap)

QMap Godot brings classic id Tech / Source-style level authoring into the Godot editor. Import `.map` geometry, `.wad` textures, and `.fgd` entity definitions directly into your project — no external conversion step required.
 
<!-- 
  Todo:
  ![QMap Godot editor preview](preview.gif)
-->

## Features
 
- **`.map` loading** — Parse and import Quake/Source-format map files directly into Godot, and support user-designed levels natively in your project.
- **WAD texture support** — Read textures directly from `.wad` archives, view them in-editor, and apply them directly to brushes.
- **FGD entity definitions** — Build and edit `.fgd` files in-editor, giving full control of how entities are loaded and managed, fully ready to hook into Godot nodes and scripts.

## Requirements
 
- [Godot 4.6+](https://godotengine.org/download)

## Installation
 
1. Download or clone this repository.
2. Copy the plugin folder into your project's `addons/` directory.
3. In Godot, go to **Project → Project Settings → Plugins** and enable **QMap Godot**.

## Usage

Any `.map` editor can be used, including importing directly from old Quake/Source games. My personally preferred editor is [TrenchBroom](https://trenchbroom.github.io/).

<!-- 
Todo:
Add details on using and loading .map, .wad, and .fgd files
-->
 
## Roadmap
 
This project is a **work in progress**. Planned/upcoming work:

- [ ] Documentation & example project
- [ ] Improved entity property inspector
- [ ] Improved in-editor WAD editing

## Contributing
 
Issues and pull requests are welcome — this project is actively evolving, so feedback on real-world use cases is especially helpful.
 
## License
 
Licensed under the [MIT License](LICENSE).

## Support

If you enjoy this project, consider supporting development:

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/joaquinkiko)
