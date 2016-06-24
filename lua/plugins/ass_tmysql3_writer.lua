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
			ErrorNoHalt("ASS Writer -> Cannot create ass_users table! "..err)
			chat.AddText(Color(0, 229, 238), "ASS Writer -> Cannot create ass_users table!")
		end
	end)
end

function PLUGIN.Registered()
	if ASS_Config["writer"] != PLUGIN.Name then return end

	require("tmysql")

	if !ASS_TMySQL3_DB then 
		d,e = tmysql.initialize(ASS_MySQLInfo.IP, ASS_MySQLInfo.User, ASS_MySQLInfo.Pass, ASS_MySQLInfo.DB, ASS_MySQLInfo.Port)
		if d == nil and e == nil then
			d = "D is for Database!"
			ASS_TMySQL3_DB = d
		end
		print("ASS Writer -> TMySQL3 connection initalized!")
	else
		d = ASS_TMySQL3_DB
	end
	if d then
		tmysql.query("SELECT TABLE_NAME FROM information_schema.TABLES WHERE TABLE_SCHEMA='"..ASS_MySQLInfo.DB.."' AND TABLE_NAME='ass_users'",function(res,status,err)
			if !res then error("ASS Writer -> Unable to retrieve query results! "..err) end
			if status == QUERY_FAIL then error("ASS Writer -> Error checking for user table: "..err) end
			
			if !res[1] or !res[1]["TABLE_NAME"] then
				print("ASS Writer -> Could not find ass_users table in "..ASS_MySQLInfo.DB.."! Creating...")
				CreateTable()
			elseif res[1]["TABLE_NAME"] then
				print("ASS Writer -> TMySQL3 Writer initalized!") 
			end
		end,QUERY_FLAG_ASSOC)
	else
		ErrorNoHalt("ASS Writer -> Error connecting to database: "..(e or "error"))
		chat.AddText(Color(0, 229, 238), "ASS Writer -> Error connecting to database!")
	end
end

function PLUGIN.LoadPlayerRank(pl)
	if ASS_Config["writer"] != PLUGIN.Name then return end

	if d then
		tmysql.query("SELECT plugin_data,rank FROM ass_users WHERE id="..pl:SteamID64(),function(res,status,err)
			if !res then error("ASS Writer -> Unable to retrieve query results!") end
			if status == QUERY_FAIL then error("ASS Writer -> Unable to load player rank: "..err) chat.AddText(Color(0, 229, 238), "ASS Writer -> Cannot load player rank! MySQL Error!") end

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
		ErrorNoHalt("ASS Writer -> Cannot load player rank! MySQL could not connect to database!")
		chat.AddText(Color(0, 229, 238), "ASS Writer -> Cannot load player rank! MySQL could not connect to database!")
	end
end

function PLUGIN.SavePlayerRank(pl)
	if ASS_Config["writer"] != PLUGIN.Name then return end
	if d then
		tmysql.query("INSERT INTO ass_users (id,plugin_data,rank) VALUES("..pl:SteamID64()..",'"..tmysql.escape(von.serialize(pl.ASSPluginValues)).."',"..pl:GetAssLevel()..") ON DUPLICATE KEY UPDATE plugin_data='"..von.serialize(pl.ASSPluginValues).."',rank="..pl:GetAssLevel())
	else
		ErrorNoHalt("ASS Writer -> Cannot save player rank! MySQL could not connect to database!")
		chat.AddText(Color(0, 229, 238), "ASS Writer -> Cannot save player rank! MySQL could not connect to database!")
	end
end

ASS_RegisterPlugin(PLUGIN)
