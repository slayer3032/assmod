
local PLUGIN = {}

PLUGIN.Name = "Admin Speech"
PLUGIN.Author = "Andy Vincent"
PLUGIN.Date = "09th August 2007"
PLUGIN.Filename = PLUGIN_FILENAME
PLUGIN.ClientSide = true
PLUGIN.ServerSide = true
PLUGIN.APIVersion = 2.3
PLUGIN.Gamemodes = {}

if (SERVER) then
	function ASS_AdminSpeech( PLAYER, TEXT, TEAMSPEAK )
		local prefix = ASS_Config["admin_speak_prefix"]
	
		if (!prefix || prefix == "") then
			prefix = "@"
		end
	
		local prefixlen = #prefix

		if (PLAYER:HasAssLevel(ASS_LVL_TEMPADMIN) && string.sub(TEXT, 1, prefixlen) == prefix) then
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
	
	hook.Add( "PlayerSay", "ASS_AdminSpeech", ASS_AdminSpeech)
end

ASS_RegisterPlugin(PLUGIN)
