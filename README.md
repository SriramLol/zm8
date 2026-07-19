# zm8 — 8-Player Zombies for Black Ops III

Play **Call of Duty: Black Ops III zombies with up to 8 players** on every map — stock and DLC (Der Eisendrache, The Giant, Origins, ...). No mod menu, no workshop subscription. Built for the BOIII ("EZZ") client.

**Only the host needs this mod.** Friends install nothing — they join through the server browser or direct connect.

## Features

- Up to 8 players in classic zombies on all stock + DLC maps
- Zombie counter HUD (top left): zombies left to spawn + currently alive
- GobbleGums for players 5–8 — the game normally gives them none; they get a shared pack you pick with the included dropdown gum picker (type-to-filter)
- Optional **permanent all-perks** for everyone (host console toggle, persists between games)
- Carpenter power-up removed from the drop pool (crash prevention)

## How it works

The 4-player limit in classic zombies is script-enforced, not an engine limit — `_zm.gsc` ends the game when a 5th player is detected, but allows 8 for Treyarch's own Grief mode, meaning the engine officially supports 8 zombies clients. This mod re-caps that check at 8 via the BOIII client's `detour` feature, fixes character assignment for slots 5–8, and swaps in GobbleGum packs for players the engine gives none (their loadout data only exists for 4 slots). Everything runs host-side in GSC; effects reach joiners through normal game networking.

## Installation

1. Find your Black Ops III game folder — the one containing `boiii.exe`.
2. Copy the contents of this repo (or the release zip) into it, keeping the folder structure:
   ```
   <BO3 folder>\boiii\custom_scripts\zm\zm8.gsc
   <BO3 folder>\boiii\data\ui_scripts\zm_8player\__init__.lua
   <BO3 folder>\launch-zm8.bat
   <BO3 folder>\zm8-gum-picker.bat
   <BO3 folder>\zm8-gum-picker.ps1
   ```
3. Done — nothing is replaced, the mod only adds files.

## Hosting

1. Start the game with **`launch-zm8.bat`** (not `boiii.exe` directly — the client wipes extra UI files at startup; the bat re-installs the 8-slot lobby patch after launch).
2. Zombies → Private Game → any map → **Configure Game Ranking → non-ranked** (custom scripts only load in non-ranked matches).
3. Start. ~6 seconds in you'll see **"zm8 mod loaded - 8 player cap active"** and the zombie counter.
4. Friends join via server browser or `connect <your-ip>` — up to 8 total.

## GobbleGums for players 5–8

Run `zm8-gum-picker.bat` → pick up to 5 gums (type to filter, `per` → Perkaholic) → Save. The per-map gum list refreshes each time you play a map (`boiii\scriptdata\zm8\available_gums.txt`). Gums marked `(mega)` are experimental. No pack saved → default classics. You can also edit `boiii\scriptdata\zm8\gum_pack.txt` by hand — one gum per line, friendly names work.

## Console commands (host, `~`)

| Command | Effect |
|---|---|
| `zm8_allperks` | toggle permanent all-perks for everyone (default: off) |
| `zm8_allperks 1` / `0` | explicitly on / off |
| `zm8_spawn` | spawn in everyone waiting in spectate right now (mid-round joiners AND bled-out players — an early revive) |
| `zm8_autospawn` | toggle auto-spawn: mid-round joiners spawn in within ~3s instead of waiting for the next round (bled-out players still wait, so dying keeps its penalty). Default: on |
| `zm8_autospawn 1` / `0` | explicitly on / off |
| `zm8_gum <name>` | Cheat: give the host any GobbleGum instantly, e.g. `zm8_gum shopping free`. Names as in `zm8/available_gums.txt` |

Toggles reset to their defaults every new game.

### Der Eisendrache commands (`zm8_de_*`)

Map-specific commands carry a map prefix and no-op on other maps. More maps to come.

| Command | Effect |
|---|---|
| `zm8_de_bossfight` | force-start the final boss fight. The stock start ritual (everyone plants Ragnarok DG-4s on the 4 pads at once) can never complete with 5+ players connected, because the game demands one pad per connected player but the map only has 4. Get everyone to the undercroft first, then run this |
| `zm8_de_eecomplete` | testing cheat: skip the entire main quest straight to boss-ready. The pyramid rises in the undercroft and its canister step is auto-pressed; once "boss gate arming" appears, `zm8_de_bossfight` will work. Skipped quest flags stay unset, so the ending cinematic may not play after the boss dies |
| `zm8_de_bows [element]` | cheat: give every living player an upgraded bow with full ammo. Element: `fire`, `void`, `storm` or `wolf`; no argument = a mix of all four across the team |
| `zm8_de_ragnarok` | cheat: give every living player the Ragnarok DG-4 (needed to plant on the boss pads) |

### Origins commands (`zm8_origins_*`)

Good news from the code audit: unlike Der Eisendrache, the Origins quest has no hard player-count block — every step gate counts staffs/objects (always 4), not players. The one co-op catch: step 6 (One-Inch Punch) requires **every connected player** — spectators included — to earn the upgraded fist.

| Command | Effect |
|---|---|
| `zm8_origins_eenext` | testing cheat: force-complete the current main quest step through the game's own sidequest API. Run it repeatedly to walk the quest forward. Before the quest starts it skips the all-staffs-crafted gate (all 6 generators must still be captured). Skipped steps may leave physical quest props missing, so later steps can look odd |
| `zm8_origins_punch` | cheat: give every living player the upgraded One-Inch Punch and satisfy the step-6 "everyone upgraded" gate |
| `zm8_origins_staffs [element]` | cheat: give every living player an upgraded staff with full ammo. Element: `fire`, `ice`, `wind` or `lightning`; no argument = a mix across the team. With 5+ players some staffs are duplicates — the per-element holder UI may look confused, combat works fine |

### Gorod Krovi commands (`zm8_gk_*`) and automatic fixes

Gorod Krovi needed the most work of any map so far. Three things break outright with 5–8 players, and zm8 fixes them **automatically** — no command needed:

- **Dragon ride**: the dragon only has 4 passenger positions; a 5th boarder crashes the script. zm8 declares the ride full the moment 4 players are aboard — everyone else catches the next flight.
- **Boss fight scaling**: the final fight reads zombie-count tables sized for 1–4 players; with 5+ the lookup errors mid-fight. zm8 pads the tables (5–8 players get 4-player pacing).
- **Boss arena teleport**: the fight start teleports each active player to one of 4 landing spots. zm8 clones them up to 8.

Two easter-egg gates count **every connected player** (spectators included) and are auto-credited for players who are not in play: the network-console (KOTH) defense and the sewer ride into the boss arena.

| Command | Effect |
|---|---|
| `zm8_gk_eecomplete` | testing cheat: force the "Love and War" quest flags in order up to the boss phase. Wait for Sophia to leave the computer, then everyone rides the sewer hatch into the arena. Skipped physical steps stay skipped, so the ending cinematic may not play |
| `zm8_gk_arena` | unstick the boss-arena entry gate manually (it normally auto-credits spectators). Anyone not in the arena when it fires misses the transport |
| `zm8_gk_koth` | credit **all** players for the network-console defense step |
| `zm8_gk_weapons [kind]` | cheat: give every living player a wonder weapon — `fire` (GKZ-45 Mk3, default), `strike` (Dragon Strike), `gauntlet` (Gauntlet of Siegfried), `shield` (dragon shield; experimental) |
| `zm8_gk_gauntlet` | skip the Gauntlet of Siegfried incubation quest and hand the gauntlet out |

### Shadows of Evil commands (`zm8_soe_*`) and automatic fixes

Two things are fixed **automatically** — no command needed:

- **Round spawner crash**: the map's zombie spawn-delay formula only covers 1–4 players and script-errors with a 5th player in the game. zm8 swaps in a clamped copy (5–8 get 4-player pacing).
- **Sword gate**: the main quest's keeper phase (`ee_begin`) waits until **every active player** holds their character's upgraded Apothicon sword, but sword progress is tracked per character — players 5–8 share a character with someone else and can never earn their own. zm8 auto-hands a duplicate the sword once their "character twin" has earned it.

Rituals, relics and pod teleporters are per-character and tolerate duplicates sharing progress (both index-twins can interact with the same stations).

| Command | Effect |
|---|---|
| `zm8_soe_eecomplete` | testing cheat: force the ritual flags (`ritual_all_characters_complete`, `ritual_pap_complete`) and hand out upgraded swords — the keeper/boss phase then starts on its own |
| `zm8_soe_swords [1\|2]` | cheat: give every living player their character's Apothicon sword (`1` = base, `2` = upgraded, default upgraded) |
| `zm8_soe_servant` | cheat: give every living player the upgraded Apothicon Servant (variant matches their character) |

## Known limitations

- Scoreboard/HUD is built for 4 players; extras may not show on some screens (gameplay unaffected)
- Players 5–8 reuse the map's 4 character models/voices
- Splitscreen remains 2 players max (engine limit)
- **Do not exceed 8 players** — beyond 8 the engine times everyone out
- Classic mode past 4 players was never QA'd by Treyarch; expect occasional weirdness

## Credits

Research references: [BO3-18-Player-Zombies](https://github.com/olie304/BO3-18-Player-Zombies) (prior art on the player-cap override), [zeroy99/bo3_modtools](https://github.com/zeroy99/bo3_modtools) (stock script source), [shiversoftdev/t7-source](https://github.com/shiversoftdev/t7-source) (decompiled GobbleGum scripts), and the BOIII client's GSC scripting docs.
