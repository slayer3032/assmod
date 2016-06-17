
include("ass_shared.lua")

ASS_Initialized = false

function ASS_BanPlayer( INFO )
	if !IsValid(INFO.Player) then return true end
	
	net.Start('ass_banplayer')
		net.WriteString(INFO.Player:AssID())
		net.WriteUInt(INFO.Time, 32)
		net.WriteString(INFO.Reason or ' ')
	net.SendToServer()
	
	return true
end

function ASS_KickPlayer( INFO )
	if !IsValid(INFO.Player) then return true end
	
	net.Start('ass_kickplayer')
		net.WriteString(INFO.Player:AssID())
		net.WriteString(INFO.Reason or ' ')
	net.SendToServer()
	
	return true
end

function ASS_SetLevel(pl, level, time)
	if !IsValid(pl) then return true end
	
	net.Start('ass_setlevel')
		net.WriteString(pl:AssID())
		net.WriteUInt(level, 8)
		net.WriteUInt(time or 0, 32)
	net.SendToServer()
	
	return true
end

function ASS_CustomReason(INFO)
	PromptStringRequest( "Custom Reason...",
		"Why do you want to " .. INFO.Type .. " " .. INFO.Player:Nick() .. "?", 
		"", 
		function( strTextOut ) 
			table.insert(ASS_Config["reasons"], 	{	name = strTextOut,	reason = strTextOut		} )
			ASS_WriteConfig()
		
			INFO.Reason = strTextOut
			INFO.Function(INFO)
		end 
	)	
end

function ASS_KickBanReasonMenu( MENU, INFO )
	INFO = INFO or {}

	for k, v in pairs(ASS_Config["reasons"]) do
		MENU:AddOption( (v.name or ("Unnamed #" .. k)), 
				function() 
					INFO.Reason = v.reason or ""
					return INFO.Function(INFO)
				end
			)
	end
	MENU:AddSpacer()
	MENU:AddOption( "Custom...", 
			function() 
				ASS_CustomReason(INFO)
			end
		)
end

function ASS_BanTimeMenu( MENU, PLAYER )
	for k, v in pairs(ASS_Config["ban_times"]) do	
		local txt = v.name or ("Unnamed #" .. k)
		MENU:AddSubMenu( txt, nil, function(NEWMENU) ASS_KickBanReasonMenu( NEWMENU, { ["Type"] = "ban", ["Function"] = ASS_BanPlayer, ["Player"] = PLAYER, ["Time"] = v.time } ) end )	
	end
end

function ASS_KickReasonMenu( MENUITEM, PLAYER, INFO )
	INFO = {}
	INFO.Function = ASS_KickPlayer
	INFO.Type = "kick"
	INFO.Player = PLAYER
	
	ASS_KickBanReasonMenu(MENUITEM, INFO)
end

function ASS_TempAdminMenu( MENU, PLAYER )
	for k, v in pairs(ASS_Config["temp_admin_times"]) do
		MENU:AddOption(v.name, function() ASS_SetLevel(PLAYER, ASS_LVL_TEMPADMIN, v.time) end )
	end
end

function ASS_AccessMenu( SUBMENU, PLAYER )
	local icontbl = table.Copy(ASS_RANKS)
	
	if (ASS_RANKS[PLAYER:GetAssLevel()]) then
		icontbl[PLAYER:GetAssLevel()].Icon = "icon16/tick.png"
	end	

	local Items = {}
	
	for k,v in pairs(ASS_RANKS) do
		if v.Name == "Temp Admin" then
			Items[k] = SUBMENU:AddSubMenu("Temp Admin", nil, function(NEWMENU) ASS_TempAdminMenu(NEWMENU, PLAYER) end):SetImage(icontbl[k].Icon)
		else
			Items[k] = SUBMENU:AddOption(v.Name, function() ASS_SetLevel(PLAYER, k) end):SetImage(icontbl[k].Icon)
		end
	end	
end

function ASS_TableContains( TAB, VAR )	
	if (!TAB) then		
		return false		
	end
	
	for k,v in pairs(TAB) do	
		if (v == VAR) then 	
			return true 	
		end
	end
	
	return false
end

// Oh god this is going to be hacky 
function ASS_FixMenu( MENU )
	
	// Call the callback when we need to build the menu
	// If we're creating the menu now, also register our
	// hacked functions with it, so this hack propagates
	// virus like among any DMenus spawned from this 
	// parent DMenu.. muhaha
 	function DMenuOption_OnCursorEntered(self) 
 		local m = self.SubMenu
 		if (self.BuildFunction) then
 	 		m = DermaMenu( self ) 
	 		ASS_FixMenu(m)
 			m:SetVisible( false ) 
 			m:SetParent( self ) 
 			ASS_PCallError( self.BuildFunction, m )
		end
		
		self.ParentMenu:OpenSubMenu( self, m )	 
	end 	
	
	// Menu item images!
	function DMenuOption_SetImage(self, img)
		self.Image = ASS_Icon(img)
	end
	
	// Change the released hook so that if the click function
	// returns a non-nil or non-false value then the menus
	// get closed (this way menus can stay opened and be clicked
	// several time).
	function DMenuOption_OnMouseReleased( self, mousecode ) 
		DButton.OnMouseReleased( self, mousecode ) 

		if ( self.m_MenuClicking ) then 
			self.m_MenuClicking = false 
			
			if (!self.ClickReturn) then
				CloseDermaMenus() 
			end
		end 
	end 
	
	// Make sure we draw the image, should be done in the skin
	// but this is a total hack, so meh.
	function DMenuOption_Paint(self, w, h)
		derma.SkinHook( "Paint", "MenuOption", self, w, h)
		
		if (self.Image) then
			surface.SetDrawColor( 255, 255, 255, 255 )
	 		surface.SetMaterial( self.Image )  
 			surface.DrawTexturedRect( 2, (self:GetTall() - 16) * 0.5, 16, 16)
 		end
		
		return false
	end

 	// Make DMenuOptions implement our new functions above.
	// Returns the new DMenuOption created.
	local function DMenu_AddOption( self, strText, funcFunction )
 		local pnl = vgui.Create( "DMenuOption", self )
 		pnl.OnCursorEntered = DMenuOption_OnCursorEntered
		pnl.OnMouseReleased = DMenuOption_OnMouseReleased
 		pnl.Paint = DMenuOption_Paint
 		pnl.SetImage = DMenuOption_SetImage
  		pnl:SetText( strText ) 

 		if ( funcFunction ) then 
 			pnl.DoClickInternal = function(self) 
 					self.ClickReturn = funcFunction(pnl) 
 				end
 		end
 	 
 		self:AddPanel( pnl )
		pnl:SetMenu( pnl )
 	 
 		return pnl 
 	end	

	// Make DMenuOptions implement our new functions above.
	// If we're creating the menu now, also register our
	// hacked functions with it, so this hack propagates
	// virus like among any DMenus spawned from this 
	// parent DMenu.. muhaha
	// Returns the new DMenu (if it exists), and the DMenuOption
	// created.
	local function DMenu_AddSubMenu( self, strText, funcFunction, openFunction ) 
	 	local SubMenu = nil
	 	if (!openFunction) then
	 		SubMenu = DermaMenu( self ) 
	 		ASS_FixMenu(SubMenu)
 			SubMenu:SetVisible( false ) 
 			SubMenu:SetParent( self ) 
 		end
 	
 		local pnl = vgui.Create( "DMenuOption", self ) 
 		pnl.OnCursorEntered = DMenuOption_OnCursorEntered
  		pnl.OnMouseReleased = DMenuOption_OnMouseReleased
		pnl.Paint = DMenuOption_Paint
 		pnl.SetImage = DMenuOption_SetImage
		pnl.BuildFunction = openFunction
		pnl:SetSubMenu( SubMenu ) 
		pnl:SetText( strText ) 

		if ( funcFunction ) then 
			pnl.DoClickInternal = function() pnl.ClickReturn = funcFunction(pnl) end
		else 
			pnl.DoClickInternal = function() pnl.ClickReturn = true end
		end

		self:AddPanel( pnl ) 

		if (SubMenu) then
			return SubMenu, pnl
		else
			return pnl
		end
	end 
	// Register our new hacked function. muhahah
	MENU.AddOption = DMenu_AddOption
	MENU.AddSubMenu = DMenu_AddSubMenu
end
// See, told you it was hacky, hopefully won't have to do this for much longer

// This function was once fairly neat and tidy... Now it's a big
// mess of anonymous functions and submenus. 
// I'd tidy it up, but I think it'd stop working, or break everything...
// It's only the "IncludeAll" options that really screw it up actually,
// but it adds soo much flexability it's totally worth it.

function ASS_PlayerMenu( SUBMENU, OPTIONS, FUNCTION, ... )
	local arg = {...}

	if (type(SUBMENU) != "Panel") then Msg("ASS_PlayerMenu: SUBMENU isn't a menu!\n") return end

	local others = player.GetAll()
	table.sort(others, function(a, b)
			return tostring(a:Nick()) < tostring(b:Nick())
	end);
	
	local includeSubMenus = ASS_TableContains(OPTIONS, "HasSubMenu")
	local includeSelf = ASS_TableContains(OPTIONS, "IncludeLocalPlayer")
	local includeAll = ASS_TableContains(OPTIONS, "IncludeAll")
	local includeAllSO = ASS_TableContains(OPTIONS, "IncludeAllSO")
	
	local NumOptions = 0
	
	if (includeAll || includeAllSO) then
	
		/* I love anonymous functions, good luck understanding what this does! */
		
		if (LocalPlayer():HasAssLevel(ASS_LVL_SERVER_OWNER) || includeAllSO) then		
			SUBMENU:AddSubMenu( "All", nil,
					function(ALLMENU)
						if (includeSubMenus) then
						
							ALLMENU:AddSubMenu( "Players", nil,
								function(NEWMENU)
									local List = {}
									for _, PL in pairs(player.GetAll()) do
										if (PL != LocalPlayer() || includeSelf) then
											table.insert(List, PL)
										end
									end
									ASS_PCallError( FUNCTION, NEWMENU, List, unpack(arg))
								end ):SetImage( "icon16/group.png" )

							ALLMENU:AddSubMenu( "Non-Admins", nil,
								function(NEWMENU)
									local List = {}
									for _, PL in pairs(player.GetAll()) do
										if (!PL:HasAssLevel(ASS_LVL_TEMPADMIN) && (PL != LocalPlayer() || includeSelf)) then
											table.insert(List, PL)
										end
									end
									ASS_PCallError( FUNCTION, NEWMENU, List, unpack(arg))
								end ):SetImage( "icon16/user.png" )

							ALLMENU:AddSubMenu( "Admins", nil,
								function(NEWMENU)
									local List = {}
									for _, PL in pairs(player.GetAll()) do
										if (PL:HasAssLevel(ASS_LVL_TEMPADMIN) && (PL != LocalPlayer() || includeSelf)) then
											table.insert(List, PL)
										end
									end
									ASS_PCallError( FUNCTION, NEWMENU, List, unpack(arg))
								end ):SetImage( "icon16/user_suit.png" )
						else
						
							ALLMENU:AddOption( "Players", 
								function()
									local res = nil
									for _, PL in pairs(player.GetAll()) do
										if (PL != LocalPlayer() || includeSelf) then
											local err,res2 = ASS_PCallError( FUNCTION, PL, unpack(arg))
											res = res || res2
										end
									end
									return res
								end ):SetImage( "icon16/group.png" )
							ALLMENU:AddOption( "Non-Admins", 
								function()
									local res = nil
									for _, PL in pairs(player.GetAll()) do
										if (!PL:HasAssLevel(ASS_LVL_TEMPADMIN) && (PL != LocalPlayer() || includeSelf)) then
											local err,res2 = ASS_PCallError( FUNCTION, PL, unpack(arg))
											res = res || res2
										end
									end
									return res
								end ):SetImage( "icon16/user.png" )
							ALLMENU:AddOption( "Admins", 
								function()
									local res = nil
									for _, PL in pairs(player.GetAll()) do
										if (PL:HasAssLevel(ASS_LVL_TEMPADMIN) && (PL != LocalPlayer() || includeSelf)) then
											local err,res2 = ASS_PCallError( FUNCTION, PL, unpack(arg))
											res = res || res2
										end
									end
									return res
								end ):SetImage( "icon16/user_suit.png" )
						
						end
					end ):SetImage( "icon16/group.png" )
		else
		
			if (includeSubMenus) then
			
				SUBMENU:AddSubMenu( "All Non-Admins", nil,
					function(NEWMENU)
						local List = {}
						for _, PL in pairs(player.GetAll()) do
							if (!PL:HasAssLevel(ASS_LVL_TEMPADMIN)) then
								table.insert(List, PL)
							end
						end
						ASS_PCallError( FUNCTION, NEWMENU, List, unpack(arg))
					end ):SetImage( "icon16/user.png" )

			else
			
				SUBMENU:AddOption( "All Non-Admins", 
					function()
						local res = nil
						for _, PL in pairs(player.GetAll()) do
							if (!PL:HasAssLevel(ASS_LVL_TEMPADMIN)) then
								local err, res2 = ASS_PCallError( FUNCTION, PL, unpack(arg))
								res = res or res2
							end
						end
						return res
					end ):SetImage( "icon16/user.png" )
					
			end

		end

		NumOptions = NumOptions + 1
	
		if (includeSelf) then
			SUBMENU:AddSpacer()
		end
		
	end

	if (includeSelf) then
		if (includeSubMenus) then
			SUBMENU:AddSubMenu( LocalPlayer():Nick(), nil, function(NEW_SUBMENU) ASS_PCallError( FUNCTION, NEW_SUBMENU, LocalPlayer(), unpack(arg) ) end ):SetImage(ASS_RANKS[LocalPlayer():GetAssLevel()].Icon)
		else
			SUBMENU:AddOption( LocalPlayer():Nick(), function() local err,res = ASS_PCallError( FUNCTION, LocalPlayer(), unpack(arg)) return res end ):SetImage(ASS_RANKS[LocalPlayer():GetAssLevel()].Icon)
		end
		NumOptions = NumOptions + 1
	end
	
	for idx,ply in pairs(others) do
		
		if (ply != LocalPlayer()) then		
			if (NumOptions == 1 && (includeSelf || includeAll || includeAllSO)) then
				SUBMENU:AddSpacer()
			end
			if (includeSubMenus) then
				SUBMENU:AddSubMenu( ply:Nick(), nil, function(NEW_SUBMENU) ASS_PCallError( FUNCTION, NEW_SUBMENU, ply, unpack(arg) ) end ):SetImage(ASS_RANKS[ply:GetAssLevel()].Icon)
			else
				SUBMENU:AddOption( ply:Nick(), function() local err,res = ASS_PCallError( FUNCTION, ply, unpack(arg)) return res end ):SetImage(ASS_RANKS[ply:GetAssLevel()].Icon)
			end
			NumOptions = NumOptions + 1
		end
		
	end
	
	if (NumOptions == 0) then
		SUBMENU:AddOption( "(none)", function() end )
	end
	
end

function ASS_Plugins( SUBMENU )
	ASS_RunPluginFunction("AddMenu", nil, SUBMENU )

	if (#SUBMENU:GetCanvas():GetChildren() == 0) then
		SUBMENU:AddOption("(none)", function() end)		
	end	
end

function ASS_Gamemodes( SUBMENU )
	local function CheckGamemode(PLUGIN)
		return PLUGIN.Gamemodes != nil and #PLUGIN.Gamemodes > 0 and ASS_PluginCheckGamemode(PLUGIN.Gamemodes)
	end

	ASS_RunPluginFunctionFiltered("AddGamemodeMenu", CheckGamemode, nil, SUBMENU )
	
	if (#SUBMENU:GetCanvas():GetChildren() == 0) then
		SUBMENU:AddOption("(none)", function() end)		
	end
end

function ASS_Settings( SUBMENU )
	if (LocalPlayer():HasAssLevel(ASS_LVL_SERVER_OWNER)) then
		
		SUBMENU:AddSubMenu("Client Notifications", nil, function(MENU)
			local Items = {}
			Items[1] = MENU:AddOption("Yes", function() net.Start('ass_clienttell') net.WriteBool(true) net.SendToServer() end )
			Items[0] = MENU:AddOption("No",	function() net.Start('ass_clienttell') net.WriteBool(false) net.SendToServer() end )
		
			local Mode = GetGlobalBool("ASS_ClientTell") and 1 or 0
			if (Items[Mode]) then
				Items[Mode]:SetImage("icon16/tick.png")
			end
		end):SetImage("icon16/user_comment.png")
		
		ASS_RunPluginFunction("AddSetting", nil, SUBMENU )
		
		SUBMENU:AddSpacer()
	end
	
	SUBMENU:AddOption( "Clear Config", function() ASS_Config = table.Copy(ASS_DefaultConfig) ASS_WriteConfig() end):SetImage("icon16/page_delete.png")
end

function ASS_Rcon(TEXT)
	net.Start("ass_rcon")
		net.WriteString(TEXT)
	net.SendToServer()
end

function ASS_RconEntry(MENUITEM)
	PromptStringRequest( "Remote Command...", 
		"What command do you want to execute?", 
		"", 
		function( TEXT ) 
			local found = false
			for k,v in pairs(ASS_Config["rcon"]) do
				if (string.lower(v.cmd) == string.lower(TEXT)) then
					found = true
					break
				end
			end
			
			if (!found) then
				table.insert(ASS_Config["rcon"], { cmd=TEXT } )
				ASS_WriteConfig()
			end
			
			ASS_Rcon(TEXT)
		end 
	)	
end

function ASS_RconMenu( MENU )
	MENU:AddOption( "Custom...", ASS_RconEntry )
	MENU:AddSpacer()
	for k,v in pairs(ASS_Config["rcon"]) do
		MENU:AddOption( v.cmd, function(MENUITEM) ASS_Rcon(v.cmd) end )
	end
end

function ASS_ShowUnbanList()
	local tblbans = net.ReadTable()
	for k,v in pairs(tblbans) do
		name = v.Name .. " (" .. util.SteamIDFrom64(k) .. ") *"..v.AdminName.."*"
		table.insert( ASS_BannedPlayers, {Text = name, ID = k} )
	end
	PromptForChoice( "Unban a player...", ASS_BannedPlayers, 
		function (DLG, ITEM)
			
			net.Start('ass_unbanplayer') net.WriteString(ITEM.ID) net.SendToServer()
			DLG:RemoveItem(DLG.Selection)
		
		end
	)
	
	ASS_BannedPlayers = nil
end

function ASS_UnbanMenu( MENUITEM )
	ASS_BannedPlayers = {}
	net.Start('ass_unbanlist') net.SendToServer()
end

local IconsLoaded = {}
function ASS_Icon( img )
	if (IconsLoaded[img]) then
		return IconsLoaded[img]
	end
	IconsLoaded[img] = Material(img)
	return IconsLoaded[img]
end

function ASS_ShowMenu()
	local MENU = DermaMenu()
	ASS_FixMenu(MENU)
	
	if (!LocalPlayer():HasAssLevel(ASS_LVL_TEMPADMIN)) then	
		MENU:AddSubMenu("Settings", nil, ASS_Settings ):SetImage( "icon16/wrench.png" )
		MENU:AddSpacer()
		
		ASS_RunPluginFunction("AddNonAdminMenu", nil, MENU )
		
		if (#MENU:GetCanvas():GetChildren() == 0) then
			return	
		end	
	else
		local GamemodeImage = "icon16/sport_soccer.png"
		if (GAMEMODE.ASS_MenuIcon) then
			GamemodeImage = GAMEMODE.ASS_MenuIcon
		end
		
		MENU:AddSubMenu("Set Access", nil, function(NEWMENU) ASS_PlayerMenu(NEWMENU, { "HasSubMenu", "IncludeLocalPlayer" }, ASS_AccessMenu ) end ):SetImage( "icon16/key.png" )
		MENU:AddSubMenu("Kick", nil, function(NEWMENU) ASS_PlayerMenu(NEWMENU, { "HasSubMenu", "IncludeLocalPlayer" }, ASS_KickReasonMenu ) end ):SetImage( "icon16/error.png" )
		MENU:AddSubMenu("Ban", nil, function(NEWMENU) ASS_PlayerMenu(NEWMENU, { "HasSubMenu", "IncludeLocalPlayer" }, ASS_BanTimeMenu ) end ):SetImage( "icon16/delete.png" )
		MENU:AddOption("Unban...", ASS_UnbanMenu ):SetImage( "icon16/add.png" )
		MENU:AddSpacer()
		MENU:AddSubMenu("Rcon", nil, ASS_RconMenu ):SetImage( "icon16/application_osx_terminal.png" )
		MENU:AddSpacer()
		MENU:AddSubMenu("Settings", nil, ASS_Settings ):SetImage( "icon16/wrench.png" )
		MENU:AddSpacer()
		MENU:AddSubMenu("Plugins", nil, ASS_Plugins ):SetImage( "icon16/bricks.png" )
		MENU:AddSubMenu( GAMEMODE.Name, nil, ASS_Gamemodes ):SetImage(GamemodeImage)

		ASS_RunPluginFunction("AddMainMenu", nil, MENU )
	end
	
	MENU:Open( 100, 100 )
	ASS_MenuShowing = true
	timer.Simple( 0, function() gui.SetMousePos(110, 110) end )
	
	ASS_Debug( "menu opened\n")
end

function ASS_HideMenu()
	CloseDermaMenus()
	ASS_Debug( "menu hiding\n")
	ASS_MenuShowing = false
end

function ASS_Initialize()
	if (ASS_Initialized) then return end

	concommand.Add("+ASS_Menu", ASS_ShowMenu)
	concommand.Add("-ASS_Menu", ASS_HideMenu)
	
	ASS_Init_Shared()
	net.Start('ass_initialize') net.SendToServer()
	
	ASS_Initialized = true
end
net.Receive('ass_initialize', ASS_Initialize)	
net.Receive('ass_unbanlist', ASS_ShowUnbanList)	

hook.Add("Initialize", "ASS_Initialize", ASS_LoadPlugins)
hook.Add("ChatText", "ASS_JoinLeaveSupress", function(pl,nick,txt,mtype) if mtype == "joinleave" then return true end end)