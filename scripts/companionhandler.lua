local scriptedailOldInit = init
--local scriptedailOldUpdate = update

function init()
  scriptedailOldInit()
  message.setHandler("returnCompanions", function() return playerCompanions.getCompanions("crew") end)
  message.setHandler("dismissCompanion", function(_, _, podUuid) recruitSpawner:dismiss(podUuid) end)
  message.setHandler("pods",function() return storage.pods end)
  message.setHandler("activePods",function() return storage.activePods end)
end

--[[function update(dt)
	scriptedailOldUpdate(dt)
end]]