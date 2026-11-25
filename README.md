# PARKORA

A mobile 3D amusement park management tycoon built with Godot 4.3 and GDScript.

## Gameplay direction
PARKORA uses **ThemeParkManager by Supercent** as its primary gameplay reference: build and expand a park, manage visitor needs and queues, tune prices, upgrade attractions, hire staff, maintain facilities, and grow long-term profit. PARKORA uses its own code, visuals, interface, names, and progression. See [GAME_DESIGN.md](GAME_DESIGN.md) for the gameplay specification.

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
- Categorized lifetime income from admission, rides, and services
- Categorized recurring expenses for staff wages, facility upkeep, and ride maintenance
- Rolling one-minute income, expense, and net-profit report plus lifetime financial totals
- Persistent local save of the categorized financial ledger
- Offline park settlement on return, capped at 8 hours and calculated from demand, attraction condition, cleanliness, services, wages, and upkeep
- Closed attractions earn no offline revenue; recurring costs still apply and cash is protected from negative balances
- Six sequential park objectives with one-time coin rewards and saved progression
- Three purchasable land expansions (north, west, east) with visible boundaries, construction limits, and saved ownership
- Food and drink kiosks selected by individual visitors according to hunger/thirst, affordability, reachable path, and walking distance
- Buildable toilet and rest facilities with distinct visitor needs, service prices, routefinding, usage time, income, and recurring upkeep
- Visitors track hygiene and rest needs and choose an affordable reachable facility when the need is high
- Visitors physically walk to a selected kiosk, purchase once, satisfy the corresponding need, and then leave
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

The project is an early playable foundation. Park progress is saved locally in `user://parkora_save.cfg` and restored when the game starts. Android export and APK packaging are intentionally deferred. The current visitor AI and economy are scaffolding. The next development stages will focus on testing and balancing the management simulation, expanding visitor behavior, and improving the mobile interface.
