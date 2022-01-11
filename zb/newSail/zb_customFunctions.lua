
function zb_sailInfo()
	resetGUI()
	local text = "Welcome the new SAIL window! In addition to the new look, this rework provides the following features:\n\n > Ability to view non-vanilla currencies (which cannot be displayed in the inventory because of hardcoded limitations)\n\n > Missions are split into main and secondary tabs, and replays are labeled as such\n\n > Custom functions can be added easily and called through a button in the 'Misc.' menu (See instructions on Ztarbound's mod page)\n\n > Full compatibility with Scripted SAIL.\n\n Be advised: should some of your crew or missions not be displayed, you can always fall back to the vanilla SAIL through via a function inside the 'MISC.' button."
	textTyper.init(cfg.TextData, text)
end

function zb_skipStarterCrap()
	-- luacheck: ignore 511
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
