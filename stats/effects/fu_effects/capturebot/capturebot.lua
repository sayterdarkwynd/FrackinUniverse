function init()

  if status.statPositive("captureImmunity") or status.statPositive("specialStatusImmunity") then
	  effect.expire()
	  return
  end
  effect.setParentDirectives(config.getParameter("directives", ""))
  self.healthPercentage = config.getParameter("healthPercentage", 0.1)

  if (not status.isResource("food")) and status.isResource("stunned") then
	  status.setResource("stunned", math.max(status.resource("stunned"), effect.duration()))
	  mcontroller.setVelocity({0, 0})
  end
end

function update(dt)
	if world.entityType(entity.id()) ~= "monster" or status.statPositive("captureImmunity") or status.statPositive("specialStatusImmunity") then
	  effect.expire()
	  return
	else
	  status.setResourcePercentage("health", math.min(status.resourcePercentage("health"), self.healthPercentage))
	    mcontroller.controlModifiers({
	      facingSuppressed = true,
	      movementSuppressed = true
	    }) 
	end
end

function uninit()

end
