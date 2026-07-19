# zm8 command-first 5-8 player test plan

This is the runtime test plan for the stock-script audit. All new `zm8_test` scenarios are explicit **testing cheats**: they place players at the compatibility-sensitive step, grant test equipment, or advance stock quest stages. They are never run automatically and are not evidence that the complete Easter egg works. The passive 5-8 player fixes remain automatic.

Only the already-confirmed Der Eisendrache two-player bow-team feature has runtime verification. Every other expected result below is based on the stock decompile plus parser/emitter validation and still needs in-game confirmation.

## Common setup

1. Select **UNRANKED**, load the named map, open the host console, and run `spawnbot 7`.
2. Run `zm8_godmode 1`, then `zm8_test help`. The help line proves that the map helper linked and lists the scenarios available on that map.
3. Run one scenario per fresh map unless the procedure explicitly says to continue. Stage-skipping and one-shot map initialization are not designed to rewind.
4. Bots can validate arrays, ownership fields, transport destinations, flags, and spectator exclusion. Use real clients for simultaneous `F` presses, vehicle purchasing, pressure plates, soul collection, and movement-sensitive steps.
5. Record the first script/link error verbatim. After every transport, verify all living players retain controls, weapons, angles, and a valid next-round respawn.

Useful common commands:

- `zm8_spawn`: spawn waiting players.
- `zm8_godmode 1`: open barriers and maintain host health, points, ammo, speed, and perks.
- `zm8_test help`: show the current map's accelerated scenarios.

## Der Eisendrache (`zm_castle`)

Stock risks: one owner/coroutine per elemental quest, four Ragnarok pads, and stock boss readiness counting connected players. Automatic fix: two-person shared-contribution/ACTIVE bow teams; reusable upgraded-bow pickup; boss ritual requires living participants capped at the four real pads.

Run these on separate fresh loads where practical:

- `zm8_test bowteam`: assigns the first bot as Lightning ACTIVE and drives the confirmed shared-Lightning harness. At the Lightning undercroft box, press/release `F` once to join, then again to take ACTIVE. Expected: stable element prompt and ACTIVE/PARTNER transfer; either teammate contributes without duplicate stage changes.
- `zm8_test bows lightning`, `fire`, `void`, or `wolf`: gives the selected upgraded bow to every living player. Use this to verify duplicate ownership, ammo, weapon switching, and deliberate repeat pickup without replaying each elemental quest. Omit the element to give all four across the team.
- `zm8_test bossready`: skips to the real boss ritual and gives Ragnaroks, but does not force the pad counter. Put four real clients on the four pads and plant. With 5-8 living, four claimed pads must start the fight; a spectator must not block it.
- `zm8_test boss`: same setup, then forces the final transition for boss-arena and ending isolation. Expected: all living players reach valid destinations and regain controls.

Do not regress the already-confirmed box interaction or `zm8_de_botlightning` behavior.

## Origins (`zm_tomb`)

Stock risks: one staff world objective per element and an upgraded-punch gate requiring every connected entity. Automatic fix: shared staff pickup/objective state and a living-player-only punch gate.

- `zm8_test staffs fire`, `ice`, `wind`, or `lightning`: powers the generators and grants duplicate holders the selected stock staff. Omit the element to distribute all staff types. Verify two holders can charge, place, retrieve, and use the shared elemental objective without clearing one another's weapon.
- `zm8_test punchprep`: advances prerequisites to step 6 and gives upgraded punch to bots only. Expected: the stage remains blocked because the living host is unfinished.
- `zm8_test punchfinish`: gives the host's contribution through the stock punch state. Expected: the automatic living-player gate sets `ee_all_players_upgraded_punch` and advances exactly once.
- Spectator variant: after `punchprep`, let one bot/client spectate, then run `punchfinish`. Expected: the spectator is excluded.
- `zm8_test portal`: advances through the stock stage API to isolate final staff placement, robot button, portal, and ending behavior. Verify duplicate staff holders do not overwrite the one physical placed staff.

## Gorod Krovi (`zm_stalingrad`)

Stock risks: four dragon seats, 1-4-player balance/time arrays, challenge-pool exhaustion, four boss arrivals, and all-connected gates in KOTH, lockboxes, sewer, and boss entry. Automatic fixes preserve stock sequences while capping or padding only those limits.

- `zm8_test dragon`: turns on the crafted dragon network, gives points, and places the team at the library platform. Buy a trip with five real clients present. Expected: purchaser plus at most three others ride; the fifth stays controllable for the next trip.
- `zm8_test trials`: completes all three assigned trials for every living player via the real player flags. Before running it, inspect slots 7-8 for valid descriptions. Expected: no undefined trial; slots 5-8 may log the intentional no-safe-reward-board diagnostic.
- `zm8_test timer 5`, `10`, `15`, `20`, or `50`: invokes the stock reward/notification path immediately, so no round grind is required. Verify the named reward and no undefined player-count lookup.
- `zm8_test postquest`: invokes the stock post-quest all-perks threshold path.
- `zm8_test koth`: satisfies prior quest flags, credits bots/non-playing clients, and moves the host to the real KOTH interaction. A living human straggler must still be required.
- `zm8_test lockbox`, then on a fresh load `zm8_test lockbox2`: isolates both Dragon Strike lockbox all-player gates. Spectators/bots are credited; living humans must still participate.
- `zm8_test sewer`: skips prior quest work and sends every living player through the real sewer trigger. Expected: the stock gate opens only after every eligible player enters and all receive valid arrivals.
- `zm8_test boss`: performs the sewer setup and forces only the recovery counter, isolating boss teleport, four-player-capped balance, Nikolai sequence, and exit.

## Shadows of Evil (`zm_zod`)

Stock risks: 5+ zombie spawn delay is undefined, sword progress is character-indexed, post-Keeper logic accepts exactly four, and ending exits have four entries. Automatic fixes clamp pacing, duplicate an earned upgraded sword to the index twin, accept 4-8, and reuse exits with offsets.

- `zm8_test swordtwin`: gives an upgraded sword to one living member of the first duplicate character pair only. Expected: within two seconds the automatic assist gives the matching twin their sword. This requires at least five living players.
- `zm8_test swords 0`, `1`, or `2`: grants every living player the matching sword tier for inventory and all-player-gate isolation. Tier 2 is the upgraded quest sword.
- `zm8_test keepers`: starts the real four Keeper defenses without rituals, eggs, or ovum setup. Complete/observe them with 5-8 connected.
- `zm8_test shadowman`: credits all four Keeper defenses and starts the first Shadowman phase.
- `zm8_test tram`: credits the first Shadowman defeat and stops at the tram/co-op shock ending phase. Perform the tram/shock interactions with real clients; the coroutine must not stall merely because 5-8 are connected.
- `zm8_test ending`: advances through the same stock states and releases the ending. Expected: every client receives a defined exit; players 5-8 are offset from the first four.

## Zetsubou No Shima (`zm_island`)

Stock risks: challenge pools end at 5/6/5, challenge completion counts connected players, several encounter arrays end at four, and boss arrivals have four points. Automatic fixes repeat exhausted assignments, retain per-player flags, exclude spectators at the completion gate, clamp balance, and offset arrivals.

- `zm8_test challengesprep`: completes all bot challenge flags but leaves the host unfinished. Expected: `all_challenges_completed` stays false.
- `zm8_test challengesfinish`: adds only the host contribution. Expected: the stock all-challenges effects fire once. Repeat with a spectator before the finish command; the spectator must not block it.
- `zm8_test plants`: gives every living player a seed clientfield and places them at planting spots. Plant simultaneously and verify per-entity plants/harvests do not overwrite another player's state.
- `zm8_test masamune`: grants every living player an upgraded Masamune for ownership/use stress testing. This is intentionally more permissive than the legitimate globally unique quest item.
- `zm8_test zipline`: powers/unlocks/charges the real zipline and places players at its first control. Use a real client to test shield/ejection while extras and a spectator are present.
- `zm8_test pap`: starts the real valve-defense routine directly. Verify 5-8 use the four-player balance values and cleanup completes.
- `zm8_test skull 1` through `4`: starts that real Skull ritual balance routine. Use `zm8_test skullfinish <n>` to end the current ritual without grinding enemies, then start the next.
- `zm8_test skullroom`: starts the real final Skull-room defense.
- `zm8_test elevator`: marks the three gears found/placed, initializes the elevator, and puts all living players in its cage. Expected: all travel and regain controls.
- `zm8_test boss`: initializes Takeo, grants Masamunes, and moves every living player to padded fight arrivals. Verify boss pacing, down/rescue points, victory, and exit.

## Moon (`zm_moon`)

No proven hard 5-8 quest gate was found, so this helper changes no normal gameplay. Its commands isolate the remaining runtime-only risks.

- `zm8_test teleporter`: stacks all living players on the Area 51 teleporter. Test both directions; every living client must receive a valid character-index destination. Repeat with one spectator.
- `zm8_test hacker`: grants the host the Hacker through the stock limited-equipment API. Use it on the current quest hack instead of searching the labs.
- `zm8_test wavegun` and `zm8_test qed`: grant the relevant quest weapons.
- `zm8_test stage ss1`, `osc`, `sc`, `sc2`, or `ss2`: completes preceding main-sidequest stages through the stock stage API and stops when the requested stage becomes active.
- `zm8_test next`: completes only the currently active main stage.
- `zm8_test ee`: walks the main sidequest to completion for ending isolation. Because Moon has parallel subquests, treat any “stage did not become active” diagnostic as a runtime finding rather than forcing another flag.

Also check the documented cosmetic case: a spectator in Area 51 may prevent the zombie-distraction POI, but Pack-a-Punch itself must remain usable.

## Revelations (`zm_genesis`)

Stock risks: two arena paths and Old School timing directly index four entries; time trials end at four players; challenge pools end at six. Automatic fixes pad arrivals/timing, clamp thresholds, and repeat trial assignments with per-player state.

- `zm8_test trials`: completes all living players' assigned trials through real flags. Slots 7-8 must have valid data; slots 5-8 may log the intentional no-safe-board diagnostic.
- `zm8_test timer 5`, `10`, `15`, or `20`: invokes the stock reward immediately.
- `zm8_test oldschool`: starts the stock Old School reset timer using the padded current-player entry.
- `zm8_test runes`: credits the four runes and stacks every living player inside the real arena-portal radius. Expected: spectators are ignored and all living players satisfy the stock radius gate.
- `zm8_test arena1` and, on a fresh load, `zm8_test arena2`: invoke the real arena-arrival function for every living player. Verify defined, offset arrivals and controls.
- `zm8_test quest`: skips early main-quest setup for general late-state isolation.
- `zm8_test thundergun` and `zm8_test servant`: grant the relevant weapons.

## Shangri-La (`zm_temple`)

Stock risk: Pack-a-Punch requests one pressure plate per connected player despite four physical plates. Automatic fix: one plate per living participant capped at four. The main EE retains its four physical co-op roles.

- `zm8_test pap`: powers the map and places all living players across the required real plates. With eight living, PaP must open from the four plates; with three living plus spectators, only three plates must be required.
- `zm8_test shrinkray`: grants the quest wonder weapon.
- `zm8_test stage BaG`, `bttp`, `bttp2`, `DgCWf`, `LGS`, `OaFC`, `PtT`, or `StD`: skips preceding stages through the stock sidequest API and stops at the requested co-op step. Rotate which four real clients perform the physical roles while extras remain connected.
- `zm8_test next`: completes only the active stage after its compatibility behavior is observed.
- `zm8_test ee`: walks the main sidequest to completion for focusing-stone/ending isolation.

For the anti-115/dynamite-wall cleanup stages, move all living clients away before `next`. Spectator behavior remains a runtime uncertainty and is not silently forced.

## Ascension (`zm_cosmodrome`)

Stock risks: four lander anchors, opening cinematic direct indexing, Matryoshka VO only for indices 0-3, and the pressure timer counting spectators. Automatic fixes share/cap seats, modulo VO, and require every living participant.

- Opening cinematic: connect all clients before loading the map. It cannot safely be replayed mid-match. Expected: all eight regain control after sharing four authored anchors.
- `zm8_test lander`: powers the map, gives points, and moves all living players to the current lander. Buy with five real clients. Expected: exactly four ride and the next group can take another trip.
- `zm8_test pressurefast`: starts the real compatibility detour with a 10-second testing timer and stacks the living team. A living player stepping off must reset it; a spectator must not matter.
- `zm8_test pressure`: same test using the full stock 120-second timer and stock post-step effects.
- `zm8_test doll`: moves slots 5-8 to Matryoshka trigger 0. Use it and verify valid modulo-four VO.
- `zm8_test reward`: invokes the stock delayed Gersh reward iterator directly. After 12.5 seconds, every valid player must receive the normal all-perks/Death Machine reward without an index error.

## The Giant (`zm_factory`)

Stock risk: four teleporter staging and arrival slots. Automatic fix: include every valid pad occupant and offset players 5-8 on reused slots.

- `zm8_test teleporter`: places all living players at the mainframe pad and invokes the real detoured teleport path. Expected: all reach a defined destination, retain controls/weapons, and return normally. Repeat with one spectator and one downed player outside the pad.

## Shi No Numa (`zm_sumpf`)

Stock risks: four opening spawn structs and four zipline attachment tags. Automatic fix: reuse spawn structs with offsets and cap each real zipline trip at four.

- `zm8_test spawn`: reruns the real detoured opening placement immediately. Expected: all eight get valid positions, angles, and real `spectator_respawn` structs.
- `zm8_test zipline`: places all living players in the zipline volume and invokes the real detoured trip with the host as purchaser. Expected: purchaser plus at most three riders travel; extras remain controllable. Run it again from the opposite stop for the return trip.
- Bleed out a second-group player after `spawn`; their normal next-round respawn must use the valid reused struct.

## Kino der Toten (`zm_theater`)

Stock risk: four teleporter staging and projection-room slots. Automatic fix: reuse them with offsets for players 5-8.

- `zm8_test teleporter`: places all living players on the pad, invokes the real detoured trip to the projection room, waits 15 seconds, then invokes the stock return. Expected: all clients retain weapons/controls and receive defined positions. Repeat with a spectator/downed client.

## Verruckt (`zm_asylum`) and Nacht (`zm_prototype`)

No late quest, transport, player-count balance table, or compatibility-sensitive array was found, so there is no fake EE state to create.

- `zm8_test help`: reports that the map has no late scripted test state.
- `spawnbot 7`, `zm8_godmode 1`, and `zm8_spawn`: perform the full connection, spawn, round, down, spectator, and next-round-respawn baseline without progression grind.

## Interpretation rules

- A `zm8_test` command succeeding proves only the isolated stock path and compatibility detour reached by that command.
- Do not report a full EE as runtime-tested after using stage skips.
- Four world objects such as staffs, skull altars, bows, or co-op buttons remain four shared objectives; creating eight independent instances would race stock flags, models, animations, and cleanup.
- Four character identities still repeat for slots 5-8. Shared cosmetics are acceptable; undefined state, quest deadlocks, lost weapons, invalid destinations, or living-player exclusion are failures.
