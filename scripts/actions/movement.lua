require "/scripts/poly.lua"
require "/scripts/rect.lua"
require "/scripts/pathutil.lua"

function controlFace(direction)
	direction = direction > 0 and 1 or -1
	if npc then
		mcontroller.controlFace(direction)
		npc.setAimPosition(vec2.add(mcontroller.position(), {direction * 4, -4}))
	else
		if config.getParameter("facingMode", "control") == "transformation" then
			mcontroller.controlFace(1)
		if animator.hasTransformationGroup("facing") then
				animator.resetTransformationGroup("facing")
				animator.scaleTransformationGroup("facing", {util.toDirection(direction), 1})
		end
			self.facingDirection = direction
		else
			mcontroller.controlFace(direction)
		end
	end
end

---------------------------------
-- ACTIONS
---------------------------------

-- param entity
-- param target
-- param offset
-- output direction
-- output vector
-- output yDirection
function entityDirection(args, board)
	if args.entity == nil or not world.entityExists(args.entity) or args.target == nil or not world.entityExists(args.target) then return false end

	local toTarget = world.distance(world.entityPosition(args.target), vec2.add(world.entityPosition(args.entity), args.offset))
	return true, {vector = toTarget, direction = util.toDirection(toTarget[1]), yDirection = util.toDirection(toTarget[2])}
end

-- param position
-- param target
-- param heading
-- param facingDirection
-- output angle
-- output direction
function entityAngle(args, board)
	if (args.position == nil) or (args.entity == nil) then return false end
	local entPos=world.entityPosition(args.entity)
	if not entPos then return false end
	local toEntity = world.distance(entPos, args.position)
	toEntity = vec2.norm(vec2.rotate(toEntity, -args.heading))

	return true, {angle = math.atan(toEntity[2], math.abs(toEntity[1])), direction = toEntity[1]}
end

-- param direction
-- param run
function move(args, board, node)
	local bounds = mcontroller.boundBox()

	while true do
		local direction = util.toDirection(args.direction)
		local run = args.run
		if config.getParameter("pathing.forceWalkingBackwards", false) then
			if run == true then run = mcontroller.movingDirection() == mcontroller.facingDirection() end
		end

		if args.direction == nil then return false end
		local position = mcontroller.position()
		position = {position[1], math.ceil(position[2]) - (bounds[2] % 1)} -- align bottom of the bound box with the ground

		local move = false
		-- Check for walls
		for _,yDir in pairs({0, -1, 1}) do
			--util.debugRect(rect.translate(bounds, vec2.add(position, {direction * 0.2, yDir})), "yellow")
			if not world.rectTileCollision(rect.translate(bounds, vec2.add(position, {direction * 0.2, yDir}))) then
				move = true
				break
			end
		end

		-- Also specifically check for a dumb collision geometry edge case where the ground goes like:
		--
		--				#
		-- ###### ######
		-- #############
		local boundsEnd = direction > 0 and bounds[3] or bounds[1]
		local wallPoint = {position[1] + boundsEnd + direction * 0.5, position[2] + bounds[2] + 0.5}
		local groundPoint = {position[1] + boundsEnd - direction * 0.5, position[2] + bounds[2] - 0.5}
		if world.pointTileCollision(wallPoint) and not world.pointTileCollision(groundPoint) then
			move = false
		end

		-- Check for ground for the entire length of the bound box
		-- Makes it so the entity can stop before a ledge
		if move then
			local boundWidth = bounds[3] - bounds[1]
			local groundRect = rect.translate({bounds[1], bounds[2] - 1.0, bounds[3], bounds[2]}, position)
			local y = 0
			for x = boundWidth % 1, math.ceil(boundWidth) do
				move = false
				for _,yDir in pairs({0, -1, 1}) do
					--util.debugRect(rect.translate(groundRect, {direction * x, y + yDir}), "blue")
					if world.rectTileCollision(rect.translate(groundRect, {direction * x, y + yDir}), {"Null", "Block", "Dynamic", "Platform"}) then
						move = true
						y = y + yDir
						break
					end
				end
				if move == false then break end
			end
		end

		if move then
			moved = true
			mcontroller.controlMove(direction, run)
			if not self.setFacingDirection then controlFace(direction) end
		else
			if moved then
				mcontroller.setXVelocity(0)
				mcontroller.clearControls()
			end
			return false
		end
		coroutine.yield()
	end
end

-- param direction
function canMove(args, board)
	if args.direction == nil then return false end

	local position = vec2.add(mcontroller.position(), {args.direction, 0})
	if args.direction > 0 then
		position[1] = math.ceil(position[1])
	else
		position[1] = math.floor(position[1])
	end
	local groundPosition = findGroundPosition(position, -1, 1, true, {"Null", "Block", "Dynamic", "Slippery"})

	if groundPosition then
		return true
	else
		return false
	end
end

function isMoving(args, board)
	return mcontroller.walking() or mcontroller.running()
end

-- param direction
-- param run
function controlMove(args, board)
	local run = args.run
	if config.getParameter("pathing.forceWalkingBackwards", false) then
		if run == true then run = mcontroller.movingDirection() == mcontroller.facingDirection() end
	end

	if args.direction == nil then return false end

	mcontroller.controlMove(args.direction, run)
	return true
end

function controlDown(args, board)
	mcontroller.controlDown()
	return true
end

function controlCrouch(args, board)
	mcontroller.controlCrouch()
	return true
end

function controlJump(args, board)
	mcontroller.controlJump()
	mcontroller.controlHoldJump()
	return true
end

-- param direction
-- output direction
function setDirection(args, board)
	local direction = args.direction or util.randomDirection()
	if direction == nil then return false end

	return true, {direction = util.toDirection(direction)}
end

-- param direction
-- output direction
function reverseDirection(args, board)
	if args.direction == nil then return false end
	return true, {direction = -args.direction}
end

-- param position
-- param run
-- param runSpeed
-- param groundPosition
-- param minGround
-- param maxGround
-- param avoidLiquid
-- output direction
-- output pathfinding
function moveToPosition(args, board, node)
	if args.position == nil then return false end

	if entity.entityType() == "npc" then npc.resetLounging() end
	local pathOptions = applyDefaults(args.pathOptions or {}, {
		returnBest = false,
		mustEndOnGround = mcontroller.baseParameters().gravityEnabled,
		maxDistance = 200,
		swimCost = 5,
		dropCost = 5,
		boundBox = mcontroller.boundBox(),
		droppingBoundBox = rect.pad(mcontroller.boundBox(), {0.2, 0}), --Wider bound box for dropping
		standingBoundBox = rect.pad(mcontroller.boundBox(), {-0.7, 0}), --Thinner bound box for standing and landing
		smallJumpMultiplier = 1 / math.sqrt(2), -- 0.5 multiplier to jump height
		jumpDropXMultiplier = 1,
		enableWalkSpeedJumps = true,
		enableVerticalJumpAirControl = false,
		maxFScore = 400,
		maxNodesToSearch = 70000,
		maxLandingVelocity = -10.0,
		liquidJumpCost = 15
	})


	local lastPosition = false
	local targetPosition = {args.position[1], args.position[2]}

	local updateTarget = function()
		lastPosition = {args.position[1], args.position[2]}
		if args.groundPosition then
			targetPosition = findGroundPosition(lastPosition, args.minGround, args.maxGround, args.avoidLiquid)
		else
			targetPosition = lastPosition
		end
	end

	updateTarget()
	if not targetPosition then
		return false
	end
	local result = mcontroller.controlPathMove(targetPosition, args.run, pathOptions)
	while true do
		if not lastPosition or world.magnitude(args.position, lastPosition) > 2 then
			updateTarget()
			if not targetPosition then
				return false
			end
		end

		if result == false or result == true then
			return result
		end
		result = mcontroller.controlPathMove(targetPosition, args.run)
		if not self.setFacingDirection then
			if not mcontroller.groundMovement() then
				controlFace(mcontroller.velocity()[1])
			elseif mcontroller.running() or mcontroller.walking() then
				controlFace(mcontroller.movingDirection())
			end
		end

		if entity.entityType() == "npc" then
			--openDoorsAhead()
			if args.closeDoors then
				closeDoorsBehind()
			end
		end

		coroutine.yield(nil, {pathfinding = mcontroller.pathfinding(), direction = mcontroller.facingDirection()})
	end
end
-- param velocity
-- param x
-- param y
function setVelocity(args, board)
	local velocity = (args.x and args.y) and {args.x, args.y} or args.velocity
	if velocity == nil then return false end

	mcontroller.setVelocity(velocity)
	return true
end

-- output velocity
-- output x
-- output y
function velocity(args, board)
	local velocity = mcontroller.velocity()
	return true, {velocity = velocity, x = velocity[1], y = velocity[2]}
end

-- param velocity
-- param force
function controlApproachVelocity(args, board)
	if args.velocity == nil or args.force == nil then return false end
	mcontroller.controlApproachVelocity(args.velocity, args.force)
	return true
end

-- param angle
-- param velocity
-- param force
function controlApproachVelocityAlongAngle(args, board)
	if args.velocity == nil or args.force == nil or args.angle == nil then return false end
	mcontroller.controlApproachVelocityAlongAngle(args.angle, args.velocity, args.force)
	return true
end

-- param velocity
-- param force
function controlApproachXVelocity(args, board)
	if args.velocity == nil or args.force == nil then return false end

	mcontroller.controlApproachXVelocity(args.velocity, args.force)
	return true
end

-- param entity
-- param headingDirection
function faceEntity(args, board)
	if args.entity == nil or not world.entityExists(args.entity) then return false end
	local position = world.entityPosition(args.entity)

	local toEntity = world.distance(position, mcontroller.position())
	local direction = util.toDirection(vec2.dot(vec2.norm(toEntity), args.headingDirection))
	controlFace(direction)

	self.setFacingDirection = true
	return true
end

-- param direction
function faceDirection(args, board)
	if args.direction == nil then return false end

	controlFace(args.direction)
	self.setFacingDirection = true
	return true
end

function onGround(args, output)
	return mcontroller.onGround()
end

-- param percentage
function inLiquid(args, board)
	return mcontroller.liquidPercentage() >= (args.percentage or 1.0)
end

-- param position
-- param tolerance
-- output vector
function flyToPosition(args, board)
	while true do
		if not args.position then return false end
		local speed = args.speed or mcontroller.baseParameters().flySpeed

		local distance = world.magnitude(args.position, mcontroller.position())
		if distance <= args.tolerance then break end

		local toTarget = vec2.norm(world.distance(args.position, mcontroller.position()))
		mcontroller.controlApproachVelocity(vec2.mul(toTarget, speed), mcontroller.baseParameters().airForce)
		mcontroller.controlFace(util.toDirection(toTarget[1]))
		mcontroller.controlDown()

		coroutine.yield(nil, {vector = toTarget})
	end

	mcontroller.controlFly({0,0})
	return true
end

-- param vector
-- param x
-- param y
function controlFly(args, board)
	local v = {args.x or args.vector[1] or 0, args.y or args.vector[2] or 0}
	mcontroller.controlFly(v)
	return true
end

function clearControls(args, board)
	mcontroller.clearControls()
	return true
end

-- param parameters
-- param gravityMultiplier
-- This is glaringly incomplete, could use an argument for every control parameter
function controlParameters(args, board)
	args.parameters.gravityMultiplier = args.gravityMultiplier

	mcontroller.controlParameters(args.parameters)
	return true
end

-- param parameters
function controlModifiers(args, board)
	mcontroller.controlModifiers(args.modifiers)
	return true
end

--------------------------------------------
--DOORS
--------------------------------------------

--Returns true if the path is clear from doors
-- param direction
-- param distance
-- param openLocked
function openDoors(args, board)
	local direction = args.direction or mcontroller.facingDirection() --Default to opening doors in front

	local position = mcontroller.position()
	local bounds = rect.translate(mcontroller.boundBox(), position)
	local opened = true
	if direction > 0 then
		bounds[1] = bounds[3]
		bounds[3] = bounds[3] + args.distance
	else
		bounds[3] = bounds[1]
		bounds[1] = bounds[1] - args.distance
	end
	if world.rectTileCollision(bounds, {"Dynamic"}) then
		opened = false

		-- There is a colliding object in the way. See if we can open it
		local closedDoors = world.entityQuery(rect.ll(bounds), rect.ur(bounds), { includedTypes = {"object"}, callScript = "hasCapability", callScriptArgs = { "closedDoor" } })
		util.debugRect(bounds, "blue")
		if args.openLocked then
			local lockedDoors = world.entityQuery(rect.ll(bounds), rect.ur(bounds), { includedTypes = {"object"}, callScript = "hasCapability", callScriptArgs = { "lockedDoor" } })
			closedDoors = util.mergeLists(closedDoors, lockedDoors)
		end
		for _, doorId in pairs(closedDoors) do
			local toDoor = world.distance(world.entityPosition(doorId), position)
			if toDoor[1] * direction > 0 then
				world.callScriptedEntity(doorId, "openDoor")
				opened = true
			end
		end
	end

	return opened
end

--Close doors - returns false if there are still open doors, true if there are no open doors
-- param direction
-- param distance
function closeDoors(args, output)
	local bounds = rect.translate(mcontroller.boundBox(), mcontroller.position())
	bounds[2] = bounds[2] + 0.5
	bounds[4] = bounds[4] - 0.5
	local direction = args.direction or -mcontroller.facingDirection()
	if direction < 0 then
		bounds[3] = bounds[1] - 1
		bounds[1] = bounds[1] - args.distance
	else
		bounds[1] = bounds[3] + 1
		bounds[3] = bounds[3] + args.distance
	end
	if not world.rectTileCollision(bounds, {"Dynamic"}) then
		local openDoorIds = world.entityQuery(rect.ll(bounds), rect.ur(bounds), { includedTypes = {"object"}, callScript = "hasCapability", callScriptArgs = { "openDoor" } })
		local closed = (#openDoorIds > 0)
		if #openDoorIds == 0 then
			return true
		else
			for _, openDoorId in pairs(openDoorIds) do
				local doorBounds = objectBounds(openDoorId)
				local npcs = world.entityQuery(rect.ll(doorBounds), rect.ur(doorBounds), {includedTypes = {"npc", "player"}})
				if #npcs == 0 then
					world.sendEntityMessage(openDoorId, "closeDoor")
					closed = true
				end
			end
		end
		return closed
	end
	return true
end

-- param position
-- param range
-- output insidePosition
-- output outsidePosition
function findOuterDoor(args, board, _, dt)
	local doorIds = world.entityQuery(args.position, args.range, {
		includedTypes = {"object"},
		callScript = "hasCapability", callScriptArgs = { "door" },
		order = "nearest"
	})
	for _, doorId in pairs(doorIds) do
		local doorPosition = world.entityPosition(doorId)

		local inside, outside

		local sidePositions = {
			vec2.add({ 3, 1.5 }, doorPosition), -- Right side
			vec2.add({ -3, 1.5 }, doorPosition) -- Left side
		}

		for _,sidePosition in pairs(sidePositions) do
			if isInside({position = sidePosition}) then
				inside = sidePosition
			else
				outside = sidePosition
			end
		end

		-- We have both an inside and an outside position
		-- meaning the door is an outer door
		if inside and outside then
			return true, {insidePosition = inside, outsidePosition = outside}
		end
	end

	return false
end

-- param position
-- param x
-- param y
-- param footPosition
function setPosition(args, board)
	local position = (args.x and args.y) and {args.x, args.y} or {args.position[1], args.position[2]}
	position = position or mcontroller.position()

	if args.footPosition then
		position[2] = position[2] - mcontroller.boundBox()[2]
	end
	mcontroller.setPosition(position)
	return true
end

function gravityEnabled(args, output)
	return mcontroller.baseParameters().gravityEnabled
end

-- output min
-- output max
function boundBox(args, board)
	local bounds = mcontroller.boundBox()
	return true, {min = {bounds[1], bounds[2]}, max = {bounds[4], bounds[4]}}
end
