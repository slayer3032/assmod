
local PLUGIN = {}

PLUGIN.Name = "Slap"
PLUGIN.Author = "Andy Vincent"
PLUGIN.Date = "10th August 2007"
PLUGIN.Filename = PLUGIN_FILENAME
PLUGIN.ClientSide = true
PLUGIN.ServerSide = true
PLUGIN.APIVersion = 2.3
PLUGIN.Gamemodes = {}

local POWER_TABLE = {

	{	Name = "Into Space",	VelocityMax = 100000, 	Damage = 0,	LogText = "into Space"		},	
	{	Name = "Deadly",	VelocityMax = 1000, 	Damage = 75,	LogText = "with deadly force"	},
	{	Name = "Super",		VelocityMax = 10000, 	Damage = 5,	LogText = "hard but fast"	},
	{	Name = "Hard",		VelocityMax = 500, 	Damage = 25,	LogText = "hard"		},
	{	Name = "Light",		VelocityMax = 200, 	Damage = 5,	LogText = "lightly"		},
	
}

local SLAP_SOUNDS = {
	"physics/body/body_medium_impact_hard1.wav",
	"physics/body/body_medium_impact_hard2.wav",
	"physics/body/body_medium_impact_hard3.wav",
	"physics/body/body_medium_impact_hard5.wav",
	"physics/body/body_medium_impact_hard6.wav",
	"physics/body/body_medium_impact_soft5.wav",
	"physics/body/body_medium_impact_soft6.wav",
	"physics/body/body_medium_impact_soft7.wav"
}

if (SERVER) then

	ASS_NewLogLevel("ASS_ACL_SLAP")

	function PLUGIN.SlapPlayer( PLAYER, CMD, ARGS )

		if (PLAYER:HasAssLevel(ASS_LVL_TEMPADMIN)) then

			local TO_SLAP = ASS_FindPlayer(ARGS[1])
			local POWER = tonumber(ARGS[2]) or 1
			local PT = POWER_TABLE[POWER]

			if (!TO_SLAP) then

				ASS_MessagePlayer(PLAYER, "Player not found!")
				return

			end
			
			if (TO_SLAP != PLAYER) then
				if (TO_SLAP:IsBetterOrSame(PLAYER)) then

					// disallow!
					ASS_MessagePlayer(PLAYER, "Access denied! \"" .. TO_SLAP:Nick() .. "\" has same or better access then you.")
					return
				end
			end

			if (ASS_RunPluginFunction( "AllowPlayerSlap", true, PLAYER, TO_SLAP )) then

				local RandomVelocity = Vector( math.random(PT.VelocityMax) - (PT.VelocityMax / 2 ), math.random(PT.VelocityMax) - (PT.VelocityMax / 2 ), math.random(PT.VelocityMax) - (PT.VelocityMax / 4 ) )
				local RandomSound = SLAP_SOUNDS[ math.random(#SLAP_SOUNDS) ]
				
				TO_SLAP:EmitSound( RandomSound )
				TO_SLAP:SetVelocity( RandomVelocity )
				TO_SLAP:Hurt( PT.Damage )

				ASS_LogAction( PLAYER, ASS_ACL_SLAP, "slapped " .. ASS_FullNick(TO_SLAP) .. " " .. PT.LogText  )
					
			end

		else

			ASS_MessagePlayer( PLAYER, "Access denied!")

		end
		
	end
	concommand.Add("ass_slapplayer", PLUGIN.SlapPlayer)

end

if (CLIENT) then

	function PLUGIN.SlapPlayer(PLAYER, POWER)

		if (type(PLAYER) == "table") then
			for _, ITEM in pairs(PLAYER) do
				if (IsValid(ITEM)) then
					RunConsoleCommand( "ASS_SlapPlayer", ITEM:AssID(), POWER )
				end
			end
		else
			if (!IsValid(PLAYER)) then return end

			RunConsoleCommand( "ASS_SlapPlayer", PLAYER:AssID(), POWER )
		end
		
		return true

	end
	
	function PLUGIN.SlapPower(MENU, PLAYER)

		for k,v in pairs(POWER_TABLE) do
			MENU:AddOption( v.Name,	function() return PLUGIN.SlapPlayer(PLAYER, k) end )
		end

	end
	
	function PLUGIN.AddMenu(DMENU)			
	
		DMENU:AddSubMenu( "Slap" , nil, function(NEWMENU) ASS_PlayerMenu( NEWMENU, {"IncludeAll", "HasSubMenu", "IncludeLocalPlayer"}, PLUGIN.SlapPower ) end ):SetImage( "icon16/wand.png" )

	end

end

ASS_RegisterPlugin(PLUGIN)


