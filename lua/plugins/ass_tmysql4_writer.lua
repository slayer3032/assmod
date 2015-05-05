local PLUGIN = {}

PLUGIN.Name = "TMySQL4 Writer"
PLUGIN.Author = ""
PLUGIN.Date = "01st May 2015"
PLUGIN.Filename = PLUGIN_FILENAME
PLUGIN.ClientSide = false
PLUGIN.ServerSide = true
PLUGIN.APIVersion = 2.3
PLUGIN.Gamemodes = {}

--local assdb, sqlerr = tmysql.initialize(ASS_MySQLInfo.IP, ASS_MySQLInfo.User, ASS_MySQLInfo.Pass, ASS_MySQLInfo.DB, ASS_MySQLInfo.Port)

function PLUGIN.AddToLog(PLAYER, ACL, ACTION)
	if (ASS_Config["writer"] != PLUGIN.Name) then return end
	
end

function PLUGIN.LoadPlayerRank(pl)
	if (ASS_Config["writer"] != PLUGIN.Name) then return false end

end

function PLUGIN.SavePlayerRank(pl)
	if (ASS_Config["writer"] != PLUGIN.Name) then return end
	
end

ASS_RegisterPlugin(PLUGIN)


