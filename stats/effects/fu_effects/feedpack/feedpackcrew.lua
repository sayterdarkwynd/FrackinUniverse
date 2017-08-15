function init() 
effect.addStatModifierGroup({
  {stat = "foodDelta", baseMultiplier = config.getParameter("regenAmount", 0.09)}
})
self.regenAmount= config.getParameter("regenAmount")
self.timerbase = config.getParameter("timer")
self.timer = config.getParameter("timer")
script.setUpdateDelta(10)


end

function update(dt)

  if status.resourcePositive("food") then
    if self.timer == 0 then
      status.modifyResource("food", self.regenAmount)
      self.timer = self.timerbase
      animator.setParticleEmitterOffsetRegion("feed", mcontroller.boundBox())
      animator.setParticleEmitterActive("feed", config.getParameter("particles", true))      
    end
  end
  self.timer = self.timer - dt
  
end

function uninit()
  effect.expire()
end