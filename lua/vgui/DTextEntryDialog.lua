--Lets create a dupe of Derma_StringRequest until garry fixes the text color in it..

function PromptStringRequest( strTitle, strText, strDefaultText, fnEnter, fnCancel, strButtonText, strButtonCancelText )

	local Window = vgui.Create( "DFrame" )
		Window:SetTitle( strTitle or "Message Title (First Parameter)" )
		Window:SetDraggable( false )
		Window:ShowCloseButton( false )
		Window:SetBackgroundBlur( true )
		Window:SetDrawOnTop( true )
		
	local InnerPanel = vgui.Create( "DPanel", Window )
	
	local Text = vgui.Create( "DLabel", InnerPanel )
		Text:SetText( strText or "Message Text (Second Parameter)" )
		Text:SizeToContents()
		Text:SetContentAlignment( 5 )
		Text:SetTextColor( Color( 70, 70, 70, 255 ) )
		
	local TextEntry = vgui.Create( "DTextEntry", InnerPanel )
		TextEntry:SetText( strDefaultText or "" )
		TextEntry.OnEnter = function() Window:Close() fnEnter( TextEntry:GetValue() ) end
		
	local ButtonPanel = vgui.Create( "DPanel", Window )
	ButtonPanel:SetTall( 30 )
		
	local Button = vgui.Create( "DButton", ButtonPanel )
		Button:SetText( strButtonText or "OK" )
		Button:SizeToContents()
		Button:SetTall( 20 )
		Button:SetWide( Button:GetWide() + 20 )
		Button:SetPos( 5, 5 )
		Button.DoClick = function() Window:Close() fnEnter( TextEntry:GetValue() ) end
		
	local ButtonCancel = vgui.Create( "DButton", ButtonPanel )
		ButtonCancel:SetText( strButtonCancelText or "Cancel" )
		ButtonCancel:SizeToContents()
		ButtonCancel:SetTall( 20 )
		ButtonCancel:SetWide( Button:GetWide() + 20 )
		ButtonCancel:SetPos( 5, 5 )
		ButtonCancel.DoClick = function() Window:Close() if ( fnCancel ) then fnCancel( TextEntry:GetValue() ) end end
		ButtonCancel:MoveRightOf( Button, 5 )
		
	ButtonPanel:SetWide( Button:GetWide() + 5 + ButtonCancel:GetWide() + 10 )
	
	local w, h = Text:GetSize()
	w = math.max( w, 400 ) 
	
	Window:SetSize( w + 50, h + 25 + 75 + 10 )
	Window:Center()
	
	InnerPanel:StretchToParent( 5, 25, 5, 45 )
	
	Text:StretchToParent( 5, 5, 5, 35 )	
	
	TextEntry:StretchToParent( 5, nil, 5, nil )
	TextEntry:AlignBottom( 5 )
	
	TextEntry:RequestFocus()
	TextEntry:SelectAllText( true )
	
	ButtonPanel:CenterHorizontal()
	ButtonPanel:AlignBottom( 8 )
	
	Window:MakePopup()
	Window:DoModal()
	return Window

end

-- This never got used in Assmod anyways..
--[[
PANEL = {}

function PANEL:Init()

	self.Text = vgui.Create("DTextEntry", self)
	
	self.OkButton = vgui.Create("DButton", self)
	self.OkButton:SetText("Ok")
	self.OkButton.DoClick = function(BTN) PCallError( self.OnOk, self, self.Text:GetValue(), unpack(self.Params) ) end
	
	self.CancelButton = vgui.Create("DButton", self)
	self.CancelButton:SetText("Cancel")
	self.CancelButton.DoClick = function(BTN) self:Close() end

end

function PANEL:PerformLayout()

	derma.SkinHook( "Layout", "Frame", self )

	self.Text:SetTall(18)
	self.OkButton:SizeToContents()
	self.CancelButton:SizeToContents()
	if (self.OkButton:GetWide() + 16 > self.CancelButton:GetWide() + 16) then
		self.OkButton:SetWide(self.OkButton:GetWide() + 16)
		self.CancelButton:SetWide(self.OkButton:GetWide() + 16)
	else
		self.OkButton:SetWide(self.CancelButton:GetWide() + 16)
		self.CancelButton:SetWide(self.CancelButton:GetWide() + 16)
	end
	if (self.OkButton:GetTall() + 8 > self.CancelButton:GetTall() + 8) then
		self.OkButton:SetTall(self.OkButton:GetTall() + 8)
		self.CancelButton:SetTall(self.OkButton:GetTall() + 8)
	else
		self.OkButton:SetTall(self.CancelButton:GetTall() + 8)
		self.CancelButton:SetTall(self.CancelButton:GetTall() + 8)
	end	
	local height = 32
		
		height = height + self.Text:GetTall()
		height = height + 8
		height = height + self.OkButton:GetTall()
		height = height + 8

	self:SetTall(height)
	
	local width = self:GetWide()

	self.Text:SetPos( 8, 32 )
	self.Text:SetWide( width - 16 )
	
	local btnY = 32 + self.Text:GetTall() + 8
	self.OkButton:SetPos( width - 8 - self.CancelButton:GetWide() - 8 - self.OkButton:GetWide(), btnY )
	self.CancelButton:SetPos( width - 8 - self.CancelButton:GetWide(), btnY )
end

derma.DefineControl( "DTextEntryDialog", "A simple text entry dialog", PANEL, "DFrame" )

function PromptForText( TITLE, DEFAULT, FUNCTION, ... )

	local TE = vgui.Create("DTextEntryDialog")
	TE.Text:SetText( DEFAULT or "" )
	TE.OnOk = FUNCTION
	TE.Params = arg
	TE:SetTitle(TITLE)
	TE:SetVisible( true )
	TE:SetWide(300)
	TE:PerformLayout()
	TE:Center()
	TE:MakePopup()
			
end


concommand.Add("text_entry_test", 
		function()
		
			PromptForText("Put some text", "Hello",
				function(DLG, TEXT, PARAM)
					Msg("Text is " .. TEXT .. " param is " .. PARAM .. "\n")
					DLG:Close()
				end,
				10
				)
				
			
		end
	)
]]