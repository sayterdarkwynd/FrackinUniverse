require "/scripts/vec2.lua"
require "/scripts/poly.lua"

function init()
	self.doingAbility = false
	self.jumpSpeedMultiplier = config.getParameter("jumpSpeedMultiplier")
	self.fallGravityMultiplier = config.getParameter("fallGravityMultiplier")
	self.fallDamageMultiplier = config.getParameter("fallDamageMultiplier")
	self.flutterXVelocity = config.getParameter("flutterXVelocity")
	self.flutterYVelocity = config.getParameter("flutterYVelocity")
	self.flutterTime = config.getParameter("flutterTime")
	self.flutterAfterFall = config.getParameter("flutterAfterFall")
	self.flutterFall = config.getParameter("flutterFall")
	self.flutterTimer = 0
	self.flutterAble = false
	
	self.wallSlideParameters = config.getParameter("wallSlideParameters")
	self.wallJumpXVelocity = config.getParameter("wallJumpXVelocity")
	self.wallGrabFreezeTime = config.getParameter("wallGrabFreezeTime")
	self.wallGrabFreezeTimer = 0
	self.wallReleaseTime = config.getParameter("wallReleaseTime")
	self.wallReleaseTimer = 0
	
	self.lastJumpKey = false

	buildSensors()
	self.wallDetectThreshold = config.getParameter("wallDetectThreshold")
	self.wallCollisionSet = {"Dynamic", "Block"}
	releaseWall()
end

function update(args)
	if not disabled(args) and args.moves["jump"] and canAbility(args) then
		if not self.doingAbility then 
			self.doingAbility = true
			startAbility(args)
		end
		updateAbility(args)
	elseif self.doingAbility then
		self.doingAbility = false
		stopAbility(args)
	end
	
	if not disabled(args) and not self.doingAbility then
		if mcontroller.jumping() then
			updateJumping(args)
		end
		if mcontroller.falling() then
			updateFalling(args)
		end
		if mcontroller.groundMovement() or mcontroller.liquidMovement() then
			landed(args)
		end
	end
	
	if not disabled(args) then updateAlways(args)
	end
	
  local jumpActivated = args.moves["jump"] and not self.lastJumpKey
  self.lastJumpKey = args.moves["jump"]
  local lrInput
  if args.moves["left"] and not args.moves["right"] then
    lrInput = "left"
  elseif args.moves["right"] and not args.moves["left"] then
    lrInput = "right"
  end

  if mcontroller.groundMovement() or mcontroller.liquidMovement() then
    if self.wall then
      releaseWall()
    end
  elseif self.wall then
    mcontroller.controlParameters(self.wallSlideParameters)

    if not checkWall(self.wall) or status.statPositive("activeMovementAbilities") then
      releaseWall()
    elseif jumpActivated then
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
    end
  end
end

function disabled(args)
	return mcontroller.liquidMovement()
		or status.statPositive("activeMovementAbilities")
end

function canAbility(args)
	return not mcontroller.jumping()
		and not mcontroller.canJump()
		and args.moves["jump"] 
		and ( not ( mcontroller.velocity()[2] > 0 ) or self.doingAbility )
end

function landed(args)
	tech.setParentState()
	if self.doingAbility then
		self.doingAbility = false
		stopAbility(args)
	end
	self.flutterAble = true
end

function startAbility(args)
	if self.flutterAble then
		self.flutterAble = false
		self.flutterTimer = self.flutterTime
		tech.setParentState("run")
		animator.setParticleEmitterActive("flutterParticles", true)
		animator.playSound("flutter")
	else
		self.doingAbility = false
		stopAbility(args)
	end
end

function stopAbility(args)
	animator.setParticleEmitterActive("flutterParticles", false)
	animator.stopAllSounds("flutter")
end

function updateAbility(args)
	if self.flutterTimer > 0 then
		tech.setParentState("run")
		local vel = mcontroller.velocity()
		vel[1] = self.flutterXVelocity * mcontroller.facingDirection()
		vel[2] = self.flutterYVelocity
		mcontroller.setVelocity(vel)
	else
		self.doingAbility = false
		stopAbility(args)
	end
	self.flutterTimer = self.flutterTimer - args.dt
end

function updateJumping(args)
	local params = mcontroller.baseParameters()
	params.airJumpProfile.jumpSpeed = params.airJumpProfile.jumpSpeed * self.jumpSpeedMultiplier
	mcontroller.controlParameters(params)
end

function updateFalling(args)
	if not self.flutterAfterFall then self.flutterAble = false end
	if self.flutterFall then tech.setParentState("run")
	else tech.setParentState() end
	local params = mcontroller.baseParameters()
	params.gravityMultiplier = params.gravityMultiplier * self.fallGravityMultiplier
	mcontroller.controlParameters(params)
end

function updateAlways(args)
	 status.setPersistentEffects ( "movementAbility", { {stat = "fallDamageMultiplier", effectiveMultiplier = self.fallDamageMultiplier } } )
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
  self.doingAbility = false
  stopAbility(nil)
  self.wall = wall
  self.wallGrabFreezeTimer = self.wallGrabFreezeTime
  self.wallReleaseTimer = 0
  mcontroller.setVelocity({0, 0})
  tech.setToolUsageSuppressed(true) -- cannot use tools while grabbing
  tech.setParentState("fly")
  animator.playSound("wallGrab")
end

function releaseWall()
  self.wall = nil
  tech.setToolUsageSuppressed(false) -- cannot use tools while grabbing
  tech.setParentState()
  animator.setParticleEmitterActive("wallSlide.left", false)
  animator.setParticleEmitterActive("wallSlide.right", false)
  animator.stopAllSounds("wallSlideLoop")
end
