local L = LANG.GetLanguageTableReference("en")

--GENERAL ROLE LANGUAGE STRINGS
L[COPYCAT.name] = "Copycat"
L["info_popup_" .. COPYCAT.name] = [[You are a Copycat. Kill everyone else.

Inspect their bodies to add their role to The Copycat Files.

Use The Copycat Files to switch roles (one time per game).]]
L["body_found_" .. COPYCAT.abbr] = "They were a Copycat."
L["search_role_" .. COPYCAT.abbr] = "This person was a Copycat!"
L["target_" .. COPYCAT.name] = "Copycat"
L["ttt2_desc_" .. COPYCAT.name] = [[You are a Copycat. Kill everyone else.

Inspect their bodies to add their role to The Copycat Files.

Use The Copycat Files to switch roles (one time per game).]]

--COPYCAT TEAM
L[TEAM_COPYCAT] = "Team Copycats"
L["hilite_win_" .. TEAM_COPYCAT] = "TEAM COPYCAT WON"
L["win_" .. TEAM_COPYCAT] = "The Copycat has won!"
L["ev_win_" .. TEAM_COPYCAT] = "The Copycat won the round!"

--COPYCAT FILES
L["CCFILES_NAME_" .. COPYCAT.name] = "Copycat Files"
L["CCFILES_DESC_" .. COPYCAT.name] = "Use to change roles (but not teams). Can only change to roles of bodies you've inspected. Can't change to the same role twice."
L["CCFILES_HELP_" .. COPYCAT.name] = "Investigate Corpses for Roles"
L["CCFILES_TITLE_" .. COPYCAT.name] = "Choose Your Role"
L["CCFILES_COOLDOWN_" .. COPYCAT.name] = "ON COOLDOWN"
L["CCFILES_INVALID_RESPONSE_" .. COPYCAT.name] = "Invalid response to the ballot! Received a role id of '{id}' with corresponding name of '{name}', which was not on the ballot."
L["CCFILES_CORPSE_" .. COPYCAT.name] = "This person had The Copycat Files on them!"
