require "/scripts/messageutil.lua"
require "/scripts/companions/util.lua"

Pet = {}
Pet.__index = Pet

function Pet.new(...)
	local self = setmetatable({}, Pet)
	self:init(...)
	return self
end

function Pet:init(podUuid, json)
	self.podUuid = podUuid
	self.name = json.name
	self.rank = json.rank
	self.description = json.description
	self.portrait = json.portrait
	self.spawnConfig = json.config
	self.uniqueId = json.uniqueId
	self.status = json.status
	self.storage = json.storage
	self.collar = json.collar
	self.collisionPoly = json.collisionPoly

	self.persistent = json.persistent or false
	self.spawner = petSpawner
	self.dirtyOnStatusUpdate = true
	self.returnMessage = "pet.returnToPod"
	self.statusRequestMessage = "pet.status"

	if self.uniqueId then
		self.statusTimer = config.getParameter("statusTimer", 2)
	end
	--[[
	local elementaltypes=root.assetJson("/damage/elementaltypes.config")
	local buffer={}


	for element,data in pairs(elementaltypes) do
		if data.resistanceStat then
			buffer[data.resistanceStat]=true
		end
	end
	self.resistanceList=buffer]]
end

function Pet:store()
	local result = self:toJson()
	if not self.persistent then
		result.uniqueId = nil
	end
	return result
end

function Pet:toJson()
	return {
			podUuid = self.podUuid,
			name = self.name,
			rank = self.rank,
			description = self.description,
			portrait = self.portrait,
			config = self.spawnConfig,
			status = self.status,
			storage = self.storage,
			collar = self.collar,
			uniqueId = self.uniqueId,
			collisionPoly = self.collisionPoly,
			persistent = self.persistent
		}
end

function Pet:dead()
	return self.status and self.status.dead
end

function Pet:_scriptConfig(parameters)
	return parameters
end

function Pet:spawn(position, extraParameters)
	if self.uniqueId then return end

	position = position or entity.position()
	if self.collisionPoly then
		position = findCompanionSpawnPosition(position, self.collisionPoly)
	end

	local parameters = {}
	util.mergeTable(parameters, self.spawnConfig.parameters)
	if extraParameters then
		util.mergeTable(parameters, extraParameters)
	end

	local scriptConfig = self:_scriptConfig(parameters)
	parameters.persistent = self.persistent
	scriptConfig.podUuid = self.podUuid
	scriptConfig.ownerUuid = self.spawner.ownerUuid
	scriptConfig.tetherUniqueId = self.spawner.tetherUniqueId

	scriptConfig.initialStatus = copy(self.status) or {}
	scriptConfig.initialStorage = util.mergeTable(scriptConfig.initialStorage or {}, self.storage or {})

	-- Pets level with the player, gaining the effects of the player's armor
	if getPetPersistentEffects then
		-- If the player is spawning us, we gain the effects of their armor, so
		-- ignore the monster's level.
		parameters.level = 1
	end
	if self.spawner.levelOverride then
		-- If a tether is spawning us, we get the level of the world/ship we're on.
		parameters.level = self.spawner.levelOverride
	end

	scriptConfig.initialStatus.persistentEffects = self:getPersistentEffects()

	local damageTeam = self:damageTeam()
	parameters.damageTeamType = damageTeam.type
	parameters.damageTeam = damageTeam.team
	parameters.relocatable = false

	if self.collar and self.collar.parameters then
		util.mergeTable(parameters, self.collar.parameters)
	end

	self.uniqueId = sb.makeUuid()
	scriptConfig.uniqueId = self.uniqueId

	local result = self:_spawn(position, parameters)

	self.spawnedCollarParameters = self.collar and self.collar.parameters
	self.spawning = true
	self:resetStatusTimer(true)

	return result
end

function Pet:_spawn(position, parameters)
	result = world.spawnMonster(self.spawnConfig.type, position, parameters)
	-- ~Psi:	Debugging pets
	-- sb.logInfo("[Pet:spawn] " .. table.tostring(parameters))
	-- sb.logInfo("[Pet:spawn] " .. result )
	-- sb.logInfo("[Pet:spawn] " .. tostring( world.entityType(result) ))
	-- sb.logInfo("[Pet:spawn] " .. tostring( world.entityHealth(result)[2] ))
	return result
end

function Pet:resetStatusTimer(initialRequest)
	if initialRequest then
		self.statusTimer = config.getParameter("initialStatusTimer", config.getParameter("statusTimer", 0.5))
	else
		self.statusTimer = config.getParameter("statusTimer", 2)
	end
end

function Pet:damageTeam()
	local damageTeam = entity.damageTeam()
	if self.collar and self.collar.damageTeam then
		util.mergeTable(damageTeam, self.collar.damageTeam)
	end
	return damageTeam
end

function Pet:getPersistentEffects()
	local effects = jarray()

	-- The player's armor takes effect if the player is spawning the pet:
	if getPetPersistentEffects then
	local buffer={}

	--khe: overriding the vanilla function somewhat because it's too limited

	local armorEffects=status.getPersistentEffects("armor")
	local filteredEffects={}

	local petPersistentEffects = {
		--powerMultiplier = true,--removing because we're handling it slightly differently.
		protection = true,
		maxHealth = true
		}
	for _,button in pairs(armorEffects) do
		if type(button)=="table" then
			if petPersistentEffects[button.stat] then --or self.resistanceList[button.stat] then
				table.insert(filteredEffects,button)
			end
		end
	end
	--we're using the player's stats, rather than just armor stats, now.
	table.insert(filteredEffects,{stat="powerMultiplier",effectiveMultiplier=status.stat("powerMultiplier")})
	--doing the same for hp regen with the upcoming changes to it
	table.insert(filteredEffects,{stat="healthRegen",amount=status.stat("healthRegen")})
		util.appendLists(effects,filteredEffects)
		--util.appendLists(effects, getPetPersistentEffects())


	local aUSES=status.activeUniqueStatusEffectSummary()
	for _,pit in pairs(aUSES) do
		buffer[pit[1]]=true
		--sb.logInfo("aUSES: %s",aUSES)
	end
	aUSES=buffer
	buffer={}

	local frackinPetStatEffectsMetatable=status.statusProperty("frackinPetStatEffectsMetatable",{})
	--sb.logInfo("status.stat(powerMultiplier):%s",status.stat("powerMultiplier"))--works
	--sb.logInfo("fpsem 1: %s",frackinPetStatEffectsMetatable)
	local frackinPetStatEffectsMetatableBuffer={}
	local frackinPetStatEffectsMetatableDirty=false
	for bonusHandle,effectList in pairs(frackinPetStatEffectsMetatable) do
		if aUSES[bonusHandle] then
			if type(effectList)=="table" then
				for _,statEffect in pairs(effectList) do
					--try to keep them unique
					frackinPetStatEffectsMetatableBuffer[statEffect]=true
				end
				--debug, to see if this actually works:
			else
				sb.logInfo("petspawner.lua pet stat handler: HEY MORON, USE TABLES, NOT OTHER VALUES. frackinPetStatEffectsMetatableBuffer={bonusHandle={\"statuseffect1\",\"statuseffect2\"}} as example. not this crap: %s",effectList)
			end
		else
			frackinPetStatEffectsMetatable[bonusHandle]=nil
			frackinPetStatEffectsMetatableDirty=true
		end
	end
	if frackinPetStatEffectsMetatableDirty then
		status.setStatusProperty("frackinPetStatEffectsMetatable",frackinPetStatEffectsMetatable)
	end
	--sb.logInfo("fpsemb 1: %s",frackinPetStatEffectsMetatableBuffer)
	for statEffect,_ in pairs(frackinPetStatEffectsMetatableBuffer) do
		table.insert(buffer,statEffect)
	end
	frackinPetStatEffectsMetatableBuffer=buffer
	--table.insert(frackinPetStatEffectsMetatableBuffer,"fudarkcommander30")
	--sb.logInfo("fpsemb 2: %s",frackinPetStatEffectsMetatableBuffer)
	util.appendLists(effects,frackinPetStatEffectsMetatableBuffer)

		-- ~Psi:	Provide a bonus to the pet's base max health, and some minor regen, so it sucks less:
		-- ~Psi:	Total bonus is x4, but we only multiply by 3, since the player's bonusHealth has already been added once
		--local playerHealthBonus = world.entityHealth(player.id())[2]--pointless.
		local playerHealthBonus = status.resourceMax("health")
		playerHealthBonus = playerHealthBonus - 100
		if playerHealthBonus < 10 then playerHealthBonus = 10 end
		local petHealthBonus = playerHealthBonus * 3



		--************* FU special pet stats
	--khe: phasing this particular variant out
		--[[local playerProtectionBonus = 0
		for _, armourEffect in ipairs (effects) do
				if armourEffect.stat == "protection" then
						playerProtectionBonus = playerProtectionBonus + armourEffect.amount
						petHealthBonus = (playerHealthBonus + playerProtectionBonus ) * 1.5 --we add the current Protection of the player x1.5 as bonus health
				end
		end]]
	--khe: we now take into account the actual current value of the player's stats. though slightly delayed.
	petHealthBonus=(petHealthBonus+status.stat("protection"))*1.5

	--below comment is more or less false. pet stats are periodically refreshed
		--below stats are currently unused, as they need to be linked to update, or they will be permanent after summon, which isnt the intent for them
	--[[
		if config.getParameter("isNocturnal") then	--is it nocturnal?
			if	world.lightLevel <=0.5 then
					local petHealthBonus = playerHealthBonus * 1.15
			end
		end
		if config.getParameter("isDiurnal") then -- does it prefer the day?
			if world.lightLevel > 0.5 then
					local petHealthBonus = playerHealthBonus * 1.15
			end
		end
		if config.getParameter("isSurface") then -- does it prefer the surface?
			if world.inSurfaceLayer then
					local petHealthBonus = playerHealthBonus * 1.15
			end
		end
		if config.getParameter("isSubterrain") then -- does it prefer being underground?
			if world.underground then
					local petHealthBonus = playerHealthBonus * 1.15
			end
		end
		if config.getParameter("isWindy") then -- does it prefer windy worlds?
			if world.windLevel >=10 then
					local petHealthBonus = playerHealthBonus * 1.15
			end
		end
		]]
		-- New Regen formula
		-- https://www.desmos.com/calculator/mmv4okrc6f
		local petRegenBonus = math.log(playerHealthBonus * 0.05 + 1) / math.log(10) * 5

		-- Health Bonus
		util.appendLists(effects, {{stat="maxHealth",amount=petHealthBonus},{stat="healthRegen",amount=petRegenBonus}})

		-- ~Psi:	Debugging info
		sb.setLogMap("~[Pet Stats] playerHealthBonus", "%s", tostring(playerHealthBonus))
		sb.setLogMap("~[Pet Stats] petHealthBonus", "%s", tostring(petHealthBonus + playerHealthBonus))
		sb.setLogMap("~[Pet Stats] petRegenBonus", "%s", tostring(petRegenBonus))
	end

	-- Collars applied to the capturepod also take effect:
	if self.collar and self.collar.effects then
		util.appendLists(effects, self.collar.effects)
	end


	--sb.logInfo("%s",effects)
	return effects
end

function Pet:despawn(callback)
	if not self.uniqueId then return end
	self.statusTimer = nil
	promises:add(
		world.sendEntityMessage(self.uniqueId, self.returnMessage), function (status)
			self.status = status
			self.uniqueId = nil
			if callback then callback() end
		end
	)
end

function Pet:needsRespawn()
	if not self.uniqueId then return false end
	if storage.summonPets or (not compare(self.spawnedCollarParameters, self.collar and self.collar.parameters)) then
		-- The collar changed and it defines parameter overrides for the pet
		return true
	end
	return false
end

function Pet:update(dt)
	if self.statusTimer then
		if self:needsRespawn() then
			self:despawn(bind(self.spawn, self))
			self.uniqueId = nil
			return
		end

		if not self.uniqueId then
			self.statusTimer = nil
			return
		end

		self.statusTimer = self.statusTimer - dt
		if self.statusTimer <= 0 then
			self.statusTimer = nil

			self:sendStatusRequest()
		end
	end
end

function Pet:statusReady()
	return self.status and not self.spawning
end

function Pet:statusFailure()
	if not self.persistent then
		-- Pet entity doesn't exist.
		-- It didn't die, because it sends us its status when it does that.
		-- It just became unloaded. It's not persistent, so respawn it.
		self.uniqueId = nil
		self:spawn()
	else
		-- Companion was tethered to the world (i.e. persistent) and disappeared.
		-- Only possible cause is death
		self.status = self.status or {}
		self.status.dead = true
		self.uniqueId = nil
	end
end

function Pet:sendStatusRequest()
	local persistentEffects = self:getPersistentEffects()

	promises:add(world.sendEntityMessage(self.uniqueId, self.statusRequestMessage, persistentEffects, self:damageTeam()), function (state)
			self.status = state.status
			self.storage = state.storage
			if state.portrait then
				self.portrait = state.portrait
			end
			self.spawning = false
			self:resetStatusTimer(false)
			self.statusTimer = config.getParameter("statusTimer", 2)
			if self.dirtyOnStatusUpdate then
				self.spawner:markDirty()
			end
		end, function ()
			if self.spawning then
				-- The pet may simply not have spawned yet. Try requesting status again.
				self:resetStatusTimer(true)
			else
				self:statusFailure()
			end
		end)
end

function Pet:setStatus(status, dead)
	self.status = status
	if dead then
		self.status.dead = true
		self.uniqueId = nil
		self.statusTimer = nil
	end
end

-- Pods contain one or more pets. All are released and returned at once.
-- In the most common case, a pod will be only one pet, but they can contain
-- more, e.g. in the cases of hemogoblin and nutmidge, which drop smaller
-- monsters when they die.
Pod = {}
Pod.__index = Pod

function Pod.new(uuid, pets)
	local self = setmetatable({}, Pod)
	self.uuid = uuid
	self.pets = util.map(pets, function (petStore)
			return Pet.new(uuid, petStore)
		end)
	return self
end

function Pod:store()
	return {
		uuid = self.uuid,
		pets = util.map(self.pets, Pet.store, jarray())
	}
end

function Pod.load(json)
	return Pod.new(json.uuid, json.pets)
end

function Pod:dead()
	for _,pet in pairs(self.pets) do
		if not pet:dead() then
			return false
		end
	end
	return true
end

function Pod:release(position)
	for _,pet in pairs(self.pets) do
		if not pet:dead() then
			pet:spawn(position)
		end
	end
end

function Pod:recall()
	for _,pet in pairs(self.pets) do
		pet:despawn()
	end
end

function Pod:update(dt)
	for _,pet in pairs(self.pets) do
		pet:update(dt)
	end
end

function Pod:setCollar(collar)
	for _,pet in pairs(self.pets) do
		pet.collar = collar
	end
end

function Pod:findPetKey(uniqueId)
	for key,pet in pairs(self.pets) do
		if pet.uniqueId == uniqueId then
			return key
		end
	end
	return nil
end

function Pod:findPet(uniqueId)
	local key = self:findPetKey(uniqueId)
	if key then
		return self.pets[key]
	else
		return nil
	end
end

function Pod:removePet(uniqueId)
	local key = self:findPetKey(uniqueId)
	if key then
		table.remove(self.pets, key)
		return true
	end
	return false
end

function Pod:addPet(pet)
	self.pets[#self.pets+1] = pet
end

petSpawner = {}

function petSpawner:init()
	message.setHandler("pets.updatePet", simpleHandler(bind(petSpawner.updatePet, self)))
	message.setHandler("pets.disassociatePet", simpleHandler(bind(petSpawner.disassociatePet, self)))
	message.setHandler("pets.associatePet", simpleHandler(bind(petSpawner.associatePet, self)))
	message.setHandler("pets.setPodCollar", simpleHandler(bind(petSpawner.setPodCollar, self)))

	-- The values of these should be set by the code using petSpawner.
	self.pods = {}
	self.ownerUuid = nil
	self.tetherUniqueId = nil
	self.levelOverride = nil
end

function petSpawner:markDirty()
	-- Mark health bars and other visual status representations as needing an
	-- update.
	self.dirty = true
end

function petSpawner:clearDirty()
	-- Indicate that UI elements have been updated
	self.dirty = false
end

function petSpawner:isDirty()
	-- Do UI elements need updating?
	return self.dirty
end

function petSpawner:updatePet(podUuid, uniqueId, status, dead)
	local pod = self.pods[podUuid]
	if not pod then
		sb.logInfo("Cannot update pet %s from invalid pod %s", uniqueId, podUuid)
		return
	end

	local pet = pod:findPet(uniqueId)
	if not pet then
		sb.logInfo("Cannot update invalid pet %s from pod %s", uniqueId, podUuid)
		return
	end

	pet:setStatus(status, dead)
	self:markDirty()
end

function petSpawner:disassociatePet(podUuid, uniqueId)
	local pod = self.pods[podUuid]
	if not pod then
		sb.logInfo("Cannot disassociate pet %s from invalid pod %s", uniqueId, podUuid)
		return
	end

	pod:removePet(uniqueId)
	self:markDirty()
end

function petSpawner:associatePet(podUuid, petJson)
	local uniqueId = petJson.uniqueId
	if not uniqueId then
		sb.logInfo("Cannot associate non-existent pet with pod %s", podUuid)
		return
	end

	local pod = self.pods[podUuid]
	if not pod then
		sb.logInfo("Cannot associate pet %s with invalid pod %s", uniqueId, podUuid)
		return
	end

	local pet = Pet.new(podUuid, petJson)

	pod:addPet(pet)
	self:markDirty()
end

function petSpawner:setPodCollar(podUuid, collar)
	local pod = self.pods[podUuid]
	if not pod then
		sb.logInfo("Cannot set a collar %s on invalid pod %s", collar and collar.name, podUuid)
		return
	end

	pod:setCollar(collar)
	self:markDirty()
end
