require "/scripts/util.lua"
require "/scripts/kheAA/transferUtil.lua"
local deltaTime=0

function init()
	transferUtil.init()
  object.setInteractive(true)
  self.timer = 1
end

function update(dt)
if deltaTime > 1 then
	deltaTime=0
	transferUtil.loadSelfContainer()
else
	deltaTime=deltaTime+dt
end

self.timer = self.timer - dt

if self.timer <= 0 then

  if isn_hasRequiredPower() == false then
    animator.setAnimationState("machineState", "idle")
	return
  end
  
  if world.liquidAt(entity.position()) == true and config.getParameter("isn_liquidCollector") == false then 
    return 
  end
  
  animator.setAnimationState("machineState", "active")
  
  local output = nil
  local rarityroll = math.random(1,100)
  if rarityroll == 100 then
    output = util.randomFromList(config.getParameter("rareOutputs"))
    self.timer = 5
  elseif rarityroll >= 79 then
    output = util.randomFromList(config.getParameter("uncommonOutputs"))
    self.timer = 3.5
  else
    output = util.randomFromList(config.getParameter("commonOutputs"))
    self.timer = 2
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