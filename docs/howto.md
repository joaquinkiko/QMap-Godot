# How To Use

- [Quick Start](#Quick-Start)
- [The MapLoader](#The-MapLoader)
- [QMap Settings](#QMap-Settings)
- [The FGD (Entity Definitions)](#The-FGD-(Entity-Definitions))
- [Setting Up TrenchBroom](#Setting-Up-TrenchBroom)
- [Runtime Entity Spawning](#Runtime-Entity-Spawning)
- [Loading WADs and Palettes Manually](#Loading-WADs-and-Palettes-Manually)
- [Textures & Materials](#Textures-&-Materials)
- [Geometry Generation Per Entity](#Geometry-Generation-Per-Entity)
- [Groups, Layers, and Targets](#Groups,-Layers,-and-Targets)
- [Coordinates & Units](#Coordinates-&-Units)
- [Tips & Troubleshooting](#Tips-&-Troubleshooting)

## Quick Start
 
1. Add a **MapLoader** node to your scene
2. Set **Map Path** to a `.map` file
3. Assign a **Settings** resource (a `QMapSettings` resource), or use the default settings
4. On that settings resource, set **FGD** to your game's `.fgd` file, or use the built in `base.fgd`
5. Run the scene! By default `auto_load_map` is `true`, so the map builds itself in `_ready()`

If you disable `auto_load_map` or want to load a different map at runtime, just call:
```gdscript
await $MapLoader.load_map()
```
 
You can also build a ready-to-instantiate scene without touching the tree:
 
```gdscript
var packed_scene := MapLoader.create_map_scene("res://maps/dm1.map", preload("res://settings/game_settings.tres"))
var instance := packed_scene.instantiate()
add_child(instance)
```
 
## The MapLoader
 
`MapLoader.load_map()` manages the whole loading process: parsing the `.map` file, loading textures/WADs, generating materials, spawning entity nodes, building brush geometry (render mesh, collision, occlusion, navigation), and finally attaching everything as children of the `MapLoader` node. It's `async` function so always use `await` it if calling manually.
 
Loading progress is reported via a signal:
 
```gdscript
func _ready() -> void:
    $MapLoader.progress.connect(_on_progress)
 
func _on_progress(percentage: float, task: String) -> void:
    print("%.0f%% — %s" % [percentage * 100.0, task])
```
 
Heavy steps are threaded by default (`allow_threading`), but can be disabled for easier debugging.

`pause_main_thread_while_loading` (default on) blocks the main thread until the map is fully loaded, which is faster but freezes the game until it's completed. You can turn this off if you want a responsive loading screen, or want the map to load in the background.
 
| Property | Type | Description |
|---|---|---|
| `map_path` | `String` (`.map` file) | Map to load on `load_map()`. |
| `map` | `QMap` | The parsed map resource (populated after loading; `null` while idle). |
| `settings` | `QMapSettings` | Generation settings, including the `FGD`. |
| `auto_load_map` | `bool` | Calls `load_map()` automatically in `_ready()`. Default `true`. |
| `auto_load_internal_wads` | `bool` | Loads any WAD files listed in the map's `worldspawn` `"wad"` key. Default `true`. |
| `allow_threading` | `bool` | Runs generation stages on worker threads. Default `true`. |
| `pause_main_thread_while_loading` | `bool` | Blocks the main thread until each stage completes. Default `true`. |
| `group_nodes` | `bool` | Groups Trenchbroom/editor "layers" and "groups" under their own `Node3D`. Default `true`. |
| `verbose` | `bool` | Print progress/timing to the console. |
| `show_non_rendered_textures` | `bool` | Debug option to render normally-hidden textures (clip, skip, trigger, etc.). |
 
**Static:**
- `MapLoader.current` — last `MapLoader` added to the tree (may be `null`).
- `MapLoader.create_map_scene(path, settings) -> PackedScene` — builds a `PackedScene` wrapping a configured `MapLoader`, without adding it to a running tree.
**Signals:**
- `progress(percentage: float, task: String)` — emitted at each pipeline stage, `percentage` from `0.0` to `1.0`.
**Methods:**
- `load_map() -> Error` — runs the full load/generate pipeline. `await` it.
- `clear_children()` — frees all children, for reloading a map on the same node.
- `spawn_entity(classname: String, properties: Dictionary = {}, origin := Vector3.ZERO) -> Node` — spawns a single runtime entity the same way the map loader would (looks up an FGD-matching scene, applies parsed properties, adds it as a child). Useful for spawning pickups, projectiles, etc. that should behave like map entities.
- `get_entities(filter: String) -> Array[Node]` — returns spawned entities (children of this `MapLoader`) whose node name matches a wildcard filter (`*`, `?`). Node names default to the entity's classname.
- `set_target_destination(target_name: String, node: Node)` / `find_target_destination(target_name: String) -> Node` — the `target`/`targetname` linking system used by `target_source`/`target_destination` FGD properties (e.g. triggers finding the door they open).

## QMap Settings
 
Created via **New Resource → QMapSettings**.

Key groups:
 
- **FGD** — `fgd: FGD` — the entity definitions used for this map. This is the one required field, everything else is optional to modify.
- **Scaling** — `scaling` (Quake units per Godot unit, `32`), `unwrap_uvs` (for lightmapping).
- **Special Textures** — `texture_origin` marks origin brushes (used by many map editors for rotation pivots).
- **Smart Tags** (`smart_tags: Array[QMapSmartTag]`) — rules that mark textures, classnames, surface flags, or content flags as non-rendered, non-colliding, non-pathfinding, transparent (skips occlusion), or force-convex-collision. This is how you implement advanced things like `clip`, `trigger`, `sky`, or `skip` textures.
- **Face Attributes** — `surface_flags` / `content_flags`: ordered lists of `QMapFaceAttribute` used for advanced Quake/Source surface & content flag features, and used by Smart Tags.
- **Texture Settings** — Default texture and material extensions to load from, as well as any WADs that should be loaded **in addition** to map specific WADs.
- **Resource Paths** — `base_path` plus subfolders (`path_textures`, `path_materials`, `path_sounds`, `path_models`, `path_scenes`, `path_skies`, `path_decals`) resolved as `res://<base_path>/<path_x>/...` for loading resources from. Additional base paths will also be searched as "Mods" (via the map's `_tb_mod` key).
- **PBR Texture** — filename suffixes for applying PBR textures
- **Default Material** — This material will be used for all WAD and loose. You can also toggle allowing animated textures, which follow naming conventions of [Quake's animated textures](https://quakewiki.org/w/index.php?title=Textures)
- **Worldspawn Properties** — Default property-key names (e.g. `_sunlight`, `_fog_density`, `skyname`) used to auto-generate a `WorldEnvironment` and `DirectionalLight3D` from `worldspawn` keys, matching common Quake/Source light/fog conventions.
- **General Entity Properties** — property keys for per-entity render/physics behavior (`_render_transparency`, `_render_shadows`, `_physics_layer`, `_physics_mask`, `_physics_linear_velocity`, etc.).
- **Pathfinding** — `generate_pathfinding`, `default_nav_mesh`, plus `_enter_cost`/`_travel_cost` brush property keys allow you to control how pathfinding is generated
- **Trenchbroom** — an editor-only button that exports the current FGD, WADs, smart tags, and flags as a ready-to-use Trenchbroom game config, so your level designers get an editor that matches your Godot setup.

## The FGD (Entity Definitions)
 
The `fgd` field on `QMapSettings` points to an `FGD` resource. QMap Godot reads and writes **standard `.fgd` text files** (the same format used by Trenchbroom, Hammer, J.A.C.K., etc.) natively. For example:
 
```fgd
@SolidClass = worldspawn : "World entity" []
 
@BaseClass = Targetname : "Baseclass for giving entity a target source"
[
    targetname(target_source) : "Name"
]
 
@PointClass base(Targetname) color(220 30 30) size(-16 -16 -16, 16 16 16) = info_player_start : "Player spawn point"
[
    angle(angle) : "Facing direction" : "0"
]
 
@SolidClass = func_door : "A sliding door"
[
    speed(integer) : "Speed" : "100"
    target(target_destination) : "Target"
]
```
 
- **`@BaseClass`** — a reusable property set (inherited via `base(...)`), not spawnable itself.
- **`@SolidClass`** — a brush entity (has volume/geometry).
- **`@PointClass`** — a point entity (spawns at a location, no brushes).
- **`@include "other.fgd"`** — pulls in another FGD's classes (this is what the `base_fgds` field represents). The addon features a built-in `base.fgd` with common helpers (`worldspawn`, `func_brush`, `func_detail`, `func_illusionary`, `func_group`, and `Phong`/`Targetname`/`Target` base classes) that you can `@include` from your own FGD.
- Supported property types: `string`, `integer`, `float`, `flags`, `choices`, `color255`, `color1`, `angle`, `vector`, `scale`, `target_source`, `target_destination`, `decal`, `studio`, `sprite`, `sound`, `res` (loads a `Resource`), `respath` (returns a resource path string).
Properties typed `res`/`respath`/`decal`/`studio`/`sprite`/`sound` are resolved against the settings' resource paths automatically, and `target_source`/`target_destination` properties power the `targetname`-style linking system.

You can read more general knowledge about FGD files [here](https://developer.valvesoftware.com/wiki/FGD).
 
### Connecting entity classnames to Godot scenes
 
If a `.tscn`/`.scn` exists at `<path_scenes>/<classname>.tscn` (checked across `base_path` and any mods), that scene is instantiated for matching entities instead of a plain `Node`. Parsed FGD properties are then applied directly by name via `node.set(key, value)`, so exposing a matching `@export var speed: int` on your scene's script lets it be driven straight from the map. If the instanced root defines `_apply_map_properties(properties: Dictionary)`, it's called with all parsed properties as a convenience hook for anything that isn't a simple exported property.
 
Entities without a matching scene become a plain `Node` (no brushes) or `StaticBody3D` (has brushes) with `Position`, `Rotation`, `Scale`, and (if applicable) `Group`/`Layer` nesting still applied from the map data.
 
## Setting Up TrenchBroom
 
TrenchBroom is the recommended editor for building `.map` files for QMap Godot. There are two directories involved, and it's easy to mix them up:
 
- **TrenchBroom's "games" folder** — lives outside your Godot project, in TrenchBroom's own user data directory. TrenchBroom scans this on startup to populate its list of games.
- **Your Godot project folder** — where your textures, FGD, and `.map` files actually live. This is what you'll point TrenchBroom's "Game Path" at.

### 1. Tell Godot where TrenchBroom's games folder is
 
The plugin adds settings under **Editor → Editor Settings → qmap → Trenchbroom** (these are Godot *Editor* Settings for just your machine, not Project Settings, so if you're woking as a team each person can assign this for themselves):
 
- **`Games Config Dir`** — absolute path to TrenchBroom's `games` folder on disk. This is where the plugin will write your exported config. Typical default locations:
  - Windows: `%AppData%\TrenchBroom\games`
  - macOS: `~/Library/Application Support/TrenchBroom/games`
  - Linux: `~/.TrenchBroom/games` (or, for the AppImage build, a `TrenchBroom.AppImage.home/.TrenchBroom/games` folder next to the AppImage if you're using portable mode)
  You can also open this folder directly from inside TrenchBroom via the folder icon at the bottom of the games list in **Preferences**.
- **`Config Version`** — the target `GameConfig.cfg` version (`Latest`, `4`, `8`, or `9`). Don't touch this unless you're supporting an older TrenchBroom release.

### 2. Export your game config from Godot
 
Before exporting, make sure:

- Your project has a name set under **Project → Project Settings → Application → Config → Name** (this becomes both the config folder name and the entry TrenchBroom lists).
- Your `QMapSettings` resource has `fgd` assigned.
- `Games Config Dir` above is set.

Then open your `QMapSettings` resource, scroll to the **Trenchbroom** group, and click **Export Trenchbroom Config**. This creates `<games_config_dir>/<YourProjectName>/` and writes:
 
- `GameConfig.cfg` — generated from your settings' texture extensions, PBR exclusions, palette path, UV scale, smart tags, and surface/content flags.
- Your FGD, plus any `@include`d base FGDs (e.g. the bundled `base.fgd`), copied in as plain `.fgd` files.
- `icon.png` — your project icon, resized to 32×32, if `application/config/icon` is set.

Re-click the button any time your FGD, smart tags, flags, or icon change — it overwrites the existing files in place. You may need to restart TrenchBroom for it to register the change.
 
### 3. Link TrenchBroom to your project directory
 
Open TrenchBroom and go to **View → Preferences** (or **TrenchBroom → Preferences** on macOS), then select your project's entry in the games list. Set **Game Path** to your Godot project's folder. TrenchBroom looks for textures under `<Game Path>/<path_textures>/...`, so this needs to line up with `path_textures` on your settings resource (`textures` by default) or texture browsing will come up empty.
 
If you use WADs instead of loose texture folders, TrenchBroom will pick them up via the `wad` key on `worldspawn` once you add them from the Face inspector and the paths get written into the map automatically. Note that many WADs require a `palette.lmp` file at the path specified in your settings to register in TrenchBroom.
 
### 4. Create a map
 
- **File → New Map**, then pick your project from the **Select Game** list.
- Choose a **map format** — `Valve` (220) is generally the better default since it stores UVs independent of face axis and survives non-axis-aligned rotations cleanly, though `Standard` also works well. QMap loader will be able to handle whichever you choose.
- Build brushes and place entities — your FGD's `@PointClass`/`@SolidClass` entries populate the entity browser, with their `size()`/`color()` helpers controlling how they're previewed in the 3D view.
- Save the `.map` file somewhere inside your project (e.g. `res://maps/`) so it shows up as an importable resource for `MapLoader.map_path`.

One more editor setting worth knowing about: **`qmap/ignore_map_autosave_dir`** (on by default) tells the plugin to drop a `.gdignore` file into the `autosave` folder TrenchBroom creates next to your maps, so Godot's filesystem dock doesn't try to import TrenchBroom's autosave backups as map resources.
 
## Runtime Entity Spawning
 
Because the FGD → scene → property pipeline is exposed via `spawn_entity()`, you can spawn map-consistent entities outside of map loading (e.g. a weapon that spawns `item_shell` pickups on death):
 
```gdscript
MapLoader.current.spawn_entity("item_health", {"amount": "25"}, global_position)
```
 
## Loading WADs and Palettes Manually
 
WADs (`.wad`) referenced by a map's `worldspawn` `"wad"` key are loaded automatically when `auto_load_internal_wads` is on. You can also always-include extra WADs via `QMapSettings.extra_wads`, or even load one manually:
 
```gdscript
var wad: WAD = load("res://textures/gfx.wad")
```
 
- `WAD2`-format WADs store colors through a `QPalette` resource (`.lmp`), which the plugin ships a default Quake palette for at `default_resources/palette.lmp`.
- `WAD3`-formate WADs have their color palettes built in.
 
## Textures & Materials
 
For each unique texture name referenced by a map, QMap Godot resolves a `Texture2D` and a `Material` independently, in this order:
 
**Texture lookup**:
1. An imported resource under `<base_path>/<path_textures>/<name>.<ext>` (any project-relative mod path too), tried against each extension in `texture_extensions` (Godot's importer runs on these normally).
2. If not imported, the same path read directly off disk as a raw `Image` (mainly relevant for textures that live outside `res://` if you wish to support modding).
3. Textures embedded in a loaded `WAD`, matched by name.
**Material lookup** (only if no Smart Tag override material matched):
1. A `.tres` (or other extension in `material_extensions`) under `<base_path>/<path_materials>/<name>.tres` — so you can hand-author a `StandardMaterial3D`/`ShaderMaterial` per texture name for full control (custom shaders, roughness, etc.) instead of relying on generation.
2. `QMapSettings.default_material`, duplicated, with the found texture assigned to `default_material_texture_path` (`albedo_texture` by default).
3. A bare `StandardMaterial3D` with nearest-neighbor + mipmap filtering, as a last-resort fallback.
**PBR textures** — if `use_pbr` is on, QMap Godot also looks for `<name><suffix_normal>`, `<suffix_metallic>`, `<suffix_roughness>`, `<suffix_emission>`, `<suffix_ao>`, and `<suffix_height>` (e.g. `brick01_normal.png`) next to the base texture and wires them into the matching `StandardMaterial3D` texture slots automatically. This only applies to generated/default materials, not hand-authored `.tres` materials, and is skipped for animated textures.
 
**Animated textures** — a texture whose name starts with any of `animated_texture_prefixes` (`+` by default, matching Quake's `+0anim`, `+1anim`, ... convention) is assembled into an `AnimatedTexture` from all numbered frames sharing that base name, played at `animated_texture_speed_scale`.
 
**Alphatest detection** — after materials are built, every texture's pixels are scanned; if any pixel has alpha `< 1`, the material's `default_material_transparency_path` is set to `transparency_alphatest_value` (alpha-scissor by default) automatically — no manual flagging needed for e.g. fences or foliage textures with a cutout alpha channel.
 
## Geometry Generation Per Entity
 
Each entity (worldspawn included) generates a combination of render mesh, collision, occlusion, and navigation geometry. **Smart Tags** allow you to toggle these generations per-texture, per-classname, or per-surface/content-flag, allowing you to define things like non-colliding entities, or non-navigatable brushes.
 
### Built-in Smart Tags
 
The default settings resource ships six Smart Tags that mirror common Quake/Source editor conventions:
 
| Tag | Matches | Behavior |
|---|---|---|
| `Clip` | texture `clip` | Not rendered, not occluding (invisible), but still collides. |
| `Skip` | texture `*skip` | Not rendered, not colliding, not pathfinding — fully inert compiler-only faces. |
| `Null` | texture `null` | Alternate to Clip for QMap purposes |
| `Hint` | texture `hint*` | Alternate to Skip for QMap purposes |
| `Trigger` | classname `trigger*` | Not rendered, not pathfinding, forces convex collision (so it works as an `Area3D`). Trigger volumes are invisible but functional. |
| `Liquid` | texture starting with `*` | Marked transparent (excluded from occlusion) to match Quake's `*water`/`*lava`/`*slime` convention. |
 
Add your own `QMapSmartTag` entries for engine-specific conventions (a `sky` texture that should render but not collide, a `nodraw` texture, etc.), or attach `override_material` to route a texture/classname to a specific material (e.g. a translucent shader for all `trigger_*` volumes, or a special water shader for anything matched by the `Liquid` tag).
 
## Groups, Layers, and Targets
 
- **Trenchbroom Groups/Layers** — entities with a `_tb_group` or `_tb_layer` property (set automatically when you group objects or use layers in TrenchBroom) are collected under a shared `Node3D` per group/layer when `group_nodes` is on, and added to a matching Godot group named after the TrenchBroom group/layer name (`_tb_name`). Objects marked `_tb_layer_omit_from_export` (hidden/excluded layers in TrenchBroom) are skipped entirely.
- **`targetname` / `target`** — the classic Quake linking system. An entity with a `target_source`-typed property (commonly `targetname`) becomes discoverable; an entity with a `target_destination`-typed property (commonly `target`) automatically has that property resolved to the actual target `Node` reference at spawn time via `find_target_destination()`, no manual `get_node()` wiring required, as long as both entities are FGD-defined with the right property types.
- **Origin brushes** — a brush entirely textured with `texture_origin` (`origin` by default) is not rendered or collided, but instead defines that entity's rotation pivot. This is used for rotating doors/platforms/etc. around a point other than their geometric center.
- **`_phong` / `_phong_angle`** — set on an entity (commonly via the bundled `Phong` FGD base class) to smooth normals across faces within `_phong_angle` degrees of each other, instead of using flat-shaded brush faces.

## Coordinates & Units
 
- Godot Y-up is reconciled with Quake/Source Z-up automatically, you don't need to rotate anything.
- `QMapSettings.scaling` (default `32`) is the number of Quake units per Godot unit. Raise it if your game feels oversized, lower it if brushes come in tiny.
- Entity `angle`/`mangle` and `scale` keys are read and applied to the spawned node's `rotation_degrees`/`scale` automatically; `-1`/`-2` for `angle` are treated as the Quake convention for straight up/down.

## Tips & Troubleshooting
 
- **"Missing MapSettings to generate with!"** — `settings` wasn't assigned on the `MapLoader`.
- **Entities aren't getting scenes** — confirm the classname matches exactly, the scene lives under `<base_path>/<path_scenes>/`, and the class is actually defined in your FGD (undefined classnames fall back to generic nodes).
- **Nothing renders for a texture** — check `Smart Tags` for a `NON_RENDERED` rule (e.g. for `clip`/`trigger`/`skip`), and confirm the texture file exists under `<base_path>/<path_textures>/` with an extension listed in `texture_extensions`.
- **A texture looks right but doesn't collide/occlude/pathfind as expected** — check `Smart Tag` settings.
- **Curved geometry (patches) is missing** — at this time Source Patches aren't supported, though this may change in the future.
- **A brush is rotating around the wrong point** — give that entity an origin brush textured with `texture_origin` (`origin` by default) to define its pivot.
- **Targets aren't linking up** — confirm both entities' properties are typed `target_source`/`target_destination` in the FGD (not plain `string`), since resolution only runs for those types.
- **Game freezes when loading map** — `pause_main_thread_while_loading = false` if you want the loading process to yield frames instead of freezing.
 

[Back](../readme.md)

