require "/scripts/vec2.lua"

function init()
  self.chargeTime = config.getParameter("chargeTime")
  self.boostTime = config.getParameter("boostTime")
  self.boostSpeed = config.getParameter("boostSpeed")
  self.boostForce = config.getParameter("boostForce")
  self.energyCostPerSecond = config.getParameter("energyCostPerSecond")

  idle()
self.active=false
  self.available = true
end

function uninit()
  idle()
end

function update(args)
  local jumpActivated = args.moves["jump"] and not self.lastJump
  self.lastJump = args.moves["jump"]
  self.cancelJump = args.moves["special1"]
  self.stateTimer = math.max(0, self.stateTimer - args.dt)

  if mcontroller.groundMovement() or mcontroller.liquidMovement() then
    if self.state ~= "idle" then
      idle()
    end
    self.available = true
  end

  if self.state == "idle" then
    if jumpActivated and canRocketJump() then
      local direction = {0, 0}
      if args.moves["right"] then direction[1] = direction[1] + 1 end
      if args.moves["left"] then direction[1] = direction[1] - 1 end
      if args.moves["up"] then direction[2] = direction[2] + 1 end
      if args.moves["down"] then direction[2] = direction[2] - 1 end   
      if vec2.eq(direction, {0, 0}) then direction = {0, 1} end	
      boost(direction)  
    end
  elseif self.state == "boost" then
      local direction = {0, 0}
      if args.moves["right"] then direction[1] = direction[1] + 1 end
      if args.moves["left"] then direction[1] = direction[1] - 1 end
      if args.moves["up"] then direction[2] = direction[2] + 1 end
      if args.moves["down"] then direction[2] = direction[2] - 1 end 
      if vec2.eq(direction, {0, 0}) then direction = {0, 1} end	
      boost(direction)  
    if args.moves["jump"] then
	  if status.overConsumeResource("energy", self.energyCostPerSecond * args.dt) then
	    mcontroller.controlApproachVelocity(self.boostVelocity, self.boostForce)
	  else
	    idle()
	  end  
    elseif args.moves["special1"] then
	  if status.overConsumeResource("energy", self.energyCostPerSecond * args.dt) then
	    mcontroller.controlApproachVelocity(2, 2)
	  else
	    idle()
	  end 	  
    else
      idle()
    end
  end

  animator.setFlipped(mcontroller.facingDirection() < 0)
end

function canRocketJump()
  return self.available and not mcontroller.canJump()
end

function boost(direction)
  self.state = "boost"
  self.stateTimer = self.boostTime
  self.boostVelocity = vec2.mul(vec2.norm(direction), self.boostSpeed)
  tech.setParentState()
  animator.setAnimationState("boosting", "on")
  animator.setParticleEmitterActive("boostParticles", true)
end

function idle()
  self.state = "idle"
  self.stateTimer = 0
  status.clearPersistentEffects("movementAbility")
  tech.setParentState()
  animator.setAnimationState("boosting", "off")
  animator.setParticleEmitterActive("boostParticles", false)
end
