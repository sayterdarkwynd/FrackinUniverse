function init()
  self.active = false
end

function input(args)
  if args.moves["special"] == 1 ~= self.active then
    if self.active then
      return "deactivate"
    else
      return "activate"
    end
  end
end

function update(args)
  local bounceCollisionPoly = tech.parameter("bounceCollisionPoly")
  local bounceFactor = tech.parameter("bounceFactor")
  local energyUsagePerSecond = tech.parameter("energyUsagePerSecond")
  
  if args.actions["activate"] then
    self.active = true
    tech.playSound("activate")
  elseif args.actions["deactivate"] then
    self.active = false
  end

  if self.active and tech.consumeTechEnergy(energyUsagePerSecond * args.dt) then
    mcontroller.controlParameters({
      frictionEnabled = false,
      gravityEnabled = false
    })
    tech.setAnimationState("boosting", "on")
    tech.setParticleEmitterActive("boostParticles", true)
  else
    tech.setAnimationState("boosting", "off")
    tech.setParticleEmitterActive("boostParticles", false)
  end
end
