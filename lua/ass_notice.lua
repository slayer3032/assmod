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


function ASS_Countdown( PLAYER, TEXT, DURATION ) 
	ASS_Debug("Countdown \"" .. TEXT .. "\" for " .. DURATION .. "\n")
	umsg.Start("ASS_Countdown", PLAYER)
 		umsg.String( TEXT ) 
 		umsg.Float( DURATION ) 
 	umsg.End()
end

function ASS_CountdownAll( TEXT, DURATION ) 
	ASS_Debug("Countdown \"" .. TEXT .. "\" for " .. DURATION .. "\n")
	umsg.Start("ASS_Countdown")
 		umsg.String( TEXT ) 
 		umsg.Float( DURATION ) 
 	umsg.End()
 end

function ASS_NamedCountdown( PLAYER, NAME, TEXT, DURATION ) 
	ASS_Debug("Countdown \"" .. TEXT .. "\" for " .. DURATION .. "\n")
	umsg.Start("ASS_NamedCountdown", PLAYER)
		umsg.String( NAME ) 
		umsg.String( TEXT ) 
		umsg.Float( DURATION ) 
	umsg.End()
end

function ASS_NamedCountdownAll( NAME, TEXT, DURATION ) 
	ASS_Debug("Countdown \"" .. TEXT .. "\" for " .. DURATION .. "\n")
	umsg.Start("ASS_NamedCountdown")
		umsg.String( NAME ) 
		umsg.String( TEXT ) 
		umsg.Float( DURATION ) 
	umsg.End()
end

function ASS_RemoveCountdown( PLAYER, NAME ) 
	umsg.Start("ASS_RemoveCountdown", PLAYER)
		umsg.String( NAME ) 
	umsg.End()
end

function ASS_RemoveCountdownAll( NAME ) 
	umsg.Start("ASS_RemoveCountdown")
		umsg.String( NAME ) 
	umsg.End()
end

function ASS_BeginProgress( PLAYER, NAME, TEXT, MAXIMUM ) 
	if (MAXIMUM == 0) then
		return 
	end

	umsg.Start("ASS_BeginProgress", PLAYER)
		umsg.String( NAME ) 
		umsg.String( TEXT ) 
		umsg.Float( MAXIMUM ) 
	umsg.End()
end

function ASS_IncProgress( PLAYER, NAME, INC ) 
	umsg.Start("ASS_IncProgress", PLAYER)
		umsg.String( NAME ) 
		umsg.Float( INC || 1 ) 
	umsg.End()
end

function ASS_EndProgress( PLAYER, NAME ) 
	umsg.Start("ASS_EndProgress", PLAYER)
		umsg.String( NAME ) 
	umsg.End()
end