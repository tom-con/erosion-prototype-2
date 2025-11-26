# Repository Guidelines

## Project Structure & Module Organization

- Source: `autoload/` (global singletons like `Game.gd`, `CombatService.gd`), `scenes/` (gameplay scenes and scripts), `systems/` (future systems), `data/` (assets/config), `.godot/` (editor metadata), `project.godot` (project settings).
- Scenes are grouped by domain, e.g. `scenes/units/Unit.tscn`, `scenes/buildings/Base.tscn`, `scenes/ui/RTSCamera2D.tscn`.
- Prefer one script per scene; expose tunables via `@export` and use `class_name` for shared types.

## Build, Test, and Development Commands

- Run game (editor): open in Godot 4.x and press Play on `scenes/Main.tscn`.
- Run game (CLI): `godot --path .` (or `godot --path .`) to launch the default scene.
- Headless quick-check: `godot --headless --path . --quit` to validate the project loads.
- Export (example): `godot --path . --export-release "macOS" build/game.app` (configure export presets first).

## Coding Style & Naming Conventions

- Indentation: tabs only (no spaces). UTF‑8 encoding (`.editorconfig`).
- GDScript 4 style: snake_case for variables/functions (`attack_cooldown`), PascalCase for `class_name` and scene/script filenames (`Unit.gd`, `Base.tscn`).
- Signals: past-tense or event-style (`unit_died`, `unit_hit`).
- Folders: lower_snake (`scenes/buildings`), assets lower_snake (`pikeman.png`).
- Autoloads live in `autoload/`; register via Project Settings → Autoload.

### GDScript Notes

- Godot 4.5: do not use C-style ternary `cond ? a : b`. Use the expression form `a if cond else b`.
- Prefer explicit `if` blocks for clarity when expressions become long.
- Never use the C-style ternary `cond ? a : b`; rewrite with `a if cond else b` or a clear `if/else` block.

## Testing Guidelines

- No automated tests are configured. Use manual playtesting: run `scenes/Main.tscn`, watch the Output for errors, and verify unit/base interactions (damage, death, targeting, camera behavior).
- Prefer small, reproducible scenes when debugging (duplicate `Main.tscn` and isolate a feature).
- Optional: integrate GUT if adding automated tests.

## Commit & Pull Request Guidelines

- Commits: imperative mood, concise subject, optional scope. Examples: `Add enemy unit scene`, `Fix Base spawn timer`, `Refactor CombatService signals`.
- Pull Requests: include purpose, key changes, and before/after notes; link issues; add short clips/screenshots (e.g., camera behavior or combat) when UI/feel changes.
- CI is not configured; ensure the project opens cleanly and runs from CLI before requesting review.

## Security & Configuration Tips

- Do not commit local exports or editor caches outside `.godot/` defaults.
- Keep gameplay constants as `@export` fields for designer tuning; avoid magic numbers.
- When adding new domains, follow the existing layout (`scenes/<domain>/`, script alongside `.tscn`).

## Variant Types

- We are using Godot 4.5, so be very mindful of the inferred type system changes. Often you will want to produce code that infers types, but it is much better to type directly instead of using inference. A;ways prefer explicit types for function return types and variable declarations.

## Considerations for multiplayer

- Always build features under the consideration that the game will eventually be multiplayer. This means avoiding single player only constructs like singletons and global state where possible. When you do need to use singletons or global state, make sure that the code is structured in a way that it can be refactored to support multiplayer in the future.

## Considerations for Godot development

- Always prefer Godot patterns of development. In some cases you may be able to solve a problem with Code, but there may be a Godot specific way of solving the same problem that is more efficient and better integrated with the engine. Always prefer Godot patterns of development unless there is a very good reason not to. For instance, you can code Input mapping/handling, but instead you should report back to your conversation partner that you should be using Godot's InputMap and InputEvent system instead and provide a list of specific actions for the conversation partner to implement.
