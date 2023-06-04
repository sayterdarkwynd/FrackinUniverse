function init()
  self.keycard=config.getParameter("keyname")
  if self.keycard==nil then
    object.setInteractive(false)
  else
    object.setInteractive(true)
  end

  if storage.state == nil then
    output(false)
  else
    output(storage.state)
  end
  if storage.timer == nil then
    storage.timer = 0
  end
  self.interval = config.getParameter("interval")
end

function onInteraction(args)
  if world.entityHasCountOfItem(args.sourceId, self.keycard) > 0 then
    if storage.state == false then
      output(true)
    end

    animator.playSound("on");
    storage.timer = self.interval
  else
    animator.playSound("fail")
  end
end

function onNpcPlay(npcId)
end

function output(state)
  if storage.state ~= state then
    storage.state = state
    object.setAllOutputNodes(state)
    if state then
      animator.setAnimationState("switchState", "on")
      animator.playSound("on");
    else
      animator.setAnimationState("switchState", "off")
      animator.playSound("off");
    end
  else
  end
end

function update(dt)
  if storage.timer > 0 then
    storage.timer = storage.timer - 1

    if storage.timer == 0 then
      output(false)
    end
  end
end
