require "/scripts/vec2.lua" -- added for npc aim fix attempt

function randomizeStatusText(args, board)
	local personality = personalityType()
	local options = nil
	if math.random() < 0.3 then
		storage.statusText = randomStatusText(personality)
	else
		storage.statusText = nil
	end
	if storage.statusText and type(storage.statusText)~="string" then
		sb.logError("npc.lua:randomizeStatusText: NPC Type %s of species %s encountered improperly formatted status text in personality %s with value %s, clearing.",npc.npcType(),npc.species(),personality,storage.statusText)
		storage.statusText=nil
	end
	npc.setStatusText(storage.statusText)
	npc.setDisplayNametag(true)
	return true
end

-- param entity
function setLounging(args, board)
	if args.entity == nil then return false end
	npc.setLounging(args.entity)
	return true
end

-- param entity
function lounge(args, board)
	if args.entity == nil then return false end
	if not npc.isLounging() or npc.loungingIn() ~= args.entity then
		npc.setLounging(args.entity)
	end
	self.lounge = true
	return true
end

function resetLounging(args, board)
	if not npc.isLounging() then return false end
	npc.resetLounging()
	return true
end

-- param slot
-- param itemName
-- param definition
-- param level
function setItemSlot(args, board)
	local params = {
		definition = args.definition,
		level = args.level or npc.level()
	}

	local item
	if args.itemName then
		item = {name = args.itemName, parameters = params}
	end

	setNpcItemSlot(args.slot, item)
	return true
end

-- param itemTable
-- param vanitySlot
function equipArmor(args, output)
	local itemName
	if type(args.itemTable) == "table" then
		itemName = args.itemTable.name
	else
		itemName = args.itemTable
	end

	local itemType = root.itemType(itemName)
	local slot
	if itemType == "headarmor" then
		slot = "head"
	elseif itemType == "chestarmor" then
		slot = "chest"
	elseif itemType == "legsarmor" then
		slot = "legs"
	elseif itemType == "backarmor" then
		slot = "back"
	else
		return false
	end

	if args.vanitySlot then
		slot = slot .. "Cosmetic"
	end

	npc.setItemSlot(slot, args.itemTable)
	storage.itemSlots = storage.itemSlots or {}
	storage.itemSlots[string.lower(slot)] = args.itemTable
	return true
end

-- param slot
function unequipSlot(args, output)
	npc.setItemSlot(args.slot, nil)
	storage.itemSlots = storage.itemSlots or {}
	storage.itemSlots[string.lower(args.slot)] = args.itemTable
	return true
end

-- param position
-- param offset
function setAimPosition(args, board)
	if args.position == nil or args.offset == nil then return false end
	
	local position = vec2.add(args.position, args.offset)
	npc.setAimPosition(position)
	-- new
	local xpos = mcontroller.xPosition()
	local ypos = mcontroller.yPosition()
	local ypos = ypos * 0.5
	local mouthPosition = vec2.add(mcontroller.position(), {1,-0.7})

	local toPosition = world.distance(position, mcontroller.position()) -- {xpos,ypos} was previously mcontroller.position()
	mcontroller.controlFace(util.toDirection(toPosition[1]))

	self.setFacingDirection = true
	return true
end

function altFire(args, board)
	self.altFire = true
	return true
end

function primaryFire(args, board)
	self.primaryFire = true
	return true
end

function endPrimaryFire(args, board)
	self.primaryFire = false
	npc.endPrimaryFire()
	return true
end

function setDropPools(args, board)
	npc.setDropPools(args.dropPools)
	return true
end

-- param deathParticleBurst
function setDeathParticleBurst(args, board)
	npc.setDeathParticleBurst(args.deathParticleBurst)
	return true
end

-- param emote
function emote(args, board)
	if args.emote == nil then return false end
	npc.emote(args.emote)
	return true
end

-- param dance
function dance(args, board)
	npc.dance(args.dance)
	return true
end

function setPersistent(args, board)
	npc.setPersistent(args.persistent)
	return true
end

-----------------------------------------------------------
-- COMBAT
-----------------------------------------------------------

function swapItemSlots(args, board)
	npc.setItemSlot("primary", self.sheathedPrimary)
	local primary = self.primary
	self.primary = self.sheathedPrimary
	self.sheathedPrimary = primary

	npc.setItemSlot("alt", self.sheathedAlt)
	local alt = self.alt
	self.alt = self.sheathedAlt
	self.sheathedAlt = alt
	return true
end

function hasMeleePrimary(args, board)
	if self.primary == nil then return false end
	return root.itemHasTag(self.primary.name, "melee")
end

function hasRangedPrimary(args, board)
	if self.primary == nil then return false end
	return root.itemHasTag(self.primary.name, "ranged")
end

function hasStaffPrimary(args, board)
	if self.primary == nil then return false end
	return root.itemHasTag(self.primary.name, "staff") or root.itemHasTag(self.primary.name, "wand")
end

function hasShield(args, board)
	if self.alt == nil then return false end
	return root.itemHasTag(self.alt.name, "shield")
end

function hasMeleeSheathed(args, board)
	if self.sheathedPrimary == nil then return false end
	return root.itemHasTag(self.sheathedPrimary.name, "melee")
end

function hasRangedSheathed(args, board)
	if self.sheathedPrimary == nil then return false end
	return root.itemHasTag(self.sheathedPrimary.name, "ranged")
end

function hasStaffSheathed(args, board)
	if self.sheathedPrimary == nil then return false end
	return root.itemHasTag(self.primary.name, "staff") or root.itemHasTag(self.primary.name, "wand")
end

function hasShieldSheathed(args, board)
	if self.sheathedAlt== nil then return false end
	return root.itemHasTag(self.sheathedAlt.name, "shield")
end

function canFire(args, board)
	return status.resourcePercentage("energy") > 0 and not status.resourceLocked("energy")
end

function getWeaponTiming(weapon)
	local meleeWeaponWindups = config.getParameter("combat.meleeWeaponWindups", {})
	local meleeWeaponCooldowns = config.getParameter("combat.meleeWeaponCooldowns", {})

	local windup = meleeWeaponWindups.default or 0.5
	local cooldown = meleeWeaponCooldowns.default or 1.0

	if weapon then
		for _,tag in pairs(root.itemTags(weapon.name)) do
			windup = meleeWeaponWindups[tag] or windup
			cooldown = meleeWeaponCooldowns[tag] or cooldown
		end
	end

	return {
			windup = windup,
			cooldown = cooldown
		}
end

-- output windup
-- output cooldown
function primaryWeaponTiming(args, output)
	local timing = getWeaponTiming(self.primary)
	return true, {windup = timing.windup, cooldown = timing.cooldown}
end

-- param tag
function primaryWeaponTag(args, board)
	if self.primary and root.itemHasTag(self.primary.name, args.tag) then
		return true
	else
		return false
	end
end

-- output damageTeam
function damageTeam(args, board)
	local team = entity.damageTeam()
	return true, {damageTeam = team.team}
end

-- param queryRange
-- param trackingRange
-- param losTime
-- param broadcastInterval
-- param attackOnSight
-- param hostileDamageTeam
function friendlyTargeting(args, board, nodeId, dt)
	local targets = {}
	local outOfSight = {}
	local attackOnSight = args.attackOnSight or {}

	local targetQuery = function()
		local cooldown = board:getNumber("queryCooldown-"..nodeId) or 0
		if world.time() - cooldown > 1.0 then
			local queried = world.entityQuery(entity.position(), args.queryRange, {includedTypes = {"monster", "npc", "player"}, order = "nearest", withoutEntityId = entity.id()})
			queried = util.filter(queried, entity.entityInSight)
			board:setNumber("queryCooldown-"..nodeId, world.time())
			return queried
		end
	end

	local filterActive = function(entityId)
		if not world.entityExists(entityId) then
			return false
		end

		if world.magnitude(entity.position(), world.entityPosition(entityId)) > args.trackingRange then
			return false
		end

		if not entity.entityInSight(entityId) then
			outOfSight[entityId] = args.losTime
			return false
		end

		return true
	end

	local filterNew = function(entityId)
		if world.magnitude(entity.position(), world.entityPosition(entityId)) > args.trackingRange
			 or not entity.entityInSight(entityId)
			 or contains(targets, entityId) then
			return false
		end

		if not entity.isValidTarget(entityId) then
			return false
		end

		if world.isNpc(entityId) then
			if entity.damageTeam().type ~= "pvp" and entity.damageTeam().team == 1 then
				-- villagers are on damage team 1 and should not attack other villagers even if their team types are different
				return not world.isNpc(entityId, entity.damageTeam().team)
			else
				return true
			end
		end

		if entity.damageTeam().type ~= "pvp" and world.entityType(entityId) == "player" and contains(attackOnSight, entityId) then
			npc.setDamageTeam(args.hostileDamageTeam)
			table.insert(attackOnSight, entityId)
		end

		return true
	end

	local broadcastTarget = function(targetId)
		local notification = {
			sourceId = entity.id(),
			targetId = targetId,
			type = "attack"
		}
		world.entityQuery(entity.position(), args.trackingRange, { includedTypes = {"npc"}, callScript = "notify", callScriptArgs = {notification} })
	end
	local periodicBroadcast = util.interval(args.broadcastInterval, function()
		if targets[1] then
			broadcastTarget(targets[1])
		end
	end)

	while true do
		local losCount = 0
		for entityId,timer in pairs(outOfSight) do
			if entity.entityInSight(entityId) then
				table.insert(targets, entityId)
				outOfSight[entityId] = nil
			else
				timer = timer - dt
				if timer <= 0 then
					outOfSight[entityId] = nil
				else
					outOfSight[entityId] = timer
					losCount = losCount + 1
				end
			end
		end

		targets = util.filter(targets, filterActive)

		-- Get a list of potential targets from querying, notifications, and taking damage
		local newTargets = targetQuery() or {}

		local notifications = util.filter(self.notifications, function(n)
			return n.type == "attack" or n.type == "attackThief"
		end)
		for _,notification in pairs(notifications) do
			if world.isNpc(notification.sourceId, entity.damageTeam().team) and notification.targetId then
				if entity.damageTeam().type ~= "pvp" and world.entityType(notification.targetId) == "player" then
					npc.setDamageTeam(args.hostileDamageTeam)
				end
				table.insert(newTargets, notification.targetId)
			end
		end

		if self.wasDamaged then
			local damageSource = board:getEntity("damageSource")
			if entity.damageTeam().type ~= "pvp" and world.isNpc(damageSource, entity.damageTeam().team) then
				npc.setDamageTeam(args.hostileDamageTeam)
			else
				table.insert(newTargets)
			end
		end

		-- Filter out invalid targets, adds out of sight targets to outOfSight
		newTargets = util.filter(newTargets, filterNew)
		if #targets == 0 and #newTargets > 0 then
			broadcastTarget(newTargets[1])
		end
		util.appendLists(targets, newTargets)

		periodicBroadcast(dt)

		if #targets == 0 and losCount == 0 then return false end
		dt = coroutine.yield(nil, {target = targets[1] or outOfSight[1], attackOnSight = attackOnSight})
		attackOnSight = args.attackOnSight or {}
	end
end

function level(args, board)
	return true, {level = npc.level()}
end
