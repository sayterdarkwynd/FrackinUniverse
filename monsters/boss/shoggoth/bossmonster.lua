require "/scripts/util.lua"
require "/scripts/rect.lua"
require "/scripts/vec2.lua"

function init()
	self.tookDamage = false
	self.dead = false

	if rangedAttack then
		rangedAttack.loadConfig()
	end

	--Movement
	self.spawnPosition = mcontroller.position()

	self.jumpTimer = 30000
	self.isBlocked = false
	self.willFall = false
	self.hadTarget = false
	self.failToMoveThreshold=3

	self.queryTargetDistance = config.getParameter("queryTargetDistance", 120)
	self.trackTargetDistance = config.getParameter("trackTargetDistance")
	self.switchTargetDistance = config.getParameter("switchTargetDistance")
	self.keepTargetInSight = config.getParameter("keepTargetInSight", true)
	self.jumpTargetDistance = 0

	self.targets = {}

	--Non-combat states
	local states = stateMachine.scanScripts(config.getParameter("scripts"), "(%a+State)%.lua")
	self.state = stateMachine.create(states)

	self.state.leavingState = function(stateName)
		self.state.moveStateToEnd(stateName)
	end

	self.skillParameters = {}
	for _, skillName in pairs(config.getParameter("skills")) do
		self.skillParameters[skillName] = config.getParameter(skillName)
	end

	--Load phases
	self.phases = config.getParameter("phases")
	setPhaseStates(self.phases)

	for skillName, params in pairs(self.skillParameters) do
		if type(_ENV[skillName].onInit) == "function" then
			_ENV[skillName].onInit()
		end
	end

	monster.setDeathParticleBurst("deathPoof")
	monster.setName("Shoggoth, Formless Horror")
	monster.setDamageBar("special")
	monster.setUniqueId(config.getParameter("uniqueId"))

	specialCounter = 0
	biteCounter = 0
end

function update(dt)
	if wrongWorld or (world.type()~="eldershoggoth") then
		if not wrongWorld then
			monster.setDropPool(nil)
		end
		status.setResource("health",0)
		wrongWorld=true
	end
	dungeonIDCheck=math.min((dungeonIDCheck or 0)-dt)
	world.debugPoint(entity.position(),"red")
	self.tookDamage = false
	self.healthLevel=status.resourcePercentage("health")
	trackTargets(self.keepTargetInSight, self.queryTargetDistance, self.trackTargetDistance, self.switchTargetDistance)

	if (self.levitationTimer and (self.levitationTimer > 0)) or ((self.failToMoveCounter or 0)>=self.failToMoveThreshold) then
		if ((self.failToMoveCounter or 0)>=self.failToMoveThreshold) then
			self.levitationTimer=4
			self.failToMoveCounter=0
			--status.modifyResource("health",dt*0.01)
		end
		status.addEphemeralEffect("levitation",0.1)
	end
	self.levitationTimer=math.max(0,(self.levitationTimer or 0) - dt)

	for skillName, params in pairs(self.skillParameters) do
		if type(_ENV[skillName].onUpdate) == "function" then
			_ENV[skillName].onUpdate(dt)
		end
	end
	if hasTarget() and status.resource("health") > 0 then
		if self.hadTarget == false then
			self.hadTarget = true
		end
		monster.setAggressive(true)
		script.setUpdateDelta(1)
		updatePhase(dt)
	else
		if (not hasTarget()) and (self.healthLevel > 0) and self.hadTarget then
			--Lost target, reset boss
			if currentPhase() then
				self.phaseStates[currentPhase()].endState()
			end
			monster.setAggressive(false)
			self.hadTarget = false
			self.phase = nil
			self.lastPhase = nil
			setPhaseStates(self.phases)
			--status.setResource("health", status.stat("maxHealth"))
			--if bossReset then bossReset() end
		elseif self.healthLevel<=0 then
			if currentPhase() then
				self.phaseStates[currentPhase()].endState()
			end
			--self.hadTarget = false
			--self.phase = nil
			--self.lastPhase = nil
			setPhaseStates(self.phases)
			if status.resource("health") <= 0 then
				local inState = self.state.stateDesc()
				animator.playSound("deathPuff")
				if inState ~= "dieState" and not self.state.pickState({ die = true }) then
					self.state.endState()
					self.dead = true
				end
			end
		end

		if status.resource("health") > 0 then script.setUpdateDelta(10) end

		if not self.state.update(dt) then
			--animator.playSound("turnHostile")
			self.state.pickState()
		end
	end
	self.hadTarget = hasTarget()
end

function die()
	world.setProperty("fu_shoggothDied", true)
end

function damage(args)
	self.tookDamage = true
	self.healthLevel=status.resourcePercentage("health")

	if self.tookDamage and math.random(10)==1 then
		animator.playSound("hurt")
	end

	if status.resource("health") <= 0 then
		local inState = self.state.stateDesc()
		animator.playSound("deathPuff")
		if inState ~= "dieState" and not self.state.pickState({ die = true }) then
			self.state.endState()
			self.dead = true
		end
	end

	if args.sourceId and args.sourceId ~= 0 and not inTargets(args.sourceId) then
		table.insert(self.targets, args.sourceId)
	end

	specialCounter = specialCounter + 1
	biteCounter = biteCounter + 1
end

function shouldDie()
	return self.dead
end

function hasTarget()
	if self.targetId and self.targetId ~= 0 then
		return self.targetId
	end
	return false
end

function trackTargets(keepInSight, queryRange, trackingRange, switchTargetDistance)
	if keepInSight == nil then keepInSight = true end

	if self.targetId == nil then
		table.insert(self.targets, util.closestValidTarget(queryRange))
	end

	--Move the closest target to the top of the list if it's inside the target switch range
	if switchTargetDistance then
		local closestValid = util.closestValidTarget(switchTargetDistance)
		local i = inTargets(closestValid)
		if i then table.remove(self.targets, i) end
		table.insert(self.targets, 1, closestValid)
	end

	--Remove any invalid targets from the list
	local updatedTargets = {}
	for i,targetId in ipairs(self.targets) do
		if validTarget(targetId, keepInSight, trackingRange) then
			table.insert(updatedTargets, targetId)
		end
	end
	self.targets = updatedTargets

	--Set target to be top of the list
	self.targetId = self.targets[1]
	if self.targetId then
		self.targetPosition = world.entityPosition(self.targetId)
	end
end

function validTarget(targetId, keepInSight, trackingRange)

	local entityType = world.entityType(targetId)

	if entityType ~= "player" and entityType ~= "npc" then
		status.addEphemeralEffect("invulnerable",math.huge)
		return false
	end

	--if not world.entityExists(targetId) then
	--	status.addEphemeralEffect("invulnerable",math.huge)
	--	return false
	--end

	--if keepInSight and not entity.entityInSight(targetId) then
	--	status.addEphemeralEffect("invulnerable",math.huge)
	--	return false
	--end

	if trackingRange then
		local distance = world.magnitude(mcontroller.position(), world.entityPosition(targetId))
		if distance > trackingRange then
			status.addEphemeralEffect("invulnerable",math.huge)
			return false
		end
	end
	status.removeEphemeralEffect("invulnerable")
	return true
end

function inTargets(entityId)
	for i,targetId in ipairs(self.targets) do
		if targetId == entityId then
			return i
		end
	end
	return false
end

--PHASES-----------------------------------------------------------------------

function currentPhase()
	return self.phase
end

function updatePhase(dt)
	if not self.phase then
		self.phase = 1
	end

	--Check if next phase is ready
	local nextPhase = self.phases[self.phase + 1]
	if nextPhase then
		if nextPhase.trigger and nextPhase.trigger == "healthPercentage" then
			if status.resourcePercentage("health") < nextPhase.healthPercentage then
				self.phase = self.phase + 1
			end
		end
	end

	if not self.lastPhase or self.lastPhase ~= self.phase then
		if self.lastPhase then
			self.phaseStates[self.lastPhase].endState()
		end
		self.phaseStates[currentPhase()].pickState({enteringPhase = currentPhase()})
	end
	if not self.phaseStates[currentPhase()].update(dt) then
		self.phaseStates[currentPhase()].pickState()
	end

	self.lastPhase = self.phase
end

function setPhaseStates(phases)
	self.phaseSkills = {}
	self.phaseStates = {}
	for i,phase in ipairs(phases) do
		self.phaseSkills[i] = {}
		for _,skillName in ipairs(phase.skills) do
			table.insert(self.phaseSkills[i], skillName)
		end
		if phase.enterPhase then
			table.insert(self.phaseSkills[i], 1, phase.enterPhase)
			animator.playSound("attackMain")
		end
		self.phaseStates[i] = stateMachine.create(self.phaseSkills[i])

		--Cycle through the skills
		self.phaseStates[i].leavingState = function(stateName)
			self.phaseStates[i].moveStateToEnd(stateName)
		end
	end
end

--MOVEMENT---------------------------------------------------------------------

function boundingBox(force)
	if self.boundingBox and not force then return self.boundingBox end

	local collisionPoly = mcontroller.collisionPoly()
	local bounds = {0, 0, 0, 0}

	for _,point in pairs(collisionPoly) do
		if point[1] < bounds[1] then bounds[1] = point[1] end
		if point[2] < bounds[2] then bounds[2] = point[2] end
		if point[1] > bounds[3] then bounds[3] = point[1] end
		if point[2] > bounds[4] then bounds[4] = point[2] end
	end
	self.boundingBox = bounds

	return bounds
end

function checkWalls(direction)
	local bounds = boundingBox()
	local position = mcontroller.position()

	local lineStart = {position[1], position[2]}

	if direction < 0 then
		lineStart[1] = lineStart[1] + bounds[1]
	else
		lineStart[1] = lineStart[1] + bounds[3]
	end

	local lineEnd = {lineStart[1] + direction * 3, lineStart[2]}
	local success=world.lineTileCollision(lineStart, lineEnd, {"Null", "Block", "Dynamic"})
	return success
end

function flyTo(position, speed)
	if not speed then speed = mcontroller.baseParameters().flySpeed end
	local toPosition = vec2.norm(world.distance(position, mcontroller.position()))
	mcontroller.controlFly(vec2.mul(toPosition, speed))
end

function handleProtection(on)
	for id,_ in pairs(self.dungeonIDList or {}) do
		world.setTileProtection(id,on)
	end
end

--------------------------------------------------------------------------------
function move(delta, run, jumpThresholdX)
	checkTerrain(delta[1])

	if ((self.failToMoveCounter or 0) < self.failToMoveThreshold) and ((not self.levitationTimer) or (self.levitationTimer <= 0)) then
		mcontroller.controlMove(delta[1], run)
	else
		mcontroller.setVelocity({util.clamp(delta[1],-1,1)*1,1})
		--sb.logInfo("%s",{delta,run,jumpThresholdX})
		--mcontroller.controlMove({delta[1],100}, true)
	end
	-- destroy walls, etc
	self.healthLevel = status.resourcePercentage("health")
	self.randval = math.random(200)
	self.randval2 = math.random(100)

	spit1={ power = 0, speed = 15, timeToLive = 0.2 }
	spit2={ power = 0, speed = 15, timeToLive = 0.2, actionOnReap = {{action = "config",file = "/projectiles/explosions/acidexplosionshoggoth/acidexplosionshoggoth.config"},{action = "spawnmonster",type = "floatingshoggoth",offset = {0, 2},arguments = {aggressive = true},level=monster.level()/4.0}}}
	if self.tookDamage and math.random(10)==1 then
		animator.playSound("hurt")
	end


	--specialCounter = specialCounter + 1--timer so these dont spam
	if (movementPulseTimer or 0) <= 0 then
		local ePos=mcontroller.position()
		if not lastPos then lastPos=ePos end
		if vec2.mag(world.distance(lastPos,ePos))<1.0 then

			biteCounter = (biteCounter or 0) + 1--timer so these dont spam
			soundChance = math.random(100)
			if biteCounter >= 3 then
				self.doBite=(self.randval2 >= 70)
				ePos[2]=ePos[2]-8
				world.spawnProjectile("shoggothchompexplosion2",ePos,entity.id(),{mcontroller.facingDirection(),-20},false,spit1)
				world.spawnProjectile("shoggothchompexplosion2",vec2.add(ePos,{mcontroller.facingDirection()*4,0}),entity.id(),{mcontroller.facingDirection(),-20},false,spit1)
				if soundChance > 50 then
					animator.playSound("shoggothChomp")
				end
				self.failToMoveCounter=(self.failToMoveCounter or 0) + 1
				biteCounter = 0
			end
		else
			self.failToMoveCounter=self.failToMoveCounter or 0
			biteCounter=0.0
		end
		lastPos=ePos
		movementPulseTimer=1.0
	else
		movementPulseTimer=movementPulseTimer-script.updateDt()
	end

	--specialCounter = specialCounter + script.updateDt()-- 1 --timer so these dont spam
	if not specialCounter or ((os.time()-specialCounter)>=5) then
	--if specialCounter >= 150 then
		if ((self.healthLevel <= 0.50) and (self.randval) >= 100) or ((self.healthLevel <= 0.65) and (self.randval) >= 150) or (self.healthLevel <= 0.80) and (self.randval) >= 190 then
			world.spawnProjectile("minishoggothspawn2",mcontroller.position(),entity.id(),{0,2},false,spit2)
			animator.playSound("giveBirth")
			specialCounter=os.time()
		end
		--specialCounter = 0
	end
	--[[if self.jumpTimer > 0 and not self.onGround then
		mcontroller.controlHoldJump()
	else
		--self.jumpTimer=self.jumpTimer-script.updateDt()
		if self.jumpTimer <= 0 then
			if jumpThresholdX == nil then jumpThresholdX = 4 end

			-- We either need to be blocked by something, the target is above us and
			-- we are about to fall, or the target is significantly high above us
			local doJump = false
			if isBlocked() then
				doJump = false
			elseif (delta[2] >= 0 and willFall() and math.abs(delta[1]) > 7) then
				doJump = false
			elseif (math.abs(delta[1]) < jumpThresholdX and delta[2] > config.getParameter("jumpTargetDistance")) then
				doJump = false
			end

			if doJump then
				self.jumpTimer = util.randomInRange(config.getParameter("jumpTime"))
				mcontroller.controlJump()
			end
		end
	end]]

	if delta[2] < 0 then
		mcontroller.controlDown()
	end
end

--------------------------------------------------------------------------------
--TODO: this could probably be further optimized by creating a list of discrete points and using sensors... project for another time
function checkTerrain(direction)
	--normalize to 1 or -1
	direction = direction > 0 and 1 or -1

	local reverse = false
	if direction ~= nil then
		reverse = direction ~= mcontroller.facingDirection()
	end

	local boundBox = mcontroller.boundBox()

	-- update self.isBlocked
	local blockLine, topLine
	if not reverse then
		blockLine = {monster.toAbsolutePosition({boundBox[3] + 0.25, boundBox[4]}), monster.toAbsolutePosition({boundBox[3] + 0.25, boundBox[2] - 1.0})}
	else
		blockLine = {monster.toAbsolutePosition({-boundBox[3] - 0.25, boundBox[4]}), monster.toAbsolutePosition({-boundBox[3] - 0.25, boundBox[2] - 1.0})}
	end
	if (not self.dungeonIDList) or (not dungeonIDCheck) or dungeonIDCheck <=0 then
		self.dungeonIDList={}
		local ePos=entity.position()
		for xP=math.floor(ePos[1])-100,math.ceil(ePos[1])+100 do--math.floor(math.min(blockLine[1][1],blockLine[2][1])),math.ceil(math.max(blockLine[1][1],blockLine[2][1])) do
			for yP=math.floor(ePos[2])-1,math.ceil(ePos[2])+1 do--math.floor(math.min(blockLine[1][2],blockLine[2][2])),math.ceil(math.max(blockLine[1][2],blockLine[2][2])) do
				self.dungeonIDList[world.dungeonId({xP,yP})]=world.isTileProtected({xP,yP})
			end
		end
		self.dungeonIDList[0]=nil
		dungeonIDCheck=15
	end
	--world.debugPoly(blockLine,"red")
	local blockBlocks = world.collisionBlocksAlongLine(blockLine[1], blockLine[2])
	self.isBlocked = false
	self.basicBlocked=false
	self.hookBlocked=false
	self.climbBlocked=false
	if #blockBlocks > 0 then
		--check for basic blockage
		local topOffset = blockBlocks[1][2] - blockLine[2][2]
		if topOffset > 2.75 then
			self.isBlocked = true
			self.basicBlocked=true
		elseif topOffset > 0.25 then
			--also check for that stupid little hook ledge thing
			self.isBlocked = not world.pointTileCollision({blockBlocks[1][1] - direction, blockBlocks[1][2] - 1})
			self.hookBlocked=self.isBlocked
			if not self.isBlocked then
				--also check if blocks above prevent us from climbing
				topLine = {monster.toAbsolutePosition({boundBox[1], boundBox[4] + 0.5}), monster.toAbsolutePosition({boundBox[3], boundBox[4] + 0.5})}
				self.isBlocked = world.lineTileCollision(topLine[1], topLine[2])
				self.climbBlocked=self.isBlocked
			end
		end
	end

	-- update self.willFall
	local fallLine
	if reverse then
		fallLine = {monster.toAbsolutePosition({-0.5, boundBox[2] - 0.75}), monster.toAbsolutePosition({boundBox[3], boundBox[2] - 0.75})}
	else
		fallLine = {monster.toAbsolutePosition({0.5, boundBox[2] - 0.75}), monster.toAbsolutePosition({-boundBox[3], boundBox[2] - 0.75})}
	end
	self.willFall = world.lineTileCollision(fallLine[1], fallLine[2]) == false and world.lineTileCollision({fallLine[1][1], fallLine[1][2] - 1}, {fallLine[2][1], fallLine[2][2] - 1}) == false
end

--------------------------------------------------------------------------------
function isBlocked()
	return self.isBlocked
end

--------------------------------------------------------------------------------
function willFall()
	return self.willFall
end

function waitforseconds(seconds)
	local start = os.time()
	repeat until os.time() > start + seconds
end

