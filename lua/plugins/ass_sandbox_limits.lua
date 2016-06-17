
local PLUGIN = {}

PLUGIN.Name = "Sandbox Limits"
PLUGIN.Author = "Andy Vincent"
PLUGIN.Date = "10th September 2007"
PLUGIN.Filename = PLUGIN_FILENAME
PLUGIN.ClientSide = true
PLUGIN.ServerSide = true
PLUGIN.APIVersion = 2.3
PLUGIN.Gamemodes = { "sandbox" } // only load this plugin for sandbox and it's derivatives

if (SERVER) then

	local SandboxVars = {
		{	text = "#SBoxMaxProps",		var = "sbox_maxprops"		},
		{	text = "#SBoxMaxRagdolls",	var = "sbox_maxragdolls"	},
		{	text = "#SBoxMaxVehicles",	var = "sbox_maxvehicles"	},
		{	text = "#SBoxMaxEffects",	var = "sbox_maxeffects"		},
		{	text = "#SBoxMaxBalloons",	var = "sbox_maxballoons"	},
		{	text = "#SBoxMaxNPCs",		var = "sbox_maxnpcs"		},
		{	text = "#SBoxMaxSENTs",		var = "sbox_maxsents"		},
		{	text = "#SBoxMaxDynamite",	var = "sbox_maxdynamite"	},
		{	text = "#SBoxMaxLamps",		var = "sbox_maxlamps"		},
		{	text = "#SBoxMaxWheels",	var = "sbox_maxwheels"		},
		{	text = "#SBoxMaxThrusters",	var = "sbox_maxthrusters"	},
		{	text = "#SBoxMaxHoverBalls",	var = "sbox_maxhoverballs"	},
		{	text = "#SBoxMaxButtons",	var = "sbox_maxbuttons"		},
		{	text = "#SBoxMaxEmitters",	var = "sbox_maxemitters"	},
		{	text = "#SBoxMaxSpawners",	var = "sbox_maxspawners"	},
		{	text = "#SBoxMaxTurrets",	var = "sbox_maxturrets"		},
	}

	table.sort(SandboxVars, function(a, b)
			return tostring(a.text) < tostring(b.text)
	end);
	
	ASS_NewLogLevel("ASS_ACL_SANDBOX")

	// Initialize
	for k,v in pairs(SandboxVars) do
		umsg.PoolString(v.text)
		umsg.PoolString(v.var)
	end
	
	function PLUGIN.RetrieveLimits( PLAYER, CMD, ARGS )
		for k,v in pairs(SandboxVars) do
			umsg.Start( "ASS_SandBoxLimit", PLAYER )
			
				umsg.String(	v.text			)
				umsg.String(	v.var			)
				umsg.String(	GetConVarString(v.var)	)
			
			umsg.End()
		end

		umsg.Start( "ASS_SandBoxLimitGUI", PLAYER )
		umsg.End()

	end
	concommand.Add("ASS_SandboxRetrieveLimits", PLUGIN.RetrieveLimits)

	function PLUGIN.ChangeLimit( PLAYER, CMD, ARGS )
	
		if (PLAYER:HasAssLevel(ASS_LVL_SUPER_ADMIN)) then
		
			if (!ARGS[1] || !ARGS[2]) then
				ASS_MessagePlayer( PLAYER, "Error!\n")
				return
			end
		
			ASS_LogAction( PLAYER, ASS_ACL_SANDBOX, "changed " .. ARGS[1] .. " from " .. GetConVarString(ARGS[1]) .. " to " .. ARGS[2] )
			
			game.ConsoleCommand( ARGS[1] .. " " .. ARGS[2] .. "\n" )
		
		else

			ASS_MessagePlayer( PLAYER, "Access denied!")

		end
	
	end
	concommand.Add("ASS_SandboxChangeLimit", PLUGIN.ChangeLimit)

end

if (CLIENT) then

	local SandboxVars = { }
		
////////////////////////////////////////////////////////////////////////////////////
// DConVarEditLine
////////////////////////////////////////////////////////////////////////////////////

	PANEL = {}

	function PANEL:Init()

		self.Label = vgui.Create("DLabel", self)
		self.Value = vgui.Create("DTextEntry", self)

	end

	function PANEL:Setup( text, cmd, val )
	
		self.Label:SetText(text)
		self.Label:SetColor(Color( 20, 20, 20, 255 ))
		self.Value:SetText(val)
		self.InitialValue = val
		self.Command = cmd
	
	end
	
	function PANEL:PerformLayout()

		derma.SkinHook( "Layout", "Panel", self )
		
		self.Label:SizeToContents()
		self.Label:SetPos( self:GetWide() - 50 - 4 -self.Label:GetWide() - 4, 8)
		
		self.Value:SetWide(50)
		self.Value:SetPos(self:GetWide() - 50 - 4, 4)
		
	end

	derma.DefineControl( "DConVarEditLine", "Convar edit line", PANEL, "Panel" )
	
////////////////////////////////////////////////////////////////////////////////////
// DChangeLimitsFrame
////////////////////////////////////////////////////////////////////////////////////

	PANEL = {}

	function PANEL:Init()

		self.List = vgui.Create("DPanelList", self)
		self.List:EnableVerticalScrollbar()
		self.List:SetPadding(4)
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
		
		self.Items = {}
		for k,v in pairs(PLUGIN.SandboxVars) do
			self:AddVar( v.text, v.var, v.value )
		end
		
		
	end
	
	function PANEL:AddVar( text, cmd, val )
		
		local item = vgui.Create("DConVarEditLine")
		item:Setup( text, cmd, val )

		self.List:AddItem(item)
		table.insert(self.Items, item)
	
	end
	
	function PANEL:ApplySettings()
		for k,v in pairs(self.Items) do
			local newValue = v.Value:GetValue()
			if (newValue != v.InitialValue) then
				RunConsoleCommand("ASS_SandboxChangeLimit", v.Command, newValue )
				v.InitialValue = newValue
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

	derma.DefineControl( "DChangeLimitsFrame", "Frame to change sandbox limits", PANEL, "DFrame" )
	
////////////////////////////////////////////////////////////////////////////////////
// Plugin Code
////////////////////////////////////////////////////////////////////////////////////

	
	usermessage.Hook( "ASS_SandBoxLimit", function (UMSG)
		
			local v = {}
			v.text = UMSG:ReadString()
			v.var = UMSG:ReadString()
			v.value = UMSG:ReadString()
			table.insert(PLUGIN.SandboxVars, v)
		end )
	
	usermessage.Hook( "ASS_SandBoxLimitGUI", function (UMSG)
			local TE = vgui.Create("DChangeLimitsFrame")
			TE:SetBackgroundBlur( true )
			TE:SetDrawOnTop( true )
			TE:SetTitle("Change Limits...")
			TE:SetVisible( true )
			TE:SetWide(250)
			TE:PerformLayout()
			TE:Center()
			TE:MakePopup()	
			
			PLUGIN.SandboxVars = nil
			
		end )
		
	function PLUGIN.ChangeLimits(MENUITEM)
	
		if (PLUGIN.SandboxVars) then return end
	
		PLUGIN.SandboxVars = {}
		RunConsoleCommand("ASS_SandboxRetrieveLimits")
		return true
		
	end

	function PLUGIN.AddGamemodeMenu(DMENU)			

		DMENU:AddOption( "Limits", PLUGIN.ChangeLimits ):SetImage( "icon16/exclamation.png" )

	end

end

ASS_RegisterPlugin(PLUGIN)
