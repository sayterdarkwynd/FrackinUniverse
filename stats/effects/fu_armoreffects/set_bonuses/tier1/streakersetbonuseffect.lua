require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_streakerset"

armorBonus={
	{stat="powerMultiplier",effectiveMultiplier=1.7},
	{stat="maxHealth",effectiveMultiplier=1.3},
	{stat="maxEnergy",effectiveMultiplier=1.4},
	{stat="protection",effectiveMultiplier=2.0}
}

function init()
	setSEBonusInit(setName)

	effectHandlerList.specialBonusHandle=effect.addStatModifierGroup({})
	effectHandlerList.armorBonusHandle=effect.addStatModifierGroup(armorBonus)
	effectHandlerList.capeBonusHandle=effect.addStatModifierGroup({})
	local elementalTypes=root.assetJson("/damage/elementaltypes.config")
	self.resistanceList={}

	for _,data in pairs(elementalTypes) do
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
			effect.setStatModifierGroup(effectHandlerList.specialBonusHandle,loadElemental(status.stat(setName.."_back")))
			self.timer=0.0
		end
	end
end

function loadElemental(capeLevel)
	if not self.resistanceList then return {} end
	local buffer={}
	local threatLevel=(world.threatLevel())*0.08

	if capeLevel>0 then
		table.insert(buffer,{stat="mentalProtection",effectiveMultiplier=1.0-capeLevel})

		table.insert(buffer,{stat="breathRegenerationRate",effectiveMultiplier=1+(capeLevel)})
		table.insert(buffer,{stat="breathDepletionRate",effectiveMultiplier=1-(capeLevel)})

		for _,stat in pairs({"powerMultiplier","maxHealth","maxEnergy","protection"}) do
			table.insert(buffer,{stat=stat,effectiveMultiplier=1.0+(capeLevel*0.1)})
		end

		--sb.logInfo("a tl %s, cl %s",threatLevel,capeLevel)
		threatLevel=threatLevel*(1+(capeLevel*0.5))
		--sb.logInfo("b tl %s, cl %s",threatLevel,capeLevel)
	elseif lastCapeLevel and lastCapeLevel>0 then
		status.setResource("breath",0)
		table.insert(buffer,{stat="breathRegenerationRate",effectiveMultiplier=0})
	end

	for stat,_ in pairs(self.resistanceList) do
		table.insert(buffer,{stat=stat,amount=threatLevel})
		table.insert(buffer,{stat=stat,effectiveMultiplier=0.5})
	end

	lastCapeLevel=capeLevel
	return buffer
end
