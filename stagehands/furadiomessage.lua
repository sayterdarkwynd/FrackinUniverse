require "/scripts/stagehandutil.lua"
require "/scripts/util.lua"

function init()
  self.containsPlayers = {}
  self.radioMessages = config.getParameter("radioMessages") or {config.getParameter("radioMessage")}

  self.check = util.interval(config.getParameter("checkCooldown"), checkIntegrity, 0)
end

function update(dt)
  self.check(dt)
  local newPlayers = broadcastAreaQuery({includedTypes = {"player"}})
  local oldPlayers = table.concat(self.containsPlayers, ",")
  for _, id in pairs(newPlayers) do
    if not string.find(oldPlayers, id) then
      for _, message in ipairs(self.radioMessages) do
        world.sendEntityMessage(id, "queueRadioMessage", message)
      end
    end
  end
  self.containsPlayers = newPlayers
end

function checkIntegrity()
  if not world.isTileProtected(entity.position()) then
    stagehand.die()
  end
end
