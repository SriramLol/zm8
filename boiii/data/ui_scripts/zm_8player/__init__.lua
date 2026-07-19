-- zm8 mod - raise the zombies lobby cap from 4 to 8 (all maps, stock + DLC)
-- Pairs with custom_scripts/zm/zm8.gsc (server-side 8-player cap).
--
-- This client wraps engine globals (Engine, LobbyData, ...) in readonly proxy
-- tables, so plain assignment throws "Attempt to modify a value in a readonly
-- table". rawset() on the proxy shadows the original method (raw fields are
-- found before the __index redirect fires), and everything is pcall-guarded so
-- a failed hook degrades to dvar-only mode instead of an error screen.

local ZM8_MAX_CLIENTS = 8

local function isZombiesMode()
	local ok, result = pcall(function()
		return Engine.CurrentSessionMode() == Enum.eModes.MODE_ZOMBIES
	end)
	return ok and result == true
end

local function forceDvars()
	pcall(function()
		Engine.SetDvar("party_maxplayers", ZM8_MAX_CLIENTS)
		Engine.SetDvar("com_maxclients", ZM8_MAX_CLIENTS)
	end)
	pcall(function()
		Engine.SetLobbyMaxClients(Enum.LobbyType.LOBBY_TYPE_GAME, ZM8_MAX_CLIENTS)
		Engine.SetLobbyMaxClients(Enum.LobbyType.LOBBY_TYPE_PRIVATE, ZM8_MAX_CLIENTS)
	end)
end

-- readonly-safe assignment: try normal set, then rawset shadow on the proxy
local function trySet(tbl, key, value)
	if pcall(function() tbl[key] = value end) then
		return true
	end
	return pcall(function() rawset(tbl, key, value) end)
end

-- raise maxClients on a lobby target table, tolerating readonly wrappers
local function liftCap(target)
	if not target or target.maxClients ~= 4 then
		return target
	end
	pcall(function() target.maxClients = ZM8_MAX_CLIENTS end)
	if target.maxClients ~= ZM8_MAX_CLIENTS then
		pcall(function() rawset(target, "maxClients", ZM8_MAX_CLIENTS) end)
	end
	return target
end

-- Hook LobbyData:UITargetFromId - every lobby screen (player-count header,
-- the party ui_script that copies maxClients into party_maxplayers, ...)
-- reads the cap through it. Zombies only; MP/CP untouched.
pcall(function()
	local originalUITargetFromId = LobbyData.UITargetFromId

	trySet(LobbyData, "UITargetFromId", function(self, targetId)
		local target = originalUITargetFromId(self, targetId)
		if isZombiesMode() then
			target = liftCap(target)
			forceDvars()
		end
		return target
	end)
end)

-- Belt and braces: if we loaded in a zombies context, push the dvars now so
-- the session cap is right even if the UI hook could not be installed.
if isZombiesMode() then
	forceDvars()
end

-- ---------------------------------------------------------------------------
-- Scoreboard guard for players 5-8
--
-- The zombies scoreboard row widget (ZMScr_ListingLg/Sm) builds one row per
-- player from a per-player data model. For slots 5-8 some model fields are
-- never registered, so GetModelValue returns false; a stripped scaling/color
-- helper then does "boolean * number" and throws a full-screen LUI error the
-- moment the scoreboard datasource refreshes.
--
-- The compiled widget is baked into the fastfiles (not readable here), so
-- instead of reconstructing it we make its model callbacks non-fatal: while
-- the widget is being constructed we swap in a linkToElementModel that wraps
-- every registered callback in pcall. A slot-5-8 row that hits the bad math
-- just skips that visual update instead of crashing the UI. Rows for players
-- 1-4 are unaffected. Everything is pcall-guarded so a failure here degrades
-- to the stock behaviour rather than an error screen.

local function makeGuardedLink(originalLink)
	return function(...)
		local n = select("#", ...)
		local args = { ... }

		for i = 1, n do
			if type(args[i]) == "function" then
				local callback = args[i]
				args[i] = function(...)
					-- swallow errors from missing slot-5-8 model values
					pcall(callback, ...)
				end
			end
		end

		return originalLink(unpack(args, 1, n))
	end
end

local function guardListingWidget(className)
	pcall(function()
		local widgetClass = CoD[className]

		if not widgetClass or type(widgetClass.new) ~= "function" then
			return
		end

		local originalNew = widgetClass.new

		local guardedNew = function(...)
			local savedLink = LUI.UIElement.linkToElementModel
			local restored = false

			-- only guard callbacks registered during this widget's build
			pcall(function()
				LUI.UIElement.linkToElementModel = makeGuardedLink(savedLink)
			end)

			local results = { pcall(originalNew, ...) }

			pcall(function()
				LUI.UIElement.linkToElementModel = savedLink
				restored = true
			end)

			if not restored then
				LUI.UIElement.linkToElementModel = savedLink
			end

			if results[1] then
				return unpack(results, 2)
			end

			-- construction itself failed - degrade to no row rather than a
			-- crash; the parent list tolerates a nil child
			return nil
		end

		if not pcall(function() widgetClass.new = guardedNew end) then
			pcall(function() rawset(widgetClass, "new", guardedNew) end)
		end
	end)
end

pcall(function()
	-- make sure the widget classes exist before we wrap them (the scoreboard
	-- modules may not be required yet at frontend init)
	pcall(function() require("ui.uieditor.widgets.hud.zm_score.zmscr_listinglg") end)
	pcall(function() require("ui.uieditor.widgets.hud.zm_score.zmscr_listingsm") end)

	guardListingWidget("ZMScr_ListingLg")
	guardListingWidget("ZMScr_ListingSm")
end)
