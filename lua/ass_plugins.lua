
local Plugins = {}

function ASS_NewLogLevel( ID, NAME )
	
	_G[ID] = NAME

end

function ASS_FindPlugin(NAME)
	for _,plugin in pairs(Plugins) do
		if (plugin.Name == NAME) then
			return plugin
		end
	end
	return nil
end

function ASS_AllPlugins(f)
	local t = {}
	for _, plugin in pairs(Plugins) do
		if (!f || (f && f(plugin))) then
			table.insert(t, plugin)
		end
	end
	return t
end

function ASS_RunPluginFunction( NAME, DEF_RETURN, ... )

	local arg = {...}

	for _,plugin in pairs(Plugins) do
	
		if (plugin[NAME]) then
		
			local err, ret = ASS_PCallError( plugin[NAME], unpack(arg) )
			
			if (ret != nil) then
			
				return ret
			
			end
		
		end
	
	end
	
	return DEF_RETURN

end

function ASS_RunPluginFunctionFiltered( NAME, FILTER_FUNC, DEF_RETURN, ... )

	local arg = {...}

	for _,plugin in pairs(Plugins) do
	
		if (plugin[NAME]) then
		
			if (FILTER_FUNC(plugin)) then
		
				local err, ret = ASS_PCallError( plugin[NAME], unpack(arg) )
			
				if (ret != nil) then
			
					return ret
			
				end
				
			end
		
		end
	
	end
	
	return DEF_RETURN

end

function ASS_PluginCheckGamemode( LIST )

	if (LIST == nil || #LIST == 0) then
		return true
	end

	for k,v in pairs(LIST) do
		local lv = string.lower(v)
		local gm = gmod.GetGamemode()
	
		while (gm) do
			if (string.lower(gm.Name) == lv) then
				return true
			end
		
			gm = gm.BaseClass
		end
	end
	
	return false

end

ASS_API_VERSION = 2.3

function ASS_RegisterPlugin( PLUGIN )

	if (!PLUGIN.APIVersion || PLUGIN.APIVersion != ASS_API_VERSION) then

		Msg( "ASS Plugin -> " .. PLUGIN.Filename .. " not registered (incorrect API version)\n" )
		ASS_Debug( "ASS Plugin -> " .. PLUGIN.Filename .. " not registered (incorrect API version)\n" )
		return
	
	end

	if (!ASS_PluginCheckGamemode(PLUGIN.Gamemodes)) then
	
		ASS_Debug( "ASS Plugin -> " .. PLUGIN.Filename .. " not registered (gamemode check failed)\n" )
		return
	
	end

	if (PLUGIN.ClientSide) then
		
		AddCSLuaFile(PLUGIN.Filename)
		
	end

	if ((PLUGIN.ClientSide && CLIENT) || (PLUGIN.ServerSide && SERVER)) then

		Msg("ASS Plugin -> " .. PLUGIN.Filename .. "\n")
		ASS_Debug( "ASS Plugin -> " .. PLUGIN.Filename .. " registered\n" )
		
		if (PLUGIN.Registered) then
			ASS_PCallError( PLUGIN.Registered )
		end

		table.insert( Plugins, PLUGIN )
		table.sort(Plugins, function(a, b)
			return tostring(a.Name) < tostring(b.Name)
		end);
		
	end
end

function ASS_LoadPlugins( DIR )

	DIR = DIR or "plugins"

	local luaFiles = file.Find(DIR .. "/*.lua", "LUA")

	for k,v in pairs(luaFiles) do
	
		PLUGIN_FILENAME = DIR .. "/" .. v
		
		if (file.IsDir(PLUGIN_FILENAME, "LUA")) then
		
			ASS_LoadPlugins( PLUGIN_FILENAME )
		
		else
		
			include( PLUGIN_FILENAME )
			
		end
		
	end

end

concommand.Add("ASS_SetBanlistPlugin",
	function(PL,CMD,ARGS)
		if (PL:HasAssLevel(ASS_LVL_SERVER_OWNER)) then
			local Name = ARGS[1] or "Default Banlist"
			local Plugin = ASS_FindPlugin(Name)

			if (!Plugin) then
				ASS_MessagePlayer(PL, "Plugin " .. Name .. " not found!");
				return
			end
			if (!Plugin.LoadBanlist || !Plugin.SaveBanlist || !Plugin.CheckPassword) then
				ASS_MessagePlayer(PL, "Plugin " .. Name .. " isn't a banlist plugin!");
				return
			end
			
			if (ASS_Config["banlist"] == Name) then
				ASS_MessagePlayer(PL, " banlist already set to " .. Name);
				return
			end

			ASS_Config["banlist"] = Name
			ASS_SaveBanlist()
			ASS_MessagePlayer(PL, "Banlist changed to " .. Name);
			ASS_WriteConfig()
			game.ConsoleCommand( "changelevel " .. game.GetMap() .. "\n" )
		else
			ASS_MessagePlayer(PL, "Access denied!");
		end
	end,
	function(CMD,ARGS)
		local f = ASS_AllPlugins(
				function(plugin) return plugin.SaveBanlist && plugin.LoadBanlist && plugin.CheckBanlist && plugin.RefreshBanlist && plugin.CheckPassword end
			)
		local res = {}
		for k,v in pairs(f) do
			table.insert(res, "ASS_SetBanlistPlugin \"" .. v.Name .. "\"")
		end
		table.insert(res, "dummy")
		return res
	end)
concommand.Add("ASS_SetWriterPlugin",
	function(PL,CMD,ARGS)
		if (PL:HasAssLevel(ASS_LVL_SERVER_OWNER)) then
			local Name = ARGS[1] or "Default Writer"
			local Plugin = ASS_FindPlugin(Name)

			if (!Plugin) then
				ASS_MessagePlayer(PL, "Plugin " .. Name .. " not found!");
				return
			end
			if (!Plugin.AddToLog || !Plugin.LoadPlayerRank || !Plugin.SavePlayerRank) then
				ASS_MessagePlayer(PL, "Plugin " .. Name .. " isn't a writer plugin!");
				return
			end
			
			if (ASS_Config["writer"] == Name) then
				ASS_MessagePlayer(PL, "Writer already set to " .. Name);
				return
			end

			ASS_Config["writer"] = Name
			ASS_MessagePlayer(PL, "Writer changed to " .. Name);
			ASS_WriteConfig()
			game.ConsoleCommand( "changelevel " .. game.GetMap() .. "\n" )
		else
			ASS_MessagePlayer(PL, "Access denied!");
		end
	end,
	function(CMD,ARGS)
		local f = ASS_AllPlugins(
				function(plugin) return plugin.AddToLog or plugin.LoadPlayerRank or plugin.SavePlayerRank end
			)
		local res = {}
		for k,v in pairs(f) do
			table.insert(res, "ASS_SetWriterPlugin \"" .. v.Name .. "\"")
		end
		table.insert(res, "dummy")
		return res
	end)
concommand.Add("ASS_SetLoggerPlugin",
	function(PL,CMD,ARGS)
		if (PL:HasAssLevel(ASS_LVL_SERVER_OWNER)) then
			local Name = ARGS[1] or "Default Logger"
			local Plugin = ASS_FindPlugin(Name)

			if (!Plugin) then
				ASS_MessagePlayer(PL, "Plugin " .. Name .. " not found!");
				return
			end
			if (!Plugin.AddToLog) then
				ASS_MessagePlayer(PL, "Plugin " .. Name .. " isn't a logger plugin!");
				return
			end
			
			if (ASS_Config["logger"] == Name) then
				ASS_MessagePlayer(PL, "Writer already set to " .. Name);
				return
			end

			ASS_Config["logger"] = Name
			ASS_MessagePlayer(PL, "Writer changed to " .. Name);
			ASS_WriteConfig()
			game.ConsoleCommand( "changelevel " .. game.GetMap() .. "\n" )
		else
			ASS_MessagePlayer(PL, "Access denied!");
		end
	end,
	function(CMD,ARGS)
		local f = ASS_AllPlugins(
				function(plugin) return plugin.AddToLog end
			)
		local res = {}
		for k,v in pairs(f) do
			table.insert(res, "ASS_SetWriterPlugin \"" .. v.Name .. "\"")
		end
		table.insert(res, "dummy")
		return res
	end)