
local PLUGIN = {}

PLUGIN.Name = "Voice"
PLUGIN.Author = "Slayer3032"
PLUGIN.Date = "25th September 2012"
PLUGIN.Filename = PLUGIN_FILENAME
PLUGIN.ClientSide = true
PLUGIN.ServerSide = true
PLUGIN.APIVersion = 2.3
PLUGIN.Gamemodes = {}

if (SERVER) then

	hook.Add("PlayerCanHearPlayersVoice", "PlayerCanHearPlayersVoice_" .. PLUGIN.Filename, function(listener, talker)
		if !IsValid(talker) then return end
		if talker.VoiceMuted then return false end
		if ASS_Config["proximity_talk"] then
			return true, true
		elseif ASS_Config["alltalk"] then
			return true
		end
	end)
	
	hook.Add("InitPostEntity", "InitPostEntity_" .. PLUGIN.Filename, function()
		if ASS_Config["alltalk"] != nil then 
			SetGlobalBool( "ASS_Alltalk", ASS_Config["alltalk"])
		else
			ASS_Config["alltalk"] = false
			ASS_WriteConfig()
			SetGlobalBool( "ASS_Alltalk", ASS_Config["alltalk"])
		end
		
		if ASS_Config["proximity_talk"] != nil then 
			SetGlobalBool( "ASS_Proxtalk", ASS_Config["proximity_talk"])
		else
			ASS_Config["proximity_talk"] = false
			ASS_WriteConfig()
			SetGlobalBool( "ASS_Proxtalk", ASS_Config["proximity_talk"])
		end
	end)
	
	concommand.Add("ass_setalltalk",function(PLAYER, CMD, ARGS)
		if (PLAYER:HasAssLevel(ASS_LVL_SERVER_OWNER)) then
			if (!tobool(ARGS[1])) then
				ASS_LogAction( PLAYER, ASS_ACL_SETTING, "turned alltalk voice off")
				ASS_Config["alltalk"] = false
				ASS_WriteConfig()
				SetGlobalBool( "ASS_Alltalk", false )
			elseif (tobool(ARGS[1])) then 
				ASS_LogAction( PLAYER, ASS_ACL_SETTING, "turned alltalk voice on")
				ASS_Config["alltalk"] = true
				ASS_WriteConfig()
				SetGlobalBool( "ASS_Alltalk", true )
			end
		else
			ASS_MessagePlayer( PLAYER, "Access denied!")
		end
	
	end
	)
	
	concommand.Add("ass_setproxtalk",function(PLAYER, CMD, ARGS)
		if (PLAYER:HasAssLevel(ASS_LVL_SERVER_OWNER)) then
			if (!tobool(ARGS[1])) then
				ASS_LogAction( PLAYER, ASS_ACL_SETTING, "turned proximity voice off")
				ASS_Config["proximity_talk"] = false
				ASS_WriteConfig()
				SetGlobalBool( "ASS_Proxtalk", false )
			elseif (tobool(ARGS[1])) then 
				ASS_LogAction( PLAYER, ASS_ACL_SETTING, "turned proximity voice on")
				ASS_Config["proximity_talk"] = true
				ASS_WriteConfig()
				SetGlobalBool( "ASS_Proxtalk", true )
			end
		else
			ASS_MessagePlayer( PLAYER, "Access denied!")
		end
	
	end
	)
end

if (CLIENT) then
	function PLUGIN.AddSetting(SUBMENU)
		SUBMENU:AddSubMenu("Alltalk", nil, function(MENU)
			local Items = {}
			Items[1] = MENU:AddOption("Yes", function() RunConsoleCommand("ASS_SetAlltalk", "1") end )
			Items[0] = MENU:AddOption("No",	function() RunConsoleCommand("ASS_SetAlltalk", "0") end )
		
			local Mode = GetGlobalBool("ASS_Alltalk") and 1 or 0
			if (Items[Mode]) then
				Items[Mode]:SetImage("icon16/tick.png")
			end
		end):SetImage("icon16/group_link.png")
		
		SUBMENU:AddSubMenu("Proximity Voice", nil, function(MENU)
			local Items = {}
			Items[1] = MENU:AddOption("Yes", function() RunConsoleCommand("ASS_SetProxtalk", "1") end )
			Items[0] = MENU:AddOption("No",	function() RunConsoleCommand("ASS_SetProxtalk", "0") end )
		
			local Mode = GetGlobalBool("ASS_Proxtalk") and 1 or 0
			if (Items[Mode]) then
				Items[Mode]:SetImage("icon16/tick.png")
			end
		end):SetImage("icon16/transmit.png")
	end
end

ASS_RegisterPlugin(PLUGIN)


