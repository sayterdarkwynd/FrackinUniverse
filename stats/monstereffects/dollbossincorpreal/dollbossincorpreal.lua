function init()
  self.statetime = config.getParameter("stateTime", 20),
  self.tag = config.getParameter("tag","incorpreal")
  self.effect = coroutine.create(effect)
  coroutine.resume(self.effect)
end

function update(dt)
  if coroutine.status(self.effect) then coroutine.resume(self.effect) end
end

function uninit()
end

function effect()
  local timer = self.stateTime
  while status.resource(health) > 0 do
    timer = timer - dt
    if timer < 0 then timer = self.stateTime end
    if stateTime > math.floor(self.stateTime/2) then
      animator.setGlobalTag(self.tag, "")
      status.removeEphemeralEffect("invulnerable")
      status.removeEphemeralEffect("camouflage55")
    else
      animator.setGlobalTag(self.tag, "incorpreal")
      status.addEphemeralEffect("invulnerable",math.huge)
      status.addEphemeralEffect("camouflage55",math.huge)
    end
    coroutine.yield()
  end
  if world.monsterType(entity.id()) == "dollbosshand" then
    animator.setGlobalTag(self.tag, "incorpreal")
    status.setResourcePercentage("health", 1)
    status.addEphemeralEffect("invulnerable",math.huge)
    status.addEphemeralEffect("camouflage55",math.huge)
  end
  effect.expire()
end
