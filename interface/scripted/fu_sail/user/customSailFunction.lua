

function myFunction()
	resetGUI()
	local text = "Welcome to FU's reworked SAIL window! In addition to the new look, this rework can:\n\n > View non-vailla currencies (Which cannot be displayed in the inventory because hardcoded inventory)\n\n > Missions are split into main, and secondary tabs, as well as notifying you which are replays\n\n > You get a little bit more info about crew\n\n > Easy-to-add custom functions called through button in the 'Misc.' menu (There are instructions in FU's files located at /interface/scripted/fu_sail/user)\n\nNote that currently, the window is unaffected by customizable SAIL, but will be in the near future."
	writerInit(cfg.TextData, text)
end

function skipStarterCrap()
	local quests = {"gaterepair", "shiprepair", "human_mission1", "mechunlock"}
	local str = "Quest IDs:"
	
	for _, quest in ipairs(quests) do
		if not player.hasCompletedQuest(quest) then
			player.startQuest(quest)
			str = str.."\n"..quest
		end
	end
	
	resetGUI()
	writerInit(cfg.TextData, str)
end