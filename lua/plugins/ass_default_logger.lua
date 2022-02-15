local PLUGIN = {}

PLUGIN.Name = "Default Logger"
PLUGIN.Author = "Slayer3032"
PLUGIN.Date = "01st May 2015"
PLUGIN.Filename = PLUGIN_FILENAME
PLUGIN.ClientSide = false
PLUGIN.ServerSide = true
PLUGIN.APIVersion = 2.3
PLUGIN.Gamemodes = {}

function PLUGIN.AddToLog(PLAYER, ACL, ACTION)
	if (ASS_Config["logger"] != PLUGIN.Name) then return end
	
	local fn = "assmod/logs/"..ACL..".txt"
    local fno = "assmod/logs/archive/"..ACL.."_"..os.date("%d-%m-%Y")..".txt"
	local log = ""
	
	if (file.Exists(fn, "DATA")) then
		log = file.Read(fn, "DATA")
		
		if (#log > 80000) then
            file.Write(fno, log)
			log = "Logs cleared on "..os.date("%d-%m-%Y").."!\n"
		end
	end
	
	log = log .. os.date("%d/%m/%Y - %H:%M:%S" , os.time()) .. ": " .. ASS_FullNickLog(PLAYER) .. " -> " .. ACTION .. "\n"
	
	file.Write(fn, log)
end

ASS_RegisterPlugin(PLUGIN)


