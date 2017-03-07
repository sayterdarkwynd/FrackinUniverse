function init()
  self.defaultOnAnimation = config.getParameter("defaultOnAnimation","other")
  self.defaultOffAnimation = config.getParameter("defaultOffAnimation","off")
  self.liquidCount = config.getParameter("liquidCount",0)
  if self.liquidCount > 0 then
    self.liquidArrayNodes = config.getParameter("liquidArrayNodes")
    self.liquidArrayIDs = config.getParameter("liquidArrayIDs")
    self.liquidArrayAnimations = config.getParameter("liquidArrayAnimations")
  end
  

end

function getSample()
  return world.liquidAt(object.position())
end

function update(dt)
  local sample = getSample()

  object.setAllOutputNodes(false)
  local i = 0
  if not sample then
    animator.setAnimationState("sensorState", self.defaultOffAnimation)
  else
    while i < self.liquidCount+2 do
      if i == self.liquidCount+1 then
        object.setOutputNodeLevel(0, true)
        animator.setAnimationState("sensorState", self.defaultOnAnimation)
        i = i + 1
      elseif sample[1] == self.liquidArrayIDs[i] then
        object.setOutputNodeLevel(self.liquidArrayNodes[i], true)
        animator.setAnimationState("sensorState", self.liquidArrayAnimations[i])
        i = self.liquidCount + 2
      else
        i = i + 1
      end
    end
  end
end
