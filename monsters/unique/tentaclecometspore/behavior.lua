function init()
	self.state = stateMachine.create({
		"idleState",
		"attackState",
	})

	self.state.leavingState = function(stateName)
		animator.setAnimationState("movement", "idle")
	end

	self.initialPauseTimer = config.getParameter("initialPauseTime")

	monster.setDeathParticleBurst("deathPoof")
	monster.setAggressive(true)
	monster.setDamageOnTouch(true)
end

--------------------------------------------------------------------------------
function main()
	local dt = entity.dt()

	if self.initialPauseTimer > 0 then
		self.initialPauseTimer = self.initialPauseTimer - dt
	else
		if util.trackTarget(config.getParameter("targetNoticeDistance")) then
			self.state.pickState(self.targetId)
		end

		self.state.update(dt)
	end
end

--------------------------------------------------------------------------------
function boundingBox(offset)
	local position = entity.position()
	if offset ~= nil then vec2.add(position, offset) end

	local bounds = config.getParameter("metaBoundBox")
	return {
		bounds[1] + position[1],
		bounds[2] + position[2],
		bounds[3] + position[1],
		bounds[4] + position[2],
	}
end

--------------------------------------------------------------------------------
function isClosed()
	return animator.animationState("movement") == "closedIdle"
end

--------------------------------------------------------------------------------
function isOnPlatform()
	local bounds = boundingBox({ 0, -1 })

	return entity.onGround() and
			not world.rectCollision(bounds, true) and
			world.rectCollision(bounds, false)
end

--------------------------------------------------------------------------------
function move(toTarget)
	animator.setAnimationState("movement", "walk")

	if math.abs(toTarget[2]) < 4.0 and isOnPlatform() then
		entity.moveDown()
	end

	entity.setFacingDirection(toTarget[1])
	if toTarget[1] < 0 then
		entity.moveLeft()
	else
		entity.moveRight()
	end
end

--------------------------------------------------------------------------------
idleState = {}

function idleState.enter()
	if isClosed() then return nil end

	return { timer = util.randomInRange(config.getParameter("idleBlinkIntervalRange")) }
end

function idleState.update(dt, stateData)
	stateData.timer = stateData.timer - dt
	if stateData.timer <= 0 then
		animator.setAnimationState("movement", "blink")
		stateData.timer = util.randomInRange(config.getParameter("idleBlinkIntervalRange"))
	end

	return false
end

--------------------------------------------------------------------------------
attackState = {}

function attackState.enterWith(targetId)
	if targetId == nil then return nil end

	if isClosed() then
		animator.setAnimationState("movement", "open")
	end

	return {
		timer = config.getParameter("attackTargetHoldTime"),
		targetId = targetId,
		targetPosition = world.entityPosition(targetId),
	}
end

function attackState.update(dt, stateData)
	if animator.animationState("movement") == "open" then
		return false
	end

	local targetPosition = world.entityPosition(stateData.targetId)
	if targetPosition == nil then return true end

	if entity.entityInSight(stateData.targetId) then
		stateData.targetPosition = targetPosition
		stateData.timer = config.getParameter("attackTargetHoldTime")
	else
		stateData.timer = stateData.timer - dt
	end

	local toTarget = world.distance(stateData.targetPosition, entity.position())
	move(toTarget)

	return stateData.timer <= 0
end