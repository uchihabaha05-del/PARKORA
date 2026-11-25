# PARKORA — Game Design Direction

## Reference

The primary gameplay reference is **ThemeParkManager by Supercent** (mobile amusement-park tycoon). PARKORA should follow its management logic and player motivation, not merely the broad theme of an amusement park.

This is a design reference only. PARKORA must use original code, original UI, original 3D assets, names, progression tuning, and presentation.

## Core player fantasy

The player starts with a small, underdeveloped amusement park and personally turns it into a profitable, popular destination. Every new facility should solve a visitor problem, increase capacity or satisfaction, and create a reason to expand.

## Core gameplay loop

1. Earn starting capital and inspect what limits park growth.
2. Unlock and purchase land or new park zones.
3. Place paths, attractions, food and drink facilities, rest areas, toilets, and decorations.
4. Visitors enter, choose activities, navigate the park, queue, ride, eat, drink, rest, and leave.
5. Earn money from admission, attractions, and services.
6. Spend money on upgrades, staff, maintenance, and expansion.
7. Improve satisfaction and throughput to attract more visitors and unlock more content.
8. Keep the park operating and earn appropriately balanced offline progress between sessions.

## Systems that define the target

### 1. Construction and land expansion
- Grid-based placement with clear occupied tiles and path connections.
- New land sections unlock progressively and have meaningful prices.
- Facilities need pedestrian access; paths must connect to the entrance.
- Layout matters: visitors should not need to cross the entire park for basic needs.

### 2. Attractions
- Multiple attraction categories with distinct prices, capacity, ride duration, appeal, and operating costs.
- Each attraction can be upgraded in stages. Upgrades should improve capacity, speed/throughput, appeal, or satisfaction.
- Attraction condition declines with operation and requires maintenance.
- Ticket prices are configurable; too expensive reduces demand/satisfaction, too cheap reduces profit.

### 3. Visitors and needs
- Visitors have individual goals and needs, not just a shared queue state.
- Core needs: fun, hunger, thirst, rest, hygiene/toilet, and comfort.
- Visitors select facilities based on their needs, price, distance, waiting time, and availability.
- Visitors can become dissatisfied, leave early, or recommend the park when their experience is good.
- Crowd flow and queue lengths must influence decisions.

### 4. Services and staff
- Food, drink, souvenir, toilet, and rest facilities serve different needs and income/cost roles.
- Staff roles should include at least maintenance and service/cleaning before expanding into more complex roles.
- Staff have wages and work capacity; hiring should solve operational bottlenecks rather than be a cosmetic button.

### 5. Economy and idle progression
- Track income and expenses by source: admission, rides, shops, wages, upkeep, and expansion.
- Show current cash, income rate, expenses, and net profit clearly.
- Offline earnings must be calculated from elapsed time with a cap and sensible operating costs; do not grant unlimited profit if the park would have run out of cash or broken down.
- Balance the early game so the player can understand why the park is earning or losing money.

### 6. Progression and goals
- Unlock rides, services, land, and upgrades through clear milestones.
- Introduce objectives that teach the next management system (e.g. serve a visitor need, reach a satisfaction target, earn a profit target).
- Park rating and visitor demand should react to actual service quality, not only elapsed visitor counts.

## Development priorities

1. Make the current prototype's economy and visitor simulation consistent with the above loop.
2. Replace automatic shop sales with individual visitor decisions and service interactions.
3. Add configurable attraction prices and upgrade levels.
4. Add visitor needs, toilets/rest areas, and satisfaction feedback.
5. Add staff, wages, and maintenance tasks.
6. Add land expansion, unlock milestones, and balanced offline earnings.
7. Improve visuals, animations, sound, and mobile UI after the management loop is reliable.

## Current implementation status

PARKORA is still a prototype. It currently has a procedural park, paths and basic routefinding, two rides, visitors and queues, basic kiosk income, maintenance costs, and local save/restore. These systems are scaffolding, not the final management simulation. Runtime validation in Godot is still required.
