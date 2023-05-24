local PlayerBans = {}

function ASS_GetBanTable()
	if !PlayerBans then PlayerBans = {} end
	return PlayerBans
end

function ASS_SetLevel( PLAYER, UNIQUEID, NEWRANK, TIME )
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
				ASS_RunPluginFunction("Countdown", nil, "TempAdmin", "Temp Admin Expires in", TIME*60, TO_CHANGE)
			end
		else
			ASS_RunPluginFunction("RemoveCountdown", nil, "TempAdmin", TO_CHANGE)
		end
		
		TO_CHANGE:SetAssLevel( NEWRANK )
		
		ASS_LogAction( PLAYER, ASS_ACL_SETLEVEL, action .. "d " .. ASS_FullNick(TO_CHANGE) .. " to " .. ASS_LevelToString(NEWRANK, tostring(TIME) .. " minutes") )
		ASS_MessagePlayer(TO_CHANGE, action .. "d to " .. ASS_LevelToString(NEWRANK, tostring(TIME) .. " minutes") )
		ASS_RunPluginFunction("SavePlayerRank", nil, TO_CHANGE)

	else
		ASS_MessagePlayer( PLAYER, "Access denied!")
	end
end

function ASS_UnBanPlayer( PLAYER, ID, REASON )
	if (PLAYER:HasAssLevel(ASS_LVL_TEMPADMIN)) then
		if !PlayerBans[ID] then return ASS_MessagePlayer( PLAYER, "ID not found!") end
		if ASS_RunPluginFunction("AllowPlayerUnban", true, PLAYER, ID) then
			ASS_LogAction(PLAYER, ASS_ACL_BAN_KICK, "unbanned \""..PlayerBans[ID].Name.."\" ("..util.SteamIDFrom64(ID)..") from admin \""..PlayerBans[ID].AdminName.."\" with reason \""..(REASON or "no reason").."\"")	
			ASS_RunPluginFunction("PlayerUnban", nil, ID, PLAYER)
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
				ASS_LogAction( PLAYER, ASS_ACL_BAN_KICK, "banned " .. ASS_FullNick(TO_BAN) .. " for " .. TIME .. " minutes with reason \"" .. REASON .. "\"" )
			else
				ASS_LogAction( PLAYER, ASS_ACL_BAN_KICK, "banned " .. ASS_FullNick(TO_BAN) .. " permanently with reason \"" .. REASON .. "\"" )
			end

			ASS_RunPluginFunction( "PlayerBan", nil, PLAYER, TO_BAN, TIME, REASON )
			if ASS_Config["tell_clients_what_happened"] then
				ASS_DropClient(TO_BAN:UserID(), PLAYER:Nick().. " has banned you for "..TIME.." minutes.".. " Reason: ("..REASON..")")
			else
				ASS_DropClient(TO_BAN:UserID(), "You have been banned for "..TIME.." minutes.".. " Reason: ("..REASON..")")
			end
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

			if ASS_Config["tell_clients_what_happened"] then
				ASS_DropClient(TO_KICK:UserID(), PLAYER:Nick().." has kicked you. Reason: ("..REASON..")")
			else
				ASS_DropClient(TO_KICK:UserID(), "You have been kicked. Reason: ("..REASON..")")
			end
		end		
	else	
		ASS_MessagePlayer( PLAYER, "Access denied!")	
	end	
end

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

local function kickplayer(len, pl)
	if pl and pl:IsValid() then
		local id = net.ReadString()
		local reason = net.ReadString() or ' '
		ASS_KickPlayer(pl, id, reason)
	end
end
net.Receive('ass_kickplayer', kickplayer)

local function banplayer(len, pl)
	if pl and pl:IsValid() then
		local id = net.ReadString()
		local time = net.ReadUInt(32)
		local reason = net.ReadString() or ' '
		ASS_BanPlayer(pl, id, time, reason)
	end
end
net.Receive('ass_banplayer', banplayer)

local function unbanplayer(len, pl)
	if pl and pl:IsValid() then
		local id = net.ReadString()
		local reason = net.ReadString() or "no reason"
		ASS_UnBanPlayer(pl, id, reason)
	end
end
net.Receive('ass_unbanplayer', unbanplayer)

local function unbanlist(len, pl)
	if pl and pl:IsValid() then
		if pl:HasAssLevel(ASS_LVL_ADMIN) then
			net.Start('ass_unbanlist')
				net.WriteTable(PlayerBans)
			net.Send(pl)
		end
	end
end
net.Receive('ass_unbanlist', unbanlist)

local function setlevel(len, pl)
	if pl and pl:IsValid() then
		local id = net.ReadString()
		local level = net.ReadUInt(8)
		local time = net.ReadUInt(32) or 0
		ASS_SetLevel(pl, id, level, time)
	end
end
net.Receive('ass_setlevel', setlevel)

local function clienttell(len, pl)
	if pl and pl:IsValid() then
		if pl:HasAssLevel(ASS_LVL_SERVER_OWNER) then
			local tell = net.ReadBool()
			local text = (tell and "") or "not "
			ASS_LogAction( pl, ASS_ACL_SETTING, "set clients to "..text.."be notified of admin actions")
			ASS_Config["tell_clients_what_happened"] = tell
			ASS_WriteConfig()
			net.Start('ass_clienttell')
				net.WriteBool(tell)
			net.Send(player.GetAll())
		end
	end
end
net.Receive('ass_clienttell', clienttell)

concommand.Add("ass_giveownership",	
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

concommand.Add("ass_banplayer", function(pl,cmd,args)
	if pl:HasAssLevel(ASS_LVL_SERVER_OWNER) then
		local id = args[1]
		local time = args[2]
		table.remove(args, 2)
		table.remove(args, 1)
		ASS_BanPlayer(pl, id, time, table.concat(args, " "))
	else
		ASS_MessagePlayer(pl, "Access denied!")
	end
end)

concommand.Add("ass_kickplayer", function(pl,cmd,args)
	if pl:HasAssLevel(ASS_LVL_SERVER_OWNER) then
		local id = args[1]
		table.remove(args, 1)
		ASS_KickPlayer(pl, id, table.concat(args, " "))
	else
		ASS_MessagePlayer(pl, "Access denied!")
	end
end)

concommand.Add("ass_banid", function(pl,cmd,args)
	if (ASS_Config["banlist"] != "Default Banlist") then ASS_MessagePlayer(pl, "This command is not supported by mysql banlists!") return end
	
	if pl:HasAssLevel(ASS_LVL_SERVER_OWNER) then
		if !args[1] then
			ASS_MessagePlayer(pl,"Assmod BanID Help: ass_banid <steamid64> \"<name>\" <time in minutes or 0> \"<reason>\"")
		else
			if IsValid(ASS_FindPlayer(args[1])) then ASS_MessagePlayer(pl, "Player found in server, use ass_banplayer!") return end

			local id = tostring(args[1])
			local name = tostring(args[2])
			local time = args[3]
			table.remove(args, 3)
			table.remove(args, 2)
			table.remove(args, 1)

			if !tonumber(time) then ASS_MessagePlayer(pl,"Assmod BanID Help: ass_banid <steamid64> \"<name>\" <time in minutes or 0> \"<reason>\"!!!") return end

			ASS_RunPluginFunction("RefreshBanlist")
    
			local bantime = (tonumber(time) == 0) and 0 or (os.time()+(tonumber(time)*60))

			PlayerBans[id] = {}
			PlayerBans[id].Name = name
			PlayerBans[id].AdminName = pl:Nick() or "Server Console"
			PlayerBans[id].AdminID = pl:SteamID64() or "Server Console"
			PlayerBans[id].UnbanTime = bantime
			PlayerBans[id].Reason = table.concat(args, " ") or "no reason"

			ASS_LogAction(pl, ASS_ACL_BAN_KICK, "manually banned \""..name.."\" ("..id..") for "..time.." minutes with reason \""..table.concat(args, " ").."\"")

			ASS_RunPluginFunction("SaveBanlist")
		end
	else
		ASS_MessagePlayer(pl, "Access denied!")
	end
end)

concommand.Add("ass_removeid", function(pl,cmd,args)
	if pl:HasAssLevel(ASS_LVL_SERVER_OWNER) then
		if !args[1] then
			ASS_MessagePlayer(pl,"Assmod RemoveID Help: ass_removeid <steamid64> \"<reason>\"")
		else
			local id = args[1]
			table.remove(args, 1)
			local reason = "no reason"
			if args[1] then reason = table.concat(args, " ") end
			ASS_UnBanPlayer(pl, id, reason)
		end
	else
		ASS_MessagePlayer(pl, "Access denied!")
	end
end)

concommand.Add("ass_listid", function(pl,cmd,args)
	if pl:HasAssLevel(ASS_LVL_SERVER_OWNER) then
		if table.Count(ASS_GetBanTable()) > 0 then
			for k,v in pairs(ASS_GetBanTable()) do
				pl:PrintMessage(HUD_PRINTCONSOLE, v.Name.."("..k..")")
				pl:PrintMessage(HUD_PRINTCONSOLE, "    Admin: "..v.AdminName.."("..v.AdminID..")")
				pl:PrintMessage(HUD_PRINTCONSOLE, "    Reason: "..v.Reason)
				pl:PrintMessage(HUD_PRINTCONSOLE, "    Length: "..((tobool(v.UnbanTime) and string.NiceTime(v.UnbanTime-os.time())) or "Permanent"))
			end
		else 
			pl:PrintMessage(HUD_PRINTCONSOLE, "Assmod Banlist is empty!")
		end
	else
		ASS_MessagePlayer(pl, "Access denied!")
	end
end)


// override kickid2 which is defined by Gmod - this is the console command fired off when you click
// the kick button on the scoreboard
concommand.Add( "kickid2", 		
	function ( pl, cmd, args )
		local id = args[1]
		local reason = args[2] or "Kicked"
			
		for k,v in pairs(player.GetAll()) do
			if (id == v:UserID()) then
				ASS_KickPlayer(pl, v:AssID(), reason)
				return	
			end
		end
	end 
)
// override banid2 which is defined by Gmod - this is the console command fired off when you click
// a ban button on the scoreboard
concommand.Add( "banid2", 
	function ( pl, cmd, args )
		local length 	= args[1]
		local id 		= args[2]
			
		for k,v in pairs(player.GetAll()) do
			if (id == v:UserID()) then
				ASS_BanPlayer(pl, v:AssID(), length, "")
				return	
			end
		end
	end 
)