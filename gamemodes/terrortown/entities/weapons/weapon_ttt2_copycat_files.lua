--Models, icons, and some code taken from [TTT/2] Petition (https://steamcommunity.com/sharedfiles/filedetails/?id=1947794080)
if SERVER then
	AddCSLuaFile()
end

if CLIENT then	
	SWEP.PrintName = "Copycat Files"
	SWEP.Author = "BlackMagicFine"
	SWEP.Contact = "https://steamcommunity.com/profiles/76561198025772353/"
	
	SWEP.ViewModelFOV = 70
	SWEP.ViewModelFlip = false
	
	SWEP.Icon = "vgui/ttt/icon_copycat_files.png"
	SWEP.EquipMenuData = {
		type = "item_weapon",
		name = "CCFILES_NAME_" .. COPYCAT.name,
		desc = "CCFILES_DESC_" .. COPYCAT.name
	}
end

SWEP.Base = "weapon_tttbase"
SWEP.Kind = WEAPON_EXTRA

SWEP.DrawAmmo = false
SWEP.Spawnable = false
SWEP.DrawCrosshair = false
SWEP.AllowDrop = false
SWEP.UseHands = false

SWEP.HoldType = "pistol"

SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false

--Gun stats
SWEP.Primary.Delay = 0.5
SWEP.Primary.Recoil = 6
SWEP.Primary.Automatic = false
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Secondary = SWEP.Primary
SWEP.Delay = 0.5

--Misc.
SWEP.InLoadoutFor = nil
SWEP.CanBuy = {}
SWEP.IsSilent = false
SWEP.NoSights = false
SWEP.LimitedStock = true
SWEP.globalLimited = true
SWEP.NoRandom = true
SWEP.notBuyable = true

--Model
SWEP.ViewModel = "models/weapons/v_pistol.mdl"
SWEP.WorldModel = "models/copycat_files/weapons/clipboard.mdl"

function SWEP:Initialize()
	self:SetHoldType("pistol")

	if SERVER then
		return
	end

	self.clipboard = ClientsideModel(self.WorldModel)
	self.clipboard:SetNoDraw(true)
end

function SWEP:OnRemove()
	self:SetHoldType("pistol")

	if SERVER then
		return
	end

	if (self.clipboard and self.clipboard:IsValid()) then
		self.clipboard:Remove()
	end
end

function SWEP:OnDrop()
	self:Remove()
end

function SWEP:PreDrawViewModel(vm, wep, ply)
	render.SetBlend(0)
end

function SWEP:PostDrawViewModel(vm, wep, ply)
	render.SetBlend(1)

	local model = self.clipboard
	local bone_pos, bone_angle = vm:GetBonePosition(vm:LookupBone("ValveBiped.base"))

	model:SetPos(bone_pos + bone_angle:Up()*-9 + bone_angle:Forward()*-1 + bone_angle:Right()*-1.5)
	bone_angle:RotateAroundAxis(bone_angle:Up(), -90)
	bone_angle:RotateAroundAxis(bone_angle:Forward(), 200)
	bone_angle:RotateAroundAxis(bone_angle:Right(), 10)
	model:SetAngles(bone_angle)
	model:SetupBones()

	model:DrawModel()
end

function SWEP:DrawWorldModel()
	local ply = self:GetOwner()
	local model = self.clipboard
	
	local bone_index = ply:LookupBone("ValveBiped.Bip01_R_Hand")
	local bone_pos, bone_angle
	
	if bone_index then
		bone_pos, bone_angle = ply:GetBonePosition(bone_index)
	end
	
	model:SetPos(bone_index and (bone_pos + bone_angle:Up()*-1 + bone_angle:Forward()*4.4 + bone_angle:Right()*6 ) or ply:GetPos())
	if bone_index then
		bone_angle:RotateAroundAxis(bone_angle:Up(), 180)
		bone_angle:RotateAroundAxis(bone_angle:Forward(), 180)
		bone_angle:RotateAroundAxis(bone_angle:Right(), -70)
		
		model:SetAngles(bone_angle)
	end
	
	model:SetupBones()
	model:DrawModel()
end

function SWEP:PrimaryAttack()
	if CLIENT then
		return
	end
	
	COPYCAT_DATA.SendCopycatFilesToClient(self:GetOwner())
	
	self:SetNextPrimaryFire(CurTime() + self.Delay)
end

function SWEP:SecondaryAttack()
	if CLIENT then
		return
	end
	
	self:PrimaryAttack()
end

function SWEP:Reload()

end