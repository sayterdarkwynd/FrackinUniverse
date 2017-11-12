require "/scripts/pathutil.lua"

function init()
  object.setInteractive(true)
  
  output(false)
end

function onInteraction(args)
  output(not storage.state)
  world.spawnItem({name = "supermatter", count = 20}, vec2.add(object.position(), args.source))
  object.setInteractive(false)
end

function output(state)
  storage.state = state
  if state then
    animator.setAnimationState("state", "on")
    object.setSoundEffectEnabled(true)
    animator.playSound("on")
  else
    animator.setAnimationState("state", "off")
    object.setSoundEffectEnabled(false)
    animator.playSound("off")
  end
end