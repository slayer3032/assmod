local PLUGIN = {}

PLUGIN.Name = "TMySQL4 Banlist"
PLUGIN.Author = "Slayer3032"
PLUGIN.Date = "21st June 2016"
PLUGIN.Filename = PLUGIN_FILENAME
PLUGIN.ClientSide = false
PLUGIN.ServerSide = true
PLUGIN.APIVersion = 2.3
PLUGIN.Gamemodes = {}

local d,e

local function CreateTable()
	if !d then ErrorNoHalt("ASSWriter -> Cannot create ass_bans table! MySQL could not connect to database!") chat.AddText(Color(0, 229, 238), "ASSWriter -> Cannot create ass_bans table!") end
	if !d:IsConnected() then ErrorNoHalt("ASSWriter -> Cannot create ass_bans table! MySQL not connected!") end
	d:Query("CREATE TABLE ass_bans (id BIGINT UNSIGNED NOT NULL,name TEXT NOT NULL,unbantime INT NOT NULL DEFAULT 0,reason TEXT NOT NULL,adminname TEXT NOT NULL,adminid BIGINT UNSIGNED NOT NULL,PRIMARY KEY (id))")
end

function PLUGIN.Registered()
	if ASS_Config["banlist"] != PLUGIN.Name then return end
	hook.Add("CheckPassword", "ASS_CheckPassword", PLUGIN.CheckPassword)
		require("tmysql4")

	if !ASS_TMySQL4_DB then 
		d,e = tmysql.initialize(ASS_MySQLInfo.IP, ASS_MySQLInfo.User, ASS_MySQLInfo.Pass, ASS_MySQLInfo.DB, ASS_MySQLInfo.Port)
		print("ASSWriter -> TMySQL4 connection initalized!")
	else
		d = ASS_TMySQL4_DB
	end
	if e then
		ErrorNoHalt("ASSWriter -> Error connecting to database: "..e or "error")
		chat.AddText(Color(0, 229, 238), "ASSWriter -> Error connecting to database!")
	else
		d:Query("SELECT TABLE_NAME FROM information_schema.TABLES WHERE TABLE_SCHEMA='"..ASS_MySQLInfo.DB.."' AND TABLE_NAME='ass_bans'",function(res)
			if !res[1] then ErrorNoHalt("ASSWriter -> Unable to retrieve query results!") end
			if !res[1].status then ErrorNoHalt("ASSWriter -> Error checking for ban table: "..res[1].error) end
			if !res[1].data[1] then
				print("ASSWriter -> Could not find ass_bans table in "..ASS_MySQLInfo.DB.."! Creating...")
				CreateTable()
			end
			if res[1].data[1] then print("ASSWriter -> TMySQL4 Banlist initalized!") end
		end)
	end
end

function PLUGIN.LoadBanlist()
	if (ASS_Config["banlist"] != PLUGIN.Name) then return end
	
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

ASS_RegisterPlugin(PLUGIN)
