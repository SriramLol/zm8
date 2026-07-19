// zm8 - Shi No Numa (zm_sumpf) 5-8 player compatibility helper
//
// The zipline model has four rider tags. Stock code continues adding players
// after all tags are removed from its free-tag array, then links to undefined.
// Carry at most four riders per trip; extra players remain safely at the stop
// and can take the return/next trip.

#using scripts\shared\ai\zombie_utility;
#using scripts\shared\clientfield_shared;
#using scripts\shared\scene_shared;
#using scripts\shared\util_shared;
#using scripts\zm\_zm;
#using scripts\zm\zm_sumpf_zipline;

autoexec function zm8_sumpf_helper_loaded()
{
    println("zm8: Shi No Numa 5-8 player zipline compatibility loaded");
}

detour scripts\zm\zm_sumpf_zipline::activatezip(rider)
{
    zombs = getaispeciesarray("axis");
    self.riders = [];
    self.var_5dbcd881 = 0;

    for (i = 0; i < zombs.size; i++)
    {
        if (isdefined(zombs[i]) && isalive(zombs[i]) && zombs[i] istouching(self.zipdamagevolume))
        {
            if (zombs[i].isdog)
            {
                zombs[i].a.nodeath = 1;
            }
            else
            {
                zombs[i] startragdoll();
            }

            zombs[i] dodamage(zombs[i].health + 600, zombs[i].origin);
        }
    }

    level thread zm_sumpf_zipline::zip_line_audio();
    free_tags = array("link_player1", "link_player2", "link_player3", "link_player4");
    all_peeps = getplayers();
    peeps = [];

    // Put the player who paid/activated first so a crowded platform never
    // sends four bystanders while leaving the purchaser behind.
    if (isdefined(rider) && zombie_utility::is_player_valid(rider))
    {
        peeps[peeps.size] = rider;
    }

    for (i = 0; i < all_peeps.size; i++)
    {
        if (!isdefined(rider) || all_peeps[i] != rider)
        {
            peeps[peeps.size] = all_peeps[i];
        }
    }

    for (i = 0; i < peeps.size; i++)
    {
        if (!zombie_utility::is_player_valid(peeps[i]) ||
            (!peeps[i] istouching(self.volume) && (!isdefined(rider) || peeps[i] != rider)))
        {
            continue;
        }

        // zm8: four physical attachment tags; remaining players wait.
        if (free_tags.size < 1)
        {
            continue;
        }

        prevdist = undefined;
        playerspot = undefined;
        playerorg = peeps[i] getorigin();

        foreach (tag_name in free_tags)
        {
            attachorg = self.zip gettagorigin(tag_name);
            dist = distance2d(playerorg, attachorg);

            if (!isdefined(prevdist) || dist <= prevdist)
            {
                prevdist = dist;
                playerspot = tag_name;
            }
        }

        self.riders[self.riders.size] = peeps[i];
        peeps[i] freezecontrols(1);
        peeps[i] thread util::magic_bullet_shield();
        peeps[i].on_zipline = 1;
        peeps[i] setstance("stand");
        peeps[i] allowcrouch(0);
        peeps[i] allowprone(0);
        peeps[i] clientfield::set("player_legs_hide", 1);
        peeps[i] playerlinkto(self.zip, playerspot, 0, 180, 180, 180, 180, 1);
        arrayremovevalue(free_tags, playerspot);
    }

    wait(0.1);

    if (free_tags.size > 0)
    {
        center = self.zip gettagorigin("link_zipline_jnt");
        physicsexplosionsphere(center, 128, 64, 2);
    }

    self thread zm_sumpf_zipline::function_58047fdd();

    if (!isdefined(level.direction))
    {
        self.aiblocker solid();
        self.aiblocker disconnectpaths(0, 0);

        for (i = 0; i < self.riders.size; i++)
        {
            self.riders[i] thread zm::store_crumb((11216, 2883, -648));
        }

        level scene::play("p7_fxanim_zm_sumpf_zipline_down_bundle");
        level notify(#"machine_done");
        level.direction = "back";
    }
    else
    {
        for (i = 0; i < self.riders.size; i++)
        {
            self.riders[i] thread zm::store_crumb((10750, 1516, -501));
        }

        level scene::play("p7_fxanim_zm_sumpf_zipline_up_bundle");
        self.aiblocker notsolid();
        self.aiblocker connectpaths();
        level.direction = undefined;
    }

    self.zipactive = 0;
    wait(0.1);

    for (i = 0; i < self.riders.size; i++)
    {
        if (!isdefined(self.riders[i]))
        {
            continue;
        }

        self.riders[i] unlink();
        self.riders[i] util::stop_magic_bullet_shield();
        self.riders[i] thread zm::store_crumb(self.origin);
        self.riders[i].on_zipline = 0;
        self.riders[i] allowcrouch(1);
        self.riders[i] allowprone(1);
        self.riders[i] freezecontrols(0);
        self.riders[i] clientfield::set("player_legs_hide", 0);
    }

    self zm_sumpf_zipline::player_collision_fix();
    self notify(#"zipdone");
}
