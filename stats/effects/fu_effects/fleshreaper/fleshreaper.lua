function init() 

  script.setUpdateDelta(10)
end

function update(dt)

      local params = copy(self.projectileParameters)
      params.powerMultiplier = activeItem.ownerPowerMultiplier()
      params.power = params.power * config.getParameter("damageLevelMultiplier")
      local actualSlamPosition = world.collisionBlocksAlongLine(lastSlamPosition, newSlamPosition,nil,1)[1]
    --   sb.logInfo("actualSlamPosition = %s, slam length = %s", actualSlamPosition, world.magnitude(lastSlamPosition,newSlamPosition))
      world.spawnProjectile(self.projectileType, {actualSlamPosition[1],actualSlamPosition[2]+2}, activeItem.ownerEntityId(), {1,0}, false, params)
end




function slamPosition()
  return vec2.add(activeItem.handPosition(animator.partPoint("blade", "groundSlamPoint")), mcontroller.position())
end


function uninit()
  
end