-- what range of dungeonIds are we reserving for shield generators?
LOWID = 30877
HIGHID = 45877

function init(args)
	object.setInteractive(true)

	-- messaging
	message.setHandler("setActiveAnimation", openedUI)
	message.setHandler("setInactiveAnimation", closedUI)
	message.setHandler("purge", purge)
end

-- UI was opened
function openedUI()
	animator.setAnimationState("switchState", "on")
	countFields()
end

-- UI was closed
function closedUI()
	animator.setAnimationState("switchState", "off")
end

-- count claimed fields
function countFields()
	local firstId, lastId = LOWID, HIGHID
	local count = 0
	for i = firstId, lastId do
		if (world.getProperty(tostring(i))) then
			count = count + 1
		end
	end
	setStatus("Found " .. tostring(count) .. " fields on this world", "green")
end

-- purge all fields from world
function purge()
	local firstId, lastId = LOWID, HIGHID
	local purged = 0
	for i = firstId, lastId do
		local record = world.getProperty(tostring(i))
		if (record) then
			removeField(i, record)
			purged = purged + 1
		end
	end
	setStatus("Purged " .. tostring(purged) .. " fields on this world", "red")
end

-- remove the field effects and reset the area's dungeonId
function removeField(id, record)
	if (type(record) == "table") then
		if (record.rect) then
			world.setDungeonGravity(id)
			world.setDungeonBreathable(id)
			world.setTileProtection(id, false)
			world.loadRegion(record.rect)
			world.setDungeonId(record.rect, 65531)
		end
		local entityId = world.objectAt(record.position)
		if (entityId) then
			if (world.breakObject(entityId, false)) then
				return
			end
		end
	end
	world.setProperty(tostring(id), nil)
end

function setStatus(message, colour)
	if (colour) then
		message = "^" .. colour .. ";" .. message
	end
	object.setConfigParameter("pilch_shieldgenerator_status", message)
end
