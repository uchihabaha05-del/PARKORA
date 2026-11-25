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
- New land sections unlock progressively and have meaningful prices; the prototype begins with a central plot and offers north, west, and east expansions.
- Construction is restricted to owned plots; purchased boundaries are shown in-world and unlock state is saved.
- Facilities need pedestrian access; paths must connect to the entrance.
- Layout matters: visitors should not need to cross the entire park for basic needs.

### 2. Attractions
- Multiple attraction categories with distinct prices, capacity, ride duration, appeal, and operating costs.
- Each attraction can be upgraded in stages. Upgrades should improve capacity, speed/throughput, appeal, or satisfaction.
- Attraction condition declines with operation and requires maintenance.
- Ticket prices are configurable; too expensive reduces demand/satisfaction, too cheap reduces profit.
- Ticket prices are configurable; a price close to a guest's spending limit reduces perceived value and satisfaction.
- Ride selection considers estimated waiting time, attraction condition, and guest willingness to pay.
- The ride panel shows queue occupancy, estimated wait, hourly throughput, and accumulated price-value feedback.

### 3. Visitors and needs
- Visitors have individual goals and needs, not just a shared queue state.
- Core needs: fun, hunger, thirst, rest, hygiene/toilet, and comfort.
- Visitors select facilities based on their needs, price, distance, waiting time, and availability.
- Visitors can become dissatisfied, leave early, or recommend the park when their experience is good.
- Each guest has an individual satisfaction score affected by queue patience, unmet needs, completed rides, service use, cleanliness, and attraction condition.
- Aggregate satisfaction and positive/negative review totals persist between sessions; satisfaction influences reputation and visitor demand.
- Crowd flow and queue lengths must influence decisions.

### 4. Services and staff
- Food, drink, souvenir, toilet, and rest facilities serve different needs and income/cost roles.
- Staff roles should include at least maintenance and service/cleaning before expanding into more complex roles.
- Staff have wages and work capacity; hiring should solve operational bottlenecks rather than be a cosmetic button.

### 5. Economy and idle progression
- Track lifetime income by source: admission, rides, and visitor services; track recurring expenses by staff wages, service-facility upkeep, and attraction maintenance.
- Show a rolling one-minute operating report with income, expenses, and net profit, alongside lifetime totals.
- Persist the categorized ledger and current reporting window in the local save so the financial picture survives a restart.
- Keep one-off construction, hiring, upgrades, and manual repairs distinct from recurring operating expenses.
- Offline earnings are calculated from elapsed wall-clock time, capped at 8 hours per absence, and use conservative visitor demand, ride condition, cleanliness, ticket prices, service sales, staff wages, and facility upkeep.
- Offline income and expenses update the same lifetime ledger as active play. Closed attractions generate no visitors; upkeep still applies, cash cannot fall below zero, and unpaid costs reduce park rating.
- Save the last successful game timestamp and apply offline settlement once on the next load, then reset the timestamp to prevent repeated claims.
- Balance the early game so the player can understand why the park is earning or losing money.

### 6. Progression and goals
- Unlock rides, services, land, and upgrades through clear milestones.
- Introduce sequential objectives that teach park management (welcome visitors, build attractions and services, earn revenue, hire staff, and improve rating/cleanliness), with one-time coin rewards and saved progress.
- Park rating and visitor demand should react to actual service quality, not only elapsed visitor counts.

## Development priorities

1. Make the current prototype's economy and visitor simulation consistent with the above loop.
2. Replace automatic shop sales with individual visitor decisions and service interactions.
3. Add configurable attraction prices and upgrade levels.
4. Expand visitor needs, toilets/rest areas, and satisfaction feedback.
5. Add staff, wages, and maintenance tasks.
6. Expand land, objectives, offline settlement, and economy balancing based on device testing.
7. Improve visuals, animations, sound, and mobile UI after the management loop is reliable.

## Current implementation status

PARKORA is still a prototype. It currently has a procedural park, path-based routefinding, two rides, visitor queues, configurable ride prices and upgrades, attraction condition and repair, food/drink kiosks, individual hunger/thirst needs, buildable toilets and rest areas, individual hygiene/rest needs, visitor-paid facility use, cleaner and mechanic hiring, litter and cleanliness simulation, recurring staff wages and facility upkeep, automatic mechanic maintenance, categorized lifetime income and operating expenses, individual guest satisfaction with persistent review statistics and demand feedback, a rolling one-minute profit report, six sequential rewarded park objectives with saved progress, three purchasable land expansions with ownership-gated construction, capped eight-hour offline earnings with operating expenses and attraction wear, and local save/restore of built objects and park finances. These systems are scaffolding, not the final management simulation. Runtime validation in Godot is still required.

- Each service building tracks its own customer count, revenue, recurring operating costs, and net profit. Operating costs are allocated from the existing service upkeep budget, not charged twice. The HUD highlights the most and least profitable service buildings.

- Service buildings use first-in-first-out queues, serve one visitor at a time, reduce guest satisfaction after eight seconds of waiting, and lose visitors who wait 45 seconds
