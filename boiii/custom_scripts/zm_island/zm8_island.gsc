// zm8 - Zetsubou No Shima (zm_island) 5-8 player compatibility helper
//
// ezboiii 1.1.6 loads custom_scripts/<mapname>/ only for that map. Keeping
// these detours here lets them reference zm_island-only scripts without
// making the universal custom_scripts/zm/zm8.gsc fail to link on other maps.

#using scripts\codescripts\struct;
#using scripts\shared\ai\zombie_utility;
#using scripts\shared\array_shared;
#using scripts\shared\clientfield_shared;
#using scripts\shared\exploder_shared;
#using scripts\shared\flag_shared;
#using scripts\shared\util_shared;
#using scripts\zm\_zm_ai_spiders;
#using scripts\zm\_zm_ai_thrasher;
#using scripts\zm\_zm_utility;
#using scripts\zm\zm_island_challenges;
#using scripts\zm\zm_island_pap_quest;
#using scripts\zm\zm_island_skullweapon_quest;
#using scripts\zm\zm_island_takeo_fight;
#using scripts\zm\zm_island_util;

autoexec function zm8_island_helper_loaded()
{
    sys::println(0, "zm8: Zetsubou 5-8 player compatibility detours loaded");
}

// The stock challenge pools contain 5/6/5 entries and remove an entry for
// every player. Player 6 therefore receives undefined data in categories 1
// and 3. Keep immutable copies and allow repeats once a category is empty.
// Challenge boards/clientfields exist only for IDs 0-3, so players 5-8 use
// their modulo-4 board while retaining their own per-player challenge state.
detour scripts\zm\zm_island_challenges::on_player_connect()
{
    level scripts\shared\flag_shared::wait_till("flag_init_player_challenges");

    if (!isdefined(level.zm8_island_challenge_pool_1))
    {
        level.zm8_island_challenge_pool_1 = [];
        level.zm8_island_challenge_pool_2 = [];
        level.zm8_island_challenge_pool_3 = [];

        for (i = 0; i < level._challenges.challenge_1.size; i++)
        {
            level.zm8_island_challenge_pool_1[level.zm8_island_challenge_pool_1.size] = level._challenges.challenge_1[i];
        }

        for (i = 0; i < level._challenges.challenge_2.size; i++)
        {
            level.zm8_island_challenge_pool_2[level.zm8_island_challenge_pool_2.size] = level._challenges.challenge_2[i];
        }

        for (i = 0; i < level._challenges.challenge_3.size; i++)
        {
            level.zm8_island_challenge_pool_3[level.zm8_island_challenge_pool_3.size] = level._challenges.challenge_3[i];
        }
    }

    player_number = self getentitynumber();
    board_number = player_number % 4;
    self.var_8575e180 = 0;
    self.var_26f3bd30 = 0;
    self.var_301c71e9 = 0;
    self._challenges = spawnstruct();

    if (level._challenges.challenge_1.size > 0)
    {
        self._challenges.challenge_1 = scripts\shared\array_shared::random(level._challenges.challenge_1);
        arrayremovevalue(level._challenges.challenge_1, self._challenges.challenge_1);
    }
    else
    {
        self._challenges.challenge_1 = scripts\shared\array_shared::random(level.zm8_island_challenge_pool_1);
    }

    if (level._challenges.challenge_2.size > 0)
    {
        self._challenges.challenge_2 = scripts\shared\array_shared::random(level._challenges.challenge_2);
        arrayremovevalue(level._challenges.challenge_2, self._challenges.challenge_2);
    }
    else
    {
        self._challenges.challenge_2 = scripts\shared\array_shared::random(level.zm8_island_challenge_pool_2);
    }

    if (level._challenges.challenge_3.size > 0)
    {
        self._challenges.challenge_3 = scripts\shared\array_shared::random(level._challenges.challenge_3);
        arrayremovevalue(level._challenges.challenge_3, self._challenges.challenge_3);
    }
    else
    {
        self._challenges.challenge_3 = scripts\shared\array_shared::random(level.zm8_island_challenge_pool_3);
    }

    self thread zm8_island_setup_challenges(board_number, player_number);
}

// Stock uses one number for both the player's entity ID and the physical
// board ID. That only works while both are 0-3. Keep the real entity ID for
// per-player prompt/trigger ownership, but use modulo 4 for board art and FX.
function zm8_island_setup_challenges(board_number, player_number)
{
    self endon("disconnect");
    self scripts\shared\flag_shared::init("flag_player_collected_reward_1");
    self scripts\shared\flag_shared::init("flag_player_collected_reward_2");
    self scripts\shared\flag_shared::init("flag_player_collected_reward_3");
    self scripts\shared\flag_shared::init("flag_player_completed_challenge_1");
    self scripts\shared\flag_shared::init("flag_player_completed_challenge_2");
    self scripts\shared\flag_shared::init("flag_player_completed_challenge_3");
    self thread scripts\zm\zm_island_challenges::function_2ce855f3(self._challenges.challenge_1.n_index, self._challenges.challenge_1.func_think, self._challenges.challenge_1.n_count, self._challenges.challenge_1.str_notify);
    self thread scripts\zm\zm_island_challenges::function_2ce855f3(self._challenges.challenge_2.n_index, self._challenges.challenge_2.func_think, self._challenges.challenge_2.n_count, self._challenges.challenge_2.str_notify);
    self thread scripts\zm\zm_island_challenges::function_2ce855f3(self._challenges.challenge_3.n_index, self._challenges.challenge_3.func_think, self._challenges.challenge_3.n_count, self._challenges.challenge_3.str_notify);
    self thread scripts\zm\zm_island_challenges::function_fbbc8608(self._challenges.challenge_1.n_index, "flag_player_completed_challenge_1");
    self thread scripts\zm\zm_island_challenges::function_fbbc8608(self._challenges.challenge_2.n_index, "flag_player_completed_challenge_2");
    self thread scripts\zm\zm_island_challenges::function_fbbc8608(self._challenges.challenge_3.n_index, "flag_player_completed_challenge_3");
    self thread scripts\zm\zm_island_challenges::function_974d5f1d();
    challenge_indices = [];
    look_at_points = [];

    for (i = 1; i < 4; i++)
    {
        foreach (look_at in getentarray("t_lookat_challenge_" + i, "targetname"))
        {
            if (look_at.script_special == board_number)
            {
                look_at_points[i] = look_at;
            }
        }

        challenge_indices[i] = i;
        self thread scripts\zm\zm_island_challenges::function_7fc84e9c(board_number, challenge_indices[i]);
        self thread scripts\zm\zm_island_challenges::function_e43d4636(board_number, challenge_indices[i]);
    }

    foreach (challenge_trigger in scripts\codescripts\struct::get_array("s_challenge_trigger"))
    {
        if (challenge_trigger.script_special == board_number)
        {
            challenge_trigger scripts\zm\zm_island_challenges::function_72a5d5e5(player_number, challenge_indices, look_at_points);
        }
    }
}

// The Pack-a-Punch valve defense switches on players.size with no case above
// 4, leaving its simultaneous-enemy limit undefined. Preserve the stock
// event and use its 4-player limit for 5-8 players.
detour scripts\zm\zm_island_pap_quest::defend_start()
{
    while (!level scripts\shared\flag_shared::exists("penstock_debris_cleared"))
    {
        wait 1;
    }

    spawn_points = scripts\codescripts\struct::get_array("defend_valve_spawnpt");
    level.var_74049442 = 0;
    player_count = level.players.size;

    if (player_count > 4)
    {
        player_count = 4;
    }

    enemy_limit = 8;

    if (player_count == 2)
    {
        enemy_limit = 10;
    }
    else if (player_count == 3)
    {
        enemy_limit = 14;
    }
    else if (player_count == 4)
    {
        enemy_limit = 18;
    }

    level scripts\shared\flag_shared::wait_till("penstock_debris_cleared");
    level.mdl_gate.v_org = level.mdl_gate.origin;
    level.mdl_gate.v_pos = scripts\codescripts\struct::get(level.mdl_gate.target).origin;
    level.mdl_clip solid();
    level.mdl_clip disconnectpaths();
    level.mdl_gate moveto(level.mdl_gate.v_pos, 3);
    level.mdl_gate playsound("zmb_papquest_defend_gate_close");
    scripts\shared\exploder_shared::exploder("fxexp_202");
    level.disable_nuke_delay_spawning = 1;
    level scripts\shared\flag_shared::clear("spawn_zombies");
    level thread scripts\zm\zm_island_pap_quest::function_03d4e00c();
    scripts\shared\exploder_shared::exploder("lgt_penstock_event");

    while (level.var_74049442 < 13)
    {
        spawn_points = scripts\shared\array_shared::randomize(spawn_points);

        for (i = 0; i < spawn_points.size; i++)
        {
            while (getfreeactorcount() < 1)
            {
                wait 0.05;
            }

            while (scripts\zm\zm_island_pap_quest::function_0a3ebebe() >= enemy_limit)
            {
                wait 0.05;
            }

            zombie = scripts\shared\ai\zombie_utility::spawn_zombie(level.zombie_spawners[0], "defend_zombie", spawn_points[i]);

            if (isdefined(zombie))
            {
                if (isdefined(spawn_points[i].script_int))
                {
                    zombie.var_57b55f08 = 1;
                }

                zombie thread scripts\zm\zm_island_pap_quest::function_2392e644();
                level.var_74049442++;

                if (level.var_74049442 >= 13)
                {
                    break;
                }

                wait 1.5;
            }
        }

        wait 0.1;
    }
}

// Every outdoor Skull ritual has three local balance arrays indexed by
// activeplayers.size and sized only for 1-4. This is the stock routine with
// those lookups clamped to the 4-player values.
detour scripts\zm\zm_island_skullweapon_quest::function_ff1550bd()
{
    self endon("skullquest_ritual_abandoned" + self.script_special);
    level endon("skullquest_ritual_ended" + self.script_special);
    ritual_index = self.script_special;
    self.var_bd61ef5b = 0;
    self.var_d38f69da = [];
    self.var_41335b73 = [];
    attacker_name = ("skull" + ritual_index) + "_attacker";
    ritual_spawners = [];
    zombie_spawners = level.zombie_spawners;
    spider_spawners = level.var_feebf312;
    thrasher_spawners = level.var_c38a4fee;

    if (level.var_04ffafd2 > 0)
    {
        ritual_number = level.var_04ffafd2;
    }
    else
    {
        ritual_number = 0;

        for (i = 1; i <= 4; i++)
        {
            if (level scripts\shared\flag_shared::get("skullquest_ritual_complete" + i) || level scripts\shared\flag_shared::get("skullquest_ritual_inprogress" + i))
            {
                ritual_number++;
            }
        }
    }

    switch (ritual_number)
    {
        case 1:
        {
            ritual_spawners = zombie_spawners;
            max_attackers = array(0, 3, 4, 5, 6);
            max_zombies = array(0, 3, 4, 5, 6);
            self.var_9543b4d3 = 2;
            self.var_7905a128 = 0;
            break;
        }
        case 2:
        {
            ritual_spawners = array(thrasher_spawners[0], thrasher_spawners[0], thrasher_spawners[0], thrasher_spawners[0]);
            max_attackers = array(0, 6, 7, 8, 9);
            max_zombies = array(0, 4, 5, 6, 7);
            self.var_9543b4d3 = 2;
            self.var_7905a128 = 0;
            break;
        }
        case 3:
        {
            ritual_spawners = array(spider_spawners[0], spider_spawners[0], spider_spawners[0], spider_spawners[0]);
            max_attackers = array(0, 6, 7, 8, 9);
            max_zombies = array(0, 4, 5, 6, 7);
            self.var_9543b4d3 = 2;
            self.var_7905a128 = 1;
            break;
        }
        case 4:
        {
            ritual_spawners = array(thrasher_spawners[0], thrasher_spawners[0], thrasher_spawners[0], spider_spawners[0]);
            max_attackers = array(0, 6, 7, 8, 9);
            max_zombies = array(0, 4, 5, 6, 7);
            self.var_9543b4d3 = 2;
            self.var_7905a128 = 0;
            break;
        }
    }

    player_count = level.activeplayers.size;

    if (player_count > 4)
    {
        player_count = 4;
    }

    attacker_limit = max_attackers[player_count];
    zombie_limit = max_zombies[player_count];
    self.var_eca4fee1 = attacker_limit;
    level.zombie_ai_limit = level.zombie_ai_limit - self.var_eca4fee1;
    thrasher_limits = array(0, 1, 1, 1, 1);
    thrasher_limit = thrasher_limits[player_count];
    self.a_s_spawnpts = scripts\shared\array_shared::randomize(self.a_s_spawnpts);
    self.var_0d8cdf3a = 1;

    while (!level scripts\shared\flag_shared::get("skullquest_ritual_complete" + self.script_special))
    {
        for (i = 0; i < self.a_s_spawnpts.size; i++)
        {
            level.var_a576e0b9[ritual_index].var_41335b73 = scripts\shared\array_shared::remove_undefined(level.var_a576e0b9[ritual_index].var_41335b73);
            level.var_a576e0b9[ritual_index].var_d38f69da = scripts\shared\array_shared::remove_undefined(level.var_a576e0b9[ritual_index].var_d38f69da);

            while (getfreeactorcount() < 1)
            {
                wait 0.05;
            }

            while (level.var_a576e0b9[ritual_index].var_d38f69da.size >= attacker_limit)
            {
                wait 0.05;
            }

            if (isdefined(self.var_7905a128) && self.var_7905a128 == 1 && self.var_bd61ef5b == 0)
            {
                spawner = thrasher_spawners[0];
            }
            else if ((isdefined(self.var_0d8cdf3a) && self.var_0d8cdf3a) || level.var_a576e0b9[ritual_index].var_41335b73.size < 2)
            {
                spawner = zombie_spawners[0];
            }
            else
            {
                spawner = scripts\shared\array_shared::random(ritual_spawners);
            }

            self.var_0d8cdf3a = !self.var_0d8cdf3a;
            attacker = undefined;
            self.a_s_spawnpts[i].script_string = "";

            if (isdefined(spawner) && isdefined(spawner.script_noteworthy))
            {
                if (spawner.script_noteworthy == "zombie_spawner")
                {
                    if (level.var_a576e0b9[ritual_index].var_41335b73.size < zombie_limit)
                    {
                        self.a_s_spawnpts[i].script_string = "find_flesh";
                        self.a_s_spawnpts[i].script_noteworthy = "spawn_location";
                        attacker = scripts\shared\ai\zombie_utility::spawn_zombie(spawner, attacker_name, self.a_s_spawnpts[i]);
                    }
                }
                else if (spawner.script_noteworthy == "zombie_thrasher_spawner")
                {
                    if (level.var_a576e0b9[ritual_index].var_bd61ef5b < thrasher_limit)
                    {
                        self.a_s_spawnpts[i].script_noteworthy = "thrasher_location";
                        attacker = scripts\shared\ai\zombie_utility::spawn_zombie(spawner, attacker_name);
                    }
                }
                else if (spawner.script_noteworthy == "zombie_spider_spawner")
                {
                    self.a_s_spawnpts[i].script_noteworthy = "spider_location";
                    attacker = scripts\shared\ai\zombie_utility::spawn_zombie(spawner, attacker_name, self.a_s_spawnpts[i]);
                }

                wait 0.1;
            }

            if (isalive(attacker))
            {
                attacker.var_ecc789a5 = ritual_index;
                scripts\shared\array_shared::add(level.var_a576e0b9[ritual_index].var_d38f69da, attacker);
                attacker.ignore_enemy_count = 1;
                attacker.no_damage_points = 1;
                attacker.deathpoints_already_given = 1;

                if (spawner.script_noteworthy == "zombie_spawner")
                {
                    attacker forceteleport(self.a_s_spawnpts[i].origin, self.a_s_spawnpts[i].angles);

                    if (attacker.health > 1263)
                    {
                        attacker.maxhealth = 1263;
                        attacker.health = 1263;
                    }

                    attacker thread zm_island_skullquest::function_bd5d2a96(self);
                }
                else if (spawner.script_noteworthy == "zombie_thrasher_spawner")
                {
                    attacker zm_ai_thrasher::function_89976d94(self.a_s_spawnpts[i].origin);
                    self.var_bd61ef5b++;
                    attacker scripts\shared\clientfield_shared::set("ritual_attacker_fx", 1);
                    attacker.var_75729ddd = 1;
                }
                else if (spawner.script_noteworthy == "zombie_spider_spawner")
                {
                    attacker.favoriteenemy = zm_ai_spiders::get_favorite_enemy();
                    self.a_s_spawnpts[i] thread zm_ai_spiders::function_49e57a3b(attacker, self.a_s_spawnpts[i]);
                }

                attacker thread zm_island_skullquest::function_c46730e7(self.script_special);
                attacker thread zm_island_util::function_acd04dc9();
                wait(self.var_9543b4d3);
            }

            level.zombie_ai_limit = level.zombie_ai_limit + self.var_eca4fee1;
            player_count = level.activeplayers.size;

            if (player_count > 4)
            {
                player_count = 4;
            }

            attacker_limit = max_attackers[player_count];
            self.var_eca4fee1 = attacker_limit;
            level.zombie_ai_limit = level.zombie_ai_limit - self.var_eca4fee1;
        }

        wait(self.var_9543b4d3);
    }
}

// The final Skull-room defense has two more 1-4 player arrays. Retain its
// complete stock sequence and use four-player pacing for larger lobbies.
detour scripts\zm\zm_island_skullweapon_quest::function_ef5b1df5()
{
    active_limits = array(0, 3, 5, 7, 8);
    total_limits = array(0, 20, 29, 38, 47);
    player_count = level.players.size;

    if (player_count > 4)
    {
        player_count = 4;
    }

    level.var_d15b7db3 = active_limits[player_count];
    level.var_49c6fb1c = total_limits[player_count];
    level.zombie_ai_limit = level.zombie_ai_limit - level.var_d15b7db3;
    level scripts\shared\flag_shared::clear("spawn_zombies");
    level.disable_nuke_delay_spawning = 1;
    level.var_92914699 = 0;
    level.var_9bc0cd6e = 0;
    keeper_spawner = getent("skullroom_keeper_spawner", "targetname");
    level.var_55c48492 scripts\shared\clientfield_shared::set("skullquest_finish_start_fx", 1);
    level.var_55c48492 scripts\shared\clientfield_shared::set("skullquest_finish_trail_fx", 1);
    level thread zm_island_skullquest::function_41b94a87();
    wait 0.25;
    level scripts\shared\clientfield_shared::set("keeper_spawn_portals", 1);
    wait 2.5;
    spawn_points = scripts\codescripts\struct::get_array("s_spawnpt_skullroom");
    level scripts\shared\flag_shared::clear("skullroom_empty_of_players");
    spawned = [];
    level thread zm_island_skullquest::function_d91adba6();
    spawn_points = scripts\shared\array_shared::randomize(spawn_points);

    while (level.var_9bc0cd6e < level.var_49c6fb1c && !level scripts\shared\flag_shared::get("skullroom_empty_of_players") && (!(isdefined(level.var_d9d19dae) && level.var_d9d19dae)))
    {
        for (i = 0; i < spawn_points.size; i++)
        {
            spawn_point = spawn_points[i];

            while (getfreeactorcount() < 1 && !level scripts\shared\flag_shared::get("skullroom_empty_of_players") && (!(isdefined(level.var_d9d19dae) && level.var_d9d19dae)))
            {
                wait 0.05;
            }

            while (level.var_92914699 >= level.var_d15b7db3 && !level scripts\shared\flag_shared::get("skullroom_empty_of_players") && (!(isdefined(level.var_d9d19dae) && level.var_d9d19dae)))
            {
                wait 0.05;
            }

            if (level.var_9bc0cd6e >= level.var_49c6fb1c || level scripts\shared\flag_shared::get("skullroom_empty_of_players") || (isdefined(level.var_d9d19dae) && level.var_d9d19dae))
            {
                break;
            }

            spawn_point.script_string = "find_flesh";
            zombie = scripts\shared\ai\zombie_utility::spawn_zombie(keeper_spawner, "skullroom_keeper_zombie", spawn_point);

            if (isdefined(zombie))
            {
                level.var_92914699++;
                zombie.var_2f846873 = 1;
                zombie.targetname = "skullroom_keeper_zombie";
                zombie thread zm_island_skullquest::function_2d0c5aa1(spawn_point);
                level thread zm_island_skullquest::function_efbd4abf(zombie, spawn_point);
                zombie.custom_location = &zm_island_skullquest::function_b820cada;
                scripts\shared\array_shared::add(spawned, zombie);
            }

            wait 1;
        }
    }

    level scripts\shared\flag_shared::clear("skullroom_defend_inprogress");
    level scripts\shared\clientfield_shared::set("keeper_spawn_portals", 0);
    level.var_55c48492 scripts\shared\clientfield_shared::set("skullquest_finish_start_fx", 0);
    level.var_55c48492 scripts\shared\clientfield_shared::set("skullquest_finish_trail_fx", 0);
    level.var_b10ab148 = level.var_9bc0cd6e >= level.var_49c6fb1c;
    level scripts\shared\flag_shared::set("skull_quest_complete");

    if (isdefined(level.var_b10ab148) && level.var_b10ab148)
    {
        no_teleport_volume = getent("volume_thrasher_non_teleport_ruins_underground", "targetname");
        no_teleport_volume delete();
        level.var_55c48492 thread zm_island_skullquest::function_85a2a491();
    }

    spawned = scripts\shared\array_shared::remove_dead(spawned, 0);

    for (i = 0; i < spawned.size; i++)
    {
        if (isalive(spawned[i]))
        {
            spawned[i] kill();
        }
    }

    level.var_55c48492 playsound("evt_keeper_quest_done");
    wait 1.5;
    level.var_55c48492 moveto(level.var_55c48492.var_5cd7e450, 0.5);
    level.zombie_ai_limit = level.zombie_ai_limit + level.var_d15b7db3;
    level scripts\shared\flag_shared::set("spawn_zombies");
    level.disable_nuke_delay_spawning = 0;
}

// Each Takeo boss wave stores three balance arrays indexed 1-4. Clamp the
// index only; all active players remain in the arena and can participate.
detour scripts\zm\zm_island_takeo_fight::function_b96762d3()
{
    player_count = level.activeplayers.size;

    if (player_count > 4)
    {
        player_count = 4;
    }

    self.var_44da5f74 = self.var_6033a1e7[player_count];
    self.var_1fcf1bc4 = self.var_ce1421d3[player_count];
    self.var_fc3dea41 = self.var_2e486eac[player_count];

    if (isdefined(self.var_eca4fee1) && self.var_eca4fee1 > 0)
    {
        level.zombie_ai_limit = level.zombie_ai_limit + self.var_eca4fee1;
    }

    self.var_eca4fee1 = (self.var_44da5f74 + self.var_1fcf1bc4) + self.var_fc3dea41;
    level.zombie_ai_limit = level.zombie_ai_limit - self.var_eca4fee1;
}

// The boss rescue teleport has four destinations and indexes them by the
// repeating character index. Keep the stock destination, but place the
// second set of index twins one body-width to the right.
detour scripts\zm\zm_island_takeo_fight::function_75275516()
{
    scripts\zm\_zm_utility::increment_ignoreme();
    playsoundatposition("zmb_bgb_abh_teleport_out", self.origin);
    teleport_spots = scripts\codescripts\struct::get_array("s_takeofight_player_teleport", "targetname");
    respawn_spot = teleport_spots[self.characterindex];
    destination = respawn_spot.origin;
    active_slot = 0;

    for (i = 0; i < level.activeplayers.size; i++)
    {
        if (level.activeplayers[i] == self)
        {
            active_slot = i;
            break;
        }
    }

    if (active_slot >= 4)
    {
        destination = destination + vectorscale(anglestoright(respawn_spot.angles), 64);
    }

    self hide();
    self setorigin(destination);
    self freezecontrols(1);
    return_position = self.origin + vectorscale((0, 0, 1), 60);
    enemies = getaiteamarray(level.zombie_team);
    closest_enemies = [];
    closest = undefined;

    if (enemies.size > 0)
    {
        closest_enemies = arraysortclosest(enemies, self.origin);

        for (i = 0; i < closest_enemies.size; i++)
        {
            trace_value = closest_enemies[i] sightconetrace(return_position, self);

            if (trace_value > 0.2)
            {
                closest = closest_enemies[i];
                break;
            }
        }

        if (isdefined(closest))
        {
            self setplayerangles(vectortoangles(closest getcentroid() - return_position));
        }
    }

    self playsound("zmb_bgb_abh_teleport_in");
    wait 0.5;
    self show();
    self util::clientnotify("sndFBM");
    playfx(level._effect["teleport_splash"], self.origin);
    playfx(level._effect["teleport_aoe"], self.origin);
    enemies = getaiarray();
    nearby = arraysortclosest(enemies, self.origin, enemies.size, 0, 200);

    for (i = 0; i < nearby.size; i++)
    {
        enemy = nearby[i];

        if (!isactor(enemy))
        {
            continue;
        }

        if (enemy.archetype === "zombie")
        {
            playfx(level._effect["teleport_aoe_kill"], enemy gettagorigin("j_spineupper"));
        }
        else
        {
            playfx(level._effect["teleport_aoe_kill"], enemy.origin);
        }

        enemy.marked_for_recycle = 1;
        enemy.has_been_damaged_by_player = 0;
        enemy dodamage(enemy.health + 1000, self.origin, self);
    }

    wait 0.2;
    self freezecontrols(0);
    wait 3;
    scripts\zm\_zm_utility::decrement_ignoreme();
}
