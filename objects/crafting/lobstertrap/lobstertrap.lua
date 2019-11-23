function init()
    object.setInteractive(true)
end

function update(dt)
object.setInteractive(true)
    if storage.waterCount == nil then 
      storage.waterCount = 0 
    end
    storage.waterCount = storage.waterCount + dt
    
end

function onInteraction(args)
  if not storage.waterCount then
   storage.waterCount = 0
  end

  if storage.waterCount and storage.waterCount > 180 then
    storage.waterCount = 180
  end  
  if storage.waterCount and storage.waterCount > 180 then
    local p = object.position()
    world.spawnItem("liquidwater", p, 10)
    storage.waterCount = storage.waterCount - 180
  end
end