# zm8 — 8-Player Zombies for Black Ops III

Play **Call of Duty: Black Ops III zombies with up to 8 players** on every map — stock and DLC (Der Eisendrache, The Giant, Origins, ...). No mod menu, no workshop subscription.

This package **bundles the BOIII client v1.1.7** (`boiii.exe`) and pins it: the included launcher runs it with `-noupdate` so it never auto-updates to a newer build that breaks the mod. You still need your own working Black Ops III + BOIII install to drop these files into — the game itself is not included.

**Only the host needs this mod.** Friends install nothing — they join through the server browser or direct connect.

## Features

- Up to 8 players in classic zombies on all stock + DLC maps
- Zombie counter HUD (top left): zombies left to spawn + currently alive
- GobbleGums for players 5–8 — the game normally gives them none; they get a shared pack you pick with the included dropdown gum picker (type-to-filter)
- Optional **permanent all-perks** for everyone (host console toggle, persists between games)
- Carpenter power-up removed from the drop pool (crash prevention)
- Server client slots forced to 8 every game (`com_maxclients`/`party_maxplayers`) — without this the listen server can keep the stock 4 slots and refuse the 5th connection outright

## How it works

The 4-player limit in classic zombies is script-enforced, not an engine limit — `_zm.gsc` ends the game when a 5th player is detected, but allows 8 for Treyarch's own Grief mode, meaning the engine officially supports 8 zombies clients. This mod re-caps that check at 8 via the BOIII client's `detour` feature, fixes character assignment for slots 5–8, and swaps in GobbleGum packs for players the engine gives none (their loadout data only exists for 4 slots). Everything runs host-side in GSC; effects reach joiners through normal game networking.

BO3's native pools remain fixed: **130,000 server ScrVars, 65,000 client ScrVars and 2,048 game entities**. GSC cannot enlarge them. Long-session 8-player stability remains under investigation; the stock 24-zombies-alive cap is unchanged.

EZZ v1.1.7 restored its legacy custom-builtin dispatcher. zm8 uses the v1.1.7 unqualified builtin syntax and supplies an explicit empty filter to `getcommand("")`, avoiding the client's broken zero-real-argument path during map startup.

## Version & updates (why this pins v1.1.7)

The BOIII client auto-updates on launch: it pulls a file manifest from the update server and re-downloads anything — **including `boiii.exe` itself** — that doesn't match the current "latest" build, then relaunches. It has **no per-version channel** (the only switch is latest-vs-beta), so you cannot ask the server for an older build. Newer builds (e.g. 1.1.10) change the client in ways that break this mod, and 1.1.10 was broken outright for us.

The fix is the client's `-noupdate` launch flag, which makes the updater return before it ever contacts the server. This package therefore:

- ships a known-good **`boiii.exe` v1.1.7** (sha256 `afc842482c14010c2225e61fe796536a632a4ad330952aa36284ae292eac2134`, the official v1.1.7 release binary), and
- launches it via `launch-zm8.bat` with `-noupdate`.

`-noupdate` has a second useful effect: the client's startup **purge** of `%LOCALAPPDATA%\boiii` lives inside the updater, so disabling the updater also stops the purge — the mod files under `boiii\` are left untouched.

**The pin lives entirely in the launcher flag.** If you start `boiii.exe` directly, or through the EZZ launcher, without `-noupdate`, it will immediately update to the latest build and overwrite the pinned exe — so always launch with the bat.

## Installation

1. Find your Black Ops III game folder — the one containing `boiii.exe`.
2. Copy the contents of the release zip into it, keeping the folder structure, and **replace `boiii.exe` when prompted** (that swap is what pins you to v1.1.7):
   ```
   <BO3 folder>\boiii.exe                        (v1.1.7)
   <BO3 folder>\boiii\custom_scripts\zm\zm8.gsc
   <BO3 folder>\boiii\custom_scripts\zm_castle\zm8_castle.gsc
   <BO3 folder>\boiii\custom_scripts\zm_cosmodrome\zm8_cosmodrome.gsc
   <BO3 folder>\boiii\custom_scripts\zm_factory\zm8_factory.gsc
   <BO3 folder>\boiii\custom_scripts\zm_genesis\zm8_genesis.gsc
   <BO3 folder>\boiii\custom_scripts\zm_island\zm8_island.gsc
   <BO3 folder>\boiii\custom_scripts\zm_moon\zm8_moon.gsc
   <BO3 folder>\boiii\custom_scripts\zm_stalingrad\zm8_stalingrad.gsc
   <BO3 folder>\boiii\custom_scripts\zm_sumpf\zm8_sumpf.gsc
   <BO3 folder>\boiii\custom_scripts\zm_temple\zm8_temple.gsc
   <BO3 folder>\boiii\custom_scripts\zm_theater\zm8_theater.gsc
   <BO3 folder>\boiii\custom_scripts\zm_tomb\zm8_tomb.gsc
   <BO3 folder>\boiii\custom_scripts\zm_zod\zm8_zod.gsc
   <BO3 folder>\boiii\ui_scripts\zm_8player\__init__.lua
   <BO3 folder>\launch-zm8.bat
   <BO3 folder>\zm8-gum-picker.bat
   <BO3 folder>\zm8-gum-picker.ps1
   ```
3. Done. The only file replaced is `boiii.exe` (swapped to the pinned v1.1.7); everything else is added. If you don't already have BOIII, install it from ezz.lol first, then apply this package over it.

## Hosting

1. **Always start the game with `launch-zm8.bat`** (double-click it). This is required — the bat passes `-noupdate`, which keeps you on the bundled v1.1.7 and stops the client's startup purge. Launching `boiii.exe` or the EZZ launcher directly will auto-update to the latest build and break the mod. (The bat also closes any leftover BO3 process so you never get "already running".)
2. Zombies → Private Game → any map → **Configure Game Ranking → non-ranked** (custom scripts only load in non-ranked matches).
3. Start. ~6 seconds in you'll see **"zm8 mod loaded - 8 player cap active"** and the zombie counter.
4. Friends join via server browser or `connect <your-ip>` — up to 8 total.

## GobbleGums for players 5–8

Run `zm8-gum-picker.bat` → pick up to 5 gums (type to filter, `per` → Perkaholic) → Save. The per-map gum list refreshes each time you play a map (`boiii\scriptdata\zm8\available_gums.txt`). Gums marked `(mega)` are experimental. No pack saved → default classics. You can also edit `boiii\scriptdata\zm8\gum_pack.txt` by hand — one gum per line, friendly names work.

## Console commands (host, `~`)

### Command categories

- **5–8-player compatibility** means the command only releases a stock all-player gate that is impossible or unsafe above four players. Use it only after the team legitimately reaches that gate. These commands do not grant free equipment or skip the rest of the quest.
- **Testing cheat** means the command grants equipment, power or quest progress without completing the normal objective. Cheats are optional testing tools; they are not required for normal 5–8-player play.
- **Host utility** means player/session management rather than an Easter-egg bypass. `zm8_spawn` can still act as a cheat when used to revive a bled-out player early.

No manual command is required for normal 5–8-player quest completion. One recovery command remains for a runtime-only transport failure:

- `zm8_gk_arena` — releases Gorod Krovi's all-connected-players sewer gate if its automatic recovery fails after all active players enter.

**Every equipment-grant, door/power setup, generator activation, KOTH completion and quest-skip command is a testing cheat.** The core 8-player cap and passive map fixes are automatic and require no command.

| Command | Effect |
|---|---|
| `zm8_allperks` | **Testing cheat:** toggle permanent all-perks for everyone (default: off) |
| `zm8_allperks 1` / `0` | **Testing cheat:** explicitly enable / disable permanent all-perks |
| `zm8_godmode [1\|0]` | **Testing cheat:** toggle the host's maintained damage immunity, all perks, 2× movement speed, unlimited sprint, ammunition and points. Enabling also force-opens every registered buyable door, airlock and debris barrier (plus map `open_sesame` listeners), and gives a Pack-a-Punched KRM-262 with Dead Wire using the host's weapon-kit attachments/camo. Turning it off stops maintenance but does not close barriers or revoke granted perks, points or the KRM |
| `zm8_spawn` | **Host utility:** spawn everyone waiting in spectate right now (mid-round joiners and bled-out players). Using it on the latter is an early-revive cheat |
| `zm8_autospawn` | **Host utility:** toggle auto-spawn for mid-round joiners within ~3s; bled-out players remain excluded. Default: on |
| `zm8_autospawn 1` / `0` | **Host utility:** explicitly enable / disable joiner auto-spawn |
| `zm8_gum <name>` | **Testing cheat:** give the host any GobbleGum instantly, e.g. `zm8_gum shopping free`. Names as in `zm8/available_gums.txt` |

Toggles reset to their defaults every new game.

### Command-first audit harness (`zm8_test`)

`zm8_test` is a map-aware **testing-cheat dispatcher** added for 5-8-player runtime auditing. It never runs automatically. Start an UNRANKED map, run `spawnbot 7`, `zm8_godmode 1`, then `zm8_test help`. Every compatibility-sensitive late step now has an accelerated setup, so testers do not have to complete an Easter egg solo with bots.

| Map | Scenarios shown by `zm8_test help` |
|---|---|
| Der Eisendrache | `bowteam`, `bows [element]`, `bossready`, `boss` |
| Origins | `staffs [element]`, `punchprep`, `punchfinish`, `portal` |
| Gorod Krovi | `dragon`, `trials`, `timer <5\|10\|15\|20\|50>`, `postquest`, `koth`, `lockbox`, `lockbox2`, `sewer`, `boss` |
| Shadows of Evil | `swords [0\|1\|2]`, `swordtwin`, `keepers`, `shadowman`, `tram`, `ending` |
| Zetsubou No Shima | `challengesprep`, `challengesfinish`, `plants`, `masamune`, `zipline`, `pap`, `skull <1-4>`, `skullfinish <1-4>`, `skullroom`, `elevator`, `boss` |
| Moon | `teleporter`, `hacker`, `next`, `stage <ss1\|osc\|sc\|sc2\|ss2>`, `ee`, `wavegun`, `qed` |
| Revelations | `quest`, `trials`, `timer <5\|10\|15\|20>`, `oldschool`, `runes`, `arena1`, `arena2`, `thundergun`, `servant` |
| Shangri-La | `pap`, `next`, `stage <BaG\|bttp\|bttp2\|DgCWf\|LGS\|OaFC\|PtT\|StD>`, `ee`, `shrinkray` |
| Ascension | `lander`, `pressure`, `pressurefast`, `doll`, `reward` |
| The Giant | `teleporter` |
| Shi No Numa | `spawn`, `zipline` |
| Kino der Toten | `teleporter` |
| Verruckt / Nacht | no late quest state; use the common spawn/round utilities |

See [MAP_AUDIT_TEST_PLAN.md](MAP_AUDIT_TEST_PLAN.md) for the exact command order, expected result, spectator variants, and the distinction between isolated-path evidence and a complete runtime-verified EE.

### Der Eisendrache commands (`zm8_de_*`)

Legacy map-prefixed commands remain available and no-op on other maps. The `zm8_test` dispatcher above is the recommended audit interface.

Automatic compatibility fixes:

- Upgraded-bow pedestals remain reusable so players 5–8 can take duplicate upgraded bows. Each player may hold only one upgraded bow at a time.
- All four elemental quests support independent **two-player bow teams**: two Lightning, two Fire, two Void and two Wolf players, covering all eight slots. The first player who legitimately starts a stock bow quest becomes its active runner. A second player presses `P` at that bow's final soul box/altar in the main pyramid undercroft—the box where the reforged arrow is placed and the upgraded bow eventually appears. This dedicated, stock-style prompt does not consume the normal Use/`F` input. Both teammates can simultaneously contribute to the same stage: kills, souls, bow shots, Lightning plates/urns/bonfires, Fire runes, Void circles/golf shots, and Wolf escort/bone steps are credited to either teammate. A small personal HUD reads `ACTIVE`, `PARTNER` or `WAITING`. One player may join one bow team, with two players maximum per bow. This is a compatibility feature, not a quest-progress cheat.
- The shared Lightning wall-plate step has no artificial timer. Each teammate enters the attempt when they hit their first plate; from then until the fifth shared plate, that participating player touching the ground resets the shared sequence exactly like stock. A teammate who has not hit a plate yet may wait on the ground.
- The final boss ritual still requires simultaneous real Ragnarok plants. It requires every living participant up to the four physical pads; a 5–8-player team must claim all four pads. Spectators no longer make the gate impossible.

DE still has only one global coroutine, owner field, arrow and physical objective set per element. Consequently, teammates cannot run two independent copies of the same bow at different stages. One teammate remains the active stock owner for unique one-time actions—binding the broken arrow, reforging it, placing it and driving stock cleanup. Press `P` at that bow's pyramid soul box/altar again to hand this role to the partner without losing progress; ordinary stage contributions do not require a handoff.

| Command | Effect |
|---|---|
| `zm8_de_bossfight` | **Testing/recovery cheat:** force the final boss-pad counter after the team reaches the undercroft. The automatic fix now supports the legitimate four-pad ritual, so this command is only for isolating a failed runtime test |
| `zm8_de_test` | **Testing cheat:** force-purchase all buyable doors/debris, turn on power and give current players damage immunity. `zm8_de_test 0` removes immunity; doors and power remain |
| `zm8_de_eecomplete` | **Testing cheat:** skip the entire main quest straight to boss-ready and auto-press the pyramid canister. Skipped quest state may prevent the ending cinematic |
| `zm8_de_bows [element]` | **Testing cheat:** give every living player an upgraded bow with full ammo. Element: `fire`, `void`, `storm` or `wolf`; no argument mixes all four |
| `zm8_de_lightningready` | **Testing cheat:** fill all three dragons and drive the stock Lightning Bow quest until the upgraded bow appears on its altar |
| `zm8_de_lightningstep` | **Testing cheat:** advance exactly one stock Lightning Bow stage per use. Use it to reach a desired stage, then have the two Lightning teammates split its remaining legitimate targets to verify shared contribution |
| `zm8_de_botlightning` | **Testing cheat:** select the first alive bot, prepare the dragons/start Lightning if needed, transfer the live stock Lightning quest to that bot, and remove the host from its team. The host can then use the Lightning soul box/altar once to test joining as its partner |
| `zm8_de_ragnarok` | **Testing cheat:** give every living player the Ragnarok DG-4 |

### Origins commands (`zm8_origins_*`)

Origins' object gates count four staffs/placements rather than players. Duplicate staff pickups are enabled automatically, so players 5–8 may hold a repeated element and contribute kills/charging around the same physical staff objective. Step 6's stock all-connected-player check is detoured to require every **living participant** to earn the upgraded One-Inch Punch; spectators no longer block it. Staff owner/model state remains single-instance per element, so duplicated holders share progress rather than running independent quests.

| Command | Effect |
|---|---|
| `zm8_origins_generators` | **Testing cheat:** activate and power all six generators without capturing them normally |
| `zm8_origins_eecomplete` | **Testing cheat:** activate the generators and force every main-quest gate through the final portal step |
| `zm8_origins_eenext` | **Testing cheat:** force-complete the current main-quest stage. Repeated use walks the quest forward and may leave skipped physical props in an unusual state |
| `zm8_origins_punch` | **Testing cheat:** give every living player the upgraded One-Inch Punch and satisfy the all-connected-players step-6 check |
| `zm8_origins_staffs [element]` | **Testing cheat:** give every living player an upgraded staff with full ammo. Element: `fire`, `ice`, `wind` or `lightning`; no argument mixes elements |

### Gorod Krovi commands (`zm8_gk_*`) and automatic fixes

Gorod Krovi needed the most work of any map so far. zm8 fixes these stock failures **automatically** — no command needed:

- **Dragon ride**: the dragon only has 4 passenger positions; a 5th boarder crashes the script. zm8 declares the ride full the moment 4 players are aboard — everyone else catches the next flight.
- **Boss fight scaling**: the final fight reads zombie-count tables sized for 1–4 players; with 5+ the lookup errors mid-fight. zm8 pads the tables (5–8 players get 4-player pacing).
- **Boss arena teleport**: the fight start teleports each active player to one of 4 landing spots. zm8 clones them up to 8.
- **Challenge pools:** all three six-entry pools are exhausted by player 7. Assignments now repeat only after a pool empties. Players 5–8 receive and progress real trials, but the four single-owner physical reward boards are not shared; their missing reward slot is reported in the console.
- **Time trials/rewards:** round 5/10/15/20/50 thresholds and the post-quest all-perks threshold have only 1–4-player cases. Teams of 5–8 use the stock four-player thresholds.

Four easter-egg gates count **every connected player** (spectators included) and are auto-credited only for players who are not in play: the network-console (KOTH) defense, both Dragon Strike lockbox stages, and the sewer ride into the boss arena.

| Command | Effect |
|---|---|
| `zm8_gk_arena` | **5–8-player compatibility:** manually release the sewer/boss-arena all-connected-players gate if automatic recovery fails. Use only after every active participant has taken the sewer; stragglers miss the transport |
| `zm8_gk_eecomplete` | **Testing cheat:** force the "Love and War" quest flags through the boss phase, then automatically activate the stock arena-start trigger after everyone finishes the sewer ride. Physical objectives are skipped and the ending sequence may not behave normally |
| `zm8_gk_koth` | **Testing cheat:** credit every connected player for the network-console defense. This completes the objective rather than merely increasing its player capacity |
| `zm8_gk_weapons [kind]` | **Testing cheat:** give every living player a wonder weapon — `fire` (GKZ-45 Mk3), `strike` (Dragon Strike), `gauntlet` or experimental `shield` |
| `zm8_gk_gauntlet` | **Testing cheat:** skip the Gauntlet of Siegfried incubation quest and give out the gauntlet |

### Shadows of Evil commands (`zm8_soe_*`) and automatic fixes

Four things are fixed **automatically** — no command needed:

- **Round spawner crash**: the map's zombie spawn-delay formula only covers 1–4 players and script-errors with a 5th player in the game. zm8 swaps in a clamped copy (5–8 get 4-player pacing).
- **Sword gate**: the main quest's keeper phase (`ee_begin`) waits until **every active player** holds their character's upgraded Apothicon sword, but sword progress is tracked per character — players 5–8 share a character with someone else and can never earn their own. zm8 auto-hands a duplicate the sword once their "character twin" has earned it.
- **Post-Keeper quest branch:** stock continues to the Shadowman/ending phase only when `players.size === 4`. The branch now accepts 4–8 while preserving the stock Keeper states and ending coroutine.
- **Ending exits:** the ending IGC directly names four exit structs by player number. Players 5–8 reuse valid exits with a small offset.

Rituals, relics and pod teleporters are per-character and tolerate duplicates sharing progress (both index-twins can interact with the same stations).

Shadows of Evil has no manual command classified as a strict 5–8-player compatibility bypass; its player-count fixes are automatic.

| Command | Effect |
|---|---|
| `zm8_soe_eecomplete` | **Testing cheat:** force the ritual flags (`ritual_all_characters_complete`, `ritual_pap_complete`) and hand out upgraded swords — the keeper/boss phase then starts on its own |
| `zm8_soe_swords [1\|2]` | **Testing cheat:** give every living player their character's Apothicon sword (`1` = base, `2` = upgraded, default upgraded) |
| `zm8_soe_servant` | **Testing cheat:** give every living player the upgraded Apothicon Servant (variant matches their character) |

### Zetsubou No Shima automatic fixes (`zm_island`)

Zetsubou contains several stock arrays and physical slots sized only for 1–4 players. zm8 fixes all of these **automatically**:

- **Challenge assignment:** the three challenge pools run out after 5/6/5 assignments. Players 5–8 may receive repeated challenges after a pool is exhausted and use their modulo-4 physical challenge board while keeping independent progress.
- **All-challenges quest gate:** stock compares completed players against every connected entity. The electrical-shield/zipline step now requires every living participant to finish all three assigned challenges, excluding spectators.
- **Pack-a-Punch valve defense:** its enemy-limit table ends at four players. Teams of 5–8 use the stock four-player limit.
- **Four Skull of Nan Sapwe rituals:** their zombie, spider and Thrasher balance tables end at four players. Teams of 5–8 use four-player pacing.
- **Final Skull room:** both enemy-balance tables end at four players. Teams of 5–8 use four-player pacing.
- **Takeo boss waves:** the boss arena's three wave tables end at four players. Teams of 5–8 use four-player pacing.
- **Boss rescue teleport:** stock has only four landing destinations. Players 5–8 receive nearby offset destinations instead of overlapping their character twins.

These are strictly **5–8-player compatibility fixes**, not cheats: they prevent undefined array reads and slot collisions while leaving normal gameplay intact. Zetsubou's optional `zm8_test` scenarios are separately labeled testing cheats.

### Moon commands (`zm8_moon_*`)

Best audit result of any map: **Moon has no 5–8-player compatibility gates at all.** The Area 51 teleporter counts only alive non-spectators on both legs, the Richtofen easter egg is proximity/interaction driven, and there are no per-player-count scaling tables. Nothing is fixed because nothing breaks — every Moon command is a testing cheat.

Cosmetic quirks with 5–8 (documented, not fixed): the Pack-a-Punch zombie-distraction POI activates only when every **connected** player stands in the enclosure, so a spectator disables the distraction (PaP itself keeps working); helmet visuals are keyed to character index 0–3, so index twins share them. The command-only Moon helper can grant the Hacker through the stock equipment API and advance stock sidequest stages for testing; it makes no automatic gameplay change.

| Command | Effect |
|---|---|
| `zm8_moon_wavegun` | **Testing cheat:** give every living player the upgraded Zap Guns / Wave Gun with full ammo |
| `zm8_moon_qed` | **Testing cheat:** give every living player QEDs (quantum entanglement devices) |

### Revelations commands (`zm8_rev_*`)

Revelations has several automatic fixes:

- Both boss-arena start paths directly index four `dark_arena_teleport_hijack` structs. The stored array is padded to eight, with offset arrivals for the second group.
- The Old School side egg directly indexes a 1–4-player delay array. Slots 5–8 use the stock four-player delay.
- Round 5/10/15/20 time trials have no 5–8-player cases. Larger teams use four-player thresholds.
- Each trial category contains six assignments. Players 7–8 now receive repeated real trials after exhaustion. Players 5–8 can progress them, but the four physical single-owner reward boards are intentionally not shared; the console prints that limitation.

The main boss-rift gate itself counts only *active* players and needs no bypass. Every `zm8_rev_*` command remains a testing cheat.

One thing to know with 5–8 (documented, no fix needed): the rift into the boss arena opens when every **living** player stands within a small radius of the rune portal at once — stack tightly on it.

| Command | Effect |
|---|---|
| `zm8_rev_eecomplete` | **Testing cheat:** force the main quest flags through Kronorium placement (character stones, shards, audio reels, toys, book). The keeper rune trial and the stack-on-the-portal rift entry remain manual |
| `zm8_rev_thundergun` | **Testing cheat:** give every living player the upgraded Thundergun with full ammo |
| `zm8_rev_servant` | **Testing cheat:** give every living player the upgraded Apothicon Servant |

### Shangri-La commands (`zm8_shang_*`) and automatic fix

**Automatic 5–8-player compatibility fix** (in `custom_scripts\zm_temple\zm8_temple.gsc`, which loads only on this map): stock Pack-a-Punch demands one pressure plate per **connected** player, but the map has exactly 4 plates — with a 5th player connected (or any spectator, even at 2–4 players) PaP is permanently unreachable. zm8 detours the plate loop to require one plate per **living** player, capped at the 4 physical plates. No command needed — 5–8 player games press the plates exactly like a full 4-player game.

The easter egg itself has no player-count gates. Two steps wait for **all** players to leave the anti-115/dynamite wall area; spectators follow living players, so simply walking away together resolves them.

| Command | Effect |
|---|---|
| `zm8_shang_shrinkray` | **Testing cheat:** give every living player the upgraded 31-79 JGb215 shrink ray with full ammo |

### Verrückt

Audited — **needs nothing**. No quest, no map-specific wonder weapon, no per-player-count tables. The split spawn (two per side) safely falls back for players 5–8: they spawn on the first point of one side. The global zm8 systems (8-cap, character fallback, gums) cover the whole map, so there are no `zm8_asylum_*` commands.

### Ascension automatic fixes (`zm_cosmodrome`)

Three co-op assumptions are repaired automatically by `custom_scripts\zm_cosmodrome\zm8_cosmodrome.gsc`:

- **Lunar lander:** the vehicle has only four physical rider anchors. Stock code writes through anchor index `-1` when a fifth player boards and can script-error. A normal trip now takes at most four players; players 5–8 remain safely at the station and take the next trip. The mandatory opening cinematic carries everybody by sharing the four cinematic anchors.
- **Matryoshka-doll VO:** the side egg's response switch only handles player indices 0–3. Players 5–8 now reuse the corresponding modulo-four voice so an undefined sound alias cannot abort the interaction.
- **Main-quest pressure timer:** every living participant must remain on the real pressure plate for the full stock timer, but waiting spectators are excluded.

These are automatic **5–8-player compatibility fixes**, not cheats. Ascension's `zm8_test` scenarios are optional testing-only setup paths.

### The Giant automatic fix (`zm_factory`)

The mainframe teleporter's stock staging loop only examines players 1–4. `custom_scripts\zm_factory\zm8_factory.gsc` includes every player standing on the pad and safely shares the four physical staging/arrival spots, with a small offset for players 5–8. This is an automatic **5–8-player compatibility fix**, not a cheat. `zm8_test teleporter` invokes that path directly for testing.

### Kino der Toten automatic fix (`zm_theater`)

Kino's teleporter has four physical staging and destination spots, but stock code directly indexes that four-entry array with the player number. Player 5 therefore reads past the end and can abort the teleport. `custom_scripts\zm_theater\zm8_theater.gsc` folds players 5–8 onto the four valid slots and gives the second group a nearby offset at both ends. This is an automatic **5–8-player compatibility fix**, not a cheat. `zm8_test teleporter` runs the trip and return directly.

### Shi No Numa automatic fix (`zm_sumpf`)

Shi No Numa has two automatic fixes in `custom_scripts\zm_sumpf\zm8_sumpf.gsc`: its opening placement directly indexes only four authored spawn structs, so players 5–8 reuse them with nearby offsets; its zipline has four attachment tags, so each trip carries at most four riders and the rest take the next trip. `zm8_test spawn` and `zm8_test zipline` isolate those paths.

### Nacht der Untoten

Audited — **needs nothing**. Nacht has no map transport, quest, player-count balance table or fixed player-slot array. The global zm8 systems cover the map, so there are no `zm8_prototype_*` commands.

## Known limitations

- The left-edge points HUD is extended to 8 rows: players 5–8 continue above the three stock teammate rows without covering the local player's points. Missing clients-4–7 color dvars are supplied by the lobby Lua. The TAB scoreboard supports 18 rows stock
- Long-session `ScrVar_ReleaseValue` access violations are native VM failures. The stability cap reduces the most likely 5–8-player pressure source but is a mitigation, not proof that every engine-side lifetime bug is eliminated
- Players 5–8 reuse the map's 4 character models/voices
- Gorod Krovi and Revelations have only four physical, single-owner challenge reward boards. Players 5–8 receive/progress trials without an unsafe shared reward pickup; the limitation is logged
- Splitscreen remains 2 players max (engine limit)
- **Do not exceed 8 players** — beyond 8 the engine times everyone out
- Classic mode past 4 players was never QA'd by Treyarch; expect occasional weirdness

The full stock-source finding matrix and exact morning test procedures are in [`MAP_AUDIT_TEST_PLAN.md`](MAP_AUDIT_TEST_PLAN.md).

## Credits

Research references: [BO3-18-Player-Zombies](https://github.com/olie304/BO3-18-Player-Zombies) (prior art on the player-cap override), [zeroy99/bo3_modtools](https://github.com/zeroy99/bo3_modtools) (stock script source), [shiversoftdev/t7-source](https://github.com/shiversoftdev/t7-source) (decompiled GobbleGum scripts), and the BOIII client's GSC scripting docs.
