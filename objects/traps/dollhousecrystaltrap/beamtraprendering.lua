require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/interp.lua"

TilePixels = 8

function init()
  script.setUpdateDelta(1)

  self.light = objectAnimator.getParameter("beamLight")
  self.beamImages = objectAnimator.getParameter("beamImages")
  self.directions = objectAnimator.getParameter("beamDirections")
  self.angle = {}
  for i=1,4 do
    self.angle[i] = vec2.angle(self.directions[i])
  end
  self.beamOffsets = objectAnimator.getParameter("beamStartOffsets")

  self.startSize = vec2.div(root.imageSize(self.beamImages.first), TilePixels)
  self.endSize = vec2.div(root.imageSize(self.beamImages.last), TilePixels)
  self.minLength = self.startSize[1] + self.endSize[1]
end

function update()
  localAnimator.clearDrawables()
  localAnimator.clearLightSources()

  local requireProjectile = animationConfig.animationParameter("requireProjectile")
  for _,beam in pairs(animationConfig.animationParameter("beams")) do
    local hasProjectile = false
    if beam.startProjectile then
      hasProjectile = hasProjectile or world.entityExists(beam.startProjectile)
      beam.startPosition = world.entityPosition(beam.startProjectile) or beam.startPosition
    end
    if beam.endProjectile then
      hasProjectile = hasProjectile or world.entityExists(beam.endProjectile)
      beam.endPosition = world.entityPosition(beam.endProjectile) or beam.endPosition
    end

    if hasProjectile or not requireProjectile then
      local length = math.max(world.magnitude(beam.endPosition, beam.startPosition), self.minLength)
      local angle = vec2.angle(world.distance(beam.endPosition, beam.startPosition))
      local bodyLength = length - self.minLength

      local drawables = {
        {
          image = self.beamImages.first,
          position = {0, -self.startSize[2] / 2},
          fullbright = true,
          centered = false
        },
        {
          image = self.beamImages.body,
          position = {length - self.endSize[1] - bodyLength, -self.startSize[2] / 2},
          fullbright = true,
          centered = false,
          transformation = {
           {math.ceil(bodyLength * TilePixels), 0, 0},
           {0, 1, 0},
           {0, 0, 1}
         }
        },
        {
          image = self.beamImages.last,
          position = {length - self.endSize[1], -self.endSize[2] / 2},
          fullbright = true,
          centered = false
        }
      }

      for _,drawable in pairs(drawables) do
        drawable.rotation = angle
        drawable.position = vec2.add(vec2.rotate(drawable.position, angle), beam.startPosition)
        localAnimator.addDrawable(drawable)
      end

      if self.light then
        for x = 0, length, 3 do
          localAnimator.addLightSource({
            position = vec2.add(vec2.rotate({x, 0}, angle), beam.startPosition),
            color = self.light
          })
        end
      end
    end
  end
end
