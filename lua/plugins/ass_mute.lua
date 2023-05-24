
local PLUGIN = {}

PLUGIN.Name = "Mute/Gag"
PLUGIN.Author = "Slayer3032"
PLUGIN.Date = "25th September 2012"
PLUGIN.Filename = PLUGIN_FILENAME
PLUGIN.ClientSide = true
PLUGIN.ServerSide = true
PLUGIN.APIVersion = 2.3
PLUGIN.Gamemodes = {}

if (SERVER) then
	ASS_NewLogLevel("ASS_ACL_MUTE")
	ASS_NewLogLevel("ASS_ACL_GAG")
	
	function PLUGIN.Mute( PLAYER, CMD, ARGS )
		if (PLAYER:HasAssLevel(ASS_LVL_TEMPADMIN)) then
			local TO_MUTE = ASS_FindPlayer(ARGS[1])

			if (!TO_MUTE) then
				ASS_MessagePlayer(PLAYER, "Player not found!")
				return
			end
			
			if (TO_MUTE != PLAYER) then
				if (TO_MUTE:IsBetterOrSame(PLAYER)) then
					ASS_MessagePlayer(PLAYER, "Access denied! \"" .. TO_MUTE:Nick() .. "\" has same or better access then you.")
					return
				end
			end

			if (ASS_RunPluginFunction( "AllowMute", true, PLAYER, TO_MUTE )) then
				TO_MUTE.ChatMuted = true
				ASS_LogAction( PLAYER, ASS_ACL_MUTE, "muted " .. ASS_FullNick(TO_MUTE) )				
			end
		end
	end
	concommand.Add("ass_mute", PLUGIN.Mute)

	function PLUGIN.UnMute( PLAYER, CMD, ARGS )
		if (PLAYER:HasAssLevel(ASS_LVL_TEMPADMIN)) then
			local TO_UNMUTE = ASS_FindPlayer(ARGS[1])

			if (!TO_UNMUTE) then
				ASS_MessagePlayer(PLAYER, "Player not found!")
				return
			end

			if (ASS_RunPluginFunction( "AllowUnMute", true, PLAYER, TO_UNMUTE )) then
				TO_UNMUTE.ChatMuted = false
				ASS_LogAction( PLAYER, ASS_ACL_MUTE, "unmuted " .. ASS_FullNick(TO_UNMUTE) )
			end
		end
	end
	concommand.Add("ass_unmute", PLUGIN.UnMute)

	hook.Add("PlayerSay", "PlayerSay_" .. PLUGIN.Filename, function(ply, msg)
		if ply.ChatMuted then return "" end
	end)
	
	
	function PLUGIN.Gag( PLAYER, CMD, ARGS )
		if (PLAYER:HasAssLevel(ASS_LVL_TEMPADMIN)) then
			local TO_GAG = ASS_FindPlayer(ARGS[1])

			if (!TO_GAG) then
				ASS_MessagePlayer(PLAYER, "Player not found!")
				return
			end
			
			if (TO_GAG != PLAYER) then
				if (TO_GAG:IsBetterOrSame(PLAYER)) then
					ASS_MessagePlayer(PLAYER, "Access denied! \"" .. TO_MUTE:Nick() .. "\" has same or better access then you.")
					return
				end
			end

			if (ASS_RunPluginFunction( "AllowGag", true, PLAYER, TO_GAG )) then
				TO_GAG.VoiceMuted = true
				ASS_LogAction( PLAYER, ASS_ACL_GAG, "gagged " .. ASS_FullNick(TO_GAG) )				
			end
		end
	end
	concommand.Add("ass_gag", PLUGIN.Gag)

	function PLUGIN.UnGag( PLAYER, CMD, ARGS )
		if (PLAYER:HasAssLevel(ASS_LVL_TEMPADMIN)) then
			local TO_UNGAG = ASS_FindPlayer(ARGS[1])

			if (!TO_UNGAG) then
				ASS_MessagePlayer(PLAYER, "Player not found!")
				return
			end

			if (ASS_RunPluginFunction( "AllowUngag", true, PLAYER, TO_UNGAG )) then
				TO_UNGAG.VoiceMuted = false
				ASS_LogAction( PLAYER, ASS_ACL_GAG, "ungagged " .. ASS_FullNick(TO_UNGAG) )
			end
		end
	end
	concommand.Add("ass_ungag", PLUGIN.UnGag)

	hook.Add("PlayerCanHearPlayersVoice", "PlayerCanHearPlayersVoice_" .. PLUGIN.Filename, function(listener, talker)
		if !IsValid(talker) then return end
		if talker.VoiceMuted then return false end
	end)
end

if (CLIENT) then
	function PLUGIN.Mute(PLAYER)
		if (!PLAYER:IsValid()) then return end
		
		RunConsoleCommand("ASS_Mute", PLAYER:AssID())
	end
	
	function PLUGIN.UnMute(PLAYER)
		if (!PLAYER:IsValid()) then return end

		RunConsoleCommand("ASS_Unmute", PLAYER:AssID())
	end
	
	function PLUGIN.Gag(PLAYER)
		if (!PLAYER:IsValid()) then return end
		
		RunConsoleCommand("ASS_Gag", PLAYER:AssID())
	end
	
	function PLUGIN.UnGag(PLAYER)
		if (!PLAYER:IsValid()) then return end

		RunConsoleCommand("ASS_Ungag", PLAYER:AssID())
	end

	function PLUGIN.AddMenu(DMENU)
		DMENU:AddSubMenu( "Mute/Gag", nil, 
			function(NEWMENU)
				NEWMENU:AddSubMenu( "Mute", nil, function(NEWMENU2) ASS_PlayerMenu( NEWMENU2, {"IncludeAll", "IncludeLocalPlayer"}, PLUGIN.Mute ) end ):SetImage( "icon16/comment_delete.png" )
				NEWMENU:AddSubMenu( "Unmute", nil, function(NEWMENU2) ASS_PlayerMenu( NEWMENU2, {"IncludeAll", "IncludeLocalPlayer"}, PLUGIN.UnMute ) end ):SetImage( "icon16/comment_add.png" )
				NEWMENU:AddSubMenu( "Gag", nil, function(NEWMENU2) ASS_PlayerMenu( NEWMENU2, {"IncludeAll", "IncludeLocalPlayer"}, PLUGIN.Gag ) end ):SetImage( "icon16/sound_mute.png" )
				NEWMENU:AddSubMenu( "Ungag", nil, function(NEWMENU2) ASS_PlayerMenu( NEWMENU2, {"IncludeAll", "IncludeLocalPlayer"}, PLUGIN.UnGag ) end ):SetImage( "icon16/sound.png" )
			end
		):SetImage( "icon16/transmit_blue.png" )
	end
end

ASS_RegisterPlugin(PLUGIN)


