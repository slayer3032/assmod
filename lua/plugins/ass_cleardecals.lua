
local PLUGIN = {}

PLUGIN.Name = "Clear Decals"
PLUGIN.Author = "PC Camper"
PLUGIN.Date = "2nd January 2008"
PLUGIN.Filename = PLUGIN_FILENAME
PLUGIN.ClientSide = true
PLUGIN.ServerSide = true
PLUGIN.APIVersion = 2.3
PLUGIN.Gamemodes = {}

if (SERVER) then
	function PLUGIN.Cleardecals(pl)
		if (pl:IsTempAdmin()) then
			for k, v in pairs(player.GetAll()) do v:ConCommand("r_cleardecals") end
		end
	end
	
	concommand.Add("ass_cleardecals", PLUGIN.Cleardecals)
end

if (CLIENT) then
	function PLUGIN.Cleardecals(MENUITEM)
		LocalPlayer():ConCommand("ass_cleardecals")
	end
	
	function PLUGIN.AddMenu(DMENU)			
		DMENU:AddOption( "Clear Decals", PLUGIN.Cleardecals ):SetImage( "icon16/tag_blue_delete.png" )
	end
end

ASS_RegisterPlugin(PLUGIN)
