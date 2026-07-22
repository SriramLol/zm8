// zm8 - Der Eisendrache (zm_castle) two-player bow-team helper
//
// Stock DE has one global coroutine, owner entity, flag set and physical
// arrow/pedestal for each elemental bow. Running two independent copies of
// one bow quest would make those globals race. Instead, two players share the
// stock quest state and actively contribute kills, shots, plates, urns,
// circles, runes, escort souls and pickups. The one active-owner role remains
// authoritative for unique arrow/reforge/place transitions and can be handed
// to the teammate at that bow's final pyramid pedestal. Stock quest_swap
// reconstructs the current interaction without resetting completed stages.

#using scripts\codescripts\struct;
#using scripts\shared\array_shared;
#using scripts\shared\clientfield_shared;
#using scripts\shared\exploder_shared;
#using scripts\shared\flag_shared;
#using scripts\shared\scene_shared;
#using scripts\shared\util_shared;
#using scripts\zm\_zm_audio;
#using scripts\zm\_zm_powerup_castle_demonic_rune;
#using scripts\zm\_zm_powerups;
#using scripts\zm\_zm_spawner;
#using scripts\zm\_zm_unitrigger;
#using scripts\zm\_zm_utility;
#using scripts\zm\_zm_weap_elemental_bow;
#using scripts\zm\zm_castle_ee_bossfight;
#using scripts\zm\zm_castle_vo;
#using scripts\zm\zm_castle_weap_quest_upgrade;

// The boss ritual has four physical Ragnarok pads, but stock waits for its
// claimed-pad count to equal every connected player (including spectators).
// Preserve the simultaneous real-plant ritual: every living participant is
// required up to the four authored pads, and four real pads are required for
// a 5-8 player group. No flag or quest stage is skipped.
detour scripts\zm\zm_castle_ee_bossfight::boss_fight_ready()
{
    level endon(#"boss_fight_begin");
    level.var_b366f2dc = 0;
    pads = getentarray("boss_gravity_spike_start_area", "targetname");

    foreach (pad in pads)
    {
        pad.b_claimed = 0;
        pad thread scripts\zm\zm_castle_ee_bossfight::function_1c249965();
    }

    required = 0;

    while (required < 1 || level.var_b366f2dc < required)
    {
        required = 0;
        players = getplayers();

        for (i = 0; i < players.size; i++)
        {
            if (isdefined(players[i]) && isalive(players[i]) && players[i].sessionstate == "playing")
            {
                required++;
            }
        }

        if (required > pads.size)
        {
            required = pads.size;
        }

        wait 0.05;
    }

    wait 0.75;

    foreach (player in level.players)
    {
        player.var_d725b0f2 = undefined;
    }

    level scripts\shared\flag_shared::set("boss_fight_begin");
}

function zm8_de_is_bow_team_contributor(player, element)
{
    if (!isdefined(player) || !isalive(player) || player.sessionstate != "playing")
    {
        return false;
    }

    owner = zm8_de_bow_owner(element);

    if (isdefined(owner) && owner === player)
    {
        return true;
    }

    return isdefined(player.zm8_de_bow_team) && player.zm8_de_bow_team == element;
}

function zm8_de_element_for_owner(owner)
{
    if (!isdefined(owner))
    {
        return undefined;
    }

    if (isdefined(level.var_f8d1dc16) && owner === level.var_f8d1dc16)
    {
        return "storm";
    }

    if (isdefined(level.var_6e68c0d8) && owner === level.var_6e68c0d8)
    {
        return "demon_gate";
    }

    if (isdefined(level.var_c62829c7) && owner === level.var_c62829c7)
    {
        return "rune_prison";
    }

    if (isdefined(level.var_52978d72) && owner === level.var_52978d72)
    {
        return "wolf_howl";
    }

    return undefined;
}

function zm8_de_attacker_matches_bow_team(attacker, owner)
{
    if (!isdefined(attacker) || !isdefined(owner))
    {
        return false;
    }

    if (attacker === owner)
    {
        return true;
    }

    element = zm8_de_element_for_owner(owner);
    return isdefined(element) && zm8_de_is_bow_team_contributor(attacker, element);
}

function zm8_de_projectile_watch(target, element, event_name)
{
    self endon("disconnect");
    target endon("zm8_stop_projectile_watch");
    stage_owner = zm8_de_bow_owner(element);

    if (isdefined(stage_owner))
    {
        stage_owner endon("death");
        stage_owner endon("quest_swap");
    }

    while (true)
    {
        self waittill("projectile_impact", weapon, point, radius, projectile, normal);

        if (zm8_de_is_bow_team_contributor(self, element))
        {
            target notify(event_name, self, weapon, point, radius, projectile, normal);
        }
    }
}

function zm8_de_missile_watch(target, element, event_name)
{
    self endon("disconnect");
    target endon("zm8_stop_missile_watch");
    stage_owner = zm8_de_bow_owner(element);

    if (isdefined(stage_owner))
    {
        stage_owner endon("death");
        stage_owner endon("quest_swap");
    }

    while (true)
    {
        self waittill("missile_fire", projectile, weapon);

        if (zm8_de_is_bow_team_contributor(self, element))
        {
            target notify(event_name, self, projectile, weapon);
        }
    }
}

// Refreshers use integer entity numbers rather than retaining a persistent
// array of player entities. The actual watcher owns the short-lived entity
// reference and ends immediately on death/disconnect or stage cleanup.
function zm8_de_refresh_projectile_watchers(element, event_name)
{
    self endon("zm8_stop_projectile_watch");
    stage_owner = zm8_de_bow_owner(element);

    if (isdefined(stage_owner))
    {
        stage_owner endon("death");
        stage_owner endon("quest_swap");
    }

    watched = [];

    while (true)
    {
        players = getplayers();

        for (i = 0; i < players.size; i++)
        {
            player = players[i];
            entnum = player getentitynumber();

            if (zm8_de_is_bow_team_contributor(player, element) && !isdefined(watched[entnum]))
            {
                watched[entnum] = true;
                player thread zm8_de_projectile_watch(self, element, event_name);
            }
        }

        wait 0.25;
    }
}

function zm8_de_refresh_missile_watchers(element, event_name)
{
    self endon("zm8_stop_missile_watch");
    stage_owner = zm8_de_bow_owner(element);

    if (isdefined(stage_owner))
    {
        stage_owner endon("death");
        stage_owner endon("quest_swap");
    }

    watched = [];

    while (true)
    {
        players = getplayers();

        for (i = 0; i < players.size; i++)
        {
            player = players[i];
            entnum = player getentitynumber();

            if (zm8_de_is_bow_team_contributor(player, element) && !isdefined(watched[entnum]))
            {
                watched[entnum] = true;
                player thread zm8_de_missile_watch(self, element, event_name);
            }
        }

        wait 0.25;
    }
}

autoexec function zm8_castle_bow_teams_init()
{
    level endon("end_game");
    level.zm8_de_bow_join_order = 0;

    // Let the map's script structs and stock bow quest initialize first.
    wait 1;
    level thread zm8_de_create_team_pedestal("storm", "upgraded_bow_struct_elemental_storm");
    level thread zm8_de_create_team_pedestal("demon_gate", "upgraded_bow_struct_demon_gate");
    level thread zm8_de_create_team_pedestal("rune_prison", "upgraded_bow_struct_rune_prison");
    level thread zm8_de_create_team_pedestal("wolf_howl", "upgraded_bow_struct_wolf_howl");
    level thread zm8_de_bow_team_monitor();
    println("zm8: DE two-player shared bow teams loaded");
}

function zm8_de_bow_label(element)
{
    if (element == "storm")
    {
        return "LIGHTNING";
    }

    if (element == "demon_gate")
    {
        return "FIRE";
    }

    if (element == "rune_prison")
    {
        return "VOID";
    }

    return "WOLF";
}

function zm8_de_bow_owner(element)
{
    if (element == "storm")
    {
        return level.var_f8d1dc16;
    }

    if (element == "demon_gate")
    {
        return level.var_6e68c0d8;
    }

    if (element == "rune_prison")
    {
        return level.var_c62829c7;
    }

    return level.var_52978d72;
}

function zm8_de_bow_team_members(element)
{
    members = [];
    players = getplayers();

    for (i = 0; i < players.size; i++)
    {
        player = players[i];

        if (isdefined(player) && isdefined(player.zm8_de_bow_team) && player.zm8_de_bow_team == element)
        {
            members[members.size] = player;
        }
    }

    return members;
}

function zm8_de_player_is_other_bow_owner(player, wanted_element)
{
    elements = [];
    elements[0] = "storm";
    elements[1] = "demon_gate";
    elements[2] = "rune_prison";
    elements[3] = "wolf_howl";

    for (i = 0; i < elements.size; i++)
    {
        if (elements[i] == wanted_element)
        {
            continue;
        }

        owner = zm8_de_bow_owner(elements[i]);

        if (isdefined(owner) && owner === player)
        {
            return true;
        }
    }

    return false;
}

function zm8_de_assign_bow_team(player, element)
{
    if (!isdefined(player))
    {
        return;
    }

    level.zm8_de_bow_join_order++;
    player.zm8_de_bow_team = element;
    player.zm8_de_bow_join_order = level.zm8_de_bow_join_order;
    player.zm8_de_bow_hud_state = undefined;
}

function zm8_de_clear_bow_team(player, message)
{
    if (!isdefined(player))
    {
        return;
    }

    player.zm8_de_bow_team = undefined;
    player.zm8_de_bow_join_order = undefined;
    player.zm8_de_bow_hud_state = undefined;

    if (isdefined(player.zm8_de_bow_hud))
    {
        player.zm8_de_bow_hud destroy();
        player.zm8_de_bow_hud = undefined;
    }

    if (isdefined(message))
    {
        player iprintlnbold(message);
    }
}

// A legitimate stock quest starter always wins the active slot. If two
// players pre-reserved that bow, evict the most recent reservation so the
// real starter and the first reservation become its two-person team.
function zm8_de_enroll_stock_owner(owner, element)
{
    if (!isdefined(owner))
    {
        return;
    }

    if (isdefined(owner.zm8_de_bow_team) && owner.zm8_de_bow_team == element)
    {
        return;
    }

    members = zm8_de_bow_team_members(element);

    if (members.size >= 2)
    {
        latest = undefined;
        latest_order = -1;

        for (i = 0; i < members.size; i++)
        {
            order = 0;

            if (isdefined(members[i].zm8_de_bow_join_order))
            {
                order = members[i].zm8_de_bow_join_order;
            }

            if (order > latest_order)
            {
                latest = members[i];
                latest_order = order;
            }
        }

        if (isdefined(latest))
        {
            zm8_de_clear_bow_team(latest, "^3zm8: bow-team reservation replaced by the quest starter");
        }
    }

    if (isdefined(owner.zm8_de_bow_team) && owner.zm8_de_bow_team != element)
    {
        owner iprintlnbold("^3zm8: moved to the bow quest you legitimately started");
    }

    zm8_de_assign_bow_team(owner, element);
    owner iprintlnbold("^2zm8: " + zm8_de_bow_label(element) + " BOW TEAM - ACTIVE RUNNER");
}

function zm8_de_bow_hud_text(element, role)
{
    if (element == "storm")
    {
        if (role == "active") return "LIGHTNING TEAM - ACTIVE";
        if (role == "partner") return "LIGHTNING TEAM - PARTNER";
        return "LIGHTNING TEAM - WAITING";
    }

    if (element == "demon_gate")
    {
        if (role == "active") return "FIRE TEAM - ACTIVE";
        if (role == "partner") return "FIRE TEAM - PARTNER";
        return "FIRE TEAM - WAITING";
    }

    if (element == "rune_prison")
    {
        if (role == "active") return "VOID TEAM - ACTIVE";
        if (role == "partner") return "VOID TEAM - PARTNER";
        return "VOID TEAM - WAITING";
    }

    if (role == "active") return "WOLF TEAM - ACTIVE";
    if (role == "partner") return "WOLF TEAM - PARTNER";
    return "WOLF TEAM - WAITING";
}

function zm8_de_update_bow_team_hud(player)
{
    if (!isdefined(player) || !isdefined(player.zm8_de_bow_team))
    {
        return;
    }

    element = player.zm8_de_bow_team;
    owner = zm8_de_bow_owner(element);
    role = "waiting";

    if (isdefined(owner))
    {
        if (owner === player)
        {
            role = "active";
        }
        else
        {
            role = "partner";
        }
    }

    state = element + "_" + role;

    if (!isdefined(player.zm8_de_bow_hud))
    {
        player.zm8_de_bow_hud = newclienthudelem(player);
        player.zm8_de_bow_hud.alignx = "center";
        player.zm8_de_bow_hud.aligny = "top";
        player.zm8_de_bow_hud.horzalign = "center";
        player.zm8_de_bow_hud.vertalign = "user_top";
        player.zm8_de_bow_hud.x = 0;
        player.zm8_de_bow_hud.y = 72;
        player.zm8_de_bow_hud.fontscale = 1.15;
        player.zm8_de_bow_hud.color = (0.55, 0.8, 1);
        player.zm8_de_bow_hud.alpha = 0.9;
        player.zm8_de_bow_hud.sort = 100;
        player.zm8_de_bow_hud.hidewheninmenu = true;
    }

    if (!isdefined(player.zm8_de_bow_hud_state) || player.zm8_de_bow_hud_state != state)
    {
        player.zm8_de_bow_hud settext(zm8_de_bow_hud_text(element, role));
        player.zm8_de_bow_hud_state = state;
    }
}

function zm8_de_bow_team_monitor()
{
    level endon("end_game");
    elements = [];
    elements[0] = "storm";
    elements[1] = "demon_gate";
    elements[2] = "rune_prison";
    elements[3] = "wolf_howl";

    while (true)
    {
        if (isdefined(level.zm8_de_bot_lightning_request))
        {
            bot = level.zm8_de_bot_lightning_request;
            level.zm8_de_bot_lightning_request = undefined;
            level thread zm8_de_handle_bot_lightning_request(bot);
        }

        for (i = 0; i < elements.size; i++)
        {
            owner = zm8_de_bow_owner(elements[i]);

            if (isdefined(owner))
            {
                zm8_de_enroll_stock_owner(owner, elements[i]);
            }
        }

        players = getplayers();

        for (i = 0; i < players.size; i++)
        {
            if (isdefined(players[i].zm8_de_bow_team))
            {
                zm8_de_update_bow_team_hud(players[i]);

                if (players[i].zm8_de_bow_team == "storm" &&
                    zm8_de_bow_flag_set("elemental_storm_batteries") &&
                    !zm8_de_bow_flag_set("elemental_storm_beacons_charged") &&
                    (!(isdefined(players[i].zm8_storm_charge_watch) && players[i].zm8_storm_charge_watch)))
                {
                    players[i] thread zm8_de_storm_charge_urn_watch();
                }
            }
        }

        wait 0.25;
    }
}

// Testing bridge requested by the universal command script. Keep the
// current stock owner until quest_swap has rebuilt the live interaction for
// the bot, then clear everyone else from the team. The human host can now
// use the custom Lightning box trigger once and exercise the real join path.
function zm8_de_handle_bot_lightning_request(bot)
{
    level endon("end_game");

    if (!isdefined(bot) || !isalive(bot) || bot.sessionstate != "playing" ||
        !isdefined(bot.pers) || !isdefined(bot.pers["isBot"]) || !bot.pers["isBot"])
    {
        level.zm8_de_botlightning_running = false;
        iprintlnbold("^1zm8: Lightning bot handoff failed - bot is no longer alive");
        return;
    }

    old_owner = zm8_de_bow_owner("storm");

    if (!isdefined(old_owner))
    {
        level.zm8_de_botlightning_running = false;
        iprintlnbold("^1zm8: Lightning bot handoff failed - stock quest has no owner");
        return;
    }

    if (zm8_de_player_is_other_bow_owner(bot, "storm"))
    {
        level.zm8_de_botlightning_running = false;
        iprintlnbold("^1zm8: Lightning bot handoff failed - bot owns another bow quest");
        return;
    }

    // If a previous test already filled the two-person team, preserve the
    // active stock owner until transfer and free the other reservation.
    members = zm8_de_bow_team_members("storm");

    for (i = 0; i < members.size; i++)
    {
        if (!(members[i] === bot) && !(members[i] === old_owner))
        {
            zm8_de_clear_bow_team(members[i], "^3zm8: reservation cleared for bot join test");
        }
    }

    if (!isdefined(bot.zm8_de_bow_team) || bot.zm8_de_bow_team != "storm")
    {
        zm8_de_assign_bow_team(bot, "storm");
    }

    success = zm8_de_transfer_bow_owner(bot, "storm");

    if (!success)
    {
        level.zm8_de_botlightning_running = false;
        iprintlnbold("^1zm8: Lightning bot handoff timed out");
        return;
    }

    members = zm8_de_bow_team_members("storm");

    for (i = 0; i < members.size; i++)
    {
        if (!(members[i] === bot))
        {
            zm8_de_clear_bow_team(members[i], "^3zm8: left Lightning team for bot join test");
        }
    }

    level.zm8_de_botlightning_running = false;
    iprintlnbold("^2zm8: bot is Lightning ACTIVE - use the Lightning box once to join");
    println("zm8: bot Lightning owner ready; host may test the undercroft team join trigger");
}

function zm8_de_bow_flag_set(flag_name)
{
    return isdefined(level.flag) && isdefined(level.flag[flag_name]) && level.flag[flag_name];
}

function zm8_de_transfer_struct(element)
{
    if (element == "storm")
    {
        if (zm8_de_bow_flag_set("elemental_storm_placed"))
        {
            return scripts\codescripts\struct::get("upgraded_bow_struct_elemental_storm", "targetname");
        }

        if (zm8_de_bow_flag_set("elemental_storm_repaired"))
        {
            return scripts\codescripts\struct::get("quest_reforge_elemental_storm");
        }

        return scripts\codescripts\struct::get("quest_start_elemental_storm");
    }

    if (element == "demon_gate")
    {
        if (zm8_de_bow_flag_set("demon_gate_placed"))
        {
            return scripts\codescripts\struct::get("upgraded_bow_struct_demon_gate", "targetname");
        }

        if (zm8_de_bow_flag_set("demon_gate_repaired"))
        {
            return scripts\codescripts\struct::get("quest_reforge_demon_gate");
        }

        return scripts\codescripts\struct::get("quest_start_demon_gate");
    }

    if (element == "rune_prison")
    {
        if (zm8_de_bow_flag_set("rune_prison_placed"))
        {
            return scripts\codescripts\struct::get("upgraded_bow_struct_rune_prison", "targetname");
        }

        if (zm8_de_bow_flag_set("rune_prison_repaired"))
        {
            return scripts\codescripts\struct::get("quest_reforge_rune_prison");
        }

        return scripts\codescripts\struct::get("quest_start_rune_prison");
    }

    if (zm8_de_bow_flag_set("wolf_howl_placed"))
    {
        return scripts\codescripts\struct::get("upgraded_bow_struct_wolf_howl", "targetname");
    }

    if (zm8_de_bow_flag_set("wolf_howl_repaired"))
    {
        return scripts\codescripts\struct::get("quest_reforge_wolf_howl");
    }

    return scripts\codescripts\struct::get("quest_start_wolf_howl");
}

function zm8_de_transfer_bow_owner(player, element)
{
    old_owner = zm8_de_bow_owner(element);

    if (!isdefined(old_owner))
    {
        player iprintlnbold("^3zm8: start this bow quest normally first");
        return false;
    }

    if (old_owner === player)
    {
        player iprintlnbold("^2zm8: you are already the active " + zm8_de_bow_label(element) + " runner");
        return true;
    }

    if (zm8_de_player_is_other_bow_owner(player, element))
    {
        player iprintlnbold("^1zm8: hand off your other active bow quest first");
        return false;
    }

    // The owner's stock monitor catches quest_swap, clears its owner HUD and
    // calls function_abeafdcb(), which rebuilds the correct current trigger.
    old_owner notify("quest_swap");
    wait 0.25;

    for (t = 0; t < 40; t++)
    {
        transfer_struct = zm8_de_transfer_struct(element);

        if (isdefined(transfer_struct) && isdefined(transfer_struct.var_67b5dd94))
        {
            transfer_struct.var_67b5dd94 notify("trigger", player);
        }

        wait 0.25;
        new_owner = zm8_de_bow_owner(element);

        if (isdefined(new_owner) && new_owner === player)
        {
            player.zm8_de_bow_hud_state = undefined;

            if (isdefined(old_owner))
            {
                old_owner.zm8_de_bow_hud_state = undefined;
                old_owner iprintlnbold("^3zm8: teammate is now the active " + zm8_de_bow_label(element) + " runner");
            }

            player iprintlnbold("^2zm8: you are now the active " + zm8_de_bow_label(element) + " runner");
            println("zm8: transferred " + zm8_de_bow_label(element) + " bow quest active owner");
            return true;
        }
    }

    player iprintlnbold("^1zm8: bow handoff timed out - try the pedestal again");
    return false;
}

function zm8_de_team_prompt_text(player, element)
{
    label = zm8_de_bow_label(element);
    members = zm8_de_bow_team_members(element);
    owner = zm8_de_bow_owner(element);

    if (!isdefined(player.zm8_de_bow_team))
    {
        if (members.size >= 2)
        {
            return label + " BOW TEAM IS FULL";
        }

        return "Press ^3[P]^7 to join the " + label + " Bow team";
    }

    if (player.zm8_de_bow_team != element)
    {
        if (members.size >= 2)
        {
            return label + " BOW TEAM IS FULL";
        }

        return "Press ^3[P]^7 to switch to the " + label + " Bow team";
    }

    if (isdefined(owner) && owner === player)
    {
        return "YOU ARE THE ACTIVE " + label + " BOW RUNNER";
    }

    return "Press ^3[P]^7 to become the active " + label + " Bow runner";
}

// Match the stock interaction presentation: a small white prompt immediately
// below the crosshair, with the dedicated key highlighted like a normal use
// hint. The UI script binds P to action slot 4 on Der Eisendrache clients.
function zm8_de_show_team_prompt(player, element)
{
    if (!isdefined(player) || !isalive(player))
    {
        return;
    }

    state = zm8_de_team_prompt_text(player, element);

    if (!isdefined(player.zm8_de_team_prompt))
    {
        player.zm8_de_team_prompt = newclienthudelem(player);
        player.zm8_de_team_prompt.alignx = "center";
        player.zm8_de_team_prompt.aligny = "middle";
        player.zm8_de_team_prompt.horzalign = "center";
        player.zm8_de_team_prompt.vertalign = "middle";
        player.zm8_de_team_prompt.x = 0;
        player.zm8_de_team_prompt.y = 55;
        player.zm8_de_team_prompt.fontscale = 1.25;
        player.zm8_de_team_prompt.color = (1, 1, 1);
        player.zm8_de_team_prompt.alpha = 1;
        player.zm8_de_team_prompt.sort = 100;
        player.zm8_de_team_prompt.hidewheninmenu = true;
        player.zm8_de_team_prompt_element = element;
        player.zm8_de_team_prompt_state = undefined;
    }

    if (!isdefined(player.zm8_de_team_prompt_state) || player.zm8_de_team_prompt_state != state)
    {
        player.zm8_de_team_prompt settext(state);
        player.zm8_de_team_prompt_state = state;
    }
}

function zm8_de_clear_team_prompt(player, element)
{
    if (!isdefined(player) || !isdefined(player.zm8_de_team_prompt) ||
        !isdefined(player.zm8_de_team_prompt_element) || player.zm8_de_team_prompt_element != element)
    {
        return;
    }

    player.zm8_de_team_prompt destroy();
    player.zm8_de_team_prompt = undefined;
    player.zm8_de_team_prompt_element = undefined;
    player.zm8_de_team_prompt_state = undefined;
}

function zm8_de_create_team_pedestal(element, struct_name)
{
    level endon("end_game");
    pedestal = undefined;

    for (t = 0; t < 120 && !isdefined(pedestal); t++)
    {
        pedestal = scripts\codescripts\struct::get(struct_name, "targetname");

        if (!isdefined(pedestal))
        {
            wait 0.25;
        }
    }

    if (!isdefined(pedestal))
    {
        println("zm8: missing DE team pedestal " + struct_name);
        return;
    }

    pedestal_model_name = "pedestal_wolf_bow_place";

    if (element == "storm")
    {
        pedestal_model_name = "pedestal_storm_bow_place";
    }
    else if (element == "demon_gate")
    {
        pedestal_model_name = "pedestal_demon_bow_place";
    }
    else if (element == "rune_prison")
    {
        pedestal_model_name = "pedestal_rune_bow_place";
    }

    pedestal_model = getent(pedestal_model_name, "targetname");
    trigger_origin = pedestal.origin;

    if (isdefined(pedestal_model))
    {
        trigger_origin = pedestal_model.origin;
    }

    // A dynamically spawned trigger_radius_use does not reliably display or
    // fire on this client build. Poll the real pedestal model instead, render
    // a stock-style per-player prompt and consume the rising edge of the
    // dedicated P binding. Proximity alone never joins a team or transfers
    // ownership.
    nearby_players = [];

    while (true)
    {
        if (zm8_de_bow_flag_set(element + "_spawned") ||
            (element == "storm" && zm8_de_bow_flag_set("elemental_storm_spawned")))
        {
            // The duplicate upgraded-bow pickup owns this location after the
            // quest completes.
            players = getplayers();

            for (i = 0; i < players.size; i++)
            {
                zm8_de_clear_team_prompt(players[i], element);
            }

            return;
        }

        players = getplayers();

        for (i = 0; i < players.size; i++)
        {
            player = players[i];

            if (!isdefined(player) || !isalive(player) || player.sessionstate != "playing")
            {
                continue;
            }

            player_id = player getentitynumber();
            is_near = distance(player.origin, trigger_origin) <= 175;

            if (!is_near)
            {
                if (isdefined(nearby_players[player_id]))
                {
                    nearby_players[player_id] = undefined;
                    zm8_de_clear_team_prompt(player, element);
                }

                continue;
            }

            if (!isdefined(nearby_players[player_id]))
            {
                nearby_players[player_id] = true;
            }

            zm8_de_show_team_prompt(player, element);

            if (!(player actionslotfourbuttonpressed()) ||
                (isdefined(player.zm8_de_team_use_locked) && player.zm8_de_team_use_locked))
            {
                continue;
            }

            player.zm8_de_team_use_locked = true;
            player thread zm8_de_unlock_team_use_after_release();
            level thread zm8_de_handle_team_pedestal_use(player, element);
        }

        wait 0.05;
    }
}

function zm8_de_handle_team_pedestal_use(player, element)
{
    if (!isdefined(player) || !isalive(player) || player.sessionstate != "playing")
    {
        return;
    }

    label = zm8_de_bow_label(element);

    if (!isdefined(player.zm8_de_bow_team))
    {
        members = zm8_de_bow_team_members(element);

        if (members.size >= 2)
        {
            player iprintlnbold("^1zm8: " + label + " bow team already has two players");
            return;
        }

        zm8_de_assign_bow_team(player, element);
        player iprintlnbold("^2zm8: joined " + label + " BOW TEAM - release and press P again to take ACTIVE");
        println("zm8: player joined " + label + " bow team");
        return;
    }

    if (player.zm8_de_bow_team != element)
    {
        old_element = player.zm8_de_bow_team;
        old_owner = zm8_de_bow_owner(old_element);

        if (isdefined(old_owner) && old_owner === player)
        {
            player iprintlnbold("^1zm8: hand off your active " + zm8_de_bow_label(old_element) + " quest first");
            return;
        }

        members = zm8_de_bow_team_members(element);

        if (members.size >= 2)
        {
            player iprintlnbold("^1zm8: " + label + " bow team already has two players");
            return;
        }

        zm8_de_assign_bow_team(player, element);
        player iprintlnbold("^2zm8: switched to " + label + " BOW TEAM - release and press P again to take ACTIVE");
        return;
    }

    zm8_de_transfer_bow_owner(player, element);
}

function zm8_de_unlock_team_use_after_release()
{
    self endon("disconnect");

    while (self actionslotfourbuttonpressed())
    {
        wait 0.05;
    }

    wait 0.15;
    self.zm8_de_team_use_locked = false;
}

// ======================= Shared contribution detours =======================
// The stock quest still owns all stage flags, models, cleanup and progression.
// These detours only widen "did the owner do this?" contribution checks to
// the owner's one teammate. That keeps every increment idempotent and leaves
// broken-arrow binding/reforge/place/pickup as single-owner interactions.

detour scripts\zm\zm_castle_weap_quest_upgrade::function_ab623d34(expected_owner, volume = undefined)
{
    if (!isdefined(self) || self.isdog || self.archetype === "mechz")
    {
        return false;
    }

    if (!isdefined(expected_owner) || !zm8_de_attacker_matches_bow_team(self.attacker, expected_owner))
    {
        return false;
    }

    if (isdefined(volume) && !(self istouching(volume)))
    {
        return false;
    }

    return true;
}

// Lightning: either teammate may hit each of the three outdoor bonfires.
detour scripts\zm\zm_castle_weap_quest_upgrade::function_6e3cfa55()
{
    owner = level.var_f8d1dc16;

    if (!isdefined(owner))
    {
        return;
    }

    owner endon("death");
    owner endon("quest_swap");
    s_beacon = scripts\codescripts\struct::get(self.target);
    self notify("zm8_stop_projectile_watch");
    self thread zm8_de_refresh_projectile_watchers("storm", "zm8_storm_beacon_hit");

    while (true)
    {
        self waittill("zm8_storm_beacon_hit", contributor, weapon, point, radius, projectile, normal);

        if (!zm8_de_is_bow_team_contributor(contributor, "storm") ||
            !scripts\zm\zm_castle_weap_quest_upgrade::function_51a90202(weapon, 1, point, self))
        {
            continue;
        }

        if (!isdefined(s_beacon.var_41f52afd))
        {
            s_beacon.var_41f52afd = scripts\shared\util_shared::spawn_model("tag_origin", s_beacon.origin);
        }

        s_beacon.var_41f52afd scripts\shared\clientfield_shared::set("beacon_fx", 1);
        self playsound("zmb_beacon_ignite");
        self.b_lit = 1;
        self notify("beacon_activated");
        self notify("zm8_stop_projectile_watch");
        return;
    }
}

function zm8_de_storm_wallrun_reset(generation)
{
    level endon("elemental_storm_wallrun");

    if (!isdefined(level.zm8_storm_wallrun_generation) || level.zm8_storm_wallrun_generation != generation)
    {
        return;
    }

    // Invalidate every participant monitor before restoring the shared set.
    level.zm8_storm_wallrun_generation++;

    if (!isdefined(level.var_49593fd9))
    {
        return;
    }

    for (i = 0; i < level.var_49593fd9.size; i++)
    {
        wallrun = level.var_49593fd9[i];

        if (isdefined(wallrun) && isdefined(wallrun.target))
        {
            rune = getent(wallrun.target, "targetname");

            if (isdefined(rune))
            {
                rune scripts\shared\clientfield_shared::set("wallrun_fx", 1);
            }

            scripts\shared\exploder_shared::stop_exploder("lgt_rune_wind_" + wallrun.script_int);
        }
    }

    level.var_49593fd9 = [];
    players = getplayers();

    for (i = 0; i < players.size; i++)
    {
        if (zm8_de_is_bow_team_contributor(players[i], "storm"))
        {
            players[i].var_a4f04654 = 0;
            players[i] playsound("zmb_wall_run_rune_cross_fail");
        }
    }
}

// Stock starts watching the owner after their first plate and resets all
// plates when that player lands. For a shared run, each teammate starts the
// same stock-style monitor when they contribute their first plate. Either
// participating teammate landing before plate five resets the shared set;
// a teammate who has not entered the sequence may remain on the ground.
function zm8_de_storm_wallrun_participant_monitor(player, generation)
{
    level endon("elemental_storm_wallrun");
    grounded_ticks = 0;

    while (isdefined(level.zm8_storm_wallrun_generation) && level.zm8_storm_wallrun_generation == generation)
    {
        if (!isdefined(player) || !isalive(player) || player.sessionstate != "playing")
        {
            level thread zm8_de_storm_wallrun_reset(generation);
            return;
        }

        if (player iswallrunning() || !player isonground() || player isinmovemode("ufo", "noclip"))
        {
            grounded_ticks = 0;
        }
        else if (player.origin[2] < 320)
        {
            level thread zm8_de_storm_wallrun_reset(generation);
            return;
        }
        else
        {
            grounded_ticks++;

            // Match stock's four consecutive grounded checks before failure.
            if (grounded_ticks >= 4)
            {
                level thread zm8_de_storm_wallrun_reset(generation);
                return;
            }
        }

        wait 0.05;
    }
}

// Lightning pyramid plates use one shared set. Both teammates may take
// different sides while retaining the normal no-ground-touch requirement.
detour scripts\zm\zm_castle_weap_quest_upgrade::function_56130b0d()
{
    while (!level scripts\shared\flag_shared::get("elemental_storm_wallrun"))
    {
        self waittill("trigger", contributor);

        if (!zm8_de_is_bow_team_contributor(contributor, "storm"))
        {
            continue;
        }

        if (!isdefined(level.var_49593fd9))
        {
            level.var_49593fd9 = [];
        }
        else if (!isarray(level.var_49593fd9))
        {
            level.var_49593fd9 = array(level.var_49593fd9);
        }

        if (scripts\shared\array_shared::contains(level.var_49593fd9, self))
        {
            continue;
        }

        rune = getent(self.target, "targetname");

        if (isdefined(rune))
        {
            rune scripts\shared\clientfield_shared::set("wallrun_fx", 2);
        }

        scripts\shared\exploder_shared::exploder("lgt_rune_wind_" + self.script_int);
        self playsound("zmb_wall_run_rune_cross");
        contributor playrumbleonentity("zm_castle_quest_elemental_storm_wallrun_rumble");
        level.var_49593fd9[level.var_49593fd9.size] = self;

        if (!isdefined(level.zm8_storm_wallrun_generation))
        {
            level.zm8_storm_wallrun_generation = 1;
        }

        generation = level.zm8_storm_wallrun_generation;

        if (!isdefined(contributor.zm8_storm_wallrun_generation) || contributor.zm8_storm_wallrun_generation != generation)
        {
            contributor.zm8_storm_wallrun_generation = generation;
            level thread zm8_de_storm_wallrun_participant_monitor(contributor, generation);
        }

        owner = level.var_f8d1dc16;

        if (isdefined(owner))
        {
            owner.var_a4f04654 = level.var_49593fd9.size;
        }

        if (level.var_49593fd9.size >= 5)
        {
            level scripts\shared\flag_shared::set("elemental_storm_wallrun");
            self playsound("zmb_wall_run_rune_cross_done");
            return;
        }
    }
}

// Lightning: charged urn shots from either teammate may charge each bonfire.
detour scripts\zm\zm_castle_weap_quest_upgrade::function_1c758ab0()
{
    owner = level.var_f8d1dc16;

    if (!isdefined(owner))
    {
        return;
    }

    owner endon("death");
    owner endon("quest_swap");
    s_beacon = scripts\codescripts\struct::get(self.target);
    self notify("zm8_stop_projectile_watch");
    self thread zm8_de_refresh_projectile_watchers("storm", "zm8_storm_charged_hit");

    while (true)
    {
        self waittill("zm8_storm_charged_hit", contributor, weapon, point, radius, projectile, normal);

        if (!zm8_de_is_bow_team_contributor(contributor, "storm") || !isdefined(projectile.var_e4594d27) ||
            !projectile.var_e4594d27 ||
            !scripts\zm\zm_castle_weap_quest_upgrade::function_51a90202(weapon, 1, point, self))
        {
            continue;
        }

        s_beacon.var_41f52afd scripts\shared\clientfield_shared::set("beacon_fx", 2);
        self.b_charged = 1;

        if (isdefined(projectile.var_8f88d1fd))
        {
            projectile.var_8f88d1fd.b_used = 1;
            battery = scripts\codescripts\struct::get(projectile.var_8f88d1fd.target, "targetname");

            if (isdefined(battery.var_41f52afd))
            {
                battery.var_41f52afd scripts\shared\clientfield_shared::set("battery_fx", 0);
                wait 0.05;

                if (isdefined(battery.var_41f52afd))
                {
                    battery.var_41f52afd delete();
                }
            }
        }

        self notify("beacon_charged");
        self notify("zm8_stop_projectile_watch");
        return;
    }
}

function zm8_de_storm_charge_urn_watch()
{
    self endon("disconnect");

    if (isdefined(self.zm8_storm_charge_watch) && self.zm8_storm_charge_watch)
    {
        return;
    }

    self.zm8_storm_charge_watch = true;
    charged_urns = getentarray("aq_es_battery_volume_charged", "script_noteworthy");

    while (!level scripts\shared\flag_shared::get("elemental_storm_beacons_charged"))
    {
        if (isalive(self) && zm8_de_is_bow_team_contributor(self, "storm") &&
            self ischargeshotpending() && self.chargeshotlevel === 4)
        {
            selected_urn = scripts\zm\zm_castle_weap_quest_upgrade::function_7e113f9d(charged_urns);

            if (isdefined(selected_urn))
            {
                self scripts\shared\clientfield_shared::set_to_player("arrow_charge_fx", 1);
                self.var_55301590 = selected_urn;
                urn_model = scripts\codescripts\struct::get(selected_urn.target, "targetname");
                urn_model.var_41f52afd scripts\shared\clientfield_shared::set("battery_fx", 1);
                self scripts\zm\zm_castle_weap_quest_upgrade::function_29163209();

                if (isdefined(urn_model.var_41f52afd))
                {
                    urn_model.var_41f52afd scripts\shared\clientfield_shared::set("battery_fx", 2);
                }

                self scripts\shared\clientfield_shared::set_to_player("arrow_charge_fx", 0);
                self.var_55301590 = undefined;
            }
        }

        wait 0.05;
    }

    self.zm8_storm_charge_watch = false;
}

// Stock starts the charged-arrow watcher only on its owner. Start one guarded
// watcher for each Lightning teammate so either may take a filled urn shot.
detour scripts\zm\zm_castle_weap_quest_upgrade::function_94af5935()
{
    players = getplayers();

    for (i = 0; i < players.size; i++)
    {
        if (zm8_de_is_bow_team_contributor(players[i], "storm"))
        {
            players[i] thread zm8_de_storm_charge_urn_watch();
        }
    }

    beacons = getentarray("aq_es_beacon_trig", "script_noteworthy");

    for (i = 0; i < beacons.size; i++)
    {
        if (!(isdefined(beacons[i].b_charged) && beacons[i].b_charged))
        {
            beacons[i] thread scripts\zm\zm_castle_weap_quest_upgrade::function_1c758ab0();
        }
    }
}

// Fire: teammate melee kills may open the slab seal.
// (The common death validator above handles function_c58a0fe3.)

// Fire rune drops are player-specific. Assign the drop to the teammate whose
// kill produced it, while leaving the rune sequence itself global and stock.
function zm8_de_fire_rune_drop_callback(attacker)
{
    if (!level scripts\shared\flag_shared::get("demonic_rune_dropped") &&
        self scripts\zm\zm_castle_weap_quest_upgrade::function_ab623d34(level.var_6e68c0d8))
    {
        if (level.var_234807d9.size > 0 && randomfloat(1) <= 0.1)
        {
            self.no_powerups = 1;
            rune_name = level.var_234807d9[0];
            level scripts\shared\flag_shared::set("demonic_rune_dropped");
            // The ezboiii compiler only recognizes decompiler hash literals
            // when all eight hexadecimal digits are present. Keep the leading
            // zero or this becomes the unrelated hash 4EAFA696 at link time.
            level._powerup_timeout_override = &scripts\zm\_zm_powerup_castle_demonic_rune::function_05b767c2;
            level thread scripts\zm\_zm_powerups::specific_powerup_drop(rune_name, self.origin, undefined, undefined, undefined, self.attacker);
            level._powerup_timeout_override = undefined;
        }
    }
}

detour scripts\zm\zm_castle_weap_quest_upgrade::function_80d54dff(attacker)
{
    self zm8_de_fire_rune_drop_callback(attacker);
}

// Stock registers function_80d54dff by function pointer, which bypasses a
// detour captured after script init. Replace the short registration wrapper
// so the callback pointer itself targets the team-aware implementation.
detour scripts\zm\zm_castle_weap_quest_upgrade::function_dc9521bc()
{
    scripts\zm\_zm_spawner::register_zombie_death_event_callback(&zm8_de_fire_rune_drop_callback);
    level scripts\zm\zm_castle_weap_quest_upgrade::function_afa0928d();
    scripts\zm\_zm_spawner::deregister_zombie_death_event_callback(&zm8_de_fire_rune_drop_callback);
}

detour scripts\zm\zm_castle_weap_quest_upgrade::function_bb59b66c()
{
    urn = scripts\codescripts\struct::get("aq_dg_urn_struct", "targetname");
    urn scripts\zm\zm_castle_weap_quest_upgrade::function_3313abd5();

    while (true)
    {
        urn.var_67b5dd94 waittill("trigger", contributor);

        if (!zm8_de_is_bow_team_contributor(contributor, "demon_gate"))
        {
            continue;
        }

        contributor playrumbleonentity("zm_castle_quest_interact_rumble");
        level thread scripts\shared\scene_shared::play("p7_fxanim_zm_castle_quest_demongate_urn_bundle");
        scripts\zm\_zm_unitrigger::unregister_unitrigger(urn.var_67b5dd94);
        urn_position = getent("aq_dg_urn_position", "targetname");
        urn_position scripts\zm\zm_castle_vo::function_f0b775a3("return");
        return;
    }
}

detour scripts\zm\zm_castle_weap_quest_upgrade::function_1353f9e3()
{
    self scripts\zm\zm_castle_weap_quest_upgrade::function_3313abd5();

    while (true)
    {
        self.var_67b5dd94 waittill("trigger", contributor);

        if (!zm8_de_is_bow_team_contributor(contributor, "demon_gate"))
        {
            continue;
        }

        self scripts\shared\clientfield_shared::set("fossil_collect_fx", 1);
        self scripts\shared\clientfield_shared::set("fossil_reveal", 0);
        self notify("returned");
        self playsound("zmb_fossil_pickup");
        contributor playrumbleonentity("zm_castle_quest_interact_rumble");
        fossil_model = getent(self.target, "targetname");

        if (fossil_model.script_label == "o_zm_dlc1_chomper_demongate_swarm_trophy_room_solo_idle")
        {
            fossil_model scripts\shared\clientfield_shared::set("init_demongate_fossil", 1);
            scripts\shared\util_shared::wait_network_frame();
            fossil_model scripts\shared\clientfield_shared::set("fossil_reveal", 2);
        }
        else
        {
            fossil_model scripts\shared\clientfield_shared::set("init_demongate_fossil", 2);
            scripts\shared\util_shared::wait_network_frame();
            fossil_model scripts\shared\clientfield_shared::set("fossil_reveal", 2);
        }

        scripts\zm\_zm_unitrigger::unregister_unitrigger(self.var_67b5dd94);
        return;
    }
}

detour scripts\zm\zm_castle_weap_quest_upgrade::function_010033c3()
{
    trophy_room = getent("aq_dg_trophy_room_trig", "targetname");

    while (true)
    {
        trophy_room waittill("trigger", contributor);

        if (zm8_de_is_bow_team_contributor(contributor, "demon_gate"))
        {
            break;
        }

        wait 0.5;
    }

    urn_position = getent("aq_dg_urn_position", "targetname");
    urn_position thread scripts\zm\zm_castle_vo::function_f0b775a3("souls");
}

detour scripts\zm\zm_castle_weap_quest_upgrade::function_cf05b763()
{
    level endon("demon_gate_runes");
    urn_damage = getent("aq_dg_urn_damage_trig", "targetname");

    while (true)
    {
        urn_damage waittill("damage", amount, attacker, direction, point, mod, tagname, modelname, partname, weapon);

        if (scripts\zm\zm_castle_weap_quest_upgrade::function_51a90202(weapon, 1, point, urn_damage) &&
            zm8_de_is_bow_team_contributor(attacker, "demon_gate") &&
            !level scripts\shared\flag_shared::get("rune_sequence_failed") &&
            (!(isdefined(level.var_f00f53e6) && level.var_f00f53e6)))
        {
            wait 1;
            level.var_6e68c0d8 scripts\zm\zm_castle_weap_quest_upgrade::function_3520622d(0);
        }
    }
}

detour scripts\zm\zm_castle_weap_quest_upgrade::function_f20a422b(rune_model, rune_vo)
{
    level endon("demon_gate_runes");
    self scripts\zm\zm_castle_weap_quest_upgrade::function_3313abd5();
    self.var_25b51f6b = rune_model;

    while (true)
    {
        self.var_67b5dd94 waittill("trigger", contributor);

        if (!zm8_de_is_bow_team_contributor(contributor, "demon_gate"))
        {
            continue;
        }

        contributor playrumbleonentity("zm_castle_quest_interact_rumble");
        level notify(#"hash_b24bc9eb");
        rune = scripts\shared\util_shared::spawn_model(rune_model, self.origin, self.angles);
        rune scripts\shared\clientfield_shared::set("demonic_rune_fx", 1);
        rune playsound("zmb_rune_armor");
        rune scripts\zm\zm_castle_vo::function_ebc3d584(rune_vo);
        wait 2;
        rune delete();
    }
}

detour scripts\zm\zm_castle_weap_quest_upgrade::function_686645ab()
{
    level endon("demon_gate_runes");
    trophy_room = getent("aq_dg_trophy_room_trig", "targetname");
    urn_position = getent("aq_dg_urn_position", "targetname");

    while (true)
    {
        level waittill(#"hash_b24bc9eb");
        trophy_room waittill("trigger", contributor);

        if (zm8_de_is_bow_team_contributor(contributor, "demon_gate"))
        {
            urn_position thread scripts\zm\zm_castle_vo::function_c123b81c("ask_name", "vox_arro_demongate_ask_name_0");
            urn_position scripts\zm\zm_castle_vo::function_7b697614("vox_arro_demongate_ask_name_0");
        }
    }
}

detour scripts\zm\zm_castle_weap_quest_upgrade::function_b08d39a1()
{
    level endon("demon_gate_runes");

    while (true)
    {
        self waittill("damage", amount, attacker, direction, point, mod, tagname, modelname, partname, weapon);

        if (scripts\zm\zm_castle_weap_quest_upgrade::function_51a90202(weapon, 1, point, self) &&
            zm8_de_is_bow_team_contributor(attacker, "demon_gate") &&
            !level scripts\shared\flag_shared::get("rune_sequence_failed") && level.var_ca3b8551 < 4)
        {
            scripts\shared\exploder_shared::stop_exploder(self.var_483af51d);
            wait 0.05;
            scripts\shared\exploder_shared::exploder(self.var_6a1fa689);
            sequence_name = "aq_dg_rune_sequence_0" + level.var_ca3b8551;
            sequence = scripts\codescripts\struct::get(sequence_name, "targetname");
            self thread scripts\zm\zm_castle_weap_quest_upgrade::function_ee73a771();
            sequence scripts\zm\zm_castle_weap_quest_upgrade::function_c85b7e17(self.script_noteworthy, self.script_label);
        }
    }
}

detour scripts\zm\zm_castle_weap_quest_upgrade::function_894eef8b()
{
    volume = getent("aq_statue_volume", "targetname");

    if (isdefined(self) && self istouching(volume) && zm8_de_is_bow_team_contributor(self.attacker, "demon_gate"))
    {
        pedestal = scripts\codescripts\struct::get("upgraded_bow_struct_demon_gate", "targetname");
        level scripts\zm\zm_castle_weap_quest_upgrade::function_55c48922(self.origin, pedestal.origin, "demon", isdefined(self.missinglegs) && self.missinglegs);
        pedestal.var_ce58f456++;

        if (pedestal.var_ce58f456 >= 20 && !level scripts\shared\flag_shared::get("demon_gate_upgraded"))
        {
            level scripts\shared\flag_shared::set("demon_gate_upgraded");
            place = getent("pedestal_demon_bow_place", "targetname");
            place playsound("evt_arrow_souls_ready");
            place thread scripts\zm\zm_castle_weap_quest_upgrade::function_bf26d3fb("arrow_charge_wolf_fx");
        }
    }
}

// Void: either teammate may shoot the obelisk while the magma window is open.
detour scripts\zm\zm_castle_weap_quest_upgrade::rune_prison_obelisk()
{
    level thread scripts\zm\zm_castle_weap_quest_upgrade::function_d13d5192();
    obelisk_trigger = getent("aq_rp_obelisk_magma_trig", "targetname");

    while (!level scripts\shared\flag_shared::get("rune_prison_obelisk"))
    {
        obelisk_trigger waittill("damage", amount, attacker, direction, point, mod, tagname, modelname, partname, weapon);

        if (level scripts\shared\flag_shared::get("rune_prison_obelisk_magma_enabled") &&
            scripts\zm\zm_castle_weap_quest_upgrade::function_51a90202(weapon, 1, point, obelisk_trigger) &&
            zm8_de_is_bow_team_contributor(attacker, "rune_prison"))
        {
            playrumbleonposition("zm_castle_quest_rune_prison_obelisk_rumble", point);
            level scripts\shared\flag_shared::set("rune_prison_obelisk");
        }
    }

    scripts\shared\exploder_shared::stop_exploder("fxexp_500");
    scripts\shared\exploder_shared::stop_exploder("fxexp_501");
    obelisks = getentarray("aq_rp_obelisk", "script_noteworthy");
    scripts\shared\array_shared::run_all(obelisks, &delete);
    obelisk_trigger delete();
    level thread scripts\zm\zm_castle_weap_quest_upgrade::function_bc213d43();
}

detour scripts\zm\zm_castle_weap_quest_upgrade::function_f9027a91()
{
    circle_trigger = getent(self.target + "_trig", "targetname");

    while (!self scripts\shared\flag_shared::get("runic_circle_activated"))
    {
        circle_trigger waittill("damage", amount, attacker, direction, point, mod, tagname, modelname, partname, weapon);

        if (scripts\zm\zm_castle_weap_quest_upgrade::function_51a90202(weapon, 1, point, circle_trigger) &&
            zm8_de_is_bow_team_contributor(attacker, "rune_prison") &&
            isdefined(attacker.is_flung) && attacker.is_flung)
        {
            self scripts\shared\flag_shared::set("runic_circle_activated");
            self playsound("evt_cirlce_rune_hit");
            circle_trigger delete();
        }
    }
}

// Void circle souls are credited where the actual teammate is standing,
// rather than checking whether only the stock owner touches that circle.
detour scripts\zm\zm_castle_weap_quest_upgrade::function_dc6aa565()
{
    circles = getentarray("aq_rp_runic_circle_volume", "script_noteworthy");
    contributor = self.attacker;

    if (self scripts\zm\zm_castle_weap_quest_upgrade::function_ab623d34(level.var_c62829c7))
    {
        touching = contributor scripts\shared\array_shared::get_touching(circles);

        if (isdefined(touching) && touching.size > 0 &&
            touching[0] scripts\shared\flag_shared::get("runic_circle_activated") &&
            !(touching[0] scripts\shared\flag_shared::get("runic_circle_charged")))
        {
            circle_model = getent(touching[0].target, "targetname");
            touching[0] scripts\zm\zm_castle_weap_quest_upgrade::function_55c48922(self.origin, circle_model.origin, "rune", isdefined(self.missinglegs) && self.missinglegs);
            touching[0] scripts\shared\util_shared::delay_notify(0.05, "killed");
            circle_model scripts\shared\clientfield_shared::increment("runic_circle_death_fx");
        }
    }
}

detour scripts\zm\zm_castle_weap_quest_upgrade::function_88082ccd()
{
    self scripts\zm\zm_castle_weap_quest_upgrade::function_3313abd5();

    while (true)
    {
        self.var_67b5dd94 waittill("trigger", contributor);

        if (zm8_de_is_bow_team_contributor(contributor, "rune_prison"))
        {
            scripts\zm\_zm_unitrigger::unregister_unitrigger(self.var_67b5dd94);
            break;
        }
    }

    contributor playrumbleonentity("zm_castle_quest_interact_rumble");
    level.var_bf08cf2d = undefined;
    level notify(#"hash_40e6d9e7");
    fireplaces = scripts\codescripts\struct::get_array("aq_rp_fireplace_struct", "targetname");
    fireplace = scripts\shared\array_shared::random(fireplaces);
    level scripts\zm\zm_castle_weap_quest_upgrade::function_16248b25(fireplace.script_int);
    wanted_label = fireplace.script_noteworthy;
    circle_models = getentarray("aq_rp_runic_circle", "script_noteworthy");

    for (i = 0; i < circle_models.size; i++)
    {
        if (circle_models[i].script_label != wanted_label)
        {
            circle_models[i] thread scripts\zm\zm_castle_weap_quest_upgrade::function_aea90ad4();
        }
    }

    circle_symbols = getentarray("aq_rp_runic_circle_symbol", "script_noteworthy");

    for (i = 0; i < circle_symbols.size; i++)
    {
        if (circle_symbols[i].script_label != wanted_label)
        {
            circle_symbols[i] thread scripts\zm\zm_castle_weap_quest_upgrade::function_561d0d99();
        }
    }

    circle_volumes = getentarray("aq_rp_runic_circle_volume", "script_noteworthy");
    selected_volume = undefined;

    for (i = 0; i < circle_volumes.size; i++)
    {
        if (circle_volumes[i].script_label != wanted_label)
        {
            circle_volumes[i] delete();
        }
        else
        {
            selected_volume = circle_volumes[i];
        }
    }

    selected_volume.var_336f1366 = fireplace;
    selected_model = getent(selected_volume.target, "targetname");
    selected_model scripts\shared\clientfield_shared::set("runic_circle_fx", 1);
    return selected_volume;
}

detour scripts\zm\zm_castle_weap_quest_upgrade::function_fd254a35()
{
    if (isdefined(level.var_c62829c7))
    {
        level.var_c62829c7 thread scripts\zm\zm_castle_vo::function_21c9c75b();
    }

    clock = scripts\codescripts\struct::get("aq_rp_clock_use_struct", "targetname");
    selected_volume = clock scripts\zm\zm_castle_weap_quest_upgrade::function_88082ccd();
    magma_tag = getent("aq_rp_magma_ball_tag", "targetname");
    magma_tag thread scripts\zm\zm_castle_weap_quest_upgrade::function_5f8f4823();
    level.var_ebaeb24a = selected_volume;
    level.var_bf08cf2d = &scripts\zm\zm_castle_weap_quest_upgrade::function_830f5cf3;
    level thread scripts\zm\zm_castle_weap_quest_upgrade::rune_prison_golf(selected_volume);
    level scripts\shared\flag_shared::wait_till("rune_prison_golf");
    fireplace = selected_volume.var_336f1366;
    selected_volume delete();
    fireplace scripts\zm\zm_castle_weap_quest_upgrade::function_e198b188(1);
    fireplace scripts\zm\zm_castle_weap_quest_upgrade::function_3313abd5();

    while (true)
    {
        fireplace.var_67b5dd94 waittill("trigger", contributor);

        if (zm8_de_is_bow_team_contributor(contributor, "rune_prison"))
        {
            scripts\zm\_zm_unitrigger::unregister_unitrigger(fireplace.var_67b5dd94);
            playsoundatposition("zmb_fireplace_interact", fireplace.origin);
            contributor playrumbleonentity("zm_castle_quest_interact_rumble");
            contributor thread scripts\zm\_zm_audio::create_and_play_dialog("quest", "fireplace");
            fireplace scripts\zm\zm_castle_weap_quest_upgrade::function_e198b188(0);
            magma_tag notify("final");
            clock_runes = getentarray("aq_rp_clock_wheel_rune", "script_noteworthy");
            scripts\shared\array_shared::run_all(clock_runes, &delete);
            magma_tag scripts\shared\flag_shared::wait_till("magma_ball_move_done");
            return;
        }
    }
}

// Resolve one Void golf projectile using whichever teammate fired it.
function zm8_de_rune_golf_impact(projectile, shot_index, fireplace, shooter)
{
    owner = level.var_c62829c7;

    if (!isdefined(owner))
    {
        return undefined;
    }

    owner endon("death");
    owner endon("quest_swap");
    fireplace_trigger = getent(fireplace.target, "targetname");
    landing = undefined;
    controller = spawnstruct();
    controller thread zm8_de_refresh_projectile_watchers("rune_prison", "zm8_rune_golf_impact");

    do
    {
        controller waittill("zm8_rune_golf_impact", contributor, weapon, position, radius, impact_projectile, normal);

        if (!zm8_de_is_bow_team_contributor(contributor, "rune_prison"))
        {
            continue;
        }

        if (projectile != impact_projectile)
        {
            if (!(contributor istouching(level.var_2e55cb98)) ||
                !scripts\zm\zm_castle_weap_quest_upgrade::function_51a90202(weapon))
            {
                controller notify("zm8_stop_projectile_watch");
                return undefined;
            }
        }

        if (level scripts\zm\zm_castle_weap_quest_upgrade::function_afda729a(shot_index, fireplace_trigger, position))
        {
            level scripts\shared\flag_shared::set("rune_prison_golf");
            level scripts\shared\util_shared::delay_notify(2, "rune_prison_postfx_end");
            controller notify("zm8_stop_projectile_watch");
            return undefined;
        }

        landing = contributor scripts\zm\_zm_weap_elemental_bow::function_0866906f(position, "elemental_bow_rune_prison", impact_projectile, 32);

        if (isdefined(landing) && !scripts\zm\_zm_utility::check_point_in_enabled_zone(landing))
        {
            landing = undefined;
        }
    }
    while (!isdefined(landing));

    controller notify("zm8_stop_projectile_watch");
    magma_tag = getent("aq_rp_magma_ball_tag", "targetname");
    anchor = scripts\shared\util_shared::spawn_model("tag_origin", landing);
    anchor scripts\shared\clientfield_shared::set("runeprison_rock_fx", 1);
    next_trigger = spawn("trigger_radius", landing, 0, 100, 150);
    next_trigger.var_41f52afd = anchor;
    magma_tag notify("drop");
    return next_trigger;
}

detour scripts\zm\zm_castle_weap_quest_upgrade::rune_prison_golf(selected_volume)
{
    owner = level.var_c62829c7;

    if (!isdefined(owner))
    {
        return;
    }

    owner endon("death");
    owner endon("quest_swap");
    shot_index = 0;
    level.var_2e55cb98 = selected_volume;
    owner thread scripts\zm\zm_castle_weap_quest_upgrade::function_592f1ad2();
    level thread scripts\zm\zm_castle_weap_quest_upgrade::function_2e904288(selected_volume);
    selected_volume notify("zm8_stop_missile_watch");
    selected_volume thread zm8_de_refresh_missile_watchers("rune_prison", "zm8_rune_golf_shot");

    while (!level scripts\shared\flag_shared::get("rune_prison_golf"))
    {
        selected_volume waittill("zm8_rune_golf_shot", contributor, projectile, weapon);

        if (!(contributor istouching(level.var_2e55cb98)) ||
            !scripts\zm\zm_castle_weap_quest_upgrade::function_51a90202(weapon))
        {
            continue;
        }

        next_trigger = zm8_de_rune_golf_impact(projectile, shot_index, selected_volume.var_336f1366, contributor);

        if (!isdefined(next_trigger))
        {
            continue;
        }

        shot_index++;

        if (shot_index == 1)
        {
            selected_model = getent(selected_volume.target, "targetname");
            selected_model scripts\shared\clientfield_shared::set("runic_circle_fx", 0);
        }

        if (shot_index > 1)
        {
            level thread scripts\zm\zm_castle_weap_quest_upgrade::function_a78192b2(level.var_2e55cb98.var_41f52afd);
            level.var_2e55cb98 delete();
        }

        if (shot_index == 2)
        {
            contributor thread scripts\zm\zm_castle_weap_quest_upgrade::function_c22c33e2();
        }

        if (shot_index == 4)
        {
            level thread scripts\zm\zm_castle_weap_quest_upgrade::function_a78192b2(next_trigger.var_41f52afd);
            next_trigger delete();
            magma_tag = getent("aq_rp_magma_ball_tag", "targetname");
            magma_tag notify("reset");
            shot_index = 0;

            if (isdefined(owner))
            {
                playsoundatposition("zmb_demon_runes_deny", owner.origin);
            }

            level waittill("between_round_over");
            level.var_2e55cb98 = selected_volume;
            selected_model = getent(selected_volume.target, "targetname");
            selected_model scripts\shared\clientfield_shared::set("runic_circle_fx", 1);
        }
        else
        {
            level.var_2e55cb98 = next_trigger;
        }
    }

    selected_volume notify("zm8_stop_missile_watch");
    level.var_ebaeb24a = undefined;
    level.var_bf08cf2d = undefined;

    if (isdefined(level.var_2e55cb98.var_41f52afd))
    {
        level thread scripts\zm\zm_castle_weap_quest_upgrade::function_a78192b2(level.var_2e55cb98.var_41f52afd);
    }

    if (level.var_2e55cb98 != selected_volume)
    {
        level.var_2e55cb98 delete();
    }

    circle_models = getentarray("aq_rp_runic_circle", "script_noteworthy");

    for (i = 0; i < circle_models.size; i++)
    {
        circle_models[i] thread scripts\zm\zm_castle_weap_quest_upgrade::function_aea90ad4();
    }

    circle_symbols = getentarray("aq_rp_runic_circle_symbol", "script_noteworthy");

    for (i = 0; i < circle_symbols.size; i++)
    {
        circle_symbols[i] thread scripts\zm\zm_castle_weap_quest_upgrade::function_561d0d99();
    }

    clock_rune = scripts\codescripts\struct::get("aq_rp_clock_rune_struct", "targetname");

    if (isdefined(clock_rune.var_7b98b639))
    {
        clock_rune.var_7b98b639 delete();
    }

    if (isdefined(level.var_c62829c7))
    {
        level.var_c62829c7.var_77447dc2 = 1;
    }
}

// Wolf: either teammate may shoot the skull shrine.
detour scripts\zm\zm_castle_weap_quest_upgrade::function_15a6ff6a()
{
    owner = level.var_52978d72;

    if (!isdefined(owner))
    {
        return;
    }

    owner endon("death");
    owner endon("quest_swap");
    owner thread scripts\zm\zm_castle_weap_quest_upgrade::function_d62aa556();
    shrine = getent("aq_wh_skull_shrine_trig", "targetname");
    shrine notify("zm8_stop_projectile_watch");
    shrine thread zm8_de_refresh_projectile_watchers("wolf_howl", "zm8_wolf_shrine_hit");

    while (true)
    {
        shrine waittill("zm8_wolf_shrine_hit", contributor, weapon, point, radius, projectile, normal);

        if (zm8_de_is_bow_team_contributor(contributor, "wolf_howl") &&
            scripts\zm\zm_castle_weap_quest_upgrade::function_51a90202(weapon, 1, point, shrine))
        {
            playsoundatposition("zmb_wolf_shrine_location", (5350, -1659, -1135));
            skull = getent("wolf_skull_roll_down", "targetname");
            skull thread scripts\zm\zm_castle_weap_quest_upgrade::function_262d06db();
            level scripts\shared\clientfield_shared::set("quest_state_wolf", 2);
            shrine notify("zm8_stop_projectile_watch");
            return;
        }
    }
}

detour scripts\zm\zm_castle_weap_quest_upgrade::function_262d06db()
{
    level notify(#"hash_80b27882");
    level.var_a1e95710 = undefined;
    level scripts\shared\scene_shared::play("p7_fxanim_zm_castle_quest_wolf_skull_roll_down_bundle");
    self scripts\zm\zm_castle_weap_quest_upgrade::function_3313abd5();

    while (true)
    {
        self.var_67b5dd94 waittill("trigger", contributor);

        if (!zm8_de_is_bow_team_contributor(contributor, "wolf_howl"))
        {
            continue;
        }

        contributor playsound("zmb_skull_pickup");
        contributor playrumbleonentity("zm_castle_quest_interact_rumble");
        scripts\zm\_zm_unitrigger::unregister_unitrigger(self.var_67b5dd94);
        self scripts\shared\clientfield_shared::set("wolf_howl_bone_fx", 0);
        wait 0.05;
        self delete();
        level notify(#"hash_88b82583");
        return;
    }
}

detour scripts\zm\zm_castle_weap_quest_upgrade::function_b9485994()
{
    skull = getent("aq_wh_skadi_skull", "targetname");
    skull scripts\zm\zm_castle_weap_quest_upgrade::function_3313abd5();

    while (true)
    {
        skull.var_67b5dd94 waittill("trigger", contributor);

        if (zm8_de_is_bow_team_contributor(contributor, "wolf_howl"))
        {
            skull playsound("zmb_skull_restore");
            contributor playrumbleonentity("zm_castle_quest_interact_rumble");
            scripts\zm\_zm_unitrigger::unregister_unitrigger(skull.var_67b5dd94);
            return;
        }
    }
}

detour scripts\zm\zm_castle_weap_quest_upgrade::function_af36e4b0()
{
    level thread scripts\shared\scene_shared::play(("p7_fxanim_zm_castle_quest_wolf_dig_" + self.script_label) + "_bundle");
    level.var_e6d07014 scripts\shared\scene_shared::play("ai_zm_dlc1_wolf_howl_dig", array(level.var_e6d07014));
    wait 0.05;
    aggro = scripts\codescripts\struct::get(self.targetname + "_aggro", "targetname");
    level.var_e6d07014 setgoal(aggro.origin, 0, 4);
    bones = getent("aq_wh_bones_" + self.script_label, "targetname");
    bones scripts\zm\zm_castle_weap_quest_upgrade::function_3313abd5(undefined, undefined, bones.origin + vectorscale((0, 0, 1), 30));

    while (true)
    {
        bones.var_67b5dd94 waittill("trigger", contributor);

        if (!zm8_de_is_bow_team_contributor(contributor, "wolf_howl"))
        {
            continue;
        }

        scripts\zm\_zm_unitrigger::unregister_unitrigger(bones.var_67b5dd94);
        playsoundatposition("zmb_bones_pickup", bones.origin);
        contributor playrumbleonentity("zm_castle_quest_interact_rumble");
        bones scripts\shared\clientfield_shared::set("wolf_howl_bone_fx", 0);
        wait 0.05;
        bones delete();
        scripts\shared\exploder_shared::stop_exploder("lgt_wolf_quest_" + self.script_label);
        owner = level.var_52978d72;

        if (isdefined(owner) && (!(isdefined(owner.var_372a0bf1) && owner.var_372a0bf1)))
        {
            wait 1;
            owner scripts\zm\_zm_audio::create_and_play_dialog("quest", "skadi_dig");
            owner.var_372a0bf1 = 1;
        }

        return;
    }
}

// The stock ledge handler only tracks the active owner's wall-run field.
// Check the actual teammate who fired instead, while retaining the one shared
// ledge animation/cooldown and single repaired-arrow transition.
detour scripts\zm\zm_castle_weap_quest_upgrade::function_987776f3()
{
    level endon(#"hash_b12ab80e");
    level endon("wolf_howl_repaired");
    ledge = getent("aq_wh_ledge_collision", "targetname");

    while (true)
    {
        self waittill("damage", amount, attacker, direction, point, mod, tagname, modelname, partname, weapon);

        if (scripts\zm\zm_castle_weap_quest_upgrade::function_51a90202(weapon, 1, point, self) &&
            zm8_de_is_bow_team_contributor(attacker, "wolf_howl") && attacker iswallrunning())
        {
            ledge scripts\zm\zm_castle_weap_quest_upgrade::function_6ab969b7();
            wait 10;
            ledge scripts\zm\zm_castle_weap_quest_upgrade::function_1676aad7();
        }
    }
}

// Final soul boxes accept both teammates but cross the completion edge once.
detour scripts\zm\zm_castle_weap_quest_upgrade::function_392a1ae1()
{
    volume = getent("aq_statue_volume", "targetname");

    if (self scripts\zm\zm_castle_weap_quest_upgrade::function_ab623d34(level.var_f8d1dc16, volume))
    {
        pedestal = scripts\codescripts\struct::get("upgraded_bow_struct_elemental_storm", "targetname");
        level scripts\zm\zm_castle_weap_quest_upgrade::function_55c48922(self.origin, pedestal.origin, "storm", isdefined(self.missinglegs) && self.missinglegs);
        pedestal.var_ce58f456++;

        if (pedestal.var_ce58f456 >= 20 && !level scripts\shared\flag_shared::get("elemental_storm_upgraded"))
        {
            level scripts\shared\flag_shared::set("elemental_storm_upgraded");
            place = getent("pedestal_storm_bow_place", "targetname");
            place playsound("evt_arrow_souls_ready");
            place thread scripts\zm\zm_castle_weap_quest_upgrade::function_bf26d3fb("arrow_charge_wolf_fx");
        }
    }
}

detour scripts\zm\zm_castle_weap_quest_upgrade::function_293189ba()
{
    volume = getent("aq_statue_volume", "targetname");

    if (self scripts\zm\zm_castle_weap_quest_upgrade::function_ab623d34(level.var_c62829c7, volume))
    {
        pedestal = scripts\codescripts\struct::get("upgraded_bow_struct_rune_prison", "targetname");
        level scripts\zm\zm_castle_weap_quest_upgrade::function_55c48922(self.origin, pedestal.origin, "rune", isdefined(self.missinglegs) && self.missinglegs);
        pedestal.var_ce58f456++;

        if (pedestal.var_ce58f456 >= 20 && !level scripts\shared\flag_shared::get("rune_prison_upgraded"))
        {
            level scripts\shared\flag_shared::set("rune_prison_upgraded");
            place = getent("pedestal_rune_bow_place", "targetname");
            place playsound("evt_arrow_souls_ready");
            place thread scripts\zm\zm_castle_weap_quest_upgrade::function_bf26d3fb("arrow_charge_wolf_fx");
        }
    }
}

detour scripts\zm\zm_castle_weap_quest_upgrade::function_803f9685()
{
    volume = getent("aq_statue_volume", "targetname");

    if (self scripts\zm\zm_castle_weap_quest_upgrade::function_ab623d34(level.var_52978d72, volume))
    {
        pedestal = scripts\codescripts\struct::get("upgraded_bow_struct_wolf_howl", "targetname");
        level scripts\zm\zm_castle_weap_quest_upgrade::function_55c48922(self.origin, pedestal.origin, "wolf", isdefined(self.missinglegs) && self.missinglegs);
        pedestal.var_ce58f456++;

        if (pedestal.var_ce58f456 >= 20 && !level scripts\shared\flag_shared::get("wolf_howl_upgraded"))
        {
            level scripts\shared\flag_shared::set("wolf_howl_upgraded");
            place = getent("pedestal_wolf_bow_place", "targetname");
            place playsound("evt_arrow_souls_ready");
            place thread scripts\zm\zm_castle_weap_quest_upgrade::function_bf26d3fb("arrow_charge_wolf_fx");
        }
    }
}
