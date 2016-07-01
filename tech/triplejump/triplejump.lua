function init()
  self.multiJumps = 0
  self.lastJump = false
end

function input(args)
  if args.moves["jump"] and not mcontroller.jumping() and not mcontroller.canJump() and not self.lastJump then
    self.lastJump = true
    return "multiJump"
  else
    self.lastJump = args.moves["jump"]
    return nil
  end
end

function update(args)
  local multiJumpCount = tech.parameter("multiJumpCount")
  local energyUsage = tech.parameter("energyUsage")

  if args.actions["multiJump"] and self.multiJumps < multiJumpCount and (energyUsage == 0 or tech.consumeTechEnergy(energyUsage)) then
    mcontroller.controlJump(true)
    self.multiJumps = self.multiJumps + 1
    tech.burstParticleEmitter("multiJumpParticles")
    tech.playSound("multiJumpSound")
  else
    if mcontroller.onGround() or mcontroller.liquidMovement() then
      self.multiJumps = 0
    end
  end
end
