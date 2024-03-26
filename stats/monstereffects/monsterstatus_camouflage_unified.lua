local fu_monsters_init = init
local fu_monsters_update = update
local fu_monsters_uninit = uninit

local camoEffectToApply

function init()
	if fu_monsters_init then
		fu_monsters_init()
	end
	camoEffectToApply=config.getParameter("camoEffectToApply") or "camouflage100"
	status.addEphemeralEffect(camoEffectToApply,script.updateDt()*3)
end



function update(dt)
	if fu_monsters_update then
		fu_monsters_update(dt)
	end
	status.addEphemeralEffect(camoEffectToApply,dt*3)
end



function uninit()
	if fu_monsters_uninit then
		fu_monsters_uninit()
	end
end
