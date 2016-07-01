function init()
end

function update(dt)
status.modifyResourcePercentage("health", 1/200 * dt)
end

function uninit()
  
end