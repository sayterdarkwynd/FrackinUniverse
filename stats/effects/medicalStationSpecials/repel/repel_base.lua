
require "/stats/effects/medicalStationSpecials/medicalStatusBase.lua"

function init()
	local resist = config.getParameter("resist", 0)
	local otherResistsMult = config.getParameter("otherResistsMult", 0)
	local statusImmunities = config.getParameter("statusImmunities", 0)
	local elements = { "physical", "fire", "poison", "ice", "electric", "radioactive", "cosmic", "shadow" }
	local modifierTable = {}
	
	for _, element in ipairs(elements) do
		if element == resist then
			table.insert(modifierTable, {stat = element.."Resistance", amount = config.getParameter("bonusResistFlat", 0)})
		else
			table.insert(modifierTable, {stat = element.."Resistance", effectiveMultiplier = otherResistsMult})
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
	baseUpdate(dt)
end

function uninit()
	baseUninit(self.modifierGroupID)
end