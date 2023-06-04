function init()
	if (status.resourceMax("health") < config.getParameter("minMaxHealth", 0)) or (not world.entityExists(entity.id())) or ((world.entityType(entity.id())== "monster") and (world.callScriptedEntity(entity.id(),"getClass") == 'bee')) then
		effect.expire()
	end

  self.blinkTimer = 0
end

function update(dt)
  self.blinkTimer = self.blinkTimer - dt
  if self.blinkTimer <= 0 then self.blinkTimer = 0.5 end

  if self.blinkTimer < 0.2 then
    effect.setParentDirectives(config.getParameter("flashDirectives", ""))
  else
    effect.setParentDirectives("")
  end

  if not status.resourcePositive("health") and status.resourceMax("health") >= config.getParameter("minMaxHealth", 0) then
    explode()
  end
end

function uninit()

end

function explode()
  if not self.exploded and not status.statPositive("deathbombDud") then
    local sourceEntityId = effect.sourceEntity() or entity.id()
    local sourceDamageTeam = world.entityDamageTeam(sourceEntityId)
    local bombPower = status.resourceMax("health") * config.getParameter("healthDamageFactor", 1.0)
    local projectileConfig = {
      power = bombPower,
      damageTeam = sourceDamageTeam,
      onlyHitTerrain = true,
      timeToLive = 0,
      actionOnReap = {
        {
          action = "config",
          file = config.getParameter("bombConfig")
        }
      }
    }
    world.spawnProjectile("invisibleprojectile", mcontroller.position(), 0, {0, 0}, false, projectileConfig)
    self.exploded = true
	if status.isResource("stunned") then
		status.setResource("stunned",0)
	end
  end
end
