function init()
  storage.timer = storage.timer or 0
  storage.timerDuration = storage.timerDuration or config.getParameter("duration", 5)

  updateAnimation()

  object.setInteractive(true)
end

function update(dt)
  if not object.getInputNodeLevel(0) then
    storage.timer = storage.timerDuration
  elseif storage.timer > 0 then
    storage.timer = math.max(storage.timer - dt, 0)
  end

  object.setOutputNodeLevel(0, storage.timer <= 0)

  updateAnimation()
end

function updateAnimation()
  if storage.timer == storage.timerDuration then
    animator.setAnimationState("timerState", "off"..storage.timerDuration)
  elseif storage.timer > 0 then
    animator.setAnimationState("timerState", "count"..math.ceil(storage.timer))
  else
    animator.setAnimationState("timerState", "on"..storage.timerDuration)
  end
end

function onInteraction(args)
  storage.timer = 0
  storage.timerDuration = storage.timerDuration + 1
  if storage.timerDuration > 5 then storage.timerDuration = 1 end
end
