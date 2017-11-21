require "/tech/jump/multijump.lua"
require "/scripts/vec2.lua"
require "/scripts/poly.lua"

function init()
  self.energyCost = config.getParameter("energyCost")
  self.multiJumpCount = config.getParameter("multiJumpCount")
  self.multiJumpModifier = config.getParameter("multiJumpModifier")

  self.wallSlideParameters = config.getParameter("wallSlideParameters")
  self.wallJumpXVelocity = config.getParameter("wallJumpXVelocity")
  self.wallGrabFreezeTime = config.getParameter("wallGrabFreezeTime")
  self.wallGrabFreezeTimer = 0
  self.wallReleaseTime = config.getParameter("wallReleaseTime")
  self.wallReleaseTimer = 0
 
  self.healTimer = 0
  self.pressDown = false
  self.soundPlay = false
  self.effectTimer = 0
  self.effectDelay = 0.8
  self.invisibleBlockTimer = 0.0
  self.setInv = false

  buildSensors()
  self.wallDetectThreshold = config.getParameter("wallDetectThreshold")
  self.wallCollisionSet = {"Dynamic", "Block"}

  refreshJumps()
  releaseWall()
end

function uninit()
  releaseWall()
end

function update(args)
  local jumpActivated = args.moves["jump"] and not self.lastJump
  self.lastJump = args.moves["jump"]

  self.pressDown = args.moves["down"]
  if mcontroller.onGround() then
    self.effectTimer = 0
  end

  updateJumpModifier()

  local lrInput
  if args.moves["left"] and not args.moves["right"] then
    lrInput = "left"
  elseif args.moves["right"] and not args.moves["left"] then
    lrInput = "right"
  end

  if mcontroller.groundMovement() or mcontroller.liquidMovement() then
    refreshJumps()
    if self.wall then
      releaseWall()
    end
  elseif self.wall then
    refreshJumps()
    mcontroller.controlParameters(self.wallSlideParameters)

    if not checkWall(self.wall) or status.statPositive("activeMovementAbilities") then
      releaseWall()
    elseif jumpActivated and status.overConsumeResource("energy", self.energyCost) then
      doWallJump()
      animator.playSound("wallJumpSound")
    else
      if lrInput and lrInput ~= self.wall then
        self.wallReleaseTimer = self.wallReleaseTimer + args.dt
      else
        self.wallReleaseTimer = 0
      end

      if self.wallReleaseTimer > self.wallReleaseTime then
        releaseWall()
      else
        mcontroller.controlFace(self.wall == "left" and 1 or -1)

        if args.moves["up"] then
          goUpside()
        end

        if not self.pressDown then
          mcontroller.controlApproachVelocity({0, 0}, 1000)
          animator.stopAllSounds("wallSlideLoop")
          self.soundPlay = false
        else
          if not self.soundPlay then
            self.soundPlay = true
            animator.setParticleEmitterActive("wallSlide."..self.wall, true)
            animator.playSound("wallSlideLoop", -1)
          end
        end
      end
    end
  elseif not status.statPositive("activeMovementAbilities") then
    if lrInput and not mcontroller.jumping() and checkWall(lrInput) then
      grabWall(lrInput)
    elseif jumpActivated and canMultiJump() then
      doMultiJump()
    end
  end

  if self.wall then
    self.effectTimer = self.effectDelay
  else
    self.effectTimer = self.effectTimer - args.dt
  end

  self.invisibleBlockTimer = self.invisibleBlockTimer - args.dt

  if args.moves["primaryFire"] or args.moves["altFire"] then
    self.invisibleBlockTimer = 0.5
  end
  
  if self.setInv and self.invisibleBlockTimer <= 0 then
    setWallClingAbility()
  else
    unsetWallClingAbility()
  end
end

function buildSensors()
  local bounds = poly.boundBox(mcontroller.baseParameters().standingPoly)
  self.wallSensors = {
    right = {},
    left = {}
  }
  for _, offset in pairs(config.getParameter("wallSensors")) do
    table.insert(self.wallSensors.left, {bounds[1] - 0.1, bounds[2] + offset})
    table.insert(self.wallSensors.right, {bounds[3] + 0.1, bounds[2] + offset})
  end
end

function checkWall(wall)
  local pos = mcontroller.position()
  local wallCheck = 0
  for _, offset in pairs(self.wallSensors[wall]) do
    if world.pointCollision(vec2.add(pos, offset), self.wallCollisionSet) then
      wallCheck = wallCheck + 1
    end
  end
  return wallCheck >= self.wallDetectThreshold
end

function doWallJump()
  mcontroller.controlJump(true)
  animator.playSound("wallJumpSound")
  animator.burstParticleEmitter("wallJump."..self.wall)
  mcontroller.setXVelocity(self.wall == "left" and self.wallJumpXVelocity or -self.wallJumpXVelocity)
  mcontroller.setYVelocity(20)
  releaseWall()
end

function grabWall(wall)
  self.wall = wall
  self.wallGrabFreezeTimer = self.wallGrabFreezeTime
  self.wallReleaseTimer = 0
  mcontroller.setVelocity({0, 0})
  tech.setParentState("fly")
  animator.playSound("wallGrab")
  refreshJumps()
  self.setInv = true
end

function releaseWall()
  self.wall = nil
  tech.setToolUsageSuppressed(false)
  tech.setParentState()
  animator.setParticleEmitterActive("wallSlide.left", false)
  animator.setParticleEmitterActive("wallSlide.right", false)
  animator.stopAllSounds("wallSlideLoop")
  self.setInv = false
  self.soundPlay = false
end

function goUpside()
  doWallJump();
end

function setWallClingAbility()
  status.addPersistentEffect("wallCling", "percentenergyboost20", math.huge);
  status.addPersistentEffect("wallCling", "percentarmorboost10", math.huge);
end

function unsetWallClingAbility()
  status.clearPersistentEffects("wallCling");
end

