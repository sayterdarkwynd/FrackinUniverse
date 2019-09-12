require "/scripts/effectUtil.lua"

function init()
	object.setInteractive(true)
	self.range=config.getParameter("range",20)
	itemList=root.assetJson("/objects/power/fu_atmosfilter/warpedItemList.json")
end

function update(dt)
	if not storage.deltaTime or storage.deltaTime > 1.0 then
		local items=world.containerItems(entity.id())
		if items and #items>0 then
			animator.setAnimationState("switchState","on")
			for _,item in pairs(items) do
				if itemList and itemList[item.name] then
					for _,buffer in pairs(itemList[item.name]) do
						 effectUtil.effectAllOfTeamInRange(buffer.status,self.range,(storage.deltaTime or 1)*(buffer.durationMod or 2),buffer.team)
					end
				end
			end
		else
			animator.setAnimationState("switchState","off")
		end
		storage.deltaTime=0.0
	else
		storage.deltaTime=storage.deltaTime+dt
	end
end