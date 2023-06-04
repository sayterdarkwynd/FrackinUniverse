local handler

function init()
	animator.setParticleEmitterOffsetRegion("snow", mcontroller.boundBox())
	animator.setParticleEmitterActive("snow", true)
	effect.setParentDirectives("fade=6f6f6f=0.55")

	local rAmt=config.getParameter("resistanceAmount", 0)
	local dAmt=config.getParameter("defenseAmount", 0)
	if status.statPositive("specialStatusImmunity") then
		rAmt=rAmt*0.25
		dAmt=dAmt*0.25
	end

	local buffer={}
	local elementalTypes=root.assetJson("/damage/elementaltypes.config")
	local statBuffer={{stat = "protection", amount = dAmt}}

	for _,data in pairs(elementalTypes) do
		if data.resistanceStat then
			buffer[data.resistanceStat]=true
		end
	end

	for stat,_ in pairs(buffer) do
		table.insert(statBuffer,{stat=stat,amount=rAmt})
	end

	handler=effect.addStatModifierGroup(statBuffer)
	makeAlert()
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
	if handler then
		effect.removeStatModifierGroup(handler)
		handler=nil
	end
end