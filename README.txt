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
zm8_allperks        toggle permanent all-perks for everyone
                    (default: OFF each game)
zm8_allperks 1 / 0  explicitly on / off
zm8_spawn           spawn in everyone waiting in spectate right now
                    (mid-round joiners AND bled-out players - works
                    as an early revive for the dead)
zm8_autospawn       toggle auto-spawn: mid-round joiners spawn in
                    within ~3s instead of waiting for next round.
                    Bled-out players still wait (death keeps its
                    penalty) - use zm8_spawn to bring them back early.
                    (default: ON each game)
zm8_autospawn 1 / 0 explicitly on / off
zm8_bossfight       Der Eisendrache only: force-start the final
                    boss fight. The stock ritual (everyone plants
                    their DG-4 on the 4 pads at once) can never
                    finish with 5+ players connected - the game
                    wants one pad per connected player but the map
                    only has 4. Get everyone into the undercroft
                    first, then run this.
zm8_eecomplete      Der Eisendrache only, TESTING CHEAT: skip the
                    entire main quest straight to boss-ready (the
                    pyramid rises in the undercroft). Follow with
                    zm8_bossfight to start the fight. Skipped quest
                    flags stay unset, so the ending cinematic may
                    not play after the boss dies.
Toggles reset to these defaults every new game. Turning allperks off
mid-game keeps perks people already have; they lose them normally on
downs.


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
