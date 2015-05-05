
local PLUGIN = {}

PLUGIN.Name = "Set Team"
PLUGIN.Author = "Andy Vincent"
PLUGIN.Date = "10th August 2007"
PLUGIN.Filename = PLUGIN_FILENAME
PLUGIN.ClientSide = true
PLUGIN.ServerSide = true
PLUGIN.APIVersion = 2.3
PLUGIN.Gamemodes = {}

local Teams = {}
Teams[TEAM_CONNECTING] 	= "Joining/Connecting"
Teams[TEAM_UNASSIGNED] 	= "Unassigned"
Teams[TEAM_SPECTATOR] 	= "Spectator"

if (SERVER) then

	ASS_NewLogLevel("ASS_ACL_TEAM")
	
	function PLUGIN.SetTeam( PLAYER, CMD, ARGS )

		if (PLAYER:HasAssLevel(ASS_LVL_TEMPADMIN)) then

			local TO_CHANGE = ASS_FindPlayer(ARGS[1])
			local TEAM = tonumber(ARGS[2]) or TEAM_UNASSIGNED

			if (!TO_CHANGE) then

				ASS_MessagePlayer(PLAYER, "Player not found!")
				return

			end

			if (ASS_RunPluginFunction( "AllowTeamChange", true, PLAYER, TO_CHANGE, TEAM )) then

				TO_CHANGE:SetTeam(TEAM)
				ASS_LogAction( PLAYER, ASS_ACL_TEAM, "changed " .. ASS_FullNick(TO_CHANGE) .. " to team " .. (Teams[TEAM] or TEAM) )
								
			end

		end

	end
	concommand.Add("ASS_SetTeam", PLUGIN.SetTeam)

end

if (CLIENT) then
	
	function PLUGIN.SetTeam(PLAYER, TEAM)
	
		if (type(PLAYER) == "table") then
			for _, ITEM in pairs(PLAYER) do
				if (IsValid(ITEM)) then
					RunConsoleCommand( "ASS_SetTeam", ITEM:AssID(), TEAM )
				end
			end
		else
			if (!IsValid(PLAYER)) then return end
			RunConsoleCommand( "ASS_SetTeam", PLAYER:AssID(), TEAM )
		end

	end
	
	function PLUGIN.TeamChoice(MENU, PLAYER)

		for k,v in pairs(Teams) do
			MENU:AddOption( v, function() PLUGIN.SetTeam(PLAYER, k) end )
		end
	end

	function PLUGIN.AddMenu(DMENU)			
	
		DMENU:AddSubMenu( "Set Team", nil, function(NEWMENU) ASS_PlayerMenu(NEWMENU, {"IncludeAll", "HasSubMenu","IncludeLocalPlayer"}, PLUGIN.TeamChoice ) end ):SetImage( "icon16/group_edit.png" )

	end

end

ASS_RegisterPlugin(PLUGIN)
	
// HACK: override the default team.SetUp so we can catch the Team setup that the gamemode uses.
local oldTeamSetup = team.SetUp
function team.SetUp( id, name, color )

	Teams[id] = name
	return oldTeamSetup(id, name, color)

end

