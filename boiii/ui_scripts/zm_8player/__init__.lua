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

-- console diagnostics: the boiii client routes lua print() to its console,
-- so every stage reports what it found - grep the console for "zm8lua"
local function dbg(msg)
	pcall(function() print("zm8lua: " .. msg) end)
end

pcall(function()
	dbg("ui script loaded, in-game=" .. tostring(Engine.IsInGame and Engine.IsInGame() or false))

	-- make sure the widget classes exist before we wrap them (both casings;
	-- module names may be registered either way across client builds)
	pcall(function() require("ui.uieditor.widgets.HUD.ZM_Score.ZMScr_ListingLg") end)
	pcall(function() require("ui.uieditor.widgets.HUD.ZM_Score.ZMScr_ListingSm") end)
	pcall(function() require("ui.uieditor.widgets.hud.zm_score.zmscr_listinglg") end)
	pcall(function() require("ui.uieditor.widgets.hud.zm_score.zmscr_listingsm") end)

	dbg("after require: ListingLg=" .. tostring(CoD.ZMScr_ListingLg ~= nil)
		.. " ListingSm=" .. tostring(CoD.ZMScr_ListingSm ~= nil))

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

	dbg("after ZMScr require: ZMScr=" .. tostring(CoD.ZMScr ~= nil)
		.. " ctorWrapped=" .. tostring(CoD.ZMScr ~= nil and CoD.ZMScr.zm8_extra_rows == true))

	-- ------------------------------------------------------------------
	-- Score colors for players 5-8 AND the real fix for the LUI error.
	--
	-- ZombieClientScoreboardColor/GlowColor read the engine color dvars
	-- cg_ScoresColor_Gamertag_<clientNum>, which only exist for 0-3. For
	-- clients 4-7 the dvar lookup returns a boolean and the glow variant
	-- multiplies it ("operator * is not supported for boolean * number" -
	-- the exact error thrown since the first 5+ game), while the plain
	-- variant leaves rows colorless. Wrap both globals: clients 4-7 get
	-- their own colors, anything unexpected degrades to white.
	local ZM8_EXTRA_COLORS = {
		[4] = { 1.00, 0.55, 0.10 }, -- orange
		[5] = { 0.75, 0.35, 1.00 }, -- purple
		[6] = { 1.00, 0.45, 0.70 }, -- pink
		[7] = { 0.25, 0.95, 0.85 }, -- teal
	}

	local colorWrapsInstalled = false

	local function installColorWraps()
		if colorWrapsInstalled then
			return true
		end

		local origColor = ZombieClientScoreboardColor
		local origGlow = ZombieClientScoreboardGlowColor

		if type(origColor) ~= "function" or type(origGlow) ~= "function" then
			return false
		end

		ZombieClientScoreboardColor = function(clientNum)
			local c = ZM8_EXTRA_COLORS[clientNum]

			if c then
				return c[1], c[2], c[3]
			end

			local ok, r, g, b = pcall(origColor, clientNum)

			if ok and type(r) == "number" then
				return r, g, b
			end

			return 1, 1, 1
		end

		ZombieClientScoreboardGlowColor = function(clientNum)
			local c = ZM8_EXTRA_COLORS[clientNum]

			if c then
				return c[1] * 0.75, c[2] * 0.75, c[3] * 0.75
			end

			local ok, r, g, b = pcall(origGlow, clientNum)

			if ok and type(r) == "number" then
				return r, g, b
			end

			return 0.75, 0.75, 0.75
		end

		colorWrapsInstalled = true
		dbg("scoreboard color wraps installed (clients 4-7 colored, glow error fixed)")
		return true
	end

	pcall(installColorWraps)

	-- ------------------------------------------------------------------
	-- Live-instance injection: if the HUD widget was ALREADY constructed
	-- before this script ran (observed in-game: constructor wrap had no
	-- effect), find the live ZMScr element in the UI trees by its id and
	-- add the four extra rows to it directly.
	local function findInstances(node, id, depth, results)
		if not node or depth > 14 or #results >= 4 then
			return
		end

		if node.id == id then
			table.insert(results, node)
		end

		local child = nil
		pcall(function() child = node:getFirstChild() end)

		while child do
			findInstances(child, id, depth + 1, results)
			local nextChild = nil
			pcall(function() nextChild = child:getNextSibling() end)
			child = nextChild
		end
	end

	local function findMenuFor(element)
		local node = element
		local hops = 0

		while node and hops < 14 do
			if type(node.updateElementState) == "function" then
				return node
			end

			local parent = nil
			pcall(function() parent = node:getParent() end)
			node = parent
			hops = hops + 1
		end

		return nil
	end

	local function injectRowsIntoInstance(instance)
		if instance.zm8_rows_added then
			return true
		end

		if not CoD.ZMScr_ListingSm then
			dbg("inject: ZMScr_ListingSm class missing")
			return false
		end

		local menu = findMenuFor(instance)

		if not menu then
			dbg("inject: no menu found above ZMScr instance")
			return false
		end

		local controller = menu.m_ownerController
			or instance.m_ownerController
			or (LUI.roots and LUI.roots.UIRoot0 and LUI.roots.UIRoot0.m_ownerController)

		if controller == nil then
			dbg("inject: no controller found; trying nil")
		end

		local ok = pcall(function()
			for slot = 4, 7 do
				local listing = CoD.ZMScr_ListingSm.new(menu, controller)
				local top = 0 - 26.12 * (slot - 3)
				listing:setLeftRight(true, false, 16.28, 101.28)
				listing:setTopBottom(true, false, top, top + 35)
				listing:subscribeToGlobalModel(controller, "ZMPlayerList", tostring(slot), function(model)
					pcall(function() listing:setModel(model, controller) end)
				end)
				instance:addElement(listing)
				instance["Listing" .. (slot + 1)] = listing
			end
		end)

		if ok then
			instance.zm8_rows_added = true
			dbg("inject: added rows 5-8 to live ZMScr instance")
		else
			dbg("inject: row construction failed")
		end

		return ok
	end

	-- 8-row TAB scoreboard: the zombies match scoreboard is
	-- ScoreboardWidgetCP whose player list (a UIList with id "Team1",
	-- default vertical count 9) gets clamped to 4 visible slots by its
	-- parent. Rows are 25px so 8 slots fit the same area without scaling.
	-- Three angles, because the previous id-walk alone did not land:
	-- wrap the class constructor, walk for the widget id, and walk for the
	-- row list's own "Team1" id directly (zombies sessions only).
	local tabPatched = false

	local function raiseListCount(lst, where)
		local ok = pcall(function() lst:setVerticalCount(8) end)

		if ok then
			tabPatched = true
			dbg("TAB scoreboard list raised to 8 slots (" .. where .. ")")
		else
			dbg("TAB scoreboard setVerticalCount failed (" .. where .. ")")
		end

		return ok
	end

	pcall(function()
		local sbClass = CoD.ScoreboardWidgetCP

		if sbClass and type(sbClass.new) == "function" and not sbClass.zm8_wrapped then
			local origSbNew = sbClass.new

			local wrapped = function(...)
				local inst = origSbNew(...)
				pcall(function()
					if inst and inst.ScoreboardFactionScoresListCP0 and inst.ScoreboardFactionScoresListCP0.Team1 then
						raiseListCount(inst.ScoreboardFactionScoresListCP0.Team1, "constructor")
					end
				end)
				return inst
			end

			if not pcall(function() sbClass.new = wrapped end) then
				pcall(function() rawset(sbClass, "new", wrapped) end)
			end

			pcall(function() sbClass.zm8_wrapped = true end)
			dbg("ScoreboardWidgetCP constructor wrapped")
		end
	end)

	local dumpedTree = false

	local function dumpIdTree(node, depth)
		if not node or depth > 3 then
			return
		end

		if node.id then
			dbg(string.rep("  ", depth) .. "id=" .. tostring(node.id))
		end

		local child = nil
		pcall(function() child = node:getFirstChild() end)

		while child do
			dumpIdTree(child, depth + 1)
			local nxt = nil
			pcall(function() nxt = child:getNextSibling() end)
			child = nxt
		end
	end

	local function patchTabScoreboard()
		if tabPatched or not (LUI and LUI.roots) then
			return tabPatched
		end

		for _, rootName in ipairs({ "UIRoot0", "UIRootFull", "UIRoot1" }) do
			local root = LUI.roots[rootName]

			if root then
				-- primary: the widget by its id, then its known child path
				local found = {}
				pcall(function() findInstances(root, "ScoreboardWidgetCP", 0, found) end)

				for i = 1, #found do
					local sb = found[i]

					pcall(function()
						if sb.ScoreboardFactionScoresListCP0 and sb.ScoreboardFactionScoresListCP0.Team1 then
							raiseListCount(sb.ScoreboardFactionScoresListCP0.Team1, "widget walk/" .. rootName)
						end
					end)
				end

				-- fallback: the row list registers its own id ("Team1")
				if not tabPatched then
					local lists = {}
					pcall(function() findInstances(root, "Team1", 0, lists) end)

					for i = 1, #lists do
						if type(lists[i].setVerticalCount) == "function" then
							raiseListCount(lists[i], "Team1 walk/" .. rootName)
						end
					end
				end
			end
		end

		return tabPatched
	end

	local function tryInjectLive()
		if not (LUI and LUI.roots) then
			return false
		end

		local injected = false

		for _, rootName in ipairs({ "UIRoot0", "UIRootFull", "UIRoot1" }) do
			local root = LUI.roots[rootName]

			if root then
				local found = {}
				pcall(function() findInstances(root, "ZMScr", 0, found) end)

				if #found > 0 then
					dbg("found " .. #found .. " ZMScr instance(s) under " .. rootName)
				end

				for i = 1, #found do
					if injectRowsIntoInstance(found[i]) then
						injected = true
					end
				end
			end
		end

		pcall(installColorWraps)
		pcall(patchTabScoreboard)

		return injected
	end

	pcall(tryInjectLive)

	-- keep retrying: the HUD builds when a map loads, which can be after
	-- this script runs. Also re-attempt the class wraps for late VMs.
	if LUI and LUI.UITimer and LUI.roots then
		pcall(function()
			local attempts = 0
			local root = LUI.roots.UIRoot0 or LUI.roots.UIRootFull

			if not root then
				dbg("poller: no UI root available")
				return
			end

			local poller = LUI.UITimer.new(1000, "zm8_scoreguard_poll")
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

				local done = false
				pcall(function() done = tryInjectLive() end)

				-- if the HUD rows landed but the TAB board still is not
				-- found after a while, dump the UI id tree once so the
				-- console shows what the scoreboard is actually called
				if done and not tabPatched and attempts == 30 and not dumpedTree then
					dumpedTree = true
					pcall(function()
						dbg("TAB board not found yet - id tree of UIRoot0:")
						dumpIdTree(LUI.roots.UIRoot0, 0)
					end)
				end

				if (done and colorWrapsInstalled and tabPatched) or attempts > 300 then
					dbg("poller finished, attempts=" .. attempts .. " injected=" .. tostring(done)
						.. " colors=" .. tostring(colorWrapsInstalled)
						.. " tab=" .. tostring(tabPatched))
					poller:close()
				end
			end)
			dbg("poller installed")
		end)
	else
		dbg("poller unavailable (no LUI.UITimer/roots)")
	end
end)
