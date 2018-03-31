require "/scripts/vec2.lua"

function init()
  self.energyCost = config.getParameter("energyCost",50)
  self.timer = 0
end

function update(args)
  if self.timer > 0 then
    self.timer = math.max(0, self.timer - args.dt)
  end
  
  if args.moves["special1"] and self.timer == 0 and math.abs(mcontroller.xVelocity()) < 1 then
    attemptActivation()
  end
end


function attemptActivation()
  if mcontroller.onGround() and status.overConsumeResource("energy", self.energyCost) then
      activate()
  end
end



function activate()
        animator.playSound("activate")
        animator.burstParticleEmitter("healing")
	configBombDrop = { timeToLive = 5}
	self.timer = 5
      	world.spawnProjectile("healingzone", mcontroller.position(), entity.id(), {0, 0}, false, configBombDrop)
end
