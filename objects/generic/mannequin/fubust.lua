require "/scripts/util.lua"

function init()
  storage.gender = storage.gender or "male"

  message.setHandler("swapGender", swapGender)
end

function update(dt)
end

--function swapGender()
--  storage.gender = storage.gender == "male" and "female" or "male"
--  setArmor(world.containerItemAt(entity.id(), 0), "headarmor")
--end

function containerCallback()
  setArmor(world.containerItemAt(entity.id(), 0), "headarmor")
end

function setArmor(item, validType)
  if item and root.itemType(item.name) == validType then
    animator.setAnimationState("head", "show")
    local itemConfig = root.itemConfig(item.name)

    local frameSet = itemConfig.config[storage.gender .. "Frames"]
    local directives = buildDirectives(item, itemConfig)

    animator.setPartTag("head", "frameSet", util.absolutePath(itemConfig.directory, frameSet))
    animator.setPartTag("head", "directives", directives)

  else
    animator.setAnimationState("head", "hide")
  end
end

function buildDirectives(item, itemConfig)
  local res = item.parameters.directives or itemConfig.directives or ""
  local colorOptions = itemConfig.config.colorOptions
  if colorOptions then
    local colorIndex = (item.parameters.colorIndex or itemConfig.config.colorIndex or 0) + 1
    colorIndex = colorIndex % #colorOptions
    if colorOptions[colorIndex] then
      for fromColor, toColor in pairs(colorOptions[colorIndex]) do
        res = res .. "?replace="..fromColor.."="..toColor
      end
    end
  end
  return res
end
