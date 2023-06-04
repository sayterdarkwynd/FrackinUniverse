require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  message.setHandler("updateProjectile", function(_,_,aimPosition)
       return entity.id()
    end)
  message.setHandler("kill", function()
      projectile.die()
    end)
  message.setHandler("reverse", function()
      mcontroller.setXVelocity(mcontroller.xVelocity()*-1)
    end)
end
