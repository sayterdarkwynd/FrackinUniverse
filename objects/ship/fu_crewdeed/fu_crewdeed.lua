require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/objects/spawner/colonydeed.lua"
require "/objects/spawner/colonydeed/scanning.lua"
require "/objects/ship/fu_shipstatmodifier.lua"

statModifierInit = init or function() end

function init()
	storage.notNew = true										--To stop it from applying the stats in init()
	statModifierInit()
	validCheck(true)
	self = config.getParameter("deed")
	self.position = entity.position()
	storage.house = storage.house or {}
	storage.occupier = storage.occupier or {tagCriteria = self.tagCriteria or {}}
	storage.house.boundary = storage.house.boundary or {{0,0}}
	timer = self.scanDelay
	object.setInteractive(self.interactive)

	local questParticipantOutbox = Outbox.new("questParticipantOutbox", ContactList.new("questParticipantContacts"))
	self.questParticipant = QuestParticipant.new("questParticipant", questParticipantOutbox)

	if not object.uniqueId() then
		object.setUniqueId(sb.makeUuid())
	end

	self.notOwnShipMessage = self.notOwnShipMessage or "Only the owner of the ship can manage crew rooms"
end

function update(dt)
	if storage.reload then
		if timer >= self.scanDelay then
			checkHouseIntegrity()
			timer = 0
		else
			timer = timer + dt
		end
	else
		animator.setAnimationState("deedState", "grumbling")
	end
end

function die()
	if storage.reload then
		if storage.statApplied then
			applyStats(-1)
			storage.statApplied = false
		end
		validCheck(false)
	end
end

function onInteraction(args)
	checkHouseIntegrity()
	grumbleText = displayGrumbles()
	timer = 0
	if #storage.grumbles > 0 then
		return {"ShowPopup", {message = grumbleText}}
	else
		world.sendEntityMessage(args.sourceId, "openCrewDeedInterface", {objectId = entity.id(), notOwnShipMessage = self.notOwnShipMessage})
	end
end

function checkHouseIntegrity()
	if storage.reload then
		storage.grumbles = scanHouseIntegrity()
	elseif world.type() ~= "unknown" then
		storage.grumbles = {{"notShip"}}
	else
		storage.grumbles = {{"notByos"}}
	end

	if fuDeedCheck() then
		storage.grumbles[#storage.grumbles+1] = {"otherDeed"}
	end

	--sb.logInfo(sb.printJson(storage.grumbles))

	if #storage.grumbles > 0 then
		animator.setAnimationState("deedState", "grumbling")
		if storage.statApplied then
			applyStats(-1)
			storage.statApplied = false
		end
	else
		animator.setAnimationState("deedState", "occupied")
		if not storage.statApplied then
			applyStats(1)
			storage.statApplied = true
		end
	end
end

function isShipWorld()
	return world.getProperty("ship.level") ~= 0			--Assumes that it only functions on ships
end

function displayGrumbles()
	grumbleDisplay = "Issues:"
	for _, grumble in pairs (storage.grumbles) do
		grumbleDisplayText = self.grumbleText[grumble[1]]
		grumbleDisplay = grumbleDisplay .. "\n" .. grumbleDisplayText:gsub("<tagAmount>", tostring(grumble[3])):gsub("<tagName>", tostring(grumble[2]))	--Improve in the future
	end
	return grumbleDisplay
end