function init()
    self.oldEfficiency = world.getProperty("ship.fuelEfficiency", 1 )
    self.oldSpeed = world.getProperty("ship.shipSpeed", 15)
    self.oldFuel = world.getProperty("ship.maxFuel", 1000)
end

function update(dt)
    world.setProperty("ship.fuelEfficiency", 1)
    world.setProperty("ship.shipSpeed", 15)
    world.setProperty("ship.maxFuel", 2000)
end

function uninit()
    world.setProperty("ship.fuelEfficiency", self.oldEfficiency)
    world.setProperty("ship.shipSpeed", self.oldSpeed)
    world.setProperty("ship.maxFuel", self.oldFuel)
end