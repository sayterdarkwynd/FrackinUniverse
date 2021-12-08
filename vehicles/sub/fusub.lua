require "/scripts/vec2.lua"
require "/scripts/util.lua"

function healthLevelAdjust(hp_or_armor)
	return root.evalFunction("npcLevelPowerMultiplierModifier", self.level) * hp_or_armor
end

function isSafeLiquid()
	-- get liquid name and compare to list
	local vehicleLiquid=root.liquidName(mcontroller.liquidId()) -- yes this works when there is no lquid too
	for x, value in pairs(self.liquidList) do
		if value == vehicleLiquid then
			return not self.liquidUnsafe
		end
	end
	return self.liquidUnsafe
end

function init()
	self.specialLast = false
	self.rockingTimer = 0
	self.facingDirection = 1
	self.angle = 0
	animator.setParticleEmitterActive("bubbles", false)
	self.damageEmoteTimer = 0
	self.spawnPosition = mcontroller.position()

	self.ballastTimer = 0
	self.ballastTimeout=2
	storage.ballasted = storage.ballasted or false

	self.fireTimer = 0
	self.fireTimeout=0.5
	self.hornTimer = 0
	self.hornTimeout=2.5
	self.hornPlaying = false
	self.headlightsOn = false
	self.headlightCanToggle = true

	self.engineLoopPlaying = false

	self.maxHealth =1
	self.maxBuoyancy =1
	self.waterFactor=0 --how much water are we in right now

	self.level = world.threatLevel() or 1
	self.maxHealth = healthLevelAdjust(config.getParameter("maxHealth"))
	self.protection = healthLevelAdjust(config.getParameter("protection"))

	self.damageStateNames = config.getParameter("damageStateNames")
	self.damageStateDriverEmotes = config.getParameter("damageStateDriverEmotes")
	self.materialKind = config.getParameter("materialKind")

	self.rockingInterval = config.getParameter("rockingInterval")

	self.windLevelOffset = config.getParameter("windLevelOffset")
	self.rockingWindAngleMultiplier = config.getParameter("rockingWindAngleMultiplier")
	self.maxRockingAngle = config.getParameter("maxRockingAngle")
	self.angleApproachFactor = config.getParameter("angleApproachFactor")

	self.speedRotationMultiplier = config.getParameter("speedRotationMultiplier")

	self.targetMoveSpeed = config.getParameter("targetMoveSpeed")
	self.moveControlForce = config.getParameter("moveControlForce")

	mcontroller.resetParameters(config.getParameter("movementSettings"))

 -- if storage.ballasted then mcontroller.applyParameters(config.getParameter("ballastedSettings")) end

	self.minWaterFactorToFloat=config.getParameter("minWaterFactorToFloat")
	self.maxWaterFactorToFloat= 1-self.minWaterFactorToFloat
	self.sinkingBuoyancy=config.getParameter("sinkingBuoyancy")
	self.sinkingFriction=config.getParameter("sinkingFriction")

	self.bowWaveParticleNames=config.getParameter("bowWaveParticles")
	self.bowWaveMaxEmissionRate=config.getParameter("bowWaveMaxEmissionRate")

	self.splashParticleNames=config.getParameter("splashParticles")
	self.splashEpsilon=config.getParameter("splashEpsilon")

	self.maxGroundSearchDistance = config.getParameter("maxGroundSearchDistance")

	local bounds = mcontroller.localBoundBox()
	local sixth = (bounds[3]-bounds[1])/6
	self.frontGroundTestPoint={bounds[1]+sixth,bounds[2]}
	self.backGroundTestPoint={bounds[3]-sixth,bounds[2]}
	local midp = bounds[1] +(bounds[3]-bounds[1])/2
	self.centerGroundTestPoint={midp,bounds[2]}

	--setup the store functionality
	self.ownerKey = config.getParameter("ownerKey")
	vehicle.setPersistent(self.ownerKey)

	self.liquidList = config.getParameter("safeLiquids")
	if not self.liquidList then
		self.liquidList = config.getParameter("unsafeLiquids", {"lava", "corelava"})
		self.liquidUnsafe = true
	else
		self.liquidUnsafe = false
	end

	message.setHandler("store", function(_, _, ownerKey)
		local animState=animator.animationState("base")
		if (animState=="idle" or animState=="sinking" or animState=="sunk") then
			if (self.ownerKey and self.ownerKey == ownerKey) then
				self.spawnPosition = mcontroller.position()
				animator.setAnimationState("base", "warpOut")
				local localStorable = (self.driver ==nil)
				return {storable = true, healthFactor = storage.health / self.maxHealth}
			end
		end
	end)

	--assume maxhealth
	if (storage.health) then
		animator.setAnimationState("base", "idle")
	else
		storage.health = self.maxHealth
		animator.setAnimationState("base", "warpIn")
	end

	--set up any damage effects we have...
	updateDamageEffects(0, true)
end

function update()
	local animState=animator.animationState("base")
	local waterFactor = mcontroller.liquidPercentage();
	drawDebugInfo(animState,waterFactor)

	if (animState=="warpedOut") then
		vehicle.destroy()
	elseif (animState=="warpIn" or animState=="warpOut") then
		animator.setAnimationState("propeller", "warping")-- hide propeller
		--lock it solid whilst spawning/despawning
		mcontroller.setPosition(self.spawnPosition)
		mcontroller.setVelocity({0,0})
	elseif (animState=="sunk") then
		-- not much here.
		local targetAngle=calcGroundCollisionAngle(self.maxGroundSearchDistance)
		self.angle = self.angle + (targetAngle - self.angle) * self.angleApproachFactor
		-- kick everyone out
		vehicle.setLoungeEnabled("drivingSeat",false)
		for num = 1,2,1 do
			if vehicle.entityLoungingIn("passenger"..num) ~= nil then
				vehicle.setLoungeEnabled("passenger"..num,false)
			end
		end
	elseif (animState=="sinking") then
		local sinkAngle=-math.pi*0.3
		self.angle=updateSinking(waterFactor, self.angle,sinkAngle)

	elseif (animState=="idle") then
		animator.setParticleEmitterEmissionRate("bubbles",1)
		animator.setParticleEmitterActive("bubbles", true)
		local healthFactor = storage.health / self.maxHealth
		local waterSurface = self.maxGroundSearchDistance
		self.waterBounds=mcontroller.localBoundBox()

		--work out water surface
		if (waterFactor>0) then
			waterSurface=(self.waterBounds[4] * waterFactor) + (self.waterBounds[2] * (1.0-waterFactor))
		end

		self.waterBounds[2] = waterSurface +0.25
		self.waterBounds[4] = waterSurface +0.5

		local facing
		local moving

		moving,facing = updateDriving()

		--Rocking in the wind, and rotating up when moving
		local floating = updateFloating(waterFactor, moving,facing)
		updateMovingEffects(floating,moving)
		updatePassengers(healthFactor)

		if storage.health<=0 then
			animator.setAnimationState("base", "sinking")
		end

		self.facingDirection = facing
		self.waterFactor=waterFactor --how deep are we in the water right now ?
	end

	--take care of rotating and flipping
--	animator.resetTransformationGroup("flip")
	animator.resetTransformationGroup("rotation")

	animator.setFlipped(self.facingDirection < 0)

	mcontroller.setRotation(self.angle)
	animator.rotateTransformationGroup("rotation", self.angle * self.facingDirection)
end

function getDriver()
	local drv = vehicle.entityLoungingIn("drivingSeat")
	if not drv then
		for num = 1,2,1 do
			drv = vehicle.entityLoungingIn("passenger"..num)
			if drv ~= nil then break end
		end
	end
	return drv or nil
end

function updateDriving()

	local moving = false
	local facing = self.facingDirection
	local floating = self.waterFactor > self.minWaterFactorToFloat and self.waterFactor < self.maxWaterFactorToFloat
	local driverThisFrame = getDriver()
	local holdingUp, holdingDown = false,false

	if driverThisFrame ~= self.driver then
		self.driver = driverThisFrame
		animator.setSoundVolume("hatch",self.waterFactor,1.5)
	animator.playSound("hatch")
	end

	self.fireTimer = self.fireTimer - script.updateDt()
	self.hornTimer = self.hornTimer - script.updateDt()
	self.ballastTimer = self.ballastTimer - script.updateDt()

	if (driverThisFrame ~= nil) then
		vehicle.setDamageTeam(world.entityDamageTeam(driverThisFrame))

		if not isSafeLiquid() then
			local fatman=vehicle.entityLoungingIn("drivingSeat")
			if fatman and world.entityExists(fatman) then
				world.sendEntityMessage(fatman, "queueRadioMessage", "subCantOperate", 1.0) -- send player a warning
			end
		else
			-- movement
			if vehicle.controlHeld("drivingSeat", "left") then
				mcontroller.approachXVelocity(-self.targetMoveSpeed, self.moveControlForce)
				moving = true
				facing = -1
			elseif vehicle.controlHeld("drivingSeat", "right") then
				mcontroller.approachXVelocity(self.targetMoveSpeed, self.moveControlForce)
				moving = true
				facing = 1
			end

			if (vehicle.controlHeld("drivingSeat", "down")) then -- negative buoyancy
				if (storage.ballasted) then
					local madj = moving and 1 or 0.75 -- dive faster while moving
					mcontroller.approachYVelocity(-self.targetMoveSpeed*madj, self.moveControlForce)
					moving = true
				end

				animator.setParticleEmitterEmissionRate("bubbles",25)
				animator.setParticleEmitterActive("bubbles", true)
				holdingDown = true
			elseif (vehicle.controlHeld("drivingSeat", "up")) then -- positive buoyancy
				if (storage.ballasted) then
					local madj = moving and 1 or 0.75 -- rise faster while moving
					mcontroller.approachYVelocity(self.targetMoveSpeed*madj, self.moveControlForce)
					moving = true
				end

				holdingUp = true
				animator.setParticleEmitterEmissionRate("bubbles",40)
				animator.setParticleEmitterActive("bubbles", true)
			end

			if self.ballastTimer <= 0 and vehicle.controlHeld("drivingSeat", "jump") then
				self.ballastTimer = self.ballastTimeout
				storage.ballasted = not storage.ballasted

				if not storage.ballasted then -- blow tanks and rise - maybe bubbles?
					applyMovementParams()
					animator.setParticleEmitterEmissionRate("bubbles",60)
					animator.setParticleEmitterActive("bubbles", true)
					vehicle.setLoungeDance("drivingSeat","warmhands")
				else -- sink to periscope depth / neutral buoyancy
					applyMovementParams()
					if not holdingDown and not holdingUp then
						if self.waterFactor < self.minWaterFactorToFloat then
							mcontroller.setYVelocity(6.5) -- pop it off surface
						end

						if floating then
							mcontroller.setYVelocity(-6.5) -- push it under surface
						end
					end
				end
			end
		end

		if vehicle.controlHeld("drivingSeat", "primaryFire") then
			if (self.headlightCanToggle) then
				if self.HeadlightsOn then
					animator.setSoundVolume("headlightSwitchOff",self.waterFactor,1.5)
					animator.playSound("headlightSwitchOff")
					animator.setLightActive("headlightBeam",false)
					animator.setLightActive("rearlightBeam",false)
					animator.setLightActive("bottomBeam",false)
					self.HeadlightsOn = false;
				else
					animator.setSoundVolume("headlightSwitchOn",self.waterFactor,1.5)
					animator.playSound("headlightSwitchOn")
					self.HeadlightsOn = true;
					animator.setLightActive("headlightBeam",true)
					animator.setLightActive("rearlightBeam",true)
					animator.setLightActive("bottomBeam",true)
				end
				self.headlightCanToggle = false
			end
		else
			self.headlightCanToggle = true;
		end

		if vehicle.controlHeld("drivingSeat", "altFire") then
			if not self.hornPlaying then
				animator.setSoundVolume("hornLoop",self.waterFactor,1.5)
				animator.playSound("hornLoop", -1)
				self.hornPlaying = true;
			end
		else
			if self.hornPlaying then
				animator.stopAllSounds("hornLoop")
				self.hornPlaying = false;
			end
		end

		if self.hornTimer < 0 then
			if vehicle.controlHeld("passenger1", "primaryFire") then
				animator.playSound("hornLoop")
				self.hornTimer = self.hornTimeout
			end
		else
			self.hornTimer = self.hornTimer - script.updateDt()
		end
	else
		vehicle.setDamageTeam({type = "passive"})
		self.notes = nil
	end

	return moving,facing
end

function updateSinking(waterFactor, currentAngle, sinkAngle)
	if storage.ballasted then storage.ballasted = false end

	if (mcontroller.onGround()) then

		--not floating any more. Must have touched bottom.
		animator.setAnimationState("base", "sunk")

		animator.setParticleEmitterEmissionRate("bubbles",15)
		animator.setParticleEmitterActive("bubbles", true)
		animator.setParticleEmitterEmissionRate("smoke",1)

		mcontroller.applyParameters({groundFriction = 0.1,liquidFriction=0,liquidBuoyancy=0,airFriction=0,airBuoyancy=0})

		local targetAngle=calcGroundCollisionAngle(self.maxGroundSearchDistance)
		currentAngle = currentAngle + (targetAngle - currentAngle) * self.angleApproachFactor
	else
		vehicle.setLoungeDance("drivingSeat","panic")
		for num = 1,2,1 do
			if vehicle.entityLoungingIn("passenger"..num) ~= nil then
				vehicle.setLoungeDance("passenger"..num,"panic")-- make passengers panic when sinking
			end
		end

		if self.hornTimer <0 and math.random(89) == 7 then -- reuse hornTimer, cant honk while sinking
			animator.burstParticleEmitter("damageShards")
			animator.playSound("changeDamageState") -- pressure implosions
			self.hornTimer = 1
		else
			self.hornTimer = self.hornTimer - script.updateDt()
		end

		if (waterFactor> self.minWaterFactorToFloat) then
			animator.setParticleEmitterEmissionRate("bubbles",11)
			animator.setParticleEmitterActive("bubbles", true)
			animator.setParticleEmitterActive("smoke", false)
		else
			animator.setParticleEmitterActive("smoke", true)
			animator.setParticleEmitterActive("bubbles", false)
		end

		if (currentAngle~=sinkAngle) then

			sinkAngle = math.max(sinkAngle,currentAngle+(self.speedRotationMultiplier * (-10+mcontroller.yVelocity())))
			currentAngle = currentAngle + (sinkAngle - currentAngle) * self.angleApproachFactor

			local lerpFactor=math.cos(currentAngle)
			local finalBuoyancy=(self.maxBuoyancy * lerpFactor) + (self.sinkingBuoyancy* (1.0-lerpFactor))
			applyMovementParams({ liquidBuoyancy=finalBuoyancy,
				liquidFriction=self.sinkingFriction,
				airBuoyancy=finalBuoyancy*0.75,
				airFriction=self.sinkingFriction,
				frictionEnabled=true})
		end
	end

	return currentAngle
end

function updateFloating(waterFactor, moving, facing)
	local floating = waterFactor > self.minWaterFactorToFloat and self.waterFactor < self.maxWaterFactorToFloat

	local speedAngle, targetAngle

	if (floating) then
		self.rockingTimer = self.rockingTimer + script.updateDt()
		if self.rockingTimer > self.rockingInterval then
			self.rockingTimer = self.rockingTimer - self.rockingInterval
		end

		speedAngle = mcontroller.xVelocity() * self.speedRotationMultiplier/2
		local windPosition = vec2.add(mcontroller.position(), self.windLevelOffset)
		local windLevel = world.windLevel(windPosition)
		world.debugText("%s ",windLevel,vec2.add(mcontroller.position(),{0,3}),"green")
		local windMaxAngle = math.max(self.rockingWindAngleMultiplier * windLevel * 0.5,self.maxRockingAngle)
		local windAngle= windMaxAngle * (math.sin(self.rockingTimer / self.rockingInterval * (math.pi * 2)))
		speedAngle = windAngle + speedAngle

		targetAngle = speedAngle-- + windMaxAngle
	else
		speedAngle = mcontroller.yVelocity() * self.speedRotationMultiplier * facing
		targetAngle=speedAngle+calcGroundCollisionAngle(self.waterBounds[2]) --pass in the water surtface
	end

	self.angle = self.angle + (targetAngle - self.angle) * self.angleApproachFactor

	if floating and waterFactor > (self.waterFactor + self.splashEpsilon) then
		local floatingLiquid=mcontroller.liquidId()

		if (floatingLiquid>0 and	floatingLiquid<=#self.splashParticleNames) then
			local splashEmitter=self.splashParticleNames[floatingLiquid]

			animator.setParticleEmitterOffsetRegion(splashEmitter,self.waterBounds)

			animator.burstParticleEmitter(splashEmitter)
		end
	end
	return floating
end

function updateMovingEffects(floating,moving)
	if moving then
		animator.setAnimationState("propeller", "turning")
		animator.setParticleEmitterActive("propwash", true)
		if not self.engineLoopPlaying then
			animator.setSoundVolume("engineLoop",self.waterFactor,1.5)
			animator.playSound("engineLoop",-1) -- loop forever -1
			self.engineLoopPlaying = true
		else
			animator.setSoundVolume("engineLoop", math.max(0.5,self.waterFactor),0.5)
		end

		if floating then
			local floatingLiquid=mcontroller.liquidId()

			if (floatingLiquid>0 and	floatingLiquid<=#self.bowWaveParticleNames) then
				local bowWaveEmitter=self.bowWaveParticleNames[floatingLiquid]

				local rateFactor=math.abs(mcontroller.xVelocity())/self.targetMoveSpeed
				rateFactor=rateFactor * self.bowWaveMaxEmissionRate
				animator.setParticleEmitterEmissionRate(bowWaveEmitter, rateFactor)

				local bowWaveBounds=self.waterBounds
				animator.setParticleEmitterOffsetRegion(bowWaveEmitter,bowWaveBounds)

				animator.setParticleEmitterActive(bowWaveEmitter, true)
			end
		end

	else
		animator.setAnimationState("propeller", "still")
		animator.setParticleEmitterActive("propwash", false)
		if self.engineLoopPlaying then
			animator.stopAllSounds("engineLoop")
			self.engineLoopPlaying = false
		end

		for i, emitter in ipairs(self.bowWaveParticleNames) do
			animator.setParticleEmitterActive(emitter, false)
		end
	end
end

--make the driver emote according to the damage state of the vehicle
function updatePassengers(healthFactor)
	if healthFactor >= 0 then
		--if we have a scared face on becasue of taking damage
		if self.damageEmoteTimer > 0 then
			self.damageEmoteTimer = self.damageEmoteTimer - script.updateDt()
			if (self.damageEmoteTimer <= 0) then
				maxDamageState = #self.damageStateDriverEmotes
				damageStateIndex = maxDamageState
				damageStateIndex = (maxDamageState - math.ceil(healthFactor * maxDamageState))+1
				vehicle.setLoungeEmote("drivingSeat",self.damageStateDriverEmotes[damageStateIndex])
				for n = 1,2,1 do
					vehicle.setLoungeEmote("passenger"..n,self.damageStateDriverEmotes[damageStateIndex])
				end
			end
		end
	end
end

function applyDamage(damageRequest)
	local damage = 0

	if damageRequest.damageType == "Damage" or damageRequest.damageType == "IgnoresDef" then
		damage = damage + root.evalFunction2("protection", damageRequest.damage, self.protection)
	elseif damageRequest.damageType == "IgnoresDef" then
		damage = damage + damageRequest.damage
	else
		return {}
	end

	updateDamageEffects(damage, false)
	storage.health = storage.health - damage

	if vehicle.getParameter then
		return {{
			sourceEntityId = damageRequest.sourceEntityId,
			targetEntityId = entity.id(),
			position = mcontroller.position(),
			damageDealt = damage,
			hitType = "Hit",
			damageSourceKind = damageRequest.damageSourceKind,
			targetMaterialKind = self.materialKind,
			killed = storage.health <= 0
		}}
	else
		return {{
			sourceEntityId = damageRequest.sourceEntityId,
			targetEntityId = entity.id(),
			position = mcontroller.position(),
			damageDealt = damage,
			healthLost = damage,
			hitType = "Hit",
			damageSourceKind = damageRequest.damageSourceKind,
			targetMaterialKind = self.materialKind,
			killed = storage.health <= 0
		}}
	end
end

function setDamageEmotes()
	local damageTakenEmote=config.getParameter("damageTakenEmote")
	self.damageEmoteTimer=config.getParameter("damageEmoteTime")
	vehicle.setLoungeEmote("drivingSeat",damageTakenEmote)
	for n = 1,2,1 do
		vehicle.setLoungeEmote("passenger"..n,damageTakenEmote)
	end
end


function updateDamageEffects(damage, initialise)
	local maxDamageState = #self.damageStateNames
	local healthFactor = (storage.health-damage) / self.maxHealth
	local prevhealthFactor = storage.health / self.maxHealth

	local prevDamageStateIndex =util.clamp( maxDamageState - math.ceil(prevhealthFactor * maxDamageState)+1, 1, maxDamageState)
	self.damageStateIndex =util.clamp( maxDamageState - math.ceil(healthFactor * maxDamageState)+1, 1, maxDamageState)

	if ((self.damageStateIndex > prevDamageStateIndex) or initialise==true) then
		animator.setGlobalTag("damageState", self.damageStateNames[self.damageStateIndex])

		--self.maxBuoyancy =mcontroller.parameters.liquidBuoyancy()
		self.maxBuoyancy = 1

		--change the floatation
		applyMovementParams(nil)
	end

	if (self.damageStateIndex > prevDamageStateIndex) then
		--people in the vehicle change thier faces when the vehicle is damaged.
		setDamageEmotes(healthFactor)

		--burstparticles.
		animator.burstParticleEmitter("damageShards")
		animator.playSound("changeDamageState")
	end
end

function calcGroundCollisionAngle(waterSurface)

	local frontDistance
	local backDistance
	local centerDistance = math.min(distanceToGround(self.centerGroundTestPoint),waterSurface)

	if self.facingDirection < 0 then
	-- keep y, swap x
		local bgtp = {self.backGroundTestPoint[1],self.frontGroundTestPoint[2]}
		local fgtp = {self.frontGroundTestPoint[1],self.backGroundTestPoint[2]}
		frontDistance = math.min(distanceToGround(fgtp),waterSurface)
		backDistance = math.min(distanceToGround(bgtp),waterSurface)
	else
		frontDistance = math.min(distanceToGround(self.frontGroundTestPoint),waterSurface)
		backDistance = math.min(distanceToGround(self.backGroundTestPoint),waterSurface)
	end

--	 world.debugText(string.format("front=%s, back=%s",frontDistance,backDistance),mcontroller.position(),"yellow")

	if frontDistance == self.maxGroundSearchDistance and centerDistance == self.maxGroundSearchDistance and backDistance == self.maxGroundSearchDistance then
		return 0
	else
		local rgroundAngle=-math.atan(backDistance - centerDistance)
		local fgroundAngle=-math.atan(centerDistance - frontDistance)
		local groundAngle = (rgroundAngle+fgroundAngle)/2
		return groundAngle
	end
end

function distanceToGround(point)
	-- to worldspace
	point = vec2.rotate(point, self.angle)
	point = vec2.add(point, mcontroller.position())

	local endPoint = vec2.add(point, {0, -self.maxGroundSearchDistance})
	world.debugLine(point, endPoint, {255, 0, 255, 255})
	local intPoint = world.lineCollision(point, endPoint)

	if intPoint then
		world.debugPoint(intPoint, {255, 255, 0, 255})
		return point[2] - intPoint[2]
	else
		world.debugPoint(endPoint, {255, 0, 0, 255})
		return self.maxGroundSearchDistance
	end

end

function applyMovementParams(args)
-- reset to defaults, apply base damage settings
	mcontroller.resetParameters(config.getParameter("movementSettings"))
	local settingsNameList=config.getParameter("damageMovementSettingNames")
	local settingsObject = config.getParameter(settingsNameList[self.damageStateIndex])

	if storage.ballasted then
		local so = config.getParameter("ballastedSettings")
		for k,v in pairs(so) do
			settingsObject[k] = v
		end
		settingsObject.liquidFriction = math.max(10,settingsObject.liquidFriction/2)
		settingsObject.airFriction = settingsObject.liquidFriction/2

	end
-- apply extra params
	if args ~= nil then
		for k,v in pairs(args) do
			settingsObject[k] = v
		end
	end

	mcontroller.applyParameters(settingsObject)

end

function toggleLights(state)
	animator.setLightActive("headlightBeam",state)
	animator.setLightActive("rearlightBeam",state)
	animator.setLightActive("bottomBeam",state)
end

function drawDebugInfo(animState,waterFactor)
	world.debugText("hp: %s/%s", storage.health,self.maxHealth,vec2.add(mcontroller.position(),{0,2}),"red")
	world.debugText("surface: %s", self.waterBounds and self.waterBounds[2]or"nil",vec2.add(mcontroller.position(),{0,1}),"yellow")
	world.debugText("+state: %s",animState,mcontroller.position(),"green")
	world.debugText("liqFric: %s",mcontroller.parameters().liquidFriction,vec2.add(mcontroller.position(),{0,-1}),"red")
	world.debugText("liquid%%: %s",waterFactor,vec2.add(mcontroller.position(),{0,-2}),"red")

end

function playSong() -- coroutine
local notes = {1.1,1.1,1.1,1.1,1.2,0.8,0.8,0.8,0.8,0.8}
local dura = {0.25,0.25,0.25,0.25,0.125,0.25,0.25,0.25,0.25,0.25}
	for i = 1,#notes do
		animator.setSoundVolume("hornLoop",self.waterFactor,1.5)
		animator.setSoundPitch("hornLoop",notes[i],0.25)
		animator.playSound("hornLoop")
		util.wait(dura[i])
	end
end
