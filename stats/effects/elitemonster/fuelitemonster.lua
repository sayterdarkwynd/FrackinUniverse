handler=-1

function init()
	if world.isMonster(entity.id()) then
		handler=effect.addStatModifierGroup({})
		--effect.setStatModifierGroup(handler,config.getParameter("statModifiers", {}))
		donkey=config.getParameter("statModifiers", {})
		effect.setStatModifierGroup(handler,donkey)
	end
	script.setUpdateDelta(0)
end