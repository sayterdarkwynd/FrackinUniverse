require("/quests/scripts/portraits.lua")
require("/quests/scripts/questutil.lua")

function init()
end

function questStart()
  player.giveItem("sciencebrochure")
end

function questComplete()
  questutil.questCompleteActions()
end

function update(dt)
	if player.hasItem("sciencebrochure") then
          quest.complete()
	end
end

function uninit()
end
