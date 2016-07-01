function init()
end

function update(dt)
  local hPerc = world.entityHealth(entity.id())
  if hPerc[1] == 0 or hPerc[2] == 0 then return end
  if ((hPerc[1] / hPerc[2]) * 100) >= 50 then return end
  
  script.setUpdateDelta(60)
  status.modifyResourcePercentage("health", 0.01)
end

function uninit()
end