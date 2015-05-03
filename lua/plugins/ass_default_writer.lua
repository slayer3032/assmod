//The Logs cleared amazingly fast so I bumped up the maximum size by 4 times

local PLUGIN = {}

PLUGIN.Name = "Default Writer"
PLUGIN.Author = "Andy Vincent, Slayer3032"
PLUGIN.Date = "09th August 2007" --"01st May 2015"
PLUGIN.Filename = PLUGIN_FILENAME
PLUGIN.ClientSide = false
PLUGIN.ServerSide = true
PLUGIN.APIVersion = 2.3
PLUGIN.Gamemodes = {}

function PLUGIN.AddToLog(PLAYER, ACL, ACTION)

	if (ASS_Config["writer"] != PLUGIN.Name) then return end
	
	local fn = "assmod/logs/" .. ACL .. ".txt"
	local log = ""
	
	if (file.Exists(fn, "DATA")) then
		log = file.Read(fn, "DATA")
		
		if (#log > 80000) then
			log = "Logs cleared!\n"
		end
	end
	
	log = log .. os.time() .. " - " .. ASS_FullNick(PLAYER) .. " -> " .. ACTION .. "\n"
	
	file.Write(fn, log)

end

function PLUGIN.LoadRankings(id)

	if (ASS_Config["writer"] != PLUGIN.Name) then return end
	if !id then return end
	if !file.Exists("assmod/users/"..id..".txt", "DATA") then return end

	local rt = ASS_GetRankingTable()
	local ranks = file.Read("assmod/users/"..id..".txt", "DATA")
	
	if (!ranks || ranks == "") then return end
	
	local ranktable = util.KeyValuesToTable(ranks)
	
	rt[id] = {}
	rt[id].Rank = ranktable.rank
	rt[id].Name = ranktable.name
	rt[id].PluginValues = ranktable.pluginpalues or {}
	
end

function PLUGIN.SaveRankings(id)

	if (ASS_Config["writer"] != PLUGIN.Name) then return end

	if id then
	
		local rt = ASS_GetRankingTable()
		local r = {}

		if (rt[id].Rank != ASS_LVL_GUEST || table.Count(rt[id].PluginValues) != 0) then
	
			r.Name = rt[id].Name
			r.Rank = rt[id].Rank
			r.SteamID = rt[id].SteamID
			r.PluginValues = {}
			for nm,val in pairs(rt[id].PluginValues) do
				r.PluginValues[nm] = tostring(val)
			end
			
			local rank = util.TableToKeyValues( r )
			file.Write("assmod/users/"..id..".txt", rank)
			
		end
	else -- save all, shouldn't really ever be used
			
		local rt = ASS_GetRankingTable()
		local r = {}
	
		for k,v in pairs(rt) do

			if (v.Rank != ASS_LVL_GUEST || table.Count(v.PluginValues) != 0) then
	
				r.Name = v.Name
				r.Rank = v.Rank
				r.SteamID = v.SteamID
				r.PluginValues = {}
				for nm,val in pairs(v.PluginValues) do
					r.PluginValues[nm] = tostring(val)
				end
			
				local rank = util.TableToKeyValues( r )
				file.Write("assmod/users/"..r.ID..".txt", rank)
				
			end
		end
	end
	
end

ASS_RegisterPlugin(PLUGIN)


