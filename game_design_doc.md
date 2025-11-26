# Overview

The purpose of the project is to learn the game engine Godot as well as foundational concepts in game development. This game is an effort to build a 2D Flash Game “Erosion Battle” in the Godot game engine (v4.5+). Erosion Battle is an RTS game where players make choices and inputs but some of the gameplay happens automatically (the player does not directly control units). The aim of Erosion Battle is for the player to build an army and overwhelm enemy forces on a battle map. The player can buy various upgrades to help accomplish this goal.

# The Game Scene

## Map

The game map is a 2D area which will consist of various terrain types (grassland, forest, rivers, mountains, etc.). The map is tile-based with square tiles of 8x8 pixels. Some maps will be hand-crafted, whereas others should be procedurally generated.

## Camera

The camera is positioned in a top-down perspective above the map. The player has control of camera positioning by using the mouse or WASD keys. Camera rotation is not enabled to retain the 2D perspective. The camera is bound to the map and cannot exit the map area.

## Player Base

The player will have a “base” which will be spawned on the map in a random area (within a specific set of spawn-zone criteria).

## Enemy Base

The enemy (or enemies) will have a base (or or bases) which will be spawned on the map in a random area (within a specific set of spawn-zone criteria).

## Fog of War

The map is covered in Fog of War, which has 3 distinct types: Discovered and Visible, Discovered and Not Visible, and Undiscovered.

### Discovered and Visible

Areas of the map that have been visited by a player-controlled entity and are currently within the line-of-sight of player-controlled entities are considered Discovered and Visible, which allows the player to see other entities in this area in both the main camera as well as in the minimap.

### Discovered and Not Visible

Areas of the map that have been visited by a player-controlled entity but are not currently within the line-of-sight of a player-controlled entity are considered Discovered and Not Visible, which allows players to see the terrain structure of the area, resources, and enemy structures in both the main camera as well as the minimap, but does not allow the player to see other entities in that area, or changes that have occurred since the last visit to that area. For instance, if a player visits an area which contains a “gold” resource, then leaves and that gold resource is then mined by an enemy, the gold resource should still appear on the minimap and main camera until the player visits again and sees it has been taken. This is consistent with other RTS games like Age of Empires 2 and Warcraft 3.

### Undiscovered

Areas of the map that a player-controlled entity has never had line-of-sight on will be considered Undiscovered. The player will have no visibility of the terrain, resources, or enemy entities in these areas.

## UI

### Minimap

In the top-right of the screen is a mini-map that shows the full map. It takes into account the current Fog of War. The minimap shows a representation of the current main camera frame in relation to the full map.

### Player Actions

In the bottom-center of the screen is a selection of Player Actions. These are the core actions a player can take. The Actions below are described from left-to-right.

#### Build

The player can build structures on the map. These are categorized into multiple categories which will appear as a sub-menu after clicking on the Build Action.

#### Paths

The player can define paths that their units will attempt to follow as best as possible and zones that their units will perform certain actions within. This Action will have a sub-menu for a player to manage these.

#### Harvesting

The player can tag resources for harvesting which allows workers to retrieve value from resources. This Action will have a sub-menu for a player to tag and untag resources for harvesting as well as an option to open the Balance menu, where resource gathering priorities can be set.

# Game Elements

## Player Base

The player’s base is the core of their operations. If the player’s base is destroyed, they will immediately lose the game.

### Health

The Player Base has a health stat which tracks how much damage the base has sustained. Base health can be restored by a variety of actions the player may take.

### Unit Spawn

The Player Base will automatically spawn units over time.

### Defensive Arrows

The Player Base will automatically target and shoot arrows at enemy units within its line-of-sight.

### Upgrades

The player can select the Player Base with their mouse cursor. By doing so, an “purchases/upgrades” menu will appear. There are 9 upgrade options available:
Base Health - the health of the base.
Base Attack Damage - the attack damage of arrow shooters in the base
Base Attack Speed - the speed of attack of arrow shooters in the base
Base Attack Range - the range/line-of-sight of the arrow shooters in the base
Unit Spawn Rate - the frequency at which units automatically spawn
Unit Health - the health of spawned units
Unit Speed - the speed of spawned units
Unit Attack - the attack of spawned units
Unit Attack Speed - the speed of attack of spawned units
Upgrades increase in cost exponentially. Unit upgrades only affect the units that spawn after the upgrade was purchased. Upgrades are purchased using resources.

### Purchases

The player can select the Player Base with their mouse cursor. By doing so, an “purchases/upgrades” menu will appear. There is only one purchase option available, “Worker”. Worker pricing stays the same. There is no limit to the number of workers that can be purchased. Purchasing workers is done with resources.

## Enemy base

The enemy base is similar to the player base with the exception that when the enemy base is destroyed, if it is the final player base, the player wins the game.

## Workers

Workers are a non-combat type entity that both the player and any enemies may purchase for their base. Workers automatically harvest nearby resources that have been tagged for harvesting.

### Health

Workers have a health state which determines how much damage they can sustain before being killed. Once killed, the resources a worker had stored in their inventory drops to the ground and is available for another worker to pick up.

### Capacity

Workers have a set capacity for resources in their inventory.

### Harvesting

Workers will automatically harvest resources as close to the base as possible and will gradually move further away when those resource nodes have been depleted. During the process of harvesting, if a worker’s capacity is reached, they will automatically return to the closest drop-off point. Workers must also take into account the Resource Balance that the player has defined.

### Building

Some buildings require workers to take resources for their construction. Workers will prioritize these buildings over resource harvesting. When a player initiates the build process for one of these structures, the closest worker with the required resources will take those resources to the structure to initiate the build process.

### Enemy Interactions

If a worker sees or is targeted by enemies, they will attempt to run away. If the enemy pursues, they will attempt to reach the nearest Garrison and automatically hide inside.

### Pathing

If a worker has no path to a given objective (whether building, harvesting, or drop-off) the worker will stop in place and play a special animation that indicates to the player that they are stuck.

## Resources

Resources are a neutral entity type that is spawned on the map during generation. Players harvest resources from these nodes on the map. Players begin the game with a small stockpile of existing resources.

### Types

There are 4 main types of resource: food, wood, stone, and iron.

#### Food

Food is a core resource used for purchasing workers, upgrades, and buildings. Food can be harvested from multiple sources, including gathering sources (like berry bushes), hunting sources (like animal packs), and fishing sources (like rivers and oceans).

#### Wood

Wood is a core resource used for purchasing workers, upgrades, and buildings. Wood can be harvested from 2 sources: trees and brush.

#### Stone

Stone is a core resource used for purchasing upgrades and buildings. Stone can be harvested from 2 sources: loose rocks and mines.

#### Iron

Iron is a core resource used for purchasing upgrades and buildings. Iron can only be harvested from iron mines.

## Units

Units are automatically spawned and will try their best to pathfind towards the enemy base. If they encounter an enemy unit or structure along the way (with the exception of bridges), they will attempt to kill/destroy that unit/structure. Think of units like Dota 2 lane creeps. Units will follow the best path that they can determine by their line-of-sight as well as knowledge about Discovered locations. If the player has placed Paths, units will try and follow those paths first if it is on their way.

## Paths

Paths are player-defined routes that units will prefer to take over their own pathfinding. These are overlaid on the map by the player as a series of nodes (like in graph theory). If an obstacle blocks a path, units try to find their way around it before returning to the path. It’s essentially an influence value that magnetizes units towards it while they are on their greater journey towards the enemy base.

## Buildings

There are a variety of buildings that the player or enemies can construct. Buildings take time to construct. These fall into various categories.

### Unit Producing Buildings

These buildings, like the player base, can spawn units of various types. They have their own upgrade options.

#### Spearman Barracks

Produces spearmen on a set interval. Upgrade options include: Spawn rate, Attack Damage, Attack Speed, Health.

#### Archer Barracks

Produces archers on a set internal.Upgrade options include: Spawn rate, Attack Damage, Attack Speed, Attack Range, Health.

#### Shieldbearer Barracks

Produces shieldbearers on a set interval. Upgrade options include: Spawn rate, Attack Damage, Attack Speed, Armor, Health.

### Resource Buildings

There are several resource buildings that players can construct to increase resource gathering efficiency.

#### Stockpile

This is considered an additional drop-off point for workers to return harvested resources to.

#### Fishing Pier

This is a resource generation node that players can create on river or ocean tiles.

#### Mine

This is a resource extraction node that players can create on stone or iron veins to extract that particular resource.

### Tactical Structures

There are a variety of tactical structures which players can build across the map.

#### Guard Tower

Guard towers can be placed anywhere to provide the player with line-of-sight over a static region.

#### Bridge

Bridges can be placed on river and ocean tiles in order to reduce the time it takes for units to cross these terrain types.

#### Wall

Walls can be placed on otherwise unoccupied terrain tiles. Walls block unit and worker movement. Units will try to path around walls, but if no path is available, units will attempt to destroy enemy-controlled walls if their objective is on the other side.

#### Roads

Roads can be placed on otherwise unoccupied terrain tiles. Roads replace the existing terrain type below and replace it with one that buffs unit movement speed.

## Terrain

The map is built of various terrain types which have different effects on units passing over them.

### Grassland

Grassland is the default terrain type. It imposes no movement changes on units passing over it. Over time, grassland degrades from unit movement, creating Dirt Path terrain type.

### Dirt Path

Dirt Path may exist already on a map at the time of creation/generation, but it will also be created over time based on the repeated movement of units over that tile. The Dirt Path will increase unit/worker movement speed by a certain amount.

### Sparse Forest

Sparse Forest is a terrain type that restricts movement of units/workers passing through. If a worker harvests a sparse forest tile, it becomes grassland.

### Dense Forest

Dense Forest is a terrain type which is considered impassable. If a worker harvests a dense forest tile, it becomes sparse forest.

### Mountain

Mountain is a terrain type which is considered impassable. If a worker harvests a mountain tile, it becomes a dirt path.

### River

River is a terrain type which greatly restricts movement of units/workers passing through.

### Sand

Sand is a terrain type which slightly restricts movement of units/workers passing through.

### Ocean

Ocean is a terrain type which is considered impassable.

## Nodes

Nodes are neutral entities that can be interacted with by a player/enemy.

### Iron Vein

An iron vein can have a mine built on it which allows for workers to harvest iron resource from it.

### Brush

A brush node can be harvested by workers for wood.

### Berry Bush

A berry bush node can be harvested by workers for food.

### Animal

An animal node can be harvested by workers for food.

# The Game Flow

### The Win Condition

The win condition for a game is that the player defeats all of their enemies' bases. A game may be 1-on-1, but it could also be 1-on-1-on-1 and so on. There is a maximum limit of 8 players/enemies on a map. A player loses the game if their own base is destroyed.

### The Map

A game consists of a map which is altered over the course of the game by player actions. Some maps will be hand-crafted, some will be player-created (workshop also), and some will be procedurally generated. The map will have a variety of terrain types.

### Placement of Bases

The initial phase of a game is the placement of the player bases. This happens automatically prior to any player input. Some maps have predetermined base spawn points, but maps which have not set those spawn points should randomly select spawn points based on a set of conditions, such as availability of nearby food, wood, and stone resources as well as being a large distance from enemy locations. Think Age of Empires 2. The placement of the base also spawns in 3 free workers, which are available to the player upon game start. The location of the enemy base is immediately known to the player, and the enemy will immediately know about the player’s base.

### Automatic Attacking

The player’s base (and unit producing structures) will automatically spawn units that will pathfind towards the enemy base utilizing the default pathfinding, but also relying on/being influenced by player-defined paths.

# Gameplay & Mechanics

## Combat Mechanics

### Attack Priority

Units will attack any enemy within their line-of-sight. Melee units attack the closest enemy or structure to them, in the case of multiple closest enemies, the unit will attack the one with lowest health. For ranged units, they attack the weakest enemy within range. Units will always prioritize killing enemy units instead of enemy structures.

### Attacking

Units attack on a set cooldown determined by their attack speed statistic. Units do a flat base damage based on their attack damage statistic.

### Ranged Unit Kiting

Ranged units will run away from and fire at enemies that get within a certain distance threshold.

## Economy

The economy can be measured in Worker-Time-to-Gather (WTG) measured in minutes.

### Gathering

The balance should make Food the most available resource, with wood and stone almost equally available, and iron being the rarest. This links to the general progression of the game, in which Food/Wood are early-game requirements, stone is a mid-game requirement and iron is late-game.

### Spending

## Economy Tables

### Gathering Table

| Node Type            | Resource Gathered   |   Amount per 1 WTG | Availability in Map   |
|:---------------------|:--------------------|-------------------:|:----------------------|
| Brush                | Wood                |                 20 | High                  |
| Sparse Wood          | Wood                |                 30 | High                  |
| Dense Wood           | Wood                |                 35 | High                  |
| Berry Bush           | Food                |                 20 | High                  |
| Fishing Pier (River) | Food                |                 35 | Medium                |
| Fishing Pier (Ocean) | Food                |                 40 | Medium                |
| Animal               | Food                |                 60 | Low                   |
| Loose Stone          | Stone               |                 30 | High                  |
| Stone Vein           | Stone               |                 60 | Medium                |
| Iron Vein            | Iron                |                 45 | Low                   |

### Building Cost Table

| Building Name         |   Food Cost |   WTG Food Cost |   Wood Cost |   WTG Wood Cost |   Stone Cost |   WTG Stone Cost |   Iron Cost |   WTG Iron Cost |   Total WTG Cost |
|:----------------------|------------:|----------------:|------------:|----------------:|-------------:|-----------------:|------------:|----------------:|-----------------:|
| Spearman Barracks     |         200 |               5 |         120 |               4 |            0 |                0 |           0 |               0 |                9 |
| Archer Barracks       |         400 |              10 |         360 |              13 |          100 |                2 |           0 |               0 |               25 |
| Shieldbearer Barracks |        1000 |              26 |        1000 |              35 |          400 |                9 |         200 |               4 |               74 |
| Stockpile             |         100 |               3 |          80 |               3 |            0 |                0 |           0 |               0 |                5 |
| Fishing Pier          |         100 |               3 |         240 |               8 |           60 |                1 |           0 |               0 |               12 |
| Mine                  |         500 |              13 |         800 |              28 |          400 |                9 |           0 |               0 |               50 |
| Guard Tower           |         140 |               4 |         140 |               5 |           40 |                1 |           0 |               0 |                9 |
| Bridge                |          40 |               1 |         100 |               4 |           40 |                1 |           0 |               0 |                5 |
| Wall                  |          40 |               1 |         180 |               6 |           80 |                2 |           0 |               0 |                9 |
| Roads                 |          40 |               1 |          80 |               3 |          120 |                3 |           0 |               0 |                7 |

### Upgrade Scaling Table

|   Level |   Cost |   WTG Cost |
|--------:|-------:|-----------:|
|       1 |     80 |          2 |
|       2 |     88 |          2 |
|       3 |     97 |          2 |
|       4 |    106 |          3 |
|       5 |    117 |          3 |
|       6 |    129 |          3 |
|       7 |    142 |          4 |
|       8 |    156 |          4 |
|       9 |    171 |          4 |
|      10 |    189 |          5 |
|      11 |    207 |          5 |
|      12 |    228 |          6 |
|      13 |    251 |          6 |
|      14 |    276 |          7 |
|      15 |    304 |          8 |
|      16 |    334 |          9 |
|      17 |    368 |          9 |
|      18 |    404 |         10 |
|      19 |    445 |         11 |
|      20 |    489 |         12 |
|      21 |    538 |         14 |
|      22 |    592 |         15 |
|      23 |    651 |         17 |
|      24 |    716 |         18 |
|      25 |    788 |         20 |

For buildings, the economy focuses mostly on Food, Wood, and Stone with the exception of the Shieldbearer Barracks which also relies on Iron. Iron is mostly used in upgrading units to higher tiers.

Upgrade scaling happens at a progression rate of 110% for each upgrade of the same type within a specific building.

## AI Design

AI will have 5 difficulty settings: Very Easy, Easy, Moderate, Hard, Very Hard. The difficulty selection will determine what the AI is capable of doing.

#### Use of Paths

Very Easy: AI only uses basic pathfinding, no custom path nodes will be used.
Easy: AI only uses basic pathfinding, no custom path nodes will be used.
Moderate: AI can utilize custom paths and prioritizes the discovery of resources.
Hard: AI can utilize custom paths and prioritizes destroying player workers.
Very Hard: AI can utilize custom paths and prioritizes destroying player workers.

#### Worker Prioritization

Very Easy: AI cannot re-prioritize workers from the default setup.
Easy: AI can re-prioritize workers up to a set limit.
Moderate: AI can re-prioritize workers fully.
Hard: AI can re-prioritize workers fully.
Very Hard: AI can re-prioritize workers fully.

#### Buildings

Very Easy: AI has a low maximum limit on all building types.
Easy: AI has a low maximum limit on unit-production buildings.
Moderate: AI has a medium maximum limit on unit-production buildings.
Hard: AI has a high maximum limit on unit-production buildings.
Very Hard: AI has no maximum limit on any building type.

#### Evil Behavior

Very Easy: AI has no evil behavior.
Easy: AI has no evil behavior.
Moderate: AI has no evil behavior.
Hard: AI will target areas of the map with iron deposits and build outposts there (unit production buildings).
Very Hard: AI will target areas of the map with iron deposits and build outposts there (unit production buildings). AI will build unit production buildings close to the player’s base.

## Progression

### Difficulty Scaling

Difficulty scaling should be consistent within a match and should be determined by the selected enemy AI levels. In a single match, different AI difficulty settings may be present. For example, in a 1-on-1-on-1 game, an enemy AI may be set to Easy and another set to Hard.

### Campaign

The game features a campaign with 20 levels. These will span the various AI difficulty ratings. All 20 levels of the campaign will have hand-crafted maps. Although each map may have varied AI difficulties in multi-enemy mode, they should generally follow this pattern: 3 Very Easy maps, 4 Easy maps, 8 Moderate maps, 3 Hard maps, 2 very hard maps. The campaign will start with 1-on-1 levels, but some multi-enemy levels will be introduced over the course of the campaign.

### Skirmish

The game features a skirmish mode where the player can select the number of opponents, the map, and resource availability.

# Player Experience

## Tutorial/Onboarding

Prior to the campaign, there will be an optional tutorial. This tutorial will take place across 3 games, each against 1 Very Easy AI. This guided experience will introduce the core concepts to the player. Tutorials will include tours which will force players to perform specific actions/tasks to advance through the games.

### Tutorial Game 1

The player is introduced to the player base, the game goal (destroying enemy base), workers, resources (food - berry bush & animals, wood, stone), automatic unit spawning, building resource buildings, and building unit-production buildings. The tutorial will end when the player destroys the enemy base.

### Tutorial Game 2

The player is introduced to fishing piers, mines, walls, bridges, guard towers, and upgrades. This will introduce more advanced building concepts where workers are required to take resources to buildings. The player will be guided to upgrade units to overcome the enemy forces (the enemy will not be able to upgrade units but will match the player buildings 1-to-1)

### Tutorial Game 3

The player is introduced to iron, shieldbearers, and Paths.The player will be required to destroy the enemy base by taking a less direct path.

## Single Player

Single player is described by the campaign and skirmishes above.

## Multiplayer (Stretch Goal)

The game is designed to support multiplayer. Where players can have battles amongst one another.

### Architecture

The multiplayer aspects of the game should be Client-to-Server architected to reduce possibilities of cheating.

### Ranked Matchmaking

Ranked matchmaking should pair together players of semi-equal skill as calculated through an ELO system.

### Private Lobby

Players can create private lobbies that allow them to invite friends to join a match with the same customization options as Skirmish mode.

## Victory & Defeat Flow

(Stretch) In the campaign, regardless of victory or defeat, the player sees statistics about the game, such as total units produced, units killed, resources collected, buildings created, buildings destroyed.

# Technical & Development

## Core System Architecture

### Autoload singletons (global services)

Game: authority over simulation clock, pause, match state, save/load, and scene transitions.
MapService: tile data, nav grids/flow fields, resource graph, chunk streaming.
FogService: visibility grid, discovery state, FOW textures.
CombatService: damage, projectiles, hit detection, death/cleanup.
EconomyService: resources, costs, upgrade scaling, income ticks (backed by your WTG tables).
AIService: blackboards, behavior trees/utility scorers, job assignments for workers.
NetService (stretch): session, snapshot/commands, reconciliation.

### Data-driven config

Define *.tres/*.res Resource assets for units, buildings, upgrades, terrain types, costs (mirror your tables so balance lives in data, not code—e.g., the WTG spending chart on p.11 becomes BuildingCost.tres).
Example Resources: UnitDef, BuildingDef, TerrainDef, UpgradeDef, AIDifficultyDef.

### Scenes (prefabs)

Unit.tscn (state machine + steering), Worker.tscn, Projectile.tscn, Base.tscn, Barracks_*.tscn, Tower.tscn, Wall.tscn, Bridge.tscn, ResourceNode.tscn.
Each scene exposes signals (died, took_damage, gathered, construction_started/finished) to decouple services.

## Simulation/Update Loop

Deterministic tick: run core sim at fixed Δ (e.g., 10–20 Hz) in _physics_process(). Interpolate visuals at render rate; all AI/economy/combat ticks live on the sim clock. This makes replays, save/load and multiplayer sane.
Authoritative systems (order each frame):
Input/Commands → 2) AI/Jobs → 3) Economy (harvest, spend, build progress) →
Spawning/Despawn → 5) Movement/Path following → 6) Combat resolution → 7) Fog update.

## Navigation & movement

Hybrid pathfinding for RTS scale:
Macro: grid flow fields per target (enemy base, rally points) for hundreds of units.
Micro: local A* for short detours (walls, chokepoints) + simple collision avoidance (RVO-lite or steering).
Maintain separate nav layers for units vs workers; bridges toggle water passability.
Player Paths feature: store user-drawn graph nodes; inject as lower-cost edges into the macro grid so units are “magnetized” but not forced.

## Procedural Map Generation

Phase 1 – Height & biomes: layered noise → thresholds for ocean/river/sand/grass, then cellular relax to remove 1-tile noise.
Phase 2 – Rivers: downhill tracer from peaks to ocean; ensure bridgeable widths.
Phase 3 – Forests & mountains: Poisson-disc scatter with density maps (dense vs sparse).
Phase 4 – Resources: rule-based placement using your rarity (Food high, Iron low) and spawn fairness around bases.
Phase 5 – Bases: pick spawn sites maximizing distance & resource quality (ties into your “Placement of Bases” section).
Expose all knobs in a MapGenProfile Resource for reproducible seeds.

## Fog of war (three states)

Keep a visibility grid (byte per tile: 0=undiscovered, 1=discovered, 2=visible).
Each frame, stamp unit/base/tower vision discs into a visible_mask (GPU or CPU), then decay to discovered_mask.
Rendering: shader mixes darken + desaturation for “discovered/not visible” and full black for “undiscovered.” Minimap samples the same masks. (Matches your three-state definition.)

## AI Architecture

Two-tier approach:
Strategic AI (per difficulty): utility scores for “expand,” “pressure workers,” “tech/upgrade,” “secure iron outpost” (matches your “evil” behaviors). Decisions emit high-level commands (build X, set harvest weights, place paths).
Tactical AI: lightweight behavior trees for groups (attack nearest, focus squishies, retreat ranged).
Job system for workers: priority queue (build > deliver > harvest); EconomyService assigns jobs respecting the user’s Balance settings.

## Combat System

Server-side (or authoritative) resolution with event queues:
Hits as discrete events at end of tick; ranged projectiles can be hitscan at tick time with interpolated VFX.
Target selection mirrors your rules (melee closest/lowest HP; ranged weakest in range).

## Save/Load/Replay System

Deterministic saves: store snapshot of services (seed, tick, RNG state) + compact arrays for unit states, buildings, resources, FOW masks.
Replays: save initial seed + command stream; sim replays deterministically.

## Multiplayer netcode (stretch)

Lockstep (lower bandwidth, requires strict determinism + rollback handling).

## Performance considerations (2D, lots of units)

Chunked TileMap updates; only redraw FOW/tiles in dirty chunks.
Object pooling for projectiles, workers’ carry VFX, and deaths.
Broadphase: spatial hash or Quadtree for sight queries & target acquisition.
Physics: minimal collision layers; units as kinematic (no expensive rigid collisions).
LOD: swap high-cost per-unit logic for group AI when zoomed out/army size large (batched decisions).
Profiling: wire in togglable debug overlays (AI heatmap, flow fields, FOW cost) and Godot’s Profiler markers.

## Project structure

/autoload   (Game.gd, MapService.gd, FogService.gd, EconomyService.gd, CombatService.gd, AIService.gd, NetService.gd)
/scenes     (units/, buildings/, resources/, vfx/, ui/)
/data      (UnitDef.tres, BuildingDef.tres, UpgradeDef.tres, TerrainDef.tres, AIDifficultyDef.tres, MapGenProfile.tres)
/systems    (pathfinding/, flowfield/, bt/, utility/, save/, replay/)

### Tooling & tests

Balance tools: in-editor panel that reads your WTG tables and computes effective time-to-tech curves.
Scenario harness: headless test scenes (100/300/600 units) to benchmark tick time.
Automated tests: GUT or --headless scripts to validate determinism (same tick → same hashes).

# Art, Audio, & UI

## Art Style Guide

The game is pixel art style with very rudimentary entities. Think Darwinia but 2D. In later versions graphics will aim to be upscaled. The size of a unit should be no larger than 10x10px. Buildings should be real-world scale as compared to the units. Therefore a barracks should be about 30 times larger than the unit. Units will be rendered quite small on the map as will workers.
During development and early Alphas, terrain types will be incredibly simple and represented by single-color tiles. Sprites will not be animated initially, but later might be.

## Sound Design

There will be no sound initially for the alpha. Eventually, very basic foley.

# Prototyping

## 0.1.0

This prototype should simply be a map (no terrain types) with a player base and enemy base. There should be no workers, upgrades, resource nodes, buildings, or anything else. Simply the auto-spawning and auto-path/attacking mechanics. The prototype should also implement a good RTS-style camera.

## 0.2.0

This prototype should focus on a better map. The map should be based on an invisible grid. The grid will need a terrain type system matching the logical rules above. The logic behind the map should support hand-crafted maps and procedural map generation (but in this prototype only hand-crafted maps are necessary). The various terrain types should block or hinder movement as per the rules above.

## 0.3.0

This prototype should focus on a limited UI. The user should be able to click on their base or the enemy base to see two statistics: a current health value out of total health and the owner of the base "Your Base" or "Enemy Base". Tiles should also be clickable and display details about the tile (type and whether it's passable/impassable as well as the buff/detriment to movement speed). All infomration from clicking tiles/bases should be displayed in a small UI box in the bottom right of the screen. Additionally, Each player's units should have a different color overlay, this should be a random color for each distinct player or enemy, the base should also have this color.

## 0.4.0

This prototype should focus on workers and economy. For now, each player should start with 2 workers, they should inherit the team color. Those workers should automatically harvest nearby resources (wood and stone from tiles) and return them to the base. The tiles should automatically update to the next type as necessary. The player should also be able to see their current resource stockpile in the top of the screen.

## 0.4.1

This prototype should expand on workers. The player should be able to mark tiles for harvesting clicking on them and pressing a UI button called "Harvest". Workers should prioritize harvesting these tiles over unmarked tiles. The player should also be able to unmark tiles for harvesting by clicking on them and pressing the "Unharvest" button.

## 0.4.2

This prototype should add better harvesting options. Workers should now be able to clip through their own player's units (but not the base). Additionally, the harvest/unharvest buttons should be replaced with a sprite. I have created the two sprites and just need a place to put them. Also, tiles that are marked should use that sprite as an overlay on the tile itself.

## 0.4.3

This prototype should add enemy worker intention. Enemy worker intention should be separate from the tiles marked by the player. Enemy workers should automatically harvest the closest resources to their base. They should not take into account any player markings. In the future, workers will need to adhere to "markings" made by the enemy AI, but for now, they should just harvest the closest resources to their base.

## 0.4.4

Tiles should have their own "health" value based on their type. For example, a dense forest tile should take much longer to deplete than a sparse forest tile due to a higher health value. You can think of this like a worker "attacking" a tile and receiving a portion of the tile's value from that action. Workers should also have a backpack capacity. Once a worker's backpack is full, they should automatically return to the base to drop off resources. Workers should only harvest until their backpack is full. They will gain a certain amount of resources per amount of tile health they have depleted.

## 0.4.5

This prototype should add multi-select for tiles. If the player clicks and drags their mouse, they should be able to select multiple tiles at once. Once multiple tiles are selected, the player should be able to press the "Harvest" button to mark all selected tiles for harvesting. Similarly, the player should be able to press the "Unharvest" button to unmark all selected tiles for harvesting.

## 0.5.0

This prototype should work on the logic behind how buildings are placed. Right now, buildings are placed directly into the Main scene and positioned with no regard for the tiles they are built on. Instead, the main scene should have an exported integer for the number of players (default 2). Then during the map generation, the process should place the bases on the map. The first base will always be the player's base. Any undesirable terrain, such as mountain, ocean, or river that intersect with the base position should be removed. IIn order to achieve the goal of this prototype, all buildings are scaled to match the tile sizes, and will have an exported variable pair (tile_width) and (tile_height). The bases should be positioned far away from one another. Additionally bases should have a 2 tile buffer from the sides of the map.

## 0.6.0

This prototype should work on pathing improvements for units. Right now unit/worker pathing is incredibly basic (moving linearly to target). Units and workers should have two separate pathing algorithms. This protoype focuses on paths for Units. They should move from tile-center to tile-center. to reach their destination. This should be achieved with a series of waypoints generated by an A* pathfinding algorithm. This pathfinding is not unit-specific, instead one path should be defined for all units a player or enemy controls. This pathfinding should be updated whenever the terrainmap tiles are changed (for instance a mountain becoming a dirt path). The algorithm should take into account the impassable terrain types as well as speed modifiers on tiles. Bases are considered impassable tiles. In the future, the player will be able to define their own waypoints, which units will attempt to incorporate into their paths. Add in a draw_path debug option that shows the calculated path for players' units.

Ideally the flow is something like this:

1. Map tiles are drawn
2. Bases are placed on the map
3. An initial path is calculated and saved for each player/enemy. The path goes from the SpawnPoint of their own base to the closest tile of the opponent base.
4. Units spawn and follow that path to the enemy base.
5. Any tile map change, such as a worker breaking through a rock or tree, triggers a recalculation of the path for all players/enemies.

## 0.6.1

Unit movement should improved in "local" scenarios. A local scenario is one where they have an enemy attack target within their line-of-sight. Local pathfinding overrides their waypoint pathfinding. Once the enemy is defeated, the unit should recalculate their path from their current position to the enemy base and continue on their way via waypoint pathfinding. In local pathfinding, the Unit should utilize a local A* pathfinding algorithm to navigate around obstacles that may be blocking their path to the enemy within their line-of-sight. The obstacles blocking the path could be tiles or even other units. Local pathfinding does not need to adhere to tiles in any way, it should simply find the best path around obstacles to reach the target. Once the target is reached or destroyed, the unit should revert to their waypoint pathfinding.

## 0.7.0

This prototype should add the upgrades system. The player should be able to click on their base to open an upgrade menu. The upgrade menu should show all 9 upgrade options with their current level and cost. The player should be able to purchase upgrades if they have enough resources. Upgrades should immediately apply to newly spawned units and the base itself. The enemy AI should also be able to purchase upgrades based on a simple timer (every 30 seconds, purchase a random upgrade if enough resources are available).

## 0.8.0

This prototype should add in building construction. This will require a new UI element on the left side of the screen of the various building types can can be constructed. In this prototype, only the stockpile building and spearman barracks should be accessible to build. The stockpile behaves like the base in that workers can drop off resources here instead of the base if the stockpile is closer. The spearman barracks should spawn spearmen on a set interval. The player should be able to click on the barracks to see its upgrade menu, which should match the upgrade menu of the base but only show spearman-specific upgrades. (The base units we have defined so far are considered spearmen). Right now only the player can place buildings. The enemy AI will not place buildings in this prototype. Buildings should have collision so that units and workers cannot pass through them. Buildings should be placed aligned to the tile grid, meaning their position should be snapped to the nearest tile center. Buildings should not be placeable on impassable terrain types. Buildings of different types have different sizes, so the placement logic should take that into account. Buildings cannot overlap one another. When placing a building, a transparent preview of the building should follow the mouse cursor. If the building can be placed at the current position, the preview should be green, otherwise red. The player can left-click to place the building if it is in a valid position. The player can right-click to cancel building placement. A basic scene with no script attached has been created for both the stockpile and spearman barracks. A stockpile is 1x1 tile in size, while a spearman barracks is 2x2 tiles in size.

## 0.9.0

This prototype should work on Map procedural generation. The game should generate a map based on a seed value applied to 3 layers of noise. The first noise layer should deal with altitude, where dark colors are low altitude and light colors are high altitude. The second layer should deal with moisture, where dark colors are dry and light colors are wet. The third layer should deal with temperature, where dark colors are cold and light colors are hot. Based on these 3 layers, the map should be generated with appropriate terrain types (for example, high altitude + low moisture + low temperature = mountain).
