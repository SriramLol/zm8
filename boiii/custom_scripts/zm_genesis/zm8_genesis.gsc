// zm8 - Revelations (zm_genesis) 5-8 player compatibility helper

#using scripts\codescripts\struct;
#using scripts\shared\array_shared;
#using scripts\shared\flag_shared;
#using scripts\zm\_zm;
#using scripts\zm\zm_genesis_arena;
#using scripts\zm\zm_genesis_challenges;
#using scripts\zm\zm_genesis_minor_ee;
#using scripts\zm\zm_genesis_timer;

autoexec function zm8_genesis_helper_loaded()
{
    level.zm8_test_handler = &zm8_genesis_test_command;
    println("zm8: Revelations 5-8 player arena/challenge compatibility loaded");
    level thread zm8_genesis_pad_arena_arrivals();
    level thread zm8_genesis_pad_old_school_timer();
}

function zm8_genesis_test_say(message)
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

function zm8_genesis_test_command(args)
{
    scenario = "help";

    if (isdefined(args) && args.size > 0)
    {
        scenario = tolower(args[0]);
    }

    if (scenario == "help")
    {
        zm8_genesis_test_say("^3zm8_test: quest | trials | timer <5|10|15|20> | oldschool | runes | arena1 | arena2 | thundergun | servant");
        return;
    }

    if (scenario == "trials")
    {
        players = getplayers();

        for (i = 0; i < players.size; i++)
        {
            if (!isdefined(players[i]) || !isalive(players[i]) || players[i].sessionstate != "playing")
            {
                continue;
            }

            players[i] scripts\shared\flag_shared::set("flag_player_completed_challenge_1");
            players[i] scripts\shared\flag_shared::set("flag_player_completed_challenge_2");
            players[i] scripts\shared\flag_shared::set("flag_player_completed_challenge_3");
        }

        zm8_genesis_test_say("^2zm8: completed all assigned Revelations trials through their real player flags");
        return;
    }

    if (scenario == "timer")
    {
        if (!isdefined(args) || args.size < 2)
        {
            zm8_genesis_test_say("^3zm8: usage: zm8_test timer <5|10|15|20>");
            return;
        }

        completed_round = int(args[1]);

        if (completed_round != 5 && completed_round != 10 && completed_round != 15 && completed_round != 20)
        {
            zm8_genesis_test_say("^1zm8: Revelations timer round must be 5, 10, 15 or 20");
            return;
        }

        luinotifyevent(&"zombie_time_attack_notification", 2, completed_round, level.players.size);
        playsoundatposition("zmb_genesis_timetrial_complete", (0, 0, 0));
        level thread scripts\zm\zm_genesis_timer::function_cc8ae246(completed_round);
        zm8_genesis_test_say("^2zm8: fired the stock Revelations time-trial reward for round " + completed_round);
        return;
    }

    if (scenario == "oldschool")
    {
        if (!isdefined(level.var_557b53fd) || !isdefined(level.var_557b53fd[level.players.size]))
        {
            zm8_genesis_test_say("^1zm8: Old School timer array is not initialized yet");
            return;
        }

        level thread scripts\zm\zm_genesis_minor_ee::function_2d1b88ec();
        zm8_genesis_test_say("^2zm8: started the stock Old School reset timer using the current 5-8 player count");
        return;
    }

    if (scenario == "runes")
    {
        level scripts\shared\flag_shared::set("book_placed");
        level scripts\shared\flag_shared::set("rune_circle_on");
        level scripts\shared\flag_shared::set("book_runes_success");
        wait 1;
        portal = getent("rift_entrance_rune_portal", "targetname");
        players = getplayers();

        if (!isdefined(portal))
        {
            zm8_genesis_test_say("^1zm8: rune portal entity was not found");
            return;
        }

        for (i = 0; i < players.size; i++)
        {
            if (isdefined(players[i]) && isalive(players[i]) && players[i].sessionstate == "playing")
            {
                players[i] setorigin(portal.origin + ((i % 4) * 12, (i / 4) * 12, 8));
            }
        }

        zm8_genesis_test_say("^2zm8: runes credited and every living player stacked on the stock arena portal");
        return;
    }

    if (scenario == "arena1" || scenario == "arena2")
    {
        arrivals = scripts\codescripts\struct::get_array("dark_arena_teleport_hijack", "targetname");
        players = getplayers();
        participant = 0;

        for (i = 0; i < players.size; i++)
        {
            if (!isdefined(players[i]) || !isalive(players[i]) || players[i].sessionstate != "playing")
            {
                continue;
            }

            if (participant >= arrivals.size)
            {
                zm8_genesis_test_say("^1zm8: padded arena arrival array is still too small");
                return;
            }

            players[i] thread scripts\zm\zm_genesis_arena::function_56668973(arrivals[participant]);
            participant++;
        }

        zm8_genesis_test_say("^2zm8: invoked the stock arena arrival path for " + participant + " living player(s)");
        return;
    }

    zm8_genesis_test_say("^1zm8: unknown Revelations scenario - run zm8_test help");
}

// Both arena-start paths directly index one dark_arena_teleport_hijack struct
// per active player. Pad the map's stored four-point array before the late-game
// quest can read it. The second group is offset to avoid player overlap.
function zm8_genesis_pad_arena_arrivals()
{
    level endon("end_game");

    while (!isdefined(level.struct_class_names) ||
        !isdefined(level.struct_class_names["targetname"]) ||
        !isdefined(level.struct_class_names["targetname"]["dark_arena_teleport_hijack"]))
    {
        wait 0.5;
    }

    arrivals = level.struct_class_names["targetname"]["dark_arena_teleport_hijack"];

    if (!isdefined(arrivals) || arrivals.size < 1 || arrivals.size >= 8)
    {
        return;
    }

    base_count = arrivals.size;

    for (i = base_count; i < 8; i++)
    {
        source = arrivals[i % base_count];
        clone = spawnstruct();
        clone.origin = source.origin + vectorscale(anglestoright(source.angles), 48);
        clone.angles = source.angles;
        clone.targetname = source.targetname;
        arrivals[arrivals.size] = clone;
    }

    level.struct_class_names["targetname"]["dark_arena_teleport_hijack"] = arrivals;
    println("zm8: padded Revelations arena arrivals from " + base_count + " to 8");
}

// The Old School side egg indexes a 1-4-player delay array directly with
// level.players.size. Its four-player delay is already the shortest intended
// value, so extend that value through eight players before the egg can run.
function zm8_genesis_pad_old_school_timer()
{
    level endon("end_game");

    while (!isdefined(level.var_557b53fd) || !isdefined(level.var_557b53fd[4]))
    {
        wait 0.5;
    }

    for (i = 5; i <= 8; i++)
    {
        level.var_557b53fd[i] = level.var_557b53fd[4];
    }

    println("zm8: padded Revelations Old School timer for 5-8 players");
}

// Stock time-trial thresholds use switches with cases only for 1-4 players,
// making every timed round reward unreachable at 5+. Use the four-player
// threshold for larger groups and retain the stock round/reward sequence.
detour scripts\zm\zm_genesis_timer::function_086419da()
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
            thresholds = array(720, 690, 670, 660);
            threshold = thresholds[count - 1];
        }
        else if (completed_round == 15)
        {
            thresholds = array(1140, 1170, 1020, 945);
            threshold = thresholds[count - 1];
        }
        else if (completed_round == 20)
        {
            thresholds = array(1920, 1800, 1720, 1680);
            threshold = thresholds[count - 1];
        }

        if (isdefined(threshold) && current_time < threshold)
        {
            luinotifyevent(&"zombie_time_attack_notification", 2, scripts\zm\_zm::get_round_number() - 1, level.players.size);
            playsoundatposition("zmb_genesis_timetrial_complete", (0, 0, 0));
            level thread scripts\zm\zm_genesis_timer::function_cc8ae246(completed_round);
        }
    }
    while (completed_round < 50);
}

// Stock has six entries in each trial category and removes one for every
// player, so player seven receives undefined challenges. Preserve immutable
// copies and repeat assignments only after a live pool is empty.
//
// The map has four physical reward boards whose trigger and reward model each
// store one entity owner. Players 5-8 still receive and legitimately progress
// all three trials, but board/reward setup is deliberately not duplicated;
// sharing those single-owner objects would race and can delete another
// player's reward.
detour scripts\zm\zm_genesis_challenges::on_player_connect()
{
    level scripts\shared\flag_shared::wait_till("flag_init_player_challenges");
    self scripts\shared\flag_shared::init("flag_player_collected_reward_1");
    self scripts\shared\flag_shared::init("flag_player_collected_reward_2");
    self scripts\shared\flag_shared::init("flag_player_collected_reward_3");
    self scripts\shared\flag_shared::init("flag_player_completed_challenge_1");
    self scripts\shared\flag_shared::init("flag_player_completed_challenge_2");
    self scripts\shared\flag_shared::init("flag_player_completed_challenge_3");
    self scripts\shared\flag_shared::init("flag_player_initialized_reward");

    if (!isdefined(level.zm8_genesis_challenge_pool_1))
    {
        level.zm8_genesis_challenge_pool_1 = [];
        level.zm8_genesis_challenge_pool_2 = [];
        level.zm8_genesis_challenge_pool_3 = [];

        for (i = 0; i < level.s_challenges.a_challenge_1.size; i++)
        {
            level.zm8_genesis_challenge_pool_1[level.zm8_genesis_challenge_pool_1.size] = level.s_challenges.a_challenge_1[i];
        }

        for (i = 0; i < level.s_challenges.a_challenge_2.size; i++)
        {
            level.zm8_genesis_challenge_pool_2[level.zm8_genesis_challenge_pool_2.size] = level.s_challenges.a_challenge_2[i];
        }

        for (i = 0; i < level.s_challenges.a_challenge_3.size; i++)
        {
            level.zm8_genesis_challenge_pool_3[level.zm8_genesis_challenge_pool_3.size] = level.s_challenges.a_challenge_3[i];
        }
    }

    self.s_challenges = spawnstruct();

    if (level.s_challenges.a_challenge_1.size > 0)
    {
        self.s_challenges.a_challenge_1 = scripts\shared\array_shared::random(level.s_challenges.a_challenge_1);
        arrayremovevalue(level.s_challenges.a_challenge_1, self.s_challenges.a_challenge_1);
    }
    else
    {
        self.s_challenges.a_challenge_1 = scripts\shared\array_shared::random(level.zm8_genesis_challenge_pool_1);
    }

    if (level.s_challenges.a_challenge_2.size > 0)
    {
        self.s_challenges.a_challenge_2 = scripts\shared\array_shared::random(level.s_challenges.a_challenge_2);
        arrayremovevalue(level.s_challenges.a_challenge_2, self.s_challenges.a_challenge_2);
    }
    else
    {
        self.s_challenges.a_challenge_2 = scripts\shared\array_shared::random(level.zm8_genesis_challenge_pool_2);
    }

    if (level.s_challenges.a_challenge_3.size > 0)
    {
        self.s_challenges.a_challenge_3 = scripts\shared\array_shared::random(level.s_challenges.a_challenge_3);
        arrayremovevalue(level.s_challenges.a_challenge_3, self.s_challenges.a_challenge_3);
    }
    else
    {
        self.s_challenges.a_challenge_3 = scripts\shared\array_shared::random(level.zm8_genesis_challenge_pool_3);
    }

    player_number = self getentitynumber();

    if (player_number < 4)
    {
        self thread scripts\zm\zm_genesis_challenges::function_b7156b15();
        return;
    }

    self thread scripts\zm\zm_genesis_challenges::function_2ce855f3(self.s_challenges.a_challenge_1);
    self thread scripts\zm\zm_genesis_challenges::function_2ce855f3(self.s_challenges.a_challenge_2);
    self thread scripts\zm\zm_genesis_challenges::function_2ce855f3(self.s_challenges.a_challenge_3);
    self thread scripts\zm\zm_genesis_challenges::function_fbbc8608(self.s_challenges.a_challenge_1.n_index, "flag_player_completed_challenge_1");
    self thread scripts\zm\zm_genesis_challenges::function_fbbc8608(self.s_challenges.a_challenge_2.n_index, "flag_player_completed_challenge_2");
    self thread scripts\zm\zm_genesis_challenges::function_fbbc8608(self.s_challenges.a_challenge_3.n_index, "flag_player_completed_challenge_3");
    self thread scripts\zm\zm_genesis_challenges::function_974d5f1d();
    println("zm8: Revelations player " + (player_number + 1) + " has trials, but stock has no safe reward board for that slot");
}
