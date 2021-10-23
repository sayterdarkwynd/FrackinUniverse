function init()
	modifiers=config.getParameter("modifiers",{})
end

--[[doc:
note that this file handles direct scaling modifiers. no static base values. so no 10+(food*x) or such.
modifiers table:
"statName":{"type":"statModifierType(baseMultiplier/effectiveMultiplier/amount)","value":baseValue,["inverse":false],["step":0.1]}
applies modifier to statName, using statModifierType, scaling the baseValue by foodPercent (or the default defined in checkFoodPercent).
inverse causes the value to grow as hunger does, rather than shrink. step clamps hunger to the value for the calculation.
]]

function setValues()
	local buffer={}
	local foodPercent=checkFoodPercent()
	for statName,data in pairs(modifiers) do
		local val=data.value
		local fVal=foodPercent
		if data.step then
			fVal=round(fVal/data.step)*data.step
		end
		fVal=((data.invert and (1-fVal)) or fVal)
		local isMult=(data.type=="effectiveMultiplier") or (data.type=="baseMultiplier")
		if isMult then val=val-1.0 end
		val=val*fVal
		if isMult then val=val+1.0 end
		local subBuffer={stat=statName}
		subBuffer[data.type]=val
		buffer[#buffer+1]=subBuffer
	end
	status.setPersistentEffects("radienPower",buffer)
end

function checkFoodPercent()
	return (((status.statusProperty("fuFoodTrackerHandler",0)>-1) and status.isResource("food")) and status.resourcePercentage("food")) or 0.5
end

function update(dt)
	self.armorTimer = (self.armorTimer or 0) + dt

	if self.armorTimer >= 50 then
		self.armorTotal = math.min(25,self.armorTotal + 1)
		status.setPersistentEffects("radienArmor", {{stat = "protection", amount = 1+ self.armorTotal }})
		self.armorTimer = 0
	end
	
	self.valueTimer=(self.valueTimer or 0)-dt
	if self.valueTimer<=0 then
		setValues()
		self.valueTimer=0.5
	end
end

function uninit()
	status.clearPersistentEffects("radienPower")
	status.clearPersistentEffects("radienArmor")
end

function round(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end