require "/tech/distortionsphere/distortionsphere.lua"
require "/scripts/rect.lua"
require "/scripts/poly.lua"
require "/scripts/status.lua"

function init()
  initCommonParameters()

  self.ignorePlatforms = config.getParameter("ignorePlatforms")
  self.damageDisableTime = config.getParameter("damageDisableTime")
  self.damageDisableTimer = 0

  self.normalCollisionSet = {"Block", "Dynamic"}
  if self.ignorePlatforms then
    self.platformCollisionSet = self.normalCollisionSet
  else
    self.platformCollisionSet = {"Block", "Dynamic", "Platform"}
  end

  self.damageListener = damageListener("damageTaken", function(notifications)
    for _, notification in pairs(notifications) do
      if notification.healthLost > 0 and notification.sourceEntityId ~= entity.id() then
        damaged()
        return
      end
    end
  end)
end

function update(args)
  restoreStoredPosition()

  if not self.specialLast and args.moves["special"] == 1 then
    attemptActivation()
  end
  self.specialLast = args.moves["special"] == 1

  self.damageDisableTimer = math.max(0, self.damageDisableTimer - args.dt)

  self.damageListener:update()

  if self.active then
    local groundDirection
    if self.damageDisableTimer == 0 then
      groundDirection = findGroundDirection()
    end

    if groundDirection then
      local ground, headingDirection, headingAngle = setGroundDirection(groundDirection)

      -- Rotate to ground slope
      local newDirection = groundSlopeDirection(headingAngle)
      if newDirection then
        headingDirection = newDirection
        headingAngle = math.atan(headingDirection[2], headingDirection[1])
        ground = vec2.rotate(headingDirection, -math.pi / 2)
      end

      mcontroller.controlApproachVelocity(vec2.mul(ground, self.ballSpeed), 300)

      local moveInput = 0

      -- more complicated controls
      -- if ground[1] < -0.1 then
      --   if args.moves["up"] then moveInput = moveInput - 1 end
      --   if args.moves["down"] then moveInput = moveInput + 1 end
      -- elseif ground[1] > 0.1 then
      --   if args.moves["up"] then moveInput = moveInput + 1 end
      --   if args.moves["down"] then moveInput = moveInput - 1 end
      -- end

      -- if ground[2] < -0.1 then
      --   if args.moves["right"] then moveInput = moveInput + 1 end
      --   if args.moves["left"] then moveInput = moveInput - 1 end
      -- elseif ground[2] > 0.1 then
      --   if args.moves["right"] then moveInput = moveInput - 1 end
      --   if args.moves["left"] then moveInput = moveInput + 1 end
      -- end

      -- simpler controls
      if args.moves["left"] then
        moveInput = -1
      elseif args.moves["right"] then
        moveInput = 1
      end

      if moveInput ~= 0 then
        moveInput = math.min(1, math.max(-1, moveInput))

        local moveDirection = vec2.mul(headingDirection, moveInput)
        mcontroller.controlApproachVelocityAlongAngle(math.atan(moveDirection[2], moveDirection[1]), self.ballSpeed, 2000)

        self.angularVelocity = self.ballSpeed * -moveInput

        if self.ignorePlatforms then
          mcontroller.controlDown()
        end

        -- world.debugLine(mcontroller.position(), vec2.add(vec2.mul(moveDirection, 5), mcontroller.position()), "yellow")
      else
        self.angularVelocity = 0
        mcontroller.controlApproachVelocity({0, 0}, 500)
      end

      -- world.debugLine(mcontroller.position(), vec2.add(mcontroller.position(), vec2.mul(vec2.rotate(headingDirection, -math.pi / 2), 5)), "blue")

      self.transformedMovementParameters.gravityEnabled = false
    else
      updateAngularVelocity(args.dt)
      self.transformedMovementParameters.gravityEnabled = true
    end

    mcontroller.controlParameters(self.transformedMovementParameters)
    status.setResourcePercentage("energyRegenBlock", 1.0)

    updateRotationFrame(args.dt)
  end

  updateTransformFade(args.dt)

  self.lastPosition = mcontroller.position()
end

function damaged()
  if self.active then
    self.damageDisableTimer = self.damageDisableTime
  end
end

function groundSlopeDirection(headingAngle)
  local bounds = mcontroller.boundBox()

  local leftLine = poly.translate(poly.rotate({{bounds[1] - 0.1, bounds[4] - 0.5}, {bounds[1] - 0.1, bounds[2] - 1}}, headingAngle), mcontroller.position())
  local rightLine = poly.translate(poly.rotate({{bounds[3] + 0.1, bounds[4] - 0.5}, {bounds[3] + 0.1, bounds[2] - 1}}, headingAngle), mcontroller.position())

  -- world.debugLine(leftLine[1], leftLine[2], "red")
  -- world.debugLine(rightLine[1], rightLine[2], "red")

  local collisionSet = leftLine[2][2] < leftLine[1][2] and self.platformCollisionSet or self.normalCollisionSet
  local leftIntersect = world.lineCollision(leftLine[1], leftLine[2], collisionSet) or leftLine[2]
  local rightIntersect = world.lineCollision(rightLine[1], rightLine[2], collisionSet) or rightLine[2]
  if leftIntersect and rightIntersect then
    return vec2.norm(world.distance(rightIntersect, leftIntersect))
  end
end

function setGroundDirection(ground)
  local headingDirection = {-ground[2], ground[1]}
  local headingAngle = math.atan(headingDirection[2], headingDirection[1])
  return ground, headingDirection, headingAngle
end

function findGroundDirection()
  local bounds = mcontroller.boundBox()
  local groundRect = {bounds[1], bounds[2] - config.getParameter("groundStickDistance", 0.25), bounds[3], bounds[2]}
  local directions = {{0,-1}, {1,0}, {0,1}, {-1,0}}
  for i = 1, 4 do
    local angle = (i - 1) * math.pi / 2
    local collisionSet = i == 1 and self.platformCollisionSet or self.normalCollisionSet
    if world.rectTileCollision(rect.translate(rect.rotate(groundRect, angle), mcontroller.position()), collisionSet) then
      return directions[i]
    end
  end
end
