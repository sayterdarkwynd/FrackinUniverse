function init()
  self.tileLayer = projectile.getParameter("layerSprayed")
  self.sprayedTile = projectile.getParameter("tileSprayed")
  self.hueShift = projectile.getParameter("hueShift", 0)
  self.allowOverlap = projectile.getParameter("overlap", true)
  self.waitUntil = projectile.getParameter("waitUntil", 0)
  self.timesUpdated = 0
end

function update(dt)
  if self.timesUpdated > self.waitUntil then
    if not world.tileIsOccupied(entity.position(), self.tileLayer) then
      world.placeMaterial(entity.position(), self.tileLayer, self.sprayedTile, self.hueShift, self.allowOverlap)
	end
  end
  self.timesUpdated = self.timesUpdated + 1
end