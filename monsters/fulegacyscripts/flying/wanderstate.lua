-- Fly around aimlessly
wanderState = {}

function wanderState.enter()
	if hasTarget() then return nil end

	math.randomseed(util.seedTime())

	return {
		wanderDirection = mcontroller.facingDirection(),
		phaseTimer = util.randomInRange(config.getParameter("wanderRiseTimeRange")),
		rising = true
	}
end

function wanderState.update(dt, stateData)
	if hasTarget() then return true end

	if self.sensors.blockedSensors.collision.any(true) then
		stateData.wanderDirection = -stateData.wanderDirection
	end

	local movement = { stateData.wanderDirection, 0 }

	if self.sensors.upSensors.collision.any(true) or world.liquidAt(monster.toAbsolutePosition({0, -10})) then
		movement[2] = config.getParameter("wanderRiseSpeed")
	elseif self.sensors.downSensors.collision.any(true) then
		movement[2] = -config.getParameter("wanderGlideSpeed")
	elseif stateData.rising then
		stateData.phaseTimer = stateData.phaseTimer - dt

		animator.setAnimationState("movement", "flying")

		if stateData.phaseTimer > 0 or self.sensors.groundSensors.collisionTrace[4].value then
			movement[2] = config.getParameter("wanderRiseSpeed")

			--Avoid ceiling
			for _, ceilingSensorIndex in ipairs({ 3, 2, 1 }) do
				local sensor = self.sensors.ceilingSensors.collisionTrace[ceilingSensorIndex]
				if sensor.value then
					movement[2] = movement[2] - 0.6 * config.getParameter("wanderRiseSpeed")
				end
			end
		else
			--stop rising and glide
			stateData.rising = false
			stateData.phaseTimer = util.randomInRange(config.getParameter("wanderGlideTimeRange"))
		end
	else --gliding
		stateData.phaseTimer = stateData.phaseTimer - dt

		if math.sin(stateData.phaseTimer * 2) > 0.4 then
			animator.setAnimationState("movement", "flying")
		else
			animator.setAnimationState("movement", "gliding")
		end

		if stateData.phaseTimer > 0 and not self.sensors.groundSensors.collisionTrace[3].value then
			movement[2] = -config.getParameter("wanderGlideSpeed")
		else
			if math.random() <= config.getParameter("wanderEndChance") then
				mcontroller.controlFly(movement, true)
				return true, 0.5
			else
				stateData.rising = true
				stateData.phaseTimer = util.randomInRange(config.getParameter("wanderRiseTimeRange"))
			end
		end
	end

	movement = vec2.add(movement, wanderState.calculateSeparationMovement())
	movement = vec2.mul(movement, mcontroller.baseParameters().flySpeed * config.getParameter("wanderSpeedMultiplier"))

	mcontroller.controlFly(movement, true)

	return false
end

function wanderState.calculateSeparationMovement()
	local separationMovement = { 0, 0 }

	local position = mcontroller.position()
	local selfId = entity.id()
	local entityIds = world.entityQuery(mcontroller.position(), 3.0, { callScript = "isFlyer", includedTypes = {"monster"} })
	for _, entityId in ipairs(entityIds) do
		if entityId ~= selfId then
			local fromEntity = world.distance(position, world.entityPosition(entityId))
			separationMovement[1] = separationMovement[1] + fromEntity[1] * math.random()
			separationMovement[2] = separationMovement[2] + fromEntity[2]
		end
	end

	return vec2.div(separationMovement, math.max(1, #entityIds))
end

