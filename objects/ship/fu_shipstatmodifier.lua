local shipStatInit = init or function() end

function init()
	if not config.getParameter("isDeed") then		--Crew deed fix for the ship thruster fix
		shipStatInit()								--Ship thruster fix
	end

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
			statChange(capability, 1, multiplier)
		end
	end
	if storage.appliedStats.stats then
		for objectStat, statAmount in pairs (storage.appliedStats.stats) do
			statChange(objectStat, statAmount, multiplier)
		end
	end
end

function statChange(stat, amount, multiplier)
	local baseAmount = world.getProperty("fu_byos." .. stat) or 0
	world.setProperty("fu_byos." .. stat, baseAmount + (amount * multiplier))
end

function validCheck(new)
	if config.getParameter("byosOnly") and world.getProperty("ship.level") ~= 0 then
		storage.reload = false
		return true
	end
	if storage.appliedStats.maxAmount then
		local maxAmountProperty = "fu_byos.object." .. object.name()
		local objectAmount = world.getProperty(maxAmountProperty) or 0
		if new then
			if objectAmount and objectAmount >= storage.appliedStats.maxAmount then
				object.smash(false)
				storage.reload = false
				return true
			else
				world.setProperty(maxAmountProperty, objectAmount + 1)
			end
		else
			world.setProperty(maxAmountProperty, objectAmount - 1)
		end
	end
	if storage.appliedStats.maxAmountGroups then
		for groupName, groupMaxAmount in pairs (storage.appliedStats.maxAmountGroups) do
			local maxAmountProperty = "fu_byos.group." .. groupName
			local groupAmount = world.getProperty(maxAmountProperty) or 0
			if new then
				if groupAmount and groupAmount >= groupMaxAmount then
					object.smash(false)
					storage.reload = false
					return true
				else
					world.setProperty(maxAmountProperty, groupAmount + 1)
				end
			else
				world.setProperty(maxAmountProperty, groupAmount - 1)
			end
		end
	end
end