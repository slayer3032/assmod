
local PLUGIN = {}

PLUGIN.Name = "Weapons / Items"
PLUGIN.Author = "Andy Vincent"
PLUGIN.Date = "22nd September 2007"
PLUGIN.Filename = PLUGIN_FILENAME
PLUGIN.ClientSide = true
PLUGIN.ServerSide = true
PLUGIN.APIVersion = 2.3
PLUGIN.Gamemodes = {}

local DEFAULT_WEAPON_TABLE = {

	{	text = ".357",			item = "weapon_357"			},
	{	text = "AR2",			item = "weapon_ar2"			},
	{	text = "Bug Bait",		item = "weapon_bugbait"		},
	{	text = "Crossbow",		item = "weapon_crossbow"	},
	{	text = "Crowbar",		item = "weapon_crowbar"		},
	{	text = "Gravity Gun",	item = "weapon_physcannon"	},
	{	text = "Physics Gun",	item = "weapon_physgun"		},
	{	text = "Pistol",		item = "weapon_pistol"		},
	{	text = "RPG",			item = "weapon_rpg"			},
	{	text = "Shotgun",		item = "weapon_shotgun"		},
	{	text = "SMG",			item = "weapon_smg1"		},
	{	text = "Stunstick",		item = "weapon_stunstick"	},

}

local DEFAULT_ITEM_TABLE = {

	{	text = "Health Kit",		item = "item_healthkit",		},
	{	text = "Health Vial",		item = "item_healthvial",		},
	{	text = "Suit",				item = "item_suit",				},
	{	text = "Suit Battery",		item = "item_battery",			},
	{	},
	{	text = ".357 ammo",			item = "item_ammo_357",			},
	{	text = ".357 ammo (large)",	item = "item_ammo_357_large",	},
	{	text = "AR2 ammo",			item = "item_ammo_ar2",			},
	{	text = "AR2 ammo (large)",	item = "item_ammo_ar2_large",	},
	{	text = "Crossbow ammo",		item = "item_ammo_crossbow",	},
	{	text = "Pistol ammo",		item = "item_ammo_pistol",		},
	{	text = "Pistol ammo (large)",	item = "item_ammo_pistol_large",	},
	{	text = "RPG ammo",			item = "item_rpg_round",		},
	{	text = "SMG ammo",			item = "item_ammo_smg1",		},
	{	text = "SMG ammo (large)",	item = "item_ammo_smg1_large",	},
	{	text = "SMG grenades",		item = "item_ammo_smg1_grenade",},
	{	text = "Shotgun ammo",		item = "item_box_buckshot",		},

}

if (SERVER) then

	ASS_NewLogLevel("ASS_ACL_GIVE")

	function PLUGIN.GiveItem( PLAYER, CMD, ARGS )

		if (PLAYER:HasAssLevel(ASS_LVL_TEMPADMIN)) then

			local TO_GIVE = ASS_FindPlayer(ARGS[1])
			local ITEM = ARGS[2]
			
			if (!ITEM) then return end

			if (!TO_GIVE) then

				ASS_MessagePlayer(PLAYER, "Player not found!")
				return

			end
			
			if (ASS_GetSwepLevel) then
				local LVL = ASS_GetSwepLevel(ITEM)
				if (!PLAYER:HasAssLevel( LVL )) then
					ASS_MessagePlayer( PLAYER, "Sorry, only " .. ASS_LevelToString(LVL) .. " are allowed to give this item!\n")
					return
				end
			end
			
			TO_GIVE:Give(ITEM)

			ASS_LogAction( PLAYER, ASS_ACL_GIVE, "gave " .. ASS_FullNick(TO_GIVE) .. " " .. ITEM  )

		else

			ASS_MessagePlayer( PLAYER, "Access denied!")

		end
		
	end
	concommand.Add("ASS_GiveItem", PLUGIN.GiveItem)

	function PLUGIN.SpawnItem( PLAYER, CMD, ARGS )

		if (PLAYER:HasAssLevel(ASS_LVL_TEMPADMIN)) then

			local ITEM = ARGS[1]
			
			if (!ITEM) then return end
			
			if (ASS_GetSwepLevel) then
				local LVL = ASS_GetSwepLevel(ITEM)
				if (!PLAYER:HasAssLevel( LVL )) then
					ASS_MessagePlayer( PLAYER, "Sorry, only " .. ASS_LevelToString(LVL) .. " are allowed to spawn this item!\n")
					return
				end
			end

			local tr_res = PLAYER:GetEyeTraceNoCursor()
			
			local ENT = ents.Create( ITEM )
			
			if (ENT && ENT:IsValid()) then
			
				ENT:SetPos( tr_res.HitPos + (tr_res.HitNormal * 16) )
				ENT:Spawn()
			
			end
			
			ASS_LogAction( PLAYER, ASS_ACL_GIVE, "spawned " .. ITEM  )

		else

			ASS_MessagePlayer( PLAYER, "Access denied!")

		end
		
	end
	concommand.Add("ASS_SpawnItem", PLUGIN.SpawnItem)

	function PLUGIN.StripWeapons( PLAYER, CMD, ARGS )
 		if (PLAYER:HasAssLevel(ASS_LVL_TEMPADMIN)) then

 			local TO_STRIP = ASS_FindPlayer(ARGS[1])
           
			if (!TO_STRIP) then

				ASS_MessagePlayer(PLAYER, "Player not found!")
				return

			end

			TO_STRIP:StripWeapons()
			TO_STRIP:StripAmmo()

			ASS_LogAction( PLAYER, ASS_ACL_GIVE, "stripped " .. ASS_FullNick(TO_STRIP) .. " of all weapons and ammo")
		else

			ASS_MessagePlayer( PLAYER, "Access denied!")

		end
	end
	concommand.Add("ASS_StripWeapons", PLUGIN.StripWeapons)

	function PLUGIN.StripAllWeapons( PLAYER, CMD, ARGS )
		// Simple check: Is the player a temporary admin or above?
		if (PLAYER:HasAssLevel(ASS_LVL_TEMPADMIN)) then
		
			local INCLUDE_ADMINS = (ARGS[1] == 1)
			
			for _,TO_STRIP in pairs(player.GetAll()) do
			
				if (INCLUDE_ADMINS || (!INCLUDE_ADMINS && !TO_STRIP:HasAssLevel(ASS_LVL_TEMPADMIN))) then

					TO_STRIP:StripWeapons()
					TO_STRIP:StripAmmo()

				end
			
			end
		
			// Log the action. Note we're using the new log level we defined earlier.
			if (INCLUDE_ADMINS) then
				ASS_LogAction( PLAYER, ASS_ACL_GIVE, "stripped everyone of all weapons and ammo (including admins)" )
			else
				ASS_LogAction( PLAYER, ASS_ACL_GIVE, "stripped everyone of all weapons and ammo (excluding admins)" )
			end
		
		else

			// Player doesn't have enough access.
			ASS_MessagePlayer( PLAYER, "Access denied!")

		end
	end
	concommand.Add("ASS_StripAllWeapons", PLUGIN.StripAllWeapons)

end

if (CLIENT) then

	function PLUGIN.SpawnItem(PLAYER, ITEM)
	
		RunConsoleCommand("ASS_SpawnItem", ITEM)
		
		return true
	
	end

	function PLUGIN.GiveItem(PLAYER, ITEM)
	
		if (type(PLAYER) == "table") then
			for _, PL in pairs(PLAYER) do
				if (IsValid(PL)) then
					RunConsoleCommand("ASS_GiveItem", PL:AssID(), ITEM)
				end
			end
		else
			if (!IsValid(PLAYER)) then return end
			
			RunConsoleCommand("ASS_GiveItem", PLAYER:AssID(), ITEM)
		end
		
		return true
	
	end

	function PLUGIN.WeaponMenu(MENU, PLAYER, FUNC)

		for k,v in pairs(DEFAULT_WEAPON_TABLE) do
			MENU:AddOption( v.text,	function() FUNC(PLAYER, v.item) end )
		end
		MENU:AddSpacer()

		local CustomSWEPs = {}
		for k,v in pairs(weapons.GetList()) do
			if (v.Spawnable || v.AdminSpawnable) then
				table.insert(CustomSWEPs, v)
			end
		end
		
		table.sort(CustomSWEPs, function(a, b)
			return tostring(a.PrintName) < tostring(b.PrintName)
		end);
		
		for k, v in pairs(CustomSWEPs) do
			MENU:AddOption( v.PrintName, function() return FUNC(PLAYER, v.ClassName) end )
		end

		return false

	end
	
	function PLUGIN.ItemMenu(MENU, PLAYER, FUNC)

		for k,v in pairs(DEFAULT_ITEM_TABLE) do
			if (v.text == nil) then
				MENU:AddSpacer()
			else
				MENU:AddOption( v.text,	function() FUNC(PLAYER, v.item) end )
			end
		end

	end

	function PLUGIN.WeaponItemMenu(MENU, PLAYER, FUNC)

		MENU:AddSubMenu( "Weapon", nil, function(NEWMENU) PLUGIN.WeaponMenu( NEWMENU, PLAYER, FUNC ) end ):SetImage( "icon16/wrench.png" )
		MENU:AddSubMenu( "Item", nil, function(NEWMENU) PLUGIN.ItemMenu( NEWMENU, PLAYER, FUNC ) end ):SetImage( "icon16/wrench_orange.png" )
		
	end
	
	function PLUGIN.StripWeapons(PLAYER, FUNC)
		if (!PLAYER:IsValid()) then return end
		RunConsoleCommand("ASS_StripWeapons", PLAYER:AssID() )
 	end

	function PLUGIN.TopMenu(MENU)			
	
		MENU:AddSubMenu( "Give",  nil, function(NEWMENU) ASS_PlayerMenu( NEWMENU, {"IncludeAll", "HasSubMenu", "IncludeLocalPlayer" }, PLUGIN.WeaponItemMenu, PLUGIN.GiveItem  ) end ):SetImage( "icon16/lorry_add.png" )
		MENU:AddSubMenu( "Spawn", nil, function(NEWMENU) PLUGIN.WeaponItemMenu( NEWMENU, LocalPlayer(), PLUGIN.SpawnItem  ) end ):SetImage( "icon16/lorry_go.png" )
		MENU:AddSubMenu( "Strip", nil, function(NEWMENU) ASS_PlayerMenu( NEWMENU, {"IncludeAll", "IncludeLocalPlayer"}, PLUGIN.StripWeapons ) end ):SetImage( "icon16/lorry_delete.png" )

	end

	function PLUGIN.AddMainMenu(DMENU)			

		DMENU:AddSpacer()
		DMENU:AddSubMenu( "Weapon / Items" , nil, PLUGIN.TopMenu ):SetImage( "icon16/lorry.png" )
        
    end

end

ASS_RegisterPlugin(PLUGIN)


