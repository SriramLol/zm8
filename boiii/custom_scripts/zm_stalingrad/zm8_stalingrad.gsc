// zm8 - Gorod Krovi (zm_stalingrad) 5-8 player challenge compatibility

#using scripts\codescripts\struct;
#using scripts\shared\array_shared;
#using scripts\shared\callbacks_shared;
#using scripts\shared\flag_shared;
#using scripts\zm\_zm;
#using scripts\zm\zm_stalingrad_challenges;
#using scripts\zm\zm_stalingrad_timer;

autoexec function zm8_stalingrad_helper_loaded()
{
    println("zm8: Gorod Krovi 5-8 player challenge compatibility loaded");
}

// Gorod's round 5/10/15/20/50 time trials have switch cases only for 1-4
// players. Clamp only the threshold lookup to the stock four-player value;
// reward setup, notifications and the special round-20 signal remain stock.
detour scripts\zm\zm_stalingrad_timer::function_086419da()
{
    do
    {
        level waittill(#"end_of_round");
        current_time = (gettime() - level.n_gameplay_start_time) / 1000;
        completed_round = scripts\zm\_zm::get_round_number() - 1;
        threshold = undefined;
        count = level.players.size;

        if (count > 4)
        {
            count = 4;
        }

        if (completed_round == 5)
        {
            thresholds = array(300, 270, 250, 240);
            threshold = thresholds[count - 1];
        }
        else if (completed_round == 10)
        {
            thresholds = array(780, 720, 670, 660);
            threshold = thresholds[count - 1];
        }
        else if (completed_round == 15)
        {
            thresholds = array(1440, 1200, 1020, 960);
            threshold = thresholds[count - 1];
        }
        else if (completed_round == 20 || completed_round == 50)
        {
            thresholds = array(1920, 1800, 1740, 1680);
            threshold = thresholds[count - 1];
        }

        if (isdefined(threshold) && current_time < threshold)
        {
            luinotifyevent(&"zombie_time_attack_notification", 2, scripts\zm\_zm::get_round_number() - 1, level.players.size);
            playsoundatposition("zmb_stalingrad_time_trial_complete", (0, 0, 0));
            level thread scripts\zm\zm_stalingrad_timer::function_cc8ae246(completed_round);

            if (completed_round == 20)
            {
                level notify(#"hash_399599c1");
            }
        }
    }
    while (completed_round < 50);
}

// The post-quest 80-minute all-perks reward has the same missing 5-8 switch
// cases. Preserve the stock four-player threshold and callbacks.
detour scripts\zm\zm_stalingrad_timer::function_3d5b5002()
{
    count = level.players.size;

    if (count > 4)
    {
        count = 4;
    }

    thresholds = array(6000, 5340, 4980, 4800);
    threshold = thresholds[count - 1];

    if (level.var_2801f599 < threshold)
    {
        level.perk_purchase_limit = level._custom_perks.size;
        scripts\shared\callbacks_shared::on_spawned(&scripts\zm\zm_stalingrad_timer::on_player_spawned);
        scripts\shared\array_shared::thread_all(level.players, &scripts\zm\zm_stalingrad_timer::function_959f59b8);
    }
}

// Each stock challenge category has six entries and removes one per player.
// Player seven therefore receives undefined data. Keep immutable copies and
// repeat a legitimate challenge only after the corresponding live pool is
// exhausted. Four physical reward boards remain authoritative; players 5-8
// can progress their assigned trials, but no unsafe shared reward model is
// created for them.
detour scripts\zm\zm_stalingrad_challenges::function_b7156b15()
{
    self endon(#"disconnect");
    self scripts\shared\flag_shared::init("flag_player_collected_reward_1");
    self scripts\shared\flag_shared::init("flag_player_collected_reward_2");
    self scripts\shared\flag_shared::init("flag_player_collected_reward_3");
    self scripts\shared\flag_shared::init("flag_player_collected_reward_4");
    self scripts\shared\flag_shared::init("flag_player_collected_reward_5");
    self scripts\shared\flag_shared::init("flag_player_completed_challenge_1");
    self scripts\shared\flag_shared::init("flag_player_completed_challenge_2");
    self scripts\shared\flag_shared::init("flag_player_completed_challenge_3");
    self scripts\shared\flag_shared::init("flag_player_completed_challenge_4");

    if (level scripts\shared\flag_shared::get("gauntlet_quest_complete"))
    {
        self scripts\shared\flag_shared::set("flag_player_completed_challenge_4");
    }

    self scripts\shared\flag_shared::init("flag_player_initialized_reward");
    level scripts\shared\flag_shared::wait_till("initial_players_connected");

    if (!isdefined(level.zm8_gk_challenge_pool_1))
    {
        level.zm8_gk_challenge_pool_1 = [];
        level.zm8_gk_challenge_pool_2 = [];
        level.zm8_gk_challenge_pool_3 = [];

        for (i = 0; i < level._challenges.challenge_1.size; i++)
        {
            level.zm8_gk_challenge_pool_1[level.zm8_gk_challenge_pool_1.size] = level._challenges.challenge_1[i];
        }

        for (i = 0; i < level._challenges.challenge_2.size; i++)
        {
            level.zm8_gk_challenge_pool_2[level.zm8_gk_challenge_pool_2.size] = level._challenges.challenge_2[i];
        }

        for (i = 0; i < level._challenges.challenge_3.size; i++)
        {
            level.zm8_gk_challenge_pool_3[level.zm8_gk_challenge_pool_3.size] = level._challenges.challenge_3[i];
        }
    }

    self._challenges = spawnstruct();

    if (level._challenges.challenge_1.size > 0)
    {
        self._challenges.challenge_1 = scripts\shared\array_shared::random(level._challenges.challenge_1);
        arrayremovevalue(level._challenges.challenge_1, self._challenges.challenge_1);
    }
    else
    {
        self._challenges.challenge_1 = scripts\shared\array_shared::random(level.zm8_gk_challenge_pool_1);
    }

    if (level._challenges.challenge_2.size > 0)
    {
        self._challenges.challenge_2 = scripts\shared\array_shared::random(level._challenges.challenge_2);
        arrayremovevalue(level._challenges.challenge_2, self._challenges.challenge_2);
    }
    else
    {
        self._challenges.challenge_2 = scripts\shared\array_shared::random(level.zm8_gk_challenge_pool_2);
    }

    do
    {
        if (level._challenges.challenge_3.size > 0)
        {
            self._challenges.challenge_3 = scripts\shared\array_shared::random(level._challenges.challenge_3);
        }
        else
        {
            self._challenges.challenge_3 = scripts\shared\array_shared::random(level.zm8_gk_challenge_pool_3);
        }
    }
    while (level scripts\shared\flag_shared::get("solo_game") && level.players.size == 1 &&
        self._challenges.challenge_3.str_notify == "update_challenge_3_4");

    if (level._challenges.challenge_3.size > 0)
    {
        arrayremovevalue(level._challenges.challenge_3, self._challenges.challenge_3);
    }

    self thread scripts\zm\zm_stalingrad_challenges::function_2ce855f3(self._challenges.challenge_1);
    self thread scripts\zm\zm_stalingrad_challenges::function_2ce855f3(self._challenges.challenge_2);
    self thread scripts\zm\zm_stalingrad_challenges::function_2ce855f3(self._challenges.challenge_3);
    self thread scripts\zm\zm_stalingrad_challenges::function_fbbc8608(self._challenges.challenge_1.n_index, "flag_player_completed_challenge_1");
    self thread scripts\zm\zm_stalingrad_challenges::function_fbbc8608(self._challenges.challenge_2.n_index, "flag_player_completed_challenge_2");
    self thread scripts\zm\zm_stalingrad_challenges::function_fbbc8608(self._challenges.challenge_3.n_index, "flag_player_completed_challenge_3");
    self thread scripts\zm\zm_stalingrad_challenges::function_974d5f1d();
    player_number = self getentitynumber();

    for (i = 1; i <= 4; i++)
    {
        self thread scripts\zm\zm_stalingrad_challenges::function_a2d25f82(i);
    }

    if (player_number < 4)
    {
        foreach (challenge_trigger in scripts\codescripts\struct::get_array("s_challenge_trigger"))
        {
            if (challenge_trigger.script_int == player_number)
            {
                challenge_trigger scripts\zm\zm_stalingrad_challenges::function_4e61a018();
                break;
            }
        }
    }
    else
    {
        println("zm8: Gorod player " + (player_number + 1) + " has trials, but stock has no safe reward board for that slot");
    }
}
