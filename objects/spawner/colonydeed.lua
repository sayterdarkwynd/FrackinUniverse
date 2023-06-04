require "/scripts/quest/participant.lua"
require "/scripts/achievements.lua"
require "/scripts/util.lua"

function init()
	self = config.getParameter("deed")
	if not self then
		sb.logInfo("Colony deed at %s is missing configuration.", object.position())
		return
	end

	object.setInteractive(self.interactive)
	self.position = object.toAbsolutePosition(self.position)

	local questParticipantOutbox = Outbox.new("questParticipantOutbox", ContactList.new("questParticipantContacts"))
	self.questParticipant = QuestParticipant.new("questParticipant", questParticipantOutbox)

	self.timers = TimerManager:new()

	self.scanTimer = Timer:new("scanTimer", {
			delay = scanDelay,
			completeCallback = scan,
			loop = true
		})
	if not self.scanTimer:active() then
		self.scanTimer:start("deed.firstScan")
	end
	self.timers:manage(self.scanTimer)

	self.rentTimer = Timer:new("rentTimer", {
			timeCallback = world.time,
			delay = randomizeRentTimer
		})
	self.timers:runWhile(self.rentTimer, function()
			return isOccupied() and not isGrumbling() and not isVacated() and not isHealing()
		end)

	self.grumbleTimer = Timer:new("grumbleTimer", {
			timeCallback = world.time,
			delay = "deed.repairTimeRange",
			completeCallback = checkHouseIntegrity
		})
	self.timers:runWhile(self.grumbleTimer, function ()
			return isOccupied() and storage.grumbles and #storage.grumbles > 0
		end)

	self.healingTimer = Timer:new("healingTimer", {
			timeCallback = world.time,
			delay = "deed.healingStateDuration",
			completeCallback = respawnTenants
		})
	self.timers:manage(self.healingTimer)

	self.healthCheckTimer = Timer:new("healthCheckTimer", {
			delay = "deed.healthCheckFrequency",
			completeCallback = healthCheck,
			loop = true
		})
	self.timers:runWhile(self.healthCheckTimer, function ()
			return isOccupied() and not isVacated() and not isHealing()
		end)

	message.setHandler("getRent", function()
			self.rentTimer:reset()
			return {
				pool = getRent().pool,
				level = getRentLevel()
			}
		end)
end

function onInteraction(args)
	self.questParticipant:fireEvent("interaction", args.sourceId)

	if isOccupied() then
		if isRentDue() then
			local primary = primaryTenant()
			callTenantsHome("rent")
			if not self.npcsDeliverRent or not primary or not world.callScriptedEntity(primary, "tenant.canDeliverRent") then
				world.spawnTreasure(self.position, getRent().pool, getRentLevel())
				self.rentTimer:reset()
			end
		else
			callTenantsHome("beacon")
		end
		animator.setAnimationState("deedState", "beacon")

	else
		scanVacantArea()
	end
end

function die()
	self.questParticipant:die()

	-- Deed was broken; evict all tenants.
	evictTenants()
end

function uninit()
	self.questParticipant:uninit()
end

function update(dt)
	self.questParticipant:update()

	self.timers:update(dt)

	updateAnimation(dt)

	if storage.house then
		util.debugPoly(storage.house.boundary, "red")
	end
end

function isSubmultiset(multiset, sub)
	for element, count in pairs(sub) do
		if not multiset[element] or multiset[element] < count then
			return false
		end
	end
	return true
end

function multisetSubtract(multiset, elements)
	for element, count in pairs(elements) do
		multiset[element] = math.max(0, (multiset[element] or 0) - count)
	end
end

function getStealableObjects()
	-- Used by the quest generator to determine what objects can be stolen.
	-- Objects are only stealable if removing them wouldn't cause the tenant's
	-- tag criteria not to be met.
	if not storage.occupier then return {} end
	local house = findHouseBoundary(self.position, self.maxPerimeter)
	local scanResults = scanHouseContents(storage.house.boundary)

	local spareTags = countTags(scanResults.objects, house.doors or {})
	multisetSubtract(spareTags, getTagCriteria())

	local objects = {}
	for objectId,_ in pairs(scanResults.objects or {}) do
		local objectTags = countObjectTags(objectId)
		if isSubmultiset(spareTags, objectTags) then
			multisetSubtract(spareTags, objectTags)
			objects[#objects+1] = objectId
		end
	end
	return objects
end

function getOwnedObjectNames()
	return storage.house and storage.house.objects or {}
end

function getPredominantTags(n)
	if not storage.occupier then return {} end
	local house = findHouseBoundary(self.position, self.maxPerimeter)
	local scanResults = scanHouseContents(storage.house.boundary)

	local tagMultiset = countTags(scanResults.objects, house.doors or {})
	tagMultiset.door = nil
	tagMultiset.light = nil

	local sortedTags = {}
	for tag, count in pairs(tagMultiset) do
		sortedTags[#sortedTags+1] = {count, tag}
	end
	table.sort(sortedTags, function (a, b)
			return a[1] > b[1]
		end)

	if n then
		sortedTags = util.take(n, sortedTags)
	end

	return util.map(sortedTags, function (row)
			return row[2]
		end)
end

function updateAnimation(dt)
	local currentState = animator.animationState("deedState")
	if currentState == "beacon" or currentState == "error" then
		-- These animations end on their own
		return
	end

	if isVacated() then
		animator.setAnimationState("deedState", "vacated")

	elseif isRentDue() then
		animator.setAnimationState("deedState", "rentdue")

	elseif isOccupied() then
		if isGrumbling() then
			animator.setAnimationState("deedState", "grumbling")
		elseif isHealing() then
			animator.setAnimationState("deedState", "healing")
		else
			animator.setAnimationState("deedState", "occupied")
		end

	else
		animator.setAnimationState("deedState", "scanning")
	end
end

function isGrumbling()
	return self.grumbleTimer:active()
end

function isRentDue()
	local rent = getRent()
	return rent and self.rentTimer:complete()
end

function getRent()
	if not storage.occupier then
		return nil
	end
	if not storage.occupier.rent then
		storage.occupier.rent = root.tenantConfig(storage.occupier.name).rent
	end
	return storage.occupier.rent
end

function getRentLevel()
	if world.getProperty("ship.level") then return 1 end
	return world.threatLevel()
end

-- Deed / house is occupied if a tenant NPC has moved in, whether or not the
-- NPC is present there.
function isOccupied()
	return storage.occupier ~= nil
end

function isVacated()
	if not isOccupied() or not self.haveVacatedState or not storage.grumbles or #storage.grumbles == 0 then
		return false
	end

	for _,tenant in ipairs(storage.occupier.tenants) do
		if tenant.uniqueId and world.findUniqueEntity(tenant.uniqueId):result() then
			return false
		end
	end
	return true
end

function isHealing()
	return self.healingTimer:active()
end

function scan()
	if isOccupied() then
		checkHouseIntegrity()
	else
		scanVacantArea()
	end
end

function scanDelay()
	if self.questParticipant:hasActiveQuest() then
		return util.randomInRange(config.getParameter("deed.questScanFrequency"))
	end
	return util.randomInRange(config.getParameter("deed.scanFrequency"))
end

function randomizeRentTimer()
	local rent = getRent()
	if not rent then return nil end
	return util.randomInRange(config.getParameter("deed.rentPeriodRange", rent.periodRange))
end

function healthCheck()
	if anyTenantsDead() then
		self.healingTimer:start()
	end
end

function tenantEventFields()
	if not storage.occupier then return {} end
	local tenant = storage.occupier.tenants[1] or {}
	return {
			spawnType = tenant.spawn,
			species = tenant.species,
			type = tenant.type
		}
end

function evictTenants()
	if not isOccupied() then
		return
	end

	util.debugLog("Evicting tenant(s)...")
	for _,tenant in ipairs(storage.occupier.tenants) do
		if tenant.uniqueId and world.findUniqueEntity(tenant.uniqueId):result() then
			local entityId = world.loadUniqueEntity(tenant.uniqueId)

			world.callScriptedEntity(entityId, "tenant.evictTenant")
		end
	end

	local owner = config.getParameter("owner")
	if owner then
		recordEvent(owner, "evictTenant", tenantEventFields(), worldEventFields())
	end

	if not self.haveVacatedState then
		storage.occupier = nil
		storage.grumbles = nil
	end

	local tenantCount = world.getProperty("tenantCount", 1)
	tenantCount = math.max(tenantCount - 1, 0)
	world.setProperty("tenantCount", tenantCount)
end

function findTenant(uniqueId)
	if not storage.occupier then return end
	for i,tenant in ipairs(storage.occupier.tenants) do
		if tenant.uniqueId == uniqueId then
			return i
		end
	end
end

function withTenant(uniqueId, func)
	local i = findTenant(uniqueId)
	if i then
		func(storage.occupier.tenants[i])
	end
end

function backupTenantStorage(uniqueId, preservedStorage)
	withTenant(uniqueId, function (tenant)
			tenant.overrides.scriptConfig = tenant.overrides.scriptConfig or {}
			tenant.overrides.scriptConfig.initialStorage = preservedStorage
		end)
end

function replaceTenant(currentUniqueId, newTenantInfo)
	withTenant(currentUniqueId, function (tenant)
			util.mergeTable(tenant, newTenantInfo)
		end)
end

function detachTenant(uniqueId)
	local i = findTenant(uniqueId)
	assert(i ~= nil)
	table.remove(storage.occupier.tenants, i)
	if #storage.occupier.tenants == 0 then
		object.smash(false)
	end
end

function primaryTenant()
	-- Return the entityId of the first tenant
	if not storage.occupier then return nil end
	for _,tenant in ipairs(storage.occupier.tenants) do
		if tenant.uniqueId and world.findUniqueEntity(tenant.uniqueId):result() then
			local entityId = world.loadUniqueEntity(tenant.uniqueId)
			return entityId
		end
	end
	return nil
end

function getTenants()
	if not storage.occupier then return {} end
	return storage.occupier.tenants
end

function countMonsterTenants()
	if not storage.occupier then return 0 end
	return #util.filter(storage.occupier.tenants, function (tenant)
			return tenant.spawn == "monster"
		end)
end

function callTenantsHome(reason)
	if not isOccupied() then
		return
	end

	for _,tenant in ipairs(storage.occupier.tenants) do
		if tenant.uniqueId and world.findUniqueEntity(tenant.uniqueId):result() then
			local entityId = world.loadUniqueEntity(tenant.uniqueId)

			world.callScriptedEntity(entityId, "tenant.returnHome", reason)
		end
	end
end

function chooseTenants(seed, tags)
	if seed then
		math.randomseed(seed)
	end

	local matches = root.getMatchingTenants(tags)
	local highestPriority = 0
	for _,tenant in ipairs(matches) do
		if tenant.priority > highestPriority then
			highestPriority = tenant.priority
		end
	end

	matches = util.filter(matches, function(match)
			return match.priority >= highestPriority
		end)
	util.debugLog("Applicable tenants:")
	for _,tenant in ipairs(matches) do
		util.debugLog("	" .. tenant.name .. " (priority " .. tenant.priority .. ")")
	end

	if #matches == 0 then
		util.debugLog("Failed to find a suitable tenant")
		return
	end

	local occupier = matches[math.random(#matches)]
	for _,tenant in ipairs(occupier.tenants) do
		if type(tenant.species) == "table" then
			tenant.species = tenant.species[math.random(#tenant.species)]
		end
		tenant.seed = sb.makeRandomSource():randu64()
	end
	storage.occupier = occupier

	if seed then
		math.randomseed(util.seedTime())
	end
end

function spawn(tenant)
	local level = tenant.level or getRentLevel()
	tenant.overrides = tenant.overrides or {}
	local overrides = tenant.overrides

	if not overrides.damageTeamType then
		overrides.damageTeamType = "friendly"
	end
	if not overrides.damageTeam then
		overrides.damageTeam = 0
	end
	overrides.persistent = true

	local position = {self.position[1], self.position[2]}
	for i,val in ipairs(self.positionVariance) do
		if val ~= 0 then
			position[i] = position[i] + math.random(val) - (val / 2)
		end
	end

	local entityId
	if tenant.spawn == "npc" then
		entityId = world.spawnNpc(position, tenant.species, tenant.type, level, tenant.seed, overrides)
		if tenant.personality then
			world.callScriptedEntity(entityId, "setPersonality", tenant.personality)
		else
			tenant.personality = world.callScriptedEntity(entityId, "personality")
		end
		if not tenant.overrides.identity then
			tenant.overrides.identity = world.callScriptedEntity(entityId, "npc.humanoidIdentity")
		end

	elseif tenant.spawn == "monster" then
		if not overrides.seed and tenant.seed then
			overrides.seed = tenant.seed
		end
		if not overrides.level then
			overrides.level = level
		end
		entityId = world.spawnMonster(tenant.type, position, overrides)

	else
		sb.logInfo("colonydeed can't be used to spawn entity type '" .. tenant.spawn .. "'")
		return nil
	end

	if tenant.seed == nil then
		tenant.seed = world.callScriptedEntity(entityId, "object.seed")
	end
	return entityId
end

function anyTenantsDead()
	for _,tenant in ipairs(storage.occupier.tenants) do
		if not tenant.uniqueId or not world.findUniqueEntity(tenant.uniqueId):result() then
			return true
		end
	end
	return false
end

function deedUniqueId()
	local uniqueId = entity.uniqueId()
	if not uniqueId then
		uniqueId = sb.makeUuid()
		world.setUniqueId(entity.id(), uniqueId)
	end
	return uniqueId
end

function respawnTenants()
	if not storage.occupier then
		return
	end
	for _,tenant in ipairs(storage.occupier.tenants) do
		if not tenant.uniqueId or not world.findUniqueEntity(tenant.uniqueId):result() then
			local entityId = spawn(tenant)
			tenant.uniqueId = tenant.uniqueId or sb.makeUuid()
			world.setUniqueId(entityId, tenant.uniqueId)

			world.callScriptedEntity(entityId, "tenant.setHome", storage.house.floorPosition, storage.house.boundary, deedUniqueId())
		end
	end
end

function addTenant(tenant)
	table.insert(storage.occupier.tenants, tenant)
	respawnTenants()
end

function sendNewTenantNotification()
	local owner = config.getParameter("owner")
	if owner then
		local tenantCount = world.getProperty("tenantCount", 0)
		tenantCount = tenantCount + 1
		world.setProperty("tenantCount", tenantCount)

		local deedsNearby = world.objectQuery(entity.position(), self.nearbyQueryRange, {
				name = object.name()
			})

		recordEvent(owner, "newTenant", tenantEventFields(), worldEventFields(), {
				countOnWorld = tenantCount,
				deedsNearby = #deedsNearby
			})

		-- Send a message to the owner of the deed for any quests they're
		-- playing to handle.
		world.sendEntityMessage(owner, "colonyDeed.newHome", storage.occupier.tenants, storage.house.objects, storage.house.boundary)
	end
end

function scanVacantArea()
	local house = findHouseBoundary(self.position, self.maxPerimeter)

	if house.poly and world.regionActive(polyBoundBox(house.poly)) then
		local scanResults = scanHouseContents(house.poly)

		if scanResults.otherDeed or fuDeedCheck(house.poly) then
			util.debugLog("Colony deed is already present")
		elseif scanResults.objects then
			local tags = countTags(scanResults.objects, house.doors)
			storage.house = {
					boundary = house.poly,
					contents = tags,
					seed = scanResults.hash,
					floorPosition = house.floor,
					objects = countObjects(scanResults.objects, house.doors)
				}
			local seed = nil
			if self.hashHouseAsSeed then
				seed = scanResults.hash
			end
			chooseTenants(seed, tags)

			if isOccupied() then
				respawnTenants()
				animator.setAnimationState("particles", "newArrival")
				sendNewTenantNotification()
				return
			end
		end
	elseif not house.poly then
		util.debugLog("Scan failed")
		animator.setAnimationState("deedState", "error")
	else
		util.debugLog("Parts of the house are unloaded - skipping scan")
	end
end

function checkHouseIntegrity()
	storage.grumbles = scanHouseIntegrity()

	if fuDeedCheck() then
		storage.grumbles[#storage.grumbles+1] = {"otherDeed"}
	end

	for _,tenant in ipairs(storage.occupier.tenants) do
		if tenant.uniqueId and world.findUniqueEntity(tenant.uniqueId):result() then
			local entityId = world.loadUniqueEntity(tenant.uniqueId)

			world.callScriptedEntity(entityId, "tenant.setGrumbles", storage.grumbles)
		end
	end

	if #storage.grumbles > 0 and isGrumbling() and self.grumbleTimer:complete() then
		evictTenants()
	end
end

function getTagCriteria()
	if not storage.occupier then return {} end
	if not storage.occupier.tagCriteria then
		storage.occupier.tagCriteria = root.tenantConfig(storage.occupier.name).colonyTagCriteria
	end
	return storage.occupier.tagCriteria
end

-- scanHouseIntegrity returns a list of things currently wrong with the house
function scanHouseIntegrity()
	if not world.regionActive(polyBoundBox(storage.house.boundary)) then
		util.debugLog("Parts of the house are unloaded - skipping integrity check")
		return storage.grumbles
	end

	local grumbles = {}
	local house = findHouseBoundary(self.position, self.maxPerimeter)

	if not house.poly then
		grumbles[#grumbles+1] = {"enclosedArea"}
	else
		storage.house.floorPosition = house.floor
		storage.house.boundary = house.poly
	end

	local scanResults = scanHouseContents(storage.house.boundary)
	if scanResults.otherDeed then
		grumbles[#grumbles+1] = {"otherDeed"}
	end

	local objects = countObjects(scanResults.objects, house.doors or {})
	storage.house.objects = storage.house.objects or {}
	for objectName, count in pairs(objects) do
		local oldCount = storage.house.objects[objectName] or 0
		if count > oldCount then
			self.questParticipant:fireEvent("objectAdded", objectName, count - oldCount)
		end
	end
	for objectName, count in pairs(storage.house.objects) do
		local newCount = objects[objectName] or 0
		if newCount < count then
			self.questParticipant:fireEvent("objectRemoved", objectName, count - newCount)
		end
	end
	storage.house.objects = objects

	local tags = countTags(scanResults.objects, house.doors or {})
	for tag, requiredAmount in pairs(getTagCriteria()) do
		local currentAmount = tags[tag] or 0
		if currentAmount < requiredAmount then
			grumbles[#grumbles+1] = {"tagCriteria", tag, requiredAmount - currentAmount}
		end
	end

	return grumbles
end

function fuDeedCheck(housePoly)
	local objects = world.objectQuery(self.position, self.position, {poly = housePoly or storage.house.boundary, boundMode = "Position"})
	local fuDeed = false
	for _, objectId in pairs (objects) do
		if objectId ~= entity.id() then
			if world.getObjectParameter(objectId, "isDeed") then
				fuDeed = true
				break
			end
	 end
	end
	return fuDeed
end
