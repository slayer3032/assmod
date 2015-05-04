

AddCSLuaFile("autorun/ass.lua")
AddCSLuaFile("ass_shared.lua")
AddCSLuaFile("ass_client.lua")

include("ass_shared.lua")
include("ass_res.lua")
include("ass_notice.lua")
include("ass_admin.lua")

// SERVER LOGGING STUFF

function ASS_NewLogLevel( ID )	_G[ ID ] = ID		end

ASS_NewLogLevel("ASS_ACL_JOIN_QUIT")
ASS_NewLogLevel("ASS_ACL_SPEECH")
ASS_NewLogLevel("ASS_ACL_BAN_KICK")
ASS_NewLogLevel("ASS_ACL_RCON")
ASS_NewLogLevel("ASS_ACL_PROMOTE")
ASS_NewLogLevel("ASS_ACL_ADMINSPEECH")
ASS_NewLogLevel("ASS_ACL_SETTING")

local PlayerRankings = {}
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

function PLAYER:InitLevel()	
	local tbl = ASS_RunPluginFunction("LoadPlayerRank", tbl, self)
	
	if tbl then
		self.ASSPluginValues = self.ASSPluginValues or {}
		self:SetAssLevel(tbl.Rank)
	else
		self.ASSPluginValues = {}
		self:SetAssLevel(ASS_LVL_GUEST)
	end
end

function PLAYER:GetAssLevel()
	return self.ASSRank or ASS_LVL_GUEST
end

function PLAYER:SetAssLevel( RANK )	
	self.ASSRank = RANK
	self:SetNetworkedInt("ASS_isAdmin", RANK )
	
	if (RANK == ASS_LVL_TEMPADMIN) then
		self:SetNetworkedFloat("ASS_tempAdminExpiry", self.ASSPluginValues["ta_expiry"] or 0)
	elseif self.ASSPluginValues["ta_expiry"] then
		self.ASSPluginValues["ta_expiry"] = nil
	end
	
	ASS_Debug( self:Nick() .. " given level " .. self:GetAssLevel() .. "\n")
	ASS_RunPluginFunction( "RankingChanged", nil, self )
end

function PLAYER:SetAssAttribute(NAME, VALUE)
	if (type(NAME) != "string") then Msg("SetAssAttribute error - Name invalid\n") return end
	if (type(VALUE) != "string" && type(VALUE) != "number" && type(VALUE) != "boolean" && type(VALUE) != "nil") then Msg("SetAssAttribute error - Value invalid\n") return end
	
	NAME = string.lower(NAME)
	
	self:InitLevel()  -- prevent multi-instance servers overwriting
	
	if (!self:GetAssLevel()) then
		self:SetAssLevel(ASS_LVL_GUEST)
	end
	if (!self.ASSPluginValues) then
		self.ASSPluginValues = {}
	end
	self.ASSPluginValues[NAME] = VALUE
	
	ASS_RunPluginFunction("SavePlayerRank", nil, self)
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
	
	self:InitLevel()  -- prevent multi-instance servers overwriting
	
	if (!self.ASSPluginValues) then
		return convertFunc(DEFAULT)
	end
	if (!self.ASSPluginValues[NAME] == nil) then
		return convertFunc(DEFAULT)
	end
	
	local result = convertFunc(self.ASSPluginValues[NAME])
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
	ASS_LoadBanlist()
	
	for k,v in pairs(ASS_Config["fixed_notices"]) do
		ASS_AddNamedNotice( ASS_GenerateFixedNoticeName(v.text, v.duration), v.text or "", tonumber(v.duration) or 10)
	end
end

function ASS_InitPostEntity()
	SetGlobalInt( "ASS_ClientTell", ASS_Config["tell_clients_what_happened"] or 1 )
end

local NextAssThink = 0

function ASS_Think()
	if (CurTime() >= NextAssThink) then
		for _, ply in pairs( player.GetAll() ) do
			if ply:GetAssLevel() == ASS_LVL_TEMPADMIN then
				if (os.time() >= ply:GetTAExpiry() && ply:GetTAExpiry() != 0) then
					ASS_LogAction(ply, ASS_ACL_PROMOTE, "Temp admin expired. Demoted to respected user.")

					ply:SetAssLevel( ASS_LVL_RESPECTED )
					ASS_RemoveCountdown( ply, "TempAdmin" )

					ASS_RunPluginFunction("SavePlayerRank", nil, ply)
				end
			end
		end
	
		if #ASS_GetActiveNotices() > 0 then
			SetGlobalString( "ServerTime", os.date("%H:%M:%S") )
			SetGlobalString( "ServerDate", os.date("%d/%b/%Y") )	
		end
		NextAssThink = CurTime() + 1
	end
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
		ASS_RunPluginFunction("SavePlayerRank", nil, PLAYER)	
	else	
		PLAYER:InitLevel()	
	end
	
	for k,v in pairs(ASS_GetActiveNotices()) do
		ASS_SendNotice(PLAYER, v.Name, v.Text, v.Duration)
	end
	
	if (#player.GetAll() <= 2 && !PLAYER:IsTempAdmin() && util.tobool(ASS_Config["demomode"]) ) then
		local TempAdminTime = (tonumber(ASS_Config["demomode_ta_time"]) or 1) *60 
		PLAYER:SetAssLevel( ASS_LVL_TEMPADMIN )
		PLAYER:SetTAExpiry( os.time() + TempAdminTime )

		ASS_NamedCountdown( PLAYER, "TempAdmin", "Temp Admin Expires in", TempAdminTime )
		ASS_RunPluginFunction("SavePlayerRank", nil, PLAYER)

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

function ASS_LogAction( PLAYER, ACL, ACTION )
	Msg( PLAYER:Nick() .. " -> " .. ACTION .. "\n")
	ASS_TellPlayers(PLAYER, ACL, ACTION)
	ASS_RunPluginFunction("AddToLog", nil, PLAYER, ACL, ACTION)
end

function ASS_MessagePlayer( PLAYER, MESSAGE )
	chat.AddText(PLAYER, Color(0, 229, 238), MESSAGE)
end

function ASS_FullNick( PLAYER )		return "\"" .. PLAYER:Nick() .. "\" (" .. PLAYER:SteamID() .. " | " .. LevelToString(PLAYER:GetAssLevel()) .. ")"		end
function ASS_FullNickLog( PLAYER )		return "\"" .. PLAYER:Nick() .. "\" (" .. PLAYER:SteamID() .. " | " .. PLAYER:IPAddress() .. ")"		end

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

function ASS_DropClient(uid, reason, ply)
	if ply then
		game.ConsoleCommand("kickid"..ply:UserID().."You were kicked with reason: "..reason.."\n")
	else
		game.ConsoleCommand("kickid "..uid.." "..reason.."\n")
	end
end

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