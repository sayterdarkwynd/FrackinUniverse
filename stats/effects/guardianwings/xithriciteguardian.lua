function init()
end

function update(dt)
status.modifyResourcePercentage("health", 1/900 * dt)
end

function uninit()
  
end