
local PLUGIN = {}

PLUGIN.Name = "No-Clip"
PLUGIN.Author = "Andy Vincent"
PLUGIN.Date = "10th August 2007"
PLUGIN.Filename = PLUGIN_FILENAME
PLUGIN.ClientSide = true
PLUGIN.ServerSide = true
PLUGIN.APIVersion = 2.3
PLUGIN.Gamemodes = {}

if (SERVER) then

	ASS_NewLogLevel("ASS_ACL_NOCLIP")
	
	function PLUGIN.SendDefaultNoclipSettings( PLAYER )
		ASS_Config["default_noclip"] = ASS_Config["default_noclip"] || {}
		
		umsg.Start( "ASS_DefaultNoclip", PLAYER )
			umsg.Short( ASS_Config["default_noclip"][ASS_LVL_SERVER_OWNER] || 1 )
			umsg.Short( ASS_Config["default_noclip"][ASS_LVL_SUPER_ADMIN] || 1 )
			umsg.Short( ASS_Config["default_noclip"][ASS_LVL_ADMIN] || 1 )
			umsg.Short( ASS_Config["default_noclip"][ASS_LVL_TEMPADMIN] || 1 )
			umsg.Short( ASS_Config["default_noclip"][ASS_LVL_RESPECTED] || 1 )
			umsg.Short( ASS_Config["default_noclip"][ASS_LVL_GUEST] || 1 )
			umsg.Short( ASS_Config["default_noclip"][ASS_LVL_BANNED] || 1 )
		umsg.End()	
	end
	
	function PLUGIN.PlayerInitialized( PLAYER )
		PLUGIN.SendDefaultNoclipSettings(PLAYER)
	end

	function PLUGIN.PlayerSpawn( PLAYER )
		PLAYER.ASS_Noclip = false
		PLAYER:SetNetworkedInt("ASS_noclip", PLUGIN.AllowNoclip(PLAYER) )
	end
	hook.Add("PlayerSpawn", "PlayerSpawn_" .. PLUGIN_FILENAME, PLUGIN.PlayerSpawn)

	function PLUGIN.RankingChanged( PLAYER, RANK )
		PLAYER:SetNetworkedInt("ASS_noclip", PLUGIN.AllowNoclip(PLAYER) )
	end

	function PLUGIN.AllowNoclip(PLAYER)

		local Allow = PLAYER:GetAssAttribute("noclip", "number", -1)
		if (Allow == -1) then

			// user has never been restricted, use default

			ASS_Config["default_noclip"] = ASS_Config["default_noclip"] || {}
			if (ASS_Config["default_noclip"][PLAYER:GetAssLevel()] == 0) then
			
				return 0
			
			else
			
				return 1
			
			end

		end

		if (Allow == 0) then
			return 0
		else
			return 1
		end

	end

	local IN_MY_HOOK = false
	function PLUGIN.PlayerNoClip( PLAYER )
		
		if (IN_MY_HOOK) then return end
	
		// re-call the gamemode function, allowing the call to pass through here
		// this is done to ensure that the gamemodes function take priority.
		
		IN_MY_HOOK = true
		local allow = hook.Call("PlayerNoClip", gmod.GetGamemode(), PLAYER)
		IN_MY_HOOK = false
		
		if (allow && PLUGIN.AllowNoclip(PLAYER) == 1 ) then
			PLAYER.ASS_Noclip = !PLAYER.ASS_Noclip
			return true
		end
		return false
	end
	hook.Add("PlayerNoClip", "PlayerNoClip_" .. PLUGIN_FILENAME, PLUGIN.PlayerNoClip)

	function PLUGIN.SetDefaultNoclip( PLAYER, CMD, ARGS )

		local level = tonumber( ARGS[1] )
		if (!level) then return end
		
		local allow = tonumber(ARGS[2])
		if (!allow) then return end
		
		if (PLAYER:HasAssLevel(ASS_LVL_SERVER_OWNER) || level > PLAYER:GetAssLevel() ) then
			ASS_Config["default_noclip"] = ASS_Config["default_noclip"] || {}
			ASS_Config["default_noclip"][level] = allow
			ASS_WriteConfig()
			
			ASS_LogAction( PLAYER, ASS_ACL_NOCLIP, "changed the default allowed level for " .. ASS_LevelToString(level) .. " to " .. tostring(allow) )
			
			PLUGIN.SendDefaultNoclipSettings()
			
			for k, v in pairs(player.GetAll()) do
				if v:GetAssLevel() == level then
					v:SetNetworkedInt("ASS_noclip", PLUGIN.AllowNoclip(v))
				end
			end
		else
			ASS_MessagePlayer(PLAYER, "Access denied!")
		end
		
	end
	concommand.Add("ASS_SetDefaultNoClipPriv", PLUGIN.SetDefaultNoclip)
	
	function PLUGIN.NoclipPriv( PLAYER, CMD, ARGS )

		if (PLAYER:HasAssLevel(ASS_LVL_TEMPADMIN)) then

			local TO_RECIEVE = ASS_FindPlayer(ARGS[1])
			local ALLOW = tonumber(ARGS[2])

			if (ALLOW != 0 && ALLOW != 1 && ALLOW != -1) then
				return
			end

			if (!TO_RECIEVE) then

				ASS_MessagePlayer(PLAYER, "Player not found!")
				return

			end
			
			if (TO_RECIEVE:IsBetterOrSame(PLAYER)) then

				// disallow!
				ASS_MessagePlayer(PLAYER, "Access denied! \"" .. TO_RECIEVE:Nick() .. "\" has same or better access then you.")
				return

			end

			if (ASS_RunPluginFunction( "AllowNoClipPriv", true, PLAYER, TO_RECIEVE, ALLOW )) then

				if (!ALLOW) then
				
					if (TO_RECIEVE.ASS_Noclip) then
						TO_RECIEVE:Spawn()
					end
					
				end
				
				TO_RECIEVE:SetAssAttribute("noclip", ALLOW)
				TO_RECIEVE:SetNetworkedInt("ASS_noclip", ALLOW )
				
				if (ALLOW == 1) then
					ASS_LogAction( PLAYER, ASS_ACL_NOCLIP, "gave noclip privalages to " .. ASS_FullNick(TO_RECIEVE) )
				elseif (ALLOW == 0) then
					ASS_LogAction( PLAYER, ASS_ACL_NOCLIP, "took noclip privalages from " .. ASS_FullNick(TO_RECIEVE) )
				elseif (ALLOW == -1) then
					ASS_LogAction( PLAYER, ASS_ACL_NOCLIP, "set noclip privalages to default for " .. ASS_FullNick(TO_RECIEVE) )
				end
				
			end

		end

	end
	concommand.Add("ASS_SetNoClipPriv", PLUGIN.NoclipPriv)

end

if (CLIENT) then

	PLUGIN.DefaultNoclipInfo = {}

	usermessage.Hook( "ASS_DefaultNoclip", function (UMSG)
	
			PLUGIN.DefaultNoclipInfo[ASS_LVL_SERVER_OWNER] = UMSG:ReadShort()
			PLUGIN.DefaultNoclipInfo[ASS_LVL_SUPER_ADMIN] = UMSG:ReadShort()
			PLUGIN.DefaultNoclipInfo[ASS_LVL_ADMIN] = UMSG:ReadShort()
			PLUGIN.DefaultNoclipInfo[ASS_LVL_TEMPADMIN] = UMSG:ReadShort()
			PLUGIN.DefaultNoclipInfo[ASS_LVL_RESPECTED] = UMSG:ReadShort()
			PLUGIN.DefaultNoclipInfo[ASS_LVL_GUEST] = UMSG:ReadShort()
			PLUGIN.DefaultNoclipInfo[ASS_LVL_BANNED] = UMSG:ReadShort()
			
		end )
		
	local IN_MY_HOOK = false
	function PLUGIN.PlayerNoClip( PLAYER )
		
		if (IN_MY_HOOK) then return end
	
		// re-call the gamemode function, allowing the call to pass through here
		// this is done to ensure that the gamemodes function take priority.
		
		IN_MY_HOOK = true
		local allow = hook.Call("PlayerNoClip", gmod.GetGamemode(), PLAYER)
		IN_MY_HOOK = false
		
		if PLAYER:GetNetworkedInt("ASS_noclip") == 1 then return true end
		
		return false
	end
	hook.Add("PlayerNoClip", "PlayerNoClip_" .. PLUGIN_FILENAME, PLUGIN.PlayerNoClip)
		
	function PLUGIN.NoclipPriv(PLAYER, ALLOW)

		if (type(PLAYER) == "table") then
			for _, ITEM in pairs(PLAYER) do
				if (IsValid(ITEM)) then
					RunConsoleCommand( "ASS_SetNoClipPriv", ITEM:AssID(), ALLOW )
				end
			end
		else
			if (!IsValid(PLAYER)) then return end
			RunConsoleCommand( "ASS_SetNoClipPriv", PLAYER:AssID(), ALLOW )
		end

	end
	
	function PLUGIN.NoClipAllowDisallow(MENU, PLAYER)
	
		local Items = {}
		local Allowed = nil
		
		if (type(PLAYER) != "table") then
			Allowed = PLAYER:GetNetworkedInt("ASS_noclip", -1)
		end

		Items[1] = MENU:AddOption( "Allow",		function() PLUGIN.NoclipPriv(PLAYER,  1) end )
		Items[0] = MENU:AddOption( "Disallow",		function() PLUGIN.NoclipPriv(PLAYER,  0) end )
		Items[-1] = MENU:AddOption( "Default",		function() PLUGIN.NoclipPriv(PLAYER,  -1) end )
		
		if (Allowed != nil && Items[Allowed]) then
			Items[Allowed]:SetImage("icon16/tick.png")
		end
	end
	
	function PLUGIN.DefNoclipPriv(LVL, ALLOW)
		RunConsoleCommand( "ASS_SetDefaultNoClipPriv", LVL, ALLOW )
	end

	function PLUGIN.DefNoClipAllowDisallow(MENU, LVL)

		local Items = {}
		Items[1] = MENU:AddOption( "Allow",	function() PLUGIN.DefNoclipPriv(LVL,  1) end )
		Items[0] = MENU:AddOption( "Disallow",	function() PLUGIN.DefNoclipPriv(LVL,  0) end )
	
		if (PLUGIN.DefaultNoclipInfo[LVL] == 1) then
			Items[1]:SetImage("icon16/tick.png")
		else
			Items[0]:SetImage("icon16/tick.png")
		end

	end

	function PLUGIN.DefaultNoclip(MENU)
		MENU:AddSubMenu("Server Owner",	nil, function(NEWMENU) PLUGIN.DefNoClipAllowDisallow(NEWMENU, ASS_LVL_SERVER_OWNER) end ):SetImage("icon16/lightning.png")
		MENU:AddSubMenu("Super Admin",	nil, function(NEWMENU) PLUGIN.DefNoClipAllowDisallow(NEWMENU, ASS_LVL_SUPER_ADMIN) end ):SetImage("icon16/star.png")
		MENU:AddSubMenu("Admin", 	nil, function(NEWMENU) PLUGIN.DefNoClipAllowDisallow(NEWMENU, ASS_LVL_ADMIN) end ):SetImage("icon16/shield.png")
		MENU:AddSubMenu("Temp Admin",	nil, function(NEWMENU) PLUGIN.DefNoClipAllowDisallow(NEWMENU, ASS_LVL_TEMPADMIN) end ):SetImage("icon16/asterisk_yellow.png")
		MENU:AddSubMenu("Respected",	nil, function(NEWMENU) PLUGIN.DefNoClipAllowDisallow(NEWMENU, ASS_LVL_RESPECTED) end ):SetImage("icon16/award_star_gold_3.png")
		MENU:AddSubMenu("Guest",	nil, function(NEWMENU) PLUGIN.DefNoClipAllowDisallow(NEWMENU, ASS_LVL_GUEST) end ):SetImage("icon16/user_gray.png")
		MENU:AddSubMenu("Unwanted",	nil, function(NEWMENU) PLUGIN.DefNoClipAllowDisallow(NEWMENU, ASS_LVL_BANNED) end ):SetImage("icon16/user_delete.png")
	end

	function PLUGIN.AddMenu(DMENU)			
	
		DMENU:AddSubMenu( "Noclip", nil, 
			function(NEWMENU) 
				NEWMENU:AddSubMenu("Default", nil, PLUGIN.DefaultNoclip ):SetImage("icon16/user.png")
				NEWMENU:AddSpacer()
				ASS_PlayerMenu( NEWMENU, {"IncludeAll","HasSubMenu","IncludeLocalPlayer"}, PLUGIN.NoClipAllowDisallow  ) 
			end
			):SetImage("icon16/status_offline.png")

	end

end

ASS_RegisterPlugin(PLUGIN)


