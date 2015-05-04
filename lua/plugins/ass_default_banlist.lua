local PLUGIN = {}

PLUGIN.Name = "Default Banlist"
PLUGIN.Author = "Andy Vincent, Slayer3032"
PLUGIN.Date = "01st May 2015"
PLUGIN.Filename = PLUGIN_FILENAME
PLUGIN.ClientSide = false
PLUGIN.ServerSide = true
PLUGIN.APIVersion = 2.3
PLUGIN.Gamemodes = {}

 --totally not copypaste of the old default writer code, I swear
function PLUGIN.LoadBanlist()

	if (ASS_Config["banlist"] != PLUGIN.Name) then return end

	local bt = ASS_GetBanTable()
	local bans = file.Read("assmod/ass_banlist.txt", "DATA")
	
	if (!bans || bans == "") then return end
	
	local bantable = util.KeyValuesToTable(bans)
	
	for k,v in pairs(bantable) do
		bt[v.id] = {}
		bt[v.id].Name = v.name
		bt[v.id].AdminName = v.adminname
		bt[v.id].AdminID = v.adminid
		bt[v.id].UnbanTime = v.unbantime
		bt[v.id].Reason	= v.reason
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

	local bans = util.TableToKeyValues( bantbl )
	file.Write("assmod/ass_banlist.txt", bans)
	
end

function PLUGIN.RefreshBanlist()

	if (ASS_Config["banlist"] != PLUGIN.Name) then return end
	
	--Uncomment if you for some reason run multi-instance servers on text files
	--ASS_LoadBanlist()
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

hook.Add("CheckPassword", "ASS_CheckPassword", PLUGIN.CheckPassword)

ASS_RegisterPlugin(PLUGIN)


