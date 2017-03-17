require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
require "/scripts/unifiedGravMod.lua"


function init()
	self.gravityMod = config.getParameter("gravityMod",0.0)
	self.gravityNormalize = config.getParameter("gravityNorm",false)
	self.gravityBaseMod = config.getParameter("gravityBaseMod",0.0)
	--sb.logInfo(sb.printJson({self.gravityMod,self.gravityNormalize,self.gravityBaseMod}))
	unifiedGravMod.init()
	setSEBonusInit("fu_spacefarerset")
	animator.setParticleEmitterOffsetRegion("sparkles", mcontroller.boundBox())
	animator.setParticleEmitterActive("sparkles", true)
	effect.setParentDirectives("fade=F1EA9C;0.00?border=0;F1EA9C00;00000000")
	effect.addStatModifierGroup({
		{stat = "fireStatusImmunity", amount = 1},
		{stat = "maxBreath", baseMultiplier = 50.0 },
		{stat = "breathRegenerationRate", baseMultiplier = 2.0 },
		{stat = "slushslowImmunity", amount = 1},
		{stat = "protoImmunity", amount = 1},
		{stat = "liquidnitrogenImmunity", amount = 1},
		{stat = "nitrogenfreezeImmunity", amount = 1},
		{stat = "iceslipImmunity", amount = 1},
		{stat = "extremepressureProtection", amount = 1},
		{stat = "asteroidImmunity", amount = 1},
		{stat = "physicalResistance", amount = 0.25},
		{stat = "gravrainImmunity", amount = 1}
  })
  --sb.logInfo("%s",self)
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else
		unifiedGravMod.update(dt)
	end
end
