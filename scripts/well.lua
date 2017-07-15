require "/scripts/kheAA/transferUtil.lua"

function init()
  transferUtil.init()
end

function update(dt)
  transferUtil.loadSelfContainer()
  storage.waterCount = math.min((storage.waterCount or 0) + dt,100)
  for i=2,#config.getParameter('wellslots') do
    if world.containerItemAt(entity.id(),i-1) and world.containerItemAt(entity.id(),i-1).name ~= config.getParameter('wellslots')[i].name then
      world.containerConsumeAt(entity.id(),i-1,world.containerItemAt(entity.id(),i-1).count)
      world.spawnItem(world.containerItemAt(entity.id(),i-1),entity.position())
    end
  end
  local item = world.containerItemAt(entity.id(),0) or {name=config.getParameter('wellslots')[1].name,count=0}
  if item.name ~= config.getParameter('wellslots')[1].name then
    world.spawnItem(item,entity.position())
    world.containerConsumeAt(entity.id(),0,item.count)
    item.count = 0
  elseif item.count > config.getParameter('wellslots')[1].max then
    local dropitem = item
    dropitem.count = dropitem.count - config.getParameter('wellslots')[1].max
    world.spawnItem(dropitem,entity.position())
    world.containerConsumeAt(entity.id(),0,dropitem.count)
    item.count = config.getParameter('wellslots')[1].max
  end
  local amount = math.min(math.floor(storage.waterCount/config.getParameter('wellslots')[1].ratio),config.getParameter('wellslots')[1].max - item.count)
  world.containerPutItemsAt(entity.id(),{name=config.getParameter('wellslots')[1].name,count=amount},0)
  storage.waterCount = storage.waterCount - amount * config.getParameter('wellslots')[1].ratio
  if amount > 0 and #config.getParameter('wellslots') > 1 then
    for i=(storage.count or 0)+1,(storage.count or 0)+amount do
      for j=2,#config.getParameter('wellslots') do
        amountmod = math.min(math.floor(math.max(config.getParameter('wellslots')[j].count/config.getParameter('wellslots')[j].amount,1)),config.getParameter('wellslots')[j].amount)
        if config.getParameter('wellslots')[j].chance > 0 and math.fmod(i,config.getParameter('wellslots')[j].count/amountmod) == 0 and math.random() <= config.getParameter('wellslots')[j].chance then
          world.containerPutItemsAt(entity.id(),{name=config.getParameter('wellslots')[j].name,count=config.getParameter('wellslots')[j].amount/amountmod},j-1)
        end
      end
    end
    storage.count = (storage.count or 0) + amount
  end
end