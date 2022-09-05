if SERVER then
	AddCSLuaFile()
	util.AddNetworkString("TTT2CopycatFilesBallotRequest")
	util.AddNetworkString("TTT2CopycatFilesBallotResponse")
end

COPYCAT_DATA = {}

function COPYCAT_DATA.DestroyBallot(ply)
	if SERVER then
		net.Start("TTT2CopycatFilesBallotResponse")
		net.Send(ply)
		ply.ccfiles_ballot_processing = nil
	else --CLIENT
		local client = LocalPlayer()
		
		if client.ccfiles_frame and client.ccfiles_frame.Close then
			client.ccfiles_frame.Close()
		end
		client.ccfiles_frame = nil
	end
end

if SERVER then
	--This structure is maintained over the entire game, to prevent the Copycat from losing all of the roles they've acquired if they happen to die and then resurrect.
	--Structure:
	--  List of players by Steam ID
	--    List of roles that the player has (using their power as a copycat) made note of.
	--      One of {nil: role has not been discovered, true: The player can become this role, false: the player has already been this role}
	COPYCAT_FILES_DATA = {}

	local function InitCCFilesForPly(ply)
		--This function exists here for now. GetOwner() appears to return nil in SWEP:Initialize (Or I am blind)
		if not COPYCAT_FILES_DATA[ply:SteamID64()] then
			COPYCAT_FILES_DATA[ply:SteamID64()] = {}
			--Always valid to become a Copycat
			COPYCAT_FILES_DATA[ply:SteamID64()][ROLE_COPYCAT] = true
		end
	end
	
	function COPYCAT_DATA.ResetCCFilesDataForServer()
		for _, ply in ipairs(player.GetAll()) do
			--Remove the ballot for everyone so that it doesn't show up next round.
			COPYCAT_DATA.DestroyBallot(ply)
			
			STATUS:RemoveStatus(ply, "ttt2_ccfiles_cooldown")
			if timer.Exists("CCFilesCooldownTimer_Server_" .. ply:SteamID64()) then
				timer.Remove("CCFilesCooldownTimer_Server_" .. ply:SteamID64())
			end
		end
		
		COPYCAT_FILES_DATA = {}
	end
	
	hook.Add("TTTCanSearchCorpse", "TTTCanSearchCorpseCCFiles", function(ply, rag, isCovert, isLongRange)
		if GetRoundState() ~= ROUND_ACTIVE or not IsValid(ply) or not ply:Alive() or not IsValid(rag) or not ply:HasWeapon("weapon_ttt2_copycat_files") then
			return
		end
		
		InitCCFilesForPly(ply)
		
		if rag.was_role and COPYCAT_FILES_DATA[ply:SteamID64()][rag.was_role] == nil then
			COPYCAT_FILES_DATA[ply:SteamID64()][rag.was_role] = true
		end
	end)
end

if CLIENT then
	hook.Add("Initialize", "InitializeCCFiles", function()
		STATUS:RegisterStatus("ttt2_ccfiles_cooldown", {
			hud = Material("vgui/ttt/dynamic/roles/icon_copy.vtf"),
			type = "bad"
		})
	end)
end
