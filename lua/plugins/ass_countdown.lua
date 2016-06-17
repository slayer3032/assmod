
local PLUGIN = {}

PLUGIN.Name = "Countdown"
PLUGIN.Author = "Andy Vincent"
PLUGIN.Date = "22nd August 2007"
PLUGIN.Filename = PLUGIN_FILENAME
PLUGIN.ClientSide = true
PLUGIN.ServerSide = true
PLUGIN.APIVersion = 2.3
PLUGIN.Gamemodes = {}

if (SERVER) then
	function PLUGIN.Countdown(name, text, time, pl) 
		if pl and !IsValid(pl) then return end
		net.Start('ass_countdown')
			net.WriteString(name)
			net.WriteString(text)
			net.WriteFloat(time)
		net.Send(pl or player.GetAll())
	end

	function PLUGIN.RemoveCountdown(name, pl) 
		if pl and !IsValid(pl) then return end
		net.Start('ass_removecountdown')
			net.WriteString(name)
		net.Send(pl or player.GetAll())
	end
end

if (CLIENT) then
	local CountDownPanel = nil

	function ASS_GetCountdownPanel()
		return CountDownPanel
	end

	local function Countdown( NAME, TEXT, DURATION ) 
		if (!CountDownPanel) then 	
			CountDownPanel = vgui.Create("DCountDownList")
			if (CountDownPanel) then
				CountDownPanel.CountDownPanel = CountDownPanel
			end
		end
		
		CountDownPanel:AddCountdown(NAME, TEXT, DURATION)
		
		if (CountDownPanel) then	
			CountDownPanel:InvalidateLayout()
		end
	end

	local function RemoveCountdown( NAME ) 
		if (!CountDownPanel) then 
			return 
		end
		
		CountDownPanel:RemoveCountdown( NAME )
		
		if (CountDownPanel) then	
			CountDownPanel:InvalidateLayout()
		end
	end

	net.Receive('ass_countdown', function()
		local name = net.ReadString()
		local text = net.ReadString()
		local time = net.ReadFloat()
		Countdown(name, text, time)
	end)

	net.Receive('ass_removecountdown', function()
		local name = net.ReadString()
		RemoveCountdown(name)
	end)
end

ASS_RegisterPlugin(PLUGIN)