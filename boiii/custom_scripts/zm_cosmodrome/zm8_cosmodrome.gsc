// zm8 - Ascension (zm_cosmodrome) 5-8 player compatibility helper
//
// The stock lander has four rider anchors. Its scripts still iterate every
// connected player and write through anchor index -1 after those four are
// occupied. Cap normal trips at four riders (extra players take the next
// trip), and safely share the four anchors during the mandatory spawn intro.

#using scripts\codescripts\struct;
#using scripts\shared\clientfield_shared;
#using scripts\shared\flag_shared;
#using scripts\shared\laststand_shared;
#using scripts\shared\util_shared;
#using scripts\zm\_zm;
#using scripts\zm\_zm_audio;
#using scripts\zm\_zm_powerup_nuke;
#using scripts\zm\zm_cosmodrome;
#using scripts\zm\zm_cosmodrome_amb;
#using scripts\zm\zm_cosmodrome_eggs;
#using scripts\zm\zm_cosmodrome_lander;

autoexec function zm8_cosmodrome_helper_loaded()
{
    level.zm8_test_handler = &zm8_cosmodrome_test_command;
    println("zm8: Ascension 5-8 player lander/quest compatibility loaded");
}

function zm8_cosmodrome_test_say(message)
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

function zm8_cosmodrome_test_command(args)
{
    scenario = "help";

    if (isdefined(args) && args.size > 0)
    {
        scenario = tolower(args[0]);
    }

    if (scenario == "help")
    {
        zm8_cosmodrome_test_say("^3zm8_test: lander | pressure | pressurefast | doll | reward");
        return;
    }

    if (scenario == "lander")
    {
        level scripts\shared\flag_shared::set("power_on");
        lander = getent("lander", "targetname");

        if (!isdefined(lander) || !isdefined(lander.station))
        {
            zm8_cosmodrome_test_say("^1zm8: lander is not initialized yet");
            return;
        }

        rider_trigger = getent(lander.station + "_riders", "targetname");
        players = getplayers();

        if (!isdefined(rider_trigger))
        {
            zm8_cosmodrome_test_say("^1zm8: current lander rider trigger was not found");
            return;
        }

        for (i = 0; i < players.size; i++)
        {
            if (isdefined(players[i]) && isalive(players[i]) && players[i].sessionstate == "playing")
            {
                players[i] setorigin(rider_trigger.origin + ((i % 4) * 18, (i / 4) * 18, 8));
                players[i].score = 50000;
            }
        }

        zm8_cosmodrome_test_say("^2zm8: players moved onto the current lander platform with power and points");
        return;
    }

    if (scenario == "pressure" || scenario == "pressurefast")
    {
        if (level scripts\shared\flag_shared::get("pressure_sustained"))
        {
            zm8_cosmodrome_test_say("^3zm8: pressure step already completed; restart the map to retest it");
            return;
        }

        area = scripts\codescripts\struct::get("pressure_pad", "targetname");

        if (!isdefined(area))
        {
            zm8_cosmodrome_test_say("^1zm8: Gersh pressure-pad struct was not found");
            return;
        }

        if (scenario == "pressurefast")
        {
            level thread zm8_cosmodrome_test_pressure_fast(area);
        }
        else
        {
            level thread scripts\zm\zm_cosmodrome_eggs::pressure_plate_event();
        }

        wait 0.25;
        players = getplayers();

        for (i = 0; i < players.size; i++)
        {
            if (isdefined(players[i]) && isalive(players[i]) && players[i].sessionstate == "playing")
            {
                players[i] setorigin(area.origin + ((i % 4) * 20, (i / 4) * 20, 8));
            }
        }

        if (scenario == "pressurefast")
        {
            zm8_cosmodrome_test_say("^2zm8: 10-second pressure compatibility test started; living players stacked on it");
        }
        else
        {
            zm8_cosmodrome_test_say("^2zm8: real 120-second Gersh pressure timer started; living players stacked on it");
        }

        return;
    }

    if (scenario == "doll")
    {
        doll = getent("doll_egg_0", "targetname");
        players = getplayers();

        if (!isdefined(doll))
        {
            zm8_cosmodrome_test_say("^1zm8: Matryoshka test trigger was not found");
            return;
        }

        for (i = 0; i < players.size; i++)
        {
            if (isdefined(players[i]) && isalive(players[i]) && players[i].sessionstate == "playing")
            {
                players[i] setorigin(doll.origin + (48 + ((i % 4) * 12), (i / 4) * 16, 0));
            }
        }

        zm8_cosmodrome_test_say("^2zm8: players moved to Matryoshka trigger 0; use it with slots 5-8");
        return;
    }

    if (scenario == "reward")
    {
        level thread scripts\zm\zm_cosmodrome_eggs::wait_for_gersh_vox();
        zm8_cosmodrome_test_say("^2zm8: stock Gersh reward starts in 12.5 seconds for every connected player");
        return;
    }

    zm8_cosmodrome_test_say("^1zm8: unknown Ascension scenario - run zm8_test help");
}

// Short testing-only wrapper around the real, detoured area timer. The normal
// pressure command retains the stock 120 seconds; this one isolates the
// living-player participation check without making a tester stand still for
// two minutes.
function zm8_cosmodrome_test_pressure_fast(area)
{
    trig = spawn("trigger_radius", area.origin, 0, 300, 100);
    trig scripts\zm\zm_cosmodrome_eggs::area_timer(10);

    if (isdefined(trig))
    {
        trig delete();
    }

    zm8_cosmodrome_test_say("^2zm8: fast pressure timer completed through the real compatibility detour");
}

function zm8_cosmodrome_all_active_on_plate(plate)
{
    players = getplayers();
    active_count = 0;

    for (i = 0; i < players.size; i++)
    {
        player = players[i];

        if (!isdefined(player) || !isalive(player) || player.sessionstate != "playing")
        {
            continue;
        }

        active_count++;

        if (!player istouching(plate))
        {
            return false;
        }
    }

    return active_count > 0;
}

// The Gersh-device pressure plate uses every connected player, so a waiting
// spectator makes the sustained-pressure step impossible. Keep the real plate
// and full stock timer; every living participant must remain on it together.
detour scripts\zm\zm_cosmodrome_eggs::area_timer(time)
{
    clock_loc = scripts\codescripts\struct::get("pressure_timer", "targetname");
    clock = spawn("script_model", clock_loc.origin);
    clock setmodel("p7_zm_tra_wall_clock");
    clock.angles = clock_loc.angles;
    hand_loc = scripts\codescripts\struct::get("clock_timer_hand", "targetname");
    hand_start_angles = vectorscale((0, 1, 0), 90);
    timer_hand = scripts\shared\util_shared::spawn_model("p7_zm_kin_clock_second_hand", hand_loc.origin, hand_start_angles);
    step = 1;

    while (!level scripts\shared\flag_shared::get("pressure_sustained"))
    {
        self waittill(#"trigger");
        stop_timer = 0;

        if (!zm8_cosmodrome_all_active_on_plate(self))
        {
            wait step;
            stop_timer = 1;
        }

        if (stop_timer)
        {
            continue;
        }

        self playsound("zmb_ee_pressure_plate_down");
        time_remaining = time;
        timer_hand rotatepitch(-360, time);

        while (time_remaining)
        {
            if (!zm8_cosmodrome_all_active_on_plate(self))
            {
                wait step;
                time_remaining = time;
                stop_timer = 1;
                self playsound("zmb_ee_pressure_plate_up");
                timer_hand rotateto(hand_start_angles, 0.5);
                timer_hand playsound("zmb_ee_pressure_deny");
                wait 0.5;
                break;
            }

            if (stop_timer)
            {
                break;
            }

            wait step;
            time_remaining -= step;
            timer_hand playsound("zmb_ee_pressure_timer");
        }

        if (time_remaining <= 0)
        {
            level scripts\shared\flag_shared::set("pressure_sustained");
            players = getplayers();
            nuke_player = undefined;

            for (i = 0; i < players.size; i++)
            {
                if (isdefined(players[i]) && isalive(players[i]) && players[i].sessionstate == "playing")
                {
                    nuke_player = players[i];
                    break;
                }
            }

            timer_hand playsound("zmb_perks_packa_ready");

            if (isdefined(nuke_player))
            {
                old_fx = undefined;

                if (isdefined(nuke_player.fx))
                {
                    old_fx = nuke_player.fx;
                }

                nuke_player.fx = level.zombie_powerups["nuke"].fx;
                level thread scripts\zm\_zm_powerup_nuke::nuke_powerup(nuke_player, nuke_player.team);
                clock stoploopsound(1);
                wait 1;

                if (isdefined(old_fx))
                {
                    nuke_player.fx = old_fx;
                }
                else
                {
                    nuke_player.fx = undefined;
                }
            }
            else
            {
                clock stoploopsound(1);
            }

            clock delete();
            timer_hand delete();
            return;
        }
    }
}

detour scripts\zm\zm_cosmodrome_lander::lock_players(destination)
{
    lander = getent("lander", "targetname");
    lander.riders = 0;
    spots = getentarray("zipline_spots", "script_noteworthy");
    taken = [];
    zipline_door1 = getent("zipline_door_n", "script_noteworthy");
    zipline_door2 = getent("zipline_door_s", "script_noteworthy");
    base = getent("lander_base", "script_noteworthy");
    rider_trigger = getent(lander.station + "_riders", "targetname");
    crumb = struct::get(rider_trigger.target, "targetname");
    lander thread zm_cosmodrome_lander::takeoff_nuke(undefined, 80, 1, rider_trigger);
    lander thread zm_cosmodrome_lander::takeoff_knockdown(81, 250);
    lander_trig = getent("zip_buy", "script_noteworthy");
    x = 0;

    while (!level flag::get("lander_grounded"))
    {
        players = getplayers();

        for (i = 0; i < players.size; i++)
        {
            if (!rider_trigger istouching(players[i]) &&
                !players[i] istouching(zipline_door1) &&
                !players[i] istouching(zipline_door2) &&
                !players[i] istouching(base) && x < 8)
            {
                continue;
            }

            if (!players[i] istouching(lander_trig))
            {
                continue;
            }

            if (isdefined(players[i].lander) && players[i].lander)
            {
                continue;
            }

            max_dist = 10000;
            grab = -1;

            for (j = 0; j < 4; j++)
            {
                if (isdefined(taken[j]) && taken[j] == 1)
                {
                    continue;
                }

                dist = distance2d(players[i].origin, spots[j].origin);

                if (dist < max_dist)
                {
                    max_dist = dist;
                    grab = j;
                }
            }

            // zm8: all four physical anchors are occupied. Leave this player
            // safely on the platform so they can take the next lander trip.
            if (grab < 0)
            {
                continue;
            }

            taken[grab] = 1;

            if (players[i] laststand::player_is_in_laststand())
            {
                players[i] thread zm_cosmodrome_lander::function_e323fa97();
            }

            players[i] playerlinktodelta(spots[grab], undefined, 1, 180, 180, 180, 180, 1);
            players[i] enableinvulnerability();
            players[i] thread zm::store_crumb(crumb.origin);
            players[i].lander = 1;
            players[i].lander_link_spot = spots[grab];
            players[i] clientfield::set("COSMO_PLAYER_LANDER_FOG", 1);
            lander.riders++;
        }

        wait(0.25);
        x++;

        if (x == 4 && (lander.riders == players.size || lander.riders >= 4))
        {
            level thread zm_cosmodrome_lander::activate_lander_poi(destination);
        }
    }
}

detour scripts\zm\zm_cosmodrome_lander::lock_players_intro()
{
    lander = getent("lander", "targetname");
    lander.riders = 0;
    spots = getentarray("zipline_spots", "script_noteworthy");
    players = getplayers();

    for (i = 0; i < players.size; i++)
    {
        // The intro must carry everyone. Players 5-8 share the four purely
        // cinematic anchors; controls and damage remain locked until landing.
        grab = i % 4;
        players[i] playerlinkto(spots[grab], undefined, 0, 180, 180, 180, 180, 1);
        players[i] enableinvulnerability();
        players[i].lander = 1;
        lander.riders++;
    }
}

// The matryoshka-doll side egg selects VO with a stock player index switch
// that only handles 0-3. Fold extra character slots onto the four VO sets.
detour scripts\zm\zm_cosmodrome_amb::doll_egg(num)
{
    if (!isdefined(self))
    {
        return;
    }

    self usetriggerrequirelookat();
    self setcursorhint("HINT_NOICON");

    while (true)
    {
        self waittill(#"trigger", player);
        index = player getentitynumber() % 4;

        if (index == 0)
        {
            alias = ("vox_egg_doll_response_" + num) + "_0";
        }
        else if (index == 1)
        {
            alias = ("vox_egg_doll_response_" + num) + "_1";
        }
        else if (index == 3)
        {
            alias = ("vox_egg_doll_response_" + num) + "_2";
        }
        else
        {
            alias = ("vox_egg_doll_response_" + num) + "_3";
        }

        self playsoundwithnotify(alias, "sounddone" + alias);
        self waittill("sounddone" + alias);
        player zm_audio::create_and_play_dialog("weapon_pickup", "dolls");
        wait(8);
    }
}
