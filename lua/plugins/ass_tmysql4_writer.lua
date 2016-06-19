local PLUGIN = {}

PLUGIN.Name = "TMySQL4 Writer"
PLUGIN.Author = "Phantom"
PLUGIN.Date = "December 2, 2015"
PLUGIN.Filename = PLUGIN_FILENAME
PLUGIN.ClientSide = false
PLUGIN.ServerSide = true
PLUGIN.APIVersion = 2.3
PLUGIN.Gamemodes = {}

local TableFirstCheck = false

function PLUGIN.Registered()
	if ASS_Config["writer"] != PLUGIN.Name then return end
	require("tmysql4")

	local d,e = tmysql.initialize(ASS_MySQLInfo.IP, ASS_MySQLInfo.User, ASS_MySQLInfo.Pass, ASS_MySQLInfo.DB, ASS_MySQLInfo.Port)
	if e then ErrorNoHalt("Error connecting to database: "..e) end
end

function PLUGIN.AddToLog(PLAYER,ACL,ACTION)
	if ASS_Config["writer"] != PLUGIN.Name then return end

	local fn = "assmod/logs/"..ACL..".txt"
	local log = ""

	if file.Exists(fn,"DATA") then
		log = file.Read(fn,"DATA")

		if #log > 80000 then
			log = "Logs cleared!\n"
		end
	end

	log = log..os.time().." - "..ASS_FullNick(PLAYER).." -> "..ACTION.."\n"

	file.Write(fn,log)
end

local function CreateTable()
	if !d:IsConnected() then Error("Cannot create ass_users table! MySQL not connected!") end
	d:Query("CREATE TABLE ass_users (id BIGINT UNSIGNED NOT NULL,plugin_data TEXT NOT NULL,rank TINYINT UNSIGNED NULL DEFAULT 5,PRIMARY KEY (id))")
end

function PLUGIN.LoadPlayerRank(pl)
	if ASS_Config["writer"] != PLUGIN.Name then return end
	if !d:IsConnected() then d:Connect() end

	if !TableFirstCheck then
		d:Query("SELECT TABLE_NAME FROM information_schema.TABLES WHERE TABLE_SCHEMA='"..ASS_MySQLInfo.DB.."' AND TABLE_NAME='ass_users'",function(res)
			if !res[1] then Error("Unable to retrieve query results!") end
			if !res[1].status then Error("Error checking for user table: "..error) end
			if !res[1].data or !res[1].data["TABLE_NAME"] then
				print("Could not find ass_users table in "..ASS_MySQLInfo.DB.."! Creating...")
				CreateTable()
			end
			TableFirstCheck = true
		end)
	end

	d:Query("SELECT plugin_data,rank FROM ass_users WHERE id="..pl:SteamID64(),function(res)
		if !res[1] then Error("Unable to retrieve query results!") end
		if !res[1].status then Error("Error with loading play rank query: "..error) end

		if !res[1].data or !res[1].data[1] then
			pl:InitLevel()
		else
			local x = res[1].data[1]
			local rt = {}
			rt.ASSPluginValues = x["plugin_data"] and von.deserialize(x["plugin_data"]) or {}
			rt.Rank = tonumber(x["rank"] or ASS_LVL_GUEST)
			pl:InitLevel(rt)
		end
	end)
end

function PLUGIN.SavePlayerRank(pl)
	if ASS_Config["writer"] != PLUGIN.Name then return end
	if !d:IsConnected() then d:Connect() end

	d:Query("INSERT INTO ass_users (id,plugin_data,rank) VALUES("..pl:SteamID64()..",'"..von.serialize(pl.ASSPluginValues).."',"..pl:GetRank()..") ON DUPLICATE KEY UPDATE plugin_data='"..von.serialize(pl.ASSPluginValues).."',rank="..pl:GetRank())
end

ASS_RegisterPlugin(PLUGIN)
