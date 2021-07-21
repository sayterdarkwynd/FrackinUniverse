require "/scripts/vec2.lua"

function init()
  checkShipSpaces()
  if config.getParameter("collisionSpaces") then
    if storage.smash then
      object.setMaterialSpaces(config.getParameter("collisionSpaces"))
    end
  end
end

function update()
  if not storage.smash then
    object.say(config.getParameter("failureText"))
  end
end

function checkShipSpaces()
  storage.smash = true
  local objectPosition = entity.position()
  if world.type() == "unknown" then
    for x = -1, 1 do
      for y = -1, 1 do
        local pos = vec2.add(objectPosition, {x,y})
        if world.material(pos,"foreground") == "metamaterial:structure" then
          storage.smash = false
          return
        end
      end
    end
  end
end