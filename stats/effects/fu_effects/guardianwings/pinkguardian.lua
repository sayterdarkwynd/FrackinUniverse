function init()
  script.setUpdateDelta(5)
end

function update(dt)
status.modifyResourcePercentage("health", 1/200 * dt)
end

function uninit()
  
end