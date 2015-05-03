surface.CreateFont("NoticePanelFont", {size = 16, weight = 800, antialias = true, font = "Tahoma"})

PANEL = {}

function PANEL:AddNotice(NAME, TEXT, DURATION)
	
	for k,v in pairs(self.Notices) do
	
		if (v.Name && v.Name == NAME) then
			v.Text = TEXT
			v.Duration = DURATION
			return
		end
	
	end
	
	table.insert( self.Notices, { Name = NAME, Text = TEXT, Duration = DURATION } );
	if (#self.Notices == 1) then
		self.NoticeExpiry = CurTime()
		self.CurrentNotice = 0
	end
	
end

function PANEL:RemoveNotice(NAME)
	for k,v in pairs(self.Notices) do
		if (v.Name == NAME) then
			table.remove(self.Notices, k)
			return
		end
	end
end

function PANEL:Init()
	self.m_bBackground = true
	self.CurrentNotice = 0
	self.NoticeExpiry = 0
	self.Notices = {}
	
	self.Info = vgui.Create("DLabel", self)
	self.Info:SetFont("NoticePanelFont")

	self:SetAlpha(0)
	self.animFade = Derma_Anim( "Fade", self, self.Fade )
end

function PANEL:PerformLayout()
	
	self:SetPos(0,0)
	self.Info:SizeToContents()
	self.Info:SetPos( 8, 4 )
	self:SetTall( self.Info:GetTall() + 8 )

	local wid = 0	
	if (self.CountDownPanel) then
		wid = self.CountDownPanel:GetWide() + 2
	end
	
	if wid > 2 then
		self:SetWide( ScrW() - wid )
	else
		self:SetWide( ScrW() )
	end
end

function PANEL:Fade(anim, delta, data)
	
	if ( anim.Finished ) then
	
		if (data.Out) then
			self:SetAlpha( 0 )
			self.CurrentNotice = 0
		else
			self:SetAlpha( 255 )
		end
		
		return 
		
	end

	if (data.Out) then
		self:SetPos( 0 - (self:GetTall() * delta) )
	else
		self:SetAlpha( (delta * 255) )
	end
	
end

function PANEL:Think()

	if ((CurTime() >= self.NoticeExpiry || self.CurrentNotice > #self.Notices) && #self.Notices > 0) then
	
		if (self.CurrentNotice + 1 > #self.Notices) then
			self.NoticeExpiry = CurTime() + 30
			self.animFade:Start( 0.5, { Out = true } )
		else
			if (self.CurrentNotice == 0) then
				self.animFade:Start( 0.5, { In = true } )
			end
			
			self.CurrentNotice = self.CurrentNotice + 1
			self.NoticeExpiry = CurTime() + self.Notices[self.CurrentNotice].Duration or 10
			self:InvalidateLayout()
		end	

	end
	
	if (self.CurrentNotice != 0 && self.Notices[self.CurrentNotice]) then
		self.Info:SetText( ASS_FormatText( self.Notices[self.CurrentNotice].Text ) )
		self:InvalidateLayout()
	end
	
	self.animFade:Run()

end

function PANEL:ApplySchemeSettings()

end

function PANEL:GetDrawColumn()
	return false
end

function PANEL:Paint(w, h)

	self.Info:SetFGColor( 40, 40, 40, 255 )

	derma.SkinHook( "Paint", "Menu", self, w, h)
	derma.SkinHook( "PaintOver", "Menu", self )
	
end

derma.DefineControl( "DNoticePanel", "Notice panel", PANEL, "Panel" )
