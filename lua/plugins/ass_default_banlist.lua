local PLUGIN = {}

PLUGIN.Name = "Default Banlist"
PLUGIN.Author = "Andy Vincent, Slayer3032"
PLUGIN.Date = "23rd May 2023"
PLUGIN.Filename = PLUGIN_FILENAME
PLUGIN.ClientSide = false
PLUGIN.ServerSide = true
PLUGIN.APIVersion = 2.3
PLUGIN.Gamemodes = {}

local function dropreason(name, time, reason)
	if time == 0 then
		return name .. " is permanently banned. \nReason: \"" .. reason .. "\""
	elseif time > os.time() then
		return name .. " is banned. Time left: " .. string.NiceTime(time-os.time()) .. "\nReason: \"" .. reason .. "\""
	end
end

local firstrun = true
function PLUGIN.LoadBanlist()
	if (ASS_Config["banlist"] != PLUGIN.Name) then return end
	if !file.Exists("assmod/bans/players.txt", "DATA") then file.Write("assmod/bans/players.txt", "") return end

	local bt = ASS_GetBanTable()
	local bans = file.Read("assmod/bans/players.txt", "DATA")
	
	if (!bans or bans == "") then return end
	
	local bantable = von.deserialize(bans)

	if (#bantable == 0) then return end
	
	for k,v in pairs(bantable) do
		bt[v.ID] = {}
		bt[v.ID].Name = v.Name
		bt[v.ID].AdminName = v.AdminName
		bt[v.ID].AdminID = v.AdminID
		bt[v.ID].UnbanTime = v.UnbanTime
		bt[v.ID].Reason	= v.Reason
	end

	if firstrun then
		Msg("ASS Banlist -> Loaded "..table.Count(bt).." entries into the banlist.\n")
		firstrun = false
	end
end

function PLUGIN.SaveBanlist()
	if (ASS_Config["banlist"] != PLUGIN.Name) then return end

	local bt = ASS_GetBanTable()
	local bantbl = {}
	
	for k,v in pairs(bt) do
		local r = {}
		r.Name = v.Name
		r.ID = k
		r.UnbanTime = v.UnbanTime
		r.AdminName = v.AdminName
		r.AdminID = v.AdminID
		r.Reason = v.Reason
		table.insert(bantbl, r)
	end

	local bans = von.serialize( bantbl )
	file.Write("assmod/bans/players.txt", bans)
end

function PLUGIN.RefreshBanlist()
	if (ASS_Config["banlist"] != PLUGIN.Name) then return end
	
	PLUGIN.LoadBanlist()
	local bt = ASS_GetBanTable()
	local savetime = nil

	if bt then
		for k, v in pairs(bt) do
			if (v.UnbanTime < os.time() && v.UnbanTime != 0) then
				bt[k] = nil
				savetime = true
			end
		end
		if savetime then
			PLUGIN.SaveBanlist()
		end	
	end
end

function PLUGIN.PlayerBan(admin, pl, time, reason)
	if (ASS_Config["banlist"] != PLUGIN.Name) then return end
	PLUGIN.RefreshBanlist()
    
    local bantime = (time == 0) and 0 or (os.time()+(time*60))

	local PlayerBans = ASS_GetBanTable()
	PlayerBans[pl:AssID()] = {}
	PlayerBans[pl:AssID()].Name = pl:Nick()
	PlayerBans[pl:AssID()].AdminName = admin:Nick()
	PlayerBans[pl:AssID()].AdminID = admin:SteamID64()
	PlayerBans[pl:AssID()].UnbanTime = bantime
	PlayerBans[pl:AssID()].Reason = reason or "no reason"

	PLUGIN.SaveBanlist()
end

function PLUGIN.PlayerUnban(id, admin)
	if (ASS_Config["banlist"] != PLUGIN.Name) then return end
	local PlayerBans = ASS_GetBanTable()
	PlayerBans[id] = nil
	PLUGIN.SaveBanlist()
end

function PLUGIN.CheckBanlist(id)
	if (ASS_Config["banlist"] != PLUGIN.Name) then return end
	
	PLUGIN.RefreshBanlist()
	
	local bt = ASS_GetBanTable()
	
	if (bt[id]) then
		return bt[id]
	else
		return false
	end
end

function PLUGIN.CheckPlayer(id)
	if (ASS_Config["banlist"] != PLUGIN.Name) then return end
	local btbl = PLUGIN.CheckBanlist(id)

	if btbl then
		if btbl.UnbanTime > os.time() or btbl.UnbanTime == 0 then
			print("ASS Banlist -> Player ban loaded for "..btbl.Name.."("..id.."), dropping client...")
			ASS_DropClient(util.SteamIDFrom64(id), dropreason(btbl.Name, btbl.UnbanTime, btbl.Reason))

			local pl = ASS_FindPlayer(id) --just in case id is not a id64
			if IsValid(pl) then
				ASS_DropClient(pl:UserID(), dropreason(btbl.Name, btbl.UnbanTime, btbl.Reason))
			end
		else
			PLUGIN.PlayerUnban(id)
		end
	end
end

function PLUGIN.CheckPassword(id, ip, svpass, clpass, name)
	if (ASS_Config["banlist"] != PLUGIN.Name) then return end
	if svpass != "" and svpass != clpass then return false, "Incorrect password." end
	
	local btbl = PLUGIN.CheckBanlist(id)
	
	if btbl then
		if btbl.UnbanTime > os.time() or btbl.UnbanTime == 0 then
			return false, dropreason(name, btbl.UnbanTime, btbl.Reason)
		end
	end
end

function PLUGIN.Registered()
	if (ASS_Config["banlist"] != PLUGIN.Name) then return end
	hook.Add("CheckPassword", "ASS_CheckPassword", PLUGIN.CheckPassword)
	hook.Add("PlayerInitialSpawn", "ASS_SpawnBanCheck", function(pl) PLUGIN.CheckPlayer(pl:AssID()) end)
	PLUGIN.LoadBanlist()
end

ASS_RegisterPlugin(PLUGIN)
