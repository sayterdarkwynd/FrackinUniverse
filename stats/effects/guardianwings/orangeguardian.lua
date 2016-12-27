function init()
end

function update(dt)
status.modifyResourcePercentage("health", 1/600 * dt)
end

function uninit()
  
end