
function zb_sailInfo()
	resetGUI()
	local text = "Welcome the new SAIL window! In addition to the new look, this rework can:\n\n > View non-vanilla currencies (Which cannot be displayed in the inventory because of hardcoded limitations)\n\n > Missions are split into main, and secondary tabs, as well as notifying you which are replays\n\n > You get a little bit more info about crew\n\n > Easy-to-add custom functions called through button in the 'Misc.' menu (There are instructions in FU's files located at /interface/scripted/fu_sail/user)\n\nNote that currently, the window is unaffected by customizable SAIL, but will be in the near future."
	textTyper.init(cfg.TextData, text)
end

function zb_skipStarterCrap()
	local quests = {"gaterepair", "shiprepair", "human_mission1", "mechunlock", "outpostclue"}
	local str = "Quest IDs:"
	
	for _, quest in ipairs(quests) do
		if not player.hasCompletedQuest(quest) then
			player.startQuest(quest)
			str = str.."\n"..quest
		end
	end
	
	resetGUI()
	textTyper.init(cfg.TextData, "[(instant)"..str.."]")
end