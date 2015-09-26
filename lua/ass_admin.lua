local PlayerBans = {}

function ASS_GetBanTable() return PlayerBans end
function ASS_LoadBanlist(id) ASS_RunPluginFunction("LoadBanlist", nil, id) end
function ASS_SaveBanlist(id) ASS_RunPluginFunction("SaveBanlist", nil, id) end

function ASS_Promote( PLAYER, UNIQUEID, NEWRANK, TIME )
	if (PLAYER:HasAssLevel(ASS_LVL_TEMPADMIN)) then
	
		local TO_CHANGE = ASS_FindPlayer(UNIQUEID)
		
		if (!TO_CHANGE) then		
			ASS_MessagePlayer(PLAYER, "Player not found!")
			return
		end

		if (TO_CHANGE:IsBetterOrSame(PLAYER)) then		
			ASS_MessagePlayer(PLAYER, "Access denied! \"" .. TO_CHANGE:Nick() .. "\" has same or better access then you.")
			return
		end
		
		local action = "promote"
		if (NEWRANK > TO_CHANGE:GetAssLevel()) then
			action = "demote"
		end

		if (NEWRANK <= PLAYER:GetAssLevel()) then	
			ASS_MessagePlayer(PLAYER, "Access denied! Can't " .. action .. " to a higher or equal level then yourself")
			return				
		end
		
		if (NEWRANK == ASS_LVL_TEMPADMIN && TIME > tonumber(ASS_Config["max_temp_admin_time"])) then		
			ASS_MessagePlayer(PLAYER, "Access denied! Can't set temp admin to longer then " .. ASS_Config["max_temp_admin_time"] .. " minutes")
			return			
		end

		if (NEWRANK == ASS_LVL_TEMPADMIN) then
			if TIME != 0 then
				TO_CHANGE:SetTAExpiry( os.time() + (TIME*60) )
				ASS_NamedCountdown( TO_CHANGE, "TempAdmin", "Temp Admin Expires in", TIME * 60 )
			end
		else
			ASS_RemoveCountdown( TO_CHANGE, "TempAdmin" )
		end
		
		TO_CHANGE:SetAssLevel( NEWRANK )
		
		ASS_LogAction( PLAYER, ASS_ACL_PROMOTE, action .. "d " .. ASS_FullNick(TO_CHANGE) .. " to " .. ASS_LevelToString(NEWRANK, tostring(TIME) .. " minutes") )
		ASS_MessagePlayer(TO_CHANGE, action .. "d to " .. ASS_LevelToString(NEWRANK, tostring(TIME) .. " minutes") )
		ASS_RunPluginFunction("SavePlayerRank", nil, TO_CHANGE)

	else
		ASS_MessagePlayer( PLAYER, "Access denied!")
	end
end

function ASS_UnBanPlayer( PLAYER, IS_IP, ID_OR_IP )
	if (PLAYER:HasAssLevel(ASS_LVL_TEMPADMIN)) then

		if (ASS_RunPluginFunction( "AllowPlayerUnBan", true, PLAYER, IS_IP, ID_OR_IP )) then
			if (IS_IP) then
				ASS_LogAction(PLAYER, ASS_ACL_BAN_KICK, "unbanned \""..PlayerBans[ID_OR_IP].Name.."\" ("..ID_OR_IP ..") from admin \""..PlayerBans[ID_OR_IP].AdminName.."\"")
			else
				ASS_LogAction(PLAYER, ASS_ACL_BAN_KICK, "unbanned \""..PlayerBans[ID_OR_IP].Name.."\" ("..util.SteamIDFrom64(ID_OR_IP)..") from admin \""..PlayerBans[ID_OR_IP].AdminName.."\"")
			end
			
			PlayerBans[ID_OR_IP] = nil
			ASS_SaveBanlist(ID_OR_IP)
			ASS_RunPluginFunction( "PlayerUnbanned", nil, PLAYER, IS_IP, ID_OR_IP )			
		end
		
	else	
		ASS_MessagePlayer( PLAYER, "Access denied!")
	end	
end

function ASS_BanPlayer( PLAYER, UNIQUEID, TIME, REASON )
	TIME = tonumber(TIME) or 0
	if (#REASON == 0) then REASON = "no reason" end
	
	if (PLAYER:HasAssLevel(ASS_LVL_TEMPADMIN)) then
		local TO_BAN = ASS_FindPlayer(UNIQUEID)
		
		if (!TO_BAN) then	
			ASS_MessagePlayer(PLAYER, "Player not found!")
			return
		end

		if (TO_BAN:IsBetterOrSame(PLAYER)) then
			if PLAYER:IsValid() then
				ASS_MessagePlayer(PLAYER, "Access denied! \"" .. TO_BAN:Nick() .. "\" has same or better access then you.")
				return
			end
		end

		if ((TIME == 0 || TIME > tonumber(ASS_Config["max_temp_admin_ban_time"])) && !PLAYER:HasAssLevel(ASS_LVL_ADMIN)) then					
			ASS_MessagePlayer(PLAYER, "\"" .. TO_BAN:Nick() .. "\" can only be banned for " .. ASS_Config["max_temp_admin_ban_time"] .. " minutes or less by a temporary admin")
			TIME = tonumber(ASS_Config["max_temp_admin_ban_time"])					
		end

		if (ASS_RunPluginFunction( "AllowPlayerBan", true, PLAYER, TO_KICK, TIME, REASON )) then		

			if (TIME > 0) then		
				ASS_LogAction( PLAYER, ASS_ACL_BAN_KICK, "banned " .. ASS_FullNick(TO_BAN) .. " for " .. TIME .. " minutes" )
			else
				ASS_LogAction( PLAYER, ASS_ACL_BAN_KICK, "banned " .. ASS_FullNick(TO_BAN) .. " permanently" )
			end

			ASS_RunPluginFunction( "PlayerBanned", nil, PLAYER, TO_BAN, TIME, REASON )
		
			PlayerBans[TO_BAN:AssID()] = {}
			PlayerBans[TO_BAN:AssID()].Name = TO_BAN:Nick()
			PlayerBans[TO_BAN:AssID()].AdminName = PLAYER:Nick()
			PlayerBans[TO_BAN:AssID()].AdminID = PLAYER:SteamID64()
			PlayerBans[TO_BAN:AssID()].UnbanTime = os.time()+(TIME*60) --no more source magic minute, writeid bullshit
			PlayerBans[TO_BAN:AssID()].Reason = REASON
			ASS_SaveBanlist(TO_BAN:AssID())

			ASS_DropClient(TO_BAN:UserID(), PLAYER:Nick().. " has banned you for "..TIME.." minutes.".. " Reason: ("..REASON..")\n")
		end
		
	else	
		ASS_MessagePlayer( PLAYER, "Access denied!")	
	end	
end

function ASS_KickPlayer( PLAYER, UNIQUEID, REASON )
	if (#REASON == 0) then REASON = "no reason" end

	if (PLAYER:HasAssLevel(ASS_LVL_TEMPADMIN)) then
		local TO_KICK = ASS_FindPlayer(UNIQUEID)

		if (!TO_KICK) then	
			ASS_MessagePlayer(PLAYER, "Player not found!")
			return
		end

		if (TO_KICK:IsBetterOrSame(PLAYER)) then
			if PLAYER:IsValid() then
				ASS_MessagePlayer(PLAYER, "Access denied! \"" .. TO_KICK:Nick() .. "\" has same or better access then you.")
				return
			end
		end

		if (ASS_RunPluginFunction( "AllowPlayerKick", true, PLAYER, TO_KICK, REASON )) then
			ASS_LogAction( PLAYER, ASS_ACL_BAN_KICK, "kicked " .. ASS_FullNick(TO_KICK) .. " with reason \"" .. REASON .. "\"" )
			ASS_RunPluginFunction( "PlayerKicked", nil, PLAYER, TO_KICK, REASON )	
			ASS_DropClient(TO_KICK:UserID(), PLAYER:Nick().." has kicked you. Reason: ("..REASON..")")
		end		
	else	
		ASS_MessagePlayer( PLAYER, "Access denied!")	
	end	
end



--[[function ASS_RconBegin( PLAYER )
	if (PLAYER:HasAssLevel(ASS_LVL_SERVER_OWNER)) then
		PLAYER.ASS_CurrentRcon = ""	
	else
		ASS_MessagePlayer( PLAYER, "Access denied!")
	end
end

function ASS_RconEnd( PLAYER, TIME )
	if (PLAYER:HasAssLevel(ASS_LVL_SERVER_OWNER)) then
		if (PLAYER.ASS_CurrentRcon && PLAYER.ASS_CurrentRcon != "") then	
			if (TIME == 0) then
				game.ConsoleCommand(PLAYER.ASS_CurrentRcon .. "\n")
				ASS_LogAction( PLAYER, ASS_ACL_RCON, "executed \"" .. PLAYER.ASS_CurrentRcon .. "\"" )
			else		
				
			end
		end
	
		PLAYER.ASS_CurrentRcon = nil
	else	
		ASS_MessagePlayer( PLAYER, "Access denied!")
	end
end

function ASS_Rcon( PLAYER, ARGS )
	if (PLAYER:HasAssLevel(ASS_LVL_SERVER_OWNER)) then
		for k,v in pairs(ARGS) do	
			PLAYER.ASS_CurrentRcon = PLAYER.ASS_CurrentRcon .. string.char(v)
		end		
	else	
		ASS_MessagePlayer( PLAYER, "Access denied!")
	end	
end]]
--[[concommand.Add( "ASS_RconBegin",		
	function (pl, cmd, args) 	
		ASS_RconBegin( pl ) 	
	end	
)
concommand.Add( "ASS_Rcon",		
	function (pl, cmd, args) 	
		ASS_Rcon( pl, args ) 	
	end	
)
concommand.Add( "ASS_RconEnd",		
	function (pl, cmd, args) 	
		ASS_RconEnd( pl, tonumber(args[1]) or 0 ) 	
	end	
)]]

function ASS_Rcon(len, pl)
	if pl and pl:IsValid() then
		if pl:HasAssLevel(ASS_LVL_SERVER_OWNER) then
			pl.ASS_CurrentRcon = net.ReadString()
			game.ConsoleCommand(pl.ASS_CurrentRcon .. "\n")
			ASS_LogAction(pl, ASS_ACL_RCON, "ran command \"" .. pl.ASS_CurrentRcon .. "\"")
			pl.ASS_CurrentRcon = nil
		end
	else	
		ASS_MessagePlayer( PLAYER, "Access denied!")
	end	
end
net.Receive("ass_rcon", ASS_Rcon)

concommand.Add( "ASS_KickPlayer",	
	function (pl, cmd, args) 	
		local uid = args[1] 
		table.remove(args, 1) 
		ASS_KickPlayer( pl, uid, table.concat(args, " ") ) 	
	end	
)
concommand.Add( "ASS_BanPlayer",	
	function (pl, cmd, args) 	
		local uid = args[1] 
		local time = tonumber(args[2])
		table.remove(args, 2) 
		table.remove(args, 1) 
		ASS_BanPlayer( pl, uid, time, table.concat(args, " ") ) 	
	end	
)
concommand.Add( "ASS_UnBanPlayer",	
	function (pl, cmd, args) 	
		local uid = args[1]
			
		if tonumber(uid) then
			uid = table.concat(args, "")
			is_ip = false
		else
			uid = table.concat(args, "")
			is_ip = true
		end
			
		ASS_UnBanPlayer( pl, is_ip, uid ) 	
	end	
)
concommand.Add( "ASS_UnbanList",
		function (pl, cmd, args)
			local n = 0
			for id, entry in pairs(PlayerBans) do
				n = n + 1
			end
			ASS_BeginProgress("ASS_BannedPlayer", "Receiving banned list...", n, 0)
			for id, entry in pairs(PlayerBans) do
				umsg.Start("ASS_BannedPlayer", pl)
					umsg.String( entry.Name )
					umsg.String( id )
					umsg.String( entry.AdminName )
				umsg.End()
			end
			umsg.Start("ASS_ShowBannedPlayerGUI", pl)
			umsg.End()
		end
	)
concommand.Add( "ASS_PromotePlayer",	
		function (pl, cmd, args) 	
			local uid = args[1] 
			local rank = tonumber(args[2])
			local time = tonumber(args[3]) or 60
			ASS_Promote( pl, uid, rank, time) 	
		end	
	)
concommand.Add( "ASS_GiveOwnership",	
		function (pl, cmd, args) 	
			if (pl:HasAssLevel(ASS_LVL_SERVER_OWNER)) then
			
				local other = ASS_FindPlayer(args[1])
				
				if (!other || !other:IsValid()) then
					ASS_MessagePlayer(pl, "Invalid Player!")
					return
				end
				
				if (other != pl) then
					other:SetAssLevel( ASS_LVL_SERVER_OWNER )
					ASS_RunPluginFunction("SavePlayerRank", nil, other)

					ASS_MessagePlayer(pl, "Ownership Given!")
				else
					ASS_MessagePlayer(pl, "You're an owner already!")
				end
			else
				ASS_MessagePlayer(pl, "Access denied!")
			end
		end	
	)
concommand.Add("ASS_SetClientTell",function(PLAYER, CMD, ARGS)
		if (PLAYER:HasAssLevel(ASS_LVL_SERVER_OWNER)) then
			if (tonumber(ARGS[1]) == 0) then
				ASS_LogAction( PLAYER, ASS_ACL_SETTING, "set clients to not be notified of admin actions")
				ASS_Config["tell_clients_what_happened"] = 0
				ASS_WriteConfig()
				SetGlobalString( "ASS_ClientTell", tonumber(ARGS[1]) )
			elseif (tonumber(ARGS[1]) == 1) then 
				ASS_LogAction( PLAYER, ASS_ACL_SETTING, "set clients to be notified of admin actions")
				ASS_Config["tell_clients_what_happened"] = 1
				ASS_WriteConfig()
				SetGlobalString( "ASS_ClientTell", tonumber(ARGS[1]) )
			end
		else
			ASS_MessagePlayer( PLAYER, "Access denied!")
		end
	
	end
	)