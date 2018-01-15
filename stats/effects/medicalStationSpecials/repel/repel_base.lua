
require "/stats/effects/medicalStationSpecials/medicalStatusBase.lua"

function init()
	local statusImmunities = config.getParameter("statusImmunities", 0)
	local modifierTable = {}

	self.elements = { "fire", "poison", "ice", "electric", "radioactive", "cosmic", "shadow" }
	self.resist = config.getParameter("resist", 0)
	self.otherResistsMult = config.getParameter("otherResistsMult", 0)
	self.resistsTableID = nil
	self.recalcInterval = 1
	self.recalcCooldown = 0
	
	for _, element in ipairs(self.elements) do
		if element == self.resist then
			table.insert(modifierTable, {stat = element.."Resistance", amount = config.getParameter("bonusResistFlat", 0)})
		end
	end
	
	if statusImmunities and type(statusImmunities) == "table" then
		for _, immunity in ipairs(statusImmunities) do
			table.insert(modifierTable, {stat = immunity, amount = 1})
		end
	end
	
	self.modifierGroupID = effect.addStatModifierGroup(modifierTable)
	baseInit()
end

function update(dt)
	if self.recalcCooldown <= 0 then
		if self.resistsTableID then
			effect.removeStatModifierGroup(self.resistsTableID)
		end
		
		local resistsTable = {}
		for _, element in ipairs(self.elements) do
			if element ~= self.resist and status.statPositive(element.."Resistance") then
				table.insert(resistsTable, {stat = element.."Resistance", effectiveMultiplier = self.otherResistsMult})
			end
		end
		
		if #resistsTable > 0 then
			self.resistsTableID = effect.addStatModifierGroup(resistsTable)
		end
		self.recalcCooldown = self.recalcInterval
	else
		self.recalcCooldown = self.recalcCooldown - dt
	end
	
	baseUpdate(dt)
end

function uninit()
	if self.resistsTableID then
		effect.removeStatModifierGroup(self.resistsTableID)
	end
	
	baseUninit(self.modifierGroupID)
end