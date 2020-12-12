local orginalUpdate = update
local Pet = Pet or {}

function update(dt)
	orginalUpdate(dt)
	local limit = config.getParameter("activePodLimit") + status.stat("pandoraBoxExtraPets")
	local overflow = math.max(util.tableSize(storage.activePods) - limit, 0)
	for uuid,_ in pairs(storage.activePods) do
		if overflow <= 0 then
			break
		end
		deactivatePod(uuid)
		overflow = overflow - 1
	end
end

function activatePod(podUuid)
	local limit = config.getParameter("activePodLimit") + status.stat("pandoraBoxExtraPets")
	if limit < 1 then return end
	local pod = petSpawner.pods[podUuid]
	if not pod then
		sb.logInfo("Cannot activate invalid pod %s", podUuid)
		return
	end

	-- If we have too many pets out, call some back
	local overflow = math.max(util.tableSize(storage.activePods) + 1 - limit, 0)
	for uuid,_ in pairs(storage.activePods) do
		if overflow <= 0 then
			break
		end
		deactivatePod(uuid)
		overflow = overflow - 1
	end

	storage.activePods[podUuid] = true
	petSpawner:markDirty()
end

function Pet:store()
	if self.uniqueId then
		promises:add(world.sendEntityMessage(self.uniqueId, "pandorasboxGetHarvestTimeLeft"), function(harvestTimeLeft)
			if harvestTimeLeft then
				self.spawnConfig.parameters.pandorasboxHarvestTimeLeft = harvestTimeLeft
			end
		end)
		promises:add(world.sendEntityMessage(self.uniqueId, "fuGetShipPetData"), function(shipPetData)
			if shipPetData then
				self.spawnConfig.parameters = util.mergeTable(self.spawnConfig.parameters, shipPetData)
			end
		end)
	end
	local result = self:toJson()
	if not self.persistent then
		result.uniqueId = nil
	end
	return result
end