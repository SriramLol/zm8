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
