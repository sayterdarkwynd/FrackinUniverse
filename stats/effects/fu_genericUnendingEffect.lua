local oldInitUnendingEffect=init
local oldUninitUnendingEffect=uninit
local oldUpdateUnendingEffect=update

function init()
	if oldInitUnendingEffect then oldInitUnendingEffect() end
end

function update(dt)
	effect.modifyDuration(dt)
	oldUpdateUnendingEffect(dt)
end

function uninit()
	if oldUninitUnendingEffect then oldUninitUnendingEffect() end
end