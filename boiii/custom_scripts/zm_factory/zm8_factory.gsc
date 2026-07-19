// zm8 - The Giant (zm_factory) 5-8 player compatibility helper
//
// The stock mainframe teleporter only examines players 1-4. This detour
// includes every nearby living player and safely shares the four physical
// staging/arrival spots, with a small offset for players 5-8.

#using scripts\shared\exploder_shared;
#using scripts\shared\util_shared;
#using scripts\shared\visionset_mgr_shared;
#using scripts\zm\zm_factory_teleporter;

autoexec function zm8_factory_helper_loaded()
{
    sys::println(0, "zm8: The Giant 5-8 player teleporter compatibility loaded");
}

function zm8_factory_extra_offset(index, angles)
{
    if (index < 4)
    {
        return (0, 0, 0);
    }

    return vectorscale(anglestoright(angles), 36);
}

detour scripts\zm\zm_factory_teleporter::teleport_players()
{
    player_radius = 16;
    players = getplayers();
    core_pos = [];
    occupied = [];
    image_room = [];
    players_touching = [];
    prone_offset = vectorscale((0, 0, 1), 49);
    crouch_offset = vectorscale((0, 0, 1), 20);
    stand_offset = (0, 0, 0);

    for (i = 0; i < 4; i++)
    {
        core_pos[i] = getent("origin_teleport_player_" + i, "targetname");
        occupied[i] = 0;
        image_room[i] = getent("teleport_room_" + i, "targetname");
    }

    for (i = 0; i < players.size; i++)
    {
        player = players[i];

        if (!isdefined(player) || !self zm_factory_teleporter::player_is_near_pad(player))
        {
            continue;
        }

        participant_index = players_touching.size;
        slot = participant_index % 4;
        players_touching[participant_index] = player;
        player.b_teleporting = 1;
        visionset_mgr::deactivate("overlay", "zm_trap_electric", player);
        visionset_mgr::activate("overlay", "zm_factory_teleport", player);
        player disableoffhandweapons();
        player disableweapons();

        if (player getstance() == "prone")
        {
            stance_offset = prone_offset;
        }
        else if (player getstance() == "crouch")
        {
            stance_offset = crouch_offset;
        }
        else
        {
            stance_offset = stand_offset;
        }

        lateral_offset = zm8_factory_extra_offset(participant_index, image_room[slot].angles);
        desired_origin = image_room[slot].origin + stance_offset + lateral_offset;
        player.teleport_origin = spawn("script_origin", player.origin);
        player.teleport_origin.angles = player.angles;
        player linkto(player.teleport_origin);
        player.teleport_origin.origin = desired_origin;
        player freezecontrols(1);
        util::wait_network_frame();

        if (isdefined(player))
        {
            util::setclientsysstate("levelNotify", "black_box_start", player);
            player.teleport_origin.angles = image_room[slot].angles;
        }
    }

    wait(2);
    core = getent("trigger_teleport_core", "targetname");
    core thread zm_factory_teleporter::teleport_nuke(undefined, 300);

    for (i = 0; i < players.size; i++)
    {
        if (!isdefined(players[i]))
        {
            continue;
        }

        for (j = 0; j < 4; j++)
        {
            if (!occupied[j] && distance2d(core_pos[j].origin, players[i].origin) < player_radius)
            {
                occupied[j] = 1;
            }
        }

        util::setclientsysstate("levelNotify", "black_box_end", players[i]);
    }

    util::wait_network_frame();

    for (i = 0; i < players_touching.size; i++)
    {
        player = players_touching[i];

        if (!isdefined(player))
        {
            continue;
        }

        slot = i % 4;
        start = 0;

        while (occupied[slot] && start < 4)
        {
            start++;
            slot++;

            if (slot >= 4)
            {
                slot = 0;
            }
        }

        occupied[slot] = 1;
        lateral_offset = zm8_factory_extra_offset(i, core_pos[slot].angles);
        player unlink();

        if (isdefined(player.teleport_origin))
        {
            player.teleport_origin delete();
        }

        player.teleport_origin = undefined;
        visionset_mgr::deactivate("overlay", "zm_factory_teleport", player);
        player enableweapons();
        player enableoffhandweapons();
        player setorigin(core_pos[slot].origin + lateral_offset);
        player setplayerangles(core_pos[slot].angles);
        player freezecontrols(0);
        player thread zm_factory_teleporter::teleport_aftereffects();
        player.b_teleporting = 0;
    }

    exploder::exploder_duration("mainframe_arrival", 1.7);
    exploder::exploder_duration("mainframe_steam", 14.6);
}
