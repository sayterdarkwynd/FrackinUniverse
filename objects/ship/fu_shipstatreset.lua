function init()
	storage.reload = storage.reload or true
	if world.type() ~= "unknown" then
		storage.reload = false
		return
	end
	if not storage.appliedStats then
		storage.appliedStats = {capabilities = config.getParameter("capabilities"), stats = config.getParameter("stats"), maxAmount = config.getParameter("maxAmount"), maxAmountGroups = config.getParameter("maxAmountGroups")}
		if not storage.notNew then
			if not validCheck(true) then
				applyStats(1)
			end
		end
	end
end

function die()
	if storage.reload then
		applyStats(-1)
		validCheck(false)
	end
end

function applyStats(multiplier)
	if storage.appliedStats.capabilities then
		for _, capability in pairs (storage.appliedStats.capabilities) do
			statChange(capability)
		end
	end
	if storage.appliedStats.stats then
		for objectStat in pairs (storage.appliedStats.stats) do
			statChange(objectStat)
		end
	end
end

function statChange(stat)
	world.setProperty("fu_byos." .. stat,0)
end

function validCheck(new)
	if config.getParameter("byosOnly") and world.getProperty("ship.level") ~= 0 then
		storage.reload = false
		return true
	end
	if storage.appliedStats.maxAmount then
		local maxAmountProperty = "fu_byos.object." .. object.name()
		world.setProperty(maxAmountProperty, 0)
	end
	if storage.appliedStats.maxAmountGroups then
		for groupName in pairs (storage.appliedStats.maxAmountGroups) do
			local maxAmountProperty = "fu_byos.group." .. groupName
			world.setProperty(maxAmountProperty, 0)
		end
	end
end
