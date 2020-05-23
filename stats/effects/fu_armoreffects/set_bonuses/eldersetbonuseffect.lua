require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

setName="fu_elderset"


weaponBonus={
	{stat = "powerMultiplier", effectiveMultiplier = 1.25}
}

armorBonus={
	{stat = "shadowImmunity", amount = 1},
	{stat = "liquidnitrogenImmunity", amount = 1},
	{stat = "insanityImmunity", amount = 1},
	{stat = "pusImmunity", amount = 1},
	{stat = "sulphuricImmunity", amount = 1}
}

function init()
	setSEBonusInit(setName)
	effectHandlerList.armorBonusHandle=effect.addStatModifierGroup(armorBonus)
	effectHandlerList.weaponBonusHandle=effect.addStatModifierGroup({})
	checkWeapons()
	--sb.logInfo("%s",status.getPersistentEffects("armor"))
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		status.removeEphemeralEffect("darkregen")
		effect.expire()
	else
		if not self.timer or self.timer >= 1 then
			for _,id in pairs(world.monsterQuery(entity.position(),50)) do
				--sb.logInfo("Elder Set Bonus update for loop. id: %s. Comparator Pre-negation (isValidTarget): %s.",id,entity.isValidTarget(id))
				if not entity.isValidTarget(id) then
					--sb.logInfo("for loop comparator passed: %s.",id)
					world.sendEntityMessage(id, "applyStatusEffect", "fudarkcommander30", (self.timer or 1.0)*2, entity.id())
				end
			end
			self.timer = 0
		else
			self.timer = self.timer + dt
		end
		status.addEphemeralEffect("darkregen")
		checkWeapons()
	end
end

function checkWeapons()
	local weapons=weaponCheck({"elder"})
	
	if weapons["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end