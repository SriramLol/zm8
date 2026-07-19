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
	-- make sure the widget classes exist before we wrap them. LUI module
	-- names are CASE-SENSITIVE and the shipped path uses mixed case - the
	-- original lowercase require failed silently and left the guard dead.
	pcall(function() require("ui.uieditor.widgets.HUD.ZM_Score.ZMScr_ListingLg") end)
	pcall(function() require("ui.uieditor.widgets.HUD.ZM_Score.ZMScr_ListingSm") end)
	-- tolerate either casing across client builds
	pcall(function() require("ui.uieditor.widgets.hud.zm_score.zmscr_listinglg") end)
	pcall(function() require("ui.uieditor.widgets.hud.zm_score.zmscr_listingsm") end)

	guardListingWidget("ZMScr_ListingLg")
	guardListingWidget("ZMScr_ListingSm")

	-- ------------------------------------------------------------------
	-- 8-row points HUD (the always-on portraits/points list, left edge)
	--
	-- Stock ZMScr hard-wires exactly three teammate rows (Listing2/3/4)
	-- to ZMPlayerList indexes 1-3, stacked 26.12px apart going up, plus
	-- the local player's big row. Players 5-8 simply have no widgets.
	-- Add four more ZMScr_ListingSm rows bound to indexes 4-7, continuing
	-- the ladder upward. The row widget hides itself (alpha 0) until its
	-- slot's playerScoreShown model is nonzero, so the extra rows are
	-- invisible in <=4 player games. Row callbacks go through the same
	-- construction-time guard as the stock rows (installed above), so the
	-- slot-5-8 model gaps cannot throw.
	local function addExtraScoreRows()
		local scr = CoD.ZMScr

		if not scr or type(scr.new) ~= "function" or scr.zm8_extra_rows then
			return
		end

		local origNew = scr.new

		local newWithExtraRows = function(menu, controller, ...)
			local self = origNew(menu, controller, ...)

			pcall(function()
				if not self or not CoD.ZMScr_ListingSm then
					return
				end

				local extras = {}

				for slot = 4, 7 do
					local listing = CoD.ZMScr_ListingSm.new(menu, controller)
					local top = 0 - 26.12 * (slot - 3)
					listing:setLeftRight(true, false, 16.28, 101.28)
					listing:setTopBottom(true, false, top, top + 35)
					listing:subscribeToGlobalModel(controller, "ZMPlayerList", tostring(slot), function(model)
						pcall(function() listing:setModel(model, controller) end)
					end)
					self:addElement(listing)
					self["Listing" .. (slot + 1)] = listing
					table.insert(extras, listing)
				end

				-- stock close() only closes the stock children
				pcall(function()
					LUI.OverrideFunction_CallOriginalSecond(self, "close", function(element)
						for i = 1, #extras do
							pcall(function() extras[i]:close() end)
						end
					end)
				end)
			end)

			return self
		end

		if not pcall(function() scr.new = newWithExtraRows end) then
			pcall(function() rawset(scr, "new", newWithExtraRows) end)
		end

		pcall(function() scr.zm8_extra_rows = true end)
		pcall(function() rawset(scr, "zm8_extra_rows", true) end)
	end

	pcall(function() require("ui.uieditor.widgets.HUD.ZM_Score.ZMScr") end)
	pcall(function() require("ui.uieditor.widgets.hud.zm_score.zmscr") end)
	pcall(addExtraScoreRows)

	-- if the classes still are not defined in this UI VM yet, retry once the
	-- scoreboard menu actually opens: hook the menu factory table lazily via
	-- a metatable-free poll driven by LUI's own timer if available
	if (not CoD.ZMScr_ListingLg) and LUI and LUI.UITimer and LUI.roots then
		pcall(function()
			local attempts = 0
			local root = LUI.roots.UIRoot0

			if not root then
				return
			end

			local poller = LUI.UITimer.new(500, "zm8_scoreguard_poll")
			root:addElement(poller)
			root:registerEventHandler("zm8_scoreguard_poll", function(element, event)
				attempts = attempts + 1

				if CoD.ZMScr_ListingLg then
					guardListingWidget("ZMScr_ListingLg")
					guardListingWidget("ZMScr_ListingSm")
				end

				if CoD.ZMScr then
					pcall(addExtraScoreRows)
				end

				if (CoD.ZMScr_ListingLg and CoD.ZMScr) or attempts > 120 then
					poller:close()
				end
			end)
		end)
	end
end)
