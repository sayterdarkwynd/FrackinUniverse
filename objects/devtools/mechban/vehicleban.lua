function init()
	self.range=config.getParameter("range",5000)
end

function update(dt)
	if self and self.range then
		animator.setAnimationState("switchState", "on")
		local pos=entity.position()
		local buffer=world.entityQuery(pos,self.range,{includedTypes={"vehicle"}})

		for _,id in pairs(buffer) do
			pass,result=pcall(world.callScriptedEntity,id,"vehicle.destroy")
			if not pass then
				local owner=world.getObjectParameter(id,"ownerKey")
				if owner then
					world.sendEntityMessage(id,"store",owner)
				end
			end
		end
	else
		animator.setAnimationState("switchState", "off")
	end
end