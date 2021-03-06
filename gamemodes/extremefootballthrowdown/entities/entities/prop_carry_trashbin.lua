AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "prop_carry_base"

ENT.Name = "Trash Bin"

ENT.IsPropWeapon = true

ENT.Model = Model("models/props_trainstation/trashcan_indoor001b.mdl")
ENT.ThrowForce = 550

ENT.BoneName = "ValveBiped.Bip01_R_Hand"
ENT.AttachmentOffset = Vector(10, 15, 0)
ENT.AttachmentAngles = Angle(90, 0, 90)

function ENT:Initialize()
	self.BaseClass.Initialize(self)

	self.NextTouch = {}
end

function ENT:PrimaryAttack(pl)
	if pl:CanMelee() then
		pl:SetState(STATE_TRASHBINATTACK--[[, STATES[STATE_TRASHBINATTACK].Time]])
	end

	return true
end

function ENT:SecondaryAttack(pl)
	if pl:CanThrow() then
		pl:SetState(STATE_THROW)
	end

	return true
end

function ENT:Move(pl, move)
	move:SetMaxSpeed(move:GetMaxSpeed() * 0.75)
	move:SetMaxClientSpeed(move:GetMaxClientSpeed() * 0.75)
end

function ENT:GetImpactSpeed()
	return self:GetLastCarrier():IsValid() and 200 or 450
end


function ENT:RefreshBoneName()
	local carrier = self:GetCarrier()
	self.BoneName = carrier:IsValid() and carrier:IsPlayer() and carrier:GetState() == STATE_TRASHBINATTACK and "ValveBiped.Bip01_L_Hand" or "ValveBiped.Bip01_R_Hand"
end

if CLIENT then

function ENT:OnThink()
	self:RefreshBoneName()
end

return

end

function ENT:OnThink()
	self:RefreshBoneName()

	if self.PhysicsData then
		self:HitObject(self.PhysicsData.HitPos, self.PhysicsData.HitNormal, self.PhysicsData.HitEntity)
	elseif self.TouchedEnemy then
		self:HitObject(nil, nil, self.TouchedEnemy)
	end
end

function ENT:PhysicsCollide(data, phys)
	if data.Speed >= self:GetImpactSpeed() then
		self.PhysicsData = data
		self:NextThink(CurTime())
	end
end

function ENT:HitObject(hitpos, hitnormal, hitent)
	self.PhysicsData = nil
	self.TouchedEnemy = nil

	self:NextThink(CurTime())

	hitpos = hitpos or self:GetPos()
	hitnormal = hitnormal or Vector(0, 0, 1)

	if IsValid(hitent) and hitent:IsPlayer() and hitent:Team() ~= self:GetLastCarrierTeam() then
		hitent:EmitSound("physics/body/body_medium_impact_hard"..math.random(6)..".wav")
		hitent:ThrowFromPosition(hitpos + Vector(0, 0, -24), math.Clamp(self:GetVelocity():Length() * 1.2, 350, 750), true, self:GetLastCarrier())
		hitent:TakeDamage(20, self:GetLastCarrier(), self)
	end

	self:EmitSound("physics/metal/metal_canister_impact_hard"..math.random(3)..".wav")
end

function ENT:OnTouch(ent)
	if ent:IsPlayer() and ent:Alive() and self:GetVelocity():Length() >= self:GetImpactSpeed() and ent:Team() ~= self:GetLastCarrierTeam() and CurTime() >= (self.NextTouch[ent] or 0) then
		self.NextTouch[ent] = CurTime() + 0.5
		self.TouchedEnemy = ent
	end
end
