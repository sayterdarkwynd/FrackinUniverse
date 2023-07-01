bugActiveStats = {
	{stat = "biomeheatImmunity", amount = 1},
	{stat = "breathProtection", amount = 1},
	{stat = "biomecoldImmunity", amount = 1},
	{stat = "biomeradiationImmunity", amount = 1},
	{stat = "poisonImmunity", amount = 1},
	{stat = "fireImmunity", amount = 1},
	{stat = "lavaImmunity", amount = 1},
	{stat = "biomeheatImmunity", amount = 1},
}

canReplant = {
	["flower"] = true,
}

function init(args)
	--sb.logInfo("I am harvester bug!")
	self.dead = false
	monster.setDamageOnTouch(false)
	monster.setAggressive(false)
	self.visible = false
	silenceTime = 0
	status.addPersistentEffects("bugActive", bugActiveStats)
	monster.setDamageBar("None")
	message.setHandler("keepAlive", function()
		keepAlive()
	end)
	message.setHandler("takeItems", function(_,_, pos, radius, owner, name)
		--sb.logInfo(tostring(pos).."|"..tostring(radius).."|"..tostring(owner).."|"..tostring(name))
		takeItems(pos, radius, owner, name)
	end)
	message.setHandler("callScript", function(_,_, id, fName)
		--sb.logInfo(tostring(pos).."|"..tostring(radius).."|"..tostring(owner).."|"..tostring(name))
		world.callScriptedEntity(id, fName)
	end)
end

function update(dt)
	if (silenceTime) and (silenceTime > 4) then
		kill()
	else
		silenceTime = silenceTime + dt
		monster.setDamageBar("None")
	end
	--[[if (takeCooldown and takeCooldown<=0) then
		takeCooldown=nil
	elseif takeCooldown
		takeCooldown=takeCooldown-dt
	end]]
end

function keepAlive()
	silenceTime = 0
end

function takeItems(pos, radius, playerID, plantName)
	--if takeCooldown then return end
	local itemList = world.getProperty("HarvesterBeamgunItemDropList") or {}
	local replantTree = false
	local foundItemDrops = world.itemDropQuery(pos, radius, {order = "nearest"})
	--sb.logInfo("foundItemDrops %s",foundItemDrops)
	for _,drop in ipairs(foundItemDrops) do
		local data = nil
		if world.entityName(drop) ~= "sapling" or not replantTree then
			data = world.takeItemDrop(drop, playerID)
		end
		if data and itemList[drop] == nil then
			local cd = vec2.mag(world.distance(world.entityPosition(drop), world.entityPosition(playerID)))/33
			if (not (world.objectAt(pos))) and (data.name == "sapling" and not plantName) then
				replantTree = data.parameters
				if data.count > 1 then
					data.count = data.count - 1
					itemList[drop] = {["data"] = data, ["cd"] = cd}
				end
			else
				itemList[drop] = {["data"] = data, ["cd"] = cd}
			end
		end
	end
	--sb.logInfo("Bug find: %s", itemList)
	local dirInt = 1
	if math.random() <= 0.5 then dirInt = -1 end
	if (not (world.objectAt(pos))) and replantTree then
		world.placeObject("sapling", pos, dirInt, replantTree)
	end

	if plantName then
		local seedConfig = root.itemConfig(plantName)
		if (not (world.objectAt(pos))) and (seedConfig and (seedConfig.hasObjectItem == nil or seedConfig.hasObjectItem == true)) then
			world.placeObject(plantName, pos, dirInt)
		end
	end

	world.setProperty("HarvesterBeamgunItemDropList", itemList)
	--[[if (type(itemList)=="table") and (util.tableSize(itemList)>0) then
		takeCooldown=1
	end]]
end

function kill()
	self.dead = true
end

function shouldDie()
	return self.dead
end

function damage(args)

end

function vec2.pureAngle(vector)
	local angle = math.atan2(vector[2], vector[1])
	if angle < 0 then angle = angle + 2 * math.pi end
	return angle
end
