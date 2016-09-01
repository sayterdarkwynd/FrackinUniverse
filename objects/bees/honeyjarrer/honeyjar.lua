local contents

function init(args)
	if self.craftDelay == nil then
		self.craftDelay = 6
	end
	animator.setAnimationState("jar", "idle")
end

function update(dt)
    contents = world.containerItems(entity.id())
	if self.craftDelay > 0 then
		self.craftDelay = self.craftDelay - 1
	end
		if self.craftDelay == 0 then
				local ents = world.objectQuery(entity.position(), 5, {name="bees_industrialcentrifuge", order="nearest"})
					if #ents > 0 then
						if world.entityName(ents[1]) == "bees_industrialcentrifuge" then
							local honeycombType = world.callScriptedEntity(ents[1], "honeyCheck")
								if honeycombType ~= nil then
									if world.containerConsume(entity.id(), { name= "emptyhoneyjar", count = 1, data={}}) == true then
										world.containerAddItems(entity.id(), { name= honeycombType, count = 1, data={}})
										animator.setAnimationState("jar", "working")
									end
								else
									animator.setAnimationState("jar", "idle")
							end
							self.craftDelay = 6
						end
					end
			end
end