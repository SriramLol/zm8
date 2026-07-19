// zm8 - Origins (zm_tomb) 5-8 player quest compatibility helper

#using scripts\shared\flag_shared;
#using scripts\shared\util_shared;
#using scripts\zm\_zm_sidequests;
#using scripts\zm\zm_tomb_ee_main_step_6;

autoexec function zm8_tomb_helper_loaded()
{
    println("zm8: Origins active-player punch gate compatibility loaded");
}

// Stock sets ee_all_players_upgraded_punch only when every connected entity
// owns the upgrade. A waiting spectator can never earn it and permanently
// blocks step 6. Keep the stock stage state machine and require every living,
// playing participant to earn the upgraded punch legitimately.
detour scripts\zm\zm_tomb_ee_main_step_6::stage_logic()
{
    while (!level scripts\shared\flag_shared::get("ee_all_players_upgraded_punch"))
    {
        players = getplayers();
        active_count = 0;
        all_upgraded = true;

        for (i = 0; i < players.size; i++)
        {
            player = players[i];

            if (!isdefined(player) || !isalive(player) || player.sessionstate != "playing")
            {
                continue;
            }

            active_count++;

            if (!isdefined(player.b_punch_upgraded) || !player.b_punch_upgraded)
            {
                all_upgraded = false;
                break;
            }
        }

        if (active_count > 0 && all_upgraded)
        {
            level scripts\shared\flag_shared::set("ee_all_players_upgraded_punch");
            break;
        }

        wait 0.25;
    }

    scripts\shared\util_shared::wait_network_frame();
    scripts\zm\_zm_sidequests::stage_completed("little_girl_lost", level._cur_stage_name);
}
