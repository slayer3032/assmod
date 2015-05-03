

AddCSLuaFile("autorun/ass.lua")
AddCSLuaFile("ass_shared.lua")
AddCSLuaFile("ass_client.lua")

include("ass_shared.lua")
include("ass_res.lua")

// SERVER LOGGING STUFF

function ASS_NewLogLevel( ID )	_G[ ID ] = ID		end

ASS_NewLogLevel("ASS_ACL_JOIN_QUIT")
ASS_NewLogLevel("ASS_ACL_SPEECH")
ASS_NewLogLevel("ASS_ACL_BAN_KICK")
ASS_NewLogLevel("ASS_ACL_RCON")
ASS_NewLogLevel("ASS_ACL_PROMOTE")
ASS_NewLogLevel("ASS_ACL_ADMINSPEECH")
ASS_NewLogLevel("ASS_ACL_SETTING")

local ActiveNotices = {}
local PlayerRankings = {}
local PlayerBans = {}
local ChatLogFilter = { ASS_ACL_SPEECH, ASS_ACL_KILL_SILENT, ASS_ACL_JOIN_QUIT }

function ASS_IsLan()	return !game.SinglePlayer() && (GetConVarNumber("sv_lan") != 0)	end

// When a console command is run on a dedicated server, the PLAYER argument is a
// NULL ENTITY. We setup this meta table so that the IsAdmin etc commands still work
// and return the appropriate level.

local CONSOLE = FindMetaTable("Entity")
function CONSOLE:IsSuperAdmin()		if (!self:IsValid()) then return true else return false end end
function CONSOLE:IsAdmin()		if (!self:IsValid()) then return true else return false end end
function CONSOLE:IsTempAdmin()		if (!self:IsValid()) then return true else return false end end
function CONSOLE:IsRespected()		if (!self:IsValid()) then return true else return false end end
function CONSOLE:IsGuest()		if (!self:IsValid()) then return false else return true end end
function CONSOLE:IsUnwanted()		if (!self:IsValid()) then return false else return true end end
function CONSOLE:GetAssLevel()		if (!self:IsValid()) then return ASS_LVL_SERVER_OWNER else return ASS_LVL_GUEST end end
function CONSOLE:HasAssLevel(n)		if (!self:IsValid()) then return ASS_LVL_SERVER_OWNER <= n else return ASS_LVL_GUEST <= n end end
function CONSOLE:IsBetterOrSame(PL2)	if (!self:IsValid()) then return ASS_LVL_SERVER_OWNER <= PL2:GetNetworkedInt("ASS_isAdmin") else return ASS_LVL_GUEST <= PL2:GetNetworkedInt("ASS_isAdmin") end end
function CONSOLE:GetTAExpiry(n)		if (!self:IsValid()) then return 0		end end
function CONSOLE:AssID()		if (!self:IsValid()) then return "CONSOLE"	end end
function CONSOLE:SteamID()		if (!self:IsValid()) then return "CONSOLE"	end end
function CONSOLE:SteamID64()		if (!self:IsValid()) then return "CONSOLE"	end end
function CONSOLE:IPAddress()		if (!self:IsValid()) then return "CONSOLE"	end end
function CONSOLE:InitLevel()					end
function CONSOLE:SetAssLevel(RANK)					end
function CONSOLE:SetAssAttribute(NAME,VAL)			end
function CONSOLE:GetAssAttribute(NAME, TYPE, DEFAULT)		end
function CONSOLE:SetTAExpiry(TIME)				end
function CONSOLE:Hurt(AMT)					end
function CONSOLE:Nick()			if (!self:IsValid()) then return "Console"	end end
function CONSOLE:PrintMessage(LOC, MSG)		if (LOC == HUD_PRINTCONSOLE || LOC == HUD_PRINTNOTIFY) then Msg(MSG) end end
function CONSOLE:ChatPrint(MSG)				end
CONSOLE = nil

local PLAYER = FindMetaTable("Player")

function PLAYER:InitLevel()	
	ASS_LoadRankings(self:AssID())
	
	if (PlayerRankings[ self:AssID() ]) then
		self:SetAssLevel(PlayerRankings[ self:AssID() ].Rank)
	else
		self:SetAssLevel(ASS_LVL_GUEST)
	end
end

function PLAYER:SetAssLevel( RANK )	
	self:SetNetworkedInt("ASS_isAdmin", RANK )

	local ID = self:AssID()
	PlayerRankings[ ID ] = PlayerRankings[ ID ] or {}
	PlayerRankings[ ID ].Rank = RANK
	PlayerRankings[ ID ].Name = self:Nick()
	PlayerRankings[ ID ].SteamID = self:SteamID()
	PlayerRankings[ ID ].PluginValues = PlayerRankings[ ID ].PluginValues or {}
	
	if (RANK == ASS_LVL_TEMPADMIN) then
		PlayerRankings[ ID ].Rank = ASS_LVL_RESPECTED
	end
	
	ASS_Debug( self:Nick() .. " given level " .. self:GetAssLevel() .. "\n")
	ASS_RunPluginFunction( "RankingChanged", nil, self )
end

function PLAYER:SetAssAttribute(NAME, VALUE)
	if (type(NAME) != "string") then Msg("SetAssAttribute error - Name invalid\n") return end
	if (type(VALUE) != "string" && type(VALUE) != "number" && type(VALUE) != "boolean" && type(VALUE) != "nil") then Msg("SetAssAttribute error - Value invalid\n") return end
	
	NAME = string.lower(NAME)
		
	local ID = self:AssID()
	if (!PlayerRankings[ ID ]) then
		self:SetAssLevel(ASS_LVL_GUEST)
	end
	if (!PlayerRankings[ ID ].PluginValues) then
		PlayerRankings[ ID ].PluginValues = {}
	end
	PlayerRankings[ ID ].PluginValues[NAME] = VALUE
	
	ASS_LoadRankings(self:AssID()) -- prevent multi-instance servers overwriting rank
	ASS_SaveRankings(self:AssID())
end

function PLAYER:GetAssAttribute(NAME, TYPE, DEFAULT)
	if (type(NAME) != "string") then  Msg("SetAssAttribute error - Name invalid\n") return DEFAULT end
	
	local convertFunc = nil
	if (TYPE == "string") then	convertFunc = tostring
	elseif (TYPE == "number") then	convertFunc = tonumber
	elseif (TYPE == "boolean") then	convertFunc = util.tobool
	else
		Msg("SetAssAttribute error - Type invalid\n")
		return DEFAULT
	end

	NAME = string.lower(NAME)
	
	local ID = self:AssID()
	if (!PlayerRankings[ ID ]) then
		return convertFunc(DEFAULT)
	end
	if (!PlayerRankings[ ID ].PluginValues) then
		return convertFunc(DEFAULT)
	end
	if (PlayerRankings[ self:AssID() ].PluginValues[NAME] == nil) then
		return convertFunc(DEFAULT)
	end
	
	local result = convertFunc(PlayerRankings[ self:AssID() ].PluginValues[NAME])
	if (result == nil) then
		return convertFunc(DEFAULT)
	else
		return result
	end
end

function PLAYER:SetTAExpiry(TIME)	
	self:SetNetworkedFloat("ASS_tempAdminExpiry", TIME)
end

function PLAYER:Hurt(HEALTH)
	local newHealth = self:Health() - HEALTH
	if (newHealth <= 0) then
		self:SetHealth(0)
		self:Kill()
	else
		self:SetHealth(newHealth)
	end
end
PLAYER = nil

function ASS_GetRankingTable()
	return PlayerRankings
end

function ASS_LoadRankings(id)
	ASS_RunPluginFunction("LoadRankings", nil, id)
end

function ASS_SaveRankings(id)
	ASS_RunPluginFunction("SaveRankings", nil, id)
end

function ASS_GetBanTable()
	return PlayerBans
end

function ASS_LoadBanlist(id)
	ASS_RunPluginFunction("LoadBanlist", nil, id)
end

function ASS_SaveBanlist(id)
	ASS_RunPluginFunction("SaveBanlist", nil, id)
end

function ASS_LogAction( PLAYER, ACL, ACTION )
	Msg( PLAYER:Nick() .. " -> " .. ACTION .. "\n")
	ASS_TellPlayers(PLAYER, ACL, ACTION)
	ASS_RunPluginFunction("AddToLog", nil, PLAYER, ACL, ACTION)
end

function ASS_Initialize()
	ASS_InitResources()
	ASS_LoadPlugins()
	ASS_LoadBanlist()
	
	for k,v in pairs(ASS_Config["fixed_notices"]) do
		ASS_AddNamedNotice( ASS_GenerateFixedNoticeName(v.text, v.duration), v.text or "", tonumber(v.duration) or 10)
	end
end

function ASS_InitPostEntity()
	SetGlobalInt( "ASS_ClientTell", ASS_Config["tell_clients_what_happened"] or 1 )
end

function ASS_PlayerInitialSpawn( PLAYER )
	PLAYER:ConCommand("ASS_CS_Initialize\n")
	
	if (ASS_IsLan()) then 
		PLAYER:SetNetworkedString("ASS_AssID", PLAYER:IPAddress())
	else 
		PLAYER:SetNetworkedString("ASS_AssID", PLAYER:SteamID64())
	end 
	
	ASS_LogAction(PLAYER, ASS_ACL_JOIN_QUIT, "has joined")
	
	if (game.SinglePlayer() || PLAYER:IsListenServerHost()) then	
		PLAYER:SetAssLevel(ASS_LVL_SERVER_OWNER)
		ASS_SaveRankings(PLAYER:AssID())
		
	else	
		PLAYER:InitLevel()	
	end
	
	for k,v in pairs(ActiveNotices) do
		ASS_SendNotice(PLAYER, v.Name, v.Text, v.Duration)
	end
	
	if (#player.GetAll() <= 2 && !PLAYER:IsTempAdmin() && util.tobool(ASS_Config["demomode"]) ) then
		local TempAdminTime = (tonumber(ASS_Config["demomode_ta_time"]) or 1) *60 
		PLAYER:SetAssLevel( ASS_LVL_TEMPADMIN )
		PLAYER:SetTAExpiry( CurTime() + TempAdminTime )

		ASS_NamedCountdown( PLAYER, "TempAdmin", "Temp Admin Expires in", TempAdminTime )
		ASS_SaveRankings(PLAYER:AssID());

		ASS_MessagePlayer( PLAYER, "Welcome to the ASSMod demo. Congratulations - you've been granted temporary admin")
		ASS_MessagePlayer( PLAYER, "Bind a key to +ASS_Menu to see the admin-menu (I recommend x):")
		ASS_MessagePlayer( PLAYER, "bind x \"+ASS_Menu\"")
	end

	ASS_Debug( PLAYER:Nick() .. " has access level " .. PLAYER:GetAssLevel() .. "\n")
end

function ASS_PlayerDisconnect( PLAYER )
	ASS_LogAction( PLAYER, ASS_ACL_JOIN_QUIT, "disconnected" )
end

function ASS_EventConnect( TBL )
	for _, pl in pairs(player.GetAll()) do
		chat.AddText(pl, Color(0, 255, 0), TBL.name, Color(255, 255, 255), " joined the server")
	end
	ASS_RunPluginFunction("PlayerConnect", nil, TBL)	
end

function ASS_EventDisconnect( TBL )
	for _, pl in pairs(player.GetAll()) do
		chat.AddText(pl, Color(0, 255, 0), TBL.name, Color(255, 255, 255), " left the server")
	end
	ASS_RunPluginFunction("PlayerDisonnect", nil, TBL)	
end

function ASS_TellPlayers( PLAYER, ACL, ACTION )
	for k,v in pairs(ChatLogFilter) do if (v == ACL) then return end end
	
	if (util.tobool(ASS_Config["tell_admins_what_happened"]) and util.tobool( ASS_Config["tell_clients_what_happened"])) then
		for _, pl in pairs(player.GetAll()) do
			chat.AddText(pl, Color(0, 255, 0), PLAYER:Nick(), Color(255, 255, 255), " "..ACTION)
		end
	else
		for _, pl in pairs(player.GetAll()) do
			if pl:IsTempAdmin() then
				chat.AddText(pl, Color(0, 255, 0), PLAYER:Nick(), Color(255, 255, 255), " "..ACTION)
			end
		end
	end	
end

function ASS_PlayerSpeech( PLAYER, TEXT, TEAMSPEAK )
	local prefix = ASS_Config["admin_speak_prefix"]
	
	if (!prefix || prefix == "") then
		prefix = "@"
	end
	
	local prefixlen = #prefix

	if (PLAYER:IsTempAdmin() && string.sub(TEXT, 1, prefixlen) == prefix) then
		ASS_TellPlayers( PLAYER, ASS_ACL_ADMINSPEECH, string.sub(TEXT, prefixlen+1) )
		ASS_LogAction( PLAYER, ASS_ACL_SPEECH, "said \"" .. TEXT .. "\"" )
		return ""
	end
	
	if (!TEAMSPEAK) then
		ASS_LogAction( PLAYER, ASS_ACL_SPEECH, "said \"" .. TEXT .. "\" to his team" )
	else
		ASS_LogAction( PLAYER, ASS_ACL_SPEECH, "said \"" .. TEXT .. "\"" )
	end
end

function ASS_FindPlayerSteamOrIP( USERID )
	for _, pl in pairs(player.GetAll()) do

		if (pl:AssID() == USERID) then
			return pl
		end

	end

	return nil
end

function ASS_FindPlayerUserID( USERID )
	local UID = tonumber(USERID)
	if (UID) then
		for _, pl in pairs(player.GetAll()) do
	
			if (pl:UserID() == UID) then
		
				return pl
		
			end
	
		end
	end
	
	return ASS_FindPlayerSteamOrIP(USERID)
end

function ASS_FindPlayerName( NAME )
	local lNAME = string.lower(NAME)

	for _,pl in pairs(player.GetAll()) do
		local name = pl:Nick()
		if (string.lower(string.sub(name, 1, #lNAME)) == lNAME) then
			return pl
		end
	end

	return ASS_FindPlayerUserID(NAME)
end

function ASS_FindPlayer( UNIQUEID )
	if (!UNIQUEID) then return nil end

	local pl = player.GetBySteamID64(UNIQUEID)
	
	if (!pl || !pl:IsValid()) then 
		return ASS_FindPlayerName(UNIQUEID)
	end
	
	return pl
end

function ASS_MessagePlayer( PLAYER, MESSAGE )
	chat.AddText(PLAYER, Color(0, 229, 238), MESSAGE)
end

function ASS_FullNick( PLAYER )		return "\"" .. PLAYER:Nick() .. "\" (" .. PLAYER:SteamID() .. " | " .. LevelToString(PLAYER:GetAssLevel()) .. ")"		end
function ASS_FullNickLog( PLAYER )		return "\"" .. PLAYER:Nick() .. "\" (" .. PLAYER:SteamID() .. " | " .. PLAYER:IPAddress() .. ")"		end

local NextAssThink = 0

function ASS_Think()
	if (CurTime() >= NextAssThink) then
		for _, ply in pairs( player.GetAll() ) do
			if (ply:GetAssLevel() == ASS_LVL_TEMPADMIN && CurTime() >= ply:GetTAExpiry()) then
				ASS_LogAction(ply, ASS_ACL_PROMOTE, "Temp admin expired. Demoted to respected user.")

				ply:SetAssLevel( ASS_LVL_RESPECTED )
				ASS_RemoveCountdown( ply, "TempAdmin" )

				ASS_SaveRankings(ply:AssID())
			end
		end
	
		if #ActiveNotices > 0 then
			SetGlobalString( "ServerTime", os.date("%H:%M:%S") )
			SetGlobalString( "ServerDate", os.date("%d/%b/%Y") )	
		end
	end
	
	NextAssThink = CurTime() + 1
end

function ASS_SendNoticesRaw( PLAYER )
	for k,v in pairs(ActiveNotices) do
		umsg.Start("ASS_RawNotice", PLAYER)
			umsg.String( v.Name ) 
	  		umsg.String( v.Text ) 
	 		umsg.Float( v.Duration ) 
		umsg.End()
	end
end

function ASS_SendNotice( PLAYER, NAME, TEXT, DURATION )
	ASS_Debug("Sending notice \"" .. TEXT .. "\"\n")

	if (NAME) then
		umsg.Start("ASS_NamedNotice", PLAYER)
		umsg.String( NAME ) 
	else
		umsg.Start("ASS_Notice", PLAYER)
	end
	
  		umsg.String( ASS_FormatText(TEXT) ) 
 		umsg.Float( DURATION ) 
	umsg.End()
end

function ASS_GenerateFixedNoticeName( TEXT, DURATION )
	return "FIXED:" .. util.CRC( tostring(TEXT) .. tostring(DURATION) )
end

function ASS_AddFixedNotice( TEXT, DURATION ) 
	ASS_AddNamedNotice( ASS_GenerateFixedNoticeName(TEXT, DURATION) , TEXT, DURATION)	
	table.insert( ASS_Config["fixed_notices"], { duration = DURATION, text = TEXT } )
	ASS_WriteConfig()
end

function ASS_AddNotice( TEXT, DURATION ) 
	ASS_AddNamedNotice(nil, TEXT, DURATION)
end

function ASS_AddNamedNotice( NAME, TEXT, DURATION ) 
	if (!NAME) then
		NAME = "NOTE:" .. util.CRC( tostring(TEXT) .. tostring(DURATION) .. tostring(CurTime()) .. tostring(#ActiveNotices) )
	end

	for k,v in pairs(ActiveNotices) do
		if (v.Name && v.Name == NAME) then
			table.remove(ActiveNotices, k)
			break
		end
	end
	
	table.insert( ActiveNotices, { Name = NAME, Text = TEXT, Duration = DURATION } )
	ASS_SendNotice(nil, NAME, TEXT, DURATION)
end

function ASS_FindNoteText( NAME )
	for k,v in pairs(ActiveNotices) do
		if (v.Name && v.Name == NAME) then
			return v.Text
		end
	end
	return nil
end

function ASS_RemoveNotice( NAME ) 
	for k,v in pairs(ActiveNotices) do
	
		if (v.Name && v.Name == NAME) then
			table.remove(ActiveNotices, k)
			break
		end
	
	end
	
	for k,v in pairs(ASS_Config["fixed_notices"]) do
		if (NAME == ASS_GenerateFixedNoticeName(v.text, v.duration)) then
			table.remove(ASS_Config["fixed_notices"], k)
			ASS_WriteConfig()
			break
		end
	end
	
	umsg.Start("ASS_RemoveNotice")
 		umsg.String( NAME ) 
 	umsg.End()
end


function ASS_Countdown( PLAYER, TEXT, DURATION ) 
	ASS_Debug("Countdown \"" .. TEXT .. "\" for " .. DURATION .. "\n")
	umsg.Start("ASS_Countdown", PLAYER)
 		umsg.String( TEXT ) 
 		umsg.Float( DURATION ) 
 	umsg.End()
end

function ASS_CountdownAll( TEXT, DURATION ) 
	ASS_Debug("Countdown \"" .. TEXT .. "\" for " .. DURATION .. "\n")
	umsg.Start("ASS_Countdown")
 		umsg.String( TEXT ) 
 		umsg.Float( DURATION ) 
 	umsg.End()
 end

function ASS_NamedCountdown( PLAYER, NAME, TEXT, DURATION ) 
	ASS_Debug("Countdown \"" .. TEXT .. "\" for " .. DURATION .. "\n")
	umsg.Start("ASS_NamedCountdown", PLAYER)
		umsg.String( NAME ) 
		umsg.String( TEXT ) 
		umsg.Float( DURATION ) 
	umsg.End()
end

function ASS_NamedCountdownAll( NAME, TEXT, DURATION ) 
	ASS_Debug("Countdown \"" .. TEXT .. "\" for " .. DURATION .. "\n")
	umsg.Start("ASS_NamedCountdown")
		umsg.String( NAME ) 
		umsg.String( TEXT ) 
		umsg.Float( DURATION ) 
	umsg.End()
end

function ASS_RemoveCountdown( PLAYER, NAME ) 
	umsg.Start("ASS_RemoveCountdown", PLAYER)
		umsg.String( NAME ) 
	umsg.End()
end

function ASS_RemoveCountdownAll( NAME ) 
	umsg.Start("ASS_RemoveCountdown")
		umsg.String( NAME ) 
	umsg.End()
end

function ASS_BeginProgress( PLAYER, NAME, TEXT, MAXIMUM ) 
	if (MAXIMUM == 0) then
		return 
	end

	umsg.Start("ASS_BeginProgress", PLAYER)
		umsg.String( NAME ) 
		umsg.String( TEXT ) 
		umsg.Float( MAXIMUM ) 
	umsg.End()
end

function ASS_IncProgress( PLAYER, NAME, INC ) 
	umsg.Start("ASS_IncProgress", PLAYER)
		umsg.String( NAME ) 
		umsg.Float( INC || 1 ) 
	umsg.End()
end

function ASS_EndProgress( PLAYER, NAME ) 
	umsg.Start("ASS_EndProgress", PLAYER)
		umsg.String( NAME ) 
	umsg.End()
end

function ASS_Promote( PLAYER, UNIQUEID, NEWRANK, TIME )
	if (PLAYER:IsTempAdmin()) then
	
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
			ASS_MessagePlayer(PLAYER, "Access denied! Can't set temp admin to longer then " .. ASS_Config["MAX_TEMP_ADMIN_TIME"] .. " minutes")
			return			
		end

		TO_CHANGE:SetAssLevel( NEWRANK )
		
		if (NEWRANK == ASS_LVL_TEMPADMIN) then
			TO_CHANGE:SetTAExpiry( CurTime() + (TIME*60) )
			ASS_NamedCountdown( TO_CHANGE, "TempAdmin", "Temp Admin Expires in", TIME * 60 )	
		else
			TO_CHANGE:SetTAExpiry( 0 )
			ASS_RemoveCountdown( TO_CHANGE, "TempAdmin" )
		end
		
		ASS_LogAction( PLAYER, ASS_ACL_PROMOTE, action .. "d " .. ASS_FullNick(TO_CHANGE) .. " to " .. LevelToString(NEWRANK, tostring(TIME) .. " minutes") )
		ASS_MessagePlayer(TO_CHANGE, action .. "d to " .. LevelToString(NEWRANK, tostring(TIME) .. " minutes") )
		ASS_SaveRankings(TO_CHANGE:AssID())

	else
		ASS_MessagePlayer( PLAYER, "Access denied!")
	end
end

function ASS_UnBanPlayer( PLAYER, IS_IP, ID_OR_IP )
	if (PLAYER:IsTempAdmin()) then

		if (ASS_RunPluginFunction( "AllowPlayerUnBan", true, PLAYER, IS_IP, ID_OR_IP )) then
			if (IS_IP) then
				ASS_LogAction(PLAYER, ASS_ACL_BAN_KICK, "unbanned "..PlayerBans[ID_OR_IP].Name.."("..ID_OR_IP ..")")
			else
				ASS_LogAction(PLAYER, ASS_ACL_BAN_KICK, "unbanned "..PlayerBans[ID_OR_IP].Name.."("..PlayerBans[ID_OR_IP].SteamID..")")
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
	
	if (PLAYER:IsTempAdmin()) then
		local TO_BAN = ASS_FindPlayer(UNIQUEID)
		
		if (!TO_BAN) then	
			ASS_MessagePlayer(PLAYER, "Player not found!")
			return
		end

		if (TO_BAN:IsBetterOrSame(PLAYER)) then
			if PLAYER:IsValid() then
				ASS_MessagePlayer(PLAYER, "Access denied! \"" .. TO_KICK:Nick() .. "\" has same or better access then you.")
				return
			end
		end

		if ((TIME == 0 || TIME > tonumber(ASS_Config["max_temp_admin_ban_time"])) && !PLAYER:IsAdmin()) then					
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
			PlayerBans[TO_BAN:AssID()].SteamID = TO_BAN:SteamID()
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

	if (PLAYER:IsTempAdmin()) then
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

function ASS_DropClient(uid, reason, ply)
	if ply then
		game.ConsoleCommand("kickid"..ply:UserID().."You were kicked with reason: "..reason.."\n")
	else
		game.ConsoleCommand("kickid "..uid.." "..reason.."\n")
	end
end

function ASS_RconBegin( PLAYER )
	if (PLAYER:IsSuperAdmin()) then
		PLAYER.ASS_CurrentRcon = ""	
	else
		ASS_MessagePlayer( PLAYER, "Access denied!")
	end
end

function ASS_RconEnd( PLAYER, TIME )
	if (PLAYER:IsSuperAdmin()) then
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
	if (PLAYER:IsSuperAdmin() ) then
		for k,v in pairs(ARGS) do	
			PLAYER.ASS_CurrentRcon = PLAYER.ASS_CurrentRcon .. string.char(v)
		end		
	else	
		ASS_MessagePlayer( PLAYER, "Access denied!")
	end	
end

concommand.Add( "ASS_RconBegin",		
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
)
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
					ASS_SaveRankings(other:AssID())

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
	
gameevent.Listen("player_connect")
gameevent.Listen("player_disconnect")
hook.Add( "player_connect", "ASS_EventConnect", ASS_EventConnect)
hook.Add( "player_disconnect", "ASS_EventDisconnect", ASS_EventDisconnect)

hook.Add( "PlayerInitialSpawn", "ASS_PlayerInitialSpawn", ASS_PlayerInitialSpawn)
hook.Add( "PlayerDisconnected", "ASS_PlayerDisconnected", ASS_PlayerDisconnect)
hook.Add( "InitPostEntity", "ASS_InitPostEntity", ASS_InitPostEntity)
hook.Add( "PlayerSay", "ASS_PlayerSpeech", ASS_PlayerSpeech)
hook.Add( "Initialize", "ASS_Initialize", ASS_Initialize)
hook.Add( "Think", "ASS_Think", ASS_Think)

ASS_Init_Shared()