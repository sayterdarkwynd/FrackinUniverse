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
	statusEffectName=config.getParameter("statusEffectName")
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		status.removeEphemeralEffect("darkregen")

		effect.expire()
	else
		if not self.timer or self.timer >= 1 then
			setPetBuffs({"fudarkcommander30"})
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