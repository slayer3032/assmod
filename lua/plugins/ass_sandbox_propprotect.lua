
local PLUGIN = {}

PLUGIN.Name = "Sandbox Prop Protection"
PLUGIN.Author = "Andy Vincent"
PLUGIN.Date = "20th September 2007"
PLUGIN.Filename = PLUGIN_FILENAME
PLUGIN.ClientSide = true
PLUGIN.ServerSide = true
PLUGIN.APIVersion = 2.3
PLUGIN.Gamemodes = { "sandbox" } // only load this plugin for sandbox and it's derivatives

local PP_OFF		=	"off"
local PP_RELAXED	=	"relaxed"
local PP_STRICT		=	"strict"
local PP_EXTREME	=	"extreme"

local ADMIN_ALLOW	=	"1"
local ADMIN_DISALLOW	=	"0"

// Now includes buddy list.
// Buddy list is stored on the client, and sent to the server when the player connects!

// Off
//   -> No protection

// Relaxed
//   -> PLAYER == OWNER or
//	PLAYER is buddy of OWNER or
//	PLAYER:IsRespected() or
//	THING == ":gravgun" or
//	THING == ":use" or
//	THING == ":ride" or
//	THING == ":physgun" or
//	THING == "duplicator" or
//	THING == "camera" or
//	THING == "rtcamera"

// Strict
//   -> PLAYER == OWNER or
//	PLAYER is buddy of OWNER or
//	PLAYER:HasAssLevel(ASS_LVL_TEMPADMIN) or
//	THING == ":ride" or
//	THING == ":duplicator" or
//	THING == "camera" or
//	THING == "rtcamera"

// Extreme
//   -> PLAYER == OWNER or
//	PLAYER is buddy of OWNER or
//	PLAYER:IsSuperAdmin()

if (SERVER) then

	local AllowedThings = {}
	AllowedThings[PP_RELAXED] = { ":uclip", ":ride", ":use", ":gravgun", ":physgun", "duplicator", "camera", "rtcamera", "ass_owner" }
	AllowedThings[PP_STRICT] = { ":ride", ":use", "duplicator", "camera", "rtcamera", "ass_owner" }
	AllowedThings[PP_EXTREME] = { "ass_owner" }
	
	local WeirdTraces = {
	"wire_winch",
	"wire_hydraulic",
	"slider",
	"hydraulic",
	"winch",
	"muscle"
}

	PlayerEntPending = {}
	
	ASS_NewLogLevel("ASS_ACL_SANDBOX")
	
	function PLUGIN.ValidMode( MODE )
		if (	MODE != PP_OFF && 
			MODE != PP_RELAXED &&
			MODE != PP_STRICT &&
			MODE != PP_EXTREME ) then return false end
			
		return true
	end
	
	function PLUGIN.GetAllowAdmins()
		local mode = ASS_Config["prop_protection_allow_admins"]
		
		if (!mode || (mode != ADMIN_DISALLOW && mode != ADMIN_ALLOW)) then
			ASS_Config["prop_protection_allow_admins"] = ADMIN_ALLOW
			ASS_WriteConfig()
			
			mode = ASS_Config["prop_protection_allow_admins"]
		end
		
		return mode
	end

	function PLUGIN.GetPropProtectionMode()
	
		local mode = ASS_Config["prop_protection"]
		
		if (!PLUGIN.ValidMode(mode)) then
			ASS_Config["prop_protection"] = PP_OFF
			ASS_WriteConfig()
			
			mode = ASS_Config["prop_protection"]
		end
		
		return mode
	
	end
	
	function PLUGIN.FormatText(TEXT)
	
		TEXT = string.Replace(TEXT, "%propprotect%", PLUGIN.GetPropProtectionMode() )
	
	end
	
	function PLUGIN.CheckConstraints(PLAYER, ENTITY)
		for k, v in pairs(constraint.GetAllConstrainedEntities(ENTITY) or {}) do
			if(v and v:IsValid()) then
				if(!PLUGIN.PlayerAllowedMsg( PLAYER, PLUGIN.GetOwner(v), "remover" )) then
					return false
				end
			end
		end
		return true
	end
	
	function PLUGIN.PlayerAllowed( PLAYER, OWNER, THING )
	
		if (!OWNER:IsValid()) then
			ASS_Debug( PLAYER:Nick() .. " -> allowed " .. THING .. " - no owner\n")
			return true
		end
		
		local mode = PLUGIN.GetPropProtectionMode()
		local aa = PLUGIN.GetAllowAdmins()
		
		if (mode == PP_OFF) then		
			ASS_Debug( PLAYER:Nick() .. " -> allowed " .. THING .. " - pp off\n")
			return true
		end
		
		if (PLAYER == OWNER) then
			ASS_Debug( PLAYER:Nick() .. " -> allowed " .. THING .. " - is owner\n")
			return true
		end
		
		if (OWNER.PropProtectionBuddies && OWNER.PropProtectionBuddies[PLAYER:AssID()]) then
			ASS_Debug( PLAYER:Nick() .. " -> allowed " .. THING .. " - is buddy of owner\n")
			return true	 
		end
		
		if (PLAYER:HasAssLevel(ASS_LVL_SERVER_OWNER)) then
			ASS_Debug( PLAYER:Nick() .. " -> allowed " .. THING .. " - is server owner\n")
			return true
		end
		
		if (PLAYER:GetAssLevel() > ASS_LVL_GUEST && mode == PP_RELAXED) then
			ASS_Debug( PLAYER:Nick() .. " -> allowed " .. THING .. " - is respected\n")
			return true
		end

		if (PLAYER:HasAssLevel(ASS_LVL_TEMPADMIN) && mode != PP_EXTREME && aa == ADMIN_ALLOW) then
			ASS_Debug( PLAYER:Nick() .. " -> allowed " .. THING .. " - is tempadmin\n")
			return true
		end
		
		if (PLAYER:IsSuperAdmin() && aa == ADMIN_ALLOW) then
			ASS_Debug( PLAYER:Nick() .. " -> allowed " .. THING .. " - is superadmin\n")
			return true
		end
		
		for k,v in pairs(AllowedThings[mode] or {}) do
			
			if (v == THING) then
				ASS_Debug( PLAYER:Nick() .. " -> allowed " .. THING .. " - is in allowed list\n")
				return true
			end
		
		end
		
		return false
		
	end

	function PLUGIN.PlayerAllowedMsg( PLAYER, OWNER, THING )
	
		if (!PLUGIN.PlayerAllowed(PLAYER, OWNER, THING)) then
			
			if CurTime()-PLAYER.LastPPMessaged > 2  then
				ASS_MessagePlayer(PLAYER, (OWNER:Nick() or OWNER:GetClass()).."\'s items are protected!")
			end
			
			PLAYER.LastPPMessaged = CurTime()
			
			return false
			
		end
		
		return true
	
	end

	function PLUGIN.SetOwner( PLAYER, ENTITY )
		if (!ENTITY:IsValid()) then return end
		
		ENTITY:SetNetworkedEntity("ASS_Owner", PLAYER)
		ENTITY:SetVar( "ASS_Owner", PLAYER )
		ENTITY:SetVar("ASS_OwnerOverride", true)
	end
	
	function PLUGIN.GetOwner( ENTITY )
	
		if (!IsValid(ENTITY)) then return NullEntity() end
		
		local b = ENTITY:GetVar("ASS_OwnerOverride", false)
		local e = ENTITY:GetVar( "ASS_Owner", NullEntity() ) 
		
		if (IsValid(e) && e:IsPlayer()) then
			ASS_Debug("GetOwner (1) - " .. tostring(e) .. "\n")
			return e
		end
		
		if (b) then
			return NullEntity()
		end
		
		if (ENTITY.Player && type(ENTITY.Player) == "Player" && IsValid(ENTITY.Player)) then
			ASS_Debug("GetOwner (2) - " .. tostring(ENTITY.Player) .. "\n")
			return ENTITY.Player
		end
		
		if (ENTITY.GetPlayer && type(ENTITY.GetPlayer) == "function") then
			local P = ENTITY:GetPlayer()
			if (type(P) == "Player" && IsValid(P)) then 
				ASS_Debug("GetOwner (3) - " .. tostring(P) .. "\n")
				return P 
			end
			
			return NullEntity()
		end
		
		return NullEntity()
	end
	
	function PLUGIN.InitPostEntity()
		SetGlobalString( "ASS_PropProtectMode", PLUGIN.GetPropProtectionMode() )
		SetGlobalString( "ASS_PropProtectAllowAdmins", PLUGIN.GetAllowAdmins() )
	end
	
	function PLUGIN.PlayerSpawnedRagdoll(PLAYER, MODEL, ENT)	PLUGIN.SetOwner(PLAYER, ENT)	end
	function PLUGIN.PlayerSpawnedProp(PLAYER, MODEL, ENT)		PLUGIN.SetOwner(PLAYER, ENT)	end
	function PLUGIN.PlayerSpawnedEffect(PLAYER, MODEL, ENT)		PLUGIN.SetOwner(PLAYER, ENT)	end
	function PLUGIN.PlayerSpawnedVehicle(PLAYER, ENT)		PLUGIN.SetOwner(PLAYER, ENT)	end
	function PLUGIN.PlayerSpawnedSENT(PLAYER, ENT)			PLUGIN.SetOwner(PLAYER, ENT)	end
	function PLUGIN.PlayerSpawnedNPC(PLAYER, ENT)			PLUGIN.SetOwner(PLAYER, ENT)	end
		
	--blatant rip from spp..
	function PLUGIN.CanTool( PLAYER, TRACE, MODE )
	
		if ( TRACE.Hit && TRACE.HitNonWorld && TRACE.Entity:IsValid() ) then
		
			local OWNER = PLUGIN.GetOwner( TRACE.Entity )
			
			if (!PLUGIN.PlayerAllowedMsg( PLAYER, OWNER, MODE )) then
				return false
			end
			
			if(MODE == "nail") then
				local Trace = {}
				Trace.start = TRACE.HitPos
				Trace.endpos = TRACE.HitPos + (PLAYER:GetAimVector() * 16.0)
				Trace.filter = {PLAYER, TRACE.Entity}
			
				local tr2 = util.TraceLine(Trace)
				if(tr2.Hit and IsValid(tr2.Entity) and !tr2.Entity:IsPlayer()) then
					if(!PLUGIN.PlayerAllowedMsg( PLAYER, PLUGIN.GetOwner(tr2.Entity), MODE )) then
						return false
					end
				end
			elseif(table.HasValue(WeirdTraces, MODE)) then
				local Trace = {}
				Trace.start = TRACE.HitPos
				Trace.endpos = Trace.start + (TRACE.HitNormal * 16384)
				Trace.filter = {PLAYER}
				local tr2 = util.TraceLine(Trace)
				if(tr2.Hit and IsValid(tr2.Entity) and !tr2.Entity:IsPlayer()) then
					if(!PLUGIN.PlayerAllowedMsg( PLAYER, PLUGIN.GetOwner(tr2.Entity), MODE )) then
						return false
					end
				end
			elseif(MODE == "remover") then
				if(!PLUGIN.CheckConstraints(PLAYER, TRACE.Entity)) then
					return false
				end
			end
		end
	end
	
	function PLUGIN.GravGunPunt( PLAYER, ENTITY )			if (!PLUGIN.PlayerAllowedMsg(PLAYER, PLUGIN.GetOwner(ENTITY), ":gravgun")) then return false end	end
	function PLUGIN.GravGunPickupAllowed( PLAYER, ENTITY )		if (!PLUGIN.PlayerAllowedMsg(PLAYER, PLUGIN.GetOwner(ENTITY), ":gravgun")) then return false end	end	
	function PLUGIN.PhysgunPickup( PLAYER, ENTITY )			if (!PLUGIN.PlayerAllowedMsg(PLAYER, PLUGIN.GetOwner(ENTITY), ":physgun")) then return false end	end
	function PLUGIN.CanPlayerUnfreeze( PLAYER, ENTITY, PHYS )	if (!PLUGIN.PlayerAllowedMsg(PLAYER, PLUGIN.GetOwner(ENTITY), ":physgun")) then return false end	end	
	function PLUGIN.CanPlayerEnterVehicle( PLAYER, VEHICLE, ROLE )	if (!PLUGIN.PlayerAllowedMsg(PLAYER, PLUGIN.GetOwner(VEHICLE), ":ride")) then return VEHICLE:Fire( "turnoff", "", 0 ) end	end	
	function PLUGIN.PlayerUse( PLAYER, ENTITY )
		if (ENTITY:IsVehicle()) then			
			return
		else
			if (!PLUGIN.PlayerAllowedMsg(PLAYER, PLUGIN.GetOwner(ENTITY), ":use")) then return false end
		end	
	end	
	
	function PLUGIN.DisconnectCleanup(uid)
		local cleanupents = cleanup.GetList()[uid]
		
		if PlayerEntPending[uid] and cleanupents then
			PlayerEntPending[uid] = nil
			
			for k,v in pairs(cleanupents) do
				for k2,v2 in pairs(v) do
					if IsValid(v2) then
						v2:Remove()
					end
				end
			end
		end
	end
	
	function PLUGIN.PlayerInitialSpawn(pl)
		pl.LastPPMessaged = 0
		
		if PlayerEntPending[pl:AssID()] then
			local cleanupents = cleanup.GetList()[pl:AssID()]
			PlayerEntPending[pl:AssID()] = nil
			
			if cleanupents then
				for k,v in pairs(cleanupents) do
					for k2,v2 in pairs(v) do
						if IsValid(v2) then
							PLUGIN.SetOwner(pl, v2)
						end
					end
				end
			end
		end
	end
	
	function PLUGIN.PlayerDisconnected(pl)
		local uid = pl:AssID()
		PlayerEntPending[uid] = true
		
		timer.Simple(75, function() PLUGIN.DisconnectCleanup(uid) end)
	end
		
	
	function PLUGIN.Registered()
		hook.Add("InitPostEntity",		"InitPostEntity_" .. PLUGIN.Filename, 		PLUGIN.InitPostEntity )
		hook.Add("PlayerSpawnedRagdoll", 	"PlayerSpawnedRagdoll_" .. PLUGIN.Filename, 	PLUGIN.PlayerSpawnedRagdoll )
		hook.Add("PlayerSpawnedProp", 		"PlayerSpawnedProp_" .. PLUGIN.Filename, 	PLUGIN.PlayerSpawnedProp )
		hook.Add("PlayerSpawnedEffect", 	"PlayerSpawnedEffect_" .. PLUGIN.Filename, 	PLUGIN.PlayerSpawnedEffect )
		hook.Add("PlayerSpawnedVehicle", 	"PlayerSpawnedVehicle_" .. PLUGIN.Filename, 	PLUGIN.PlayerSpawnedVehicle )
		hook.Add("PlayerSpawnedSENT", 		"PlayerSpawnedSENT_" .. PLUGIN.Filename, 	PLUGIN.PlayerSpawnedSENT )
		hook.Add("PlayerSpawnedNPC", 		"PlayerSpawnedNPC_" .. PLUGIN.Filename, 	PLUGIN.PlayerSpawnedNPC )
		hook.Add("CanTool", 			"CanTool_" .. PLUGIN.Filename, 			PLUGIN.CanTool )
		hook.Add("GravGunPunt", 		"GravGunPunt_" .. PLUGIN.Filename, 		PLUGIN.GravGunPunt )
		hook.Add("GravGunPickupAllowed", 	"GravGunPickupAllowed_" .. PLUGIN.Filename, 	PLUGIN.GravGunPickupAllowed )
		hook.Add("PhysgunPickup", 		"PhysgunPickup_" .. PLUGIN.Filename, 		PLUGIN.PhysgunPickup )
		hook.Add("CanPlayerUnfreeze", 		"CanPlayerUnfreeze_" .. PLUGIN.Filename, 	PLUGIN.CanPlayerUnfreeze )
		hook.Add("CanPlayerEnterVehicle", 	"CanPlayerEnterVehicle_" .. PLUGIN.Filename, 	PLUGIN.CanPlayerEnterVehicle )
		hook.Add("PlayerUse", 			"PlayerUse_" .. PLUGIN.Filename, 		PLUGIN.PlayerUse )
		hook.Add("PlayerInitialSpawn",	"PlayerInitialSpawn_" .. PLUGIN.Filename, PLUGIN.PlayerInitialSpawn )
		hook.Add("PlayerDisconnected", "PlayerDisconnected_" .. PLUGIN.Filename, PLUGIN.PlayerDisconnected )

		ASS_PP_SetOwner = PLUGIN.SetOwner
		ASS_PP_GetOwner = PLUGIN.GetOwner
		ASS_PP_IsAllowed = PLUGIN.PlayerAllowed
	end
	
	function PLUGIN.PropProtectMode(PLAYER, CMD, ARGS)
	
		if (PLAYER:HasAssLevel(ASS_LVL_TEMPADMIN)) then
		
			if (!ARGS[1]) then return end
			if (!PLUGIN.ValidMode(ARGS[1])) then return end
				
			ASS_LogAction( PLAYER, ASS_ACL_SANDBOX, "set prop protection to " .. ARGS[1])

			ASS_Config["prop_protection"] = ARGS[1]
			ASS_WriteConfig()
			SetGlobalString( "ASS_PropProtectMode", PLUGIN.GetPropProtectionMode() )

		else
			ASS_MessagePlayer( PLAYER, "Access denied!")
		end
	
	end
	concommand.Add("ASS_PropProtect", PLUGIN.PropProtectMode)

	function PLUGIN.PropProtectAllowAdmins(PLAYER, CMD, ARGS)
	
		if (PLAYER:HasAssLevel(ASS_LVL_SERVER_OWNER)) then
			
			if (ARGS[1] == ADMIN_ALLOW) then
				ASS_LogAction( PLAYER, ASS_ACL_SANDBOX, "set prop protection to allow admins")
				ASS_Config["prop_protection_allow_admins"] = ADMIN_ALLOW
			else
				ASS_LogAction( PLAYER, ASS_ACL_SANDBOX, "set prop protection to disallow admins")
				ASS_Config["prop_protection_allow_admins"] = ADMIN_DISALLOW
			end
			
			ASS_WriteConfig()
			SetGlobalString( "ASS_PropProtectAllowAdmins", PLUGIN.GetAllowAdmins() )

		else
			ASS_MessagePlayer( PLAYER, "Access denied!")
		end
	
	end
	concommand.Add("ASS_PropProtectAllowAdmins", PLUGIN.PropProtectAllowAdmins)

	function PLUGIN.AddBuddy(PLAYER, CMD, ARGS)
		local uid = table.concat(ARGS, "")
		PLAYER.PropProtectionBuddies = PLAYER.PropProtectionBuddies or {}
		PLAYER.PropProtectionBuddies[ uid ] = true
	end
	concommand.Add("ASS_PropProtectAddBuddy", PLUGIN.AddBuddy)
	
	function PLUGIN.RemoveBuddy(PLAYER, CMD, ARGS)
		local uid = table.concat(ARGS, "")
		PLAYER.PropProtectionBuddies = PLAYER.PropProtectionBuddies or {}
		PLAYER.PropProtectionBuddies[ uid ] = nil
	end
	concommand.Add("ASS_PropProtectRemoveBuddy", PLUGIN.RemoveBuddy)
	
end

if (CLIENT) then

	function PLUGIN.Registered()
	
		if (ASS_Config["pp_buddy"]) then
			for k,v in pairs(ASS_Config["pp_buddy"]) do
				RunConsoleCommand("ASS_PropProtectAddBuddy", v.id)
			end
		end
	
	end
	
	
	function PLUGIN.PropProtectMode(MODE)
	
		RunConsoleCommand("ASS_PropProtect", MODE)
	
		return true
	
	end

	function PLUGIN.AllowAdmins(MODE)
		RunConsoleCommand("ASS_PropProtectAllowAdmins", MODE)
		return true
	end

	function PLUGIN.BuddyAdd(BUDDY)
	
		if (!IsValid(BUDDY)) then return end

		ASS_Config["pp_buddy"] = ASS_Config["pp_buddy"] or {}
		for k,v in pairs(ASS_Config["pp_buddy"]) do
			if (v.id == BUDDY:AssID()) then return true end
		end
		table.insert(ASS_Config["pp_buddy"], { id = BUDDY:AssID(), name = BUDDY:Nick() } )
		
		ASS_WriteConfig()
		RunConsoleCommand("ASS_PropProtectAddBuddy", BUDDY:AssID())

	end
	
	function PLUGIN.CCBuddyAdd(ID)
		for k,v in pairs(player.GetAll()) do
			if (ID == v:AssID()) then
				PLUGIN.BuddyAdd(nil, v)
				break
			end
		end
		local CP = GetControlPanel("ASSmodBuddyList")
		if (CP) then
			CP:ClearControls()
			PLUGIN.ShowBuddyList( CP )
		end
	end
	concommand.Add("ASS_PropProtectAddBuddy_CL", function(PL,CMD,ARGS) PLUGIN.CCBuddyAdd( table.concat(ARGS, "") ) end )
	
	function PLUGIN.CCBuddyRemove(ID)
		RunConsoleCommand("ASS_PropProtectRemoveBuddy", ID)

		for k,v in pairs(ASS_Config["pp_buddy"]) do
			if (v.id == ID) then
				table.remove(ASS_Config["pp_buddy"], k)
				break
			end
		end
		ASS_WriteConfig()
		
		local CP = GetControlPanel("ASSmodBuddyList")
		if (CP) then
			CP:ClearControls()
			PLUGIN.ShowBuddyList( CP )
		end
	end
	concommand.Add("ASS_PropProtectRemoveBuddy_CL", function(PL,CMD,ARGS) PLUGIN.CCBuddyRemove( table.concat(ARGS, "") ) end )
	
	
	function PLUGIN.BuddyRemove(MENUITEM)
	
		ASS_Config["pp_buddy"] = ASS_Config["pp_buddy"] or {}
		local Choices = {}
		for k,v in pairs(ASS_Config["pp_buddy"]) do
			table.insert(Choices, { Text = v.name .. " (" .. v.id .. ")", ID = v.id } )
		end
	
		PromptForChoice( "Remove buddy...", Choices, 
			function (DLG, ITEM)
			
				PLUGIN.CCBuddyRemove(ITEM.ID)
				DLG:Close()

			end
		)	
		
		return true
	
	end
	
	function PLUGIN.PropProtectionNonAdmin(MENU)
	
		MENU:AddSubMenu("Add Buddy", nil, function(NEWMENU) ASS_PlayerMenu( NEWMENU, {}, PLUGIN.BuddyAdd ) end ):SetImage("icon16/shield_add.png")
		MENU:AddOption("Remove Buddy...",	PLUGIN.BuddyRemove ):SetImage("icon16/shield_delete.png")
		
		return false
		
	end

	function PLUGIN.AddNonAdminMenu(MENU)
		
		MENU:AddSubMenu( "Prop Protection", nil, PLUGIN.PropProtectionNonAdmin ):SetImage("icon16/shield.png")
	
	end
	
	function PLUGIN.PropProtection(MENU)

		local Items = {}
		
		Items[PP_OFF] = MENU:AddOption("Off",		function() PLUGIN.PropProtectMode(PP_OFF) end )
		Items[PP_RELAXED] = MENU:AddOption("Relaxed",	function() PLUGIN.PropProtectMode(PP_RELAXED) end )
		Items[PP_STRICT] = MENU:AddOption("Strict",	function() PLUGIN.PropProtectMode(PP_STRICT) end )
		Items[PP_EXTREME] = MENU:AddOption("Extreme",	function() PLUGIN.PropProtectMode(PP_EXTREME) end )
		
		local Mode = GetGlobalString("ASS_PropProtectMode")
		if (Items[Mode]) then
			Items[Mode]:SetImage("icon16/tick.png")
		end
		
		if (LocalPlayer():HasAssLevel(ASS_LVL_SERVER_OWNER)) then
			MENU:AddSpacer()
			MENU:AddSubMenu("Allow Admins", nil, 
				function(NEWMENU) 
					local Mode = GetGlobalString("ASS_PropProtectAllowAdmins")

					local Items = {}
					Items[ADMIN_ALLOW] = NEWMENU:AddOption("Yes", function() PLUGIN.AllowAdmins(ADMIN_ALLOW) end )
					Items[ADMIN_DISALLOW] = NEWMENU:AddOption("No", function() PLUGIN.AllowAdmins(ADMIN_DISALLOW) end )

					if (Items[Mode]) then
						Items[Mode]:SetImage("icon16/tick.png")
					end
				end ):SetImage("icon16/user_suit.png")
		end
		
		MENU:AddSpacer()
		
		PLUGIN.PropProtectionNonAdmin(MENU)
		
	end

	function PLUGIN.AddGamemodeMenu(DMENU)			

		DMENU:AddSubMenu( "Prop Protection" , nil, PLUGIN.PropProtection ):SetImage("icon16/shield.png")

	end
	
	function PLUGIN.ShowBuddyList( CP )
	
		ASS_Config["pp_buddy"] = ASS_Config["pp_buddy"] or {}
	
		CP:AddControl( "Header", { Text = "ASSmod Buddy List", Description	= "Used for the prop protection." }  )
		
		local CurPlayers = player.GetAll()
		
		for k,v in pairs(ASS_Config["pp_buddy"]) do
		
			CP:AddControl("Button", { Text = "Remove", Label = v.name .. " (" .. v.id .. ")", Command = "ASS_PropProtectRemoveBuddy_CL " .. v.id } )
		
			for idx, pl in pairs(CurPlayers) do
				if (v.id == pl:AssID()) then
				
					table.remove(CurPlayers, idx)
					break;
				end
			end
		end
		
		for k,v in pairs(CurPlayers) do

			if (v != LocalPlayer()) then
			
				CP:AddControl("Button", { Text = "Add", Label = v:Nick() .. " (" .. v:AssID() .. ")", Command = "ASS_PropProtectAddBuddy_CL " .. v:AssID() } )
		
			end
		end
	end
	
	function PLUGIN.AddSpawnmenuStuff()
 		spawnmenu.AddToolCategory( "Utilities", "ASSmod", "ASSmod" )
		spawnmenu.AddToolMenuOption( "Utilities", "ASSmod", "ASSmodBuddyList", "Buddy List", "", "", PLUGIN.ShowBuddyList )
	end

	function PLUGIN.HUDPaint()
	
		local pl = LocalPlayer()
		
		local tr = LocalPlayer():GetEyeTrace()
		local ep = EyePos()

		if (tr.Hit && IsValid(tr.Entity)) then
		
			local text = "Not owned!"
			
			local ENTITY = tr.Entity
			
			local OWNER = ENTITY:GetNetworkedEntity("ASS_Owner")
			
			if (!IsValid(OWNER)) then

				if (ENTITY.Player && type(ENTITY.Player) == "Player" && IsValid(ENTITY.Player)) then
				
					OWNER = ENTITY.Player
				
				elseif (ENTITY.GetPlayer && type(ENTITY.GetPlayer) == "function") then
					
					local O = ENTITY:GetPlayer()
					
					if (type(OWNER) == "Player" && IsValid(OWNER)) then 
					
						OWNER = O

					end	
				end
			end

			if (IsValid(OWNER) && OWNER:IsPlayer()) then					
				text = "Owned by " .. OWNER:Nick()
			end
			
			surface.SetFont("Default")
			local w,h = surface.GetTextSize( text )
			surface.SetTextColor( 128, 0, 0, 255 )
			surface.SetTextPos(ScrW() - w, ScrH() - h)
			surface.DrawText(text)

			surface.SetTextColor( 255, 0, 0, 255 )
			surface.SetTextPos(ScrW() - w - 1, ScrH() - h - 1)
			surface.DrawText(text)
		end
	
	end

	function PLUGIN.Registered()
		hook.Add("HUDPaint",		"HUDPaint_" .. PLUGIN.Filename, 		PLUGIN.HUDPaint )
		hook.Add("AddToolMenuCategories",	"AddToolMenuCategories_" .. PLUGIN.Filename, 		PLUGIN.AddSpawnmenuStuff )
	end
	
end

ASS_RegisterPlugin(PLUGIN)
