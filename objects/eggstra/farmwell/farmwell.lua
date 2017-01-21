function init()
    object.setInteractive(true)
     script.setUpdateDelta(10)
end

function update(dt)
object.setInteractive(true)
    if storage.waterCount == nil then 
      storage.waterCount = 0 
    end
    storage.waterCount = storage.waterCount + dt
  if storage.waterCount < 100 then
    object.say("Water : Nearly Dry ("..math.ceil(storage.waterCount)..")")
  elseif storage.waterCount > 600 then
    object.say("Water : Brimming ("..math.ceil(storage.waterCount)..")")
  elseif storage.waterCount > 500 then
    object.say("Water : Full ("..math.ceil(storage.waterCount)..")")
  elseif storage.waterCount > 400 then
    object.say("Water : Wet ("..math.ceil(storage.waterCount)..")")
  elseif storage.waterCount > 300 then
    object.say("Water : Passable ("..math.ceil(storage.waterCount)..")")
  elseif storage.waterCount > 200 then
    object.say("Water : Low  "..math.ceil(storage.waterCount)..")")
  elseif storage.waterCount > 100 then
    object.say("Water : Very Low ("..math.ceil(storage.waterCount)..")")
  end
end

function onInteraction(args)
  if not storage.waterCount then
   storage.waterCount = 0
  end
  
  if storage.waterCount < 100 then
    object.say("Water : Nearly Dry ("..math.ceil(storage.waterCount)..")")
  elseif storage.waterCount > 600 then
    object.say("Water : Brimming ("..math.ceil(storage.waterCount)..")")
  elseif storage.waterCount > 500 then
    object.say("Water : Full ("..math.ceil(storage.waterCount)..")")
  elseif storage.waterCount > 400 then
    object.say("Water : Wet ("..math.ceil(storage.waterCount)..")")
  elseif storage.waterCount > 300 then
    object.say("Water : Passable ("..math.ceil(storage.waterCount)..")")
  elseif storage.waterCount > 200 then
    object.say("Water : Low  "..math.ceil(storage.waterCount)..")")
  elseif storage.waterCount > 100 then
    object.say("Water : Very Low ("..math.ceil(storage.waterCount)..")")
  end
  
  if storage.waterCount and storage.waterCount > 25 then
    local p = object.position()
    world.spawnItem("waterbucket", p, 1)
    storage.waterCount = storage.waterCount - 25
  end
end