
local PLUGIN = {}

PLUGIN.Name = "God"
PLUGIN.Author = "Andy Vincent"
PLUGIN.Date = "10th August 2007"
PLUGIN.Filename = PLUGIN_FILENAME
PLUGIN.ClientSide = true
PLUGIN.ServerSide = true
PLUGIN.APIVersion = 2.3
PLUGIN.Gamemodes = {}

if (SERVER) then

	ASS_NewLogLevel("ASS_ACL_GOD")
	
	function PLUGIN.God( PLAYER, CMD, ARGS )

		if (PLAYER:HasAssLevel(ASS_LVL_TEMPADMIN)) then

			local TO_RECIEVE = ASS_FindPlayer(ARGS[1])
			local ENABLE = tonumber(ARGS[2]) > 0

			if (!TO_RECIEVE) then

				ASS_MessagePlayer(PLAYER, "Player not found!")
				return

			end
			
			if (PLAYER != TO_RECIEVE) then
				if (TO_RECIEVE:IsBetterOrSame(PLAYER) && !ENABLE) then

					// disallow!
					ASS_MessagePlayer(PLAYER, "Access denied! \"" .. TO_RECIEVE:Nick() .. "\" has same or better access then you.")
					return
	
				end
			end

			if (ASS_RunPluginFunction( "AllowGod", true, PLAYER, TO_RECIEVE, ENABLE )) then

				if (ENABLE) then
					TO_RECIEVE:GodEnable()
					ASS_LogAction( PLAYER, ASS_ACL_GOD, "enabled god mode for " .. ASS_FullNick(TO_RECIEVE) )
				else
					TO_RECIEVE:GodDisable()
					ASS_LogAction( PLAYER, ASS_ACL_GOD, "disabled god mode for " .. ASS_FullNick(TO_RECIEVE) )
				end
								
			end

		end

	end
	concommand.Add("ASS_God", PLUGIN.God)

end

if (CLIENT) then

	function PLUGIN.God(PLAYER, ALLOW)

		// Check if PLAYER is actually a table, or a player.
		// If it's a table, run the console command for each
		// player.
		
		if (type(PLAYER) == "table") then
			for _, ITEM in pairs(PLAYER) do
				if (IsValid(ITEM)) then
					RunConsoleCommand( "ASS_God", ITEM:AssID(), ALLOW )
				end
			end
		else
			if (!IsValid(PLAYER)) then return end
			RunConsoleCommand( "ASS_God", PLAYER:AssID(), ALLOW )
		end

	end
	
	function PLUGIN.GodEnableDisable(MENU, PLAYER)

		// Here if one of the (All Player | All Admins | All Non-Admins) items has been
		// selected, PLAYER is actually a table of players (not an individual player).
		// It doesn't really matter at this stage, since we're just passing it on to an
		// anonymous function (I love anonymous functions <3)
		
		MENU:AddOption( "Enable",	function() PLUGIN.God(PLAYER, 1) end ):SetImage( "icon16/lightning_add.png" )
		MENU:AddOption( "Disable",	function() PLUGIN.God(PLAYER, 0) end ):SetImage( "icon16/lightning_delete.png" )

	end

	function PLUGIN.AddMenu(DMENU)			
	
		// Sample usage of the new "IncludeAll" option, with the "HasSubMenu" option.
		// When GodEnableDisable is called from the called from one of the 
		// (All Player | All Admins | All Non-Admins) menus, the PLAYER parameter is
		// actually a table of players to act upon.
		
		DMENU:AddSubMenu( "God", nil, 
			function(NEWMENU) 
				ASS_PlayerMenu( NEWMENU, {"IncludeAll", "HasSubMenu","IncludeLocalPlayer"}, PLUGIN.GodEnableDisable  ) 
			end
		):SetImage( "icon16/lightning.png" )

	end

end

ASS_RegisterPlugin(PLUGIN)


