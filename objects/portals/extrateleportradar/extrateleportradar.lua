require "/scripts/util.lua"

function init()
  self.detectArea = config.getParameter("detectArea")
  self.detectArea[1] = object.toAbsolutePosition(self.detectArea[1])
  self.detectArea[2] = object.toAbsolutePosition(self.detectArea[2])

  storage.uuid = storage.uuid or sb.makeUuid()
  object.setInteractive(true)

  message.setHandler("onTeleport", function(message, isLocal, data)
      if not storage.vanishTime then
        storage.vanishTime = world.time() + config.getParameter("vanishTime",15)
      end
    end)

end

function update(dt)

if storage.vanishTime and world.time() > storage.vanishTime then
    object.smash()
  end

end

function uninit()
  if storage.vanishTime then
    storage.vanishTime = -1
  end
end

function onInteraction(args)
  if config.getParameter("returnDoor") then
    return { "OpenTeleportDialog", {
        canBookmark = false,
        includePlayerBookmarks = false,
        destinations = { {
          name = "Departure Radar",
          planetName = "Beam back...hopefully!",
          icon = "return",
          warpAction = "Return"
        } }
      }
    }
  else
    return { "OpenTeleportDialog", {
        canBookmark = false,
        includePlayerBookmarks = false,
        destinations = { {
          name = "???",
          planetName = "Unknown Destination",
          icon = "default",
          warpAction = string.format(config.getParameter("destination"), storage.uuid, world.threatLevel())
        } }
      }
    }
  end
end
