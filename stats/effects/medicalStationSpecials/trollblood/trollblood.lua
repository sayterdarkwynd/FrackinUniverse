
require "/stats/effects/medicalStationSpecials/medicalStatusBase.lua"

function init()
	self.oldHealth = status.resource("health")
	self.regenPcnt = config.getParameter("regenPcnt", 0) * 0.01
	self.regenInstances = config.getParameter("regenDuration", 0) / config.getParameter("regenInterval", 0)
	self.damageInstances = {}
	self.regenInterval = 0
	
	self.modifierGroupID = effect.addStatModifierGroup({
		{stat = "maxHealth", amount = config.getParameter("healthReductionPcnt", 0)},
		{stat = "energyRegenBlockTime", amount = config.getParameter("energyBlockIncrease", 0)}
	})
	
	baseInit()
end

function update(dt)
	local health = status.resource("health")
	if health < self.oldHealth then
		table.insert(self.damageInstances, {damage = self.oldHealth - health, instances = self.regenInstances})
	end
	
	if self.regenInterval <= 0 then
		local totalRegen = 0
		local finishedIndexes = {}
		
		for i, tbl in ipairs(self.damageInstances) do
			totalRegen = totalRegen + tbl.damage / self.regenInstances
			
			if tbl.instances > 1 then
				tbl.instances = tbl.instances - 1
			else
				table.insert(finishedIndexes, i)
			end
		end
		
		for i, index in ipairs(finishedIndexes) do
			table.remove(self.damageInstances, #finishedIndexes - i + 1)
		end
		
		status.modifyResource("health", totalRegen * self.regenPcnt)
		self.regenInterval = config.getParameter("regenInterval", 0)
	else
		self.regenInterval = self.regenInterval - dt
	end
	
	self.oldHealth = status.resource("health")
	baseUpdate(dt)
end

function uninit()
	baseUninit(self.modifierGroupID)
end