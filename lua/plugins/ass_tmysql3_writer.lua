local PLUGIN = {}

PLUGIN.Name = "TMySQL3 Writer"
PLUGIN.Author = "Phantom"
PLUGIN.Date = "June 16, 2016"
PLUGIN.Filename = PLUGIN_FILENAME
PLUGIN.ClientSide = false
PLUGIN.ServerSide = true
PLUGIN.APIVersion = 2.3
PLUGIN.Gamemodes = {}

local d,e

local function CreateTable()
	tmysql.query("CREATE TABLE ass_users (id BIGINT UNSIGNED NOT NULL,plugin_data TEXT NOT NULL,rank TINYINT UNSIGNED NULL DEFAULT 5,PRIMARY KEY (id))",function(res,status,err)
		if status == QUERY_FAIL then
			ErrorNoHalt("ASSWriter -> Cannot create ass_users table! "..err)
			chat.AddText(Color(0, 229, 238), "ASSWriter -> Cannot create ass_users table!")
		end
	end)
end

function PLUGIN.Registered()
	if ASS_Config["writer"] != PLUGIN.Name then return end

	require("tmysql")
	d,e = tmysql.initialize(ASS_MySQLInfo.IP, ASS_MySQLInfo.User, ASS_MySQLInfo.Pass, ASS_MySQLInfo.DB, ASS_MySQLInfo.Port)

	if d then
		tmysql.query("SELECT TABLE_NAME FROM information_schema.TABLES WHERE TABLE_SCHEMA='"..ASS_MySQLInfo.DB.."' AND TABLE_NAME='ass_users'",function(res,status,err)
			if !res then error("ASSWriter -> Unable to retrieve query results! "..err) end
			if status == QUERY_FAIL then error("ASSWriter -> Error checking for user table: "..err) end
			if !res[1] or !res[1]["TABLE_NAME"] then
				print("ASSWriter -> Could not find ass_users table in "..ASS_MySQLInfo.DB.."! Creating...")
				CreateTable()
			end
			if res[1]["TABLE_NAME"] then print("ASSWriter -> TMySQL4 connection initalized!") end
		end,QUERY_FLAG_ASSOC)
	else
		ErrorNoHalt("ASSWriter -> Error connecting to database: "..e or "error")
		chat.AddText(Color(0, 229, 238), "ASSWriter -> Error connecting to database!")
	end
end

function PLUGIN.LoadPlayerRank(pl)
	if ASS_Config["writer"] != PLUGIN.Name then return end

	if d then
		tmysql.query("SELECT plugin_data,rank FROM ass_users WHERE id="..pl:SteamID64(),function(res,status,err)
			if !res then error("ASSWriter -> Unable to retrieve query results!") end
			if err then error("ASSWriter -> Unable to load player rank: "..error) chat.AddText(Color(0, 229, 238), "ASSWriter -> Cannot load player rank! MySQL Error!") end 

			if res[1] then
				local x = res[1]
				local rt = {}
				rt.ASSPluginValues = x[1] and von.deserialize(x[1]) or {}
				rt.Rank = tonumber(x[2] or ASS_LVL_GUEST)
				pl:InitLevel(rt)
			else
				pl:InitLevel()
			end
		end)
	else
		ErrorNoHalt("ASSWriter -> Cannot load player rank! MySQL could not connect to database!")
		chat.AddText(Color(0, 229, 238), "ASSWriter -> Cannot load player rank! MySQL could not connect to database!")
	end
end

function PLUGIN.SavePlayerRank(pl)
	if ASS_Config["writer"] != PLUGIN.Name then return end
	if d then
		tmysql.query("INSERT INTO ass_users (id,plugin_data,rank) VALUES("..pl:SteamID64()..",'"..von.serialize(pl.ASSPluginValues).."',"..pl:GetAssLevel()..") ON DUPLICATE KEY UPDATE plugin_data='"..von.serialize(pl.ASSPluginValues).."',rank="..pl:GetAssLevel())
	else
		ErrorNoHalt("ASSWriter -> Cannot save player rank! MySQL could not connect to database!")
		chat.AddText(Color(0, 229, 238), "ASSWriter -> Cannot save player rank! MySQL could not connect to database!")
	end
end

ASS_RegisterPlugin(PLUGIN)
