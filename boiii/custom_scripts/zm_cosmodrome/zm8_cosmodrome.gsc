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
#using scripts\zm\_zm;
#using scripts\zm\_zm_audio;
#using scripts\zm\zm_cosmodrome_amb;
#using scripts\zm\zm_cosmodrome_lander;

autoexec function zm8_cosmodrome_helper_loaded()
{
    sys::println(0, "zm8: Ascension 5-8 player lander compatibility loaded");
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
