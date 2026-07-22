================================================================
 zm8 - 8-Player Zombies Mod for Black Ops III (BOIII client)
================================================================

Play Call of Duty: Black Ops III zombies with up to 8 players on
EVERY map - stock and DLC (Der Eisendrache, The Giant, Origins...).
No mod menu, no workshop subscription.

This package BUNDLES the BOIII client v1.1.7 (boiii.exe) and pins it
there - the included launcher runs it with -noupdate so it never
auto-updates to a newer build that breaks the mod. You still need
your own working Black Ops III + BOIII install to drop these files
into (the game itself is not included).

FEATURES
--------
- Up to 8 players in classic zombies on all stock + DLC maps
- Zombie counter (top left): zombies left to spawn + currently alive
- GobbleGums for players 5-8 (the game normally gives them none):
  they get a shared pack you choose with the included gum picker
- Optional permanent all-perks for everyone (host toggle)
- Carpenter power-up removed from the drop pool (crash prevention)
- Server client slots forced to 8 every game (com_maxclients /
  party_maxplayers) - without this the listen server can keep the
  stock 4 slots and refuse the 5th connection outright

IMPORTANT: ONLY THE HOST NEEDS THIS MOD.
Friends joining your game install nothing - they just need the same
BOIII client and join via the server browser or direct connect.

ENGINE STABILITY NOTE: BO3's native pools are fixed at 130,000 server
ScrVars, 65,000 client ScrVars and 2,048 game entities. GSC cannot
enlarge them. Long-session 8-player stability remains under investigation;
the stock 24-zombies-alive limit is unchanged.

EZZ v1.1.7 NOTE: zm8 uses the restored unqualified custom-builtin syntax.
Its command poll calls getcommand("") with an explicit empty filter to avoid
the client's broken zero-real-argument dispatcher path during map startup.


VERSION & UPDATES (WHY THIS PINS v1.1.7)
----------------------------------------
The BOIII client auto-updates on launch: it pulls a file manifest from
its update server and re-downloads anything - INCLUDING boiii.exe itself
- that doesn't match the current "latest" build, then relaunches. It has
NO per-version option (the only switch is latest-vs-beta), so you cannot
ask the server for an older build. Newer builds change the client in ways
that break this mod, and 1.1.10 was broken outright for us.

The fix is the client's -noupdate launch flag, which makes the updater
return before it ever contacts the server. So this package:
  * ships a known-good boiii.exe v1.1.7 (the official v1.1.7 release
    binary, sha256 afc842482c14010c2225e61fe796536a632a4ad330952aa362
    84ae292eac2134), and
  * launches it via launch-zm8.bat with -noupdate.

-noupdate also stops the client's startup purge of %LOCALAPPDATA%\boiii
(that purge lives inside the updater), so the mod files under boiii\ are
left untouched.

THE PIN LIVES ENTIRELY IN THE LAUNCHER FLAG. If you start boiii.exe
directly, or through the EZZ launcher, without -noupdate, it will update
to the latest build and overwrite the pinned exe - so ALWAYS launch with
the bat.


INSTALLATION
------------
1. Find your Black Ops III game folder - the one that contains
   boiii.exe (e.g. C:\Games\Call of Duty Black Ops III\).

2. Extract EVERYTHING in this zip into that folder, keeping the
   folder structure. Merge folders if asked, and REPLACE boiii.exe
   when prompted (that swap is what pins you to v1.1.7). You should
   end up with:

      <your BO3 folder>\boiii.exe                       (v1.1.7)
      <your BO3 folder>\boiii\custom_scripts\zm\zm8.gsc
      <your BO3 folder>\boiii\custom_scripts\zm_castle\zm8_castle.gsc
      <your BO3 folder>\boiii\custom_scripts\zm_cosmodrome\zm8_cosmodrome.gsc
      <your BO3 folder>\boiii\custom_scripts\zm_factory\zm8_factory.gsc
      <your BO3 folder>\boiii\custom_scripts\zm_genesis\zm8_genesis.gsc
      <your BO3 folder>\boiii\custom_scripts\zm_island\zm8_island.gsc
      <your BO3 folder>\boiii\custom_scripts\zm_moon\zm8_moon.gsc
      <your BO3 folder>\boiii\custom_scripts\zm_stalingrad\zm8_stalingrad.gsc
      <your BO3 folder>\boiii\custom_scripts\zm_sumpf\zm8_sumpf.gsc
      <your BO3 folder>\boiii\custom_scripts\zm_temple\zm8_temple.gsc
      <your BO3 folder>\boiii\custom_scripts\zm_theater\zm8_theater.gsc
      <your BO3 folder>\boiii\custom_scripts\zm_tomb\zm8_tomb.gsc
      <your BO3 folder>\boiii\custom_scripts\zm_zod\zm8_zod.gsc
      <your BO3 folder>\boiii\ui_scripts\zm_8player\__init__.lua
      <your BO3 folder>\launch-zm8.bat
      <your BO3 folder>\zm8-gum-picker.bat
      <your BO3 folder>\zm8-gum-picker.ps1

3. That's it. The only file replaced is boiii.exe (swapped to the
   pinned v1.1.7); everything else is added.

   NOTE: if you don't already have BOIII installed, get it from
   ezz.lol first (that gives you the client + game data hookup),
   then apply this package over it and launch with the bat below.


HOW TO PLAY (HOST)
------------------
1. ALWAYS start the game with launch-zm8.bat (double-click it).
   This is required: the bat passes -noupdate, which keeps you on the
   bundled v1.1.7 and stops the client's startup purge. If you launch
   boiii.exe directly or through the EZZ launcher, it will auto-update
   to the latest build and the mod will stop working. (The bat also
   closes any leftover BO3 process so you never get "already running".)

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

Normal 5-8 player quests need no manual bypass. One recovery command is:
  zm8_gk_arena      - GK's all-player sewer gate (manual fallback)
All item grants, quest skips, generator/KOTH completion, and test
setup commands are cheats. Most 5-8 player fixes run automatically.

[TESTING CHEAT] zm8_allperks
                    toggle permanent all-perks for everyone
                    (default: OFF each game)
[TESTING CHEAT] zm8_allperks 1 / 0
                    explicitly on / off
[TESTING CHEAT] zm8_godmode [1|0]
                    toggle the host's maintained damage immunity,
                    all perks, 2x movement speed, unlimited sprint,
                    ammunition and points. Enabling also opens every
                    registered buyable door, airlock and debris
                    barrier (plus map open-sesame listeners), and
                    gives a Pack-a-Punched KRM-262 with Dead Wire
                    using the host's weapon-kit attachments/camo.
                    Turning it off stops maintenance but keeps opened
                    barriers, granted perks, points and the KRM.
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

COMMAND-FIRST AUDIT HARNESS (zm8_test)
--------------------------------------
All zm8_test scenarios are TESTING CHEATS. They never run automatically.
They put the team at an audited late step so nobody must complete an EE
solo with bots. Start UNRANKED, then run:
  spawnbot 7
  zm8_godmode 1
  zm8_test help

The map-aware scenario lists are:
  Der Eisendrache: bowteam, bows [element], bossready, boss
  Origins: staffs [element], punchprep, punchfinish, portal
  Gorod Krovi: dragon, trials, timer <5|10|15|20|50>, postquest,
               koth, lockbox, lockbox2, sewer, boss
  Shadows: swords [0|1|2], swordtwin, keepers, shadowman, tram, ending
  Zetsubou: challengesprep, challengesfinish, plants, masamune,
            zipline, pap, skull <1-4>, skullfinish <1-4>, skullroom,
            elevator, boss
  Moon: teleporter, hacker, next, stage <ss1|osc|sc|sc2|ss2>, ee,
        wavegun, qed
  Revelations: quest, trials, timer <5|10|15|20>, oldschool, runes,
               arena1, arena2, thundergun, servant
  Shangri-La: pap, next, stage <BaG|bttp|bttp2|DgCWf|LGS|OaFC|PtT|StD>,
               ee, shrinkray
  Ascension: lander, pressure, pressurefast, doll, reward
  The Giant: teleporter
  Shi No Numa: spawn, zipline
  Kino der Toten: teleporter
  Verruckt/Nacht: no late quest state; common spawn/round utilities suffice

See MAP_AUDIT_TEST_PLAN.md for the exact command order, expected results,
spectator variants and what each isolated test does and does not prove.

DER EISENDRACHE COMMANDS (zm8_de_*)
-----------------------------------
Map-specific commands carry a map prefix and no-op on other maps.
Upgraded-bow pedestals automatically stay reusable for players 5-8;
no command is required for duplicate bow pickups.

All four elemental quests support TWO-PLAYER BOW TEAMS: two Lightning,
two Fire, two Void and two Wolf players, covering all eight slots. The
first player who legitimately starts a bow quest becomes its active
runner. A second player presses P at that bow's final soul box/altar in the
main pyramid undercroft: the box where the reforged arrow is placed and
the upgraded bow eventually appears. This dedicated stock-style prompt
does not consume the normal Use/F input. Both
players can simultaneously contribute kills, souls, shots, plates,
urns, bonfires, Fire runes, Void circles/golf shots and Wolf escort/bone
steps. A personal HUD shows ACTIVE, PARTNER or WAITING. One player can
join one team; each bow allows two players.

The shared Lightning wall plates have NO artificial timer. Each teammate
enters the attempt when they hit their first plate. From then until the
fifth shared plate, that participating player touching the ground resets
the whole shared sequence like stock. A teammate who has not hit a plate
yet may wait on the ground.

The final boss ritual still requires real simultaneous Ragnarok plants:
every living participant up to four, and all four physical pads for a
5-8 player team. Spectators no longer make the gate impossible.

The map still has only one stock quest coroutine, owner, arrow and prop
set per bow. Two teammates therefore cannot be on separate steps of the
same bow simultaneously. The active runner remains authoritative only
for unique one-time broken-arrow, reforge, placement and cleanup actions.
Press P at the pyramid soul box/altar again to hand that role to the partner without
losing progress; ordinary shared-stage contributions need no handoff.

[TESTING CHEAT] zm8_de_bossfight
                    force the final boss-pad counter. The legitimate
                    four-pad ritual is fixed automatically; use this
                    only to recover/isolate a failed runtime test.
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
[TESTING CHEAT] zm8_de_lightningstep
                    advance exactly one stock Lightning Bow stage per
                    use. Use it to reach the desired test stage, then
                    split the remaining legitimate targets between the
                    two Lightning teammates to test shared credit.
[TESTING CHEAT] zm8_de_botlightning
                    select the first alive bot; prepare the dragons and
                    start Lightning if needed; transfer the live stock
                    quest to that bot; remove the host from its team.
                    The host can then use the Lightning soul box/altar
                    once to test joining as the bot's partner.
[TESTING CHEAT] zm8_de_ragnarok
                    give every living player the Ragnarok
                    DG-4 (needed for the boss pads).

ORIGINS COMMANDS (zm8_origins_*)
--------------------------------
Object gates count four staffs/placements rather than players.
Duplicate staff pickups are automatic, and repeated holders share the
one physical elemental objective. Step 6 now requires every LIVING
participant to earn the upgraded punch; spectators are excluded.

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
Several things break outright with 5-8 players; zm8 fixes them
automatically (no command needed):
- Dragon ride: only 4 passenger positions exist and a 5th boarder
  crashes the script. zm8 departs the ride "full" at 4 riders;
  everyone else catches the next flight.
- Boss fight scaling: the final fight reads zombie tables sized for
  1-4 players. zm8 pads them (5-8 players get 4-player pacing).
- Boss arena teleport: fight start teleports each active player to
  one of 4 landing spots. zm8 clones them up to 8.
- Challenge pools: player 7 exhausts all three six-entry pools.
  Assignments repeat only after exhaustion. Players 5-8 progress real
  trials, but the four single-owner reward boards are not shared.
- Time trials and the post-quest all-perks threshold have only 1-4
  cases. Teams of 5-8 use stock four-player thresholds.
Four easter-egg gates count EVERY connected player (spectators too)
and auto-credit only players not in play: KOTH, both Dragon Strike
lockbox stages, and the sewer ride into the boss arena.

[COMPATIBILITY] zm8_gk_arena
                    manually release the all-connected-player sewer
                    gate if automatic recovery fails. Use only after
                    every active player rides; stragglers miss it.
[TESTING CHEAT] zm8_gk_eecomplete
                    force the "Love and War" quest
                    flags in order up to the boss phase. Wait for
                    Sophia to leave the computer, then everyone
                    rides the sewer hatch into the arena. The stock
                    arena-start trigger activates automatically once
                    everyone lands. Skipped steps stay skipped - the
                    ending cinematic may not play.
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
- Post-Keeper branch: stock continues only when players.size is
  exactly 4. It now accepts 4-8 while retaining stock sequencing.
- Ending exits: four physical IGC exits are reused with offsets for
  players 5-8.
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

ZETSUBOU NO SHIMA AUTOMATIC FIXES (zm_island)
---------------------------------------------
Zetsubou has several stock arrays and physical slots sized only for
1-4 players. zm8 fixes all of these automatically:
- Challenge assignment: the three pools run out after 5/6/5
  assignments. Players 5-8 may repeat challenges after exhaustion
  and share their modulo-4 physical board, but keep separate progress.
- All-challenges quest gate: every living participant must complete
  all three assigned trials; spectators no longer block the zipline step.
- Pack-a-Punch valve defense: 5-8 use the 4-player enemy limit.
- All four Skull rituals: 5-8 use 4-player zombie/spider/Thrasher
  pacing instead of reading past the stock balance arrays.
- Final Skull room: 5-8 use 4-player enemy pacing.
- Takeo boss waves: 5-8 use 4-player wave pacing.
- Boss rescue teleport: players 5-8 get nearby offset destinations
  instead of overlapping their character twins.
These are strictly 5-8 PLAYER COMPATIBILITY FIXES, not cheats. Normal
play remains unchanged. Zetsubou's optional zm8_test scenarios are
separate testing-only setup cheats.

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
character-index twins. The command-only Moon helper can grant the Hacker
through the stock equipment API and advance stock sidequest stages; it
makes no automatic gameplay change.

[TESTING CHEAT] zm8_moon_wavegun
                    give every living player the upgraded Zap Guns /
                    Wave Gun with full ammo.
[TESTING CHEAT] zm8_moon_qed
                    give every living player QEDs.

REVELATIONS COMMANDS (zm8_rev_*)
--------------------------------
Automatic fixes:
- Both boss-arena paths index four arrival structs; the array is padded
  to eight and the second group receives nearby offsets.
- The Old School side-egg delay and round 5/10/15/20 time trials use
  stock four-player values for teams of 5-8.
- Trial pools exhaust at player 7. Players 7-8 receive repeated real
  trials; players 5-8 progress them, but the four single-owner reward
  boards are intentionally not shared.
The boss-rift gate itself counts only ACTIVE players and needs no bypass.
Every Revelations command is a testing cheat.
Note with 5-8: the rift into the boss arena opens when every LIVING
player stands within a small radius of the rune portal at once -
stack tightly on it.

[TESTING CHEAT] zm8_rev_eecomplete
                    force the main quest flags through Kronorium
                    placement (stones, shards, reels, toys, book).
                    The keeper rune trial and the rift entry stay
                    manual.
[TESTING CHEAT] zm8_rev_thundergun
                    give every living player the upgraded Thundergun.
[TESTING CHEAT] zm8_rev_servant
                    give every living player the upgraded Apothicon
                    Servant.

SHANGRI-LA COMMANDS (zm8_shang_*) AND AUTOMATIC FIX
---------------------------------------------------
AUTOMATIC 5-8 COMPATIBILITY FIX (custom_scripts\zm_temple\
zm8_temple.gsc, loads only on this map): stock Pack-a-Punch demands
one pressure plate per CONNECTED player but the map has exactly 4
plates - unreachable with 5+ connected and blocked by any spectator
even at 2-4 players. zm8 detours the plate loop to require one plate
per LIVING player capped at 4. No command needed: 5-8 player games
press the plates exactly like a full 4-player game.
The easter egg has no player-count gates. Two steps wait for ALL
players to leave the anti-115/dynamite wall area; spectators follow
living players, so walking away together resolves them.

[TESTING CHEAT] zm8_shang_shrinkray
                    give every living player the upgraded 31-79
                    JGb215 shrink ray with full ammo.

VERRUCKT
--------
Audited - needs nothing. No quest, no map wonder weapon, no
per-player-count tables. The split spawn (two per side) safely
falls back for players 5-8 (they spawn on the first point of one
side). The global zm8 systems cover the whole map; there are no
zm8_asylum_* commands.

ASCENSION AUTOMATIC FIXES (zm_cosmodrome)
-----------------------------------------
AUTOMATIC 5-8 COMPATIBILITY FIXES, not cheats:
- The lunar lander has only four physical rider anchors. A normal
  trip now takes at most four players; extras safely take the next
  trip. The mandatory opening cinematic shares the four anchors.
- The Matryoshka-doll side egg now folds player indices 5-8 onto
  the four valid VO sets instead of playing an undefined alias.
- The main quest pressure timer requires every living participant to
  stay on the real plate for the stock duration; spectators are excluded.
Optional zm8_test scenarios isolate the lander, pressure and doll paths.

THE GIANT AUTOMATIC FIX (zm_factory)
------------------------------------
AUTOMATIC 5-8 COMPATIBILITY FIX, not a cheat: the mainframe
teleporter's stock staging loop only examines players 1-4. zm8
includes everyone on the pad and safely shares the four physical
staging/arrival spots, offsetting players 5-8. The rest of the map
has no other player-count gates. zm8_test teleporter invokes this path.

KINO DER TOTEN AUTOMATIC FIX (zm_theater)
-----------------------------------------
AUTOMATIC 5-8 COMPATIBILITY FIX, not a cheat: stock teleporter code
indexes its four spots with the player number, so player 5 reads past
the array. zm8 folds players 5-8 onto valid spots with nearby offsets
at both ends. Kino has no main quest/player-count gate. The testing-only
zm8_test teleporter command runs the trip and return directly.

SHI NO NUMA AUTOMATIC FIX (zm_sumpf)
------------------------------------
AUTOMATIC 5-8 COMPATIBILITY FIXES, not cheats: opening placement
directly indexes four spawn structs, so players 5-8 reuse them with
nearby offsets. The zipline has four attachment tags, so each trip
carries at most four and extras safely take the next/return trip.
zm8_test spawn and zm8_test zipline isolate these paths.

NACHT DER UNTOTEN
-----------------
Audited - needs nothing. No transport, quest, player-count balance
table or fixed player-slot array. The global zm8 systems cover it;
there are no zm8_prototype_* commands.


KNOWN LIMITATIONS
-----------------
- The left-edge points HUD is extended to 8 rows. Players 5-8 continue
  above the stock teammate rows without covering the local player's
  points. Missing clients-4-7 color dvars are supplied by the Lua.
  TAB scoreboard is 18 rows stock.
- Long-session ScrVar_ReleaseValue access violations are native VM
  failures. The stability cap reduces the most likely 5-8-player
  pressure source, but cannot prove every engine lifetime bug is gone.
- Players 5-8 reuse the map's 4 character models/voices (duplicates).
- Gorod and Revelations have only four physical single-owner challenge
  reward boards. Players 5-8 progress trials without an unsafe shared
  pickup; the limitation is printed to the console.
- Splitscreen is still 2 players max (engine limit).
- More than 8 total players is NOT supported - the engine tolerates
  8 (Treyarch's own Grief mode uses 8), beyond that games time out.
- Stability with 5-8 players is community territory - Treyarch never
  QA'd classic mode beyond 4. Expect occasional weirdness.

See MAP_AUDIT_TEST_PLAN.md for the stock-source finding matrix and exact
morning test procedures.

UNINSTALL
---------
Delete the files listed in step 2 of installation.

Have fun!
