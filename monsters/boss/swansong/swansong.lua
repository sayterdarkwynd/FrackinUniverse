require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/rect.lua"
require "/scripts/async.lua"

function init()
	monster.setDamageBar(config.getParameter("damageBar"))

	local movementParameters = mcontroller.baseParameters()
	self.flySpeed = movementParameters.flySpeed
	self.airForce = movementParameters.airForce

	storage.spawnPosition = storage.spawnPosition or mcontroller.position()
	self.hoverHeight = 20

	self.shouldDie = false
	self.targets = {}

	self.boostForceModifier = 0.0

	self.lhorig = { anchor = {-3.375, 0.0}, angle = -math.pi / 2, distance = 3.25, lock = false }
	self.rhorig = { anchor = {2.625, 0.0}, angle = -math.pi / 2, distance = 3.25, lock = false }
	self.lefthand = copy(self.lhorig)
	self.righthand = copy(self.rhorig)
	self.body = { anchor = {0.0, 0.0}, angle = 0, lock = false }
	self.wings = { anchor = {0.0, 0.0}, angle = 0 }
	self.facing = 1

	self.maxAdds = 24
	self.ophanims = {}
	self.ophanimStart = (math.pi / 8) + math.random(1, 4) * (math.pi / 2)
	message.setHandler("ophanimPosition", function(_, _, sourceId)
		local angle = math.floor(#self.ophanims / 3) * math.pi / 4
		local range = 10 + (#self.ophanims % 3) * 11.5
		local pos = vec2.add(storage.spawnPosition, vec2.withAngle(self.ophanimStart + angle, range))
		table.insert(self.ophanims, sourceId)
		return pos
	end)

	message.setHandler("beamTargets", function(_, _, sourceId)
			local _, i = util.find(self.ophanims, function(id) return id == sourceId end)
			if i == nil then
				return {}
			end

			local adjacent = {}
			local wrap = function(j)
				while j > self.maxAdds do
					j = j - self.maxAdds
				end
				return j
			end
			if i % 3 ~= 0 then
				table.insert(adjacent, self.ophanims[wrap(i + 1)])
			end
			table.insert(adjacent, self.ophanims[wrap(i + 3)])
			return adjacent
		end)

	self.gravityDungeonId = config.getParameter("gravityDungeonId")
	world.setTileProtection(self.gravityDungeonId, true)
	local attackConfig = config.getParameter("attackConfig")
	self.behavior = swansongBehavior(attackConfig)
end

function update(dt)
	mcontroller.controlFace(1)
	updateTargets()

	tick(self.behavior)

	boostAnimation()

	if self.approachVelocity then
		if self.approachVelocity[1] ~= 0 then
			controlFace(util.toDirection(self.approachVelocity[1]))
		end
		mcontroller.controlApproachVelocity(self.approachVelocity, self.approachForce * self.boostForceModifier)
		self.approachVelocity = nil
		self.approachForce = nil
	end

	local facing = {self.facing, 1.0}
	local velocity = mcontroller.velocity()

	if self.facing then
		animator.resetTransformationGroup("flip")
		if self.facing < 0 then
			animator.scaleTransformationGroup("flip", {-1, 1.0})
		end
	end

	animator.resetTransformationGroup("body")
	animator.translateTransformationGroup("body", self.body.anchor)
	animator.rotateTransformationGroup("body", self.body.angle * self.facing)
	mcontroller.setRotation(self.body.angle)

	animator.resetTransformationGroup("wings")
	animator.translateTransformationGroup("wings", self.wings.anchor)
	animator.rotateTransformationGroup("wings", self.wings.angle * self.facing, vec2.mul(animator.partPoint("body", "wingsAnchor"), facing))
	animator.translateTransformationGroup("wings", vec2.mul(vec2.mul(velocity, -0.025), facing))

	local lhAngle = vec2.angle(vec2.mul(vec2.withAngle(self.lefthand.angle), facing))
	local lhAnchor = vec2.rotate(self.lefthand.anchor, self.body.angle * self.facing)
	animator.resetTransformationGroup("lefthand")
	animator.rotateTransformationGroup("lefthand", math.pi / 2)
	animator.translateTransformationGroup("lefthand", lhAnchor)
	animator.rotateTransformationGroup("lefthand", lhAngle, lhAnchor)
	animator.translateTransformationGroup("lefthand", vec2.rotate({self.lefthand.distance, 0.0}, lhAngle))

	local rhAngle = vec2.angle(vec2.mul(vec2.withAngle(self.righthand.angle), facing))
	local rhAnchor = vec2.rotate(self.righthand.anchor, self.body.angle * self.facing)
	animator.resetTransformationGroup("righthand")
	animator.rotateTransformationGroup("righthand", math.pi / 2)
	animator.translateTransformationGroup("righthand", rhAnchor)
	animator.rotateTransformationGroup("righthand", rhAngle, rhAnchor)
	animator.translateTransformationGroup("righthand", vec2.rotate({self.righthand.distance, 0.0}, rhAngle))
end

function shouldDie()
	return self.shouldDie and status.resource("health") <= 0
end

function die()
	world.spawnMonster("noxcapture", mcontroller.position())
end

function damage(damageSource)
end

function scalePower(power)
	return power * root.evalFunction("spaceMonsterLevelPowerMultiplier", monster.level())
end

-- converts an absolute angle to a local one, adjusted by the facing direction
function localAngle(a)
	return vec2.angle(vec2.mul(vec2.withAngle(a), {self.facing, 1.0}))
end

function controlFace(dir)
	self.facing = util.toDirection(dir)
end

function setBoostSoundActive(active)
	if active and self.boostSoundActive ~= true then
		animator.playSound("thrustLoop", -1)
		self.boostSoundActive = true
	elseif not active then
		animator.stopAllSounds("thrustLoop")
		self.boostSoundActive = false
	end
end

function updateTargets()
	local validTarget = function(e)
		local pos = world.entityPosition(e)
		if pos == nil then
			return false
		end

		return world.magnitude(pos, mcontroller.position()) < 100 and not world.lineTileCollision(mcontroller.position(), pos)
	end
	self.targets = util.filter(self.targets, validTarget)

	if #self.targets == 0 then
		local players = world.entityQuery(mcontroller.position(), 50, {includedTypes={"player"}, orderBy="nearest"})
		self.targets = util.filter(players, validTarget)
	end
	self.target = self.targets[1]
end

function controlApproachVelocity(velocity, force)
	self.approachVelocity = velocity
	self.approachForce = force
end

-- moves hands and rotates body based on movement direction
function boostAnimation()
	local approach = copy(self.approachVelocity) or {0.0, 10.0}
	local handApproach = copy(self.approachVelocity) or {0.0, 0.1}
	if world.gravity(mcontroller.position()) ~= 0 then
		approach[2] = approach[2] + 50
	end

	local approachDir = vec2.norm(approach)
	local velDiff = vec2.sub(approach, mcontroller.velocity())
	local forceDir = vec2.norm(velDiff)
	-- braking if we're currently accelerating in the opposite direction of the approach vector
	local braking = self.approachVelocity ~= nil and
		vec2.dot(forceDir, approachDir) < 0.0 and
		vec2.mag(velDiff) > 0.01

	local speedMultiplier = math.min(1.0, vec2.mag(mcontroller.velocity()) / self.flySpeed) ^ 2
	local downAngle = -math.pi/2
	local thrustAngle = util.angleDiff(0, vec2.angle(approach) + math.pi)
	local handThrustAngle = util.angleDiff(0, vec2.angle(handApproach) + math.pi)

	local bodyTargetAngle = util.angleDiff(downAngle, thrustAngle) * 0.75
	local lhTargetAngle = downAngle + util.angleDiff(downAngle, handThrustAngle)
	if braking then
		-- move body and hands back toward their original angles when braking
		bodyTargetAngle = util.angleDiff(0, bodyTargetAngle) * speedMultiplier
		lhTargetAngle = downAngle + util.angleDiff(downAngle, lhTargetAngle) * speedMultiplier
	end

	local hands = {
		left = {state = self.lefthand, origin = self.lhorig, part = "lefthand", boost = 0},
		right = {state = self.righthand, origin = self.rhorig, part = "righthand", boost = 0}
	}
	local boosting = false
	for _, hand in pairs(hands) do
		if not hand.state.lock then
			hand.state.anchor = vec2.lerp(0.15, hand.state.anchor, hand.origin.anchor)
			hand.state.angle = hand.state.angle + util.angleDiff(hand.state.angle, lhTargetAngle) * 0.15
			hand.state.distance = util.lerp(0.15, hand.state.distance, hand.origin.distance - (speedMultiplier * 2.0))
			hand.boost = (math.cos(handThrustAngle - hand.state.angle) - 0.8) * 5
			if not contains({"invisible", "spawn"}, animator.animationState(hand.part))then
				local state = "idle"
				if self.approachVelocity ~= nil and hand.boost > 0.0 then
					state = "boost"
				end
				if animator.animationState(hand.part) == "idle" and state == "boost" then
					boosting = true
				end
				animator.setAnimationState(hand.part, state)
			end
		end
	end
	if boosting then
		animator.playSound("thrustBurst")
	end
	setBoostSoundActive(boosting or animator.animationState("body") == "idlegrav")

	-- only rotate body when the hands are boosting, we are braking, or sitting still
	if not self.body.lock then
		if hands.left.boost > 0.0 or hands.right.boost > 0.0 or braking or not self.approachVelocity then
			self.body.angle = self.body.angle + util.angleDiff(self.body.angle, bodyTargetAngle) * 0.15
			self.wings.angle = util.angleDiff(0, self.body.angle) * -0.5
		end
	end

	-- move with more force the more the hands and body are aligned with the approach direction
	local bodyBoost = math.cos(bodyTargetAngle - self.body.angle) * 2
	local lhBoostMod = self.lefthand.lock and 1.0 or hands.left.boost
	local rhBoostMod = self.lefthand.lock and 1.0 or hands.right.boost
	self.boostForceModifier = math.min(1.0, math.max(0.0, (lhBoostMod + rhBoostMod + bodyBoost) / 2))
	if braking then
		-- except when braking, always brake with full force
		self.boostForceModifier = 1.0
	end
end

function wallPoint(dir, distance)
	local pos = mcontroller.position()
	local wallPoint = world.lineTileCollisionPoint(pos, vec2.add(pos, vec2.mul(vec2.norm(dir), distance)))
	if world.lineTileCollision(pos, vec2.add(pos, vec2.mul(vec2.norm(dir), distance))) then
		world.debugLine(pos, vec2.add(pos, vec2.mul(vec2.norm(dir), distance)), "red")
	else
		world.debugLine(pos, vec2.add(pos, vec2.mul(vec2.norm(dir), distance)), "blue")
	end
	if wallPoint then
		return wallPoint[1]
	end
end

function groundDistance()
	local pos = mcontroller.position()
	local groundPoint = world.lineTileCollisionPoint(pos, vec2.add(pos, {0, -self.hoverHeight * 2.0}))
	if groundPoint then
		return pos[2] - groundPoint[1][2]
	else
		return self.hoverHeight * 2
	end
end

-- predicts the direction the target will be in in `time` seconds
-- trackRange optionally gives an optimal range for the prediction
function anglePrediction(sourcePosition, targetId, time, trackRange)
		local targetVelocity = world.entityVelocity(targetId)
		local toTarget = world.distance(world.entityPosition(targetId), sourcePosition)

		trackRange = trackRange or vec2.mag(toTarget)
		local perpendicular = vec2.rotate(vec2.norm(toTarget), math.pi / 2)
		local angularVel = vec2.dot(perpendicular, vec2.norm(targetVelocity)) * (vec2.mag(targetVelocity) / trackRange)
		return vec2.angle(toTarget) + angularVel * time
end

function queryOphanims()
	local ophanims = world.entityQuery(mcontroller.position(), 80, {includedTypes = {"monster"}})
	return util.filter(ophanims, function(entityId)
			return world.monsterType(entityId) == "ophanim"
		end)
end

function breakAdds()
	local e=queryOphanims()
	e = util.filter(e, world.entityExists)
	for _, entityId in ipairs(e) do
		world.sendEntityMessage(entityId, "break")
	end
end

function despawnAdds()
	local e=queryOphanims()
	e = util.filter(e, world.entityExists)
	for _, entityId in ipairs(e) do
		world.sendEntityMessage(entityId, "despawn")
	end
end

function setMusicEnabled(enabled)
	local res = util.await(world.sendEntityMessage("bossmusic", "setMusicEnabled", enabled))
	if not res:succeeded() then
		sb.logInfo("Error starting boss music: %s", res:error())
	end
end

-- TOP LEVEL BEHAVIOR

-- swansongBehavior is an async function that should be ticked on every update
swansongBehavior = async(function(attackConfig)
	animator.setAnimationState("body", "init")
	animator.setAnimationState("lefthand", "invisible")
	animator.setAnimationState("righthand", "invisible")
	animator.setAnimationState("wings", "invisible")

	while self.target == nil do
		coroutine.yield()
	end

	world.setDungeonGravity(self.gravityDungeonId, 0)
	await(select(
		spawnAnimation(),
		function()
			while true do
				status.addEphemeralEffect("invulnerable")
				coroutine.yield()
			end
		end
	))
	status.removeEphemeralEffect("invulnerable")

	while status.resource("health") > 0 or self.shouldDie == false do
		world.setDungeonGravity(self.gravityDungeonId, 0)
		status.setResourcePercentage("health", 1.0)
		await(delay(1.0))

		despawnAdds()
		await(flyTo(storage.spawnPosition))

		while self.target == nil do
			coroutine.yield()
		end

		setMusicEnabled(true)
		local active = activeState(attackConfig) -- coroutine for the active state
		while self.target ~= nil do
			coroutine.yield(tick(active)) -- we don't expect the active state to finish
		end

		await(resetBoss())
		await(deactivateGravity())
	end
end)

-- run while the boss has targets
activeState = async(function(attackConfig)
	monster.setDamageOnTouch(true)

	local attackSequence = async(function()
		-- first do each attack once, with an ophanim wave between each
		local attacks = {
			rocketSwarmAttack(attackConfig.rocketSwarm),
			deathLaserAttack(attackConfig.deathLaser),
			coroutine.create(function()
				for _ = 1, 4 do
					await(meleeSequenceAttack(attackConfig.melee))
				end
			end)
		}
		for _, attack in ipairs(attacks) do
			await(attack)

			await(activateGravity(attackConfig.activateGravity))

			await(spawnOphanimsAttack(attackConfig.spawnOphanims))
			for _ = 1, 2 do
				await(hoverFireAttack(attackConfig.hoverFire))
			end

			await(deactivateGravity())
		end

		-- then do two attacks between each wave, repeating
		local step = 0
		while true do
			controlFace(1)

			if step == 0 or step == 2 then
				await(rocketSwarmAttack(attackConfig.rocketSwarm))
			end
			if step == 1 or step == 2 then
				await(deathLaserAttack(attackConfig.deathLaser))
			end
			if step == 0 or step == 1 then
				for _ = 1, 4 do
					await(meleeSequenceAttack(attackConfig.melee))
				end
			end

			await(activateGravity(attackConfig.activateGravity))

			-- fly to the center of the room
			await(flyTo({storage.spawnPosition[1], mcontroller.position()[2]}))

			await(spawnOphanimsAttack(attackConfig.spawnOphanims))
			for _ = 1, 2 do
				await(hoverFireAttack(attackConfig.hoverFire))
			end

			await(deactivateGravity())
			step = (step + 1) % 3
		end
	end)
	local finalAttackSequence = async(function()
		while true do
			await(finalFormMeleeAttack(attackConfig.finalMelee))
		end
	end)


	-- Run phase 1 until health is 0, but don't die
	self.shouldDie = false
	local mainAttacks = attackSequence()
	while status.resource("health") > 0 do
		coroutine.yield(tick(mainAttacks))
	end

	-- transition into phase 2
	await(finalFormTransition(attackConfig.transition))
	await(delay(1.0))

	-- Run phase 2 until health is 0, die afterwards
	local finalAttacks = finalAttackSequence()
	while status.resource("health") > 0 do
		status.addEphemeralEffect("maxhealthreduction")
		coroutine.yield(tick(finalAttacks))
	end

	resetAttacks()

	setMusicEnabled(false)

	-- death animation

	self.lefthand.lock, self.righthand.lock, self.body.lock = true, true, true
	animator.burstParticleEmitter("burst")
	animator.playSound("shockLoop", -1)
	animator.setParticleEmitterActive("shock", true)
	animator.setParticleEmitterActive("smoke", true)

	await(delay(2.0))

	await(blinkDash(storage.spawnPosition, 0.0, {body = "final", wings = "broken", lefthand = "idle", righthand = "idle"}))

	animator.playSound("deathLoop", -1)
	await(select(
		function()
			while true do
				mcontroller.controlApproachVelocity({0.0, -50.0}, 2)
				coroutine.yield()
			end
		end,
		function()
			await(join(
				moveLeftHand(self.lhorig.anchor, self.lhorig.angle, self.lhorig.distance, 0.2),
				moveRightHand(self.rhorig.anchor, self.rhorig.angle, self.rhorig.distance, 0.2)
			))

			while true do
				self.lefthand.angle = util.lerp(0.025, self.lefthand.angle, util.toRadians(90))
				self.righthand.angle = util.lerp(0.025, self.righthand.angle, util.toRadians(90))
				self.body.angle = util.lerp(0.025, self.body.angle, util.toRadians(-70))
				coroutine.yield()
			end
		end,
		function()
			await(delay(2.5))
			animator.burstParticleEmitter("rhburst")
			animator.setAnimationState("righthand", "invisible")

			await(delay(0.5))
			animator.burstParticleEmitter("lhburst")
			animator.setAnimationState("lefthand", "invisible")

			await(delay(1.5))
			animator.burstParticleEmitter("burst")
			animator.burstParticleEmitter("deathBurst")
			animator.setAnimationState("body", "invisible")
			animator.setAnimationState("wings", "invisible")
			animator.setParticleEmitterActive("shock", false)
			animator.setParticleEmitterActive("smoke", false)
			animator.stopAllSounds("shockLoop")
			animator.stopAllSounds("deathLoop")
			animator.playSound("deathBurst")
			world.setDungeonGravity(self.gravityDungeonId, 50)
			self.shouldDie = true
		end
	))

end)

-- HELPERS

-- flyTo smoothly flies to a position
flyTo = async(function(pos)
	local maxAcc = self.airForce / mcontroller.mass()
	local targetDir = vec2.norm(world.distance(pos, mcontroller.position()))
	local failsafeTimer=0.0
	local forceTeleport=false
	while true do
		failsafeTimer=failsafeTimer+script.updateDt()
		local toTarget = world.distance(pos, mcontroller.position())
		local distance = world.magnitude(toTarget)
		if vec2.dot(toTarget, targetDir) < 0.0 or distance < 0.1 then
			-- passed the target, or is very close
			break
		end

		if failsafeTimer>10.0 then
			forceTeleport=true
			break
		end

		-- approach the max speed that allows braking to a stop on the target
		-- using the approximate distance one step ahead to err on the side of caution
		local step = vec2.mag(mcontroller.velocity()) * script.updateDt()
		local targetSpeed = math.min(math.sqrt(2 * maxAcc * (distance - step)), self.flySpeed)

		controlApproachVelocity(vec2.mul(vec2.norm(toTarget), targetSpeed), self.airForce)
		coroutine.yield()
	end
	mcontroller.setVelocity({0, 0})
	if forceTeleport then
		mcontroller.setPosition(pos)
	end
	return true
end)

-- stop smoothly comes to a stop
stop = async(function(force)
	while vec2.mag(mcontroller.velocity()) > 0.1 do
		controlApproachVelocity({0, 0}, force or self.airForce)
		coroutine.yield()
	end
	mcontroller.setVelocity({0, 0})
end)

-- moveLeftHand smoothly moves the left hand to the desired position
moveLeftHand = async(function(anchor, angle, distance, time)
	return await(moveHand(self.lefthand, anchor, angle, distance, time))
end)

-- moveRightHand smoothly moves the right hand to the desired position
moveRightHand = async(function(anchor, angle, distance, time)
	return await(moveHand(self.righthand, anchor, angle, distance, time))
end)

moveHand = async(function(hand, anchor, angle, distance, time)
	local timer = 0.0
	local start = copy(hand)
	angle = start.angle + util.angleDiff(start.angle, angle)
	while timer < time do
		local ratio = util.easeInOutSin(timer / time, 0, 1.0)
		hand.anchor = vec2.lerp(ratio, start.anchor, anchor)
		hand.angle = util.lerp(ratio, start.angle, angle)
		hand.distance = util.lerp(ratio, start.distance, distance)

		timer = timer + script.updateDt()
		coroutine.yield()
	end

	hand.anchor = anchor
	hand.angle = angle
	hand.distance = distance

	return true
end)

-- Teleports the boss to the specified position, with a dash effect
-- dashPos - the position to dash to
-- endStates - states to set after the dash (returning from invisible)
-- onDash - callback function called when arriving at dashPos but while still invisible
blinkDash = async(function(dashPos, endSpeed, endStates, onDash)
	local dashDir = vec2.norm(world.distance(dashPos, mcontroller.position()))

	animator.setEffectActive("teleport", true)
	animator.burstParticleEmitter("teleport")
	animator.playSound("blinkDash")
	await(delay(0.1))
	monster.setAnimationParameter("dash", {first = mcontroller.position(), last = dashPos})

	animator.setAnimationState("body", "invisible")
	animator.setAnimationState("wings", "invisible")
	animator.setAnimationState("lefthand", "invisible")
	animator.setAnimationState("righthand", "invisible")

	coroutine.yield()

	monster.setAnimationParameter("dash", nil)
	mcontroller.setPosition(dashPos)
	mcontroller.setVelocity(vec2.mul(dashDir, endSpeed))

	coroutine.yield()

	if onDash ~= nil then
		onDash()
	end

	await(join(
		stop(50),
		function()
			animator.setAnimationState("body", endStates.body)
			animator.setAnimationState("wings", endStates.wings)
			animator.setAnimationState("lefthand", endStates.lefthand)
			animator.setAnimationState("righthand", endStates.righthand)

			await(delay(0.1))
			animator.setEffectActive("teleport", false)
		end
	))
end)

-- shoots a beam out of either hand
-- handName - "left" or "right"
-- angle - firing angle
-- setDamagePartActive - a function(part, active) that sets the damage parts, required to
-- be able to set the damage parts for both hands if run in parallel
handBeam = async(function(handName, angle, setDamagePartActive)
	local hand, animationPart, beamParam, damagePart, move
	if handName == "left" then
		hand, animationPart, beamParam, damagePart, move = self.lefthand, "lefthand", "lhbeam", "lhbeam", moveLeftHand
	elseif handName == "right" then
		hand, animationPart, beamParam, damagePart, move = self.righthand, "righthand", "rhbeam", "rhbeam", moveRightHand
	else
		error(string.format("Invalid hand %s for handBeam", handName))
	end

	hand.lock = true
	await(move({0.0, 0.0}, angle, 6.0, 0.5))

	-- windup
	animator.setAnimationState(animationPart, "boost")
	monster.setAnimationParameter(beamParam, true)
	animator.playSound("beamStart")
	await(delay(0.3)) -- windup

	animator.playSound("beamLoop", -1)
	await(delay(0.2)) -- start firing

	-- damage
	setDamagePartActive(damagePart, true)
	await(delay(0.3))

	-- winddown
	setDamagePartActive(damagePart, false)
	monster.setDamageParts({})
	animator.stopAllSounds("beamLoop", 0.5)
	animator.setAnimationState(animationPart, "idle")
	monster.setAnimationParameter(beamParam, false)
	await(delay(0.5))

	hand.lock = false
end)

function resetAttacks()
	-- remove rockets and all boss damage
	local projectiles = world.entityQuery(mcontroller.position(), 50, {includedTypes={"projectile"}})
	projectiles = util.filter(projectiles, function(id) return world.entityName(id) == "swansongrocket" end)
	projectiles = util.filter(projectiles, world.entityExists)
	for _, id in ipairs(projectiles) do
		world.sendEntityMessage(id, "explode")
	end
	monster.setDamageSources({})
	monster.setDamageParts({})

	-- stop all rendering effects
	monster.setAnimationParameter("aimLaser", false)
	monster.setAnimationParameter("rocketMarkers", nil)
	monster.setAnimationParameter("dash", nil)
	monster.setAnimationParameter("beam", false)
	monster.setAnimationParameter("lhbeam", false)
	monster.setAnimationParameter("rhbeam", false)

	animator.setAnimationState("chargeswoosh", "inactive")
end

-- resets the boss back to its original idle state
resetBoss = async(function()
	setMusicEnabled(false)
	resetAttacks()
	monster.setDamageOnTouch(false)
	await(delay(0.5))

	-- move everything back into place
	self.lefthand.lock, self.righthand.lock = true, true
	self.body.lock = false
	await(join(
		moveLeftHand(self.lhorig.anchor, self.lhorig.angle, self.lhorig.distance, 0.5),
		moveRightHand(self.rhorig.anchor, self.rhorig.angle, self.rhorig.distance, 0.5),
		function()
			animator.setEffectActive("teleport", true)

			await(delay(0.1))

			animator.setAnimationState("body", "idle")
			if animator.animationState("wings") == "beamloop" then
				animator.setAnimationState("wings", "beamwinddown")
			end
			animator.setAnimationState("wings", "idle")
			animator.setAnimationState("lefthand", "idle")
			animator.setAnimationState("righthand", "idle")

			animator.resetTransformationGroup("lhflip")
			animator.resetTransformationGroup("rhflip")

			await(delay(0.1))

			animator.setEffectActive("teleport", false)
		end
	))
	self.lefthand.lock, self.righthand.lock = false, false

	await(delay(1.0))
end)

-- MAIN ABILITIES

spawnAnimation = async(function()
	await(delay(2.0))

	local dialog = config.getParameter("openingDialog")
	local dialogTime = config.getParameter("dialogTime")
	local portrait = config.getParameter("chatPortrait")
	local waitTime = (dialogTime - 6.0) / (#dialog - 1)
	for i, line in ipairs(dialog) do
		monster.sayPortrait(line, portrait)
		if i == 3 then
			setMusicEnabled(true)
		end
		if i < #dialog then
			await(delay(waitTime))
		end
	end
	await(delay(6.0))

	monster.setDamageBar("Special")

	await(join(
		function()
			animator.setAnimationState("body", "spawn")
			await(delay(1.0))

			animator.setAnimationState("lefthand", "spawn")
			await(delay(0.5))

			animator.setAnimationState("righthand", "spawn")
			await(delay(0.5))

			animator.setAnimationState("wings", "spawn")
			await(delay(0.75))
		end,
		function()
			for _ = 1, 5 do
				--animator.playSound("spawnClank")
				await(delay(0.5))
			end
		end
	))
end)

activateGravity = async(function(conf)
	if math.abs(world.distance(mcontroller.position(), storage.spawnPosition)[1]) > 20 then
		await(flyTo(storage.spawnPosition))
	end

	animator.playSound("toggleGravityWarning")
	await(delay(1.0))

	animator.playSound("enableGravity")
	world.setDungeonGravity(self.gravityDungeonId, 50)

	-- fall down a bit
	local fallForce = mcontroller.mass() * world.gravity(mcontroller.position())
	while groundDistance() > conf.hoverHeight do
		mcontroller.controlApproachVelocity({0, -100}, fallForce)
		coroutine.yield()
	end

	animator.setAnimationState("body", "idlegrav")
	await(stop(150))
	await(flyTo(vec2.add(mcontroller.position(), {0, self.hoverHeight - groundDistance()})))
end)


deactivateGravity = async(function()
	self.ophanims = {}
	self.ophanimStart = (math.pi / 8) + math.random(1, 4) * (math.pi / 2)

	animator.playSound("toggleGravityWarning")
	await(delay(1.0))

	animator.playSound("disableGravity")
	world.setDungeonGravity(self.gravityDungeonId, 0)
	animator.setAnimationState("body", "idle")
	animator.setAnimationState("lefthand", "idle")
	animator.setAnimationState("righthand", "idle")

	await(flyTo(storage.spawnPosition))
end)

spawnOphanimsAttack = async(function()
	self.ophanims = util.filter(self.ophanims, world.entityExists)
	local maxSpawn = 8
	local spawnCount = math.min(maxSpawn, self.maxAdds - #self.ophanims)
	if spawnCount == 0 then
	return
	end

	self.righthand.lock = true

	local upAngle = math.pi/2
	local angleRange = ((math.pi - 0.2) / maxSpawn) * (spawnCount - 1)
	local startAngle = upAngle - (angleRange / 2)
	await(moveRightHand({0, 2.0}, startAngle, 6.0, 0.5))

	animator.setAnimationState("righthand", "firewindup")
	await(delay(0.4))

	local stepAngle = angleRange / math.max(1, spawnCount - 1)
	local energyIndices = {}
	for i = 1, maxSpawn do
		table.insert(energyIndices, i)
	end
	shuffle(energyIndices)
	energyIndices = util.take(3, energyIndices)
	for i = 1, spawnCount do
		animator.setAnimationState("righthand", "fire")

		local sourcePosition = vec2.add(mcontroller.position(), animator.partPoint("righthand", "projectileSource"))
		local aimDir = vec2.withAngle(self.righthand.angle)
		local params = {speed = 25}
		if contains(energyIndices, i) then
			params.spawnEnergyPickup = true
		end
		world.spawnProjectile("ophanimspawner", sourcePosition, entity.id(), aimDir, false, params)

		await(delay(0.1))

		if i < spawnCount then
			await(moveRightHand({0.0, 2.0}, startAngle + (i * stepAngle), 6.0, 0.3))
		end
	end

	await(delay(0.2))
	animator.setAnimationState("righthand", "fireend")
	await(delay(0.5))
	await(moveRightHand(self.rhorig.anchor, self.rhorig.angle, self.rhorig.distance, 0.6))
	self.righthand.lock = false
end)

hoverFireAttack = async(function(conf)
	local left = wallPoint({-1, 0}, 50) or vec2.add(mcontroller.position(), {-50, 0})
	local right = wallPoint({1, 0}, 50) or vec2.add(mcontroller.position(), {50, 0})
	left[1] = left[1] + 10
	right[1] = right[1] - 10

	local hoverRange = right[1] - left[1]
	local hoverY = mcontroller.position()[2] + self.hoverHeight - groundDistance()
	hoverY = hoverY - 5 + math.random() * 10
	local hoverX
	while hoverX == nil or world.magnitude(mcontroller.position(), {hoverX, hoverY}) < 20 do
		hoverX = left[1] + math.random() * hoverRange
	end
	await(flyTo({hoverX, mcontroller.position()[2] + self.hoverHeight - groundDistance()}))

	self.righthand.lock = true

	animator.setAnimationState("righthand", "firewindup")
	await(delay(0.5))
	monster.setAnimationParameter("aimLaser", true)

	local targetPosition = world.entityPosition(self.target)
	local toTarget = world.distance(targetPosition, vec2.add(mcontroller.position(), self.rhorig.anchor))
	controlFace(util.toDirection(toTarget[1]))
	await(moveRightHand(self.rhorig.anchor, vec2.angle(toTarget), 6.0, 0.5))

	animator.playSound("targetRockets")
	await(delay(0.5))
	monster.setAnimationParameter("aimLaser", false)

	for _ = 1, 5 do
		animator.setAnimationState("righthand", "fire", true)
		local sourcePosition = vec2.add(mcontroller.position(), animator.partPoint("righthand", "projectileSource"))
		local aimDir = vec2.withAngle(self.righthand.angle)
		world.spawnProjectile("swansongbolt", sourcePosition, entity.id(), aimDir, false, {
			speed = 35,
			power = scalePower(conf.power)
		})
		await(delay(0.25))
	end

	animator.setAnimationState("righthand", "fireend")
	await(delay(0.6))

	self.righthand.lock = false
end)

rocketSwarmAttack = async(function(conf)
	await(flyTo(storage.spawnPosition))

	self.lefthand.lock, self.righthand.lock = true, true
	await(join(
		moveLeftHand(self.lhorig.anchor, util.toRadians(-90), 2.5, 1.0),
		moveRightHand(self.rhorig.anchor, util.toRadians(-90), 2.5, 1.0)
	))

	animator.setAnimationState("body", "rocketwindup")
	animator.resetTransformationGroup("lhflip")
	animator.resetTransformationGroup("rhflip")
	animator.scaleTransformationGroup("lhflip", {-1.0, 1.0})
	animator.scaleTransformationGroup("rhflip", {-1.0, 1.0})

	local projectiles = {}
	local markers = {}
	local fired = false
	local randomTargetPosition = function()
		local e = util.randomFromList(self.targets)
		pos = vec2.add(world.entityPosition(e), vec2.withAngle(math.random() * math.pi * 2, math.random() * 7))
		return pos
	end

	await(select(
		join(
			moveLeftHand(vec2.add(self.lhorig.anchor, {0.0, -2}), localAngle(util.toRadians(-130)), 2.5, 2.0),
			moveRightHand(vec2.add(self.rhorig.anchor, {0.0, -2}), localAngle(util.toRadians(-50)), 2.5, 2.0),
			function()
				await(delay(0.5))

				for _ = 1, conf.rocketCount do
					-- spawn one rocket from each rocket orifice
					local leftPos = vec2.add(mcontroller.position(), animator.partPoint("body", "leftRocketSource"))
					local aimDir = vec2.rotate({-1, 0}, -util.toRadians(30) * math.random() * util.toRadians(60))
					local leftId = world.spawnProjectile("swansongrocket", leftPos, entity.id(), aimDir, false, {power = scalePower(conf.power)})
					table.insert(projectiles, leftId)

					local rightPos = vec2.add(mcontroller.position(), animator.partPoint("body", "rightRocketSource"))
					aimDir = vec2.rotate({1, 0}, -util.toRadians(30) * math.random() * util.toRadians(60))
					local rightId = world.spawnProjectile("swansongrocket", rightPos, entity.id(), aimDir, false, {power = scalePower(conf.power)})
					table.insert(projectiles, rightId)

					animator.playSound("fireRockets")

					await(delay(math.random() * conf.spawnDelay))
				end

				fired = true
			end,
			function()
				await(delay(2.0))

				while fired == false or #projectiles > 0 do
					if #projectiles > 0 then
						local popped = {
							table.remove(projectiles, #projectiles),
							table.remove(projectiles, #projectiles)
						}
						popped = util.filter(popped, world.entityExists)
						for _, e in ipairs(popped) do
							local targetPos = randomTargetPosition()
							table.insert(markers, {entity = e, position = targetPos})
							world.sendEntityMessage(e, "setTargetPosition", targetPos)

							markers = util.filter(markers, function(m)
									return world.entityExists(m.entity)
								end)
							monster.setAnimationParameter("rocketMarkers", markers)

							animator.playSound("targetRockets")

							await(delay(conf.targetDelay))
						end
					else
						coroutine.yield()
					end
				end
			end
		),
		function()
			local timer = 0.0
			while true do
				jitter = 0.1 * timer / 2.0
				self.lefthand.anchor = vec2.add(self.lefthand.anchor, vec2.withAngle(math.random() * math.pi * 2, jitter))
				self.righthand.anchor = vec2.add(self.righthand.anchor, vec2.withAngle(math.random() * math.pi * 2, jitter))

				timer = math.min(1.0, timer + script.updateDt())
				coroutine.yield()
			end
		end
	))

	monster.setAnimationParameter("rocketMarkers", nil)

	monster.setAnimationParameter("rockets", {})
	animator.resetTransformationGroup("lhflip")
	animator.resetTransformationGroup("rhflip")

	animator.setAnimationState("body", "rocketwinddown")

	self.lefthand.lock, self.righthand.lock = false, false
	await(delay(0.5))
end)

meleeSlashAttack = async(function(conf)
	self.lefthand.lock = true

	local swordStartAngle = util.toRadians(160)
	local targetAngle, facing
	local rotateTime = conf.rotate
	local windupTime = conf.windup
	await(join(
		moveLeftHand({0.5, 2.0}, self.lhorig.angle, 2.0, rotateTime),
		stop(),
		function()
			local timer = 0.0
			local startAngle = self.lefthand.angle
			while timer < windupTime do
				local toTarget = world.distance(world.entityPosition(self.target), mcontroller.position())
				facing = util.toDirection(toTarget[1])
				targetAngle = vec2.angle(toTarget)
				local newAngle = startAngle + util.angleDiff(startAngle, targetAngle + facing * swordStartAngle)

				controlFace(facing)
				self.lefthand.angle = util.lerp(math.min(1.0, timer / rotateTime), startAngle, newAngle)

				timer = timer + script.updateDt()
				coroutine.yield()
			end

			controlFace(facing)
			self.lefthand.angle = targetAngle + facing * swordStartAngle
		end,
		function()
			await(delay(rotateTime))
			animator.setAnimationState("lefthand", "swordwindup")
		end
	))

	animator.playSound("slash")
	await(moveLeftHand({0.0, -1.0}, targetAngle + facing * util.toRadians(70), 2.0, 0.00))
	coroutine.yield()
	await(moveLeftHand({0.0, -1.0}, targetAngle + facing * util.toRadians(-70), 4.0, 0.00))

	local localTargetAngle = vec2.angle({math.cos(targetAngle) * facing, math.sin(targetAngle)})
	local offset = vec2.rotate({3.5 * facing, -2.75}, localTargetAngle * facing)
	local pos = vec2.add(mcontroller.position(), offset)
	world.spawnProjectile("swansongslashswoosh", pos, entity.id(), vec2.withAngle(targetAngle), false, {power = scalePower(conf.power)})

	await(delay(conf.postslash))

	animator.setAnimationState("lefthand", "swordwinddown")
	await(delay(conf.winddown))

	self.lefthand.lock = false
end)

meleeChargeAttack = async(function(conf, bodyChargeState, bodyEndState)
	self.lefthand.lock, self.righthand.lock, self.body.lock = true, true, true

	local bodyStart, lhStart, rhStart = self.body.angle, self.lefthand.angle, self.righthand.angle
	local turnTime = conf.turn
	local timer = 0.0
	local targetAngle, facing
	animator.playSound("charge")
	await(select(
		function()
			while timer < turnTime do
				local toTarget = world.distance(world.entityPosition(self.target), mcontroller.position())
				facing = toTarget[1] < 0 and -1 or 1
				targetAngle = anglePrediction(mcontroller.position(), self.target, 1.0, 35)

				controlFace(facing)
				local ratio = util.easeInOutSin(timer / turnTime, 0, 1)
				local toAngle = bodyStart + util.angleDiff(bodyStart, targetAngle + util.toRadians(-90))
				self.body.angle = util.lerp(ratio, bodyStart, toAngle)
				self.lefthand.angle = util.lerp(ratio, lhStart, lhStart + util.angleDiff(lhStart, targetAngle))
				self.righthand.angle = util.lerp(ratio, rhStart, self.body.angle + util.toRadians(-90))

				timer = timer + script.updateDt()
				coroutine.yield()
			end

			self.body.angle = targetAngle + util.toRadians(-90)
		end,
		function()
			await(join(
				stop(150),
				function()
					animator.setAnimationState("lefthand", "swordwindup")
					await(moveLeftHand({0.0, 0.0}, targetAngle, -3.0, turnTime))
				end,
				function()
					while true do
						local ratio = util.easeInOutSin(timer / turnTime, 0, 1)
						self.lefthand.angle = util.lerp(ratio, lhStart, lhStart + util.angleDiff(lhStart, targetAngle))
						coroutine.yield()
					end
				end
			))
			while true do
				self.lefthand.angle = targetAngle
				coroutine.yield()
			end
		end
	))

	animator.setAnimationState("body", bodyChargeState)
	animator.setAnimationState("righthand", "boost")
	animator.setAnimationState("chargeswoosh", "active")
	animator.playSound("thrustBurst")
	animator.playSound("thrustLoop", -1)
	monster.setDamageParts({"sword"})

	timer = 0.0
	local windupTime = conf.windup
	while timer < windupTime do
		local jitter = 0.125 * timer / windupTime
		self.body.anchor = vec2.withAngle(math.random() * util.toRadians(360), jitter)

		timer = math.min(windupTime, timer + script.updateDt())
		coroutine.yield()
	end

	local chargeDir = vec2.withAngle(targetAngle)
	local wallPoint = nil
	await(join(
		moveLeftHand({0.0, 0.0}, targetAngle, 6.0, 0.2),
		function()
			local spawnedWallMelt = false
			local failsafeTimer=0.0
			while true do
				local speed = 75
				local force = 400
				local swordStart = vec2.add(mcontroller.position(), animator.partPoint("lefthand", "swordStart"))
				local swordEnd = vec2.add(mcontroller.position(), animator.partPoint("lefthand", "swordEnd"))
				local normal
				failsafeTimer=failsafeTimer+script.updateDt()
				wallPoint, normal = world.lineCollision(swordStart, swordEnd)
				if wallPoint then
					local wallDistance = world.magnitude(swordStart, wallPoint)
					speed = speed * (wallDistance / world.magnitude(swordStart, swordEnd))
					force = 2000
					if (wallDistance < 0.1) or (failsafeTimer > 5.0) then
						mcontroller.setVelocity({0.0, 0.0})
						return
					end

					if normal ~= nil and spawnedWallMelt == false then
						world.spawnProjectile("wallmelt", wallPoint, entity.id(), vec2.mul(normal, {-1, -1}), false)
						spawnedWallMelt = true
						animator.playSound("chargeBrake")
					end
				else
					world.debugLine(swordStart, swordEnd, "green")
				end

				controlApproachVelocity(vec2.mul(chargeDir, speed), force)

				coroutine.yield()
			end
		end
	))

	await(delay(0.1))

	mcontroller.setVelocity({0.0, 0.0})
	animator.setAnimationState("body", bodyEndState)
	animator.setAnimationState("righthand", "idle")
	animator.setAnimationState("lefthand", "swordwinddown")
	animator.setAnimationState("chargeswoosh", "inactive")
	animator.stopAllSounds("thrustLoop")
	monster.setDamageParts({})

	await(delay(conf.winddown))

	self.body.lock, self.lefthand.lock, self.righthand.lock = false, false, false
end)

meleeDashAttack = async(function(conf, targetAngle)
	self.lefthand.lock = true
	self.righthand.lock = true
	self.body.lock = true

	animator.setAnimationState("lefthand", "swordwindup")
	animator.playSound("charge")
	controlFace(math.cos(targetAngle))

	local rotateTime = conf.rotate
	await(join(
		function()
			local failsafeTimer=0.0
			while (vec2.mag(mcontroller.velocity()) > 1.0) and (failsafeTimer<5.0) do
				mcontroller.controlApproachVelocity({0.0, 0.0}, self.airForce)
				coroutine.yield()
				failsafeTimer=failsafeTimer+script.updateDt()
			end
		end,
		moveLeftHand(self.lhorig.anchor, targetAngle + util.toRadians(-170) * self.facing, self.lhorig.distance, rotateTime),
		function()
			local timer = 0.0
			local startAngle = self.body.angle
			local targetAngle2 = startAngle + util.angleDiff(startAngle, localAngle(targetAngle) * self.facing)
			while timer < rotateTime do
				self.body.angle = util.lerp(timer / rotateTime, startAngle, targetAngle2)
				self.righthand.angle = self.body.angle + util.toRadians(-90)
				timer = timer + script.updateDt()
				coroutine.yield()
			end

			self.body.angle = targetAngle2
		end
	))

	local dashPos = vec2.add(mcontroller.position(), vec2.withAngle(targetAngle, 30))
	local dashMidPos = vec2.mul(vec2.add(mcontroller.position(), dashPos), 0.5)
	local dashDir = vec2.norm(world.distance(dashPos, mcontroller.position()))

	await(delay(conf.windup))
	await(blinkDash(
		dashPos,
		30.0,
		{body = conf.bodyState, wings = conf.wingsState, lefthand = "swordloop", righthand = "idle"},
		function()
			await(moveLeftHand(self.lhorig.anchor, targetAngle + util.toRadians(10) * self.facing, 6.0, 0.0))
			animator.playSound("slash")
			local offset = {-2.25, 0.0}
			local swooshPos = vec2.add(dashMidPos, vec2.mul(vec2.rotate(offset, localAngle(vec2.angle(dashDir))), {self.facing, 1.0}))
			world.spawnProjectile("swansongdashswoosh", swooshPos, entity.id(), dashDir, false, {power = scalePower(conf.power)})
		end
	))

	await(delay(0.1))

	animator.setAnimationState("lefthand", "swordwinddown")

	await(delay(conf.winddown))

	self.lefthand.lock = false
	self.righthand.lock = false
	self.body.lock = false
end)

meleeSequenceAttack = async(function(conf)
	local targetPosition, targetDistance, targetInner, targetOuter
	local attack
	await(select(
		function()
			while true do
				targetPosition = world.entityPosition(self.target)
				local targetToSpawn = world.distance(targetPosition, storage.spawnPosition)
				local distance = world.magnitude(targetToSpawn)

				targetInner = distance < conf.dashArea
				targetOuter = distance > conf.chargeArea
				targetDistance = world.magnitude(targetPosition, mcontroller.position())

				coroutine.yield()
			end
		end,
		function()
			while true do
				if targetDistance < conf.slashRange then
					attack = meleeSlashAttack(conf.slash)
					break
				end

				local toTarget = world.distance(targetPosition, mcontroller.position())
				local toSpawn = world.distance(storage.spawnPosition, mcontroller.position())
				local spawnDistance = world.magnitude(toSpawn)
				if spawnDistance < conf.chargeArea and targetOuter then
					attack = meleeChargeAttack(conf.charge, "idlegrav", "idle")
					break
				end
				if spawnDistance > conf.chargeArea and targetDistance < conf.dashArea and targetInner then
					attack = meleeDashAttack(conf.dash, vec2.angle(toTarget))
					break
				end

				if targetInner then
					if spawnDistance < conf.chargeArea then
						controlApproachVelocity(vec2.mul(vec2.norm(toSpawn), -self.flySpeed), self.airForce)
					elseif targetDistance > conf.dashArea then
						controlApproachVelocity(vec2.mul(vec2.norm(toTarget), self.flySpeed), self.airForce)
					end
				elseif targetOuter then
					controlApproachVelocity(vec2.mul(vec2.norm(toSpawn), self.flySpeed), self.airForce)
				end

				coroutine.yield()
			end
		end
	))

	await(attack)
end)

deathLaserAttack = async(function(conf)
	await(flyTo(vec2.add(storage.spawnPosition, {0.0, -6.0})))

	local timer = 0.0
	while timer < 0.5 do
		self.wings.anchor = vec2.lerp(util.easeInOutSin(timer / 0.5, 0, 1), {0.0, 0.0}, {0.0, 3.5})
		timer = timer + script.updateDt()
		coroutine.yield()
	end
	animator.setAnimationState("wings", "beamwindup")
	await(delay(1.0))

	for _ = 1, 6 do
		local sourcePosition = vec2.add(mcontroller.position(), animator.partPoint("beam", "beamStart"))
		local toTarget = world.distance(world.entityPosition(self.target), sourcePosition)
		controlFace(toTarget[1])
		local targetAngle = anglePrediction(sourcePosition, self.target, 1.0, 45)
		animator.resetTransformationGroup("beam")
		animator.rotateTransformationGroup("beam", localAngle(targetAngle))
		coroutine.yield()

		monster.setAnimationParameter("beam", true)
		animator.playSound("beamStart")
		await(delay(0.3)) -- windup

		animator.playSound("beamLoop", -1)
		await(delay(0.2)) -- start firing

		-- damage
		monster.setDamageParts({"beam"})
		await(delay(0.3))

		-- winddown
		monster.setDamageParts({})
		monster.setAnimationParameter("beam", false)
		animator.stopAllSounds("beamLoop", 0.5)
		await(delay(0.5))
	end

	animator.setAnimationState("wings", "beamwinddown")
	await(delay(1.0))

	timer = 0.0
	while timer < 0.5 do
		self.wings.anchor = vec2.lerp(util.easeInOutSin(timer / 0.5, 0, 1), {0.0, 3.5}, {0.0, 0.0})
		timer = timer + script.updateDt()
		coroutine.yield()
	end
end)

finalFormTransition = async(function(conf)
	animator.setParticleEmitterActive("shock", true)
	animator.playSound("shockLoop", -1)
	resetAttacks()

	world.setDungeonGravity(self.gravityDungeonId, 0)
	await(flyTo(storage.spawnPosition))
	breakAdds()

	local damageParts = {}
	local setDamagePartActive = function(part, active)
		if active then
			table.insert(damageParts, part)
		else
			damageParts = util.filter(damageParts, function(p) return p ~= part end)
		end
		monster.setDamageParts(damageParts)
	end

	local timer = 0.0
	await(join(
		function()
			while timer < conf.chargeTime do
				local ratio = timer / conf.chargeTime
				status.addEphemeralEffect("maxprotectionnogrit")
				animator.setLightColor("glow", {ratio * 0.75 * 255, ratio * 0.75 * 200, 100})
				status.setResourcePercentage("health", timer / conf.chargeTime)

				timer = timer + script.updateDt()
				coroutine.yield()
			end
		end,
		function()
			for _ = 1, conf.beams do
				await(handBeam("left", anglePrediction(mcontroller.position(), self.target, 1.0, 35), setDamagePartActive))
			end
		end,
		function()
			await(delay(0.75))
			for _ = 1, conf.beams do
				await(handBeam("right", anglePrediction(mcontroller.position(), self.target, 1.0, 35), setDamagePartActive))
			end
		end
	))

	status.removeEphemeralEffect("maxprotectionnogrit")
	status.setResourcePercentage("health", 1.0)

	animator.stopAllSounds("shockLoop")
	animator.setParticleEmitterActive("shock", false)
	animator.setLightColor("glow", {255, 200, 100, 255})
	animator.burstParticleEmitter("burst")
	animator.playSound("transitionBurst")
	animator.setAnimationState("body", "final")
	animator.setAnimationState("wings", "broken")
end)

finalFormMeleeAttack = async(function(conf)
	local dash = async(function()
		local spawnToTarget = world.distance(world.entityPosition(self.target), storage.spawnPosition)
		local distance = vec2.mag(spawnToTarget)
		if distance < 25 then
			-- teleport to the outside of the area, placing the target between us and the center
			local dashPos = vec2.add(storage.spawnPosition, vec2.mul(vec2.norm(spawnToTarget), math.min(distance + 10, 25)))
			await(blinkDash(dashPos, 0.0, {body = "final", wings = "broken", lefthand = "idle", righthand = "idle"}))
			local toSpawn = world.distance(storage.spawnPosition, mcontroller.position())
			await(meleeDashAttack(conf.dash, vec2.angle(toSpawn)))
		end
	end)
	local charge = async(function()
		local spawnToTarget = world.distance(world.entityPosition(self.target), storage.spawnPosition)
		local distance = vec2.mag(spawnToTarget)
		if distance > 10 then
			-- teleport to the outside of the area, placing the target between us and the center
			await(blinkDash(storage.spawnPosition, 0.0, {body = "final", wings = "broken", lefthand = "idle", righthand = "idle"}))
			await(meleeChargeAttack(conf.charge, "final", "final"))
		end
	end)
	local slash = async(function()
		local targetPosition = world.entityPosition(self.target)
		local slashDistance = 10
		local positions = shuffled({
			vec2.add(targetPosition, vec2.withAngle(util.toRadians(45), slashDistance)),
			vec2.add(targetPosition, vec2.withAngle(util.toRadians(135), slashDistance)),
			vec2.add(targetPosition, vec2.withAngle(util.toRadians(225), slashDistance)),
			vec2.add(targetPosition, vec2.withAngle(util.toRadians(315), slashDistance))
		})
		for _, pos in ipairs(shuffled(positions)) do
			local bounds = rect.translate(mcontroller.boundBox(), pos)
			if not world.rectTileCollision(bounds) then
				await(blinkDash(pos, 0.0, {body = "final", wings = "broken", lefthand = "idle", righthand = "idle"}))
				await(meleeSlashAttack(conf.slash))
				return
			end
		end
	end)

	local attack = util.randomFromList({dash, charge, slash})
	await(attack())

	coroutine.yield()
end)
