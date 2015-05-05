
local PLUGIN = {}

PLUGIN.Name = "Notice"
PLUGIN.Author = "Andy Vincent"
PLUGIN.Date = "22nd August 2007"
PLUGIN.Filename = PLUGIN_FILENAME
PLUGIN.ClientSide = true
PLUGIN.ServerSide = true
PLUGIN.APIVersion = 2.3
PLUGIN.Gamemodes = {}

if (SERVER) then

	ASS_NewLogLevel("ASS_ACL_NOTICE")
	
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
	concommand.Add("ASS_AddFixedNotice", PLUGIN.AddFixedNotice)

	function PLUGIN.AddNotice( PLAYER, CMD, ARGS )
		if (PLAYER:HasAssLevel(ASS_LVL_TEMPADMIN)) then
		
			local dur = tonumber(ARGS[1]) or 5
			table.remove(ARGS, 1)
			local msg = table.concat(ARGS, " ")
		
			ASS_AddNotice( msg, dur )
			ASS_LogAction( PLAYER, ASS_ACL_NOTICE, "added a notice showing for " .. dur .. " seconds -> " .. msg)
		
		end
	end
	concommand.Add("ASS_AddNotice", PLUGIN.AddNotice)
	
	function PLUGIN.ListAllNotices( PLAYER, CMD, ARGS)
		ASS_SendNoticesRaw(PLAYER)	
		
		umsg.Start("ASS_RemoveNoticeGUI", PLAYER)
		umsg.End()
	end
	concommand.Add("ASS_ListAllNotices", PLUGIN.ListAllNotices)

	function PLUGIN.RemoveNotice( PLAYER, CMD, ARGS )
		if (PLAYER:HasAssLevel(ASS_LVL_TEMPADMIN)) then
			
			local name = table.concat(ARGS, "")
			local note = ASS_FindNoteText(name) or "(unknown)"
			 
			ASS_RemoveNotice(name)
			ASS_LogAction( PLAYER, ASS_ACL_NOTICE, "removed a notice -> " .. note)
			
		end
	end
	concommand.Add("ASS_RemoveNotice", PLUGIN.RemoveNotice)
end

if (CLIENT) then

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

end

ASS_RegisterPlugin(PLUGIN)
