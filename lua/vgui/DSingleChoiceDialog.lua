
PANEL = {}

function PANEL:Init()

	self.List = vgui.Create("DPanelList", self)
	self.List:EnableVerticalScrollbar()
	self.List:SetPaintBackground(true)
	self.List:SetPadding(4)
	self.List:SetSpacing(1)
	self.List.Paint = function(w,h)
		draw.RoundedBox( 4, 0, 0, self.List:GetWide(), self.List:GetTall(), Color( 220, 220, 220, 255 ) )
		derma.SkinHook( "Paint", "PanelList", self.List, w, h )
	end

	self.CancelButton = vgui.Create("DButton", self)
	self.CancelButton:SetText("Cancel")
	self.CancelButton.DoClick = function(BTN) self:Close() end

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

	self.List:SetTall(200)
	
	self.CancelButton:SizeToContents()
	self.CancelButton:SetWide(self.CancelButton:GetWide() + 16)
	self.CancelButton:SetTall(self.CancelButton:GetTall() + 8)

	local height = 32
		
		height = height + self.List:GetTall()
		height = height + 8
		height = height + self.CancelButton:GetTall()
		height = height + 8

	self:SetTall(height)
	
	local width = self:GetWide()

	self.List:SetPos( 8, 32 )
	self.List:SetWide( width - 16 )
	
	local btnY = 32 + self.List:GetTall() + 8
	self.CancelButton:SetPos( width - 8 - self.CancelButton:GetWide(), btnY )
end

function PANEL:RemoveItem(BTN)
	self.List:RemoveItem(BTN)
	self:PerformLayout()
end

derma.DefineControl( "DSingleChoiceDialog", "A simple list dialog", PANEL, "DFrame" )

function PromptForChoice( TITLE, SELECTION, FUNCTION, ... )

	local arg = {...}

	local TE = vgui.Create("DSingleChoiceDialog")
	TE:SetBackgroundBlur( true )
	TE:SetDrawOnTop( true )
	for k,v in pairs(SELECTION) do
		local item = vgui.Create("DButton")
		item:SetText( v.Text )
		item.DoClick = 
			function(BTN) 
				TE.Selection = item
				PCallError( FUNCTION, TE, v, unpack(arg) )
			end

		TE.List:AddItem(item)
	end
	TE:SetTitle(TITLE)
	TE:SetVisible( true )
	TE:SetWide(300)
	TE:PerformLayout()
	TE:Center()
	TE:MakePopup()

end


concommand.Add("list_entry_test", 
		function()
		
			local test_items = {
				{	Text = "Hello", 	OtherData = 12		},
				{	Text = "Hello 2", 	OtherData = 113		},
				{	Text = "Hello 3", 	OtherData = "A"		},
				{	Text = "Hello 4", 	OtherData = "Ban"	},
								{	Text = "Hello", 	OtherData = 12		},
				{	Text = "Hello 2", 	OtherData = 113		},
				{	Text = "Hello 3", 	OtherData = "A"		},
				{	Text = "Hello 4", 	OtherData = "Ban"	},
								{	Text = "Hello", 	OtherData = 12		},
				{	Text = "Hello 2", 	OtherData = 113		},
				{	Text = "Hello 3", 	OtherData = "A"		},
				{	Text = "Hello 4", 	OtherData = "Ban"	},
								{	Text = "Hello", 	OtherData = 12		},
				{	Text = "Hello 2", 	OtherData = 113		},
				{	Text = "Hello 3", 	OtherData = "A"		},
				{	Text = "Hello 4", 	OtherData = "Ban"	},
								{	Text = "Hello", 	OtherData = 12		},
				{	Text = "Hello 2", 	OtherData = 113		},
				{	Text = "Hello 3", 	OtherData = "A"		},
				{	Text = "Hello 4", 	OtherData = "Ban"	},
			}
		
			PromptForChoice("Select something", test_items,
				function(DLG, ITEM, PARAM)
					Msg("Text is " .. ITEM.Text .. " param is " .. PARAM .. "\n")
					DLG:Close()
				end,
				99
				)
				
			
		end
	)
