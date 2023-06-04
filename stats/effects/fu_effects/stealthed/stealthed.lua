require "/scripts/status.lua"

function init()
  self.active = true

	animator.playSound("on")

  world.setProperty("entity["..tostring(entity.id()).."]Stealthed", true)

  self.damageListener1 = damageListener("inflictedDamage", checkDamage)
  self.damageListener2 = damageListener("inflictedHits", checkDamage)
  self.damageListener3 = damageListener("damageTaken", checkDamage)
end

function checkDamage(notifications)
  for _,notification in pairs(notifications) do
    if notification.sourceEntityId == entity.id() or notification.targetEntityId == entity.id() then
      -- sb.logInfo("break stealth")
      breakStealth()
      return
    end
  end
end

function endStealth() --back to normal
	self.active = false
  self.coolDownTimer = self.coolDownTime
	world.setProperty("entity["..tostring(entity.id()).."]Stealthed", nil)
  effect.setParentDirectives("multiply=ffffff00")

end

function breakStealth(mode)
	animator.playSound("break")
	animator.burstParticleEmitter("breakStealth")
  endStealth()
end

function update(dt)

  if self.active then
    self.damageListener1:update()
    self.damageListener2:update()
    self.damageListener3:update()


    local stealthTransparency = string.format("%X", math.max(math.floor(100 - 50*math.min(1.0,world.lightLevel(mcontroller.position()))), 50))
    if string.len(stealthTransparency) == 1 then stealthTransparency = "0"..stealthTransparency end
    effect.setParentDirectives("multiply=ffffff"..stealthTransparency)
    --sb.logInfo("Light: %s, Speed: %s, Sum: %s", world.lightLevel(mcontroller.position()), vec2.mag(mcontroller.velocity()), stealthCost/args.dt)

  else
    effect.expire()
  end
end

function uninit()
  endStealth()
	animator.playSound("off")
end