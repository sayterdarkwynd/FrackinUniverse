
function zb_sailInfo()
	resetGUI()
	local text = "Welcome the new SAIL window! In addition to the new look, this rework can:\n\n > View non-vanilla currencies (Which cannot be displayed in the inventory because of hardcoded limitations)\n\n > Missions are split into main, and secondary tabs, as well as notifying you which are replays\n\n > Easy-to-add custom functions called through button in the 'Misc.' menu (Instructions can be found on Ztarbounds mod page)\n\n > Full compatiability with Scripted SAIL.\n\n Be advised, should some of your crew or missions are not displayed, you can always fallback to the vanilla sail through via a function inside the 'MISC.' button."
	textTyper.init(cfg.TextData, text)
end

function zb_skipStarterCrap()
	if false then--disabling this function until someone can make it not cause issues.
		local quests = {"gaterepair", "shiprepair", "human_mission1", "mechunlock", "outpostclue"}
		local str = "Quest IDs:"

		for _, quest in ipairs(quests) do
			if not player.hasCompletedQuest(quest) then
				player.startQuest(quest)
				str = str.."\n"..quest
			end
		end
	end
	resetGUI()
	textTyper.init(cfg.TextData, "[(instant)"..str.."]")
end