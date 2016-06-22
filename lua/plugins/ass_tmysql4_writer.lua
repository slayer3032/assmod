local PLUGIN = {}

PLUGIN.Name = "TMySQL4 Writer"
PLUGIN.Author = "Phantom"
PLUGIN.Date = "December 2, 2015"
PLUGIN.Filename = PLUGIN_FILENAME
PLUGIN.ClientSide = false
PLUGIN.ServerSide = true
PLUGIN.APIVersion = 2.3
PLUGIN.Gamemodes = {}

local d,e

local function CreateTable()
	if !d then ErrorNoHalt("ASSWriter -> Cannot create ass_users table! MySQL could not connect to database!") chat.AddText(Color(0, 229, 238), "ASSWriter -> Cannot create ass_users table!") end
	if !d:IsConnected() then ErrorNoHalt("ASSWriter -> Cannot create ass_users table! MySQL not connected!") end
	d:Query("CREATE TABLE ass_users (id BIGINT UNSIGNED NOT NULL,plugin_data TEXT NOT NULL,rank TINYINT UNSIGNED NULL DEFAULT 5,PRIMARY KEY (id))")
end

function PLUGIN.Registered()
	if ASS_Config["writer"] != PLUGIN.Name then return end
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
		d:Query("SELECT TABLE_NAME FROM information_schema.TABLES WHERE TABLE_SCHEMA='"..ASS_MySQLInfo.DB.."' AND TABLE_NAME='ass_users'",function(res)
			if !res[1] then ErrorNoHalt("ASSWriter -> Unable to retrieve query results!") end
			if !res[1].status then ErrorNoHalt("ASSWriter -> Error checking for user table: "..res[1].error) end
			if !res[1].data[1] then
				print("ASSWriter -> Could not find ass_users table in "..ASS_MySQLInfo.DB.."! Creating...")
				CreateTable()
			end
			if res[1].data[1] then print("ASSWriter -> TMySQL4 Writer initalized!") end
		end)
	end
end

function PLUGIN.LoadPlayerRank(pl)
	if ASS_Config["writer"] != PLUGIN.Name then return end
	if d then
		if !d:IsConnected() then d:Connect() end

		d:Query("SELECT plugin_data,rank FROM ass_users WHERE id="..pl:SteamID64(),function(res)
			if !res[1] then error("ASSWriter -> Unable to retrieve query results!") end
			if !res[1].status then error("ASSWriter -> Error with loading play rank query: "..res[1].error) end
			if res[1].error then error("ASSWriter -> Unable to load player rank: "..error) chat.AddText(Color(0, 229, 238), "ASSWriter -> Cannot load player rank! MySQL Error!") end

			if res[1].data then
				if res[1].data[1] then
					local x = res[1].data[1]
					local rt = {}
					rt.ASSPluginValues = x["plugin_data"] and von.deserialize(x["plugin_data"]) or {}
					rt.Rank = tonumber(x["rank"] or ASS_LVL_GUEST)
					pl:InitLevel(rt)
				else
					pl:InitLevel()
				end
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
		if !d:IsConnected() then d:Connect() end
		d:Query("INSERT INTO ass_users (id,plugin_data,rank) VALUES("..pl:SteamID64()..",'"..von.serialize(pl.ASSPluginValues).."',"..pl:GetAssLevel()..") ON DUPLICATE KEY UPDATE plugin_data='"..von.serialize(pl.ASSPluginValues).."',rank="..pl:GetAssLevel())
	else
		ErrorNoHalt("ASSWriter -> Cannot save player rank! MySQL could not connect to database!")
		chat.AddText(Color(0, 229, 238), "ASSWriter -> Cannot save player rank! MySQL could not connect to database!")
	end
end

ASS_RegisterPlugin(PLUGIN)
