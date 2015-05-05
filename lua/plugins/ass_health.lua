
local PLUGIN = {}

PLUGIN.Name = "Health"
PLUGIN.Author = "Andy Vincent"
PLUGIN.Date = "10th August 2007"
PLUGIN.Filename = PLUGIN_FILENAME
PLUGIN.ClientSide = true
PLUGIN.ServerSide = true
PLUGIN.APIVersion = 2.3
PLUGIN.Gamemodes = {}

if (SERVER) then

	ASS_NewLogLevel("ASS_ACL_HEALTH")

	function PLUGIN.GiveTakeHealth( PLAYER, CMD, ARGS )

		if (PLAYER:HasAssLevel(ASS_LVL_TEMPADMIN)) then

			local TO_RECIEVE = ASS_FindPlayer(ARGS[1])
			local HEALTH = tonumber(ARGS[2]) or 0

			if (!TO_RECIEVE) then

				ASS_MessagePlayer(PLAYER, "Player not found!")
				return

			end
			
			if (HEALTH == 0) then return end // nothing to do!

			if (PLAYER != TO_RECIEVE) then
				if (TO_RECIEVE:IsBetterOrSame(PLAYER) && HEALTH < 0) then

					// disallow!
					ASS_MessagePlayer(PLAYER, "Access denied! \"" .. TO_RECIEVE:Nick() .. "\" has same or better access then you.")
					return
				end
			end

			if (ASS_RunPluginFunction( "AllowPlayerHealth", true, PLAYER, TO_RECIEVE, HEALTH )) then

				if (HEALTH < 0) then

					TO_RECIEVE:Hurt( -HEALTH )
					ASS_LogAction( PLAYER, ASS_ACL_HEALTH, "took " .. -HEALTH .. " health from " .. ASS_FullNick(TO_RECIEVE) )

				else

					TO_RECIEVE:SetHealth( TO_RECIEVE:Health() + HEALTH )
					ASS_LogAction( PLAYER, ASS_ACL_HEALTH, "gave " .. ASS_FullNick(TO_RECIEVE) .. " " .. HEALTH .. " health"  )

				end

			end


		else

			ASS_MessagePlayer( PLAYER, "Access denied!")

		end

	end
	concommand.Add("ASS_GiveTakeHealth", PLUGIN.GiveTakeHealth)
	
	function PLUGIN.GiveTakeArmor( PLAYER, CMD, ARGS )

		if (PLAYER:HasAssLevel(ASS_LVL_TEMPADMIN)) then

			local TO_RECIEVE = ASS_FindPlayer(ARGS[1])
			local ARMOR = tonumber(ARGS[2]) or 0

			if (!TO_RECIEVE) then

				ASS_MessagePlayer(PLAYER, "Player not found!")
				return

			end
			
			if (ARMOR == 0) then return end // nothing to do!

			if (PLAYER != TO_RECIEVE) then
				if (TO_RECIEVE:IsBetterOrSame(PLAYER) && ARMOR < 0) then

					// disallow!
					ASS_MessagePlayer(PLAYER, "Access denied! \"" .. TO_RECIEVE:Nick() .. "\" has same or better access then you.")
					return
				end
			end

			if (ASS_RunPluginFunction( "AllowPlayerHealth", true, PLAYER, TO_RECIEVE, ARMOR )) then

				if (ARMOR < 0) then

					TO_RECIEVE:Hurt( -ARMOR )
					ASS_LogAction( PLAYER, ASS_ACL_HEALTH, "took " .. -ARMOR .. " armor from " .. ASS_FullNick(TO_RECIEVE) )

				else

					TO_RECIEVE:SetHealth( TO_RECIEVE:Health() + ARMOR )
					ASS_LogAction( PLAYER, ASS_ACL_HEALTH, "gave " .. ASS_FullNick(TO_RECIEVE) .. " " .. ARMOR .. " armor"  )

				end

			end


		else

			ASS_MessagePlayer( PLAYER, "Access denied!")

		end

	end
	concommand.Add("ASS_GiveTakeArmor", PLUGIN.GiveTakeArmor)

end

if (CLIENT) then

	function PLUGIN.GiveTakeHealth(PLAYER, AMOUNT)

		if (type(PLAYER) == "table") then
			for _, ITEM in pairs(PLAYER) do
				if (IsValid(ITEM)) then
					RunConsoleCommand( "ASS_GiveTakeHealth", ITEM:AssID(), AMOUNT )
				end
			end
		else
			if (!IsValid(PLAYER)) then return end
			RunConsoleCommand( "ASS_GiveTakeHealth", PLAYER:AssID(), AMOUNT )
		end
		
		return true
	end
	
	function PLUGIN.GiveTakeArmor(PLAYER, AMOUNT)

		if (type(PLAYER) == "table") then
			for _, ITEM in pairs(PLAYER) do
				if (IsValid(ITEM)) then
					RunConsoleCommand( "ASS_GiveTakeArmor", ITEM:AssID(), AMOUNT )
				end
			end
		else
			if (!IsValid(PLAYER)) then return end
			RunConsoleCommand( "ASS_GiveTakeArmor", PLAYER:AssID(), AMOUNT )
		end
		
		return true
	end
	
	function PLUGIN.PosAmountPower(MENU, PLAYER)

		for i=10,100,10 do
			MENU:AddOption( tostring(i),	function() return PLUGIN.GiveTakeHealth(PLAYER,  i) end )
		end

	end
	
	function PLUGIN.NegAmountPower(MENU, PLAYER)

		for i=10,100,10 do
			MENU:AddOption( tostring(i),	function() return PLUGIN.GiveTakeHealth(PLAYER,  -i) end )
		end

	end
	
	function PLUGIN.PosAmountPowerA(MENU, PLAYER)

		for i=10,100,10 do
			MENU:AddOption( tostring(i),	function() return PLUGIN.GiveTakeArmor(PLAYER,  i) end )
		end

	end
	
	function PLUGIN.NegAmountPowerA(MENU, PLAYER)

		for i=10,100,10 do
			MENU:AddOption( tostring(i),	function() return PLUGIN.GiveTakeArmor(PLAYER,  -i) end )
		end

	end
	
	function PLUGIN.AddMenu(DMENU)			
	
	
		DMENU:AddSubMenu( "HP/Armor", nil, 
			function(NEWMENU)
				NEWMENU:AddSubMenu( "Give Health", nil, function(NEWMENU2) ASS_PlayerMenu( NEWMENU2, {"IncludeAll", "IncludeLocalPlayer", "HasSubMenu"}, PLUGIN.PosAmountPower  ) end ):SetImage( "icon16/heart_add.png" )
				NEWMENU:AddSubMenu( "Take Health", nil, function(NEWMENU2) ASS_PlayerMenu( NEWMENU2, {"IncludeAll", "IncludeLocalPlayer", "HasSubMenu"}, PLUGIN.NegAmountPower  ) end ):SetImage( "icon16/heart_delete.png" )
				NEWMENU:AddSubMenu( "Give Armor", nil, function(NEWMENU2) ASS_PlayerMenu( NEWMENU2, {"IncludeAll", "IncludeLocalPlayer", "HasSubMenu"}, PLUGIN.PosAmountPowerA  ) end ):SetImage( "icon16/shield_add.png" )
				NEWMENU:AddSubMenu( "Take Armor", nil, function(NEWMENU2) ASS_PlayerMenu( NEWMENU2, {"IncludeAll", "IncludeLocalPlayer", "HasSubMenu"}, PLUGIN.NegAmountPowerA  ) end ):SetImage( "icon16/shield_delete.png" )
			end
		):SetImage( "icon16/heart.png" )

	end

end

ASS_RegisterPlugin(PLUGIN)


