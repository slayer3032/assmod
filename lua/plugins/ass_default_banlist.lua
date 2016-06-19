local PLUGIN = {}

PLUGIN.Name = "Default Banlist"
PLUGIN.Author = "Andy Vincent, Slayer3032"
PLUGIN.Date = "01st May 2015"
PLUGIN.Filename = PLUGIN_FILENAME
PLUGIN.ClientSide = false
PLUGIN.ServerSide = true
PLUGIN.APIVersion = 2.3
PLUGIN.Gamemodes = {}

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
	
end

function PLUGIN.SaveBanlist(id)
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
	
	ASS_LoadBanlist()
	local bt = ASS_GetBanTable()

	if bt then
		for k, v in pairs(bt) do
			if (v.UnbanTime < os.time() && v.UnbanTime != 0) then
				bt[k] = nil
				ASS_SaveBanlist()
			end
		end
	end
	
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

function PLUGIN.CheckPassword(id, ip, svpass, clpass, name)
	if (ASS_Config["banlist"] != PLUGIN.Name) then return end
	if svpass != "" and svpass != clpass then return false, "Incorrect password." end
	
	local btbl = PLUGIN.CheckBanlist(id)
	local biptbl = PLUGIN.CheckBanlist(ip)
	
	if btbl then
		if btbl.UnbanTime == 0 then
			return false, name .. " is permanently banned. \nReason: \"" .. btbl.Reason .. "\""
		elseif btbl.UnbanTime > os.time() then
			return false, name .. " is banned. Time left: " .. string.NiceTime(btbl.UnbanTime-os.time()) .. "\nReason: \"" .. btbl.Reason .. "\""
		end
	elseif biptbl then
		if biptbl.UnbanTime == 0 then
			return false, name .. " is permanently banned. \nReason: \"" .. biptbl.Reason .. "\""
		elseif btbl.UnbanTime > os.time() then
			return false, name .. " is banned. Time left: " .. string.NiceTime(biptbl.UnbanTime-os.time()) .. "\nReason: \"" .. biptbl.Reason .. "\""
		end
	end
end

function PLUGIN.Registered()
	if ASS_Config["banlist"] != PLUGIN.Name then return end
	hook.Add("CheckPassword", "ASS_CheckPassword", PLUGIN.CheckPassword)
end

ASS_RegisterPlugin(PLUGIN)


