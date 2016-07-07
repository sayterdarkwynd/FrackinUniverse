function init(args)
  object.setInteractive(true)
  self.timer = 0.05
end

function update(dt)
self.timer = self.timer - dt

if self.timer <= 0 then

  if isn_hasRequiredPower() == false then
    animator.setAnimationState("samplingarrayanim", "idle")
	return
  end
  
  if world.liquidAt(entity.position()) == true and entity.configParameter("isn_liquidCollector") == false then return end
  
  animator.setAnimationState("samplingarrayanim", "working")
  
  local output = nil
  local rarityroll = math.random(1,100)
  if rarityroll == 100 then
    output = entity.randomizeParameter("rareOutputs")
    self.timer = 0.05
  elseif rarityroll >= 79 then
    output = entity.randomizeParameter("uncommonOutputs")
    self.timer = 0.05
  else
    output = entity.randomizeParameter("commonOutputs")
    self.timer = 0.05
  end
  
  if output == nil or clearSlotCheck(output) == false then return end
  
  world.containerAddItems(entity.id(), {name = output, count = 1, data={}})
end


end




function clearSlotCheck(checkname)
	if world.containerItemsCanFit(entity.id(), {name= checkname, count=1, data={}}) > 0 then
		return true
	end
	return false
end