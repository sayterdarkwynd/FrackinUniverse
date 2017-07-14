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
    storage.count = (storage.count or 0) + amount
	sb.logInfo(storage.count)
    if storage.count >= config.getParameter('wellslots')[1].secondarycount then
	  sb.logInfo('test')
      storage.count = storage.count - config.getParameter('wellslots')[1].secondarycount
      for i=2,#config.getParameter('wellslots') do
        for j=1,amount do
          if math.random() <= config.getParameter('wellslots')[i].chance then
            world.containerPutItemsAt(entity.id(),{name=config.getParameter('wellslots')[i].name,count=config.getParameter('wellslots')[i].amount},i-1)
          end
        end
      end
    end
  end
end