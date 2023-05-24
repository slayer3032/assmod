local PLUGIN = {}

PLUGIN.Name = "Default Logger"
PLUGIN.Author = "Slayer3032"
PLUGIN.Date = "23rd May 2023"
PLUGIN.Filename = PLUGIN_FILENAME
PLUGIN.ClientSide = false
PLUGIN.ServerSide = true
PLUGIN.APIVersion = 2.3
PLUGIN.Gamemodes = {}

function PLUGIN.AddToLog(PLAYER, ACL, ACTION)
	if (ASS_Config["logger"] != PLUGIN.Name) then return end
	
	local fn = "assmod/logs/"..ACL..".txt"
    local fno = "assmod/logs/archive/"..ACL.."_"..os.date("%m-%d-%Y")..".txt"
	local log = ""
	
	if (file.Exists(fn, "DATA")) then
		log = file.Read(fn, "DATA")
		
		if (#log > 80000) then
            file.Write(fno, log)
			log = "Logs cleared on "..os.date("%m-%d-%Y").."!\n"
		end
	end
	
	log = log .. os.date("%m/%d/%Y - %H:%M:%S" , os.time()) .. ": " .. ASS_FullNickLog(PLAYER) .. " -> " .. ACTION .. "\n"
	
	file.Write(fn, log)
end

ASS_RegisterPlugin(PLUGIN)


