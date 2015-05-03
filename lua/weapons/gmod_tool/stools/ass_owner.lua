
TOOL.Category		= "Assmod"
TOOL.Name		= "#tool.ass_owner.name"
TOOL.Command		= nil
TOOL.ConfigName		= ""

// Add Default Language translation (saves adding it to the txt files)
if ( CLIENT ) then

	language.Add( "tool.ass_owner.name", "Set Owner" )
	language.Add( "tool.ass_owner.desc", "Set's the owner of an item for Assmod prop protection" )
	language.Add( "tool.ass_owner.0", "Left click to take ownership, Right click to release ownership" )
	
end

function TOOL:LeftClick( trace )
	if !trace.Entity then return false end
	if !trace.Entity:IsValid() then return false end
	if trace.Entity:IsPlayer() then return false end
	if CLIENT then return true end
	if !ASS_PP_GetOwner || !ASS_PP_SetOwner || !ASS_MessagePlayer then return false end
	
	local owner = ASS_PP_GetOwner( trace.Entity )
	
	if (owner:IsValid()) then
		if (owner != self:GetOwner()) then
			ASS_MessagePlayer(self:GetOwner(),"Item is already owned by " .. owner:Nick() )
		else
			ASS_MessagePlayer(self:GetOwner(),"You already own this item!" )
		end
		return false
	end
	
	ASS_PP_SetOwner(self:GetOwner(),trace.Entity )
	ASS_MessagePlayer(self:GetOwner(),"You now own this item" )
		
	return true
end

function TOOL:RightClick( trace )
	if !trace.Entity then return false end
	if !trace.Entity:IsValid() then return false end
	if trace.Entity:IsPlayer() then return false end
	if CLIENT then return true end
	if !ASS_PP_GetOwner || !ASS_PP_SetOwner || !ASS_MessagePlayer then return false end
	
	local owner = ASS_PP_GetOwner( trace.Entity )
	
	if (owner != self:GetOwner() && owner:IsValid() ) then
		ASS_MessagePlayer(self:GetOwner(),"You do not own this item" )
		return false
	end
	
	ASS_PP_SetOwner(NullEntity(), trace.Entity )
	ASS_MessagePlayer(self:GetOwner(),"Item is now not owned" )
		
	return true
end

function TOOL.BuildCPanel( CPanel )

	// HEADER
	CPanel:AddControl( "Header", { Text = "#Tool_ass_owner_name", Description	= "#Tool_ass_owner_desc" }  )

end
