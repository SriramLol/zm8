// zm8 - Shangri-La (zm_temple) 5-8 player compatibility helper
//
// ezboiii 1.1.6 loads custom_scripts/<mapname>/ only for that map. Keeping
// this detour here lets it reference zm_temple-only scripts without making
// the universal custom_scripts/zm/zm8.gsc fail to link on other maps.
//
// AUTOMATIC 5-8 PLAYER COMPATIBILITY FIX (no command):
// Shangri-La's Pack-a-Punch requires one pressure plate per CONNECTED
// player, but the map has exactly 4 plates - with a 5th player connected
// (or any spectator) the stock gate can never be satisfied and PaP is
// permanently unreachable. The detour below is a faithful copy of the stock
// plate loop with one change: it requires one plate per LIVING player,
// capped at the 4 physical plates.

#using scripts\shared\array_shared;
#using scripts\shared\flag_shared;
#using scripts\shared\util_shared;
#using scripts\zm\_zm_sidequests;
#using scripts\zm\_zm_utility;
#using scripts\zm\zm_temple_pack_a_punch;

autoexec function zm8_temple_helper_loaded()
{
    level.zm8_test_handler = &zm8_temple_test_command;
    println("zm8: Shangri-La 5-8 player compatibility detour loaded");
}

function zm8_temple_test_say(message)
{
    if (isdefined(level.zm8_test_announce))
    {
        level [[level.zm8_test_announce]](message);
    }
    else
    {
        println(message);
    }
}

function zm8_temple_test_stage_name(raw)
{
    names = array("BaG", "bttp", "bttp2", "DgCWf", "LGS", "OaFC", "PtT", "StD");

    for (i = 0; i < names.size; i++)
    {
        if (tolower(names[i]) == tolower(raw))
        {
            return names[i];
        }
    }

    return undefined;
}

function zm8_temple_test_complete_current()
{
    if (!isdefined(level._last_stage_started))
    {
        return false;
    }

    scripts\zm\_zm_sidequests::stage_completed("sq", level._last_stage_started);
    return true;
}

function zm8_temple_test_to_stage(target, complete_all)
{
    level scripts\shared\flag_shared::set("power_on");
    deadline = gettime() + 30000;

    while (!isdefined(level._last_stage_started) && gettime() < deadline)
    {
        wait 0.25;
    }

    for (step = 0; step < 12; step++)
    {
        if (!isdefined(level._last_stage_started))
        {
            wait 0.5;
            continue;
        }

        if (!complete_all && level._last_stage_started == target)
        {
            zm8_temple_test_say("^2zm8: Shangri-La test stage ready: " + target);
            return;
        }

        current = level._last_stage_started;
        scripts\zm\_zm_sidequests::stage_completed("sq", current);
        wait 1;

        if (isdefined(level._zombie_sidequests) && isdefined(level._zombie_sidequests["sq"]) &&
            isdefined(level._zombie_sidequests["sq"].sidequest_completed) && level._zombie_sidequests["sq"].sidequest_completed)
        {
            zm8_temple_test_say("^2zm8: Shangri-La sidequest completed through the stock stage API");
            return;
        }
    }

    zm8_temple_test_say("^1zm8: requested Shangri-La stage did not become active");
}

function zm8_temple_test_command(args)
{
    scenario = "help";

    if (isdefined(args) && args.size > 0)
    {
        scenario = tolower(args[0]);
    }

    if (scenario == "help")
    {
        zm8_temple_test_say("^3zm8_test: pap | next | stage <BaG|bttp|bttp2|DgCWf|LGS|OaFC|PtT|StD> | ee | shrinkray");
        return;
    }

    if (scenario == "pap")
    {
        level scripts\shared\flag_shared::set("power_on");
        triggers = [];

        for (i = 0; i < 4; i++)
        {
            triggers[i] = getent("pap_blocker_trigger" + (i + 1), "targetname");

            if (!isdefined(triggers[i]))
            {
                zm8_temple_test_say("^1zm8: Shangri-La Pack-a-Punch plates are not initialized yet");
                return;
            }
        }

        players = getplayers();
        participant = 0;

        for (i = 0; i < players.size; i++)
        {
            if (!isdefined(players[i]) || !isalive(players[i]) || players[i].sessionstate != "playing")
            {
                continue;
            }

            slot = participant;

            if (slot > 3)
            {
                slot = 3;
            }

            players[i] setorigin(triggers[slot].origin + (0, 0, 8));
            participant++;
        }

        zm8_temple_test_say("^2zm8: living players placed across the required Pack-a-Punch plates");
        return;
    }

    if (scenario == "next")
    {
        if (zm8_temple_test_complete_current())
        {
            zm8_temple_test_say("^2zm8: completed current Shangri-La stage through the stock API");
        }
        else
        {
            zm8_temple_test_say("^1zm8: no Shangri-La sidequest stage is active yet");
        }

        return;
    }

    if (scenario == "stage")
    {
        if (!isdefined(args) || args.size < 2)
        {
            zm8_temple_test_say("^3zm8: usage: zm8_test stage <stage name>");
            return;
        }

        target = zm8_temple_test_stage_name(args[1]);

        if (!isdefined(target))
        {
            zm8_temple_test_say("^1zm8: unknown Shangri-La stage name");
            return;
        }

        level thread zm8_temple_test_to_stage(target, false);
        return;
    }

    if (scenario == "ee")
    {
        level thread zm8_temple_test_to_stage(undefined, true);
        return;
    }

    zm8_temple_test_say("^1zm8: unknown Shangri-La scenario - run zm8_test help");
}

// the stock script's power() helper is file-local flavored; keep our own
function zm8_temple_pow2(exp)
{
    result = 1;

    for (i = 0; i < exp; i++)
    {
        result = result * 2;
    }

    return result;
}

// One plate per LIVING player, capped at the 4 physical plates. Spectators
// and bled-out players no longer count against the gate.
function zm8_temple_plates_needed()
{
    players = getplayers();
    needed = 0;

    for (i = 0; i < players.size; i++)
    {
        player = players[i];

        if (isdefined(player) && isalive(player) && player.sessionstate == "playing")
        {
            needed++;
        }
    }

    if (needed > 4)
    {
        needed = 4;
    }

    if (needed < 1)
    {
        needed = 1;
    }

    return needed;
}

// Faithful copy of the stock function; the only functional change is where
// num_plates_needed comes from (see header). The dev-only block is dropped.
detour scripts\zm\zm_temple_pack_a_punch::_setup_simultaneous_pap_triggers()
{
    spots = getentarray("hanging_base", "targetname");

    for (i = 0; i < spots.size; i++)
    {
        spots[i] delete();
    }

    level flag::wait_till("power_on");
    triggers = [];

    for (i = 0; i < 4; i++)
    {
        triggers[i] = getent("pap_blocker_trigger" + i + 1, "targetname");
    }

    zm_temple_pack_a_punch::_randomize_pressure_plates(triggers);
    array::thread_all(triggers, &zm_temple_pack_a_punch::_pap_pressure_plate_move);
    wait 1;
    last_num_plates_active = -1;
    last_plate_state = -1;

    while (true)
    {
        // zm8 change: living players capped at 4, not all connected clients
        num_plates_needed = zm8_temple_plates_needed();

        num_plates_active = 0;
        plate_state = 0;

        for (i = 0; i < triggers.size; i++)
        {
            if (triggers[i].plate.active)
            {
                num_plates_active++;
            }

            if (triggers[i].plate.active || triggers[i].requiredplayers - 1 >= num_plates_needed)
            {
                plate_state += zm8_temple_pow2(triggers[i].requiredplayers - 1);
            }
        }

        if (last_num_plates_active != num_plates_active || plate_state != last_plate_state)
        {
            last_num_plates_active = num_plates_active;
            last_plate_state = plate_state;
            zm_temple_pack_a_punch::_set_num_plates_active(num_plates_active, plate_state);
        }

        zm_temple_pack_a_punch::_update_stairs(triggers);

        if (num_plates_active >= num_plates_needed)
        {
            for (i = 0; i < triggers.size; i++)
            {
                triggers[i] notify("pap_active");
                triggers[i].plate zm_temple_pack_a_punch::_plate_move_down();
            }

            zm_temple_pack_a_punch::_pap_think();
            zm_temple_pack_a_punch::_randomize_pressure_plates(triggers);
            array::thread_all(triggers, &zm_temple_pack_a_punch::_pap_pressure_plate_move);
            zm_temple_pack_a_punch::_set_num_plates_active(4, 15);
            wait 1;
        }

        util::wait_network_frame();
    }
}
