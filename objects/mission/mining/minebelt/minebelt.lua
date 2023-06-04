function init(args)
  entity.setInteractive(true)
  entity.setAllOutboundNodes(entity.animationState("switchState") == "on")
end

function onInteraction(args)
  if entity.animationState("switchState") == "off" then
    entity.setAnimationState("switchState", "on")
    entity.playSound("onSounds");
    entity.setAllOutboundNodes(true)
  else
    entity.setAnimationState("switchState", "off")
    entity.playSound("offSounds");
    entity.setAllOutboundNodes(false)
  end
end
