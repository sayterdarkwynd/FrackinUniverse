require "/scripts/vec2.lua"

function update()
  localAnimator.clearDrawables()

  local lastPoint = activeItemAnimation.handPosition(config.getParameter("ropeOffset"))
  for i = 2, 1000 do
    local nextPoint = animationConfig.animationParameter("p"..i)
    if nextPoint == nil then
      break
    end

    local position = activeItemAnimation.ownerPosition()
    local relativeNextPoint = world.distance(nextPoint, position)
    localAnimator.addDrawable({
        position = position,
        line = {lastPoint, relativeNextPoint},
        width = config.getParameter("ropeWidth"),
        color = config.getParameter("ropeColor")
      }, "player-1")

    lastPoint = relativeNextPoint
  end
end
