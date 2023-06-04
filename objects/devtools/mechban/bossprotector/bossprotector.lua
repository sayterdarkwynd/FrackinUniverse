require "/scripts/effectUtil.lua"

function init()
	self.range=config.getParameter("range",50)
end

function update(dt)
	if self and self.range then
		effectUtil.messageMechsInRange("despawnMech",self.range)
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
	end
end