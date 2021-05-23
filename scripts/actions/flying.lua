require "/scripts/poly.lua"


-- param keepGroundDistance
-- param keepCeilingDistance
-- param yVelocityVariance
-- param maxXVelocityu
-- param maxYVelocity
function flyAlongGround(args, board)
	local baseParameters = mcontroller.baseParameters()
	if not args.keepGroundDistance or not args.keepCeilingDistance or not args.maxXVelocity or not args.maxYVelocity then return false end

	while true do
		local groundLine = poly.translate({{0, 0}, {0, -args.keepGroundDistance * 2}}, mcontroller.position())
		local ceilingLine = poly.translate({{0, 0}, {0, args.keepCeilingDistance}}, mcontroller.position())
		local groundPoint = world.lineCollision(groundLine[1], groundLine[2]) or groundLine[2]
		local ceilingPoint = world.lineCollision(ceilingLine[1], ceilingLine[2]) or ceilingLine[2]

		-- Find liquid
		local x = mcontroller.position()[1]
		for y=groundLine[1][2], groundPoint[2], -1 do
			y = math.floor(y)
			local liquid = world.liquidAt({x, y})
			if liquid then
				groundPoint = {x, y + liquid[2]}
				break
			end
		end

		-- Move the ground point up by the height we want to keep,
		-- gives us the y position we want to stay around
		local groundApproachPoint = vec2.add(groundPoint, {0, args.keepGroundDistance})
		local keepGroundDistanceFactor = world.distance(groundApproachPoint, mcontroller.position())[2] / args.keepGroundDistance

		-- Keep away from the ceiling
		local keepCeilingDistanceFactor = (-args.keepCeilingDistance + world.distance(ceilingPoint, mcontroller.position())[2]) / args.keepCeilingDistance

		local yVelocityFactor = keepGroundDistanceFactor + keepCeilingDistanceFactor

		mcontroller.controlApproachVelocity({mcontroller.facingDirection() * args.maxXVelocity, yVelocityFactor * args.maxYVelocity}, baseParameters.airForce)

		coroutine.yield()
	end
end

-- param centerPosition
-- param maxDistance
-- param collisionArea
-- param lerpStep
-- output position
function findAirPosition(args, board)
	if args.centerPosition == nil or args.maxDistance == nil then return false end

	for i = 0, args.maxDistance, args.lerpStep do
		for a = 0, math.pi*2, math.pi/4 do
			local dir = {math.cos(a), math.sin(a)}
			local position = vec2.add(args.centerPosition, vec2.mul(dir, i))
			if not world.rectTileCollision(rect.translate(args.collisionArea, position)) then
				return true, {position = position}
			end
		end
	end

	return false
end

-- param position
-- param maxAngle
-- param speed
function flyInGeneralDirection(args, board)
	local speed = args.speed or mcontroller.baseParameters().flySpeed

	local direction
	while true do
		mcontroller.controlDown()
		local maxAngle = util.toRadians(args.maxAngle)
	local pos=args.position or entity.position()
		local toTarget = vec2.norm(world.distance(pos, mcontroller.position()))
		if direction == nil or math.acos(vec2.dot(toTarget, direction)) > maxAngle then
			direction = vec2.rotate(toTarget, (util.randomDirection() * math.random() * maxAngle))
		end

		mcontroller.controlApproachVelocity(vec2.mul(direction, speed), mcontroller.baseParameters().airForce)
		mcontroller.controlFace(util.toDirection(toTarget[1]))

		coroutine.yield()
	end

	return true
end


function swarmPosition(args, board, _, dt)
	local bounds = mcontroller.boundBox()
	local position = args.center

	if world.lineTileCollision(position, mcontroller.position()) then
		return false
	end
	repeat
		local distance = math.random(0, args.maxRange)
		local angle = math.random() * math.pi * 2
		local offset = {math.cos(angle) * distance, math.sin(angle) * distance}
		position = vec2.add(args.center, offset)
		coroutine.yield()
	until not world.lineTileCollision(args.center, position)
		and not world.rectTileCollision(rect.translate(bounds, position))
		and world.magnitude(position, mcontroller.position()) > args.minMoveDistance

	repeat
		local toTarget = world.distance(position, mcontroller.position())
		mcontroller.controlFly(toTarget)

		if world.rectTileCollision(rect.translate(rect.pad(bounds, 0.25), mcontroller.position())) then
			return false
		end
		coroutine.yield()
	until world.magnitude(position, mcontroller.position()) < 1.0

	local timer = args.idleTime
	while timer > 0 do
		timer = timer - dt
		dt = coroutine.yield()
	end
	return true
end

-- param entity
-- param turnSpeed
-- output angle
-- output direction
function approachTurn(args, output, _, dt)
	local targetPosition = world.entityPosition(args.entity)
	local distance = world.magnitude(targetPosition, mcontroller.position())
	while true do
		local toTarget = world.distance(targetPosition, mcontroller.position())
		local angle = mcontroller.rotation()

		local targetAngle = vec2.angle(toTarget)
		local diff = util.angleDiff(angle, targetAngle)
		if diff ~= 0 then
			angle = angle + (util.toDirection(diff) * args.turnSpeed) * dt
			if util.angleDiff(angle, targetAngle) * diff < 0 then
				angle = targetAngle
			end
		end

		local collisionRect = rect.translate(mcontroller.boundBox(), vec2.add(mcontroller.position(), vec2.withAngle(angle, 0.25)))
		if world.rectTileCollision(collisionRect) then
			angle = angle + math.pi
			mcontroller.setVelocity(vec2.mul(mcontroller.velocity(), -1))
		end

		mcontroller.setRotation(angle)
		local speedRatio = math.max(0.2, vec2.dot(vec2.norm(toTarget), vec2.withAngle(angle)) ^ 3)
		local speed = speedRatio * mcontroller.baseParameters().flySpeed
		mcontroller.controlApproachVelocity(vec2.withAngle(angle, speed), mcontroller.baseParameters().airForce, true)
		mcontroller.controlApproachVelocityAlongAngle(angle + math.pi * 0.5, 0, 50, false)

		coroutine.yield(nil, {angle = angle, direction = diff})

		targetPosition = world.entityPosition(args.entity)
		distance = world.magnitude(targetPosition, mcontroller.position())
	end
end

function approachBurn(args, output, _, dt)
	local burn = function(toVelocity)
		local timer = args.burnTime
		local angle = vec2.angle(vec2.sub(toVelocity, mcontroller.velocity()))
		while timer > 0 do
			timer = timer - dt
			mcontroller.controlApproachVelocity(toVelocity, mcontroller.baseParameters().airForce)
			coroutine.yield(nil, {burning = true, angle = angle})
		end
	end

	local flySpeed = mcontroller.baseParameters().flySpeed

	local targetPosition = world.entityPosition(args.entity)
	local toTarget = vec2.norm(world.distance(targetPosition, entity.position()))
	local targetVelocity = world.entityVelocity(args.entity)

	local distance = world.magnitude(entity.position(), targetPosition)
	local approach = vec2.add(targetPosition, vec2.mul(toTarget, -args.approachRadius))
	local toApproach = vec2.norm(world.distance(approach, entity.position()))
	local approachSpeed = flySpeed + vec2.mag(targetVelocity)
	if distance < args.approachRadius * 2 then
		local angle = math.atan(args.approachRadius, distance / 2)
		local directions = {
			vec2.rotate(toTarget, angle),
			vec2.rotate(toTarget, -angle)
		}
		shuffle(directions)

		for _,dir in pairs(directions) do
			local test = vec2.add(targetPosition, vec2.mul(dir, args.approachRadius))
			if not world.lineTileCollision(entity.position(), test) then
				approach = test
				break
			end
		end
		local approachVelocity = vec2.mul(vec2.norm(world.distance(approach, entity.position())), flySpeed)
		approachSpeed = vec2.mag(vec2.add(approachVelocity, targetVelocity))
		approach = util.predictedPosition(approach, entity.position(), targetVelocity, approachSpeed)
	end

	local toApproach = vec2.norm(world.distance(approach, entity.position()))
	burn(vec2.mul(toApproach, approachSpeed))

	-- while going in roughly the same direction
	-- at roughly the same speed
	-- and still moving toward the approach position
	-- and still within a reasonable range of the target
	while vec2.dot(mcontroller.velocity(), toApproach) > 0.95
		 and vec2.mag(mcontroller.velocity()) / approachSpeed > 0.75
		 and vec2.dot(world.distance(approach, entity.position()), toApproach) > 0 do

		world.debugLine(entity.position(), approach, "yellow")
		if world.rectTileCollision(rect.translate(mcontroller.boundBox(), entity.position())) then
			return false
		end

		coroutine.yield(nil, {burning = false})
	end

	burn(world.entityVelocity(args.entity))

	return true, {burning = false}
end

function approachFall(args, output, _, dt)
	local flySpeed = mcontroller.baseParameters().flySpeed
	while true do
		local targetPosition = world.entityPosition(args.target)
		local toTarget = world.distance(targetPosition, mcontroller.position())
		local airForce = mcontroller.baseParameters().airForce
		if vec2.dot(toTarget, mcontroller.velocity()) < 0 and vec2.mag(toTarget) > args.dampenDistance then
			airForce = airForce * args.dampenMultiplier
		end
		mcontroller.controlApproachVelocity(vec2.mul(vec2.norm(toTarget), flySpeed), airForce)

		local perpendicular = vec2.angle(toTarget) + math.pi / 2
		mcontroller.controlApproachVelocityAlongAngle(perpendicular, 0, args.friction, false)
		coroutine.yield()
	end
end
