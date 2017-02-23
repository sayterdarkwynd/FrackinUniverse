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

  if storage.waterCount and storage.waterCount > 600 then
    storage.waterCount = 600
  end  
  if storage.waterCount and storage.waterCount > 99 then
    local p = object.position()
    world.spawnItem("liquidwater", p, 10)
    storage.waterCount = storage.waterCount - 100
  end
	  if storage.waterCount < 100 then
	    object.say("Water : "..math.ceil(storage.waterCount).." (Nearly Dry)")
	  elseif storage.waterCount > 600 then
	    object.say("Water : "..math.ceil(storage.waterCount).." (Brimming)")
	  elseif storage.waterCount > 500 then
	    object.say("Water : "..math.ceil(storage.waterCount).." (Full)")
	  elseif storage.waterCount > 400 then
	    object.say("Water : "..math.ceil(storage.waterCount).." (Wet)")
	  elseif storage.waterCount > 300 then
	    object.say("Water : "..math.ceil(storage.waterCount).." (Ample)")
	  elseif storage.waterCount > 200 then
	    object.say("Water : "..math.ceil(storage.waterCount).." (Low)")
	  elseif storage.waterCount > 100 then
	    object.say("Water : "..math.ceil(storage.waterCount).." (Very Low)")
	  end  
end