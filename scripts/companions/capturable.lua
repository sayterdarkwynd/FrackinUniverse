require "/scripts/companions/util.lua"
require "/scripts/achievements.lua"

local originalUninit = uninit or function() end

-- Functions for entities that can be captured with a capturepod
capturable = {}

function capturable.init()
	message.setHandler("pet.attemptCapture", function (_, _, ...)
		if not caught then
			caught = capturable.attemptCapture(...)
				return caught
		end
	end)
	message.setHandler("pet.attemptRelocate", function (_, _, ...)
		return capturable.attemptRelocate(...)
	end)
	message.setHandler("pet.returnToPod", function(_, _, ...)
		local status = capturable.captureStatus()
		capturable.recall()
		return status
	end)
	message.setHandler("pet.status", function(_, _, persistentEffects, damageTeam)
		if persistentEffects then
			status.setPersistentEffects("owner", persistentEffects)
		end
		if damageTeam then
			monster.setDamageTeam(damageTeam)
		end
		return { status = capturable.captureStatus() }
	end)
	message.setHandler("pet.isCapturable", function()
		return capturable.capturable()
	end)
	message.setHandler("pet.restoreHealth", function(_, _, restoreHealthAmount, restoreHealthPercent)
		if not restoreHealthAmount and not restoreHealthPercent then
			if capturable.ownerUuid() then
				if status.resource("health") ~= status.resourceMax("health") then
					return true
				end
				return
			end
			return
		else
			if restoreHealthAmount then
				status.modifyResource("health", restoreHealthAmount)
			end
			if restoreHealthPercent then
				status.modifyResourcePercentage("health", restoreHealthPercent / 100)
			end
		end
		return
	end)
	message.setHandler("pandorasboxGetColorDirectives", function ()
		return pandorasboxColorDirectives
	end)
	message.setHandler("pandorasboxGetStatusText", function ()
		return storage.statusText
	end)

	local initialStatus = config.getParameter("initialStatus")
	if initialStatus then
		setCurrentStatus(initialStatus, "owner")
	end

	if capturable.podUuid() then
		capturable.startReleaseAnimation()
	end

	if capturable.wasRelocated() and not storage.spawned then
		status.addEphemeralEffect("monsterrelocatespawn")
		storage = config.getParameter("relocateStorage", {})
		storage.spawned = true
	end

	storage.statusTimer = storage.statusTimer or 0
	personalityEffects = config.getParameter("personalityEffects")
	if personalityEffects then
		status.setPersistentEffects("personality", personalityEffects)
	end

	petOwnerStatusEffects = config.getParameter("petOwnerStatusEffects")
	petOwnerStatusEffectTimer = 0

	pandorasboxSpecialColorConfig = config.getParameter("pandorasboxSpecialColors")
	storage.pandorasboxSpecialColor = storage.pandorasboxSpecialColor or config.getParameter("pandorasboxSpecialColor") or getPandorasboxSpecialColor()
	setPandorasboxSpecialColor()
	pandorasboxSpecialColorMusicPlayers = {}
	pandorasboxSpecialColorMusicRange = 100
	--pandorasboxSpecialColorMusic = {"/music/desert-battle-2.ogg"}
	pandorasboxSpecialColorMusic = {}
end

function capturable.startReleaseAnimation()
	status.addEphemeralEffect("monsterrelease")
	animator.setAnimationState("releaseParticles", "on")
end

function capturable.update(dt)

	if capturable.ownerUuid() then
		if not capturable.optName() then
			--monster.setName("Pet")
		end
		if not petName then
			petName = monster.uniqueParameters().shortdescription or world.entityName(entity.id()) or "Pet"
			if petName=="" then petName="Pet" end
		end
		if storage.statusTimer <= 0 then
			local statuses = root.assetJson("/monsters/statuses.config:statuses")
			local personality = config.getParameter("personality")
			if not personality or math.random() < 0.5 then
				options = statuses.generic
			else
				options = statuses[personality]
				if not options then
					options = statuses.generic
				end
			end
			storage.statusText = options[math.random(#options)]
			storage.statusTimer = 300
		else
			storage.statusTimer = storage.statusTimer - dt
		end
		if petName and storage.statusText then
			if storage.statusText == "" then
				monster.setName(petName)
			else
				monster.setName(petName .. "\n ^white;" .. storage.statusText)
			end
		end
		monster.setDisplayNametag(true)	--Make name visible.
		if petOwnerStatusEffects then
			if petOwnerStatusEffectTimer <= 0 then
				for _, petOwnerStatusEffect in pairs (petOwnerStatusEffects) do
					world.sendEntityMessage(capturable.ownerUuid(), "applyStatusEffect", petOwnerStatusEffect, 2)
				end
				petOwnerStatusEffectTimer = 1
			else
				petOwnerStatusEffectTimer = petOwnerStatusEffectTimer - dt
			end
		end
	end

	if config.getParameter("uniqueId") then
		if entity.uniqueId() == nil then
			world.setUniqueId(entity.id(), config.getParameter("uniqueId"))
		else
			assert(entity.uniqueId() == config.getParameter("uniqueId"))
		end
	end

	if capturable.despawnTimer then
		capturable.despawnTimer = capturable.despawnTimer - dt
		if capturable.despawnTimer <= 0 then
			capturable.despawn()
		end
	else
		local spawner = capturable.tetherUniqueId() or capturable.ownerUuid()
		if spawner then
			if not world.entityExists(world.loadUniqueEntity(spawner)) then
				capturable.recall()
			end
		end
	end

	if capturable.confirmRelocate then
		if capturable.confirmRelocate:finished() then
			if capturable.confirmRelocate:result() then
				capturable.despawnTimer = 0.3
			else
				status.removeEphemeralEffect("monsterrelocate")
				status.addEphemeralEffect("monsterrelocatespawn")
			end
			capturable.confirmRelocate = nil
		end
	end

	if not capturable.ownerUuid() and storage.pandorasboxSpecialColor and storage.pandorasboxSpecialColor ~= "default" then
		for playerId, _ in pairs(pandorasboxSpecialColorMusicPlayers) do
			local playerNearby = pandorasboxPlayerInRange(playerId)
			if not playerNearby then
				pandorasboxSpecialColorMusicPlayers[playerId] = nil
				world.sendEntityMessage(playerId, "stopAltMusic", 2.0)
			end
		end
		local newPlayers = world.playerQuery(entity.position(), pandorasboxSpecialColorMusicRange)
		for _, playerId in pairs(newPlayers) do
			if not pandorasboxSpecialColorMusicPlayers[playerId] then
			pandorasboxSpecialColorMusicPlayers[playerId] = true
			end
		end
		pandorasboxStartMusic()
		pandorasboxSpecialColorMusicPlaying = true
	end
end

function capturable.die()
	if capturable.ownerUuid() and not capturable.justCaptured then
		local podUuid = capturable.podUuid()
		if podUuid then
			local uniqueId = entity.uniqueId()
			local status = capturable.captureStatus()
			status.dead = true
			capturable.messageOwner("pets.updatePet", podUuid, uniqueId, status, true)
		end
		monster.setDropPool(nil)
	end
	if pandorasboxSpecialColorMusicPlaying then
		pandorasboxStopMusic()
	end
end

-- Extricate this pet from its pod until the next time the pod is 'healed'.
function capturable.disassociate()
	local podUuid = capturable.podUuid()
	if capturable.ownerUuid() and podUuid then
		capturable.messageOwner("pets.disassociatePet", podUuid, entity.uniqueId())
		capturable.disassociated = true
	end
end

-- Associate another monster with this monster's pod.
function capturable.associate(pet)
	assert(capturable.ownerUuid())
	local podUuid = config.getParameter("podUuid")
	capturable.messageOwner("pets.associatePet", podUuid, pet)
end

function capturable.tetherUniqueId()
	return config.getParameter("tetherUniqueId")
end

function capturable.ownerUuid()
	return config.getParameter("ownerUuid")
end

function capturable.podUuid()
	if capturable.disassociated then
		return nil
	end
	return config.getParameter("podUuid")
end

function capturable.messageOwner(message, ...)
	world.sendEntityMessage(capturable.tetherUniqueId() or capturable.ownerUuid(), message, ...)
end

function capturable.captureStatus()
	local currentStatus = getCurrentStatus()
	-- Compute some artificial stats for displaying in the inventory, next to the
	-- pet slot:
	local stats = currentStatus.stats
	stats.defense = stats.protection
	stats.attack = 0
	local touchDamageConfig = config.getParameter("touchDamage")
	if touchDamageConfig then
		stats.attack = touchDamageConfig.damage
		stats.attack = stats.attack * (config.getParameter("touchDamageMultiplier") or 1)
		stats.attack = stats.attack * root.evalFunction("monsterLevelPowerMultiplier", monster.level())
		stats.attack = stats.attack * stats.powerMultiplier
	end

	return currentStatus
end

function capturable.recall()
	animator.burstParticleEmitter("captureParticles")
	status.addEphemeralEffect("monstercapture")
	capturable.despawnTimer = 0.5
end

function capturable.despawn()
	monster.setDropPool(nil)
	monster.setDeathParticleBurst(nil)

	local projectileTarget = capturable.tetherUniqueId() or capturable.ownerUuid()
	if projectileTarget then
		projectileTarget = world.loadUniqueEntity(projectileTarget)
		if not projectileTarget or not world.entityExists(projectileTarget) then
			projectileTarget = nil
		end
	end
	if projectileTarget then
		local projectiles = 5
		for i = 1, projectiles do
			local angle = math.pi * 2 / projectiles * i
			local direction = { math.sin(angle), math.cos(angle) }
			world.spawnProjectile("monstercaptureenergy", entity.position(), entity.id(), direction, false, {
				target = projectileTarget
			})
		end
	end

	capturable.justCaptured = true
end

function capturable.attemptCapture(podOwner)
	-- Try to capture the monster. If successful, the monster is killed and the
	-- pet configuration is returned.
	if capturable.capturable() then
		local petInfo = capturable.generatePet()

		recordEvent(podOwner, "captureMonster", entityEventFields(entity.id()), worldEventFields(), {
			monsterLevel = monster.level()
		})

		capturable.recall()
		return petInfo
	end
	return nil
end

function capturable.wasRelocated()
	return config.getParameter("wasRelocated", false)
end

function capturable.attemptRelocate(sourceEntity)
	if config.getParameter("relocatable", false) and not capturable.confirmRelocate then
		--The point that the monster will scale toward
		local scaleOffsetPart = config.getParameter("scaleOffsetPart", "body")
		local attachPoint = vec2.div(animator.partPoint(scaleOffsetPart, "offset") or {0, 0}, 2) -- divide by two because partPoint adds offset to offset
		local petInfo = {
			monsterType = monster.type(),
			collisionPoly = mcontroller.collisionPoly(),
			parameters = monster.uniqueParameters(),
			attachPoint = attachPoint
		}
		for k,v in pairs(config.getParameter("relocateParameters", {})) do
			petInfo.parameters[k] = v
		end
		petInfo.parameters.relocateStorage = storage
		petInfo.parameters.seed = monster.seed()

		status.addEphemeralEffect("monsterrelocate")
		capturable.confirmRelocate = world.sendEntityMessage(sourceEntity, "confirmRelocate", entity.id(), petInfo)
		return true
	end
end

function capturable.capturable(capturer)
	if capturable.ownerUuid() or storage.respawner then
		return false
	end

	local isCapturable = config.getParameter("capturable")
	if not isCapturable then
		return false
	end

	local captureHealthFraction = config.getParameter("captureHealthFraction", 0.5)
	local healthFraction = status.resource("health") / status.resourceMax("health")
	if healthFraction > captureHealthFraction then
		return false
	end

	return true
end

--Khe's note: we're not incorporating this override. it will remain commented out.
--[[
--The named pets functionality is incorporated from (with permission from Vanake14)
--the Named Pets mod and Named Pets - Procedural Only mod. Procedural monsters, will only use procedural names.
--Unique monsters can receive both procedural and unique names.

function capturable.optName()

	local name = world.entityName(entity.id())
	if name == "" then
		name = root.generateName("/monsters/pandorasboxmonsternames/pandorasboxproceduralmonsternamegen.config:names")
		return nil
	else
		name = root.generateName("/monsters/pandorasboxmonsternames/pandorasboxmonsterpetnamegen.config:names")
	end

	return name
end
]]

--this is vanilla's implementation. we use this.
function capturable.optName()
	local name = world.entityName(entity.id())
	if name == "" then
		return nil
	end
	return name
end

function capturable.generatePet()
	local parameters = monster.uniqueParameters()
	parameters.aggressive = true

	parameters.seed = monster.seed()
	parameters.level = monster.level()

	local poly = mcontroller.collisionPoly()
	if #poly <= 0 then poly = nil end

	local monsterType = config.getParameter("capturedMonsterType", monster.type())
	local name = capturable.optName()
	local captureCollectables = config.getParameter("captureCollectables")
	parameters.monsterTypeName = world.entityName(entity.id())
	parameters.shortdescription = name

	local personalities = config.getParameter("personalities") or root.assetJson("/monsters/statuses.config:personalities")
	local personality = personalities[math.random(#personalities)]
	if type(personality) == "string" then
		personality = {personality = personality}
		for _, personalityData in pairs(root.assetJson("/monsters/statuses.config:personalities")) do
			if personalityData.personality == personality.personality then
				personality = personalityData
				break
			end
		end
	end
	parameters = util.mergeTable(parameters, personality)

	parameters.pandorasboxSpecialColor = storage.pandorasboxSpecialColor
	local portrait = world.entityPortrait(entity.id(), "full")
	if pandorasboxColorDirectives then
		portrait[1].image = portrait[1].image .. pandorasboxColorDirectives
	end

	return {
		name = name,
		description = world.entityDescription(entity.id()),
		portrait = portrait,
		collisionPoly = poly,
		status = capturable.captureStatus(),
		collectables = captureCollectables,
		config = {
			type = monsterType,
			parameters = parameters
		}
	}
end


function uninit()
	if pandorasboxSpecialColorMusicPlaying then
		--sb.logInfo("Uninit")
		pandorasboxStopMusic()
	end
	originalUninit()
end

function getPandorasboxSpecialColor()
	local color = "default"
	if pandorasboxSpecialColorConfig then
		local colorPoolInfo = pandorasboxSpecialColorConfig.colorPool
		color = checkColorPool(colorPoolInfo)
	end
	return color
end

function checkColorPool(pool)
	local colorPoolResult = util.weightedRandom(pool, generateSeed())
	if colorPoolResult.type == "color" then
		return colorPoolResult.color
	elseif colorPoolResult.type == "colorPool" then
		if type(colorPoolResult.colorPool) == "string" then
		 return checkColorPool(root.assetJson(colorPoolResult.colorPool).colorPool)
		elseif type(colorPoolResult.colorPool) == "table" then
			return checkColorPool(colorPoolResult.colorPool)
		end
	end
end

function setPandorasboxSpecialColor()
	if pandorasboxSpecialColorConfig then
		local colorInfoConfig = pandorasboxSpecialColorConfig.colors
		local colorInfo = {}
		for _, colors in pairs (colorInfoConfig) do
			if type(colors) == "string" then
				util.mergeTable(colorInfo, root.assetJson(colors).colors)
			elseif type(colors) == "table" then
				 util.mergeTable(colorInfo, colors)
			end
		end
		local colorData = colorInfo[storage.pandorasboxSpecialColor]
		if colorData then
			if colorData == "default" then
				return
			elseif type(colorData) == "string" then
				animator.setPartTag("body", "partImage", colorData)
				return
			elseif type(colorData) == "table" then
				if pandorasboxSpecialColorConfig.paletteSwapBaseImage then
					animator.setPartTag("body", "partImage", pandorasboxSpecialColorConfig.paletteSwapBaseImage)
				end
				pandorasboxColorDirectives = "?replace;"
				for original, new in pairs (colorData) do
					pandorasboxColorDirectives = pandorasboxColorDirectives .. original .. "=" .. new .. ";"
				end
				status.addPersistentEffect("pandorasboxSpecialColor", "pandorasboxshinymonster")
				return
			end
		end
	end
end

function pandorasboxPlayerInRange(id)
	if not world.entityExists(id) then
		-- Player died or left the mission
		return false
	end
	local newPlayers = world.playerQuery(entity.position(), pandorasboxSpecialColorMusicRange)
	for _, playerId in pairs(newPlayers) do
		if id == playerId then
			return true
		end
	end
	return false
end

function pandorasboxStartMusic()
	for playerId, _ in pairs(pandorasboxSpecialColorMusicPlayers) do
		world.sendEntityMessage(playerId, "playAltMusic", pandorasboxSpecialColorMusic, 2)
	end
end

function pandorasboxStopMusic()
	for playerId, _ in pairs(pandorasboxSpecialColorMusicPlayers) do
		world.sendEntityMessage(playerId, "stopAltMusic", 2)
	end
end