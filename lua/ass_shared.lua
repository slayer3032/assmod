--If you don't understand that people are assigned these specific numbers as a rank and changing them won't change *them* automagicly, don't touch them.
--Feel free to jam whatever ranks, variables or whatever. This is meant for someone with an understanding of lua to be able to add ranks and with the pretences that many things are staticly scripted and the permissions for those things could be open to abuse.
--However, as long as you adjust ASS_LVL_TEMPADMIN as the base admin level and keep ASS_LVL_SERVER_OWNER as the highest rank you should be okay.

ASS_LVL_SERVER_OWNER	= 0
ASS_LVL_SUPER_ADMIN	= 1
ASS_LVL_ADMIN		= 2
ASS_LVL_TEMPADMIN	= 3
ASS_LVL_RESPECTED	= 4
ASS_LVL_GUEST		= 5 -- do not change variable name, this is your default rank
ASS_LVL_BANNED		= 255

ASS_RANKS = {}
ASS_RANKS[0] = {Name = "Server Owner", Icon = "icon16/lightning.png", SuperAdmin = true}
ASS_RANKS[1] = {Name = "Super Admin", Icon = "icon16/star.png", SuperAdmin = true}
ASS_RANKS[2] = {Name = "Admin", Icon = "icon16/shield.png", Admin = true}
ASS_RANKS[3] = {Name = "Temp Admin", Icon = "icon16/asterisk_yellow.png", TempAdmin = true}
ASS_RANKS[4] = {Name = "Respected", Icon = "icon16/award_star_gold_3.png", Respected = true}
ASS_RANKS[5] = {Name = "User", Icon = "icon16/user_gray.png"}
ASS_RANKS[255] = {Name = "Unwanted", Icon = "icon16/user_delete.png", Unwanted = true}

ASS_VERSION = "Assmod 2.4"

function ASS_Init_Shared()

	local PLAYER = FindMetaTable("Player")
	function PLAYER:IsSuperAdmin()	return self:GetNetworkedInt("ASS_isAdmin", ASS_LVL_GUEST) <= ASS_LVL_SUPER_ADMIN	end
	function PLAYER:IsAdmin()	return self:GetNetworkedInt("ASS_isAdmin", ASS_LVL_GUEST) <= ASS_LVL_ADMIN		end
	function PLAYER:IsTempAdmin()	return self:GetNetworkedInt("ASS_isAdmin", ASS_LVL_GUEST) <= ASS_LVL_TEMPADMIN	end
	function PLAYER:IsRespected()	return self:GetNetworkedInt("ASS_isAdmin", ASS_LVL_GUEST) <= ASS_LVL_RESPECTED	end

	function PLAYER:IsGuest()	return self:GetNetworkedInt("ASS_isAdmin", ASS_LVL_GUEST) >= ASS_LVL_GUEST && self:GetNetworkedInt("ASS_isAdmin", ASS_LVL_GUEST) < ASS_LVL_BANNED end
	function PLAYER:IsUnwanted()	return self:GetNetworkedInt("ASS_isAdmin", ASS_LVL_GUEST) >= ASS_LVL_BANNED end

	function PLAYER:GetAssLevel()		return self:GetNetworkedInt("ASS_isAdmin", ASS_LVL_GUEST)						end
	function PLAYER:HasAssLevel(n)		return self:GetNetworkedInt("ASS_isAdmin", ASS_LVL_GUEST) <= n						end
	function PLAYER:IsBetterOrSame(PL2)	if (!PL2:IsValid()) then return ASS_LVL_SERVER_OWNER <= self:GetNetworkedInt("ASS_isAdmin") else return self:GetNetworkedInt("ASS_isAdmin", ASS_LVL_GUEST) <= PL2:GetNetworkedInt("ASS_isAdmin", ASS_LVL_GUEST)	end end
	function PLAYER:GetTAExpiry(n)		return self:GetNetworkedFloat("ASS_tempAdminExpiry", 0)	end
	function PLAYER:AssID()		return self:GetNetworkedString("ASS_AssID")	end
	
	function PLAYER:IsBetterOrSame(PL2) if (!PL2:IsValid()) then return ASS_LVL_SERVER_OWNER <= self:GetNetworkedInt("ASS_isAdmin") else return self:GetNetworkedInt("ASS_isAdmin", 5) <= PL2:GetNetworkedInt("ASS_isAdmin", 5) end end
	
	PLAYER = nil

end

function IncludeSharedFile( S )
	
	if (SERVER) then
		AddCSLuaFile(S)
	end
	
	include(S)

end

function PCallError(...)
 	local arg = {...}

	local errored, retval = pcall(unpack(arg))
 
	if not errored then
		ErrorNoHalt(retval)
		return false, retval
	end

	return true, retval
end

function LevelToString( LEVEL, TIME )

	if TIME then
		return ASS_RANKS[LEVEL].Name.." for "..TIME
	else
		return ASS_RANKS[LEVEL].Name
	end
	
end

function ASS_FormatText( TEXT )

	if (CLIENT) then
		TEXT = string.Replace(TEXT, "%assmod%", ASS_VERSION )

		TEXT = string.Replace(TEXT, "%cl_time%", os.date("%H:%M:%S") )
		TEXT = string.Replace(TEXT, "%cl_date%",  os.date("%d/%b/%Y") )
		TEXT = string.Replace(TEXT, "%cl_timedate%", os.date("%H:%M:%S") .. " " ..  os.date("%d/%b/%Y") )

		TEXT = string.Replace(TEXT, "%sv_time%", GetGlobalString("ServerTime") )
		TEXT = string.Replace(TEXT, "%sv_date%", GetGlobalString("ServerDate") )
		TEXT = string.Replace(TEXT, "%sv_timedate%", GetGlobalString("ServerTime") .. " " .. GetGlobalString("ServerDate") )

		TEXT = string.Replace(TEXT, "%hostname%", GetGlobalString( "ServerName" ) )
		TEXT = string.gsub(TEXT, "%%%&([%w_]+)%%", GetConVarString)
	end
	if (SERVER) then
	
		TEXT = string.Replace(TEXT, "%map%", game.GetMap() )
		TEXT = string.Replace(TEXT, "%gamemode%", gmod.GetGamemode().Name )

		TEXT = string.gsub(TEXT, "%%@([%w_]+)%%", GetConVarString)
	
	end
	
	TEXT = ASS_RunPluginFunction("FormatText", TEXT, TEXT)


	return TEXT
	
end

--Functions Garry removed we should still be using..
function NullEntity()
	return NULL
end

--Overv's Serverside chat.AddText
if SERVER then
    chat = { }
    function chat.AddText( ... )
		local arg = {...}
        if ( type( arg[1] ) == "Player" ) then ply = arg[1] end
		if ply then if !ply:IsValid() then return end end
         
        umsg.Start( "AddText", ply )
            umsg.Short( #arg )
            for _, v in pairs( arg ) do
                if ( type( v ) == "string" ) then
                    umsg.String( v )
                elseif ( type ( v ) == "table" ) then
                    umsg.Short( v.r )
                    umsg.Short( v.g )
                    umsg.Short( v.b )
                    umsg.Short( v.a )
                end
            end
        umsg.End( )
    end
else
    usermessage.Hook( "AddText", function( um )
        local argc = um:ReadShort( )
        local args = { }
        for i = 1, argc / 2, 1 do
            table.insert( args, Color( um:ReadShort( ), um:ReadShort( ), um:ReadShort( ), um:ReadShort( ) ) )
            table.insert( args, um:ReadString( ) )
        end
         
        chat.AddText( unpack( args ) )
    end )
end

--temp dev update code
function player.GetBySteamID64( ID )
	ID = tostring( ID )

	for _, pl in pairs( player.GetAll() ) do
		if ( pl:SteamID64() == ID )	then
			return pl
		end
	end

	return false
end

IncludeSharedFile("ass_plugins.lua")
IncludeSharedFile("ass_debug.lua")
IncludeSharedFile("ass_config.lua")
