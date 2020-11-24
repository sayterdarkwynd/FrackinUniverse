require "/scripts/util.lua"

function init()
	self.slot=config.getParameter("effectSlot","chest")
end


function update(dt)
	local eType=world.entityType(entity.id())
	if not eType or eType ~= "player" then return end

	if promise and promise:finished() and promise:succeeded() then
		data=promise:result()
		promise=nil
	else
		if promise and promise:error() then
			promise=nil
		elseif not promise then
			promise=world.sendEntityMessage(entity.id(),"player.equippedItem",self.slot)
		end
		return
	end
	data=data.parameters.currentCollar
	if data and data.effects then
		for _,e in pairs(data.effects) do
			if type(e)=="string" then
				status.addEphemeralEffect(e,dt*3)
			end
		end
	end
end
