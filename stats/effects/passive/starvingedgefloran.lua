function init()
	script.setUpdateDelta(5)
	starvationpower2=effect.addStatModifierGroup({})
	starvationpower=effect.addStatModifierGroup({})
end

function update(dt)

	if status.isResource("food") then
		self.foodValue = status.resource("food")
	else
		self.foodValue = 50
	end

	--[[local foodMax = 100
	local foodMin = 35
	local foodRange = foodMax - foodMin    --100-35=65
	]]
	--local ratio = math.max(0, (self.foodValue - 35) / 65)

	--[[
	local energyMax = 1.3
	local energyMin = 1
	local energyRange = energyMax - energyMin--1.3-1=0.3
	local finalEnergy = math.floor((energyMin + energyRange * ratio) * 100) / 100
	]]
	if self.foodValue>=35 then
		local finalEnergy = math.floor((1+(0.3 * (self.foodValue - 35) / 65)) * 100) / 100
		effect.setStatModifierGroup(starvationpower2, {{stat = "maxEnergy", baseMultiplier = finalEnergy}})
	else
		effect.setStatModifierGroup(starvationpower2, {})
	end

	if self.foodValue < 5 then
		effect.setStatModifierGroup(starvationpower, {{stat = "powerMultiplier", baseMultiplier = 1.24}})
	elseif self.foodValue < 10 then
		effect.setStatModifierGroup(starvationpower, {{stat = "powerMultiplier", baseMultiplier = 1.20}})
	elseif self.foodValue < 20 then
		effect.setStatModifierGroup(starvationpower, {{stat = "powerMultiplier", baseMultiplier = 1.15}})
	elseif self.foodValue < 30 then
		effect.setStatModifierGroup(starvationpower, {{stat = "powerMultiplier", baseMultiplier = 1.09}})
	elseif self.foodValue < 40 then
		effect.setStatModifierGroup(starvationpower, {{stat = "powerMultiplier", baseMultiplier = 1.07}})
	elseif self.foodValue < 50 then
		effect.setStatModifierGroup(starvationpower, {{stat = "powerMultiplier", baseMultiplier = 1.05}})
	elseif self.foodValue < 60 then
		effect.setStatModifierGroup(starvationpower, {{stat = "powerMultiplier", baseMultiplier = 1.03}})
	else
		effect.setStatModifierGroup(starvationpower,{})
	end


end

function uninit()
	effect.removeStatModifierGroup(starvationpower)
	effect.removeStatModifierGroup(starvationpower2)
end











