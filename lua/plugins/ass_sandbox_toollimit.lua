
local PLUGIN = {}

PLUGIN.Name = "Sandbox Tool/Swep/Sent Protection"
PLUGIN.Author = "Andy Vincent"
PLUGIN.Date = "3rd February 2008"
PLUGIN.Filename = PLUGIN_FILENAME
PLUGIN.ClientSide = true
PLUGIN.ServerSide = true
PLUGIN.APIVersion = 2.3
PLUGIN.Gamemodes = { "sandbox" } // only load this plugin for sandbox and it's derivatives

if (SERVER) then

	PLUGIN.ToolList = {}
	PLUGIN.SwepList = {}
	PLUGIN.SentList = {}

	function PLUGIN.InitToolList()

		local toolgun = weapons.GetStored("gmod_tool")
		
		if (!toolgun || !toolgun.Tool) then
			return false
		end
		
		for toolname, tool in pairs(toolgun.Tool) do
			local ToolInfo = {}
			ToolInfo.DisplayName = tool.Name || "#"..toolname
			ToolInfo.InternalName = string.lower(toolname)
			ToolInfo.LowestAllowedLevel = ASS_LVL_GUEST
			table.insert( PLUGIN.ToolList, ToolInfo )
			
			umsg.PoolString(ToolInfo.DisplayName)
			umsg.PoolString(ToolInfo.InternalName)
		end
		
		return true
		
	end
	
	function PLUGIN.InitSwepList()
		local sweps = weapons.GetList() 
		for _,wep in pairs(sweps) do
			if (wep.Spawnable || wep.AdminSpawnable) then
				local SwepInfo = {}
				SwepInfo.DisplayName = wep.PrintName || wep.ClassName
				SwepInfo.InternalName = wep.ClassName
				if (!wep.Spawnable && wep.AdminSpawnable) then
					SwepInfo.LowestAllowedLevel = ASS_LVL_ADMIN
				else
					SwepInfo.LowestAllowedLevel = ASS_LVL_GUEST
				end
				table.insert( PLUGIN.SwepList, SwepInfo )

				umsg.PoolString(SwepInfo.DisplayName)
				umsg.PoolString(SwepInfo.InternalName)
			end
		end
		return true
	end

	function PLUGIN.InitSentList()
		local sents = scripted_ents.GetSpawnable() 
		for _,sent in pairs(sents) do
			local SentInfo = {}
			SentInfo.DisplayName = sent.PrintName || sent.ClassName
			SentInfo.InternalName = sent.ClassName
			SentInfo.LowestAllowedLevel = ASS_LVL_GUEST
			table.insert( PLUGIN.SentList, SentInfo )

			umsg.PoolString(SentInfo.DisplayName)
			umsg.PoolString(SentInfo.InternalName)
		end
		return true
	end
	
	function PLUGIN.SetListAllowed(LIST, NAME, LEVEL)
	
		for _,info in pairs(LIST) do
			if (info.InternalName == NAME) then
				info.LowestAllowedLevel = LEVEL
				break
			end
		end
	
	end

	function PLUGIN.GetListLevel(LIST, NAME)
		for _,info in pairs(LIST) do
			if (info.InternalName == NAME) then
				return info.LowestAllowedLevel || ASS_LVL_GUEST
			end
		end
		return ASS_LVL_GUEST
	end
	
	function PLUGIN.SetToolAllowed(NAME, LEVEL)	PLUGIN.SetListAllowed(PLUGIN.ToolList, NAME, LEVEL ) end
	function PLUGIN.SetSwepAllowed(NAME, LEVEL)	PLUGIN.SetListAllowed(PLUGIN.SwepList, NAME, LEVEL ) end
	function PLUGIN.SetSentAllowed(NAME, LEVEL)	PLUGIN.SetListAllowed(PLUGIN.SentList, NAME, LEVEL ) end
	function PLUGIN.GetToolLevel(NAME, LEVEL)	return PLUGIN.GetListLevel(PLUGIN.ToolList, NAME ) end
	function PLUGIN.GetSwepLevel(NAME, LEVEL)	return PLUGIN.GetListLevel(PLUGIN.SwepList, NAME ) end
	function PLUGIN.GetSentLevel(NAME, LEVEL)	return PLUGIN.GetListLevel(PLUGIN.SentList, NAME ) end
	
	function PLUGIN.InitPostEntity()
		ASS_Config["restrict_tools"] = ASS_Config["restrict_tools"] || {}
		for name,level in pairs(ASS_Config["restrict_tools"]) do
			PLUGIN.SetToolAllowed(name, tonumber(level))
		end

		ASS_Config["restrict_sweps"] = ASS_Config["restrict_sweps"] || {}
		for name,level in pairs(ASS_Config["restrict_sweps"]) do
			PLUGIN.SetSwepAllowed(name, tonumber(level))
		end

		ASS_Config["restrict_sents"] = ASS_Config["restrict_sents"] || {}
		for name,level in pairs(ASS_Config["restrict_sents"]) do
			PLUGIN.SetSentAllowed(name, tonumber(level))
		end
	end

	function PLUGIN.Registered()
	
		if (PLUGIN.InitToolList() && PLUGIN.InitSwepList() && PLUGIN.InitSentList()) then
		
			ASS_GetSwepLevel = PLUGIN.GetSwepLevel
		
			hook.Add("InitPostEntity",	"InitPostEntity_" .. PLUGIN.Filename,	PLUGIN.InitPostEntity )
			hook.Add("CanTool",		"CanTool_" .. PLUGIN.Filename,		PLUGIN.CanTool )
			hook.Add("PlayerSpawnSENT",	"PlayerSpawnSENT_" .. PLUGIN.Filename,	PLUGIN.PlayerSpawnSENT )

		// MESSY: Gmod doesn't actually have any hooks to allow/disallow swep spawning/giving, so
		//        we override the console command, and call the base functions ourselves...
			concommand.Add( "gm_giveswep", 
				function(PLAYER, CMD, ARGS)
					if ( ARGS[1] == nil ) then return end
					
					// Make sure it's a SWEP
					local swep = weapons.GetStored(ARGS[1]) 
 					if (swep == nil) then return end 

					// Can it be spawned at all?
					if ( !swep.Spawnable && !swep.AdminSpawnable ) then return end

					// Check what the server allows
					local LVL = PLUGIN.GetSwepLevel(ARGS[1])
					if (!PLAYER:HasAssLevel( LVL )) then
						ASS_MessagePlayer( PLAYER, "Sorry, only " .. LevelToString(LVL) .. " are allowed to use this weapon!")
						return
					end
					
					// Give
 					MsgAll( "Giving "..PLAYER:Nick().." a "..swep.ClassName.."\n" ) 
					PLAYER:Give( swep.ClassName ) 
				 	PLAYER:SelectWeapon( swep.ClassName ) 
				end)
		
			concommand.Add( "gm_spawnswep", 
				function(PLAYER, CMD, ARGS)

					if ( ARGS[1] == nil ) then return end
					
					// Make sure it's a SWEP
					local swep = weapons.GetStored(ARGS[1]) 
 					if (swep == nil) then return end 

					// Can it be spawned at all?
					if ( !swep.Spawnable && !swep.AdminSpawnable ) then return end

					// Check what the server allows
					local LVL = PLUGIN.GetSwepLevel(ARGS[1])
					if (!PLAYER:HasAssLevel( LVL )) then
						ASS_MessagePlayer( PLAYER, "Sorry, only " .. LevelToString(LVL) .. " are allowed to use this weapon!")
						return
					end
					
					// Spawn!
					local tr = PLAYER:GetEyeTraceNoCursor() 

					if ( !tr.Hit ) then return end 

					local entity = ents.Create( swep.ClassName ) 

					if ( IsValid( entity ) ) then 

						entity:SetPos( tr.HitPos + tr.HitNormal * 32 ) 
						entity:Spawn() 

					end 				
				end)
				
		end
	
	end
	
	function PLUGIN.PlayerSpawnSENT(PLAYER, NAME )
	
		local LVL = PLUGIN.GetSentLevel(NAME)
		if (!PLAYER:HasAssLevel( LVL )) then
			ASS_MessagePlayer( PLAYER, "Sorry, only " .. LevelToString(LVL) .. " are allowed to use this entity!")
			return false
		end
	
	end
	
	function PLUGIN.CanTool( PLAYER, TRACE, MODE )
		
		local LVL = PLUGIN.GetToolLevel(MODE)
		if (!PLAYER:HasAssLevel( LVL )) then
			ASS_MessagePlayer( PLAYER, "Sorry, only " .. LevelToString(LVL) .. " are allowed to use this tool!")
			return false
		end
		
	end
	
	function PLUGIN.SendAllowedList(PLAYER, CMD, ARGS)
		
		if (ARGS[1] == "tools") then
		
			ASS_BeginProgress( PLAYER, "ASS_ToolLimit", "Recieving tool data...", #PLUGIN.ToolList )

			for k,v in pairs(PLUGIN.ToolList) do
				if (PLAYER:HasAssLevel(v.LowestAllowedLevel)) then
					umsg.Start( "ASS_SandBoxToolRestrict", PLAYER )

						umsg.Short( 0 )
						umsg.String(	v.DisplayName		)
						umsg.String(	v.InternalName		)
						umsg.Short(	v.LowestAllowedLevel	)

					umsg.End()
				end
			end
			
			umsg.Start( "ASS_SandBoxToolRestrictGUI", PLAYER )
				umsg.Short( 0 )
			umsg.End()
			
		elseif (ARGS[1] == "sweps") then
		
			ASS_BeginProgress( PLAYER, "ASS_SwepLimit", "Recieving weapon data...", #PLUGIN.SwepList )

			for k,v in pairs(PLUGIN.SwepList) do
				if (PLAYER:HasAssLevel(v.LowestAllowedLevel)) then
					umsg.Start( "ASS_SandBoxToolRestrict", PLAYER )

						umsg.Short( 1 )
						umsg.String(	v.DisplayName		)
						umsg.String(	v.InternalName		)
						umsg.Short(	v.LowestAllowedLevel	)

					umsg.End()
				end
			end
			
			umsg.Start( "ASS_SandBoxToolRestrictGUI", PLAYER )
				umsg.Short( 1 )
			umsg.End()

		elseif (ARGS[1] == "sents") then

			ASS_BeginProgress( PLAYER, "ASS_SentLimit", "Recieving entity data...", #PLUGIN.SentList )

			for k,v in pairs(PLUGIN.SentList) do
				if (PLAYER:HasAssLevel(v.LowestAllowedLevel)) then
					umsg.Start( "ASS_SandBoxToolRestrict", PLAYER )

						umsg.Short( 2 )
						umsg.String(	v.DisplayName		)
						umsg.String(	v.InternalName		)
						umsg.Short(	v.LowestAllowedLevel	)

					umsg.End()
				end
			end
			
			umsg.Start( "ASS_SandBoxToolRestrictGUI", PLAYER )
				umsg.Short( 2 )
			umsg.End()
		
		end

	end
	concommand.Add("ASS_GetToolAllowed", PLUGIN.SendAllowedList)
	
	function PLUGIN.SetAllowedValue(PLAYER, CMD, ARGS)
		if (PLAYER:IsSuperAdmin()) then
			local Type = ARGS[1]
			local ToolName = ARGS[2]
			local Level = tonumber(ARGS[3])
			
			if (!Type || !ToolName || !Level) then return end
			
			if (!ASS_RANKS[Level]) then return end

			if (Type == "tools") then
				local CurrentLevel = PLUGIN.GetToolLevel(ToolName)
				if (CurrentLevel == Level) then return end

				if (!PLAYER:HasAssLevel(CurrentLevel)) then
					ASS_MessagePlayer( PLAYER, "Access denied!")
					return
				end

				PLUGIN.SetToolAllowed(ToolName, Level)	
				ASS_Config["restrict_tools"] = ASS_Config["restrict_tools"] || {}
				ASS_Config["restrict_tools"][ToolName] = Level
				ASS_WriteConfig()

				ASS_LogAction( PLAYER, ASS_ACL_SANDBOX, "set " .. ToolName .. " to " .. LevelToString(Level) .. " only" )
			elseif (Type == "sweps") then
				local CurrentLevel = PLUGIN.GetSwepLevel(ToolName)
				if (CurrentLevel == Level) then return end

				if (!PLAYER:HasAssLevel(CurrentLevel)) then
					ASS_MessagePlayer( PLAYER, "Access denied!")
					return
				end

				PLUGIN.SetSwepAllowed(ToolName, Level)	
				ASS_Config["restrict_sweps"] = ASS_Config["restrict_sweps"] || {}
				ASS_Config["restrict_sweps"][ToolName] = Level
				ASS_WriteConfig()

				ASS_LogAction( PLAYER, ASS_ACL_SANDBOX, "set " .. ToolName .. " to " .. LevelToString(Level) .. " only" )
			elseif (Type == "sents") then
				local CurrentLevel = PLUGIN.GetSentLevel(ToolName)
				if (CurrentLevel == Level) then return end

				if (!PLAYER:HasAssLevel(CurrentLevel)) then
					ASS_MessagePlayer( PLAYER, "Access denied!")
					return
				end

				PLUGIN.SetSentAllowed(ToolName, Level)	
				ASS_Config["restrict_sents"] = ASS_Config["restrict_sents"] || {}
				ASS_Config["restrict_sents"][ToolName] = Level
				ASS_WriteConfig()

				ASS_LogAction( PLAYER, ASS_ACL_SANDBOX, "set " .. ToolName .. " to " .. LevelToString(Level) .. " only" )
			end
		else
			ASS_MessagePlayer( PLAYER, "Access denied!")
		end
	end
	concommand.Add("ASS_ToolAllowed", PLUGIN.SetAllowedValue)

end

if (CLIENT) then

////////////////////////////////////////////////////////////////////////////////////
// DToolRestrictLine
////////////////////////////////////////////////////////////////////////////////////

	PANEL = {}

	function PANEL:Init()

		self.AdminItems = {}
		self.Label = vgui.Create("DLabel", self)
		self.Value = vgui.Create("DComboBox", self)
		--self.Value:SetEditable(false)
		self.Value.OnSelect = function(self, index, value, data) self.Selected = data end
		
		for k,v in pairs(ASS_RANKS) do
			self.AdminItems[k] = self.Value:AddChoice(v.Name, k)
		end
		
	end

	function PANEL:Setup( DisplayName, InternalName, AllowedLevel )
	
		self.InternalName = InternalName
		self.InitialValue = AllowedLevel
		
		self.Label:SetText(DisplayName)
		self.Label:SetColor(Color( 20, 20, 20, 255 ))
		self.Value.Selected = AllowedLevel
		self.Value:ChooseOption( LevelToString(AllowedLevel), self.AdminItems[AllowedLevel] )
	
	end
	
	function PANEL:PerformLayout()

		derma.SkinHook( "Layout", "Panel", self )	
		
		self.Label:SizeToContents()
		self.Label:SetPos(self:GetWide() - 100 - 4 -self.Label:GetWide() - 4, 8)
		
		self.Value:SetWide(100)
		self.Value:SetPos(self:GetWide() - 100 - 4, 4)
		
	end

	derma.DefineControl( "DToolRestrictLine", "Tool restrict line", PANEL, "Panel" )
	
////////////////////////////////////////////////////////////////////////////////////
// DToolRestrictFrame
////////////////////////////////////////////////////////////////////////////////////

	PANEL = {}

	function PANEL:Init()

		self.List = vgui.Create("DPanelList", self)
		self.List:EnableVerticalScrollbar()
		self.List:SetPadding(4)
		self.List:SetSpacing(1)
		self.List.Paint = function(w,h)
			draw.RoundedBox( 4, 0, 0, self.List:GetWide(), self.List:GetTall(), Color( 220, 220, 220, 255 ) )
			derma.SkinHook( "Paint", "PanelList", self.List, w, h )
		end

		self.ApplyButton = vgui.Create("DButton", self)
		self.ApplyButton:SetText("Apply")
		self.ApplyButton.DoClick = function(BTN) self:ApplySettings() end

		self.CancelButton = vgui.Create("DButton", self)
		self.CancelButton:SetText("Cancel")
		self.CancelButton.DoClick = function(BTN) self:Close() end
	end
	
	function PANEL:SetMode(mode, list)
	
		self.Mode = mode
		self.Items = {}
		self.ItemList = list
		
		for k,v in pairs(self.ItemList) do
			self:AddVar( v.DisplayName, v.InternalName, v.LowestAllowedLevel )
		end
		
	end
	
	function PANEL:AddVar( DisplayName, InternalName, LowestLevel )
		
		local item = vgui.Create("DToolRestrictLine")
		item:Setup( DisplayName, InternalName, LowestLevel )
		item:SetTall(30)

		self.List:AddItem(item)
		table.insert(self.Items, item)
	
	end
	
	function PANEL:ApplySettings()
		for k,v in pairs(self.Items) do
			local NewValue = v.Value.Selected
			
			if (NewValue != v.InitialValue) then
				RunConsoleCommand("ASS_ToolAllowed", self.Mode, v.InternalName, NewValue )
				v.InitialValue = NewValue
			end
		end
	end

	function PANEL:PerformLayout()

		--derma.SkinHook( "Layout", "Frame", self )
		
		--Hacky copy paste from DFrame's PerformLayout()
		self.btnClose:SetPos( self:GetWide() - 31 - 4, 0 )
		self.btnClose:SetSize( 31, 31 )

		self.btnMaxim:SetPos( self:GetWide() - 31*2 - 4, 0 )
		self.btnMaxim:SetSize( 31, 31 )

		self.btnMinim:SetPos( self:GetWide() - 31*3 - 4, 0 )
		self.btnMinim:SetSize( 31, 31 )
	
		self.lblTitle:SetPos( 8, 2 )
		self.lblTitle:SetSize( self:GetWide() - 25, 20 )
		--end

		self.List:SetTall(300)

		self.CancelButton:SizeToContents()
		self.ApplyButton:SizeToContents()
		
		local btnWid = self.CancelButton:GetWide()
		if (self.ApplyButton:GetWide() > btnWid) then
			btnWid = self.ApplyButton:GetWide()
		end
		btnWid = btnWid + 16

		local btnHei = self.CancelButton:GetTall()
		if (self.ApplyButton:GetTall() > btnHei) then
			btnHei = self.ApplyButton:GetTall()
		end
		btnHei = btnHei + 8
		
		self.CancelButton:SetWide(btnWid)
		self.CancelButton:SetTall(btnHei)

		self.ApplyButton:SetWide(btnWid)
		self.ApplyButton:SetTall(btnHei)

		local height = 32

			height = height + self.List:GetTall()
			height = height + 8
			height = height + btnHei
			height = height + 8

		self:SetTall(height)

		local width = self:GetWide()

		self.List:SetPos( 8, 32 )
		self.List:SetWide( width - 16 )

		local btnY = 32 + self.List:GetTall() + 8
		self.CancelButton:SetPos( width - 8 - btnWid, btnY )
		self.ApplyButton:SetPos( width - 8 - btnWid - 8 - btnWid, btnY )
	end

	derma.DefineControl( "DToolRestrictFrame", "Frame to restrict tools", PANEL, "DFrame" )

////////////////////////////////////////////////////////////////////////////////////
// Plugin Code
////////////////////////////////////////////////////////////////////////////////////

	usermessage.Hook( "ASS_SandBoxToolRestrict", function (UMSG)
		
			local v = {}
			local typ = UMSG:ReadShort()
			v.DisplayName = UMSG:ReadString()
			v.InternalName = UMSG:ReadString()
			v.LowestAllowedLevel = UMSG:ReadShort()
			if (typ == 0) then	
				ASS_IncProgress("ASS_ToolLimit")
				table.insert(PLUGIN.ToolList, v)
				table.sort(PLUGIN.ToolList, function(a, b)
					return tostring(a.InternalName) < tostring(b.InternalName)
				end)
			elseif (typ == 1) then	
			
				/* HACKITY HACK: SWEP names are stored clientside only! */
				local wep = weapons.GetStored(v.InternalName)
				if (wep && wep.PrintName) then
					v.DisplayName = wep.PrintName
				end
			
				ASS_IncProgress("ASS_SwepLimit")
				table.insert(PLUGIN.SwepList, v)
				table.sort(PLUGIN.SwepList, function(a, b)
					return tostring(a.DisplayName) < tostring(b.DisplayName)
				end)
			elseif (typ == 2) then	
				ASS_IncProgress("ASS_SentLimit")
				table.insert(PLUGIN.SentList, v)
				table.sort(PLUGIN.SentList, function(a, b)
					return tostring(a.DisplayName) < tostring(b.DisplayName)
				end)
			end			
		end )
	
	usermessage.Hook( "ASS_SandBoxToolRestrictGUI", function (UMSG)
		
			local typ = UMSG:ReadShort()
			
			local TE = vgui.Create("DToolRestrictFrame")
			TE:SetBackgroundBlur( true )
			TE:SetDrawOnTop( true )
			if (typ == 0) then
				ASS_EndProgress("ASS_ToolLimit")
				TE:SetTitle("Restrict Tools...")
				TE:SetMode("tools", PLUGIN.ToolList)
				PLUGIN.ToolList = nil
			elseif (typ == 1) then
				ASS_EndProgress("ASS_SwepLimit")
				TE:SetTitle("Restrict Weapons...")
				TE:SetMode("sweps", PLUGIN.SwepList)
				PLUGIN.SwepList = nil
			elseif (typ == 2) then
				ASS_EndProgress("ASS_SentLimit")
				TE:SetTitle("Restrict Entities...")
				TE:SetMode("sents", PLUGIN.SentList)
				PLUGIN.SentList = nil
			end
			TE:SetVisible( true )
			TE:SetWide(300)
			TE:PerformLayout()
			TE:Center()
			TE:MakePopup()	
			
		end )

	function PLUGIN.AddGamemodeMenu(DMENU)			

		DMENU:AddSubMenu( "Restrict", nil, 
				function(NEWMENU)

					NEWMENU:AddOption( "Tools", 	
						function() 
							if (PLUGIN.ToolList) then return end
							PLUGIN.ToolList = {}	
							RunConsoleCommand("ASS_GetToolAllowed", "tools")	
						end
					):SetImage("icon16/wand.png")

					NEWMENU:AddOption( "Weapons", 	
						function() 
							if (PLUGIN.SwepList) then return end
							PLUGIN.SwepList = {}	
							RunConsoleCommand("ASS_GetToolAllowed", "sweps")	
						end
					):SetImage("icon16/wrench.png")

					NEWMENU:AddOption( "Entities", 	
						function() 
							if (PLUGIN.SentList) then return end
							PLUGIN.SentList = {}	
							RunConsoleCommand("ASS_GetToolAllowed", "sents")	
						end
					):SetImage("icon16/wrench_orange.png")
				
				end
			):SetImage("icon16/shield_delete.png")

	end

end

ASS_RegisterPlugin(PLUGIN)
