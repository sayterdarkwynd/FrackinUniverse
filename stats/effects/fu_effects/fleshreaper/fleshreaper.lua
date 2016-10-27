function init() 
  local bounds = mcontroller.boundBox()
  script.setUpdateDelta(10)
end

function update(dt)
    if mcontroller.falling() then
      mcontroller.controlParameters(config.getParameter("fallingParameters"))
      mcontroller.setYVelocity(math.max(mcontroller.yVelocity(), config.getParameter("maxFallSpeed")))
    end
end

function uninit()
  
end