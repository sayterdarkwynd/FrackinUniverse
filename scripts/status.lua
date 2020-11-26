function damageListener(listenerType, callback)
  local listener = {}
  listener.callback = callback
  if listenerType == "inflictedDamage" then
    listener.pollFunction = status.inflictedDamageSince
  elseif listenerType == "inflictedHits" then
    listener.pollFunction = status.inflictedHitsSince
  elseif listenerType == "damageTaken" then
    listener.pollFunction = status.damageTakenSince
  elseif listenerType == "Kill" then -- FU adds kill tracking
    listener.pollFunction = status.inflictedHitsSince
  else
    sb.logInfo("Failed to create damageListener - invalid listenerType '%s'", listenerType)
  end
  _,listener.timestep = listener.pollFunction()

  function listener:update()
    local notifications
    notifications, self.timestep = self.pollFunction(self.timestep)
    if #notifications > 0 then
      callback(notifications)
    end
  end

  return listener
end
