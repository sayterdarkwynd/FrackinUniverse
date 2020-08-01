require "/stats/effects/fu_armoreffects/setbonuses_common.lua"


armorBonus={
	{stat="powerMultiplier",effectiveMultiplier=1.7},
	{stat="maxHealth",effectiveMultiplier=1.3},
	{stat="maxEnergy",effectiveMultiplier=1.4},
	{stat="protection",effectiveMultiplier=2.0}
}

setName="fu_streakerset"

function init()
	setSEBonusInit(setName)
	
	effectHandlerList.specialBonusHandle=effect.addStatModifierGroup({})
	effectHandlerList.armorBonusHandle=effect.addStatModifierGroup(armorBonus)
	local elementalTypes=root.assetJson("/damage/elementaltypes.config")
	local statBuffer={}
	self.resistanceList={}
	
	for element,data in pairs(elementalTypes) do
		if data.resistanceStat then
			self.resistanceList[data.resistanceStat]=true
		end
	end
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else
		mcontroller.controlModifiers({speedModifier = 1.20,airJumpModifier = 1.20})
		self.timer=(self.timer or 0) + dt
		if self.timer > 1.0 then
			effect.setStatModifierGroup(effectHandlerList.specialBonusHandle,loadElemental())
			self.timer=0.0
		end
	end
end

function loadElemental()
	if not self.resistanceList then return {} end
	local buffer={}
	local threatLevel=(world.threatLevel())*0.04
	for stat,_ in pairs(self.resistanceList) do
		table.insert(buffer,{stat=stat,amount=threatLevel})
	end
	
	return buffer
end