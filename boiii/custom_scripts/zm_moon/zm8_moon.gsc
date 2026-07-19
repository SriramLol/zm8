// zm8 - Moon (zm_moon) command-only quest test helper
//
// Everything in this file is an explicit TESTING CHEAT. It does not alter
// Moon's automatic gameplay. The stage skipper mirrors the stock linked
// cheat_complete_stage routine and uses the normal sidequest completion API.

#using scripts\shared\flag_shared;
#using scripts\zm\_zm_equipment;
#using scripts\zm\_zm_sidequests;

autoexec function zm8_moon_test_helper_loaded()
{
    level.zm8_test_handler = &zm8_moon_test_command;
    println("zm8: Moon quest test commands loaded");
}

function zm8_moon_test_say(message)
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

function zm8_moon_test_stage_name(raw)
{
    names = array("ss1", "osc", "sc", "sc2", "ss2");

    for (i = 0; i < names.size; i++)
    {
        if (tolower(names[i]) == tolower(raw))
        {
            return names[i];
        }
    }

    return undefined;
}

function zm8_moon_test_to_stage(target, complete_all)
{
    level scripts\shared\flag_shared::set("power_on");
    deadline = gettime() + 30000;

    while (!isdefined(level._last_stage_started) && gettime() < deadline)
    {
        wait 0.25;
    }

    for (step = 0; step < 10; step++)
    {
        if (!isdefined(level._last_stage_started))
        {
            wait 0.5;
            continue;
        }

        if (!complete_all && level._last_stage_started == target)
        {
            zm8_moon_test_say("^2zm8: Moon test stage ready: " + target);
            return;
        }

        current = level._last_stage_started;
        scripts\zm\_zm_sidequests::stage_completed("sq", current);
        wait 1;

        if (isdefined(level._zombie_sidequests) && isdefined(level._zombie_sidequests["sq"]) &&
            isdefined(level._zombie_sidequests["sq"].sidequest_completed) && level._zombie_sidequests["sq"].sidequest_completed)
        {
            zm8_moon_test_say("^2zm8: Moon main sidequest completed through the stock stage API");
            return;
        }
    }

    zm8_moon_test_say("^1zm8: requested Moon stage did not become active");
}

function zm8_moon_test_command(args)
{
    scenario = "help";

    if (isdefined(args) && args.size > 0)
    {
        scenario = tolower(args[0]);
    }

    if (scenario == "help")
    {
        zm8_moon_test_say("^3zm8_test: teleporter | hacker | next | stage <ss1|osc|sc|sc2|ss2> | ee | wavegun | qed");
        return;
    }

    if (scenario == "teleporter")
    {
        teleporter = getent("nml_teleporter", "targetname");
        players = getplayers();

        if (!isdefined(teleporter))
        {
            zm8_moon_test_say("^1zm8: Area 51 teleporter entity was not found");
            return;
        }

        for (i = 0; i < players.size; i++)
        {
            if (isdefined(players[i]) && isalive(players[i]) && players[i].sessionstate == "playing")
            {
                players[i] setorigin(teleporter.origin + ((i % 4) * 12, (i / 4) * 12, 8));
            }
        }

        zm8_moon_test_say("^2zm8: living players stacked on the Area 51 teleporter");
        return;
    }

    if (scenario == "hacker")
    {
        players = getplayers();
        hacker = getweapon("equip_hacker");

        if (players.size < 1 || !isdefined(players[0]) || !isalive(players[0]))
        {
            zm8_moon_test_say("^1zm8: no living host found for the Hacker");
            return;
        }

        if (!isdefined(level.zombie_equipment) || !isdefined(level.zombie_equipment[hacker]))
        {
            zm8_moon_test_say("^1zm8: Moon Hacker equipment has not initialized yet");
            return;
        }

        if (!(players[0] scripts\zm\_zm_equipment::has_player_equipment(hacker)))
        {
            players[0] scripts\zm\_zm_equipment::setup_limited(hacker);
            players[0] scripts\zm\_zm_equipment::give(hacker);
        }

        zm8_moon_test_say("^2zm8: host received the Hacker through the stock equipment API");
        return;
    }

    if (scenario == "next")
    {
        if (!isdefined(level._last_stage_started))
        {
            zm8_moon_test_say("^1zm8: no Moon main-quest stage is active yet");
            return;
        }

        scripts\zm\_zm_sidequests::stage_completed("sq", level._last_stage_started);
        zm8_moon_test_say("^2zm8: completed current Moon stage through the stock API");
        return;
    }

    if (scenario == "stage")
    {
        if (!isdefined(args) || args.size < 2)
        {
            zm8_moon_test_say("^3zm8: usage: zm8_test stage <ss1|osc|sc|sc2|ss2>");
            return;
        }

        target = zm8_moon_test_stage_name(args[1]);

        if (!isdefined(target))
        {
            zm8_moon_test_say("^1zm8: unknown Moon stage name");
            return;
        }

        level thread zm8_moon_test_to_stage(target, false);
        return;
    }

    if (scenario == "ee")
    {
        level thread zm8_moon_test_to_stage(undefined, true);
        return;
    }

    zm8_moon_test_say("^1zm8: unknown Moon scenario - run zm8_test help");
}
