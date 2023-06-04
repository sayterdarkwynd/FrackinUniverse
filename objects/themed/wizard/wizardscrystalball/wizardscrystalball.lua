function init()
  object.setInteractive(true)
  animator.setAnimationState("pulse", "stop")
end

function onInteraction(args)
  animator.setAnimationState("pulse", "pulse1")
end
