function init()
  if storage.state == nil then
    output(false)
  else
    output(storage.state)
  end
  if storage.timer == nil then
    storage.timer = 0
  end
  self.interval = entity.configParameter("interval")
  self.inverted = entity.configParameter("inverted") or false
  self.switchIsActive = false
end

function output(state)
  if storage.state ~= state then
    storage.state = state
    entity.setAlloutputNodes(state)
    if state then
      entity.setAnimationState("switchState", "on")
    else
      entity.setAnimationState("switchState", "off")
    end
  else
  end
end

function update(dt)
  if storage.timer == 0 then
    output(self.inverted)
    if entity.getInboundNodeLevel(0) then
      if (not self.switchIsActive) and storage.state == self.inverted then
        self.switchIsActive = true
        storage.timer = self.interval
        output(not self.inverted)
      end
    else
      self.switchIsActive = false
    end
  else
    storage.timer = storage.timer - 1 
  end
end