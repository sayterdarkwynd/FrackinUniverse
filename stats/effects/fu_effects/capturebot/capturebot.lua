function init()
  effect.setParentDirectives(config.getParameter("directives", ""))
  self.healthPercentage = config.getParameter("healthPercentage", 0.1)

  if not (status.isResource("food")) then
	  if status.isResource("stunned") then
	    status.setResource("stunned", math.max(status.resource("stunned"), effect.duration()))
	  end
	  mcontroller.setVelocity({0, 0})
  end
end

function update(dt)
  if not (status.isResource("food")) then
	  status.setResourcePercentage("health", math.min(status.resourcePercentage("health"), self.healthPercentage))
	    mcontroller.controlModifiers({
	      facingSuppressed = true,
	      movementSuppressed = true
	    }) 
  end
end

function uninit()

end
