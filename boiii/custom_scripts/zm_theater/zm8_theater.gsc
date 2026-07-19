// zm8 - Kino der Toten (zm_theater) 5-8 player compatibility helper
//
// Kino owns four teleporter staging/destination spots. The stock function
// directly indexes the staging array with the player number, so player 5
// reads past the end and aborts the teleport. This faithful detour folds
// players 5-8 onto the four physical spots and offsets the second group.

#using scripts\shared\array_shared;
#using scripts\shared\clientfield_shared;
#using scripts\shared\exploder_shared;
#using scripts\shared\util_shared;
#using scripts\shared\visionset_mgr_shared;
#using scripts\zm\zm_theater_teleporter;

autoexec function zm8_theater_helper_loaded()
{
    level.zm8_test_handler = &zm8_theater_test_command;
    println("zm8: Kino 5-8 player teleporter compatibility loaded");
}

function zm8_theater_test_say(message)
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

function zm8_theater_test_command(args)
{
    scenario = "help";

    if (isdefined(args) && args.size > 0)
    {
        scenario = tolower(args[0]);
    }

    if (scenario == "help")
    {
        zm8_theater_test_say("^3zm8_test: teleporter");
        return;
    }

    if (scenario == "teleporter")
    {
        level thread zm8_theater_test_teleporter();
        return;
    }

    zm8_theater_test_say("^1zm8: unknown Kino scenario - run zm8_test help");
}

function zm8_theater_test_teleporter()
{
    if (isdefined(level.zm8_theater_test_running) && level.zm8_theater_test_running)
    {
        zm8_theater_test_say("^3zm8: Kino teleporter test is already running");
        return;
    }

    level.zm8_theater_test_running = true;
    pad = getent("trigger_teleport_pad_0", "targetname");

    if (!isdefined(pad))
    {
        level.zm8_theater_test_running = false;
        zm8_theater_test_say("^1zm8: Kino teleporter pad was not found");
        return;
    }

    players = getplayers();

    for (i = 0; i < players.size; i++)
    {
        if (isdefined(players[i]) && isalive(players[i]) && players[i].sessionstate == "playing")
        {
            players[i] setorigin(pad.origin + ((i % 4) * 10, (i / 4) * 10, 8));
        }
    }

    wait 0.25;
    teleporting = [];
    teleporting = pad scripts\zm\zm_theater_teleporter::teleport_players(teleporting, "projroom");
    zm8_theater_test_say("^2zm8: Kino projection-room arrival complete; automatic return in 15 seconds");
    wait 15;
    pad scripts\zm\zm_theater_teleporter::teleport_players(teleporting, "theater");
    level.zm8_theater_test_running = false;
}

function zm8_theater_extra_offset(player_index, angles)
{
    if (player_index < 4)
    {
        return (0, 0, 0);
    }

    return vectorscale(anglestoright(angles), 36);
}

detour scripts\zm\zm_theater_teleporter::teleport_players(teleporting, loc)
{
    self endon(#"death");
    player_radius = 16;
    all_players = level.players;

    if (loc == "projroom")
    {
        players = all_players;
    }
    else
    {
        players = teleporting;
    }

    dest_room = [];
    dest_room = zm_theater_teleporter::get_array_spots("teleport_room_", dest_room);
    zm_theater_teleporter::initialize_occupied_flag(dest_room);
    zm_theater_teleporter::check_for_occupied_spots(dest_room, all_players, player_radius);
    prone_offset = vectorscale((0, 0, 1), 49);
    crouch_offset = vectorscale((0, 0, 1), 20);
    stand_offset = (0, 0, 0);

    for (i = 0; i < players.size; i++)
    {
        player = players[i];

        if (!isdefined(player))
        {
            continue;
        }

        if (loc == "projroom" && self zm_theater_teleporter::player_is_near_pad(player) == 0)
        {
            continue;
        }
        else if (loc == "projroom" && self zm_theater_teleporter::player_is_near_pad(player))
        {
            array::add(teleporting, player, 0);
        }

        player.is_teleporting = 1;
        player clientfield::increment("player_teleport_fx");
        player clientfield::set_to_player("player_dust_mote", 0);
        player freezecontrols(1);
        player disableweapons();
        player disableoffhandweapons();
        util::wait_network_frame();

        slot = i % 4;
        start = 0;

        while (dest_room[slot].occupied && start < 4)
        {
            start++;
            slot++;

            if (slot >= 4)
            {
                slot = 0;
            }
        }

        dest_room[slot].occupied = 1;
        player.inteleportation = 1;
        visionset_mgr::activate("overlay", "zm_theater_teleport", player);

        if (player getstance() == "prone")
        {
            desired_offset = prone_offset;
        }
        else if (player getstance() == "crouch")
        {
            desired_offset = crouch_offset;
        }
        else
        {
            desired_offset = stand_offset;
        }

        lateral_offset = zm8_theater_extra_offset(i, dest_room[slot].angles);
        util::setclientsysstate("levelNotify", "black_box_start", player);
        player setorigin(dest_room[slot].origin + lateral_offset);
        player setplayerangles(dest_room[slot].angles);
        player.teleport_origin = spawn("script_origin", player.origin);
        player.teleport_origin.angles = player.angles;
        player linkto(player.teleport_origin);
        player thread zm_theater_teleporter::function_7e0ed731(slot, desired_offset);
        player playrumbleonentity("zm_castle_moon_explosion_rumble");
    }

    if (!isdefined(teleporting) || teleporting.size < 1)
    {
        return;
    }

    wait(2);
    teleporting = array::filter(teleporting, 0, &zm_theater_teleporter::function_1488cf91);
    dest_room = [];

    if (loc == "projroom")
    {
        dest_room = zm_theater_teleporter::get_array_spots("projroom_teleport_player", dest_room);
    }
    else if (loc == "eerooms")
    {
        level.eeroomsinuse = 1;
        dest_room = zm_theater_teleporter::get_array_spots("ee_teleport_player", dest_room);
    }
    else if (loc == "theater")
    {
        if (isdefined(self.target))
        {
            ent = getent(self.target, "targetname");
            self thread zm_theater_teleporter::teleport_nuke(undefined, 20);
        }

        dest_room = zm_theater_teleporter::get_array_spots("theater_teleport_player", dest_room);
    }

    zm_theater_teleporter::initialize_occupied_flag(dest_room);
    zm_theater_teleporter::check_for_occupied_spots(dest_room, all_players, player_radius);
    teleporting = array::filter(teleporting, 0, &zm_theater_teleporter::function_1488cf91);

    for (i = 0; i < teleporting.size; i++)
    {
        player = teleporting[i];

        if (!isdefined(player))
        {
            continue;
        }

        slot = randomintrange(0, 4);
        start = 0;

        while (dest_room[slot].occupied && start < 4)
        {
            start++;
            slot++;

            if (slot >= 4)
            {
                slot = 0;
            }
        }

        dest_room[slot].occupied = 1;
        lateral_offset = zm8_theater_extra_offset(i, dest_room[slot].angles);
        util::setclientsysstate("levelNotify", "black_box_end", player);
        player notify(#"stop_teleport_fx");

        if (isdefined(player.teleport_origin))
        {
            player.teleport_origin delete();
        }

        player.teleport_origin = undefined;
        player setorigin(dest_room[slot].origin + lateral_offset);
        player setplayerangles(dest_room[slot].angles);
        player clientfield::increment("player_teleport_fx");

        if (loc != "eerooms")
        {
            player enableweapons();
            player enableoffhandweapons();
        }

        player freezecontrols(0);
        util::setclientsysstate("levelNotify", "t2bfx", player);
        visionset_mgr::deactivate("overlay", "zm_theater_teleport", player);
        player zm_theater_teleporter::teleport_aftereffects();

        if (loc == "projroom")
        {
            level.second_hand thread zm_theater_teleporter::start_wall_clock();
            thread zm_theater_teleporter::extra_cam_startup();
            player clientfield::set_to_player("player_dust_mote", 1);
        }
        else if (loc == "theater")
        {
            player.inteleportation = 0;
            player.var_35c3d096 = undefined;
            player clientfield::set_to_player("player_dust_mote", 1);
        }
        else
        {
            player notify(#"player_teleported", slot);
        }

        player.is_teleporting = 0;
    }

    if (loc == "projroom")
    {
        return teleporting;
    }

    if (loc == "theater")
    {
        level.eeroomsinuse = undefined;
        exploder::exploder(302);
    }
}
