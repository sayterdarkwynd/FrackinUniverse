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
        if self.wallGrabFreezeTimer > 0 then
          self.wallGrabFreezeTimer = math.max(0, self.wallGrabFreezeTimer - args.dt)
          mcontroller.controlApproachVelocity({0, 0}, 1000)
          if self.wallGrabFreezeTimer == 0 then
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
    -- world.debugPoint(vec2.add(pos, offset), world.pointCollision(vec2.add(pos, offset), self.wallCollisionSet) and "yellow" or "blue")
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
  releaseWall()
end

function grabWall(wall)
  self.wall = wall
  self.wallGrabFreezeTimer = self.wallGrabFreezeTime
  self.wallReleaseTimer = 0
  mcontroller.setVelocity({0, 0})
 
  tech.setParentState("fly")
  animator.playSound("wallGrab")
end

function releaseWall()
  self.wall = nil
  tech.setToolUsageSuppressed(false)
  tech.setParentState()
  animator.setParticleEmitterActive("wallSlide.left", false)
  animator.setParticleEmitterActive("wallSlide.right", false)
  animator.stopAllSounds("wallSlideLoop")
end
