
local PLUGIN = {}

PLUGIN.Name = "Sandbox Options"
PLUGIN.Author = "Andy Vincent"
PLUGIN.Date = "21st September 2007"
PLUGIN.Filename = PLUGIN_FILENAME
PLUGIN.ClientSide = true
PLUGIN.ServerSide = true
PLUGIN.APIVersion = 2.3
PLUGIN.Gamemodes = { "sandbox" } // only load this plugin for sandbox and it's derivatives

if (SERVER) then

	local SandboxOptions = {
		"sbox_godmode",
		"sbox_playershurtplayers",
		"sbox_weapons",
		"sbox_noclip",
		"sbox_admin_nolimits",
	}

	// !!! Fix Gmod bug !!!
	if (!ConVarExists("sbox_weapons")) then
		CreateConVar( "sbox_weapons", "1", FCVAR_NOTIFY )
	end
	
	// !!! Add functionality !!!
	if (!ConVarExists("sbox_admin_nolimits")) then
		CreateConVar( "sbox_admin_nolimits", "0", FCVAR_NOTIFY )
	end
	
	// Initialize
	for k,v in pairs(SandboxOptions) do
		umsg.PoolString(v)
	end

	ASS_NewLogLevel("ASS_ACL_SANDBOX")
	
	function PLUGIN.RetrieveOptions( PLAYER, CMD, ARGS )

		for k,v in pairs(SandboxOptions) do
			umsg.Start( "ASS_SandBoxOption", PLAYER )
			
				umsg.String(	v			)
				umsg.Short(	GetConVarNumber(v) 	)
			
			umsg.End()
		end
	end
	concommand.Add("ASS_SandboxReadOptions", PLUGIN.RetrieveOptions)

	function PLUGIN.ChangeOption( PLAYER, CMD, ARGS )
	
		if (PLAYER:IsSuperAdmin()) then
		
			if (!ARGS[1] || !ARGS[2]) then
				ASS_MessagePlayer( PLAYER, "Error!\n")
				return
			end
		
			ASS_LogAction( PLAYER, ASS_ACL_SANDBOX, "changed " .. ARGS[1] .. " from " .. GetConVarNumber(ARGS[1]) .. " to " .. ARGS[2] )
			
			game.ConsoleCommand( ARGS[1] .. " " .. ARGS[2] .. "\n" )
		end
	
	end
	concommand.Add("ASS_SandboxChangeOption", PLUGIN.ChangeOption)

	function PLUGIN.Registered()

		hook.Add("PlayerInitialSpawn", "PlayerInitialSpawn_" .. PLUGIN.Filename, 
			function (PL) 
				PLUGIN.RetrieveOptions(PL, "ASS_SandboxReadOptions", {} )
			end
		)
		
	end
	
	local META = FindMetaTable("Player")
	if (META) then
		META.ASS_Backup_CheckLimit = META.CheckLimit
		META.ASS_Backup_GetCount = META.GetCount
		
		function META:CheckLimit( str )
			
			if (GetConVarNumber( "sbox_admin_nolimits" ) == 1) then
				if (self:IsTempAdmin())	then 
					return true
				end
			end
			
			return self:ASS_Backup_CheckLimit(str)
		end

		function META:GetCount( str, minus )
		
			if (GetConVarNumber( "sbox_admin_nolimits" ) == 1) then
				if (self:IsTempAdmin())	then 
					if (minus) then
						return 1
					else 
						return -1
					end
				end
			end
			
			return self:ASS_Backup_GetCount(str, minus)

		end
	end
	
end

if (CLIENT) then

	local SandboxOptions = {}

	usermessage.Hook( "ASS_SandBoxOption", function (UMSG)
	
			local name = UMSG:ReadString()
			local val = UMSG:ReadShort()
			
			SandboxOptions[name] = val
			
		end )
		
	function PLUGIN.ChangeOption(CMD, VAL)

		RunConsoleCommand("ASS_SandboxChangeOption", CMD, VAL)

	end

	function PLUGIN.OnOffMenu(MENU, CMD, ON_VAL, OFF_VAL, ON_TXT, OFF_TXT)
	
		local Items = {}

		Items[ON_VAL] = MENU:AddOption( 	ON_TXT or "Yes",	function() PLUGIN.ChangeOption(CMD, tostring(ON_VAL)) end 	)
		Items[OFF_VAL] = MENU:AddOption(	OFF_TXT or "No",	function() PLUGIN.ChangeOption(CMD, tostring(OFF_VAL)) end	)

		if (Items[ SandboxOptions[CMD] ]) then
			Items[ SandboxOptions[CMD] ]:SetImage("icon16/tick.png")
		end
		
	end

	function PLUGIN.AddGamemodeMenu(DMENU)

       		RunConsoleCommand("ASS_SandboxReadOptions")	
			
		DMENU:AddSubMenu( "No Admin Limits",	nil, function(NEWMENU) PLUGIN.OnOffMenu(NEWMENU, "sbox_admin_nolimits",	1, 0 ) end ):SetImage( "icon16/accept.png" )
		DMENU:AddSubMenu( "Give Weapons", 		nil, function(NEWMENU) PLUGIN.OnOffMenu(NEWMENU, "sbox_weapons", 	1, 0 ) end ):SetImage( "icon16/lorry_add.png" )
		DMENU:AddSubMenu( "Noclip",		nil, function(NEWMENU) PLUGIN.OnOffMenu(NEWMENU, "sbox_noclip", 	1, 0 ) end ):SetImage( "icon16/status_offline.png" )
		DMENU:AddSubMenu( "Player Godmode",	nil, function(NEWMENU) PLUGIN.OnOffMenu(NEWMENU, "sbox_godmode", 	1, 0 ) end ):SetImage( "icon16/lightning.png" )
		DMENU:AddSubMenu( "PvP Damage",		nil, function(NEWMENU) PLUGIN.OnOffMenu(NEWMENU, "sbox_playershurtplayers", 	1, 0 ) end ):SetImage( "icon16/group_error.png" )

	end

end

ASS_RegisterPlugin(PLUGIN)
