local scriptedailOldInit = init

function init()
  scriptedailOldInit()
  message.setHandler("returnCompanions", function() return playerCompanions.getCompanions("crew") end)
  message.setHandler("dismissCompanion", function(_, _, podUuid) recruitSpawner:dismiss(podUuid) end)
end