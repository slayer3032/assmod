
local PLUGIN = {}

PLUGIN.Name = "Notice"
PLUGIN.Author = "Andy Vincent"
PLUGIN.Date = "22nd August 2007"
PLUGIN.Filename = PLUGIN_FILENAME
PLUGIN.ClientSide = true
PLUGIN.ServerSide = true
PLUGIN.APIVersion = 2.3
PLUGIN.Gamemodes = {}

function ASS_FormatText( TEXT )
	if (CLIENT) then
		TEXT = string.Replace(TEXT, "%assmod%", ASS_VERSION )

		TEXT = string.Replace(TEXT, "%cl_time%", os.date("%H:%M:%S") )
		TEXT = string.Replace(TEXT, "%cl_date%",  os.date("%d/%b/%Y") )
		TEXT = string.Replace(TEXT, "%cl_timedate%", os.date("%H:%M:%S") .. " " ..  os.date("%d/%b/%Y") )

		TEXT = string.Replace(TEXT, "%sv_time%", GetGlobalString("ServerTime") )
		TEXT = string.Replace(TEXT, "%sv_date%", GetGlobalString("ServerDate") )
		TEXT = string.Replace(TEXT, "%sv_timedate%", GetGlobalString("ServerTime") .. " " .. GetGlobalString("ServerDate") )

		TEXT = string.Replace(TEXT, "%hostname%", GetGlobalString( "ServerName" ) )
		TEXT = string.gsub(TEXT, "%%%&([%w_]+)%%", GetConVarString)
	end
	if (SERVER) then
		TEXT = string.Replace(TEXT, "%map%", game.GetMap() )
		TEXT = string.Replace(TEXT, "%gamemode%", gmod.GetGamemode().Name )

		TEXT = string.gsub(TEXT, "%%@([%w_]+)%%", GetConVarString)
	end
	
	TEXT = ASS_RunPluginFunction("FormatText", TEXT, TEXT)

	return TEXT
end

function PLUGIN.Registered()
	if !ASS_Config["fixed_notices"] then
		ASS_Config["fixed_notices"] = {
			{	duration = 10,		text = "Welcome to %hostname%. Please play nice!"			},
			{	duration = 10,		text = "Running %gamemode% on %map%"					},
			{	duration = 10,		text = "%assmod% - If you're an admin, bind a key to +ass_menu"		},
		}
	end
end

if (SERVER) then
	ASS_NewLogLevel("ASS_ACL_NOTICE")

	local ActiveNotices = {}

	function ASS_GetActiveNotices()
		return ActiveNotices
	end

	function ASS_SendNoticesRaw( PLAYER )
		for k,v in pairs(ActiveNotices) do
			umsg.Start("ASS_RawNotice", PLAYER)
				umsg.String( v.Name ) 
		  		umsg.String( v.Text ) 
		 		umsg.Float( v.Duration ) 
			umsg.End()
		end
	end

	function ASS_SendNotice( PLAYER, NAME, TEXT, DURATION )
		ASS_Debug("Sending notice \"" .. TEXT .. "\"\n")

		if (NAME) then
			umsg.Start("ASS_NamedNotice", PLAYER)
			umsg.String( NAME ) 
		else
			umsg.Start("ASS_Notice", PLAYER)
		end
		
	  		umsg.String( ASS_FormatText(TEXT) ) 
	 		umsg.Float( DURATION ) 
		umsg.End()
	end

	function ASS_GenerateFixedNoticeName( TEXT, DURATION )
		return "FIXED:" .. util.CRC( tostring(TEXT) .. tostring(DURATION) )
	end

	function ASS_AddFixedNotice( TEXT, DURATION ) 
		ASS_AddNamedNotice( ASS_GenerateFixedNoticeName(TEXT, DURATION) , TEXT, DURATION)	
		table.insert( ASS_Config["fixed_notices"], { duration = DURATION, text = TEXT } )
		ASS_WriteConfig()
	end

	function ASS_AddNotice( TEXT, DURATION ) 
		ASS_AddNamedNotice(nil, TEXT, DURATION)
	end

	function ASS_AddNamedNotice( NAME, TEXT, DURATION ) 
		if (!NAME) then
			NAME = "NOTE:" .. util.CRC( tostring(TEXT) .. tostring(DURATION) .. tostring(CurTime()) .. tostring(#ActiveNotices) )
		end

		for k,v in pairs(ActiveNotices) do
			if (v.Name && v.Name == NAME) then
				table.remove(ActiveNotices, k)
				break
			end
		end
		
		table.insert( ActiveNotices, { Name = NAME, Text = TEXT, Duration = DURATION } )
		ASS_SendNotice(nil, NAME, TEXT, DURATION)
	end

	function ASS_FindNoteText( NAME )
		for k,v in pairs(ActiveNotices) do
			if (v.Name && v.Name == NAME) then
				return v.Text
			end
		end
		return nil
	end

	function ASS_RemoveNotice( NAME ) 
		for k,v in pairs(ActiveNotices) do
		
			if (v.Name && v.Name == NAME) then
				table.remove(ActiveNotices, k)
				break
			end
		
		end
		
		for k,v in pairs(ASS_Config["fixed_notices"]) do
			if (NAME == ASS_GenerateFixedNoticeName(v.text, v.duration)) then
				table.remove(ASS_Config["fixed_notices"], k)
				ASS_WriteConfig()
				break
			end
		end
		
		umsg.Start("ASS_RemoveNotice")
	 		umsg.String( NAME ) 
	 	umsg.End()
	end

	local NextAssThink = 0
	hook.Add('InitPostEntity', 'ASS_NoticeInitialize', function() for k,v in pairs(ASS_Config["fixed_notices"]) do ASS_AddNamedNotice( ASS_GenerateFixedNoticeName(v.text, v.duration), v.text or "", tonumber(v.duration) or 10) end end)
	hook.Add('Think', 'ASS_NoticeThink', function() if #ASS_GetActiveNotices() > 0 then SetGlobalString( "ServerTime", os.date("%H:%M:%S") ) SetGlobalString( "ServerDate", os.date("%d/%b/%Y") ) end NextAssThink = CurTime() + 1 end)

	function PLUGIN.PlayerInitialized(PLAYER)
		for k,v in pairs(ASS_GetActiveNotices()) do
			ASS_SendNotice(PLAYER, v.Name, v.Text, v.Duration)
		end
	end

	function PLUGIN.AddFixedNotice( PLAYER, CMD, ARGS )
		if (!PLAYER:IsValid()) then PLAYER = ConsolePlayer() end
		if (PLAYER:HasAssLevel(ASS_LVL_ADMIN)) then
		
			local dur = tonumber(ARGS[1]) or 5
			table.remove(ARGS, 1)
			local msg = table.concat(ARGS, " ")
		
			ASS_AddFixedNotice( msg, dur )
			ASS_LogAction( PLAYER, ASS_ACL_NOTICE, "added a fixed notice showing for " .. dur .. " seconds -> " .. msg)
		
		end
	end
	concommand.Add("ass_addfixednotice", PLUGIN.AddFixedNotice)

	function PLUGIN.AddNotice( PLAYER, CMD, ARGS )
		if (PLAYER:HasAssLevel(ASS_LVL_TEMPADMIN)) then
		
			local dur = tonumber(ARGS[1]) or 5
			table.remove(ARGS, 1)
			local msg = table.concat(ARGS, " ")
		
			ASS_AddNotice( msg, dur )
			ASS_LogAction( PLAYER, ASS_ACL_NOTICE, "added a notice showing for " .. dur .. " seconds -> " .. msg)
		
		end
	end
	concommand.Add("ass_addnotice", PLUGIN.AddNotice)
	
	function PLUGIN.ListAllNotices( PLAYER, CMD, ARGS)
		ASS_SendNoticesRaw(PLAYER)	
		
		umsg.Start("ASS_RemoveNoticeGUI", PLAYER)
		umsg.End()
	end
	concommand.Add("ass_listallnotices", PLUGIN.ListAllNotices)

	function PLUGIN.RemoveNotice( PLAYER, CMD, ARGS )
		if (PLAYER:HasAssLevel(ASS_LVL_TEMPADMIN)) then
			
			local name = table.concat(ARGS, "")
			local note = ASS_FindNoteText(name) or "(unknown)"
			 
			ASS_RemoveNotice(name)
			ASS_LogAction( PLAYER, ASS_ACL_NOTICE, "removed a notice -> " .. note)
			
		end
	end
	concommand.Add("ass_removenotice", PLUGIN.RemoveNotice)
end

if (CLIENT) then
	local NoticePanel = nil

	function ASS_ShouldShowNoticeBar()
		if (GAMEMODE.ASS_HideNoticeBar) then
			return false
		end

		return (tonumber(ASS_Config["show_notice_bar"]) or 1) == 1
	end

	function ASS_GetNoticePanel()
		return NoticePanel
	end

	function ASS_Notice( NAME, TEXT, DURATION ) 
		if (!NoticePanel) then 	
			NoticePanel = vgui.Create("DNoticePanel")
			if ASS_GetCountdownPanel then
				NoticePanel.CountDownPanel = ASS_GetCountdownPanel()
			end
			NoticePanel:SetVisible( ASS_ShouldShowNoticeBar() )
		end
		
		NoticePanel:AddNotice(NAME, TEXT, DURATION)
	end

	function ASS_RemoveNotice( NAME ) 
		if (!NoticePanel) then 	
			return
		end
		
		NoticePanel:RemoveNotice(NAME)
	end

	function ASS_ToggleNoticeBar( PLAYER, CMD, ARGS )
		if (ASS_Config["show_notice_bar"] == 0) then
			ASS_Config["show_notice_bar"] = 1
			chat.AddText(Color(0, 229, 238), "Assmod notice bar enabled.")
		else
			ASS_Config["show_notice_bar"] = 0
			chat.AddText(Color(0, 229, 238), "Assmod notice bar disabled.")
		end
		ASS_WriteConfig()
		
		if (NoticePanel) then
			NoticePanel:SetVisible( ASS_ShouldShowNoticeBar() )
		end
	end
	concommand.Add("ass_togglenoticebar", ASS_ToggleNoticeBar)

	usermessage.Hook( "ASS_NamedNotice", 
			function(UM)
				ASS_Notice( UM:ReadString(), UM:ReadString(), UM:ReadFloat() )
			end
		)
	usermessage.Hook( "ASS_Notice", 
			function(UM)
				ASS_Notice( nil, UM:ReadString(), UM:ReadFloat() )
			end
		)
	usermessage.Hook( "ASS_RemoveNotice", 
			function(UM)
				ASS_RemoveNotice( UM:ReadString() )
			end
		)	

	function PLUGIN.NoticeGUI(FIXED)
	
		if (FIXED) then
			PromptStringRequest( "Add permanent notice...", 
				"What text do you wish to permanently display?", 
				"", 
				function( strTextOut ) RunConsoleCommand("ASS_AddFixedNotice" , "10", strTextOut) end 
			)
		else
			PromptStringRequest( "Add temporary notice...", 
				"What text do you wish to temporarily display?", 
				"", 
				function( strTextOut ) RunConsoleCommand("ASS_AddNotice" , "10", strTextOut) end 
			)
		end
	
	end
	
	local RawMessages = {}
	
	function PLUGIN.RemoveNoticeGUI()
		PromptForChoice( "Remove a notice...", RawMessages, 
			function (DLG, ITEM)

				RunConsoleCommand("ASS_RemoveNotice", ITEM.Name)
				DLG:RemoveItem(DLG.Selection)

			end
		)
	end
	
	usermessage.Hook( "ASS_RawNotice", 
			function(UM)
				local name = UM:ReadString()
				local txt = UM:ReadString()
				local dur = UM:ReadFloat()
				table.insert( RawMessages, { Name = name, Text = txt } )
			end
		)
	usermessage.Hook( "ASS_RemoveNoticeGUI", 
			function(UM)
				PLUGIN.RemoveNoticeGUI()
			end
		)
		
	function PLUGIN.RemoveNotice()
	
		RawMessages = {}
	
		RunConsoleCommand("ASS_ListAllNotices")
		
		return true
	
	end

	function PLUGIN.NoticeMenu(MENU)			
		
		MENU:AddOption( "Add Notice...", 	function() PLUGIN.NoticeGUI(false) end ):SetImage( "icon16/newspaper_add.png" )
		MENU:AddOption( "Add Fixed Notice...",	function() PLUGIN.NoticeGUI(true) end ):SetImage( "icon16/newspaper_link.png" )
		MENU:AddOption( "Remove Notice...", 	function() PLUGIN.RemoveNotice() end ):SetImage( "icon16/newspaper_delete.png" )

	end

	function PLUGIN.AddMenu(DMENU)			
	
		DMENU:AddSubMenu( "Notices", nil, PLUGIN.NoticeMenu ):SetImage( "icon16/newspaper.png" )

	end

	function PLUGIN.AddSetting(SUBMENU)
		SUBMENU:AddOption( "Toggle Notice Bar", function() RunConsoleCommand("ass_togglenoticebar") end):SetImage("icon16/newspaper.png")
	end

end

ASS_RegisterPlugin(PLUGIN)
