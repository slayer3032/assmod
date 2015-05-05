
local PLUGIN = {}

PLUGIN.Name = "Sandbox Spam Protection"
PLUGIN.Author = "Andy Vincent"
PLUGIN.Date = "31st January 2007"
PLUGIN.Filename = PLUGIN_FILENAME
PLUGIN.ClientSide = true
PLUGIN.ServerSide = true
PLUGIN.APIVersion = 2.3
PLUGIN.Gamemodes = { "sandbox" } // only load this plugin for sandbox and it's derivatives

if (SERVER) then

	ASS_NewLogLevel("ASS_ACL_SANDBOX")
	
	function PLUGIN.ValidSpamMode( MODE )
		if (	MODE != 0 && 
			MODE != 0.25 &&
			MODE != 0.5 &&
			MODE != 0.75 &&
			MODE != 1 &&
			MODE != 1.5 &&
			MODE != 2 &&
			MODE != 3 &&
			MODE != 4 ) then return false end
			
		return true
	end
	
	function PLUGIN.GetProtectionMode(TYPE)
	
		local mode = tonumber( ASS_Config["spam_" .. TYPE .. "_protection"] )
		
		if (!PLUGIN.ValidSpamMode(mode)) then
			ASS_Config["spam_" .. TYPE .. "_protection"] = 0
			ASS_WriteConfig()
			
			mode = tonumber( ASS_Config["spam_" .. TYPE .. "_protection"] )
		end
		
		return mode
	
	end
	
	function PLUGIN.IsDuplicatorRunning(PLAYER)

		// The duplicator is a bit hacky, and does everything in one
		// frame. Therefore the CurTime() when CanTool is called and
		// now /should/ be the same.
		
		if (PLAYER.ASS_DuplicatorTime) then
		
			if (CurTime() == PLAYER.ASS_DuplicatorTime) then
				return true			
			else
				PLAYER.ASS_DuplicatorTime = nil
			end
		end
		
		return false
		
	end
	
	function PLUGIN.IsAdvDupeRunning(PLAYER)

		// The advanced duplicator does things nicely :)

		return (AdvDupe && AdvDupe[PLAYER] && AdvDupe[PLAYER].Pasting)
		
	end
	
	function PLUGIN.IsContraptionSaverRunning(PLAYER)
	
		// Conna's contraption saver also does things nicely :)
	
		return (css && css.Players && css.Players[PLAYER].Spawning && css.Players[PLAYER].Active)
	
	end
	
	function PLUGIN.CanSpawnObject( PLAYER, TYPE )
	
		local DELAY = PLUGIN.GetProtectionMode(TYPE)
		
		if (!PLAYER.ASS_SpamTimer) then
		
			PLAYER.ASS_SpamTimer = {}
			PLAYER.ASS_SpamTimer["spawn"] = 0
			PLAYER.ASS_SpamTimer["tool"] = 0
			
		end
		
		if (DELAY != 0) then
			if (PLAYER.ASS_SpamTimer[TYPE]) then -- DarkRP compliance (!PLAYER:IsRespected() &&)
			
				if (	TYPE == "spawn" &&
					(PLUGIN.IsDuplicatorRunning(PLAYER) ||
					PLUGIN.IsAdvDupeRunning(PLAYER) || 
					PLUGIN.IsContraptionSaverRunning(PLAYER))) then
					
					// this handles if we're running the advanced duplicator...
					PLAYER.ASS_SpamTimer[TYPE] = CurTime()
					return true
					
				end
			
				if ((CurTime() - PLAYER.ASS_SpamTimer[TYPE]) < DELAY) then
					return false
				end
			end
		end

		PLAYER.ASS_SpamTimer[TYPE] = CurTime()
		return true
	end
	
	function PLUGIN.CanSpawnObjectMsg( PLAYER, TYPE )
	
		if (!PLUGIN.CanSpawnObject(PLAYER, TYPE)) then
		
			local DELAY = PLUGIN.GetProtectionMode(TYPE)
			local TIME = DELAY - (CurTime() - PLAYER.ASS_SpamTimer[TYPE])

			if (TIME > 0) then
				ASS_MessagePlayer(PLAYER, "Creating stuff to fast! Slow down! Wait " .. string.format("%.2f", TIME) .. " seconds")
			else
				ASS_MessagePlayer(PLAYER, "Creating stuff to fast! Slow down!")
			end
			return false
			
		end
		
		return true
	
	end

	function PLUGIN.PlayerSpawnRagdoll(PLAYER)	if (!PLUGIN.CanSpawnObjectMsg(PLAYER, "spawn")) then return false end	end
	function PLUGIN.PlayerSpawnProp(PLAYER)		if (!PLUGIN.CanSpawnObjectMsg(PLAYER, "spawn")) then return false end	end
	function PLUGIN.PlayerSpawnEffect(PLAYER)	if (!PLUGIN.CanSpawnObjectMsg(PLAYER, "spawn")) then return false end	end
	function PLUGIN.PlayerSpawnVehicle(PLAYER)	if (!PLUGIN.CanSpawnObjectMsg(PLAYER, "spawn")) then return false end	end
	function PLUGIN.PlayerSpawnSENT(PLAYER)		if (!PLUGIN.CanSpawnObjectMsg(PLAYER, "spawn")) then return false end	end
	function PLUGIN.PlayerSpawnNPC(PLAYER)		if (!PLUGIN.CanSpawnObjectMsg(PLAYER, "spawn")) then return false end	end
		
	function PLUGIN.CanTool( PLAYER, TRACE, MODE)
	
		if (MODE == "duplicator") then
			PLAYER.ASS_DuplicatorTime = CurTime()
		end
		
		if (!PLUGIN.CanSpawnObjectMsg(PLAYER, "tool")) then
			return false
		end

	end
	
	function PLUGIN.InitPostEntity()
		SetGlobalString( "ASS_SpamtoolProtect", tostring( PLUGIN.GetProtectionMode("tool") ) )
		SetGlobalString( "ASS_SpamspawnProtect", tostring( PLUGIN.GetProtectionMode("spawn") ) )
	end
	
	function PLUGIN.Registered()
		hook.Add("InitPostEntity",		"InitPostEntity_" .. PLUGIN.Filename, 		PLUGIN.InitPostEntity )
		hook.Add("CanTool", 			"CanTool_" .. PLUGIN.Filename, 			PLUGIN.CanTool )
		hook.Add("PlayerSpawnRagdoll", 		"PlayerSpawnRagdoll_" .. PLUGIN.Filename, 	PLUGIN.PlayerSpawnRagdoll )
		hook.Add("PlayerSpawnProp", 		"PlayerSpawnProp_" .. PLUGIN.Filename, 		PLUGIN.PlayerSpawnProp )
		hook.Add("PlayerSpawnEffect", 		"PlayerSpawnEffect_" .. PLUGIN.Filename, 	PLUGIN.PlayerSpawnEffect )
		hook.Add("PlayerSpawnVehicle", 		"PlayerSpawnVehicle_" .. PLUGIN.Filename, 	PLUGIN.PlayerSpawnVehicle )
		hook.Add("PlayerSpawnSENT", 		"PlayerSpawnSENT_" .. PLUGIN.Filename, 		PLUGIN.PlayerSpawnSENT )
		hook.Add("PlayerSpawnNPC", 		"PlayerSpawnNPC_" .. PLUGIN.Filename, 		PLUGIN.PlayerSpawnNPC )
	end
	
	function PLUGIN.SpamProtectMode(PLAYER, CMD, ARGS)
	
		if (PLAYER:HasAssLevel(ASS_LVL_TEMPADMIN)) then
		
			if (!ARGS[1]) then return end
			if (!ARGS[2]) then return end
			if ((ARGS[1] != "spawn") && (ARGS[1] != "tool")) then return end
			
			local TIME = tonumber(ARGS[2])
			if (!PLUGIN.ValidSpamMode(TIME)) then return end
				
			if (TIME == 0) then
				ASS_LogAction( PLAYER, ASS_ACL_SANDBOX, "set " .. ARGS[1] .. "-spam protection to off")
			else
				ASS_LogAction( PLAYER, ASS_ACL_SANDBOX, "set " .. ARGS[1] .. "-spam protection to " .. TIME .. " seconds")
			end

			ASS_Config["spam_" .. ARGS[1] .. "_protection"] = TIME
			ASS_WriteConfig()
			SetGlobalString( "ASS_Spam" .. ARGS[1] .. "Protect", tostring( PLUGIN.GetProtectionMode(ARGS[1]) ) )

		else
			ASS_MessagePlayer( PLAYER, "Access denied!")
		end
	
	end
	concommand.Add("ASS_SpamProtect", PLUGIN.SpamProtectMode)
	
end

if (CLIENT) then

	function PLUGIN.SpamProtectionTime(MENU, CMD)
		local Items = {}
		
		Items["0"] = MENU:AddOption("Off",		function() RunConsoleCommand("ASS_SpamProtect", CMD, 0) end )
		Items["0.25"] = MENU:AddOption("1/4 second",	function() RunConsoleCommand("ASS_SpamProtect", CMD, 0.25) end )
		Items["0.5"] = MENU:AddOption("1/2 second",	function() RunConsoleCommand("ASS_SpamProtect", CMD, 0.5) end )
		Items["0.75"] = MENU:AddOption("3/4 second",	function() RunConsoleCommand("ASS_SpamProtect", CMD, 0.75) end )
		Items["1"] = MENU:AddOption("1 second",		function() RunConsoleCommand("ASS_SpamProtect", CMD, 1) end )
		Items["1.5"] = MENU:AddOption("1.5 second",	function() RunConsoleCommand("ASS_SpamProtect", CMD, 1.5) end )
		Items["2"] = MENU:AddOption("2 second",		function() RunConsoleCommand("ASS_SpamProtect", CMD, 2) end )
		Items["3"] = MENU:AddOption("3 second",		function() RunConsoleCommand("ASS_SpamProtect", CMD, 3) end )
		Items["4"] = MENU:AddOption("4 second",		function() RunConsoleCommand("ASS_SpamProtect", CMD, 4) end )

		local Mode = GetGlobalString("ASS_Spam" .. CMD .. "Protect")
		if (Items[Mode]) then
			Items[Mode]:SetImage("icon16/tick.png")
		end

	end

	function PLUGIN.SpamProtection(MENU)
		MENU:AddSubMenu( "Spawning",	nil, function(NEWMENU) PLUGIN.SpamProtectionTime(NEWMENU, "spawn") end ):SetImage("icon16/wrench_orange.png")
		MENU:AddSubMenu( "Tool",	nil, function(NEWMENU) PLUGIN.SpamProtectionTime(NEWMENU, "tool") end ):SetImage("icon16/wand.png")
	end

	function PLUGIN.AddGamemodeMenu(DMENU)			

		DMENU:AddSubMenu( "Spam Protection" , nil, PLUGIN.SpamProtection ):SetImage("icon16/brick_delete.png")

	end
		
end

ASS_RegisterPlugin(PLUGIN)
