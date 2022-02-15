

AddCSLuaFile("autorun/ass.lua")
AddCSLuaFile("ass_shared.lua")
AddCSLuaFile("ass_client.lua")

include("ass_von.lua")
include("ass_config_mysql.lua")
include("ass_shared.lua")
include("ass_res.lua")
include("ass_admin.lua")

// SERVER LOGGING STUFF

function ASS_NewLogLevel( ID )	_G[ ID ] = ID		end

ASS_NewLogLevel("ASS_ACL_JOIN_QUIT")
ASS_NewLogLevel("ASS_ACL_SPEECH")
ASS_NewLogLevel("ASS_ACL_BAN_KICK")
ASS_NewLogLevel("ASS_ACL_RCON")
ASS_NewLogLevel("ASS_ACL_SETLEVEL")
ASS_NewLogLevel("ASS_ACL_SETTING")
ASS_NewLogLevel("ASS_ACL_MESSAGE")

local ChatLogFilter = { ASS_ACL_SPEECH, ASS_ACL_KILL_SILENT, ASS_ACL_JOIN_QUIT }
local ConsoleFilter = { ASS_ACL_SPEECH = true, ASS_ACL_JOIN_QUIT = true }

// When a console command is run on a dedicated server, the PLAYER argument is a
// NULL ENTITY. We setup this meta table so that the IsAdmin etc commands still work
// and return the appropriate level.

local CONSOLE = FindMetaTable("Entity")
function CONSOLE:IsSuperAdmin()		if (!self:IsValid()) then return true else return false end end
function CONSOLE:IsAdmin()		if (!self:IsValid()) then return true else return false end end
function CONSOLE:GetAssLevel()		if (!self:IsValid()) then return ASS_LVL_SERVER_OWNER else return ASS_LVL_GUEST end end
function CONSOLE:HasAssLevel(n)		if (!self:IsValid()) then return ASS_LVL_SERVER_OWNER <= n else return ASS_LVL_GUEST <= n end end
function CONSOLE:IsBetterOrSame(PL2)	if (!self:IsValid()) then return ASS_LVL_SERVER_OWNER <= PL2:GetAssLevel() else return ASS_LVL_GUEST <= PL2:GetAssLevel() end end
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

function PLAYER:InitLevel(tbl)
	if !IsValid(self) then return end

	if tbl then
		self.ASSPluginValues = tbl.ASSPluginValues or {}
		self:SetAssLevel(tbl.Rank)
	else
		self.ASSPluginValues = {}
		self:SetAssLevel(ASS_LVL_GUEST)
	end
end

function PLAYER:SetAssLevel( RANK )	
	self.ASSRank = RANK
	self:SetNetworkedInt("ASS_Rank", RANK )
	
	if ASS_RANKS[RANK].UserGroup and !ASS_NoUserGroups then
		self:SetUserGroup(ASS_RANKS[RANK].UserGroup)
	end
	
	if (RANK == ASS_LVL_TEMPADMIN) then
		if self.ASSPluginValues["ass_server"] then
			if self.ASSPluginValues["ass_server"]["ta_expiry"] and self.ASSPluginValues["ass_server"]["ta_expiry"] > 0 then
				self:SetNetworkedFloat("ASS_tempAdminExpiry", self.ASSPluginValues["ass_server"]["ta_expiry"] or 0)
				ASS_RunPluginFunction("Countdown", nil, "TempAdmin", "Temp Admin Expires in", self.ASSPluginValues["ass_server"]["ta_expiry"]-os.time(), self)
			end
		end
	end
	
	ASS_Debug( self:Nick() .. " given level " .. self:GetAssLevel() .. "\n")
	ASS_RunPluginFunction("RankingChanged", nil, self , RANK)
end

function PLAYER:SetAssAttribute(NAME, VALUE)
	if (type(NAME) != "string") then Msg("SetAssAttribute error - Name invalid\n") return end
	if (type(VALUE) != "string" && type(VALUE) != "number" && type(VALUE) != "boolean" && type(VALUE) != "nil") then Msg("SetAssAttribute error - Value invalid\n") return end
	
	NAME = string.lower(NAME)
	PLUGIN = string.match(debug.getinfo(1,"S").short_src, "[/]?([^/]+)$-[%.]")
	
	if (!self:GetAssLevel()) then
		self:SetAssLevel(ASS_LVL_GUEST)
	end
	if (!self.ASSPluginValues) then
		self.ASSPluginValues = {}
	end
	if (!self.ASSPluginValues[PLUGIN]) then
		self.ASSPluginValues[PLUGIN] = {}
	end
	self.ASSPluginValues[PLUGIN][NAME] = VALUE
	
	ASS_RunPluginFunction("SavePlayerRank", nil, self)
end

function PLAYER:GetAssAttribute(NAME, TYPE, DEFAULT)
	if (type(NAME) != "string") then  Msg("SetAssAttribute error - Name invalid\n") return DEFAULT end
	
	local convertFunc = nil
	if (TYPE == "string") then	convertFunc = tostring
	elseif (TYPE == "number") then	convertFunc = tonumber
	elseif (TYPE == "boolean") then	convertFunc = tobool
	else
		Msg("SetAssAttribute error - Type invalid\n")
		return DEFAULT
	end

	NAME = string.lower(NAME)
	PLUGIN = string.match(debug.getinfo(1,"S").short_src, "[/]?([^/]+)$-[%.]")
	
	if (!self.ASSPluginValues) then
		return convertFunc(DEFAULT)
	end
	if (!self.ASSPluginValues[PLUGIN]) then
		return convertFunc(DEFAULT)
	end
	if (self.ASSPluginValues[PLUGIN][NAME] == nil) then
		return convertFunc(DEFAULT)
	end
	
	local result = convertFunc(self.ASSPluginValues[PLUGIN][NAME])
	if (result == nil) then
		return convertFunc(DEFAULT)
	else
		return result	
	end
end

function PLAYER:SetTAExpiry(TIME)
	self:SetAssAttribute("ta_expiry", TIME)
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

function ASS_Initialize()
	ASS_InitResources()
	ASS_LoadPlugins()
	
	util.AddNetworkString('ass_rcon')
	util.AddNetworkString('ass_kickplayer')
	util.AddNetworkString('ass_banplayer')
	util.AddNetworkString('ass_unbanplayer')
	util.AddNetworkString('ass_unbanlist')
	util.AddNetworkString('ass_setlevel')
	util.AddNetworkString('ass_clienttell')
	util.AddNetworkString('ass_initialize')
	util.AddNetworkString('ass_countdown')
	util.AddNetworkString('ass_removecountdown')
end

local NextAssThink = 0

function ASS_Think()
	if (CurTime() >= NextAssThink) then
		for _, ply in pairs( player.GetAll() ) do
			if ply:GetAssLevel() == ASS_LVL_TEMPADMIN then
				if (os.time() >= ply:GetTAExpiry() && ply:GetTAExpiry() != 0) then
					ASS_LogAction(ply, ASS_ACL_SETLEVEL, "Temp admin expired. Demoted to respected user.")
					ply:SetAssLevel( ASS_LVL_RESPECTED )
					ASS_RunPluginFunction("RemoveCountdown", nil, "TempAdmin", ply)
					ASS_RunPluginFunction("SavePlayerRank", nil, ply)
				end
			end
		end

		NextAssThink = CurTime() + 1
	end
end

function ASS_PlayerInitialSpawn( PLAYER )
	net.Start('ass_initialize') net.Send(PLAYER)
	PLAYER.ASSPluginValues = PLAYER.ASSPluginValues or {}
	PLAYER.ASSRank = PLAYER.ASSRank or ASS_LVL_GUEST
	
	if PLAYER:IsListenServerHost() then	
		PLAYER:SetAssLevel(ASS_LVL_SERVER_OWNER)
		ASS_RunPluginFunction("SavePlayerRank", nil, PLAYER)	
	end
end

function ASS_PlayerAuthed(ply, sid)
	if ply.SlowAuth then
		ASS_MessagePlayer(ply, 'Assmod: Your profile has been loaded, steamauth was slow today...')
	end
	ASS_RunPluginFunction("LoadPlayerRank", nil, ply)
end

function ASS_EventConnect( TBL )
	ASS_TellPlayers(TBL.name, ASS_ACL_MESSAGE, "joined the server")
	ASS_LogAction("\'"..TBL.name.."\' ("..TBL.networkid.." | "..util.SteamIDTo64(TBL.networkid).." | " .. TBL.address .. ")", ASS_ACL_JOIN_QUIT, " connected")
	ASS_RunPluginFunction("PlayerConnect", nil, TBL)	
end

function ASS_EventDisconnect( TBL )
	ASS_TellPlayers(TBL.name, ASS_ACL_MESSAGE, "left the server")
	ASS_LogAction("\'"..TBL.name.."\' ("..TBL.networkid.." | "..util.SteamIDTo64(TBL.networkid)..")", ASS_ACL_JOIN_QUIT, " disconnected (Reason: "..TBL.reason..")")
	ASS_RunPluginFunction("PlayerDisonnect", nil, TBL)	
end

function ASS_PlayerSpeech( PLAYER, TEXT, TEAMSPEAK )
	if (TEAMSPEAK) then
		ASS_LogAction( PLAYER, ASS_ACL_SPEECH, "said \"" .. TEXT .. "\" to his team" )
	else
		ASS_LogAction( PLAYER, ASS_ACL_SPEECH, "said \"" .. TEXT .. "\"" )
	end
end

function ASS_LogAction( PLAYER, ACL, ACTION )
	if !ConsoleFilter[ACL] then
		if type(PLAYER) == "string" then
			Msg( PLAYER .. " -> " .. ACTION .. "\n")
		else
			Msg( PLAYER:Nick() .. " -> " .. ACTION .. "\n")
		end
    end
	
	ASS_TellPlayers(PLAYER, ACL, ACTION)
	ASS_RunPluginFunction("AddToLog", nil, PLAYER, ACL, ACTION)
end

function ASS_FullNick( PLAYER )	
	if type(PLAYER) == "string" then return PLAYER end
	return "\"" .. PLAYER:Nick() .. "\" (" .. PLAYER:SteamID() .. " | " .. ASS_LevelToString(PLAYER:GetAssLevel()) .. ")"
end

function ASS_FullNickLog( PLAYER )
	if type(PLAYER) == "string" then return PLAYER end
	return "\'" .. PLAYER:Nick() .. "\' (" .. PLAYER:SteamID() .. " | "..PLAYER:SteamID64().." | " .. PLAYER:IPAddress() .. ")"
end

function ASS_MessagePlayer( PLAYER, MESSAGE )
	chat.AddText(PLAYER, Color(0, 229, 238), MESSAGE)
end

function ASS_TellPlayers( PLAYER, ACL, ACTION, BYPASS)
	for k,v in pairs(ChatLogFilter) do if (v == ACL) then return end end

	if (ASS_Config["tell_admins_what_happened"] and ASS_Config["tell_clients_what_happened"]) then
		for _, pl in pairs(player.GetAll()) do
			chat.AddText(pl, Color(0, 255, 0), (type(PLAYER) == "string" and PLAYER) or PLAYER:Nick(), Color(255, 255, 255), " "..ACTION)
		end
	else
		for _, pl in pairs(player.GetAll()) do
			if pl:HasAssLevel(ASS_LVL_TEMPADMIN) or BYPASS then
				chat.AddText(pl, Color(0, 255, 0), (type(PLAYER) == "string" and PLAYER) or PLAYER:Nick(), Color(255, 255, 255), " "..ACTION)
			end
		end
	end	
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
	
	return nil
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

function ASS_DropClient(uid, reason, ply)
	if ply then
		game.KickID(ply:UserID(), reason)
	else
		game.KickID(uid, reason)
	end
end
	
net.Receive('ass_initialize', function(len, pl)
	ASS_RunPluginFunction("PlayerInitialized", nil, pl)
	if !pl:IsFullyAuthenticated() then
		ASS_MessagePlayer(pl, 'Assmod: Your profile is loading, waiting for steamauth...')
		pl.SlowAuth = true
	end
	net.Start('ass_clienttell')
		net.WriteBool(ASS_Config["tell_clients_what_happened"])
	net.Send(pl)
end)
	
gameevent.Listen("player_connect")
gameevent.Listen("player_disconnect")
hook.Add( "player_connect", "ASS_EventConnect", ASS_EventConnect)
hook.Add( "player_disconnect", "ASS_EventDisconnect", ASS_EventDisconnect)

hook.Add( "PlayerInitialSpawn", "ASS_PlayerInitialSpawn", ASS_PlayerInitialSpawn)
hook.Add( "PlayerAuthed", "ASS_PlayerAuthed", ASS_PlayerAuthed)
hook.Add( "Initialize", "ASS_Initialize", ASS_Initialize)
hook.Add( "Think", "ASS_Think", ASS_Think)
hook.Add( "PlayerSay", "ASS_PlayerSpeech", ASS_PlayerSpeech)

ASS_Init_Shared()
