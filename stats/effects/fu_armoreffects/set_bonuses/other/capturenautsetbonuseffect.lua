require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_capturenautset"

armorBonus={{stat = "pandoraBoxExtraPets", amount = 1}}

function init()
	setSEBonusInit(setName)
	--effectHandlerList.armorBonusHandle=effect.addStatModifierGroup({})
	statusEffectName=config.getParameter("statusEffectName")
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else
		if not self.timer or self.timer >= 1 then
			status.setPersistentEffects(setName.."_special",setBonusMultiply(armorBonus,1+((checkSetLevel(self.setBonusCheck)-5)/2)+((status.statPositive("fu_capturenautset_back") and 1) or 0)))
			setPetBuffs({"fubeastmaster30"})
			self.timer = 0
		else
			self.timer = self.timer + dt
		end
		if not self.timer2 or self.timer2 >= 0.25 then
			world.sendEntityMessage(entity.id(),"recordFUPersistentEffect",setName.."_special")
			self.timer2 = 0
		else
			self.timer2 = self.timer2 + dt
		end
	end
end