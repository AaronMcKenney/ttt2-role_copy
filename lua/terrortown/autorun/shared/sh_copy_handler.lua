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
		
		hook.Remove("Think", "ThinkCopycatForClient")
	end
end

if SERVER then
	--This structure is maintained over the entire game, to prevent the Copycat from losing all of the roles they've acquired if they happen to die and then resurrect.
	--Structure:
	--  List of players by Steam ID
	--    List of roles that the player has (using their power as a copycat) made note of.
	--      One of {nil: role has not been discovered, true: The player can become this role, false: the player has already been this role}
	COPYCAT_FILES_DATA = {}
	
	function COPYCAT_DATA.InitCCFilesForPly(ply)
		--Create the Copycat Files structure for the given player if it doesn't already exist.
		if not COPYCAT_FILES_DATA[ply:SteamID64()] then
			COPYCAT_FILES_DATA[ply:SteamID64()] = {}
			--Always valid to become a Copycat
			COPYCAT_FILES_DATA[ply:SteamID64()][ROLE_COPYCAT] = true
		end
	end
	
	function COPYCAT_DATA.ResetCCFilesDataForServer()
		COPYCAT_FILES_DATA = {}
		
		for _, ply in ipairs(player.GetAll()) do
			--Remove the GUI for everyone so that it doesn't show up next round.
			COPYCAT_DATA.DestroyCCFilesGUI(ply)
			
			STATUS:RemoveStatus(ply, "ttt2_ccfiles_cooldown")
			if timer.Exists("CCFilesCooldownTimer_Server_" .. ply:SteamID64()) then
				timer.Remove("CCFilesCooldownTimer_Server_" .. ply:SteamID64())
			end
			
			--At the beginning of the round, resetting involves giving Copycats their initial CCFile state.
			if GetRoundState() == ROUND_ACTIVE and ply:GetSubRole() == ROLE_COPYCAT then
				COPYCAT_DATA.InitCCFilesForPly(ply)
			end
		end
	end
	
	hook.Add("TTTCanSearchCorpse", "TTTCanSearchCorpseCCFiles", function(ply, rag, isCovert, isLongRange)
		if GetRoundState() ~= ROUND_ACTIVE or not IsValid(ply) or not ply:Alive() or not IsValid(rag) or not ply:HasWeapon("weapon_ttt2_copycat_files") then
			return
		end
		
		if rag.was_role and COPYCAT_FILES_DATA[ply:SteamID64()][rag.was_role] == nil then
			COPYCAT_FILES_DATA[ply:SteamID64()][rag.was_role] = true
			
			events.Trigger(EVENT_COPY_TRANSCRIBE, ply, rag)
			
			--Resend the CCFiles if the client currently has the GUI open
			if ply.ccfiles_processing then
				COPYCAT_DATA.SendCopycatFilesToClient(ply, true)
			end
		end
	end)
	
	hook.Add("PlayerSwitchWeapon", "PlayerSwitchWeaponCopycat", function(ply, old, new)
		if not IsValid(ply) or not ply:IsPlayer() or not ply.ccfiles_processing then
			return
		end
		
		--Get rid of Copycat Files GUI when switching weapons, to prevent the player from just leaving it up forever (both annoying for new players and weird meta tactic)
		COPYCAT_DATA.DestroyCCFilesGUI(ply)
	end)
	
	function COPYCAT_DATA.SendCopycatFilesToClient(ply, resend)
		if not ply or not IsValid(ply) or not ply:IsPlayer() then
			return
		end
		
		if (not ply.ccfiles_processing or resend) and GetRoundState() == ROUND_ACTIVE then
			local client_ccfiles = {}
			ply.ccfiles_processing = true
			
			for role_id, picked_at_least_once in pairs(COPYCAT_FILES_DATA[ply:SteamID64()]) do
				--Handle Copycat in the client end.
				if role_id ~= ROLE_COPYCAT then
					client_ccfiles[role_id] = (picked_at_least_once == true or (not GetConVar("ttt2_copycat_once_per_role"):GetBool()))
				end
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
				STATUS:AddTimedStatus(ply, "ttt2_ccfiles_cooldown", cooldown, true)
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
		
		--ccfiles is of the form: {role_id: selectable, ...}
		local ccfiles = net.ReadTable()
		local client = LocalPlayer()
		
		--Remove previous GUI if it exists
		COPYCAT_DATA.DestroyCCFilesGUI()
		
		--Lua is really dumb. It cannot sort a table that has strings as keys. A workaround is needed
		--We'll have to sort the keys individually, and then iterate over this list and use these keys to index into ccfiles.
		--We're doing this here since the Server's time is precious, 
		--  and because net.ReadTable() does not guarrantee that the key-value pairs arrive in the same order as they are sent.
		local sorted_keys = {}
		local key_to_value = {}
		for role_id, selectable in pairs(ccfiles) do
			local role_data = roles.GetByIndex(role_id)
			local ccfiles_entry_str = LANG.TryTranslation(role_data.name)
			sorted_keys[#sorted_keys+1] = ccfiles_entry_str
			key_to_value[ccfiles_entry_str] = {role_id, selectable}
		end
		table.sort(sorted_keys)
		--Always append Copycat at the bottom of the list, for ease of use. It may always be used to return to the Copycat role if the player isn't already a Copycat.
		local copycat_name = LANG.TryTranslation(roles.GetByIndex(ROLE_COPYCAT).name)
		sorted_keys[#sorted_keys+1] = copycat_name
		key_to_value[copycat_name] = {ROLE_COPYCAT, client:GetSubRole() ~= ROLE_COPYCAT}
		
		--Create GUI in its initial state
		client.ccfiles_frame = vgui.Create("DFrame")
		client.ccfiles_frame:SetPos(5, ScrH() / 3)
		if #sorted_keys == 1 then
			--Inform newbies that they should collect more roles.
			client.ccfiles_frame:SetTitle(LANG.TryTranslation("CCFILES_HELP_" .. COPYCAT.name))
			--Only Copycat is present. Use just enough height to display the help section and the Copycat button.
			client.ccfiles_frame:SetSize(175, 50)
		else
			client.ccfiles_frame:SetTitle(LANG.TryTranslation("CCFILES_TITLE_" .. COPYCAT.name))
			--Can't use #ccfiles, as "#" only computes the size of an array if all of the keys are contiguous integers
			--Add an additional 10 to the height. It will be used to space out Copycat button from the others above it.
			client.ccfiles_frame:SetSize(175, 10 + (20 * (#sorted_keys + 1)) + 10)
		end
		client.ccfiles_frame:SetVisible(true)
		client.ccfiles_frame:SetDraggable(false)
		client.ccfiles_frame:ShowCloseButton(false)
		--Memorize FG color in case we enter then exit cooldown.
		local default_fg_color = client.ccfiles_frame:GetFGColor()
		
		for i=1, #sorted_keys do
			local ccfiles_entry_str = sorted_keys[i]
			local role_id = key_to_value[ccfiles_entry_str][1]
			local selectable = key_to_value[ccfiles_entry_str][2]
			local button = vgui.Create("DButton", client.ccfiles_frame)
			
			button:SetText(ccfiles_entry_str)
			if role_id == ROLE_COPYCAT and #sorted_keys > 1 then
				--Give Copycat role an additional 10 height to separate it from the other roles.
				button:SetPos(0, 10 + (20 * i) + 10)
			else
				--Typical button position
				button:SetPos(0, 10 + (20 * i))
			end
			button:SetSize(175, 20)
			button.DoClick = function()
				--If we're not on cooldown, we can send a request to change the Copycat's role.
				if not STATUS:Active("ttt2_ccfiles_cooldown") then
					net.Start("TTT2CopycatFilesResponse")
					net.WriteInt(role_id, 16)
					net.SendToServer()
					COPYCAT_DATA.DestroyCCFilesGUI()
				end
			end
			
			--TODO: Per https://wiki.facepunch.com/gmod/DButton it may be better to use Panel:SetEnabled in some manner.
			button:SetDisabled(not selectable)
		end
		
		hook.Add("Think", "ThinkCopycatForClient", function()
			local client = LocalPlayer()
			
			--Handle state transitions that can occur past the initial state (i.e. only Copycat listed) for the CCFiles GUI
			if client.ccfiles_frame and client.ccfiles_frame.SetTitle then
				if STATUS:Active("ttt2_ccfiles_cooldown") then
					--CCFIles is on cooldown. Display in red to get the point across.
					client.ccfiles_frame:SetFGColor(COLOR_RED)
					client.ccfiles_frame:SetTitle(LANG.TryTranslation("CCFILES_COOLDOWN_" .. COPYCAT.name))
				elseif #sorted_keys > 1 then
					--CCFiles is off coolodwn and has at least one other role aside from Copycat. Usual title and color.
					client.ccfiles_frame:SetFGColor(default_fg_color)
					client.ccfiles_frame:SetTitle(LANG.TryTranslation("CCFILES_TITLE_" .. COPYCAT.name))
				end
			end
		end)
	end)
	
	net.Receive("TTT2CopycatFilesResponse", function()
		COPYCAT_DATA.DestroyCCFilesGUI()
	end)
end
