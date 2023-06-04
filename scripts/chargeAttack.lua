rotationReset = {
  old_update = update
  }

update = function(dt, fireMode, shiftHeld)
  self.weapon.aimAngle = 0
  rotationReset.old_update(dt, fireMode, shiftHeld)
end