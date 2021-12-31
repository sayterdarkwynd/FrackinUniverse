require "/scripts/companions/petspawner.lua"
require "/scripts/companions/recruitspawner.lua"
require "/scripts/achievements.lua"

local petPersistentEffects = {
		powerMultiplier = true,
		protection = true,
		maxHealth = true
	}

local function filterPersistentEffects(effects)
	return util.filter(effects, function (effect)
			return type(effect) == "table" and petPersistentEffects[effect.stat]
		end)
end

function getPetPersistentEffects()
	local effects = filterPersistentEffects(status.getPersistentEffects("armor"))
	if onOwnShip() then
		util.appendLists(effects, recruitSpawner:getShipPersistentEffects())
	end
	return effects
end

function init()
	-- Sets up handlers for messages common to all pet spawner types:
	petSpawner:init()
	-- Sets up handlers for messages common to all recruit spawner types:
	recruitSpawner:init()

	-- Messages specific to player-spawned pets:
	message.setHandler("pets.podPets", localHandler(podPets))
	message.setHandler("pets.setPodPets", localHandler(setPodPets))
	message.setHandler("pets.isPodActive", localHandler(isPodActive))
	message.setHandler("pets.activatePod", localHandler(activatePod))
	message.setHandler("pets.deactivatePod", localHandler(deactivatePod))
	message.setHandler("pets.togglePod", localHandler(togglePod))
	message.setHandler("pets.spawnFromPod", localHandler(spawnFromPod))

	--Messages specific to player-spawned recruits:
	message.setHandler("recruits.offerRecruit", simpleHandler(offerRecruit))
	message.setHandler("recruits.offerMercenary", simpleHandler(offerMercenary))
	message.setHandler("recruits.requestFollow", simpleHandler(requestFollow))
	message.setHandler("recruits.requestUnfollow", simpleHandler(requestUnfollow))
	message.setHandler("recruits.offerUniformUpdate", simpleHandler(offerUniformUpdate))
	message.setHandler("recruits.triggerFieldBenefits", simpleHandler(triggerFieldBenefits))
	message.setHandler("recruits.triggerCombatBenefits", simpleHandler(triggerCombatBenefits))

	petSpawner.ownerUuid = entity.uniqueId()
	recruitSpawner.ownerUuid = entity.uniqueId()
	recruitSpawner.activeCrewLimit = config.getParameter("activeCrewLimit")
	recruitSpawner.crewLimit = function() return player.shipUpgrades().crewSize end

	for uuid, podStore in pairs(storage.pods or {}) do
		petSpawner.pods[uuid] = Pod.load(podStore)
	end

	local followers = playerCompanions.getCompanions("followers")
	for _,follower in pairs(followers) do
		follower.uniqueId = nil
	end
	recruitSpawner:load({
			followers = followers,
			shipCrew = playerCompanions.getCompanions("shipCrew")
		}, storage.recruits or {})

	storage.activePods = storage.activePods or {}
	self.spawnedCompanions = false
end

-- Releases the pets that are currently active. Triggered by player init,
-- but only runs after the player's map sector is loaded.
function spawnCompanions()
	if world.pointTileCollision(entity.position(), {"Null"}) then
		-- The player's sector is not loaded yet. We need it to be loaded in
		-- order to be able to spawn pets at positions that won't intersect
		-- world geometry.
		return false
	end

	-- don't attempt to spawn companions when entering a world without gravity
	if world.gravity(entity.position()) <= 0 then
		return true
	end

	for uuid,_ in pairs(storage.activePods) do
		petSpawner.pods[uuid]:release()
	end
	petSpawner:markDirty()

	for _, recruit in pairs(recruitSpawner.followers) do
		if not recruit:dead() then
			recruit:spawn()
		end
	end
	recruitSpawner:markDirty()

	return true
end

function updateShipCrewEffects()
	if onOwnShip() then
		for _,effect in pairs(recruitSpawner:getShipEphemeralEffects()) do
			if type(effect) ~= "string" then
				effect = effect.effect
			end
			status.removeEphemeralEffect(effect)
		end
		status.setPersistentEffects("shipCrew", recruitSpawner:getShipPersistentEffects())
	else
		status.clearPersistentEffects("shipCrew")
	end
end

function updateShipUpgrades()--reworked, in vanilla the math is atrocious if the values applied aren't identical.
	--in vanilla it iterates through the list, applying a multiplier of 0.5 to the power of an incremented timer to each value.
	--the series 5,5,25 will result in 13.75, while 25,5,5 will result in something near 28. unacceptable.
	local diminishingReturns = config.getParameter("shipUpgradeDiminishingReturns")--0.5 in vanilla, changing to 0.25+1/3 in FU
	local upgrades = root.assetJson("/ships/shipupgrades.config")--base for fuel efficiency is 0
	local appliedCount = {}

	local modifiers = jobject()
	for _,upgrade in pairs(recruitSpawner:getShipUpgrades()) do
		for k,v in pairs(upgrade) do
			if not upgrades[k] then
				error(string.format("No base value set for ship upgrade %s in /ship/shipupgrades.config. Cannot apply crew benefit."))
			end
			local value = v
			modifiers[k] = (modifiers[k] or {})-- + value
			table.insert(modifiers[k],value)
		end
	end
	for property,value in pairs(modifiers) do
		--sb.logInfo("pre-sort: property %s modifiers %s",property,modifiers)
		table.sort(value,function(a,b) return b<a end)
		--sb.logInfo("post-sort: property %s modifiers %s",property,modifiers)
		local result=0.0
		for _,v in pairs(value) do
			local count = appliedCount[property] or 0
			local v2=v * (diminishingReturns ^ count)
			appliedCount[property] = count + 1
			result=result+v2
		end
		--sb.logInfo("property %s result %s",property,result)
		upgrades[property] = upgrades[property] + result
		--sb.logInfo("property %s upgrades(property) %s",property,upgrades[property])
	end
	--local dink=status and true or false
	--sb.logInfo("status exists %s",dink)
	--sb.logInfo("upgrades: %s",upgrades)
	--rather than setting the upgrades directly, we set it so that these are set to a status property on the player. this is read by /scripts/quest/shipUpgrades.lua
	status.setStatusProperty("fu_shipUpgradeStatProperty",upgrades)
	--player.upgradeShip(upgrades)
end

function uninit()
	status.clearPersistentEffects("shipCrew")
	if onOwnShip() then
		status.addEphemeralEffects(recruitSpawner:getShipEphemeralEffects())
	end

	storage.pods = {}

	for uuid, pod in pairs(petSpawner.pods) do
		-- Player is leaving the world; return all pets
		pod:recall()
		storage.pods[uuid] = pod:store()
	end

	recruitSpawner:uninit()
	for category, companions in pairs(recruitSpawner:storeCrew()) do
		playerCompanions.setCompanions(category, companions)
	end
	storage.recruits = recruitSpawner:store()
end

function dismissCompanion(category, podUuid)
	if category == "pets" then
		deactivatePod(podUuid)
	elseif category == "crew" then
		local recruit = recruitSpawner:getRecruit(podUuid)

		recruitSpawner:dismiss(podUuid)

		recordEvent(entity.id(), "dismissCrewMember", recruitSpawner:eventFields(), recruit:eventFields())
	end
end

function update(dt)
	if not self.spawnedCompanions then
		self.spawnedCompanions = spawnCompanions()
	end

	promises:update()

	for uuid,_ in pairs(storage.activePods) do
		local pod = petSpawner.pods[uuid]
		pod:update(dt)
		local podItem = player.getItemWithParameter("podUuid", uuid)
		if pod:dead() or not podItem then
			deactivatePod(uuid)
		else
			petSpawner:setPodCollar(uuid, podItem.parameters.currentCollar)
		end
	end

	recruitSpawner:update(dt)
	if onOwnShip() then
		recruitSpawner:shipUpdate(dt)

		for uuid, recruit in pairs(recruitSpawner.shipCrew) do
			if not recruitSpawner.beenOnShip[uuid] then
				runFirstShipExperience(uuid, recruit)
			end
		end
	end

	if petSpawner:isDirty() then
		local activePets = {}
		for uuid,_ in pairs(storage.activePods) do
			for _,pet in pairs(petSpawner.pods[uuid].pets) do
				if pet:statusReady() and not pet:dead() then
					activePets[#activePets+1] = pet:toJson()
				end
			end
		end
		playerCompanions.setCompanions("pets", activePets)
		petSpawner:clearDirty()
	end

	if recruitSpawner:isDirty() then
		updateShipCrewEffects()
		updateShipUpgrades()

		logCrewSize()

		for category, companions in pairs(recruitSpawner:storeCrew()) do
			playerCompanions.setCompanions(category, companions)
		end
		recruitSpawner:clearDirty()
	end

	if onOwnShip() and recruitSpawner:crewSize() >= recruitSpawner.crewLimit() then
		grantNextLicense()
	end

	if storage.pendingItem then
		storage.pendingItemDelay = (storage.pendingItemDelay or 0) - dt
		if storage.pendingItemDelay <= 0 then
			player.giveItem(storage.pendingItem)
			storage.pendingItem = nil
			storage.pendingItemDelay = nil
		end
	end
end

function onOwnShip()
	return player.worldId() == player.ownShipWorldId()
end

function podPets(podUuid)
	local pod = petSpawner.pods[podUuid]
	if pod then
		return util.map(pod.pets, Pet.store, jarray())
	end
	return nil
end

function setPodPets(podUuid, pets)
	local pod = petSpawner.pods[podUuid]
	if pod then
		pod:recall()
	end
	petSpawner.pods[podUuid] = Pod.new(podUuid, pets)
	if storage.activePods[podUuid] then
		petSpawner.pods[podUuid]:release()
	end
	petSpawner:markDirty()
end

function isPodActive(podUuid)
	return storage.activePods[podUuid] == true
end

-- Activate means 'regard this pod as active' but do not release yet.
-- When the player throws the filledcapturepod, activatePod is called.
-- When the filledcapturepod hits something, it calls spawnFromPod to release
-- the monster.
function activatePod(podUuid)
	local limit = config.getParameter("activePodLimit")
	if limit < 1 then return end
	local pod = petSpawner.pods[podUuid]
	if not pod then
		sb.logInfo("Cannot activate invalid pod %s", podUuid)
		return
	end

	-- If we have too many pets out, call some back
	local overflow = math.max(util.tableSize(storage.activePods) + 1 - limit, 0)
	for uuid,_ in pairs(storage.activePods) do
		deactivatePod(uuid)
		overflow = overflow - 1
		if overflow <= 0 then
			break
		end
	end

	storage.activePods[podUuid] = true
	petSpawner:markDirty()
end

-- Deactivate calls the pet back.
function deactivatePod(podUuid)
	local pod = petSpawner.pods[podUuid]
	if not pod then
		sb.logInfo("Cannot deactivate invalid pod %s", podUuid)
		return
	end

	pod:recall()
	storage.activePods[podUuid] = nil
	petSpawner:markDirty()
end

function togglePod(podUuid)
	if storage.activePods[podUuid] then
		deactivatePod(podUuid)
		return false
	else
		activatePod(podUuid)
		return true
	end
end

function spawnFromPod(podUuid, position)
	local pod = petSpawner.pods[podUuid]
	if not pod then
		sb.logInfo("Cannot spawn pet from invalid pod %s", podUuid)
		return
	end

	if storage.activePods[podUuid] then
		pod:release(position)
	end
end

function logCrewSize()
	--sb.logInfo("Followers: %s / %s", recruitSpawner:followerCount(), recruitSpawner.activeCrewLimit)
	--sb.logInfo("Crew: %s / %s", recruitSpawner:crewSize(), recruitSpawner.crewLimit())
end

-- See if we can add recruitUuid to our ship crew list without
-- breaching any limits
function checkCrewLimits(recruitUuid)
	if not recruitSpawner:canGainCrew(recruitUuid) then
		-- Can't gain any more crew members
		if player.hasCompletedQuest("fu_byos") then
			player.radioMessage("crewLimitByos")
		else
			player.radioMessage("crewLimit")
		end
		logCrewSize()
		return false
	end
	return true
end

-- See if we can add recruitUuid to our followers lists without
-- breaching any limits
function checkFollowLimits(recruitUuid)
	if not recruitSpawner:canGainFollower(recruitUuid) then
		-- Can't gain any more followers
		player.radioMessage("activeCrewLimit")
		logCrewSize()
		return false
	end
	return true
end

function recruitTags(recruit)
	return {
			name = recruit.name,
			role = recruit.role.name,
			field = recruit.role.field,
			rank = recruit.rank,
			status = recruit.statusText
		}
end

function createConfirmationDialog(configPath, recruit)
	local dialogConfig = root.assetJson(configPath)
	local tags = recruitTags(recruit)
	for key,value in pairs(dialogConfig) do
		if type(value) == "string" then
			dialogConfig[key] = sb.replaceTags(value, tags)
		end
	end
	return dialogConfig
end

local function playerHasItems(price)
	for _, item in pairs(price) do
		if not player.hasItem(item) then return false end
	end
	return true
end

local function consumeItems(price)
	for _, item in pairs(price) do
		player.consumeItem(item)
	end
end

local function recruitImpl(uniqueId, position, recruitInfo, entityId, dialogConfigPath, price)
	local uuid = recruitInfo.podUuid or sb.makeUuid()
	if not playerHasItems(price) or not checkCrewLimits(uuid) then
		world.sendEntityMessage(uniqueId, "recruit.interactBehavior", { sourceId = entity.id() })
		return false
	end

	local recruit = Recruit.new(uuid, recruitInfo)
	local dialogConfig = createConfirmationDialog(dialogConfigPath, recruit)
	dialogConfig.sourceEntityId = entityId
	if recruit.portrait then
		dialogConfig.images.portrait = recruit.portrait
	end

	promises:add(player.confirm(dialogConfig), function (choice)
			if choice and playerHasItems(price) then
				promises:add(world.sendEntityMessage(uniqueId, "recruit.confirmRecruitment", recruitSpawner.ownerUuid, uuid, onOwnShip()), function (success)
						if success then
							consumeItems(price)

							recruitSpawner:addCrew(uuid, recruitInfo)
						end
					end)
			else
				world.sendEntityMessage(uniqueId, "recruit.declineRecruitment", recruitSpawner.ownerUuid)
			end
		end)
end

function offerRecruit(uniqueId, position, recruitInfo, entityId)
	return recruitImpl(uniqueId, position, recruitInfo, entityId, "/interface/confirmation/recruitconfirmation.config", {})
end

function offerMercenary(uniqueId, position, recruitInfo, entityId, price)
	return recruitImpl(uniqueId, position, recruitInfo, entityId, "/interface/confirmation/hiremercenaryconfirmation.config", price)
end

function requestFollow(uniqueId, recruitUuid, recruitInfo)
	if not checkFollowLimits(recruitUuid) then
		world.sendEntityMessage(uniqueId, "recruit.interactBehavior", { sourceId = entity.id() })
		return
	end
	promises:add(world.sendEntityMessage(uniqueId, "recruit.confirmFollow"), function (success)
			recruitSpawner:recruitFollowing(onOwnShip(), recruitUuid, recruitInfo)
		end)
end

function requestUnfollow(uniqueId, recruitUuid)
	if not onOwnShip() then
		local recruit = recruitSpawner:getRecruit(recruitUuid)
		if not recruit then return end

		world.sendEntityMessage(uniqueId, "recruit.confirmUnfollowBehavior")
	else
		recruitSpawner:recruitUnfollowing(onOwnShip(), recruitUuid)
		world.sendEntityMessage(uniqueId, "recruit.confirmUnfollow")
	end
end

function getPlayerUniform()
	local items = {}
	local slots = {}
	local uniformSlots = config.getParameter("uniformSlots")
	for slotName,playerSlots in pairs(uniformSlots) do
		table.insert(slots, slotName)
		for _,playerSlot in pairs(playerSlots) do
			if player.equippedItem(playerSlot) then
				items[slotName] = player.equippedItem(playerSlot)
				break
			end
		end
	end
	return {
			slots = slots,
			items = items
		}
end

function setUniform(items)
	recruitSpawner.uniform = items
end

function updateUniform()
	setUniform(getPlayerUniform())
end

function resetUniform()
	setUniform(nil)
end

function offerUniformUpdate(recruitUuid, entityId)
	local recruit = recruitSpawner:getRecruit(recruitUuid)
	if not recruit then return end

	if not recruitSpawner.uniform then
		local dialogConfig = createConfirmationDialog("/interface/confirmation/setuniformconfirmation.config", recruit)
		dialogConfig.sourceEntityId = entityId
		dialogConfig.images.portrait = world.entityPortrait(entity.id(), "full")
		promises:add(player.confirm(dialogConfig), function (choice)
				if choice then
					updateUniform()
				end
			end)
	else
		local dialogConfig = createConfirmationDialog("/interface/confirmation/resetuniformconfirmation.config", recruit)
		dialogConfig.sourceEntityId = entityId
		dialogConfig.images.portrait = world.entityPortrait(entity.id(), "full")
		promises:add(player.confirm(dialogConfig), function (choice)
				if choice then
					resetUniform()
				end
			end)
	end
end

function grantNextLicense()
	local currentShipLevel = player.shipUpgrades().shipLevel
	local licenses = root.assetJson("/ships/licenses.config")
	local upgrade = licenses[tostring(currentShipLevel)]
	if upgrade and upgrade.licenseLevel > (storage.licenseLevel or 0) then
		if upgrade.exclusiveQuests then
			for _,exclusive in pairs(upgrade.exclusiveQuests) do
				if player.hasQuest(exclusive) then
					return
				end
			end
		end

		if upgrade.cinematic then
			player.playCinematic(upgrade.cinematic, true)
		end
		if upgrade.radioMessage then
			player.radioMessage(upgrade.radioMessage, 0.1)
		end
		assert(upgrade.item)
		storage.pendingItem = upgrade.item
		storage.pendingItemDelay = upgrade.itemDelay or 0
		storage.licenseLevel = upgrade.licenseLevel
	end
end

function runFirstShipExperience(uuid, recruit)
	if not recruit.spawning and recruit.uniqueId then
		player.radioMessage("gainedCrewMember")
		world.sendEntityMessage(recruit.uniqueId, "notify", { type = "firstTimeOnShip", sourceId = entity.id()})
		recruitSpawner.beenOnShip[uuid] = true

		recordEvent(entity.id(), "newCrewMember", recruitSpawner:eventFields(), recruit:eventFields())
	end
end

function triggerFieldBenefits(recruitUuid)
	local recruit = recruitSpawner:getRecruit(recruitUuid)
	if not recruit then
		sb.logInfo("Cannot trigger field benefits for unknown recruit %s", recruitUuid)
		return
	end

	status.addEphemeralEffects(recruit:fieldBenefits())
end

function triggerCombatBenefits(recruitUuid)
	local recruit = recruitSpawner:getRecruit(recruitUuid)
	if not recruit then
		sb.logInfo("Cannot trigger combat benefits for unknown recruit %s", recruitUuid)
		return
	end

	status.addEphemeralEffects(recruit:combatBenefits())
end
