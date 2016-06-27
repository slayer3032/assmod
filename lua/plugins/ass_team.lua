
local PLUGIN = {}

PLUGIN.Name = "Set Team"
PLUGIN.Author = "Andy Vincent"
PLUGIN.Date = "10th August 2007"
PLUGIN.Filename = PLUGIN_FILENAME
PLUGIN.ClientSide = true
PLUGIN.ServerSide = true
PLUGIN.APIVersion = 2.3
PLUGIN.Gamemodes = {}

local Teams = nil

if (SERVER) then

	ASS_NewLogLevel("ASS_ACL_TEAM")
	
	function PLUGIN.SetTeam( PLAYER, CMD, ARGS )
		
		if !Teams or table.Count(Teams) < 0 then
			Teams = team.GetAllTeams()
		end

		if (PLAYER:HasAssLevel(ASS_LVL_TEMPADMIN)) then

			local TO_CHANGE = ASS_FindPlayer(ARGS[1])
			local TEAM = tonumber(ARGS[2]) or TEAM_UNASSIGNED

			if (!TO_CHANGE) then

				ASS_MessagePlayer(PLAYER, "Player not found!")
				return

			end

			if (ASS_RunPluginFunction( "AllowTeamChange", true, PLAYER, TO_CHANGE, TEAM )) then

				TO_CHANGE:SetTeam(TEAM)
				ASS_LogAction( PLAYER, ASS_ACL_TEAM, "changed " .. ASS_FullNick(TO_CHANGE) .. " to team " .. (Teams[TEAM] and Teams[TEAM].Name or TEAM) )
								
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
		
		if !Teams or table.Count(Teams) < 0 then
			Teams = team.GetAllTeams()
		end

		for k,v in pairs(Teams) do
			MENU:AddOption( v.Name, function() PLUGIN.SetTeam(PLAYER, k) end )
		end
	end

	function PLUGIN.AddMenu(DMENU)			
	
		DMENU:AddSubMenu( "Team", nil, function(NEWMENU) ASS_PlayerMenu(NEWMENU, {"IncludeAll", "HasSubMenu","IncludeLocalPlayer"}, PLUGIN.TeamChoice ) end ):SetImage( "icon16/group_edit.png" )

	end

end

ASS_RegisterPlugin(PLUGIN)

