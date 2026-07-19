================================================================
 zm8 - 8-Player Zombies Mod for Black Ops III (BOIII client)
================================================================

Play Call of Duty: Black Ops III zombies with up to 8 players on
EVERY map - stock and DLC (Der Eisendrache, The Giant, Origins...).
No mod menu, no workshop subscription. Works on the BOIII ("EZZ")
client.

FEATURES
--------
- Up to 8 players in classic zombies on all stock + DLC maps
- Zombie counter (top left): zombies left to spawn + currently alive
- GobbleGums for players 5-8 (the game normally gives them none):
  they get a shared pack you choose with the included gum picker
- Optional permanent all-perks for everyone (host toggle)
- Carpenter power-up removed from the drop pool (crash prevention)

IMPORTANT: ONLY THE HOST NEEDS THIS MOD.
Friends joining your game install nothing - they just need the same
BOIII client and join via the server browser or direct connect.


INSTALLATION
------------
1. Find your Black Ops III game folder - the one that contains
   boiii.exe (e.g. C:\Games\Call of Duty Black Ops III\).

2. Extract EVERYTHING in this zip into that folder, keeping the
   folder structure. Merge folders if asked. You should end up with:

      <your BO3 folder>\boiii\custom_scripts\zm\zm8.gsc
      <your BO3 folder>\boiii\data\ui_scripts\zm_8player\__init__.lua
      <your BO3 folder>\launch-zm8.bat
      <your BO3 folder>\zm8-gum-picker.bat
      <your BO3 folder>\zm8-gum-picker.ps1

3. That's it. No files are replaced - the mod only adds new ones.


HOW TO PLAY (HOST)
------------------
1. Start the game with launch-zm8.bat (NOT boiii.exe directly).
   Why: the client deletes extra UI files on every start; the bat
   re-installs the 8-player lobby patch after startup. If you forget,
   the mod still works - only the lobby will claim "4 Max" (fix: run
   the bat again, or console: set party_maxplayers 8)

2. In-game: ZOMBIES -> PRIVATE GAME -> pick any map.

3. IMPORTANT: open CONFIGURE GAME RANKING and set the match to
   NON-RANKED. The client only allows custom scripts in non-ranked
   games. (Trade-off: no XP/stat progression while modded.)

4. Start the game. About 6 seconds in you'll see:
      "zm8 mod loaded - 8 player cap active"
   and the zombie counter appears top-left. If you don't see these,
   the match is probably still ranked.

5. Friends join through the SERVER BROWSER or direct connect
   (console: connect <your-ip>). Up to 8 total.


GOBBLEGUMS FOR PLAYERS 5-8
--------------------------
The game only stores gum loadouts for 4 players. Players 5-8 get a
shared pack instead, which you choose:

- Double-click zm8-gum-picker.bat -> pick up to 5 gums from the
  dropdowns (type to filter, e.g. "per" finds Perkaholic) -> Save.
- The gum list per map is refreshed every time you play that map
  (file: boiii\scriptdata\zm8\available_gums.txt).
- Gums marked (mega) are experimental - if one misbehaves, remove it.
- No pack saved? Players 5-8 get a default classic pack.

You can also edit boiii\scriptdata\zm8\gum_pack.txt by hand: one gum
per line, friendly names like "in plain sight" work.


HOST CONSOLE COMMANDS (~ key)
-----------------------------
COMMAND CATEGORIES
  [COMPATIBILITY] Only releases a stock all-player gate that is
                  impossible or unsafe above 4 players. Use only
                  after legitimately reaching that gate.
  [TESTING CHEAT] Grants equipment, power, doors, or quest progress
                  without completing the normal objective.
  [HOST UTILITY]  Manages joining/spawning, not an EE limit.

The ONLY strict 5-8 player compatibility commands are:
  zm8_de_bossfight  - DE's 4-pad boss gate
  zm8_gk_arena      - GK's all-player sewer gate (manual fallback)
All item grants, quest skips, generator/KOTH completion, and test
setup commands are cheats. Most 5-8 player fixes run automatically.

[TESTING CHEAT] zm8_allperks
                    toggle permanent all-perks for everyone
                    (default: OFF each game)
[TESTING CHEAT] zm8_allperks 1 / 0
                    explicitly on / off
[HOST UTILITY] zm8_spawn
                    spawn in everyone waiting in spectate right now
                    (mid-round joiners AND bled-out players - works
                    as an early revive for the dead)
[HOST UTILITY] zm8_autospawn
                    toggle auto-spawn: mid-round joiners spawn in
                    within ~3s instead of waiting for next round.
                    Bled-out players still wait (death keeps its
                    penalty) - use zm8_spawn to bring them back early.
                    (default: ON each game)
[HOST UTILITY] zm8_autospawn 1 / 0
                    explicitly on / off
[TESTING CHEAT] zm8_gum <name>
                    give the host any GobbleGum instantly,
                    e.g. zm8_gum shopping free. Names as in
                    zm8/available_gums.txt.
Toggles reset to these defaults every new game. Turning allperks off
mid-game keeps perks people already have; they lose them normally on
downs.

DER EISENDRACHE COMMANDS (zm8_de_*)
-----------------------------------
Map-specific commands carry a map prefix and no-op on other maps.
Upgraded-bow pedestals automatically stay reusable for players 5-8;
no command is required for duplicate bow pickups.

[COMPATIBILITY] zm8_de_bossfight
                    release the final boss-pad gate. The stock
                    ritual (everyone plants their DG-4 on the 4 pads
                    at once) can never finish with 5+ players
                    connected - the game wants one pad per connected
                    player but the map only has 4. Get everyone into
                    the undercroft first, then run this.
[TESTING CHEAT] zm8_de_test
                    force-purchase every door/debris blocker, turn
                    on power, and enable damage immunity. Use
                    zm8_de_test 0 to remove immunity only.
[TESTING CHEAT] zm8_de_eecomplete
                    skip the entire main quest
                    straight to boss-ready. The pyramid rises in the
                    undercroft and its canister step is auto-pressed;
                    once "boss gate arming" shows, zm8_de_bossfight
                    will work. Skipped quest flags stay unset, so the
                    ending cinematic may not play after the boss dies.
[TESTING CHEAT] zm8_de_bows [elem]
                    give every living player an upgraded bow
                    with full ammo. Element: fire, void, storm or
                    wolf; no arg = mix of all four.
[TESTING CHEAT] zm8_de_lightningready
                    fill all 3 dragons and drive the stock Lightning
                    Bow quest until the upgrade is on its altar.
[TESTING CHEAT] zm8_de_ragnarok
                    give every living player the Ragnarok
                    DG-4 (needed for the boss pads).

ORIGINS COMMANDS (zm8_origins_*)
--------------------------------
No hard player-count block in the Origins quest (gates count staffs,
not players), but step 6 (One-Inch Punch) requires EVERY connected
player - spectators included - to earn the upgraded fist.
Duplicate staff pickups are automatic. Origins has NO command that
is classified as a strict 5-8 player compatibility bypass.

[TESTING CHEAT] zm8_origins_generators
                    activate and power all 6 generators.
[TESTING CHEAT] zm8_origins_eecomplete
                    activate generators and force all main-quest
                    gates through the final portal step.
[TESTING CHEAT] zm8_origins_eenext
                    force-complete the current main
                    quest step via the game's own sidequest API. Run
                    repeatedly to walk the quest forward. Before the
                    quest starts it skips the all-staffs-crafted
                    gate (all 6 generators must still be captured).
                    Skipped steps may leave quest props missing.
[TESTING CHEAT] zm8_origins_punch
                    give every living player the upgraded
                    One-Inch Punch and satisfy the step-6 gate.
[TESTING CHEAT] zm8_origins_staffs [element]
                    give every living player an upgraded
                    staff with full ammo. Element: fire, ice, wind
                    or lightning; no arg = mix. With 5+ players some
                    staffs are duplicates - holder UI may confuse,
                    combat works fine.


GOROD KROVI COMMANDS (zm8_gk_*) AND AUTOMATIC FIXES
---------------------------------------------------
Three things break outright with 5-8 players; zm8 fixes them
automatically (no command needed):
- Dragon ride: only 4 passenger positions exist and a 5th boarder
  crashes the script. zm8 departs the ride "full" at 4 riders;
  everyone else catches the next flight.
- Boss fight scaling: the final fight reads zombie tables sized for
  1-4 players. zm8 pads them (5-8 players get 4-player pacing).
- Boss arena teleport: fight start teleports each active player to
  one of 4 landing spots. zm8 clones them up to 8.
Two easter-egg gates count EVERY connected player (spectators too)
and are auto-credited for players not in play: the network-console
(KOTH) defense and the sewer ride into the boss arena.

[COMPATIBILITY] zm8_gk_arena
                    manually release the all-connected-player sewer
                    gate if automatic recovery fails. Use only after
                    every active player rides; stragglers miss it.
[TESTING CHEAT] zm8_gk_eecomplete
                    force the "Love and War" quest
                    flags in order up to the boss phase. Wait for
                    Sophia to leave the computer, then everyone
                    rides the sewer hatch into the arena. Skipped
                    steps stay skipped - the ending cinematic may
                    not play.
[TESTING CHEAT] zm8_gk_koth
                    credit ALL players for the network-console step;
                    this completes the objective and is a cheat.
[TESTING CHEAT] zm8_gk_weapons [kind]
                    give every living player a wonder weapon.
                    fire = GKZ-45 Mk3 (default), strike = Dragon
                    Strike, gauntlet = Gauntlet of Siegfried,
                    shield = dragon shield (experimental).
[TESTING CHEAT] zm8_gk_gauntlet
                    skip the gauntlet incubation quest + give it.


SHADOWS OF EVIL COMMANDS (zm8_soe_*) AND AUTOMATIC FIXES
--------------------------------------------------------
Fixed automatically (no command needed):
- Round spawner crash: the zombie spawn-delay formula only covers
  1-4 players and script-errors with a 5th player. zm8 swaps in a
  clamped copy (5-8 get 4-player pacing).
- Sword gate: the keeper phase (ee_begin) waits until EVERY active
  player holds their character's upgraded Apothicon sword, but sword
  progress is per character - players 5-8 share a character and can
  never earn their own. zm8 hands a duplicate the sword once their
  "character twin" earned it.
Rituals/relics/teleporters are per-character and tolerate index
twins sharing progress.
All Shadows commands are testing cheats; its 5-8 player fixes are
automatic and require no manual compatibility command.

[TESTING CHEAT] zm8_soe_eecomplete
                    force the ritual flags and hand
                    out upgraded swords - the keeper/boss phase then
                    starts on its own.
[TESTING CHEAT] zm8_soe_swords [1|2]
                    give every living player their character's
                    Apothicon sword (1 = base, 2 = upgraded/default).
[TESTING CHEAT] zm8_soe_servant
                    give every living player the upgraded
                    Apothicon Servant (variant matches character).

MOON COMMANDS (zm8_moon_*)
--------------------------
Best audit result of any map: Moon has NO 5-8 player compatibility
gates. The Area 51 teleporter counts only alive non-spectators, the
easter egg is proximity/interaction driven, and there are no
per-player-count scaling tables. Nothing is fixed because nothing
breaks - every Moon command is a testing cheat.
Cosmetic with 5-8: the PaP zombie-distraction POI needs every
CONNECTED player inside the enclosure (a spectator disables the
distraction; PaP itself works), and helmet visuals are shared by
character-index twins. The hacker has no give command (equipment
system is map-wired) - grab it in the labs normally.

[TESTING CHEAT] zm8_moon_wavegun
                    give every living player the upgraded Zap Guns /
                    Wave Gun with full ammo.
[TESTING CHEAT] zm8_moon_qed
                    give every living player QEDs.


KNOWN LIMITATIONS
-----------------
- Scoreboard/HUD is built for 4 players; extra players may not show
  on some screens. Gameplay is unaffected.
- Players 5-8 reuse the map's 4 character models/voices (duplicates).
- Splitscreen is still 2 players max (engine limit).
- More than 8 total players is NOT supported - the engine tolerates
  8 (Treyarch's own Grief mode uses 8), beyond that games time out.
- Stability with 5-8 players is community territory - Treyarch never
  QA'd classic mode beyond 4. Expect occasional weirdness.

UNINSTALL
---------
Delete the files listed in step 2 of installation.

Have fun!
