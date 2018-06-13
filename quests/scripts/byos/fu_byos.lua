require "/scripts/util.lua"
require "/quests/scripts/questutil.lua"
require "/quests/scripts/portraits.lua"

function init()
	setPortraits()
end

function update(dt)
	if player.hasCompletedQuest("bootship") then
		quest.complete()
	end
end