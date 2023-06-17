if SERVER then
    AddCSLuaFile()

    resource.AddFile("materials/vgui/ttt/dynamic/roles/icon_copy.vmt")
end

if CLIENT then
	EVENT.title = "title_event_copy_transcribe"
	EVENT.icon = Material("vgui/ttt/dynamic/roles/icon_copy.vmt")
	
	function EVENT:GetText()
		return {
			{
				string = "desc_event_copy_transcribe",
				params = {
					name1 = self.event.copy_name,
					name2 = self.event.corpse_name,
					role = self.event.role_str
				},
				translateParams = true
			}
		}
    end
end

if SERVER then
	function EVENT:Trigger(copy, rag)
		local role_data = roles.GetByIndex(rag.was_role)
		local rag_owner = player.GetBySteamID64(rag.sid64)
		if rag_owner then
			rag_name = rag_owner:GetName()
		else
			--player.GetBySteamID64 returns false if it can't find the player (ex. the player disconnected and left behind a ragdoll)
			rag_name = "???"
		end
		
		self:AddAffectedPlayers(
			{copy:SteamID64(), rag.sid64},
			{copy:GetName(), rag_name}
		)
		
		return self:Add({
			serialname = self.event.title,
			copy_name = copy:GetName(),
			copy_id = copy:SteamID64(),
			corpse_name = rag_name,
			role_str = role_data.name
		})
	end
	
	function EVENT:CalculateScore()
		self:SetPlayerScore(self.event.copy_id, {
			score = 1
		})
	end
	
	function EVENT:Serialize()
		return self.event.serialname
	end
end