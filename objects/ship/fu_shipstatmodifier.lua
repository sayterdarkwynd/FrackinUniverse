local reload = true

function init()
	if world.type() ~= "unknown" then
		object.smash(false)
		reload = false
		return
	end
	if not storage.notNew then
		applyStats(1)
		maxAmountCheck()
		storage.notNew = true
	end
end

function die()
	if reload then
		applyStats(-1)
		maxAmountCheck()
	end
end

function applyStats(multiplier)
	capabilities = config.getParameter("capabilities")
	stats = config.getParameter("stats")
	if capabilities then
		for _, capability in pairs (capabilities) do
			statChange(capability, 1, multiplier)
		end
	end
	if stats then
		for objectStat, statAmount in pairs (stats) do
			statChange(objectStat, statAmount, multiplier)
		end
	end
end

function statChange(stat, amount, multiplier)
	baseAmount = world.getProperty("fu_byos." .. stat) or 0
	world.setProperty("fu_byos." .. stat, baseAmount + (amount * multiplier))
end

function maxAmountCheck()
	maxAmount = config.getParameter("maxAmount")
	if maxAmount then
		maxAmountProperty = "fu_byos.object." .. object.name()
		objectAmount = world.getProperty(maxAmountProperty) or 0
		if not storage.notNew then
			if objectAmount and objectAmount >= maxAmount then
				object.smash(false)
				reload = false
				return
			else
				world.setProperty(maxAmountProperty, objectAmount + 1)
			end
		else
			world.setProperty(maxAmountProperty, objectAmount - 1)
		end
	end
end