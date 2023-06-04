function init()
  self.defaultOnAnimation = config.getParameter("defaultOnAnimation","max")
  self.defaultOffAnimation = config.getParameter("defaultOffAnimation","min")
  self.thresholdCount = config.getParameter("thresholdCount", 0)
  if self.thresholdCount > 0 then
    self.detectThresholds = config.getParameter("detectThresholds")
    self.lightArrayAnimations = config.getParameter("lightArrayAnimations")
  end
end

function getSample()
  local sample = math.min(world.lightLevel(object.position()),1.0)
  return math.floor(sample * 1000) * 0.1
end

function update(dt)
  object.setAllOutputNodes(false)
  animator.setAnimationState("sensorState", self.defaultOffAnimation)
  local i = 0
  if self.thresholdCount > 0 then
    local sample = getSample()

    if sample > 0 then
      while i < self.thresholdCount do
        if sample >= self.detectThresholds[i+1] then
          object.setOutputNodeLevel(i, true)
          animator.setAnimationState("sensorState", self.lightArrayAnimations[i+1])
        end
        i = i + 1
      end
    end
  end
end
