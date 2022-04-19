function init()
  object.setInteractive(config.getParameter("interactive", true))
  if storage.state == nil then
    output(config.getParameter("defaultSwitchState", false))
  else
    output(storage.state)
  end
end

function onInteraction(args)
  output(not storage.state)
end

function onNpcPlay(npcId)
end

function onInputNodeChange(args)
  if args.level then
    output(args.node == 0)
  end
end

function output(state)
  storage.state = state
  if state then
    animator.setAnimationState("switchState", "on")
    if not (config.getParameter("alwaysLit")) then object.setLightColor(config.getParameter("lightColor", {0, 0, 0, 0})) end
    animator.playSound("on");
    object.setAllOutputNodes(true)
  else
    animator.setAnimationState("switchState", "off")
    if not (config.getParameter("alwaysLit")) then object.setLightColor({0, 0, 0, 0}) end
    animator.playSound("off");
    object.setAllOutputNodes(false)
  end
end
