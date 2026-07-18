// zm8 mod - 8-player zombies on all maps (stock + DLC) + zombie counter
// boiii-free custom script (auto-compiled by the client, zombies mode only)
//
// Stock scripts\zm\_zm.gsc ends the game when GetPlayers().size > 4 in classic
// modes (8 allowed for grief). The engine supports 8 zm clients, so re-cap the
// check at 8 instead of removing it.

detour scripts\zm\_zm::player_too_many_players_check()
{
    if (getplayers().size > 8)
    {
        zm8_announce("^1zm8: more than 8 players - ending game");
        level notify("end_game");
    }
}

// iprintln goes to a notify feed the zombies HUD doesn't render on this
// client (console-only), so announce center-screen instead
function zm8_announce(msg)
{
    iprintlnbold(msg);
    println(msg);
}

autoexec function zm8_init()
{
    level endon("end_game");

    // guard against the same script being loaded from more than one folder
    if (isdefined(level.zm8_loaded))
    {
        return;
    }
    level.zm8_loaded = true;

    while (getplayers().size == 0)
    {
        wait 0.5;
    }

    // let the intro blackscreen pass so the print is visible
    wait 6;
    zm8_announce("^2zm8 mod loaded - 8 player cap, mid-round auto-spawn on");

    // per-game defaults: all-perks off, auto-spawn on (toggles last one game)
    level.zm8_allperks = false;
    level.zm8_autospawn = true;

    level thread zm8_character_index_fixer();
    level thread zm8_bgb_pack_fixer();
    level thread zm8_allperks_monitor();
    level thread zm8_powerup_pool_fixer();
    level thread zm8_autospawn_monitor();
    level thread zm8_zombie_counter();
}

// carpenter powerups reportedly crash modded 8-player games - keep them out
// of the random drop pool (it persists across the reshuffles the powerup
// system does between cycles, so re-check rather than remove once)
function zm8_powerup_pool_fixer()
{
    level endon("end_game");

    while (true)
    {
        if (isdefined(level.zombie_powerup_array))
        {
            filtered = [];
            removed = false;

            for (i = 0; i < level.zombie_powerup_array.size; i++)
            {
                if (level.zombie_powerup_array[i] == "carpenter")
                {
                    removed = true;
                    continue;
                }

                filtered[filtered.size] = level.zombie_powerup_array[i];
            }

            if (removed)
            {
                level.zombie_powerup_array = filtered;

                // keep the cycle index in bounds after shrinking the pool
                if (isdefined(level.zombie_powerup_index) && level.zombie_powerup_index >= filtered.size)
                {
                    level.zombie_powerup_index = 0;
                }

                println("zm8: removed carpenter from the powerup pool");
            }
        }

        wait 5;
    }
}

// host console commands, any map:
//   zm8_allperks  [0|1]  (no arg = toggle) - permanent all-perks
//   zm8_spawn            - force every waiting spectator to spawn in now
//   zm8_autospawn [0|1]  (no arg = toggle) - auto-spawn mid-round joiners
//   zm8_gum <name>       - cheat: give the host any gum right now
//                          (e.g. zm8_gum shopping free)
//
// Der Eisendrache (zm_castle) - guarded by mapname, no-ops elsewhere:
//   zm8_de_eecomplete     - TEST cheat: skip the whole main quest to
//                           boss-ready (then use zm8_de_bossfight)
//   zm8_de_bossfight      - force-start the final boss fight
//   zm8_de_bows [element] - cheat: give everyone an upgraded bow
//                           (fire/void/storm/wolf; no arg = mix of all four)
//   zm8_de_ragnarok       - cheat: give everyone the Ragnarok DG-4
//
// Origins (zm_tomb) - guarded by mapname, no-ops elsewhere:
//   zm8_origins_eenext    - TEST cheat: force-complete the current main
//                           quest step (at step_0 it skips the staffs-
//                           crafted gate; generators must still be on)
//   zm8_origins_punch     - cheat: give everyone the upgraded One-Inch
//                           Punch; also satisfies the step-6 gate that
//                           needs EVERY connected player upgraded
//   zm8_origins_staffs [element] - cheat: give everyone an upgraded staff
//                           (fire/ice/wind/lightning; no arg = mix)
//
// Map-specific commands use a zm8_<map>_ prefix and live in their own
// section further down; add future maps (soe, moon, ...) the same way.
autoexec function zm8_register_commands()
{
    addcommand("zm8_allperks", &zm8_cmd_allperks);
    addcommand("zm8_spawn", &zm8_cmd_spawn);
    addcommand("zm8_autospawn", &zm8_cmd_autospawn);
    addcommand("zm8_gum", &zm8_cmd_gum);

    // Der Eisendrache
    addcommand("zm8_de_eecomplete", &zm8_de_cmd_eecomplete);
    addcommand("zm8_de_bossfight", &zm8_de_cmd_bossfight);
    addcommand("zm8_de_bows", &zm8_de_cmd_bows);
    addcommand("zm8_de_ragnarok", &zm8_de_cmd_ragnarok);

    // Origins
    addcommand("zm8_origins_eenext", &zm8_origins_cmd_eenext);
    addcommand("zm8_origins_punch", &zm8_origins_cmd_punch);
    addcommand("zm8_origins_staffs", &zm8_origins_cmd_staffs);
}

// Hand the host (player 0 on a listen server) any gum via the stock
// _zm_bgb::give API - same path the machine uses, so HUD and activation
// behave normally. Friendly or internal names both work.
function zm8_cmd_gum(args)
{
    if (!isdefined(args) || args.size < 1)
    {
        zm8_announce("^3zm8: usage: zm8_gum <gum name> - names in zm8/available_gums.txt");
        return;
    }

    raw = args[0];

    for (i = 1; i < args.size; i++)
    {
        raw += " " + args[i];
    }

    gum = zm8_normalize_gum_name(zm8_strip_marker(raw));

    if (!isdefined(level.bgb) || !isdefined(level.bgb[gum]))
    {
        zm8_announce("^1zm8: unknown gum '" + raw + "' - see zm8/available_gums.txt");
        return;
    }

    players = getplayers();

    if (players.size == 0)
    {
        return;
    }

    host = players[0];
    host scripts\zm\_zm_bgb::give(gum);
    zm8_announce("^2zm8: gave " + zm8_friendly_gum_name(gum) + " to " + host.name);
}

// Testing cheat. Setting the "boss_fight_ready" flag is all that launches the
// boss sequence (pyramid rise in the undercroft, then the pad gate that
// zm8_de_bossfight releases) - the fight uses none of the earlier quest state,
// and the keeper AI the real quest spawns is deleted again before this flag
// in a legit run. The one physical leftover is the raised pyramid ramps the
// ceremony normally lowers, so lower them here the same way. Skipped-over
// quest flags stay unset, so the ending cinematic after the boss may not
// play in a skipped run.
function zm8_de_cmd_eecomplete(args)
{
    if (getdvarstring("mapname") != "zm_castle")
    {
        zm8_announce("^1zm8: zm8_de_eecomplete only works on Der Eisendrache");
        return;
    }

    if (!isdefined(level.flag) || !isdefined(level.flag["boss_fight_ready"]))
    {
        zm8_announce("^1zm8: boss fight system not initialized on this map");
        return;
    }

    if (level.flag["boss_fight_ready"])
    {
        zm8_announce("^3zm8: quest is already at boss-ready or beyond");
        return;
    }

    zm8_announce("^2zm8: TEST - skipping quest to boss-ready, watch the undercroft");

    ramps = getentarray("pyramid", "targetname");

    for (i = 0; i < ramps.size; i++)
    {
        ramps[i] notsolid();
        ramps[i] connectpaths();
        ramps[i] moveto(ramps[i].origin - (0, 0, 96), 3);
    }

    // the pyramid-open part of the boss sequence blocks on this time-travel
    // quest flag, then on a use-press at the broken canister on the pyramid
    level scripts\shared\flag_shared::set("mpd_canister_replacement");
    level thread zm8_de_auto_press_canister();

    level scripts\shared\flag_shared::set("boss_fight_ready");
}

// The boss sequence registers a unitrigger on the "canister_2" struct and
// waits for its "trigger_activated" notify before opening the pyramid and
// arming the pad gate. Press it for the team once it appears.
function zm8_de_auto_press_canister()
{
    level endon("end_game");

    s_canister = scripts\codescripts\struct::get("canister_2", "targetname");

    if (!isdefined(s_canister))
    {
        zm8_announce("^1zm8: canister_2 struct not found - press the canister prompt at the pyramid manually");
        return;
    }

    // create_unitrigger stamps .s_unitrigger on the struct when it registers
    for (t = 0; t < 240 && !isdefined(s_canister.s_unitrigger); t++)
    {
        wait 0.5;
    }

    if (!isdefined(s_canister.s_unitrigger))
    {
        zm8_announce("^1zm8: canister never appeared - boss gate may not arm");
        return;
    }

    // a few notifies in case the listener arms a beat after registration
    for (i = 0; i < 5; i++)
    {
        wait 1;
        s_canister notify("trigger_activated", getplayers()[0]);
    }

    zm8_announce("^2zm8: pyramid opening - boss gate arming, zm8_de_bossfight is ready soon");
}

// Give every player an upgraded elemental bow, mirroring the stock upgrade
// handover: take any bow variant they hold, free a weapon slot if full,
// give the upgrade with full ammo.
function zm8_de_cmd_bows(args)
{
    if (getdvarstring("mapname") != "zm_castle")
    {
        zm8_announce("^1zm8: zm8_de_bows only works on Der Eisendrache");
        return;
    }

    elements = [];
    elements[0] = "storm";
    elements[1] = "demongate";
    elements[2] = "wolf_howl";
    elements[3] = "rune_prison";

    forced = undefined;

    if (isdefined(args) && args.size >= 1)
    {
        forced = zm8_de_bow_element_from_name(args[0]);

        if (!isdefined(forced))
        {
            zm8_announce("^1zm8: unknown bow '" + args[0] + "' - use fire, void, storm or wolf");
            return;
        }
    }

    players = getplayers();

    for (i = 0; i < players.size; i++)
    {
        player = players[i];

        if (!isdefined(player) || !isalive(player) || player.sessionstate != "playing")
        {
            continue;
        }

        element = forced;

        if (!isdefined(element))
        {
            element = elements[i % 4];
        }

        player zm8_de_give_bow(element);
    }

    zm8_announce("^2zm8: upgraded bows handed out");
}

function zm8_de_bow_element_from_name(raw)
{
    raw = tolower(raw);

    if (raw == "fire" || raw == "demongate" || raw == "demon")
    {
        return "demongate";
    }

    if (raw == "void" || raw == "rune_prison" || raw == "rune")
    {
        return "rune_prison";
    }

    if (raw == "storm" || raw == "lightning")
    {
        return "storm";
    }

    if (raw == "wolf" || raw == "wolf_howl")
    {
        return "wolf_howl";
    }

    return undefined;
}

function zm8_de_give_bow(element)
{
    variants = [];
    variants[0] = "elemental_bow";
    variants[1] = "elemental_bow_storm";
    variants[2] = "elemental_bow_demongate";
    variants[3] = "elemental_bow_wolf_howl";
    variants[4] = "elemental_bow_rune_prison";

    had_bow = false;

    for (i = 0; i < variants.size; i++)
    {
        w_old = getweapon(variants[i]);

        if (self hasweapon(w_old))
        {
            self scripts\zm\_zm_weapons::weapon_take(w_old);
            had_bow = true;
        }
    }

    // stock base-bow pickup frees a slot by taking the held weapon when full
    if (!had_bow)
    {
        limit = scripts\zm\_zm_utility::get_player_weapon_limit(self);
        primaries = self getweaponslistprimaries();

        if (primaries.size >= limit)
        {
            self scripts\zm\_zm_weapons::weapon_take(self getcurrentweapon());
        }
    }

    w_bow = getweapon("elemental_bow_" + element);
    self scripts\zm\_zm_weapons::weapon_give(w_bow, 0, 0, 1);
    self setweaponammostock(w_bow, w_bow.maxammo);
    self setweaponammoclip(w_bow, w_bow.clipsize);
    self switchtoweapon(w_bow);
}

// Give every player the Ragnarok DG-4 exactly like the stock pickup trigger:
// weapon_give + full gadget power + gravityspikes state 2 ("has it").
function zm8_de_cmd_ragnarok(args)
{
    if (getdvarstring("mapname") != "zm_castle")
    {
        zm8_announce("^1zm8: zm8_de_ragnarok only works on Der Eisendrache");
        return;
    }

    wpn = getweapon("hero_gravityspikes_melee");
    players = getplayers();
    count = 0;

    for (i = 0; i < players.size; i++)
    {
        player = players[i];

        if (!isdefined(player) || !isalive(player) || player.sessionstate != "playing")
        {
            continue;
        }

        // the boss stun phase picks a random player's trap FX entity, which
        // only exists after a first plant - seed it so a never-planted
        // player (or 5th-8th) can't crash that pick. The weapon script
        // repositions it on every real plant, so pre-seeding is harmless.
        if (!isdefined(player.mdl_gravity_trap_fx_source))
        {
            mdl_fx = spawn("script_model", player.origin);
            mdl_fx setmodel("tag_origin");
            player.mdl_gravity_trap_fx_source = mdl_fx;
        }

        if (isdefined(player.gravityspikes_state) && player.gravityspikes_state != 0)
        {
            continue;
        }

        player scripts\zm\_zm_weapons::weapon_give(wpn, 0, 1);
        player gadgetpowerset(player gadgetgetslot(wpn), 100);

        // _zm_weap_gravityspikes is castle-only and this script links on
        // every map, so set the state field the way its helper does
        player.gravityspikes_state = 2;
        count++;
    }

    zm8_announce("^2zm8: gave the Ragnarok DG-4 to " + count + " player(s)");
}

// ========================== Der Eisendrache (zm8_de_*) ==========================
// Everything below is zm_castle-only and guarded by mapname.

// The final boss fight starts when the count of
// claimed gravity-spike pads reaches level.players.size, but the map has
// only 4 pads and level.players counts spectators too - unstartable with a
// 5th connected player. This satisfies the counter directly once the gate
// is active (var_b366f2dc is the decompiler's hash name for it, resolved by
// the EZZ compiler). Everyone should be in the undercroft when it fires.
function zm8_de_cmd_bossfight(args)
{
    mapname = getdvarstring("mapname");

    if (mapname != "zm_castle")
    {
        zm8_announce("^1zm8: zm8_de_bossfight only works on Der Eisendrache");
        return;
    }

    if (isdefined(level.flag) && isdefined(level.flag["boss_fight_begin"]) && level.flag["boss_fight_begin"])
    {
        zm8_announce("^3zm8: the boss fight has already started");
        return;
    }

    if (!isdefined(level.var_b366f2dc))
    {
        zm8_announce("^3zm8: boss fight is not ready - finish the earlier quest steps first");
        return;
    }

    zm8_announce("^2zm8: starting the boss fight - everyone to the undercroft!");
    level.var_b366f2dc = level.players.size;
}

function zm8_cmd_allperks(args)
{
    enable = !(isdefined(level.zm8_allperks) && level.zm8_allperks);

    if (isdefined(args) && args.size >= 1)
    {
        enable = (args[0] == "1");
    }

    level.zm8_allperks = enable;

    if (enable)
    {
        zm8_announce("^3zm8: permanent all-perks ON");
    }
    else
    {
        zm8_announce("^3zm8: permanent all-perks OFF (perks already given stay until lost)");
    }
}

// Stock behavior: mid-round joiners (and bled-out players) sit in spectate
// until _zm::spectators_respawn() runs, which only happens between rounds.
// zm8_spawn pushes them through the exact same respawn path immediately.
// zm8_spawn includes bled-out players (early "revive"); autospawn only takes
// fresh joiners so dying keeps its penalty.
function zm8_cmd_spawn(args)
{
    level thread zm8_force_spawn_spectators(true, true);
}

function zm8_cmd_autospawn(args)
{
    enable = !(isdefined(level.zm8_autospawn) && level.zm8_autospawn);

    if (isdefined(args) && args.size >= 1)
    {
        enable = (args[0] == "1");
    }

    level.zm8_autospawn = enable;

    if (enable)
    {
        zm8_announce("^3zm8: mid-round auto-spawn ON");
    }
    else
    {
        zm8_announce("^3zm8: mid-round auto-spawn OFF (joiners spawn next round, or via zm8_spawn)");
    }
}

function zm8_autospawn_monitor()
{
    level endon("end_game");

    while (true)
    {
        if (isdefined(level.zm8_autospawn) && level.zm8_autospawn)
        {
            level thread zm8_force_spawn_spectators(false, false);
        }

        wait 3;
    }
}

// level.game_mode_spawn_player_logic is what sends a mid-round joiner
// straight back to spectate after onSpawnPlayer, so blank it while we force
// the spawn, then restore. include_bled_out also spawns players who died and
// bled out this round (player_initialized = they have spawned before).
function zm8_force_spawn_spectators(announce_if_none, include_bled_out)
{
    if (isdefined(level.intermission) && level.intermission)
    {
        return;
    }

    if (isdefined(level.zm8_force_spawn_busy) && level.zm8_force_spawn_busy)
    {
        return;
    }
    level.zm8_force_spawn_busy = true;

    saved_logic = level.game_mode_spawn_player_logic;
    level.game_mode_spawn_player_logic = undefined;

    count = 0;
    players = getplayers();

    for (i = 0; i < players.size; i++)
    {
        player = players[i];

        if (!isdefined(player) || player.sessionstate != "spectator")
        {
            continue;
        }

        // the stock respawn path needs a spawn struct; joiners get one in
        // onSpawnPlayer just before being sent to spectate
        if (!isdefined(player.spectator_respawn))
        {
            continue;
        }

        if (!include_bled_out && isdefined(player.player_initialized) && player.player_initialized)
        {
            continue;
        }

        zm8_announce("^2zm8: spawning in " + player.name);
        player scripts\zm\_zm::spectator_respawn_player();
        count++;
        wait 0.25;
    }

    level.game_mode_spawn_player_logic = saved_logic;
    level.zm8_force_spawn_busy = false;

    if (count == 0 && announce_if_none)
    {
        zm8_announce("^3zm8: no spectators waiting to spawn");
    }
}

// While enabled, every player is topped up to all perks the map registered,
// including after downs/respawns - the Perkaholic effect, permanently.
function zm8_allperks_monitor()
{
    level endon("end_game");

    while (true)
    {
        if (isdefined(level.zm8_allperks) && level.zm8_allperks)
        {
            // the stock 4-perk cap would block perk 5+
            level.perk_purchase_limit = 100;

            perks = zm8_perk_list();
            players = getplayers();

            for (i = 0; i < players.size; i++)
            {
                player = players[i];

                if (!isdefined(player) || !isalive(player))
                {
                    continue;
                }

                if (isdefined(player.laststand) && player.laststand)
                {
                    continue;
                }

                if (player.sessionstate != "playing")
                {
                    continue;
                }

                for (j = 0; j < perks.size; j++)
                {
                    if (!(player hasperk(perks[j])))
                    {
                        player thread scripts\zm\_zm_perks::give_perk(perks[j], 0);
                        wait 0.1;
                    }
                }
            }
        }

        wait 3;
    }
}

function zm8_perk_list()
{
    if (isdefined(level._custom_perks))
    {
        return getarraykeys(level._custom_perks);
    }

    perks = [];
    perks[perks.size] = "specialty_armorvest";
    perks[perks.size] = "specialty_quickrevive";
    perks[perks.size] = "specialty_fastreload";
    perks[perks.size] = "specialty_rof";
    perks[perks.size] = "specialty_longersprint";
    return perks;
}

// GobbleGums for players 5-8: the gum scripts have no player cap, but the
// engine builtin getbubblegumpack() reads lobby loadout data that only exists
// for slots 0-3, so late slots can end up with an empty pack. The machine
// draws from the cached self.bgb_pack, so we can swap that cache freely.
//
// Custom pack: one shared pack for every player who needs one (there is no
// reliable way to tell which human is in slot 5 vs 6). The host lists gums in
// boiii\scriptdata\zm8\gum_pack.txt, one per line, using friendly names
// ("In Plain Sight") or internal ones (zm_bgb_in_plain_sight) - both work.
// A template plus a per-map list of valid gum names are written on map start.
function zm8_bgb_pack_fixer()
{
    level endon("end_game");

    zm8_write_available_gums();
    zm8_write_pack_template();

    while (true)
    {
        players = getplayers();

        for (i = 0; i < players.size; i++)
        {
            player = players[i];

            if (!isdefined(player) || isdefined(player.zm8_bgb_fixed))
            {
                continue;
            }

            // wait until _zm_bgb has initialized this player
            if (!isdefined(player.bgb_pack))
            {
                continue;
            }

            player.zm8_bgb_fixed = true;

            if (zm8_bgb_pack_is_empty(player.bgb_pack))
            {
                custom = zm8_read_shared_pack();

                if (isdefined(custom) && custom.size > 0)
                {
                    zm8_announce("^3zm8: giving " + player.name + " the shared custom pack");
                    player.bgb_pack = custom;
                }
                else
                {
                    zm8_announce("^3zm8: giving " + player.name + " the default gum pack");
                    player.bgb_pack = zm8_default_bgb_pack();
                }

                player.bgb_pack_randomized = [];
                player zm8_seed_mega_stats();
            }
        }

        wait 1;
    }
}

// dump every usable gum on this map, as friendly names players can copy
function zm8_write_available_gums()
{
    if (!isdefined(level.bgb))
    {
        return;
    }

    mkdir("zm8");

    out = "# gobblegums usable on this map - write these names in gum_pack.txt\n";
    out += "# megas are marked and experimental\n";

    keys = getarraykeys(level.bgb);

    for (i = 0; i < keys.size; i++)
    {
        out += zm8_friendly_gum_name(keys[i]);

        if (isdefined(level.bgb[keys[i]].consumable) && level.bgb[keys[i]].consumable)
        {
            out += " (mega)";
        }

        out += "\n";
    }

    writefile("zm8/available_gums.txt", out);
}

function zm8_write_pack_template()
{
    mkdir("zm8");

    if (fileexists("zm8/gum_pack.txt"))
    {
        return;
    }

    t = "# zm8 shared gum pack - given to every player the game did not give\n";
    t += "# a pack of their own (usually players 5-8). One gum per line, up to 5.\n";
    t += "# Names from zm8/available_gums.txt; friendly or internal names both work.\n";
    t += "# Megas (marked (mega) in the list) are allowed but experimental.\n";
    t += "# Delete the # from the lines below to use this example pack:\n";
    t += "#always done swiftly\n";
    t += "#arms grace\n";
    t += "#coagulant\n";
    t += "#in plain sight\n";
    t += "#stock option\n";

    writefile("zm8/gum_pack.txt", t);
}

// Megas (consumables) need a per-gum tracking struct that _zm_bgb only builds
// for the pack the engine handed over at init. Seed the missing ones so the
// machine can vend megas from an injected pack without touching undefined
// fields. var_e0b06b47 is the decompiler's hashed name for the remaining-uses
// field the machine reads (the EZZ compiler resolves var_ hash names).
function zm8_seed_mega_stats()
{
    if (!isdefined(self.bgb_pack) || !isdefined(level.bgb))
    {
        return;
    }

    if (!isdefined(self.bgb_stats))
    {
        self.bgb_stats = [];
    }

    for (i = 0; i < self.bgb_pack.size; i++)
    {
        gum = self.bgb_pack[i];

        if (!isdefined(level.bgb[gum]))
        {
            continue;
        }

        if (!isdefined(level.bgb[gum].consumable) || !level.bgb[gum].consumable)
        {
            continue;
        }

        if (isdefined(self.bgb_stats[gum]))
        {
            continue;
        }

        self.bgb_stats[gum] = spawnstruct();
        self.bgb_stats[gum].var_e0b06b47 = self getbgbremaining(gum);
        self.bgb_stats[gum].bgb_used_this_game = 0;
    }
}

// "in plain sight (mega)" -> "in plain sight"
function zm8_strip_marker(line)
{
    for (i = 0; i < line.size; i++)
    {
        if (getsubstr(line, i, i + 1) == "(")
        {
            return getsubstr(line, 0, i);
        }
    }

    return line;
}

// "In Plain Sight" -> zm_bgb_in_plain_sight
function zm8_normalize_gum_name(raw)
{
    while (raw.size > 0 && getsubstr(raw, 0, 1) == " ")
    {
        raw = getsubstr(raw, 1, raw.size);
    }

    while (raw.size > 0 && getsubstr(raw, raw.size - 1, raw.size) == " ")
    {
        raw = getsubstr(raw, 0, raw.size - 1);
    }

    raw = tolower(raw);
    out = "";

    for (i = 0; i < raw.size; i++)
    {
        c = getsubstr(raw, i, i + 1);

        if (c == " ")
        {
            out += "_";
        }
        else if (c == "'" || c == "\"" || c == "-")
        {
            continue;
        }
        else
        {
            out += c;
        }
    }

    if (out.size < 7 || getsubstr(out, 0, 7) != "zm_bgb_")
    {
        out = "zm_bgb_" + out;
    }

    return out;
}

// zm_bgb_in_plain_sight -> "in plain sight"
function zm8_friendly_gum_name(internal)
{
    name = internal;

    if (name.size > 7 && getsubstr(name, 0, 7) == "zm_bgb_")
    {
        name = getsubstr(name, 7, name.size);
    }

    out = "";

    for (i = 0; i < name.size; i++)
    {
        c = getsubstr(name, i, i + 1);

        if (c == "_")
        {
            out += " ";
        }
        else
        {
            out += c;
        }
    }

    return out;
}

function zm8_read_shared_pack()
{
    if (!fileexists("zm8/gum_pack.txt"))
    {
        return undefined;
    }

    content = readfile("zm8/gum_pack.txt");

    if (!isdefined(content) || content == "")
    {
        return undefined;
    }

    lines = strtok(content, "\n\r");
    pack = [];

    for (i = 0; i < lines.size; i++)
    {
        line = lines[i];

        if (line.size == 0 || getsubstr(line, 0, 1) == "#")
        {
            continue;
        }

        gum = zm8_normalize_gum_name(zm8_strip_marker(line));

        if (gum == "zm_bgb_")
        {
            continue;
        }

        if (!isdefined(level.bgb) || !isdefined(level.bgb[gum]))
        {
            zm8_announce("^1zm8: unknown gum '" + line + "' in gum_pack.txt - skipped");
            continue;
        }

        if (pack.size < 5)
        {
            pack[pack.size] = gum;
        }
    }

    if (pack.size > 0)
    {
        return pack;
    }

    return undefined;
}

function zm8_bgb_pack_is_empty(pack)
{
    if (!isdefined(pack) || pack.size == 0)
    {
        return true;
    }

    for (i = 0; i < pack.size; i++)
    {
        if (isdefined(pack[i]) && pack[i] != "weapon_null")
        {
            return false;
        }
    }

    return true;
}

// Default classic pack (GobbleGum Pack 1); only gums registered on this map
function zm8_default_bgb_pack()
{
    candidates = [];
    candidates[candidates.size] = "zm_bgb_always_done_swiftly";
    candidates[candidates.size] = "zm_bgb_arms_grace";
    candidates[candidates.size] = "zm_bgb_coagulant";
    candidates[candidates.size] = "zm_bgb_in_plain_sight";
    candidates[candidates.size] = "zm_bgb_stock_option";
    candidates[candidates.size] = "zm_bgb_sword_flay";
    candidates[candidates.size] = "zm_bgb_anywhere_but_here";

    pack = [];

    for (i = 0; i < candidates.size; i++)
    {
        if (pack.size >= 5)
        {
            break;
        }

        if (isdefined(level.bgb) && isdefined(level.bgb[candidates[i]]))
        {
            pack[pack.size] = candidates[i];
        }
    }

    return pack;
}

// Slots 0-3 get a characterindex from the lobby; players 5-8 may not.
// Several _zm.gsc monitors wait forever on self.characterindex if undefined,
// so fill gaps with one of the map's 4 characters (duplicates are expected).
function zm8_character_index_fixer()
{
    level endon("end_game");

    while (true)
    {
        players = getplayers();

        for (i = 0; i < players.size; i++)
        {
            if (isdefined(players[i]) && !isdefined(players[i].characterindex))
            {
                players[i].characterindex = players[i] getentitynumber() % 4;
            }
        }

        wait 1;
    }
}

// Zombie counter, top left: zombies left to spawn this round + currently alive
function zm8_zombie_counter()
{
    level endon("end_game");

    elem = newhudelem();
    elem.alignx = "left";
    elem.aligny = "top";
    elem.horzalign = "user_left";
    elem.vertalign = "user_top";
    elem.x = 10;
    elem.y = 10;
    elem.fontscale = 1.5;
    elem.color = (1, 0.4, 0.4);
    elem.alpha = 0.9;
    elem.hidewheninmenu = true;

    last_spawning = -1;
    last_alive = -1;

    while (true)
    {
        spawning = 0;

        if (isdefined(level.zombie_total))
        {
            spawning = level.zombie_total;
        }

        alive = scripts\shared\ai\zombie_utility::get_current_zombie_count();

        if (spawning != last_spawning || alive != last_alive)
        {
            elem setText("Spawning: " + spawning + "  Alive: " + alive);
            last_spawning = spawning;
            last_alive = alive;
        }

        wait 0.5;
    }
}

// ========================== Origins (zm8_origins_*) ==========================
// Everything below is zm_tomb-only and guarded by mapname.
//
// Audit notes for 5-8 players: the quest ("little_girl_lost") is 8 linear
// stages; each ends with zm_sidequests::stage_completed firing
// "little_girl_lost_step_N_over". No pad-style hard block like DE, but
// step 6 waits for flag ee_all_players_upgraded_punch, which is only set
// when EVERY connected player (spectators included) has b_punch_upgraded -
// zm8_origins_punch clears that. Only 4 staffs exist for up to 8 players -
// zm8_origins_staffs hands out duplicates. Players 5-8 all get character
// index 0 (extra Dempseys) from the map's own assigner; harmless.

// Force-complete the current quest step via the stock sidequest API (fires
// the same notifies/bookkeeping as a legit completion). At step_0 the quest
// has not started: it is gated on flags ee_all_staffs_crafted +
// all_zones_captured; we set the former, but zone capture is live generator
// state the capture system rewrites, so generators must genuinely be on.
function zm8_origins_cmd_eenext(args)
{
    if (getdvarstring("mapname") != "zm_tomb")
    {
        zm8_announce("^1zm8: zm8_origins_eenext only works on Origins");
        return;
    }

    if (!isdefined(level._zombie_sidequests) || !isdefined(level._zombie_sidequests["little_girl_lost"]))
    {
        zm8_announce("^1zm8: Origins quest system not initialized");
        return;
    }

    if (!isdefined(level._cur_stage_name) || level._cur_stage_name == "step_0")
    {
        level scripts\shared\flag_shared::set("ee_all_staffs_crafted");
        zm8_announce("^2zm8: staffs-crafted gate skipped - quest begins once all generators are captured");
        return;
    }

    quest = level._zombie_sidequests["little_girl_lost"];
    stage = quest.stages[level._cur_stage_name];

    if (!isdefined(stage))
    {
        zm8_announce("^1zm8: unknown quest stage " + level._cur_stage_name);
        return;
    }

    if (isdefined(stage.completed) && stage.completed == 1)
    {
        zm8_announce("^3zm8: " + level._cur_stage_name + " is already complete");
        return;
    }

    zm8_announce("^2zm8: force-completing " + level._cur_stage_name);
    level thread zm8_origins_complete_stage(quest, stage);
}

// Replicates _zm_sidequests::stage_completed_internal using only the data
// and function pointers stored on level._zombie_sidequests - linking to the
// sidequest script directly breaks maps that do not load it. Only skipped
// stock behavior: stage hint assets are not deleted.
function zm8_origins_complete_stage(quest, stage)
{
    level notify(quest.name + "_" + stage.name + "_over");
    level notify(quest.name + "_" + stage.name + "_completed");

    if (isdefined(quest.generic_stage_end_func))
    {
        stage [[quest.generic_stage_end_func]]();
    }

    if (isdefined(stage.exit_func))
    {
        stage [[stage.exit_func]](1);
    }

    stage.completed = 1;
    quest.last_completed_stage = quest.active_stage;
    quest.active_stage = -1;

    all_complete = 1;
    names = getarraykeys(quest.stages);

    for (i = 0; i < names.size; i++)
    {
        if (quest.stages[names[i]].completed == 0)
        {
            all_complete = 0;
            break;
        }
    }

    if (all_complete == 1)
    {
        if (isdefined(quest.complete_func))
        {
            quest thread [[quest.complete_func]]();
        }

        level notify("sidequest_" + quest.name + "_complete");
    }
}

// _zm_weap_one_inch_punch is tomb-only, so its stock giver cannot be linked
// from this all-maps script. Swap the melee slot to the upgraded punch the
// way the stock giver does. Players who earned a punch legitimately already
// run the map's melee monitor; for pure cheat recipients the punch does its
// weapon-def melee damage without the scripted AOE knockdown.
function zm8_origins_give_punch_weapon()
{
    w_melee = self scripts\zm\_zm_utility::get_player_melee_weapon();

    if (isdefined(w_melee))
    {
        self takeweapon(w_melee);
    }

    w_punch = getweapon("one_inch_punch_upgraded");
    self giveweapon(w_punch);
    self scripts\zm\_zm_utility::set_player_melee_weapon(w_punch);
}

// Upgraded One-Inch Punch for everyone, via the stock giver thread (handles
// the flourish, melee slot and element variant). Setting b_punch_upgraded
// first makes the giver hand out the upgraded fist, and setting the step-6
// flag directly is what unblocks the quest with spectators connected.
function zm8_origins_cmd_punch(args)
{
    if (getdvarstring("mapname") != "zm_tomb")
    {
        zm8_announce("^1zm8: zm8_origins_punch only works on Origins");
        return;
    }

    players = getplayers();

    for (i = 0; i < players.size; i++)
    {
        player = players[i];

        if (!isdefined(player) || !isalive(player) || player.sessionstate != "playing")
        {
            continue;
        }

        player.n_ee_punch_souls = 20;
        player.b_punch_upgraded = 1;

        if (!isdefined(player.str_punch_element))
        {
            player.str_punch_element = "upgraded";
        }

        player zm8_origins_give_punch_weapon();
    }

    if (isdefined(level.flag) && isdefined(level.flag["ee_all_players_upgraded_punch"]) && !level.flag["ee_all_players_upgraded_punch"])
    {
        level scripts\shared\flag_shared::set("ee_all_players_upgraded_punch");
    }

    zm8_announce("^2zm8: upgraded punch given to everyone (step 6 gate satisfied)");
}

// Give every player an upgraded elemental staff with full ammo. Only 4
// staffs exist in a normal game, so with 5-8 players this hands out
// duplicates - the staff charging/holder UI tracks one holder per element,
// which duplicates will confuse (combat works fine).
function zm8_origins_cmd_staffs(args)
{
    if (getdvarstring("mapname") != "zm_tomb")
    {
        zm8_announce("^1zm8: zm8_origins_staffs only works on Origins");
        return;
    }

    elements = [];
    elements[0] = "fire";
    elements[1] = "water";
    elements[2] = "air";
    elements[3] = "lightning";

    forced = undefined;

    if (isdefined(args) && args.size >= 1)
    {
        forced = zm8_origins_staff_element_from_name(args[0]);

        if (!isdefined(forced))
        {
            zm8_announce("^1zm8: unknown staff '" + args[0] + "' - use fire, ice, wind or lightning");
            return;
        }
    }

    players = getplayers();

    for (i = 0; i < players.size; i++)
    {
        player = players[i];

        if (!isdefined(player) || !isalive(player) || player.sessionstate != "playing")
        {
            continue;
        }

        element = forced;

        if (!isdefined(element))
        {
            element = elements[i % 4];
        }

        player zm8_origins_give_staff(element);
    }

    zm8_announce("^2zm8: upgraded staffs handed out");
}

function zm8_origins_staff_element_from_name(raw)
{
    raw = tolower(raw);

    if (raw == "fire")
    {
        return "fire";
    }

    if (raw == "ice" || raw == "water")
    {
        return "water";
    }

    if (raw == "wind" || raw == "air")
    {
        return "air";
    }

    if (raw == "lightning" || raw == "elec")
    {
        return "lightning";
    }

    return undefined;
}

function zm8_origins_give_staff(element)
{
    variants = [];
    variants[0] = "staff_air";
    variants[1] = "staff_fire";
    variants[2] = "staff_lightning";
    variants[3] = "staff_water";
    variants[4] = "staff_air_upgraded";
    variants[5] = "staff_fire_upgraded";
    variants[6] = "staff_lightning_upgraded";
    variants[7] = "staff_water_upgraded";

    had_staff = false;

    for (i = 0; i < variants.size; i++)
    {
        w_old = getweapon(variants[i]);

        if (self hasweapon(w_old))
        {
            self scripts\zm\_zm_weapons::weapon_take(w_old);
            had_staff = true;
        }
    }

    if (!had_staff)
    {
        limit = scripts\zm\_zm_utility::get_player_weapon_limit(self);
        primaries = self getweaponslistprimaries();

        if (primaries.size >= limit)
        {
            self scripts\zm\_zm_weapons::weapon_take(self getcurrentweapon());
        }
    }

    w_staff = getweapon("staff_" + element + "_upgraded");
    self scripts\zm\_zm_weapons::weapon_give(w_staff, 0, 0, 1);
    self setweaponammostock(w_staff, w_staff.maxammo);
    self setweaponammoclip(w_staff, w_staff.clipsize);
    self switchtoweapon(w_staff);
}
