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
  self.stateTimer = math.max(0, self.stateTimer - args.dt)
  
	if args.moves["special1"] and status.overConsumeResource("energy", 0.07) then 
	  status.addEphemeralEffects{{effect = "nofalldamage", duration = 0.2}}
	  self.boostSpeed = 0
	  local direction = {0, 0}
	  boost(direction) 

	elseif args.moves["special1"] then
	  self.boostSpeed = 0
	else
	  self.boostSpeed = config.getParameter("boostSpeed")
	end

  if self.state == "idle" then
 
    if jumpActivated and canRocketJump() then
      local direction = {0, 0}
      if args.moves["right"] then direction[1] = direction[1] + 1 end
      if args.moves["left"] then direction[1] = direction[1] - 1 end
      if args.moves["up"] then direction[2] = direction[2] + 1 end
      if args.moves["down"] then direction[2] = direction[2] - 1 end

      if vec2.eq(direction, {0, 0}) then direction = {0, 0} end    
      boost(direction)
    end
  elseif self.state == "boost" then
      local direction = {0, 0}
      if args.moves["right"] then direction[1] = direction[1] + 1 end
      if args.moves["left"] then direction[1] = direction[1] - 1 end
      if args.moves["up"] then direction[2] = direction[2] + 1 end
      if args.moves["down"] then direction[2] = direction[2] - 1 end

      if vec2.eq(direction, {0, 0}) then direction = {0, 0} end
      boost(direction)  
    if args.moves["jump"] then
	  if status.overConsumeResource("energy", self.energyCostPerSecond * args.dt) then
	    mcontroller.controlApproachVelocity(self.boostVelocity, self.boostForce)
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
  return self.available
      --and not mcontroller.jumping()
      and not mcontroller.canJump()
      --and not mcontroller.liquidMovement()
      and not status.statPositive("activeMovementAbilities")
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
