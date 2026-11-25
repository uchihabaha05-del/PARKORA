# PARKORA

A mobile 3D amusement park tycoon built with Godot 4.3 and GDScript.

## Gameplay direction
PARKORA takes inspiration from the accessible idle-tycoon loop of mobile amusement-park management games, while using original code, procedural placeholder art, and its own progression.

- Start with a small park and a coin budget.
- Build attractions and decorations on the land.
- Visitors enter through the gate and pay an entrance fee.
- Visitors walk to an attraction, spend time enjoying the ride, then leave.
- Earn ride income and reinvest coins into park expansion.
- Unlock the Ferris wheel after welcoming 8 visitors.
- Add paths, trees, and more attractions as the park grows.

## Current prototype
- Stylized procedural 3D park environment
- Free orbit camera with touch and mouse controls
- Buildable carousel, Ferris wheel, trees, and path tiles
- Animated carousel and Ferris wheel
- Visitor spawning, physical queue slots, sequential ride service, and exit behavior
- Attraction queue capacity and load-aware visitor assignment
- Connected path grid with breadth-first routefinding to rides and back to the gate
- Ride entrances must connect to the pedestrian path network
- Guest patience, queue abandonment, and a park rating that affects visitor demand
- Connected path grid with breadth-first routefinding for visitors
- Attractions require a nearby connected pedestrian path
- Coin economy with entrance and ride ticket income
- Recurring attraction maintenance costs, cash-flow tracking, and lifetime revenue/expense/net-profit HUD
- Automatic local save/restore of park funds, visitor totals, rating, finances, and player-built objects
- Basic attraction unlock progression
- Russian mobile HUD

## Open in Godot
1. Install Godot 4.3.
2. Clone or download this repository.
3. Import the folder containing `project.godot`.
4. Run the main scene.

## Controls
- Drag: orbit camera
- Mouse wheel / pinch: zoom
- Select a construction item, then tap/click the ground to place it

The project is an early playable foundation. Park progress is saved locally in `user://parkora_save.cfg` and restored when the game starts. Android export and APK packaging are intentionally deferred. The current visitor AI is a lightweight prototype and will be expanded with more advanced pathfinding and crowd flow, staff, services, and deeper park-management systems.
