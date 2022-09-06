if SERVER then
	AddCSLuaFile()
	util.AddNetworkString("TTT2CopycatFilesCorpseUpdate")
end

roles.InitCustomTeam(ROLE.name, {
	icon = "vgui/ttt/dynamic/roles/icon_copy",
	color = Color(152, 70, 211, 255),
	sticky = true
})

function ROLE:PreInitialize()
	self.color = Color(152, 70, 211, 255)
	self.abbr = "copy" -- abbreviation
	
	self.score.teamKillsMultiplier = -16
	self.score.killsMultiplier = 5
	
	self.preventFindCredits = false
	
	self.fallbackTable = {}
	self.unknownTeam = false -- disables team voice chat.
	
	if DOPPELGANGER and GetConVar("ttt2_copycat_on_dop_team"):GetBool() then
		self.defaultTeam = TEAM_DOPPELGANGER
	else
		self.defaultTeam = TEAM_COPYCAT
	end
	self.defaultEquipment = SPECIAL_EQUIPMENT
	
	--The Copycat will always be able to inspect bodies, confirm them, and be called to them.
	--Downside is that I think they are given a hat, similar to Survivalist.
	self.isPolicingRole = true
	
	-- ULX ConVars
	self.conVarData = {
		pct = 0.13,
		maximum = 1,
		minPlayers = 6,
		random = 30,
		traitorButton = 0,
		
		--The Copycat starts with 1 credit, but needs to switch to a shopping role in order to use it
		credits = 1,
		creditsAwardDeadEnable = 1,
		creditsAwardKillEnable = 1,
		shopFallback = SHOP_DISABLED,
		
		togglable = true
	}
end

if SERVER then
	local function ResetCopycatForServer()
		COPYCAT_DATA.ResetCCFilesDataForServer()
		
		for _, ply in ipairs(player.GetAll()) do
			--Don't reset was_copycat at start of round if the player is a copycat, as that will overwrite the logic in GiveRoleLoadout.
			if GetRoundState() == ROUND_POST or ply:GetSubRole() ~= ROLE_COPYCAT then
				ply.was_copycat = nil
			end
		end
	end
	hook.Add("TTTPrepareRound", "TTTPrepareRoundCopycatForServer", ResetCopycatForServer)
	hook.Add("TTTBeginRound", "TTTBeginRoundCopycatForServer", ResetCopycatForServer)
	hook.Add("TTTEndRound", "TTTEndRoundCopycatForServer", ResetCopycatForServer)
	
	function ROLE:GiveRoleLoadout(ply, isRoleChange)
		--The Copycat should hold onto their files for as long as possible, as they are used for role switches.
		--The Copycat will hold onto this item even if they switch roles, as its primary use is to switch roles at will.
		if not ply:HasWeapon("weapon_ttt2_copycat_files") then
			ply:GiveEquipmentWeapon("weapon_ttt2_copycat_files")
		end
		
		--If the Copycat were to switch to a revival role, die, and then revive, they will lose their copycat files unless we remember them.
		--Upon becoming a Copycat, they will remain a Copycat. Unless their team changes. Or the game ends.
		ply.was_copycat = true
	end
	
	hook.Add("PlayerDeath", "PlayerDeathCopycat", function(ply)
		if not ply or not IsValid(ply) or not ply:IsPlayer() or not ply.was_copycat then
			return
		end
		
		COPYCAT_DATA.DestroyCCFilesGUI(ply)
		
		--Inform all clients that the corpse has Copycat Files (and therefore is a Copycat)
		net.Start("TTT2CopycatFilesCorpseUpdate")
		net.WriteEntity(ply)
		net.WriteBool(true)
		net.Broadcast()
	end)
	
	hook.Add("PlayerSpawn", "PlayerSpawnCopycat", function(ply)
		if not ply or not IsValid(ply) or not ply:IsPlayer() or not ply.was_copycat then
			return
		end
		
		if ply:GetSubRole() ~= ROLE_COPYCAT then
			ply:GiveEquipmentWeapon("weapon_ttt2_copycat_files")
		end
		
		--Reset was_copycat for all clients to limit the information they have on hand.
		net.Start("TTT2CopycatFilesCorpseUpdate")
		net.WriteEntity(ply)
		net.WriteBool(false)
		net.Broadcast()
	end)
end

if CLIENT then
	local function ResetCopycatForClient()
		for _, ply in ipairs(player.GetAll()) do
			ply.was_copycat = nil
		end
	end
	hook.Add("TTTPrepareRound", "TTTPrepareRoundCopycatForClient", ResetCopycatForClient)
	hook.Add("TTTBeginRound", "TTTBeginRoundCopycatForClient", ResetCopycatForClient)
	hook.Add("TTTEndRound", "TTTEndRoundCopycatForClient", ResetCopycatForClient)
	
	net.Receive("TTT2CopycatFilesCorpseUpdate", function()
		local ply = net.ReadEntity()
		if not ply or not IsValid(ply) or not ply:IsPlayer() then
			return
		end
		
		ply.was_copycat = net.ReadBool()
	end)
	
	hook.Add("TTTBodySearchPopulate", "TTTBodySearchPopulateCCFiles", function(search, raw)
		if not raw.owner or not raw.owner.was_copycat then
			return
		end
		
		local highest_id = 0
		for _, v in pairs(search) do
			highest_id = math.max(highest_id, v.p)
		end
		
		search.was_copycat = {img = "vgui/ttt/dynamic/roles/icon_copy.vmt", text = LANG.GetTranslation("CCFILES_CORPSE_" .. COPYCAT.name), p = highest_id + 1}
	end)
end
