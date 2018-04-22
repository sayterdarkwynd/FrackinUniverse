require "/scripts/mementomori.lua"

function init()
	activeItem.setScriptedAnimationParameter(mementomori.deathPositionKey,status.statusProperty(mementomori.deathPositionKey))
	script.setUpdateDelta(5)
	promise=world.sendEntityMessage(activeItem.ownerEntityId(),"player.worldId")
end

function update(dt)
	if promise then
		if promise:finished() then
			if promise:succeeded() then
				activeItem.setScriptedAnimationParameter(mementomori.worldId,promise:result())
			end
			script.setUpdateDelta(0)
		end
	end
end