function init()
	self.range=config.getParameter("range",5000)
end

function update(dt)
	if self and self.range then
		animator.setAnimationState("switchState", "on")
		local pos=entity.position()
		local buffer=world.entityQuery(pos,self.range,{includedTypes={"vehicle"}})

		for _,id in pairs(buffer) do
			world.callScriptedEntity(id,"vehicle.destroy")
		end
	else
		animator.setAnimationState("switchState", "off")
	end
end