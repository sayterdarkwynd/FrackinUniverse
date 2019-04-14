require "/scripts/vec2.lua"

function init()
  storage.timer = storage.timer or 0

  if storage.active == nil then
    updateActive()
  end
  object.setSoundEffectEnabled(storage.active)

  self.fireTime = config.getParameter("fireTime", 1)
  self.fireTimeVariance = config.getParameter("fireTimeVariance", 0)
  self.projectile = config.getParameter("projectile")
  self.projectileConfig = config.getParameter("projectileConfig", {})
  self.projectilePosition = config.getParameter("projectilePosition", {0, 0})
  self.projectileDirection = config.getParameter("projectileDirection", {1, 0})
  self.inaccuracy = config.getParameter("inaccuracy", 0)

  self.projectilePosition = object.toAbsolutePosition(self.projectilePosition)

end

function update(dt)
  if storage.active then
    storage.timer = storage.timer - dt
    if storage.timer <= 0 then
      storage.timer = self.fireTime + (self.fireTimeVariance * math.random() - self.fireTimeVariance / 2)
      shoot()
    end
  end
end

function onNodeConnectionChange(args)
  updateActive()
end

function onInputNodeChange(args)
  updateActive()
end

function shoot()
  animator.playSound("shoot")
  local projectileDirection = vec2.rotate(self.projectileDirection, sb.nrand(self.inaccuracy, 0))
  world.spawnProjectile(self.projectile, self.projectilePosition, entity.id(), projectileDirection, false, self.projectileConfig)
end

function updateActive()
  local active = (not object.isInputNodeConnected(0)) or object.getInputNodeLevel(0)
  local active2 = (object.getInputNodeLevel(1))
  local facing = config.getParameter("scb-direction", " ")
  if active ~= storage.active then
    storage.active = active
    if active then
      storage.timer = 0
--      animator.setAnimationState("trapState", "on")
      object.setLightColor(config.getParameter("activeLightColor", {0, 0, 0, 0}))
      object.setSoundEffectEnabled(true)
      animator.playSound("on");
    else
        object.setLightColor(config.getParameter("inactiveLightColor", {0, 0, 0, 0}))
        object.setSoundEffectEnabled(false)
        animator.playSound("off");
    end
  end
  if active2 ~= storage.active2 then
    storage.active2 = active2
    if active2 then
      if facing == "up" then
        animator.setAnimationState("trapState", "upOn")
      elseif facing == "right" then
        animator.setAnimationState("trapState", "rightOn")
      elseif facing == "down" then
        animator.setAnimationState("trapState", "downOn")
      elseif facing == "left" then
        animator.setAnimationState("trapState", "leftOn")
      elseif facing == "upperL" then
        animator.setAnimationState("trapState", "upperLOn")
      elseif facing == "upperR" then
        animator.setAnimationState("trapState", "upperROn")
      elseif facing == "lowerR" then
        animator.setAnimationState("trapState", "lowerROn")
      elseif facing == "lowerL" then
        animator.setAnimationState("trapState", "lowerLOn")
      end
    else
      animator.setAnimationState("trapState", "off")
    end
  end
end
