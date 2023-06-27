--ConVar syncing
CreateConVar("ttt2_copycat_once_per_role", "1", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
CreateConVar("ttt2_copycat_role_change_cooldown", "30", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
CreateConVar("ttt2_copycat_on_dop_team", "0", {FCVAR_ARCHIVE, FCVAR_NOTFIY})

hook.Add("TTTUlxDynamicRCVars", "TTTUlxDynamicCopycatCVars", function(tbl)
	tbl[ROLE_COPYCAT] = tbl[ROLE_COPYCAT] or {}
	
	--# Can the Copycat only switch to a given role once per game?
	--  Note1: If disabled, I can't guarrantee that this won't cause role abuse (ex. constantly swapping between revival roles for infinite lives)
	--  ttt2_copycat_once_per_role [0/1] (default: 1)
	table.insert(tbl[ROLE_COPYCAT], {
		cvar = "ttt2_copycat_once_per_role",
		checkbox = true,
		desc = "ttt2_copycat_once_per_role (Def: 1)"
	})

	--# How many seconds must pass until The Copycat can change their role again?
	--  ttt2_copycat_role_change_cooldown [0..n] (default: 30)
	table.insert(tbl[ROLE_COPYCAT], {
		cvar = "ttt2_copycat_role_change_cooldown",
		slider = true,
		min = 0,
		max = 120,
		decimal = 0,
		desc = "ttt2_copycat_role_change_cooldown (Def: 30)"
	})
	
	--# Is the Copycat on The Doppelganger's Team?
	--  Note1: Even if this is enabled, The Copycat will be on their own team if the Doppelganger isn't installed.
	--  Note2: The server (and GMod if peer-to-peer) will need to be restarted in order for a change in this ConVar to take effect
	--  ttt2_copycat_on_dop_team [0/1] (default: 0)
	table.insert(tbl[ROLE_COPYCAT], {
		cvar = "ttt2_copycat_on_dop_team",
		checkbox = true,
		desc = "ttt2_copycat_on_dop_team (Def: 0)"
	})
end)

hook.Add("TTT2SyncGlobals", "AddCopycatGlobals", function()
	SetGlobalBool("ttt2_copycat_once_per_role", GetConVar("ttt2_copycat_once_per_role"):GetBool())
	SetGlobalInt("ttt2_copycat_role_change_cooldown", GetConVar("ttt2_copycat_role_change_cooldown"):GetInt())
	SetGlobalBool("ttt2_copycat_on_dop_team", GetConVar("ttt2_copycat_on_dop_team"):GetBool())
end)

cvars.AddChangeCallback("ttt2_copycat_once_per_role", function(name, old, new)
	SetGlobalBool("ttt2_copycat_once_per_role", tobool(tonumber(new)))
end)
cvars.AddChangeCallback("ttt2_copycat_role_change_cooldown", function(name, old, new)
	SetGlobalInt("ttt2_copycat_role_change_cooldown", tonumber(new))
end)
cvars.AddChangeCallback("ttt2_copycat_on_dop_team", function(name, old, new)
	SetGlobalBool("ttt2_copycat_on_dop_team", tobool(tonumber(new)))
end)
