require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_darkdisguisesetkhe"

shellBonus={
	{stat = "physicalResistance", amount = 0.25},
	{stat = "grit", amount = 0.25},
	{stat = "fallDamageMultiplier", effectiveMultiplier = 0.75},
	{stat = "shadowImmunity", amount = 1},
	{stat = "poisonStatusImmunity", amount = 1},

	{stat = "snowslowImmunity", amount = 1},
	{stat = "slushslowImmunity", amount = 1},
	{stat = "clayslowImmunity", amount = 1},
	{stat = "blacktarImmunity", amount = 1},
	{stat = "fumudslowImmunity", amount = 1},
	{stat = "jungleslowImmunity", amount = 1},
	{stat = "quicksandImmunity", amount = 1},
	{stat = "honeyslowImmunity", amount = 1},
	{stat = "iceslipImmunity", amount = 1},
	{stat = "slimeImmunity", amount = 1},
	{stat = "slimestickImmunity", amount = 1}
}

function init()
	setSEBonusInit(setName)
	effectHandlerList.shellBonusHandle=effect.addStatModifierGroup({})

	checkShell()
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		status.removeEphemeralEffect("regeneratingshield_energy-2_2-ereg_eblock-10")
		status.removeEphemeralEffect("regeneratingshieldindicatorwraith")
		effect.expire()
	else
		checkShell()
		status.addEphemeralEffect("regeneratingshield_energy-2_2-ereg_eblock-10")
		status.addEphemeralEffect("regeneratingshieldindicatorwraith")
	end
end

function checkShell()
	local rsp=status.stat("regeneratingshieldpercent")
	if rsp > 0.05 then
		effect.setStatModifierGroup(effectHandlerList.shellBonusHandle,shellBonus)
		effect.setParentDirectives(string.format("?multiply=ffffff%02x", math.floor(255-(rsp*200))))
	else
		effect.setStatModifierGroup(effectHandlerList.shellBonusHandle,{})
		effect.setParentDirectives()
	end
end
