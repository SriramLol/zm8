# zm8 stock-script audit and morning test plan

Audit basis: the decompiled T7 scripts at `C:\Games\Bo3\.t7-source` were checked for connected/active-player counts, fixed four-entry arrays, entity/character indexing, physical slots, single-owner fields and all-player gates. These changes have parser/emitter validation only. Nothing below is claimed as runtime-tested unless it is the already-confirmed Der Eisendrache two-player bow-team feature.

## Test setup and evidence capture

1. Set the private match to **UNRANKED**. Start the map from the UI or use `map <mapname>`.
2. Open the console after the map loads. Use `spawnbot 7` for connection/array smoke tests; use real clients for simultaneous-use, pressure-plate, vehicle and quest-participation tests because bots do not perform quest interactions reliably.
3. Confirm the map helper's `zm8:` loaded line appears. Keep the console open for diagnostics and record the first script/link error verbatim.
4. For spectator tests, let one client bleed out and remain in `sessionstate == "spectator"`; do not use `zm8_spawn` until the gate under test has resolved.
5. Run the legitimate route first. Commands labeled **testing cheat** below are only accelerated setup for isolating the late step; they are not evidence that the complete quest works.
6. After each transport or ending, verify all living clients retain weapons, controls, orientation and a valid `spectator_respawn` on the following round.

## Finding matrix

| Map | Stock failure or risk | Classification and exact fix | Code | Remaining uncertainty |
|---|---|---|---|---|
| Der Eisendrache (`zm_castle`) | Four physical Ragnarok pads, but `boss_fight_ready` waits for `level.players.size`; spectators and player 5 make the ritual impossible. Elemental bow quests have one owner/coroutine per element. | **Automatic:** require every living participant up to four, and four real claimed pads for 5–8. Existing, runtime-confirmed **shared contribution/ACTIVE** bow teams are preserved unchanged. | `zm_castle/zm8_castle.gsc`: `boss_fight_ready`; existing bow detours | Boss start/ending with 5–8 is not runtime-tested. Character twins share four teleport locations briefly. |
| Origins (`zm_tomb`) | Step 6's tablet handler sets `ee_all_players_upgraded_punch` only when every connected entity is upgraded; a spectator can never qualify. Staff world state has one owner/object per element. | **Automatic:** the stock stage coroutine waits until every living participant legitimately has `b_punch_upgraded`, sets the stock flag, then calls the stock stage completion API. Duplicate staff holders share the one elemental objective; no second quest instance is created. | `zm_tomb/zm8_tomb.gsc`: `stage_logic`; global `zm8.gsc`: staff pickup wrappers | Optional Origins challenge rewards remain keyed by four character indices. Duplicate staff holder UI/owner fields may show only one holder. |
| Gorod Krovi (`zm_stalingrad`) | Dragon has four passenger tags; boss balance arrays and landing structs end at four; three challenge pools end at six; time-trial switches end at four; KOTH, two lockboxes and sewer entry count spectators. | **Automatic:** cap each dragon trip at four; pad boss arrays/landings; repeat challenge assignments only after exhaustion; use four-player time thresholds for 5–8; credit only non-playing clients at all-connected gates. | global `zm8.gsc`: `zm8_gk_*`; `zm_stalingrad/zm8_stalingrad.gsc`: challenge and timer detours | Four challenge reward boards/models each hold one owner. Players 5–8 progress trials but cannot safely claim a board reward; console diagnostic is intentional. Full trials/boss sequence needs runtime testing. |
| Shadows of Evil (`zm_zod`) | Post-Keeper main coroutine continues only for exactly four players. Ending IGC indexes four named exits by player position. Sword ownership/progress is character-indexed. | **Automatic:** accept 4–8 in the stock branch, preserve Keeper states/ending, reuse four ending exits with offsets, and retain existing duplicate upgraded swords for character twins. | global `zm8.gsc`: spawn delay/sword assist; `zm_zod/zm8_zod.gsc`: `function_189ed812`, `function_5091df99` | Ritual/sword props are still one instance per character; twins share progress. Full 5–8 Shadowman/tram/ending runtime is unverified. |
| Zetsubou No Shima (`zm_island`) | Challenge pools end at 5/6/5; the all-challenges gate compares completion against all connected players; several encounter arrays and boss arrivals end at four. | **Automatic:** repeat exhausted assignments with per-player state/modulo boards; set the stock all-challenges flag only when every living participant completed all three; clamp stock balance tables; offset boss rescue arrivals. | `zm_island/zm8_island.gsc`: challenge, PaP, Skull and Takeo detours | KT-4/Masamune and Skull remain globally unique by design. Plant mutation ownership and the complete Takeo ending need runtime coverage. |
| Moon (`zm_moon`) | No hard 5–8 quest gate found. Teleport validation already excludes invalid players and character-index destinations remain defined. PaP's zombie-distraction POI counts all connected players. | **Safe with 5–8; cosmetic only:** no automatic patch. PaP itself works even if a spectator prevents the distraction POI. | No map helper; global commands are **testing cheats only** | Full 5–8 Richtofen EE remains runtime-unverified. Character twins share helmet clientfields. |
| Revelations (`zm_genesis`) | Both arena paths directly index four arrivals; Old School delay and time-trial switches end at four; three challenge pools end at six. | **Automatic:** pad arena arrivals/Old School delay to eight; use four-player time thresholds; repeat trials after exhaustion and keep independent progress. | `zm_genesis/zm8_genesis.gsc`: one-shot padders, timer and challenge detours | Only four single-owner reward boards exist. Players 5–8 progress trials without reward-board pickup. Main rift gate is stock-safe and still requires all living players in its small radius. |
| Shangri-La (`zm_temple`) | Pack-a-Punch asks for one plate per connected player but has four plates. Main EE has four physical co-op roles/buttons; two cleanup loops include all connected players. | **Automatic:** existing helper requires living players capped at four for PaP. Main EE's four-role actions are safe: any four unique participants can contribute. | `zm_temple/zm8_temple.gsc`: PaP plate detour | The two “all players leave wall” cleanup loops were not forced; walk all clients away. Spectator-follow behavior should be runtime-checked. |
| Ascension (`zm_cosmodrome`) | Lander has four anchors; intro indexes them for every player; Matryoshka VO handles only indices 0–3; main EE pressure timer includes spectators. | **Automatic:** four riders per normal trip, shared cinematic anchors, modulo VO, and a faithful pressure timer requiring every living participant. | `zm_cosmodrome/zm8_cosmodrome.gsc`: lander, VO, `area_timer` detours | Eight-player Gersh-device finale/reward has not been runtime-tested. |
| The Giant (`zm_factory`) | Mainframe teleporter staging and destination arrays have four slots. | **Automatic:** include all valid pad occupants, fold the second group onto four slots with offsets. | `zm_factory/zm8_factory.gsc`: teleporter detours | Simultaneous eight-player arrival collision/crumb behavior needs runtime testing. No main quest blocker found. |
| Shi No Numa (`zm_sumpf`) | Opening placement indexes four spawn structs directly. Zipline keeps assigning after four attachment tags are exhausted. | **Automatic:** reuse spawn structs with offsets and retain the real struct as `spectator_respawn`; carry at most four zipline riders per trip. | `zm_sumpf/zm8_sumpf.gsc`: spawn and zipline detours | Verify purchaser-first ordering and return trip with players waiting at both stops. |
| Kino der Toten (`zm_theater`) | Teleporter directly indexes four staging/destination slots. | **Automatic:** fold players 5–8 onto valid slots and offset the second group at both ends. | `zm_theater/zm8_theater.gsc`: teleporter detours | Eight-player film-room return and downed-player handling need runtime testing. No main quest blocker found. |

## Exact map test procedures

### Der Eisendrache

1. `map zm_castle`, then `spawnbot 7`; confirm `zm8: DE two-player shared bow teams loaded` and no linker error.
2. Preserve the confirmed bow regression test: with one bot use `spawnbot 1`, then `zm8_de_botlightning`. Approach the Lightning undercroft soul box, press/release `F` once to join, then press/release again to take ACTIVE. Repeat contributions at plates, urns and bonfires; repeat the upgraded-bow pickup deliberately. Expected: the stock stage changes once, both teammates contribute, and the box interaction text remains stable.
3. Legitimate boss test: complete the quest, give/earn Ragnaroks normally, place four living players on the four undercroft pads and plant simultaneously while players 5–8 stand nearby. Expected: four real claims start the fight; no command is needed.
4. Spectator variant: bleed out player 8 before the ritual and repeat. Expected: the spectator is excluded.
5. Accelerated isolation only: `zm8_de_eecomplete`, then `zm8_de_ragnarok`. `zm8_de_bossfight` is now a **testing/recovery cheat**, not the normal compatibility path.

### Origins

1. `map zm_tomb`, `spawnbot 7`; verify `zm8: Origins active-player punch gate compatibility loaded`.
2. With human clients, have two players take the same base staff from its pedestal. Charge/upgrade it using shared nearby kills, place the one physical staff where the quest requests it, and confirm the second holder neither resets nor duplicates the stock prop.
3. Reach step 6 normally. Every living player must earn 20 fist souls and collect their tablet. Bleed out one otherwise-unupgraded client before the last living player collects theirs.
4. Expected: `ee_all_players_upgraded_punch` advances the stock stage only after all living participants have the upgrade; the spectator does not block it. Respawned players should retain normal quest flow.
5. Accelerated isolation only: `zm8_origins_generators`, repeated `zm8_origins_eenext`, or `zm8_origins_punch` are **testing cheats**.

### Gorod Krovi

1. `map zm_stalingrad`, `spawnbot 7`; confirm both global GK messages and `zm8: Gorod Krovi 5-8 player challenge compatibility loaded` with no undefined challenge error.
2. Inspect each human client's three trials. Players 7–8 must have valid descriptions/progress. Players 5–8 should produce the explicit “no safe reward board” console diagnostic; do not treat absent reward pickup as a new failure.
3. Finish round 5 under 240 seconds with 5–8 connected. Expected: stock time-trial notification/reward. Repeat the round 10/15/20 thresholds when practical.
4. Board dragons with five players at one station. Expected: exactly four travel and the fifth remains controllable for the next trip.
5. During KOTH and each Dragon Strike lockbox stage, leave one client spectating while every living client performs the interaction. Expected: the non-playing client is credited; living stragglers are not.
6. Take all living clients through the sewer. Expected: the stock boss transition begins after every eligible rider, with eight valid landing spots and four-player-capped boss pacing.
7. `zm8_gk_arena` is a manual recovery path only. `zm8_gk_eecomplete`, `zm8_gk_koth`, `zm8_gk_weapons` and `zm8_gk_gauntlet` are **testing cheats**.

### Shadows of Evil

1. `map zm_zod`, `spawnbot 7`; confirm the Zod helper and no unresolved `zm_zod_sword` import.
2. Complete rituals and sword eggs normally with at least five humans. When a character's upgraded sword is earned, verify its character twin receives a duplicate and the all-active sword gate can finish.
3. Complete all four Keeper defenses. Expected with 5–8 connected: `ee_quest_state` proceeds to the stock final phase instead of stopping at state 2.
4. Complete Shadowman damage/banish and the tram/co-op shock sequence. At the ending, verify all clients appear at defined exits; players 5–8 should be offset from the first group.
5. Accelerated isolation only: `zm8_soe_eecomplete`, `zm8_soe_swords 2`, and `zm8_soe_servant` are **testing cheats**.

### Zetsubou No Shima

1. `map zm_island`, `spawnbot 7`; confirm the helper and valid challenges for all clients. Verify players 5–8 see/use their modulo board but retain independent progress.
2. With humans, complete all three trials for every living participant. Leave one client spectating. Expected: the stock `all_challenges_completed` effects play once and the electric-shield/zipline step unlocks.
3. Perform the charged electric-shield zipline action with multiple players at the line. Expected: the actual rider is ejected normally and no spectator blocks it.
4. Run each Skull ritual, final Skull room, PaP valve defense and Takeo boss with 5–8 connected. Expected: four-player-capped pacing, no undefined arrays, and separated rescue destinations.
5. Test KT-4/Masamune, plants, elevator entry and Takeo sequencing normally; no duplication/skip command was added.

### Moon

1. `map zm_moon`, `spawnbot 7`; verify all living clients travel both directions through the Area 51 teleporter and arrive at defined character-index destinations.
2. Complete hacker, QED, excavator and Richtofen EE interactions normally with 5–8. Verify no all-player gate stalls.
3. Spectator cosmetic check: leave one client spectating at Area 51. Expected: PaP remains usable even if the zombie-distraction POI does not activate.
4. `zm8_moon_wavegun` and `zm8_moon_qed` are **testing cheats** only.

### Revelations

1. `map zm_genesis`, `spawnbot 7`; confirm arena, Old School and challenge padding messages. Players 7–8 must receive valid trial data; players 5–8 log the intentional no-board-reward diagnostic.
2. Finish round 5 under 240 seconds with 5–8 connected. Expected: the time-trial notification and reward. Repeat rounds 10/15/20 where practical.
3. Trigger the Old School side egg. Expected: its two-second four-player delay is used and no undefined wait occurs.
4. Complete four Keeper runes. Stack every living player within the stock 84-unit rune-portal radius. Expected: the gate opens without spectator assistance.
5. Enter both arena phases with 5–8 living clients. Expected: every `function_56668973` receives a defined padded arrival; the second group is offset.
6. Accelerated early setup only: `zm8_rev_eecomplete` is a **testing cheat**; the rune trial and portal entry remain manual. Weapon commands are cheats.

### Shangri-La

1. `map zm_temple`, `spawnbot 7`; with eight living players, occupy all four PaP plates. Expected: PaP opens at four physical plates.
2. With three living and one or more spectators, occupy three plates. Expected: PaP opens; spectators are excluded.
3. Run the main EE: use four unique players on sundial/co-op actions; let different members of the 5–8 group fill those roles on a second attempt. Verify waterslide/eclipses/focusing stone remain stock.
4. After anti-115/dynamite-wall steps, walk every client well outside the area. Record any spectator cleanup stall; no forced completion was added.
5. `zm8_shang_shrinkray` is a **testing cheat** only.

### Ascension

1. `map zm_cosmodrome`, `spawnbot 7`; verify all eight survive the opening cinematic and regain controls after sharing four anchors.
2. Put five humans on a normal lander platform and buy the trip. Expected: four riders travel, purchaser is not displaced by bystanders, fifth remains controllable and can take the next trip.
3. Reach the Gersh pressure plate. Keep every living client on the plate for the full stock timer while one client spectates. Expected: timer completes and the nuke/quest sequence fires once. A living straggler must reset the timer.
4. Trigger the Matryoshka doll responses with player slots 5–8. Expected: valid modulo-four VO and no undefined alias.

### The Giant

1. `map zm_factory`, `spawnbot 7`; gather all living clients on the mainframe teleporter and activate it.
2. Expected: every pad occupant is staged, teleported and returned; players 5–8 use nearby offsets and retain controls/weapons. Repeat with a spectator and with one downed player outside the pad.

### Shi No Numa

1. `map zm_sumpf`, then immediately `spawnbot 7` before round logic settles. Expected: all eight receive defined initial positions/angles; players 5–8 are offset and later have valid spectator respawns.
2. Put five humans at a zipline stop and have one buy it. Expected: purchaser plus at most three others ride; the fifth stays controllable. Repeat the return trip and swap which player buys.
3. Bleed out an offset-spawn player and wait for normal round respawn. Expected: the real reused spawn struct works as `spectator_respawn`.

### Kino der Toten

1. `map zm_theater`, `spawnbot 7`; place all living clients in the teleporter and activate it.
2. Expected: all clients reach the projection room using four valid destinations plus second-group offsets, then return with controls/weapons intact. Repeat with one spectator and one downed client.

## No-change audit notes

- Physical four-role quest objects (four Origins staffs, four Shangri-La sundial buttons, four Zetsubou skull altars) are objective counts, not arrays that must expand to eight. Sharing/rotating participants is correct; creating eight independent world instances would race stock global flags and cleanup.
- Character-index arrays on all maps remain 0–3 by design. zm8 only duplicates a held quest weapon where the stock all-active-player gate makes that necessary (DE bows, Origins staffs, Shadows swords). VO/models/cosmetics may be shared by character twins.
- No new permanent global poller was added. New polling is confined to an active quest stage, an existing replaced timer, or one-shot initialization; existing GK/DE monitors were extended rather than duplicated.
