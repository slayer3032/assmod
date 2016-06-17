
local PLUGIN = {}

PLUGIN.Name = "Map"
PLUGIN.Author = "Andy Vincent"
PLUGIN.Date = "10th August 2007"
PLUGIN.Filename = PLUGIN_FILENAME
PLUGIN.ClientSide = true
PLUGIN.ServerSide = true
PLUGIN.APIVersion = 2.3
PLUGIN.Gamemodes = {}

if (SERVER) then

	ASS_NewLogLevel("ASS_ACL_MAP")

	util.AddNetworkString('ass_maplist')
	util.AddNetworkString('ass_mapchange')
	util.AddNetworkString('ass_mapabort')

	function PLUGIN.RefreshMapList(PLAYER)
		allMaps = file.Find("maps/*.bsp", "GAME")
		for k,v in pairs(allMaps) do
			allMaps[k] = string.gsub(string.lower( v ), ".bsp", "")
		end
		table.sort(allMaps, function(a,b) return a < b end )
		
		net.Start('ass_maplist')
			net.WriteTable(allMaps)
		net.Send(PLAYER)
	end
	concommand.Add("ASS_RefreshMapList", PLUGIN.RefreshMapList)
	
	function PLUGIN.PlayerInitialized(PLAYER)
		PLUGIN.RefreshMapList(PLAYER)
	end

	function PLUGIN.DoChangeMap( PLAYER, MAP )
		if (PLAYER:IsValid()) then
			ASS_LogAction( PLAYER, ASS_ACL_MAP, "changed map to " .. MAP )
		end
		
		game.ConsoleCommand( "changelevel " .. MAP .. "\n" )
	end

	function PLUGIN.ChangeMap( PLAYER, MAP, TIME )
		if (PLAYER:HasAssLevel(ASS_LVL_TEMPADMIN)) then

			if (ASS_RunPluginFunction( "AllowMapChange", true, MAP, TIME )) then
				if !TIME then TIME = 0 end
				if (TIME == 0) then
					PLUGIN.DoChangeMap( PLAYER, MAP )				
				else			
					ASS_LogAction( PLAYER, ASS_ACL_MAP, "scheduled a map change to " .. MAP .. " in " .. TIME .. " seconds" )
					
					ASS_RunPluginFunction("Countdown", nil, "MapChange", "Map change to " .. MAP, TIME)
					
					timer.Create( "ASS_MapChange", TIME, 1, function() PLUGIN.DoChangeMap(PLAYER, MAP) end )			
				end
			end
		end
	end
	net.Receive('ass_mapchange',function(len, pl) PLUGIN.ChangeMap(pl, net.ReadString(), net.ReadUInt(16)) end)
	
	function PLUGIN.RestartMap(pl)
		PLUGIN.ChangeMap(pl, game.GetMap(), 0)
	end
	concommand.Add("ass_restartmap", PLUGIN.RestartMap)
			
	function PLUGIN.AbortChangeMap( PLAYER )
		if (PLAYER:HasAssLevel(ASS_LVL_TEMPADMIN)) then		
			timer.Remove( "ASS_MapChange" )
			ASS_LogAction( PLAYER, ASS_ACL_MAP, "aborted the map change" )
			ASS_RunPluginFunction("RemoveCountdown", nil, "MapChange")	
		end
	end
	net.Receive('ass_mapabort',function(len, pl) PLUGIN.AbortChangeMap(pl) end)

end

if (CLIENT) then
	allMaps = {}
	local maplistLoaded = false
	local numToLoad = 0
	local currentMap = game.GetMap()
	
	function PLUGIN.AddToFavourites(MAP)
		if (!MAP) then return end
		
		local LMAP = string.lower(MAP)
		ASS_Config["maps"] = ASS_Config["maps"] || {}
		for k,v in pairs(ASS_Config["maps"]) do
			if (LMAP == string.lower(v)) then
				table.remove(ASS_Config["maps"], k)
				break
			end
		end
		
		table.insert(ASS_Config["maps"], LMAP)
		if (#ASS_Config["maps"] > 10) then
			table.remove(ASS_Config["maps"], 1)
		end
		
		ASS_WriteConfig()
	end
	
	function PLUGIN.ChangeMap(MAP, TIME)	
		if (MAP == nil || type(MAP) == "string") then
		
			if (MAP == nil) then	
				net.Start('ass_mapchange')
					net.WriteString(game.GetMap())
					net.WriteUInt(TIME or 0,16)
				net.SendToServer()
				PLUGIN.AddToFavourites(currentMap)
			else
				net.Start('ass_mapchange')
					net.WriteString(MAP)
					net.WriteUInt(TIME or 0,16)
				net.SendToServer()
				PLUGIN.AddToFavourites(MAP)
			end
		else
			PromptStringRequest( "Map...", 
				"Which map do you want to switch to?", 
				currentMap, 
				function( strTextOut ) 
					net.Start('ass_mapchange')
						net.WriteString(strTextOut)
						net.WriteUInt(TIME or 0,16)
					net.SendToServer() 
					PLUGIN.AddToFavourites(strTextOut)
				end 
			)
		end

		return true
	end
	
	function PLUGIN.TimeMenu(MENU, MAP)
		MENU:AddOption( "Now", 		function() PLUGIN.ChangeMap(MAP, 0) end 	)
		MENU:AddSpacer()
		MENU:AddOption( "30 seconds",	function() PLUGIN.ChangeMap(MAP, 30) end 	)
		MENU:AddOption( "1 minute",	function() PLUGIN.ChangeMap(MAP, 60) end	)
		MENU:AddOption( "3 minutes",	function() PLUGIN.ChangeMap(MAP, 3 * 60) end	)
		MENU:AddOption( "5 minutes",	function() PLUGIN.ChangeMap(MAP, 5 * 60) end	)
		MENU:AddOption( "15 minutes",	function() PLUGIN.ChangeMap(MAP, 15 * 60) end	)
		MENU:AddOption( "30 minutes",	function() PLUGIN.ChangeMap(MAP, 30 * 60) end	)
		MENU:AddOption( "1 hour",	function() PLUGIN.ChangeMap(MAP, 60 * 60) end	)
	end
	
	MAPS_PER_MENU = 30
	
	function PLUGIN.BlockMenu(MENU, BLOCK)
		for k,v in pairs(BLOCK) do
			MENU:AddSubMenu( v, nil, function(NEWMENU) PLUGIN.TimeMenu(NEWMENU, v ) end )
		end
	end

	function PLUGIN.FavouritesMenu(MENU)
		if (ASS_Config["maps"] == nil || #ASS_Config["maps"] == 0) then
			MENU:AddOption( "(none)", function() end )
		else
			PLUGIN.BlockMenu(MENU,ASS_Config["maps"])
		end
	end
	
	function PLUGIN.MapMenu(MENU)
		if (!maplistLoaded) then
			MENU:AddOption("Not loaded (" .. math.floor((#allMaps / numToLoad) * 100) .. "%)", function() end )
			return
		end
	
		local current = {}
		local blocks = {}
		for k,v in pairs(allMaps) do
			table.insert(current, v)
			
			if (#current > MAPS_PER_MENU) then
				table.insert(blocks, current)
				current = {}
			end
		end
		if (#current > 0) then
			table.insert(blocks, current)
		end
		
		MENU:AddSubMenu( "Current (".. currentMap..")", nil, function(NEWMENU) PLUGIN.TimeMenu( NEWMENU, nil ) end )
		MENU:AddSubMenu( "Custom" , nil, function(NEWMENU) PLUGIN.TimeMenu(NEWMENU, true ) end )
		MENU:AddSubMenu( "Favourites" , nil, function(NEWMENU) PLUGIN.FavouritesMenu(NEWMENU) end )
		MENU:AddSpacer()
		
		if (#blocks == 1) then
			PLUGIN.BlockMenu(MENU, blocks[1], true)	
		else
			for k, v in pairs(blocks) do
				local first = ((k - 1) * MAPS_PER_MENU) + 1
				local last = (k * MAPS_PER_MENU)
				MENU:AddSubMenu( first .. " .. " .. last, nil, function(NEWMENU) PLUGIN.BlockMenu( NEWMENU, v, false) end )
			end
		end
		
		return false
	end

	function PLUGIN.AbortMapChange(MENUITEM)
		net.Start('ass_mapabort') net.SendToServer()
		return true
	end
	
	function PLUGIN.AddMainMenu(DMENU)			
		DMENU:AddSpacer()
		DMENU:AddSubMenu( "Change Map", nil, PLUGIN.MapMenu ):SetImage( "icon16/map_go.png" )
		DMENU:AddOption( "Abort Change Map", PLUGIN.AbortMapChange ):SetImage( "icon16/map_delete.png" )
	end

	net.Receive('ass_maplist', function()
		allMaps = net.ReadTable()
		maplistLoaded = true
	end)
end

ASS_RegisterPlugin(PLUGIN)
