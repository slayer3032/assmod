local PLUGIN = {}

PLUGIN.Name = "Teleport"
PLUGIN.Author = "Sezasm"
PLUGIN.Date = "6th August 2012"
PLUGIN.Filename = PLUGIN_FILENAME
PLUGIN.ClientSide = true
PLUGIN.ServerSide = true
PLUGIN.APIVersion = 2.3
PLUGIN.Gamemodes = {}

if SERVER then
	ASS_NewLogLevel("ASS_ACL_TELEPORT")

	function PLUGIN.TeleportPlayer( PLAYER, CMD, ARGS )
		if PLAYER:IsTempAdmin() then
			local TO_TELE = ASS_FindPlayer( ARGS[1] )

			if !TO_TELE then
				ASS_MessagePlayer( PLAYER, "Player not found!" )
				return
			end

			if TO_TELE != PLAYER then
				if TO_TELE:IsBetterOrSame( PLAYER ) then
					ASS_MessagePlayer( PLAYER, "Access denied \"" .. TO_TELE:Nick() .. "\" has same or better access than you." )
					return
				end
			end

			if ASS_RunPluginFunction( "AllowPlayerTeleport", true, PLAYER, TO_TELE ) then
				local trace = {}
				trace.start = PLAYER:GetShootPos()
				trace.endpos = PLAYER:GetShootPos() + PLAYER:GetAimVector() * 99999999999
				trace.filter = PLAYER
				local line = util.TraceLine( trace ) 

				TO_TELE:SetPos( line.HitPos + line.HitNormal * Vector( 35, 35, 1 ) )
				TO_TELE:SetLocalVelocity( Vector( 0, 0, 0 ) )

				ASS_LogAction( PLAYER, ASS_ACL_TELEPORT, "teleported " .. ASS_FullNick(TO_TELE) )
			end
		else
			ASS_MessagePlayer( PLAYER, "Access denied!" )
		end
	end
	concommand.Add( "ASS_TeleportPlayer", PLUGIN.TeleportPlayer )

	ASS_NewLogLevel("ASS_ACL_GOTO")
	function PLUGIN.GotoPlayer( PLAYER, CMD, ARGS )
		if PLAYER:IsTempAdmin() then
			local TO_GOTO = ASS_FindPlayer( ARGS[1] )

			if !TO_GOTO then
				ASS_MessagePlayer( PLAYER, "Player not found!" )
				return
			end

			if ASS_RunPluginFunction( "AllowGoto", true, PLAYER, TO_GOTO ) then
				
				if PLAYER:GetMoveType() == MOVETYPE_NOCLIP then
					PLAYER:SetPos( TO_GOTO:GetPos() + TO_GOTO:GetForward() * 50 )
					return
				end
				if PLAYER:InVehicle() then
					PLAYER:ExitVehicle()
				end
				if !PLAYER:Alive() then
					ASS_MessagePlayer( PLAYER, "You must be alive to goto!" )
					return
				end

				local pos = {}
				for i = 1, 360 do table.insert( pos, TO_GOTO:GetPos() + Vector( math.sin( i ) * 50, math.cos( i ) * 50, 37 ) ) end
				table.insert( pos, TO_GOTO:GetPos() + Vector( 0, 0, 112 ) )

				for k,v in pairs( pos ) do
					local trace = {}
					trace.start = v
					trace.endpos = v 
					trace.mins = Vector( -25, -25, -37 )
					trace.maxs = Vector( 25, 25, 37 )
					local hull = util.TraceHull( trace )

					if !hull.Hit then
						PLAYER:SetPos( v - Vector( 0, 0, 37 ) )
						PLAYER:SetLocalVelocity( Vector( 0, 0, 0 ) )
						PLAYER:SetEyeAngles( ( TO_GOTO:GetShootPos() - PLAYER:GetShootPos() ):Angle() )
						ASS_LogAction( PLAYER, ASS_ACL_GOTO, "went to " .. ASS_FullNick(TO_GOTO) )
						return
					end
				end

				ASS_MessagePlayer( PLAYER, "Could not find a place to put you!  Go into noclip to force a goto." )
				return
			end
		else
			ASS_MessagePlayer( PLAYER, "Access denied!" )
		end
	end
	concommand.Add( "ASS_GotoPlayer", PLUGIN.GotoPlayer )

	ASS_NewLogLevel("ASS_ACL_BRING")
	function PLUGIN.BringPlayer( PLAYER, CMD, ARGS )
		if PLAYER:IsTempAdmin() then
			local TO_BRING = ASS_FindPlayer( ARGS[1] )

			if !TO_BRING then
				ASS_MessagePlayer( PLAYER, "Player not found!" )
				return
			end

			if ASS_RunPluginFunction( "AllowBring", true, PLAYER, TO_BRING ) then
				
				if TO_BRING:GetMoveType() == MOVETYPE_NOCLIP then
					TO_BRING:SetPos( PLAYER:GetPos() + PLAYER:GetForward() * 50 )
					ASS_LogAction( PLAYER, ASS_ACL_BRING, "brought " .. ASS_FullNick(TO_BRING) )
					return
				end
				if TO_BRING:InVehicle() then
					TO_BRING:ExitVehicle()
				end
				if !TO_BRING:Alive() then
					ASS_MessagePlayer( PLAYER, "The target is not alive!" )
					return
				end

				local pos = {}
				for i = 1, 360 do table.insert( pos, PLAYER:GetPos() + Vector( math.sin( i ) * 35, math.cos( i ) * 35, 37 ) ) end
				table.insert( pos, PLAYER:GetPos() + Vector( 0, 0, 112 ) )

				for k,v in pairs( pos ) do
					local trace = {}
					trace.start = v
					trace.endpos = v 
					trace.mins = Vector( -16, -16, -36 )
					trace.maxs = Vector( 16, 16, 36 )
					local hull = util.TraceHull( trace )

					if !hull.Hit then
						TO_BRING:SetPos( v - Vector( 0, 0, 37 ) )
						TO_BRING:SetLocalVelocity( Vector( 0, 0, 0 ) )
						TO_BRING:SetEyeAngles( ( PLAYER:GetShootPos() - TO_BRING:GetShootPos() ):Angle() )
						ASS_LogAction( PLAYER, ASS_ACL_BRING, "brought " .. ASS_FullNick(TO_BRING) )
						return
					end
				end

				ASS_MessagePlayer( PLAYER, "Could not find a place to put the target!" )
				return
			end
		else
			ASS_MessagePlayer( PLAYER, "Access denied!" )
		end
	end
	concommand.Add( "ASS_BringPlayer", PLUGIN.BringPlayer )
end

if CLIENT then
	function PLUGIN.TeleportPlayer( PLAYER, ALLOW )
		if !PLAYER:IsValid() then return end

		RunConsoleCommand( "ASS_TeleportPlayer", PLAYER:AssID() )
	end
	function PLUGIN.GotoPlayer( PLAYER, ALLOW )
		if !PLAYER:IsValid() then return end

		RunConsoleCommand( "ASS_GotoPlayer", PLAYER:AssID() )
	end
	function PLUGIN.BringPlayer( PLAYER, ALLOW )
		if !PLAYER:IsValid() then return end

		RunConsoleCommand( "ASS_BringPlayer", PLAYER:AssID() )
	end

	function PLUGIN.BuildMenu( NEWMENU )
		NEWMENU:AddSubMenu( "Teleport" , nil, function(NEWMENU2) ASS_PlayerMenu( NEWMENU2, {"IncludeLocalPlayer", "IncludeAll"}, PLUGIN.TeleportPlayer ) end):SetImage( "icon16/arrow_in.png" )
		NEWMENU:AddSubMenu( "Goto" , nil, function(NEWMENU2) ASS_PlayerMenu( NEWMENU2, {"IncludeAll"}, PLUGIN.GotoPlayer ) end):SetImage( "icon16/arrow_up.png" )
		NEWMENU:AddSubMenu( "Bring" , nil, function(NEWMENU2) ASS_PlayerMenu( NEWMENU2, {"IncludeAll"}, PLUGIN.BringPlayer ) end):SetImage( "icon16/arrow_down.png" )
	end

	function PLUGIN.AddMenu( DMENU )
		DMENU:AddSubMenu( "Teleport" , nil, PLUGIN.BuildMenu ):SetImage( "icon16/door_open.png" )
	end
end

ASS_RegisterPlugin(PLUGIN)