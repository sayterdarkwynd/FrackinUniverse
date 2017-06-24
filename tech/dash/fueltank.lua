require "/scripts/util.lua"
require "/scripts/vec2.lua"

function init()
self.fuelAmount = world.getProperty("ship.fuel")  
world.setProperty("ship.fuel", self.fuelAmount * 1.25)

end

function uninit()
  tech.setParentDirectives()
end


function update(args)


end




