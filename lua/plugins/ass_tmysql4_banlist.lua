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

end

function PLUGIN.SaveBanlist(id)
	if (ASS_Config["banlist"] != PLUGIN.Name) then return end

end

function PLUGIN.RefreshBanlist()
	if (ASS_Config["banlist"] != PLUGIN.Name) then return end
	
end

function PLUGIN.CheckBanlist(id)
	if (ASS_Config["banlist"] != PLUGIN.Name) then return end
	
end

function PLUGIN.CheckPassword(id, ip, svpass, clpass, name)
	if (ASS_Config["banlist"] != PLUGIN.Name) then return end
end

--hook.Add("CheckPassword", "ASS_CheckPassword", PLUGIN.CheckPassword)

ASS_RegisterPlugin(PLUGIN)
