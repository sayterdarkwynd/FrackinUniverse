require "/quests/scripts/portraits.lua"
require "/quests/scripts/conditions/gather.lua"
require "/scripts/util.lua"
require "/quests/scripts/messages.lua"
require "/quests/scripts/questutil.lua"
require "/quests/scripts/conditions/scanning.lua"


function init()
  buildMessageHandlers()
  setPortraits()
end

function questStart()
  player.playCinematic(config.getParameter("cinematicToLoad"))
end

function questComplete()
  setPortraits()
  questutil.questCompleteActions()
end

function update(dt)
  promises:update()
end