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
   <BO3 folder>\boiii\custom_scripts\zm_island\zm8_island.gsc
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

### Command categories

- **5–8-player compatibility** means the command only releases a stock all-player gate that is impossible or unsafe above four players. Use it only after the team legitimately reaches that gate. These commands do not grant free equipment or skip the rest of the quest.
- **Testing cheat** means the command grants equipment, power or quest progress without completing the normal objective. Cheats are optional testing tools; they are not required for normal 5–8-player play.
- **Host utility** means player/session management rather than an Easter-egg bypass. `zm8_spawn` can still act as a cheat when used to revive a bled-out player early.

The only manual commands currently classified as strict 5–8-player compatibility bypasses are:

- `zm8_de_bossfight` — releases Der Eisendrache's four-Ragnarok-pad gate for a 5–8-player team already at the boss entrance.
- `zm8_gk_arena` — releases Gorod Krovi's all-connected-players sewer gate if its automatic recovery fails after all active players enter.

**Every equipment-grant, door/power setup, generator activation, KOTH completion and quest-skip command is a testing cheat.** The core 8-player cap and passive map fixes are automatic and require no command.

| Command | Effect |
|---|---|
| `zm8_allperks` | **Testing cheat:** toggle permanent all-perks for everyone (default: off) |
| `zm8_allperks 1` / `0` | **Testing cheat:** explicitly enable / disable permanent all-perks |
| `zm8_spawn` | **Host utility:** spawn everyone waiting in spectate right now (mid-round joiners and bled-out players). Using it on the latter is an early-revive cheat |
| `zm8_autospawn` | **Host utility:** toggle auto-spawn for mid-round joiners within ~3s; bled-out players remain excluded. Default: on |
| `zm8_autospawn 1` / `0` | **Host utility:** explicitly enable / disable joiner auto-spawn |
| `zm8_gum <name>` | **Testing cheat:** give the host any GobbleGum instantly, e.g. `zm8_gum shopping free`. Names as in `zm8/available_gums.txt` |

Toggles reset to their defaults every new game.

### Der Eisendrache commands (`zm8_de_*`)

Map-specific commands carry a map prefix and no-op on other maps. More maps to come.

Automatic compatibility fix: upgraded-bow pedestals remain reusable so players 5–8 can take duplicate upgraded bows. No command is required for this; each player may hold only one upgraded bow at a time.

| Command | Effect |
|---|---|
| `zm8_de_bossfight` | **5–8-player compatibility:** release the final boss-pad gate after the team legitimately reaches it. Stock demands one simultaneous Ragnarok plant per connected player but provides only four pads, so 5+ players cannot satisfy it. Gather everyone in the undercroft first |
| `zm8_de_test` | **Testing cheat:** force-purchase all buyable doors/debris, turn on power and give current players damage immunity. `zm8_de_test 0` removes immunity; doors and power remain |
| `zm8_de_eecomplete` | **Testing cheat:** skip the entire main quest straight to boss-ready and auto-press the pyramid canister. Skipped quest state may prevent the ending cinematic |
| `zm8_de_bows [element]` | **Testing cheat:** give every living player an upgraded bow with full ammo. Element: `fire`, `void`, `storm` or `wolf`; no argument mixes all four |
| `zm8_de_lightningready` | **Testing cheat:** fill all three dragons and drive the stock Lightning Bow quest until the upgraded bow appears on its altar |
| `zm8_de_ragnarok` | **Testing cheat:** give every living player the Ragnarok DG-4 |

### Origins commands (`zm8_origins_*`)

Good news from the code audit: unlike Der Eisendrache, the Origins quest has no hard player-count block — every step gate counts staffs/objects (always 4), not players. The one co-op catch: step 6 (One-Inch Punch) requires **every connected player** — spectators included — to earn the upgraded fist. Duplicate staff pickups are enabled automatically for players 5–8. Therefore, **Origins has no command classified as a strict 5–8-player compatibility bypass**.

| Command | Effect |
|---|---|
| `zm8_origins_generators` | **Testing cheat:** activate and power all six generators without capturing them normally |
| `zm8_origins_eecomplete` | **Testing cheat:** activate the generators and force every main-quest gate through the final portal step |
| `zm8_origins_eenext` | **Testing cheat:** force-complete the current main-quest stage. Repeated use walks the quest forward and may leave skipped physical props in an unusual state |
| `zm8_origins_punch` | **Testing cheat:** give every living player the upgraded One-Inch Punch and satisfy the all-connected-players step-6 check |
| `zm8_origins_staffs [element]` | **Testing cheat:** give every living player an upgraded staff with full ammo. Element: `fire`, `ice`, `wind` or `lightning`; no argument mixes elements |

### Gorod Krovi commands (`zm8_gk_*`) and automatic fixes

Gorod Krovi needed the most work of any map so far. Three things break outright with 5–8 players, and zm8 fixes them **automatically** — no command needed:

- **Dragon ride**: the dragon only has 4 passenger positions; a 5th boarder crashes the script. zm8 declares the ride full the moment 4 players are aboard — everyone else catches the next flight.
- **Boss fight scaling**: the final fight reads zombie-count tables sized for 1–4 players; with 5+ the lookup errors mid-fight. zm8 pads the tables (5–8 players get 4-player pacing).
- **Boss arena teleport**: the fight start teleports each active player to one of 4 landing spots. zm8 clones them up to 8.

Two easter-egg gates count **every connected player** (spectators included) and are auto-credited for players who are not in play: the network-console (KOTH) defense and the sewer ride into the boss arena.

| Command | Effect |
|---|---|
| `zm8_gk_arena` | **5–8-player compatibility:** manually release the sewer/boss-arena all-connected-players gate if automatic recovery fails. Use only after every active participant has taken the sewer; stragglers miss the transport |
| `zm8_gk_eecomplete` | **Testing cheat:** force the "Love and War" quest flags through the boss phase. Physical objectives are skipped and the ending sequence may not behave normally |
| `zm8_gk_koth` | **Testing cheat:** credit every connected player for the network-console defense. This completes the objective rather than merely increasing its player capacity |
| `zm8_gk_weapons [kind]` | **Testing cheat:** give every living player a wonder weapon — `fire` (GKZ-45 Mk3), `strike` (Dragon Strike), `gauntlet` or experimental `shield` |
| `zm8_gk_gauntlet` | **Testing cheat:** skip the Gauntlet of Siegfried incubation quest and give out the gauntlet |

### Shadows of Evil commands (`zm8_soe_*`) and automatic fixes

Two things are fixed **automatically** — no command needed:

- **Round spawner crash**: the map's zombie spawn-delay formula only covers 1–4 players and script-errors with a 5th player in the game. zm8 swaps in a clamped copy (5–8 get 4-player pacing).
- **Sword gate**: the main quest's keeper phase (`ee_begin`) waits until **every active player** holds their character's upgraded Apothicon sword, but sword progress is tracked per character — players 5–8 share a character with someone else and can never earn their own. zm8 auto-hands a duplicate the sword once their "character twin" has earned it.

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
- **Pack-a-Punch valve defense:** its enemy-limit table ends at four players. Teams of 5–8 use the stock four-player limit.
- **Four Skull of Nan Sapwe rituals:** their zombie, spider and Thrasher balance tables end at four players. Teams of 5–8 use four-player pacing.
- **Final Skull room:** both enemy-balance tables end at four players. Teams of 5–8 use four-player pacing.
- **Takeo boss waves:** the boss arena's three wave tables end at four players. Teams of 5–8 use four-player pacing.
- **Boss rescue teleport:** stock has only four landing destinations. Players 5–8 receive nearby offset destinations instead of overlapping their character twins.

These are strictly **5–8-player compatibility fixes**, not cheats: they prevent undefined array reads and slot collisions while leaving the generators, challenges, Skull quest, main Easter egg and boss fight to be completed normally. Zetsubou currently adds no console commands or quest skips.

### Moon commands (`zm8_moon_*`)

Best audit result of any map: **Moon has no 5–8-player compatibility gates at all.** The Area 51 teleporter counts only alive non-spectators on both legs, the Richtofen easter egg is proximity/interaction driven, and there are no per-player-count scaling tables. Nothing is fixed because nothing breaks — every Moon command is a testing cheat.

Cosmetic quirks with 5–8 (documented, not fixed): the Pack-a-Punch zombie-distraction POI activates only when every **connected** player stands in the enclosure, so a spectator disables the distraction (PaP itself keeps working); helmet visuals are keyed to character index 0–3, so index twins share them. The hacker is wired through the map's equipment system and has no give command — grab it in the labs normally.

| Command | Effect |
|---|---|
| `zm8_moon_wavegun` | **Testing cheat:** give every living player the upgraded Zap Guns / Wave Gun with full ammo |
| `zm8_moon_qed` | **Testing cheat:** give every living player QEDs (quantum entanglement devices) |

### Revelations commands (`zm8_rev_*`)

**Revelations has no 5–8-player compatibility gates.** The boss-arena rift gate counts only *active* players (spectator-safe), the arena teleports share their 4 landing spots across any number of players, and there are no per-player-count scaling tables. Every Revelations command is a testing cheat.

One thing to know with 5–8 (documented, no fix needed): the rift into the boss arena opens when every **living** player stands within a small radius of the rune portal at once — stack tightly on it.

| Command | Effect |
|---|---|
| `zm8_rev_eecomplete` | **Testing cheat:** force the main quest flags through Kronorium placement (character stones, shards, audio reels, toys, book). The keeper rune trial and the stack-on-the-portal rift entry remain manual |
| `zm8_rev_thundergun` | **Testing cheat:** give every living player the upgraded Thundergun with full ammo |
| `zm8_rev_servant` | **Testing cheat:** give every living player the upgraded Apothicon Servant |

## Known limitations

- Scoreboard/HUD is built for 4 players; extras may not show on some screens (gameplay unaffected)
- Players 5–8 reuse the map's 4 character models/voices
- Splitscreen remains 2 players max (engine limit)
- **Do not exceed 8 players** — beyond 8 the engine times everyone out
- Classic mode past 4 players was never QA'd by Treyarch; expect occasional weirdness

## Credits

Research references: [BO3-18-Player-Zombies](https://github.com/olie304/BO3-18-Player-Zombies) (prior art on the player-cap override), [zeroy99/bo3_modtools](https://github.com/zeroy99/bo3_modtools) (stock script source), [shiversoftdev/t7-source](https://github.com/shiversoftdev/t7-source) (decompiled GobbleGum scripts), and the BOIII client's GSC scripting docs.
