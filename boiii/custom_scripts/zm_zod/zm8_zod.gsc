// zm8 - Shadows of Evil (zm_zod) 5-8 player quest compatibility helper

#using scripts\codescripts\struct;
#using scripts\shared\callbacks_shared;
#using scripts\shared\clientfield_shared;
#using scripts\shared\flag_shared;
#using scripts\zm\zm_zod_ee;
#using scripts\zm\zm_zod_sword_quest;

autoexec function zm8_zod_helper_loaded()
{
    println("zm8: Shadows of Evil 5-8 player quest detours loaded");
}

// Faithful copy of the stock main EE coroutine with one compatibility change:
// the post-Keeper branch is reachable for 4-8 players instead of exactly 4.
// Every ritual, sword, Keeper defense and state transition remains stock.
detour scripts\zm\zm_zod_ee::function_189ed812()
{
    scripts\shared\callbacks_shared::on_connect(&scripts\zm\zm_zod_ee::function_7a1d4697);
    scripts\zm\zm_zod_ee::function_1b6ee215();
    level scripts\shared\flag_shared::wait_till("ritual_pap_complete");
    scripts\zm\zm_zod_ee::function_08a05e65();
    level scripts\shared\flag_shared::wait_till("ee_begin");
    scripts\zm\zm_zod_ee::ee_begin();
    scripts\zm\zm_zod_ee::function_2e77f7bf();
    scripts\zm\zm_zod_ee::function_db49b939();
    players = level.players;

    if (players.size >= 4 || (isdefined(level.var_421ff75e) && level.var_421ff75e))
    {
        level scripts\shared\clientfield_shared::set("ee_quest_state", 3);

        for (i = 1; i < 5; i++)
        {
            character_name = scripts\zm\zm_zod_ee::function_d93f551b(i);
            keeper_state = ("ee_keeper_" + character_name) + "_state";
            level scripts\shared\clientfield_shared::set(keeper_state, 8);
            wait 0.1;
        }

        scripts\zm\zm_zod_ee::function_db8d1f6e();
        scripts\zm\zm_zod_ee::ee_ending();
    }
    else
    {
        level scripts\shared\clientfield_shared::set("ee_quest_state", 2);
    }

    players = level.activeplayers;

    for (i = 0; i < players.size; i++)
    {
        players[i] zm_zod_sword::give_sword(2, 1);
    }
}

// The ending IGC names four physical exits and indexes them by player array
// position. Reuse those valid exits for players 5-8 with a small separation.
detour scripts\zm\zm_zod_ee::function_5091df99()
{
    if (level.players.size <= 1)
    {
        return;
    }

    for (i = 0; i < level.players.size; i++)
    {
        slot = i % 4;
        spot = scripts\codescripts\struct::get("ending_igc_exit_" + slot);

        if (!isdefined(spot))
        {
            println("zm8: Shadows ending exit " + slot + " was not found");
            continue;
        }

        destination = spot.origin;

        if (i >= 4)
        {
            destination += vectorscale(anglestoright(spot.angles), 48);
        }

        level.players[i] setorigin(destination);

        if (isdefined(spot.angles))
        {
            level.players[i] setplayerangles(spot.angles);
        }
    }
}
