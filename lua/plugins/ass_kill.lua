
local PLUGIN = {}

PLUGIN.Name = "Kill"
PLUGIN.Author = "Andy Vincent"
PLUGIN.Date = "10th August 2007"
PLUGIN.Filename = PLUGIN_FILENAME
PLUGIN.ClientSide = true
PLUGIN.ServerSide = true
PLUGIN.APIVersion = 2.3
PLUGIN.Gamemodes = {}

if (SERVER) then
	ASS_NewLogLevel("ASS_ACL_KILL")
	--ASS_NewLogLevel("ASS_ACL_KILL_SILENT")

	function PLUGIN.KillPlayer( PLAYER, CMD, ARGS )
		if (PLAYER:HasAssLevel(ASS_LVL_TEMPADMIN)) then
			local TO_KILL = ASS_FindPlayer(ARGS[1])
			if (!TO_KILL) then
				ASS_MessagePlayer(PLAYER, "Player not found!")
				return
			end

			if (TO_KILL != PLAYER) then
				if (TO_KILL:IsBetterOrSame(PLAYER)) then
					ASS_MessagePlayer(PLAYER, "Access denied! \"" .. TO_KILL:Nick() .. "\" has same or better access then you.")
					return
				end
			end

			if (ASS_RunPluginFunction( "AllowPlayerKill", true, PLAYER, TO_KILL )) then
				TO_KILL:Kill()
				ASS_LogAction( PLAYER, ASS_ACL_KILL, "killed " .. ASS_FullNick(TO_KILL) )	
			end
		else
			ASS_MessagePlayer( PLAYER, "Access denied!")
		end
	end
	concommand.Add("ASS_KillPlayer", PLUGIN.KillPlayer)
	
	function PLUGIN.RespawnPlayer( PLAYER, CMD, ARGS )
		if (PLAYER:HasAssLevel(ASS_LVL_TEMPADMIN)) then
			local TO_RESPAWN = ASS_FindPlayer(ARGS[1])
			if (!TO_RESPAWN) then
				ASS_MessagePlayer(PLAYER, "Player not found!")
				return
			end

			if (TO_RESPAWN != PLAYER) then
				if (TO_RESPAWN:IsBetterOrSame(PLAYER)) then
					ASS_MessagePlayer(PLAYER, "Access denied! \"" .. TO_RESPAWN:Nick() .. "\" has same or better access then you.")
					return
				end
			end

			if (ASS_RunPluginFunction( "AllowPlayerKill", true, PLAYER, TO_KILL )) then
				TO_RESPAWN:Spawn()
				ASS_LogAction( PLAYER, ASS_ACL_KILL, "respawned " .. ASS_FullNick(TO_RESPAWN) )	
			end
		else
			ASS_MessagePlayer( PLAYER, "Access denied!")
		end
	end
	concommand.Add("ASS_RespawnPlayer", PLUGIN.RespawnPlayer)
	
	-- This is probably a bad idea but if you want to uncomment it, go for it!
	--[[function PLUGIN.KillSilentPlayer( PLAYER, CMD, ARGS )
		if (PLAYER:HasAssLevel(ASS_LVL_TEMPADMIN)) then
			local TO_KILL = ASS_FindPlayer(ARGS[1])
			if (!TO_KILL) then
				ASS_MessagePlayer(PLAYER, "Player not found!")
				return
			end

			if (TO_KILL != PLAYER) then
				if (TO_KILL:IsBetterOrSame(PLAYER)) then
					ASS_MessagePlayer(PLAYER, "Access denied! \"" .. TO_KILL:Nick() .. "\" has same or better access then you.")
					return
				end
			end

			if (ASS_RunPluginFunction( "AllowPlayerKillSilent", true, PLAYER, TO_KILL )) then
				TO_KILL:KillSilent()
				ASS_LogAction( PLAYER, ASS_ACL_KILL_SILENT, "killed " .. ASS_FullNick(TO_KILL) .. " silently" )	
			end
		else
			ASS_MessagePlayer( PLAYER, "Access denied!")
		end
	end
	concommand.Add("ASS_KillSilentPlayer", PLUGIN.KillSilentPlayer)]]
	
	function PLUGIN.RocketPlayer( PLAYER, CMD, ARGS )
		if (PLAYER:HasAssLevel(ASS_LVL_TEMPADMIN)) then

			local TO_ROCKET = ASS_FindPlayer(ARGS[1])

			if (!TO_ROCKET) then
				ASS_MessagePlayer(PLAYER, "Player not found!")
				return
			end

			if (TO_ROCKET != PLAYER) then
				if (TO_ROCKET:IsBetterOrSame(PLAYER)) then
					ASS_MessagePlayer(PLAYER, "Access denied! \"" .. TO_ROCKET:Nick() .. "\" has same or better access then you.")
					return
				end
			end
			
			if (ASS_RunPluginFunction( "AllowPlayerRocket", true, PLAYER, TO_ROCKET )) then
			
				TO_ROCKET:SetMoveType(MOVETYPE_WALK)
				TO_ROCKET:SetVelocity(Vector(0, 0, 2048))
				
				timer.Simple(3, function()
					local Position = TO_ROCKET:GetPos()
					
					local Effect = EffectData()
					Effect:SetOrigin(Position)
					Effect:SetStart(Position)
					Effect:SetMagnitude(512)
					Effect:SetScale(128)
			
					util.Effect("Explosion", Effect)
					timer.Simple(0.1, function() TO_ROCKET:Kill() end)
				end)
			end
			
			ASS_LogAction( PLAYER, ASS_ACL_KILL, "rocketed " .. ASS_FullNick(TO_ROCKET) )
		else
			ASS_MessagePlayer( PLAYER, "Access denied!")
		end
	end
	concommand.Add("ASS_RocketPlayer", PLUGIN.RocketPlayer)
	
	function PLUGIN.ExplodePlayer( PLAYER, CMD, ARGS )
		if (PLAYER:HasAssLevel(ASS_LVL_TEMPADMIN)) then
			local TO_EXPLODE = ASS_FindPlayer(ARGS[1])

			if (!TO_EXPLODE) then
				ASS_MessagePlayer(PLAYER, "Player not found!")
				return
			end

			if (TO_EXPLODE != PLAYER) then
				if (TO_EXPLODE:IsBetterOrSame(PLAYER)) then
					ASS_MessagePlayer(PLAYER, "Access denied! \"" .. TO_EXPLODE:Nick() .. "\" has same or better access then you.")
					return
				end
			end
			
			if (ASS_RunPluginFunction( "AllowPlayerExplode", true, PLAYER, TO_EXPLODE )) then
				function TO_EXPLODE:Explode() 
				  util.BlastDamage(self,self,self:GetPos(),150,150) 
				  
 				  local effect = EffectData() 
  				      effect:SetOrigin(self:GetPos()) 
  				      effect:SetScale(1) 
  				  util.Effect("Explosion",effect)
				end 

				TO_EXPLODE:Explode()
				TO_EXPLODE:Kill()

				ASS_LogAction( PLAYER, ASS_ACL_KILL, "exploded " .. ASS_FullNick(TO_EXPLODE) )	
			end
		else
			ASS_MessagePlayer( PLAYER, "Access denied!")
		end
	end
	concommand.Add("ASS_ExplodePlayer", PLUGIN.ExplodePlayer)
end

if (CLIENT) then
	function PLUGIN.KillPlayer(PLAYER)
		if (!PLAYER:IsValid()) then return end

		RunConsoleCommand( "ASS_KillPlayer", PLAYER:AssID() )
	end
	
	function PLUGIN.KillSlientPlayer(PLAYER)
		if (!PLAYER:IsValid()) then return end

		RunConsoleCommand( "ASS_KillSilentPlayer", PLAYER:AssID() )
	end
	
	function PLUGIN.ExplodePlayer(PLAYER)
		if (!PLAYER:IsValid()) then return end

		RunConsoleCommand( "ASS_ExplodePlayer", PLAYER:AssID() )
	end
	
	function PLUGIN.RocketPlayer(PLAYER)
		if (!PLAYER:IsValid()) then return end

		RunConsoleCommand( "ASS_RocketPlayer", PLAYER:AssID() )
	end
	
	function PLUGIN.RespawnPlayer(PLAYER)
		if (!PLAYER:IsValid()) then return end

		RunConsoleCommand( "ASS_RespawnPlayer", PLAYER:AssID() )
	end
	
	function PLUGIN.BuildMenu(NEWMENU)
		NEWMENU:AddSubMenu( "Kill" , nil, function(NEWMENU2) ASS_PlayerMenu( NEWMENU2, {"IncludeLocalPlayer", "IncludeAll"}, PLUGIN.KillPlayer ) end):SetImage( "icon16/user_delete.png" )
		--NEWMENU:AddSubMenu( "Kill Silent" , nil, function(NEWMENU2) ASS_PlayerMenu( NEWMENU2, {"IncludeLocalPlayer", "IncludeAll"}, PLUGIN.KillSilentPlayer ) end):SetImage( "icon16/status_offline_delete.png" )
		NEWMENU:AddSubMenu( "Explode" , nil, function(NEWMENU2) ASS_PlayerMenu( NEWMENU2, {"IncludeLocalPlayer", "IncludeAll"}, PLUGIN.ExplodePlayer ) end):SetImage( "icon16/bomb.png" )
		NEWMENU:AddSubMenu( "Rocket" , nil, function(NEWMENU2) ASS_PlayerMenu( NEWMENU2, {"IncludeLocalPlayer", "IncludeAll"}, PLUGIN.RocketPlayer ) end):SetImage( "icon16/sport_shuttlecock_reverse.png" )
		NEWMENU:AddSubMenu( "Respawn" , nil, function(NEWMENU2) ASS_PlayerMenu( NEWMENU2, {"IncludeLocalPlayer", "IncludeAll"}, PLUGIN.RespawnPlayer ) end):SetImage( "icon16/user_go.png" )
	end
	
	function PLUGIN.AddMenu(DMENU)			
		DMENU:AddSubMenu( "Kill" , nil, PLUGIN.BuildMenu):SetImage( "icon16/user_delete.png" )
	end
end

ASS_RegisterPlugin(PLUGIN)


