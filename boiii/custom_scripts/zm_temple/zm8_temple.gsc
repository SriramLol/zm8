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
#using scripts\zm\_zm_utility;
#using scripts\zm\zm_temple_pack_a_punch;

autoexec function zm8_temple_helper_loaded()
{
    println("zm8: Shangri-La 5-8 player compatibility detour loaded");
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
