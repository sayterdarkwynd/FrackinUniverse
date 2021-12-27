function init()
	animator.setParticleEmitterOffsetRegion("snow", mcontroller.boundBox())
	animator.setParticleEmitterActive("snow", true)
	effect.setParentDirectives("fade=6f6f6f=0.55")
	
	local rAmt=config.getParameter("resistanceAmount", 0)
	local dAmt=config.getParameter("defenseAmount", 0)
	--[[if status.statPositive("specialStatusImmunity") then
		rAmt=rAmt*0.25
		dAmt=dAmt*0.25
	end]]
	if (world.entityType(entity.id()) == "player") or (world.entityType(entity.id()) == "npc") then
		effect.addStatModifierGroup({
			{stat = "protection", baseMultiplier = status.stat("protection") * dAmt},
			{stat = "physicalResistance", amount = rAmt},
			{stat = "fireResistance", amount = rAmt},
			{stat = "iceResistance", amount = rAmt},
			{stat = "poisonResistance", amount = rAmt},
			{stat = "electricResistance", amount = rAmt},
			{stat = "radioactiveResistance", amount = rAmt},
			{stat = "shadowResistance", amount = rAmt},
			{stat = "cosmicResistance", amount = rAmt},
			{stat = "healingStatusImmunity", amount = 1 }
		})
		makeAlert()
	 end
	 script.setUpdateDelta(0)
end

function makeAlert()
	if entity.entityType()=="player" then
		local statusTextRegion = { 0, 1, 0, 1 }
		animator.setParticleEmitterOffsetRegion("statustext", statusTextRegion)
		animator.burstParticleEmitter("statustext")
	end
end


function update(dt)

end

function uninit()

end