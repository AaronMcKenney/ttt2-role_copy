if SERVER then
	AddCSLuaFile()
	util.AddNetworkString("TTT2CopycatFilesRequest")
	util.AddNetworkString("TTT2CopycatFilesResponse")
end

COPYCAT_DATA = {}

function COPYCAT_DATA.DestroyCCFilesGUI(ply)
	if SERVER then
		net.Start("TTT2CopycatFilesResponse")
		net.Send(ply)
		ply.ccfiles_processing = nil
	else --CLIENT
		local client = LocalPlayer()
		
		if client.ccfiles_frame and client.ccfiles_frame.Close then
			client.ccfiles_frame:Close()
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
		--Create the Copycat Files structure for the given player if it doesn't already exist.
		if not COPYCAT_FILES_DATA[ply:SteamID64()] then
			COPYCAT_FILES_DATA[ply:SteamID64()] = {}
			--Always valid to become a Copycat
			COPYCAT_FILES_DATA[ply:SteamID64()][ROLE_COPYCAT] = true
		end
	end
	
	function COPYCAT_DATA.ResetCCFilesDataForServer()
		for _, ply in ipairs(player.GetAll()) do
			--Remove the GUI for everyone so that it doesn't show up next round.
			COPYCAT_DATA.DestroyCCFilesGUI(ply)
			
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
	
	function COPYCAT_DATA.SendCopycatFilesToClient(ply)
		if not ply or not IsValid(ply) or not ply:IsPlayer() then
			return
		end
		
		if not ply.ccfiles_processing and GetRoundState() == ROUND_ACTIVE then
			local client_ccfiles = {}
			ply.ccfiles_processing = true
			
			InitCCFilesForPly(ply)
			
			for k,v in pairs(COPYCAT_FILES_DATA[ply:SteamID64()]) do
				client_ccfiles[k] = (v == true or (not GetConVar("ttt2_copycat_once_per_role"):GetBool()))
			end
			
			net.Start("TTT2CopycatFilesRequest")
			net.WriteTable(client_ccfiles)
			net.Send(ply)
		else
			--Get rid of the Copycat files GUI when using primary fire again.
			COPYCAT_DATA.DestroyCCFilesGUI(ply)
		end
	end
	
	net.Receive("TTT2CopycatFilesResponse", function(len, ply)
		local role_id = net.ReadInt(16)
		local role_id_is_valid = (COPYCAT_FILES_DATA[ply:SteamID64()] ~= nil and COPYCAT_FILES_DATA[ply:SteamID64()][role_id] ~= nil and (COPYCAT_FILES_DATA[ply:SteamID64()][role_id] == true or not GetConVar("ttt2_copycat_once_per_role"):GetBool()))
		local cooldown = GetConVar("ttt2_copycat_role_change_cooldown"):GetInt()
		local under_cooldown = timer.Exists("CCFilesCooldownTimer_Server_" .. ply:SteamID64())
		
		if role_id == ROLE_NONE then
			--Client has opted to not change their role, and merely wanted to destroy the GUI.
			COPYCAT_DATA.DestroyCCFilesGUI(ply)
			return
		end
		
		if not role_id_is_valid then
			local role_data = roles.GetByIndex(role_id)
			local role_name = LANG.TryTranslation(role_data.name)
			LANG.Msg(ply, "CCFILES_INVALID_RESPONSE_" .. COPYCAT.name, {id=tostring(role_id), name=tostring(role_name)}, MSG_MSTACK_WARN)
		elseif GetRoundState() == ROUND_ACTIVE and ply:Alive() and not under_cooldown and ply.ccfiles_processing and role_id ~= ply:GetSubRole() then
			ply:SetRole(role_id, ply:GetTeam())
			SendFullStateUpdate()
			
			--The Copycat role is always valid. Every other role may only be used once.
			if role_id ~= ROLE_COPYCAT then
				COPYCAT_FILES_DATA[ply:SteamID64()][role_id] = false
			end
			
			if cooldown > 0 then
				timer.Create("CCFilesCooldownTimer_Server_" .. ply:SteamID64(), cooldown, 1, function() end)
				STATUS:AddTimedStatus(ply, "ttt2_ccfiles_cooldown", cooldown, false)
			end
		end
		
		COPYCAT_DATA.DestroyCCFilesGUI(ply)
	end)
end

if CLIENT then
	hook.Add("Initialize", "InitializeCCFiles", function()
		STATUS:RegisterStatus("ttt2_ccfiles_cooldown", {
			hud = Material("vgui/ttt/dynamic/roles/icon_copy.vtf"),
			type = "bad"
		})
	end)
	
	net.Receive("TTT2CopycatFilesRequest", function()
		if GetRoundState() ~= ROUND_ACTIVE then
			return
		end
		
		local ccfiles = net.ReadTable()
		
		local client = LocalPlayer()
		
		COPYCAT_DATA.DestroyCCFilesGUI()
		
		client.ccfiles_frame = vgui.Create("DFrame")
		client.ccfiles_frame:SetTitle(LANG.TryTranslation("CCFILES_TITLE_" .. COPYCAT.name))
		client.ccfiles_frame:SetPos(5, ScrH() / 3)
		--For reasons unknown, have to add +2 to #ccfiles instead of +1 if #ccfiles == 1. Otherwise the size is not large enough to hold any buttons. Very confusing.
		client.ccfiles_frame:SetSize(150, 10 + (20 * (math.max(#ccfiles + 1, 3))))
		client.ccfiles_frame:SetVisible(true)
		client.ccfiles_frame:SetDraggable(false)
		client.ccfiles_frame:ShowCloseButton(false)
		
		local i = 1
		for role_id, selectable in pairs(ccfiles) do
			local role_data = roles.GetByIndex(role_id)
			local ccfiles_entry_str = LANG.TryTranslation(role_data.name)
			local button = vgui.Create("DButton", client.ccfiles_frame)
			
			button:SetText(ccfiles_entry_str)
			button:SetPos(0, 10 + (20 * i))
			button:SetSize(150,20)
			button.DoClick = function()
				net.Start("TTT2CopycatFilesResponse")
				net.WriteInt(role_id, 16)
				net.SendToServer()
				COPYCAT_DATA.DestroyCCFilesGUI()
			end
			
			--TODO: Per https://wiki.facepunch.com/gmod/DButton it may be better to use Panel:SetEnabled in some manner.
			button:SetDisabled(not selectable)
			
			i = i + 1
		end
	end)
	
	net.Receive("TTT2CopycatFilesResponse", function()
		COPYCAT_DATA.DestroyCCFilesGUI()
	end)
end
