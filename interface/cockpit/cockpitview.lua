require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/rect.lua"
require "/scripts/poly.lua"
require "/interface/cockpit/cockpitutil.lua"
require "/scripts/drawingutil.lua"


-- tweening helpers
-- take an object and cockpit view settings, return position, rotation, scale

function warpIn(object, settings)
  local ratio = 1 - ((1 - (object.timer / settings.tweenInTime)) ^ 4)
  local distance = interp.linear(ratio, settings.warpDistance, 0)
  local position = vec2.add(object.position, vec2.mul(vec2.norm(object.position), distance))
  local angle = vec2.angle(vec2.sub({0, 0}, object.position))
  local scale = 1
  return position, angle, scale
end

function warpOut(object, settings)
  local distance = interp.linear((object.timer / settings.tweenOutTime) ^ 4, 0, settings.warpDistance)
  local position = vec2.add(object.position, vec2.mul(vec2.norm(object.position), distance))
  local angle = vec2.angle(object.position)
  local scale = 1
  return position, angle, scale
end

function swirlIn(object, settings)
  local position = object.position
  local toAngle = vec2.angle(vec2.sub({0, 0}, object.position))
  local angle = util.easeInOutQuad(object.timer / settings.tweenInTime, toAngle - settings.swirlAngle, toAngle)
  local scale = util.easeInOutQuad(object.timer / settings.tweenInTime, 0, 1)
  return position, angle, scale
end

function swirlOut(object, settings)
  local position = object.position
  local fromAngle = vec2.angle(vec2.sub({0, 0}, object.position))
  local angle = util.easeInOutQuad(object.timer / settings.tweenInTime, fromAngle, fromAngle + settings.swirlAngle)
  local scale = 1 - util.easeInOutQuad(object.timer / settings.tweenInTime, 0, 1)
  return position, angle, scale
end

-- Cockpit view object

View = {
  player = {
    position = nil,
    direction = nil
  },

  tweenIn = {},
  tweenOut = {},
  objects = {},

  systemCamera = {
    position = {0, 0},
    scale = 1
  },
  universeCamera = {
    position = {0, 0},
    scale = 1
  },
  twinkleTimer = 0,
  backgroundScale = 1.0
}

function View:init()
  self.windowSize = widget.getSize("consoleScreenCanvas")
  self.settings = config.getParameter("cockpitViewSettings")

  for _,uuid in pairs(celestial.systemObjects()) do
    local objectConfig = celestial.objectTypeConfig(celestial.objectType(uuid))

    self.objects[uuid] = {
      position = celestial.objectPosition(uuid),
      parameters = celestial.objectParameters(uuid),
      direction = {0, 0},
      permanent = objectConfig.permanent,
      moving = objectConfig.moving
    }
    if moving then
      self.objects[uuid].outFunc = warpOut
    else
      self.objects[uuid].outFunc = swirlOut
    end
  end

  for _,uuid in pairs(celestial.playerShips()) do
    self.objects[uuid] = {
      position = celestial.playerShipPosition(uuid),
      parameters = self.settings.playerShipParameters,
      direction = {0, 0},
      moving = true,
      permanent = false,
      player = true,
      outFunc = warpOut
    }
  end

  self.player = {
    position = celestial.shipSystemPosition(),
    direction = {1, 0}
  }

  self:reset()
end

function View:reset()
  self.canvas = widget.bindCanvas("consoleScreenCanvas")

  self.drawPlanet = false
  self.drawSystem = false
  self.drawStars = false
  self.drawTravel = false
  self.drawShip = false

  self.planet = {
    planet = nil,
    orbitOpacity = 1.0,
    hover = nil,
    drawObjects = false,
    mappedObjects = {}
  }

  self.system = {
    system = nil,
    planets = {},
    drawObjects = true,
    mappedObjects = {},
    orbitOpacity = 1.0,
    fadePlanet = nil,
    fadeOpacity = 1.0,
    hover = nil,
    destination = nil,
    asteroidCounts = {},
    planetParameters = {},
    visitableParameters = {}
  }

  self.stars = {
    systems = {},
    lines = {},
    hoverSystem = nil,
    travelSystem = nil,
    currentSystem = nil,
    displayMarker = false,
    currentOpacity = 1.0,
    lineOpacity = 1.0
  }

  self.travel = {
    stars = {},
    lines = {},
    finalStars = {},
    lineOpacity = 1.0,
    travelLine = nil,
    travelLineTimer = 0
  }

  self.ship = {
    scale = 1.0,
    opacity = 1.0
  }

  if self.selection then
    pane.playSound(self.settings.sounds.deselect)
  end
  self.selection = nil
  self.selectionPosition = nil
  self.selectionTimer = 0

  self.infoBox = nil
  self:showPlanetInfo(false)
  self:showClusterInfo(false)
  self:showObjectInfo(false)
  self:showSystemInfo(false)
end

function View:circle(radius, center)
  return circle(radius, math.ceil(4.0 * math.sqrt(radius)), center)
end

function View:render(dt)
  if self.playerWarpIn then
    self.playerWarpIn = self.playerWarpIn + dt
    if self.playerWarpIn > self.settings.playerWarpTime then
      self.playerWarpIn = nil
    end

    self.player.position = celestial.shipSystemPosition()
    self.player.direction = vec2.norm(vec2.sub({0, 0}, self.player.position))
  end

  local playerPosition = celestial.shipSystemPosition()
  if playerPosition and vec2.mag(vec2.sub(playerPosition, self.player.position)) > 0.001 then
    self.player.direction = vec2.norm(vec2.sub(playerPosition, self.player.position))
    self.player.position = playerPosition
  end
  local destination = celestial.shipDestination()
  if destination and playerPosition then
    self.player.direction = vec2.norm(vec2.sub(celestial.systemPosition(destination), playerPosition))
  end

  local newObjects = celestial.systemObjects()
  for _,uuid in pairs(newObjects) do
    if not self.objects[uuid] and not self.tweenIn[uuid] then
      local objectConfig = celestial.objectTypeConfig(celestial.objectType(uuid))
      local parameters = celestial.objectParameters(uuid)
      self.tweenIn[uuid] = {
        timer = 0,
        position = celestial.objectPosition(uuid),
        parameters = parameters,
        moving = objectConfig.moving,
        permanent = objectConfig.permanent
      }
      if objectConfig.moving then
        self.tweenIn[uuid].inFunc = warpIn
        self.tweenIn[uuid].outFunc = warpOut
      else
        self.tweenIn[uuid].inFunc = swirlIn
        self.tweenIn[uuid].outFunc = swirlOut
      end
    end
  end
  local newShips = celestial.playerShips()
  for _,uuid in pairs(newShips) do
    if not self.objects[uuid] and not self.tweenIn[uuid] then
      self.tweenIn[uuid] = {
        timer = 0,
        position = celestial.playerShipPosition(uuid),
        parameters = self.settings.playerShipParameters,
        moving = true,
        inFunc = warpIn,
        outFunc = warpOut
      }
    end
  end
  for uuid,object in pairs(self.tweenIn) do
    object.timer = object.timer + dt
    object.position = celestial.objectPosition(uuid) or object.position
    if object.timer >= self.settings.tweenInTime then
      self.objects[uuid] = object
      self.objects[uuid].direction = vec2.sub({0, 0}, object.position)
      object.timer = 0
      self.tweenIn[uuid] = nil
    end
  end
  for uuid,object in pairs(self.objects) do
    local position = celestial.objectPosition(uuid) or celestial.playerShipPosition(uuid)
    if position then
      if not compare(position, object.position) then
        object.direction = vec2.norm(vec2.sub(position, object.position))
      end
      object.position = position
    else
      self.tweenOut[uuid] = object
      object.timer = 0
      self.objects[uuid] = nil
    end
  end
  for uuid,object in pairs(self.tweenOut) do
    object.timer = object.timer + dt
    if object.timer > self.settings.tweenOutTime then
      self.tweenOut[uuid] = nil
    end
  end

  self.canvas:clear()

  local cameras = {self.universeCamera, self.systemCamera}
  for _,camera in pairs(cameras) do
    if camera.transition then
      camera.transition.timer = math.min(1.0, transition.timer + dt)
      local ratio = camera.transition.timer / camera.transition.time
      lerpCamera(transition.timer / transition.time, transition.position, transition.scale)
    end
  end

  self.twinkleTimer = self.twinkleTimer + dt

  self:renderBackground(self.backgroundScale)

  if self.drawPlanet then
    self:renderPlanet(self.planet, dt)
  end

  if self.drawSystem then
    self:renderSystem(self.system, dt)
  end

  if self.drawShip then
    self:renderPlayerShip(self.ship, dt)
  end

  if self.drawStars then
    self:renderStars(self.stars, dt)
  end

  if self.drawTravel then
    self:renderTravel(self.travel, dt)
  end

  if self.selection then
    self:renderSelection(dt)
  end

  if self.infoBox then
    self:renderInfoBox(dt)
  end
end

function View:select(system, location)
  if location == nil then
    if self.selection then
      pane.playSound(self.settings.sounds.deselect)
    end
    self.selection = nil
    self.selectionPosition = nil
    return
  end

  if not compare(self.selection, {system, location}) then
    pane.playSound(self.settings.sounds.select)
    self.selectionTimer = 0
  end
  self.selection = {system, location}
  self.selectionPosition = nil
end

function View:renderSelection(dt)
  local system, location = self.selection[1], self.selection[2]
  if location[1] == "coordinate" and location[2].planet == 0 then
    self.selectionPosition = self:uToScreen(systemPosition(location[2]))
  else
    local worldPosition
    if location[1] == "object" then
      worldPosition = objectPosition(system, location[2])
    else
      worldPosition = celestial.systemPosition(location)
    end
    if not worldPosition then
      self.selection = nil
      self.selectionPosition = nil
      return
    end

    self.selectionPosition = self:sToScreen(worldPosition)
  end
  local animation = self.settings.selectMarkerAnimation
  self.selectionTimer = math.min(animation.cycle, self.selectionTimer + dt)
  local frame = math.ceil(self.selectionTimer / animation.cycle * animation.frames)
  self.canvas:drawImage(string.format(animation.image, frame), self.selectionPosition, 1, "white", true)
end

function View:showPlanetInfo(planet)
  if not planet then
    widget.setVisible("planetinfo", false)
    return
  end

  self.infoBox = {
    timer = 0,
    widget = "planetinfo",
    background = "planetinfo.background",
    inner = "planetinfo.inner",
    height = config.getParameter("planetInfoBox.height"),
    tooltips = {}
  }
  local seed = celestial.planetSeed(planet)
  local rand = sb.makeRandomSource(seed)
  local parameters = celestial.visitableParameters(planet)

  widget.setText("planetinfo.inner.name", celestial.planetName(planet))
  widget.removeAllChildren("planetinfo.inner.oreLayout")
  widget.removeAllChildren("planetinfo.inner.weatherLayout")

  local description = ""
  if parameters then
    description = util.randomFromList(config.getParameter("visitableTypeDescription")[parameters.typeName], rand)

    widget.setVisible("planetinfo.inner.threatLabel", true)
    widget.setVisible("planetinfo.inner.threatValue", true)

    local threatLevelText = config.getParameter("threatLevelText")
    threatLevelText = threatLevelText[parameters.typeName] or threatLevelText.default
    local threatLevel = threatLevelText[util.clamp(math.ceil(parameters.threatLevel), 1, #threatLevelText)]
    widget.setText("planetinfo.inner.threatValue", threatLevel)

    local threatLevelColor = config.getParameter("threatLevelColor")
    threatLevelColor = threatLevelColor[parameters.typeName] or threatLevelColor.default
    local color = threatLevelColor[util.clamp(math.ceil(parameters.threatLevel), 1, #threatLevelColor)]
    widget.setFontColor("planetinfo.inner.threatValue", color)

    local displayOres = config.getParameter("displayOres")
    for _,ore in pairs(celestial.planetOres(planet, parameters.threatLevel)) do
      local display = displayOres[ore]
      if display then
        self.infoBox.tooltips[string.format("planetinfo.inner.oreLayout.%s", ore)] = display.displayName
        widget.addFlowImage("planetinfo.inner.oreLayout", ore, display.icon)
      end
    end

    if parameters.weatherPool then
      local displayWeathers = config.getParameter("displayWeathers")
      self.infoBox.weathers = {}
      for _,weather in pairs(parameters.weatherPool) do
        local display = displayWeathers[weather.item]
        if display then
          self.infoBox.tooltips[string.format("planetinfo.inner.weatherLayout.%s", weather.item)] = display.displayName
          widget.addFlowImage("planetinfo.inner.weatherLayout", weather.item, display.icon)
        end
      end
    end
  else
    parameters = celestial.planetParameters(planet)
    description = util.randomFromList(config.getParameter("worldTypeDescription")[parameters.worldType], rand)

    widget.setVisible("planetinfo.inner.threatLabel", false)
    widget.setVisible("planetinfo.inner.threatValue", false)
  end
  widget.setText("planetinfo.inner.description", description)

  self.infoBox.update = function()
    local bookmark = newPlanetBookmark(planet)
    if existingBookmark(coordinateSystem(planet), bookmark) then
      widget.setText("planetinfo.inner.bookmark", config.getParameter("planetInfoBox.bookmarkButtonCaption.edit"))
      widget.setButtonEnabled("planetinfo.inner.bookmark", true)
    elseif bookmark then
      widget.setText("planetinfo.inner.bookmark", config.getParameter("planetInfoBox.bookmarkButtonCaption.add"))
      widget.setButtonEnabled("planetinfo.inner.bookmark", true)
    else
      widget.setText("planetinfo.inner.bookmark", config.getParameter("planetInfoBox.bookmarkButtonCaption.disabled"))
      widget.setButtonEnabled("planetinfo.inner.bookmark", false)
    end
  end

  self.infoBox.update()
end

function View:showClusterInfo(planet)
  if not planet then
    widget.setVisible("clusterinfo", false)
    return
  end

  self.infoBox = {
    timer = 0,
    widget = "clusterinfo",
    background = "clusterinfo.background",
    inner = "clusterinfo.inner",
    height = config.getParameter("clusterInfoBox.height"),
    tooltips = {}
  }

  widget.setText("clusterinfo.inner.name", celestial.planetName(planet))

  local planetType = nil
  local visitableParameters = celestial.visitableParameters(planet)
  local typeNames = config.getParameter("planetTypeNames")
  if visitableParameters then
    planetType = visitableParameters.typeName
  elseif celestial.planetParameters(planet).worldType == "GasGiant" then
    planetType = "gasgiant"
  else
    planetType = celestial.planetParameters(planet).worldType
  end
  local image = string.format(config.getParameter("clusterInfoBox.iconImage"), planetType)
  widget.setImage("clusterinfo.inner.type", image)

  local moons = celestial.children(planet)
  local moonLabels = config.getParameter("clusterMoons")
  local displayMoon = ""
  if #moons == 0 then
    displayMoon = moonLabels.none
  elseif #moons == 1 then
    displayMoon = moonLabels.singular
  else
    displayMoon = string.format(moonLabels.plural, #moons)
  end
  widget.setText("clusterinfo.inner.moons", displayMoon)

  self.infoBox.update = function()
    if player.isMapped(planet) then
      widget.setButtonEnabled("clusterinfo.inner.view", true)
      widget.setText("clusterinfo.inner.view", config.getParameter("clusterInfoBox.viewButtonCaption.enabled"))
    else
      widget.setButtonEnabled("clusterinfo.inner.view", false)
      widget.setText("clusterinfo.inner.view", config.getParameter("clusterInfoBox.viewButtonCaption.disabled"))
    end
  end

  self.infoBox.update()
end

function View:showObjectInfo(system, object)
  if not system then
    widget.setVisible("objectinfo", false)
    return
  end

  self.infoBox = {
    timer = 0,
    widget = "objectinfo",
    background = "objectinfo.background",
    inner = "objectinfo.inner",
    height = config.getParameter("objectInfoBox.height"),
    tooltips = {}
  }

  if object.parameters then
    widget.setText("objectinfo.inner.name", object.parameters.displayName)
    widget.setText("objectinfo.inner.description", object.parameters.description)
  end

  local colors = config.getParameter("objectThreatColors")
  local threatText = config.getParameter("objectThreatText")
  if player.canDeploy() then
    local systemParameters = celestial.planetParameters(system)
    local minThreat = config.getParameter("objectMinThreat")
    local threatLevel = celestial.objectTypeConfig(object.type).threatLevel or systemParameters.spaceThreatLevel
    local index = math.max(1, threatLevel - minThreat + 1)
    widget.setFontColor("objectinfo.inner.threat", colors.available[index])
    widget.setText("objectinfo.inner.threat", string.format("%s%s", config.getParameter("threatTextPrefix"), threatText.available[index]))
  else
    widget.setFontColor("objectinfo.inner.threat", colors.unavailable)
    widget.setText("objectinfo.inner.threat", threatText.unavailable)
  end

  self.infoBox.update = function()
    local bookmark = newObjectBookmark(object.uuid, object.type)
    if player.mappedObjects(system)[object.uuid] then
      if celestial.objectTypeConfig(object.type).permanent then
        widget.setButtonEnabled("objectinfo.inner.bookmark", true)
        if existingBookmark(coordinateSystem(system), bookmark) then
          widget.setText("objectinfo.inner.bookmark", config.getParameter("objectInfoBox.bookmarkButtonCaption.edit"))
        else
          widget.setText("objectinfo.inner.bookmark", config.getParameter("objectInfoBox.bookmarkButtonCaption.add"))
        end
      else
        widget.setButtonEnabled("objectinfo.inner.bookmark", false)
        widget.setText("objectinfo.inner.bookmark", config.getParameter("objectInfoBox.bookmarkButtonCaption.disabled"))
      end
    else
      widget.setButtonEnabled("objectinfo.inner.bookmark", false)
      widget.setText("objectinfo.inner.bookmark", config.getParameter("objectInfoBox.bookmarkButtonCaption.unexplored"))
    end
  end

  self.infoBox.update()
end

function View:showSystemInfo(system)
  if not system then
    widget.setVisible("systeminfo", false)
    return
  end

  self.infoBox = {
    timer = 0,
    widget = "systeminfo",
    background = "systeminfo.background",
    inner = "systeminfo.inner",
    height = config.getParameter("systemInfoBox.startHeight"),
    tooltips = {}
  }

  widget.setText("systeminfo.inner.name", celestial.planetName(system))

  local starType = celestial.planetParameters(system).typeName or "default"
  widget.setText("systeminfo.inner.type", config.getParameter(string.format("starTypeNames.%s", starType)))
  widget.setFontColor("systeminfo.inner.type", config.getParameter(string.format("starTypeColors.%s", starType)))

  local clusters = celestial.children(system)
  local planets = {}
  for _,parent in pairs(clusters) do
    table.insert(planets, parent)
    for _,moon in pairs(celestial.children(parent)) do
      table.insert(planets, moon)
    end
  end

  local types = {}
  for _,planet in pairs(planets) do
    local parameters = celestial.visitableParameters(planet)
    if parameters then
      types[parameters.typeName] = true
    else
      parameters = celestial.planetParameters(planet)
      types[parameters.worldType] = true
    end
  end

  widget.clearListItems("systeminfo.inner.planetList")

  for planetType in pairs(types) do
    local displayName = config.getParameter(string.format("planetTypeNames.%s", planetType))
    local displayColor = config.getParameter(string.format("planetTypeColors.%s", planetType), {255, 255, 255})
    local displayIcon = string.format(config.getParameter("systemInfoBox.iconImage"), planetType)
    if displayName then
      local listItem = string.format("systeminfo.inner.planetList.%s", widget.addListItem("systeminfo.inner.planetList"))
      widget.setText(string.format("%s.type", listItem), displayName)
      widget.setFontColor(string.format("%s.type", listItem), displayColor)
      widget.setImage(string.format("%s.icon", listItem), displayIcon)
    end
  end
  local listSize = widget.getSize("systeminfo.inner.planetList")
  local listPos = widget.getPosition("systeminfo.inner.planetList")
  self.infoBox.height = self.infoBox.height + listSize[2] + listPos[2]

  local namePosition = widget.getPosition("systeminfo.inner.name")
  widget.setPosition("systeminfo.inner.name", {namePosition[1], config.getParameter("systemInfoBox.nameLabelHeight") + listPos[2] + listSize[2]})
  widget.setPosition("systeminfo.inner.type", {namePosition[1], config.getParameter("systemInfoBox.typeLabelHeight") + listPos[2] + listSize[2]})

  if player.isMapped(system) then
    widget.setButtonEnabled("systeminfo.inner.view", true)
    widget.setText("systeminfo.inner.view", config.getParameter("systemInfoBox.viewButtonCaption.enabled"))
  else
    widget.setButtonEnabled("systeminfo.inner.view", false)
    widget.setText("systeminfo.inner.view", config.getParameter("systemInfoBox.viewButtonCaption.disabled"))
  end
end

function View:tooltip(mousePosition)
  if self.infoBox and self.infoBox.tooltips then
    for widgetName,tooltip in pairs(self.infoBox.tooltips) do
      if widget.inMember(widgetName, mousePosition) then
        return tooltip
      end
    end
  end
end

function View:renderInfoBox(dt)
  local info = self.infoBox
  local canvas = rect.withSize(widget.getPosition("consoleScreenCanvas"), self.windowSize)
  if info then
    if not self.selectionPosition then
      widget.setVisible(info.widget, false)
      self.infoBox = nil
      return
    end

    local size = widget.getSize(info.widget)
    widget.setVisible(info.widget, true)
    info.timer = info.timer + dt

    local height = math.min(1.0, info.timer / self.settings.planetInfo.expandTime) * info.height
    widget.setSize(info.widget, {size[1], height})
    widget.setSize(info.background, {size[1], height})
    widget.setSize(info.inner, {size[1] - 2, height - 10})
    local position = vec2.add(vec2.add(self.selectionPosition, {0, -height / 2}), self.settings.planetInfo.offset)

    local box = rect.withSize(vec2.add(position, rect.ll(canvas)), {size[1], height})
    box = rect.bound(box, rect.pad(canvas, -5))

    local line
    if box[1] - self.selectionPosition[1] < self.settings.planetInfo.minOffset then
      box[3] = self.selectionPosition[1] - self.settings.planetInfo.offset[1]
      box[1] = box[3] - size[1]
      box = rect.bound(box, rect.pad(canvas, -5))
      line = {
        vec2.sub({math.floor(box[3] - 1), (box[4] + box[2]) / 2}, {canvas[1], canvas[2]}),
        vec2.add(self.selectionPosition, {-3, 0})
      }
    else
      line = {
        vec2.add(self.selectionPosition, {3, 0}),
        vec2.sub({math.floor(box[1]), (box[4] + box[2]) / 2}, {canvas[1], canvas[2]})
      }
    end
    local mid = (line[1][1] + line[2][1]) / 2
    self.canvas:drawLine(line[1], {mid, line[1][2]}, {23, 178, 0}, 2)
    self.canvas:drawLine({mid, line[1][2]}, {mid, line[2][2]}, {23, 178, 0}, 2)
    self.canvas:drawLine({mid, line[2][2]}, line[2], {23, 178, 0}, 2)

    widget.setPosition(info.widget, rect.ll(box))

    if info.timer > self.settings.planetInfo.expandTime then
      widget.setVisible(info.inner, true)
    else
      widget.setVisible(info.inner, false)
    end

    if info.update then
      info.update()
    end
  end
end

function View:systemScanRegion(position)
  position = position or self.universeCamera.position
  local windowSize = widget.getSize("consoleScreenCanvas")
  return {
    position[1] - windowSize[1] / 2 / self.universeCamera.scale,
    position[2] - windowSize[2] / 2 / self.universeCamera.scale,
    position[1] + windowSize[1] / 2 / self.universeCamera.scale,
    position[2] + windowSize[2] / 2 / self.universeCamera.scale
  }
end

function View:bgScale(screen)
  return self.settings.bgScale[screen]
end

function View:systemScale(system)
  local planets = celestial.children(system)
  local radius = 0
  if #planets > 0 then
    local planet = {planet = 0}
    for _,p in pairs(planets) do
      if p.planet > planet.planet then
        planet = p
      end
    end
    radius = radius + vec2.mag(celestial.planetPosition(planet))
    radius = radius + celestial.clusterSize(planet)
  end
  return math.min(self.settings.scale.system[2], math.max(self.settings.scale.system[1], self.settings.viewRadius / radius))
end

function View:planetScale(planet)
  local radius = celestial.clusterSize(planet)
  return math.min(self.settings.scale.planet[2], math.max(self.settings.scale.planet[1], self.settings.viewRadius / radius))
end

function View:scale(camera, scale)
  if type(scale) == "string" then
    scale = (self.settings.scale[scale][1] + self.settings.scale[scale][2]) / 2
  end
  if scale == nil then error(string.format("No scale set for screen %s", screen)) end
  if camera == "universe" then
    scale = scale * self.settings.universeSystemRatio
  end
  return scale
end

function View:camera(camera)
  if camera == "universe" then
    return self.universeCamera
  elseif camera == "system" then
    return self.systemCamera
  end
end

function View:clampUniversePosition(position)
  local scale = View:scale("universe", "universe")
  local min = {-2147483647 + (self.windowSize[1] / scale / 2), -2147483647 + (self.windowSize[2] / scale / 2)}
  local max = {2147483647 - (self.windowSize[1] / scale / 2), 2147483647 - (self.windowSize[2] / scale / 2)}
  return {
    util.clamp(position[1], min[1], max[1]),
    util.clamp(position[2], min[2], max[2])
  }
end

function View:setCamera(camera, position, scale)
  if type(scale) == "string" then
    scale = self:scale(camera, scale)
  end
  self:camera(camera).position = position
  self:camera(camera).scale = scale
end

-- takes world position transition and scale transition
-- interpolates scale and the calculated displayed position
function View:transitionCamera(camera, ratio, position, scale)
  scale[1] = self:scale(camera, scale[1])
  scale[2] = self:scale(camera, scale[2])
  camera = self:camera(camera)
  local movement = vec2.mul(vec2.sub(position[2], position[1]), scale[2])
  camera.scale = interp.linear(ratio, scale[1], scale[2])
  camera.position = vec2.add(position[1], vec2.div(vec2.mul(movement, interp.linear(ratio, 0, 1)), camera.scale))
end

function View:setSystemCamera(position, scale)
  self.systemCamera = {position = position, scale = scale}
end

function View:mousePosition()
  return self.canvas:mousePosition()
end

function View:uToScreen(position)
  return vec2.add(vec2.mul(vec2.sub(position, self.universeCamera.position), self.universeCamera.scale), vec2.mul(self.windowSize, 0.5))
end

function View:toUniverse(position)
  return vec2.add(vec2.div(vec2.sub(position, vec2.mul(self.windowSize, 0.5)), self.universeCamera.scale), self.universeCamera.position)
end

function View:sToScreen(position)
  return vec2.add(vec2.mul(vec2.sub(position, self.systemCamera.position), self.systemCamera.scale), vec2.mul(self.windowSize, 0.5))
end

function View:toSystem(position)
  return vec2.add(vec2.div(vec2.sub(position, vec2.mul(self.windowSize, 0.5)), self.systemCamera.scale), self.systemCamera.position)
end

function View:renderPlanet(args)
  self:drawWorld(args.planet)

  local planetPosition = celestial.planetPosition(args.planet)
  local moons = celestial.children(args.planet)
  for _,moon in pairs(moons) do
    local radius = vec2.mag(vec2.sub(celestial.planetPosition(moon), planetPosition)) * View.systemCamera.scale
    local color = self.settings.orbitColor
    View.canvas:drawPoly(self:circle(radius, self:sToScreen(planetPosition)), {color[1], color[2], color[3], args.orbitOpacity * color[4]}, 0.5)
    self:drawWorld(moon)
  end

  if args.drawObjects then
    self:renderSystemObjects(coordinateSystem(args.planet), args.mappedObjects, false)
  end

  if args.hover then
    local position = self:sToScreen(celestial.systemPosition(args.hover))
    View.canvas:drawImage(self.settings.hoverImage, position, 1, "white", true)
  end
end

function View:renderSystem(args, dt)
  local starImages = celestial.centralBodyImages(args.system)
  if #starImages > 0 then
    local starSize = celestial.planetSize(args.system)
    local imageSize = rect.size(root.nonEmptyRegion(starImages[1][1]))
    local scale = (starSize * View.systemCamera.scale) / imageSize[1]
    for _,i in pairs(starImages) do
      View.canvas:drawImage(i[1], self:sToScreen({0, 0}), scale, "white", true)
    end
  end

  for i,planet in pairs(args.planets) do
    local opacity = 1.0
    if args.fadePlanet and compare(planet, args.fadePlanet) then
      opacity = args.fadeOpacity
    end

    local parameters = args.planetParameters[i] or celestial.planetParameters(planet)
    args.planetParameters[i] = parameters
    if parameters and parameters.worldType == "Asteroids" then
      local count = args.asteroidCounts[i] or math.ceil(vec2.mag(celestial.planetPosition(planet)) * self.settings.asteroidBelt.density)
      self:drawAsteroidField(planet, count)
      args.asteroidCounts[i] = count
    else
      local radius = vec2.mag(celestial.planetPosition(planet)) * View.systemCamera.scale
      local color = self.settings.orbitColor
      View.canvas:drawPoly(self:circle(radius, self:sToScreen({0, 0})), {color[1], color[2], color[3], args.orbitOpacity * color[4]}, 0.5)
      local visitable = args.visitableParameters[i] or celestial.visitableParameters(planet)
      args.visitableParameters[i] = visitable
      self:drawSystemPlanet(planet, opacity, parameters, visitable)
    end

    local moons = celestial.children(planet)
    for j,moon in pairs(moons) do
      local parameters = args.planetParameters[i..j] or celestial.planetParameters(moon)
      args.planetParameters[i..j] = parameters
      local visitable = args.visitableParameters[i..j] or celestial.visitableParameters(moon)
      args.visitableParameters[i..j] = visitable
      self:drawSystemPlanet(moon, opacity, parameters, visitable)
    end
  end

  if args.drawObjects then
    self:renderSystemObjects(args.system, args.mappedObjects, true)
  end

  local getPosition = function(location)
    if compare(args.system, celestial.currentSystem()) then
      return celestial.systemPosition(location)
    elseif location[1] == "object" then
      return objectPosition(args.system, location[2])
    elseif location[1] == "coordinate" then
      return celestial.planetPosition(location[2])
    elseif type(location[1]) == "number" then
      return location
    end
  end

  if args.hover then
    local position = getPosition(args.hover)
    if position then
      View.canvas:drawImage(self.settings.hoverImage, self:sToScreen(position), 1, "white", true)
    end
  end
  if args.destination and compare(View.universeCamera.position[1],celestial.currentSystem().location[1]) and compare(View.universeCamera.position[2],celestial.currentSystem().location[2]) then
    if args.destination[1] == "orbit" then
      local position = celestial.planetPosition(args.destination[2].target)
      local radius = vec2.mag(args.destination[2].enterPosition) * self.systemCamera.scale
      local color = self.settings.playerDestinationOrbitColor
      View.canvas:drawPoly(self:circle(radius, self:sToScreen(position)), {color[1], color[2], color[3], args.orbitOpacity * color[4]}, 0.5)
    else
      local position = getPosition(args.destination)
      if position then
        for _,line in pairs(angledMarkerLines(1, 2, 0)) do
          View.canvas:drawLine(vec2.add(line[1], self:sToScreen(position)), vec2.add(line[2], self:sToScreen(position)), self.settings.positionMarkerColor, 1);
        end
      end
    end
  end
end

function View:renderSystemObjects(system, mappedObjects, doScale)
  local imageScale = View.systemCamera.scale / View:systemScale(system)
  local objectScale = doScale and imageScale * 0.5 or 0.5
  if compare(system, celestial.currentSystem()) then
    for uuid,object in pairs(self.tweenIn) do
      local position, angle, scale = object.inFunc(object, self.settings)
      View.canvas:drawImageDrawable(object.parameters.icon, self:sToScreen(position), objectScale * scale, "white", angle)
    end
    for uuid,object in pairs(self.objects) do
      local flip = object.direction[1] > 0 and 1 or -1
      local angle
      if object.moving then
        angle = math.atan(object.direction[2], math.abs(object.direction[1])) * flip
      else
        angle = vec2.angle(vec2.sub({0, 0}, object.position))
      end
      local color = "white"
      if not object.permanent and not object.player and player.mappedObjects(system)[uuid] then
        color = self.settings.visitedTempObjectColor
      end
      View.canvas:drawImageDrawable(object.parameters.icon, self:sToScreen(object.position), {objectScale * flip, objectScale}, color, angle)
    end
    for uuid,object in pairs(self.tweenOut) do
      local position, angle, scale = object.outFunc(object, self.settings)
      View.canvas:drawImageDrawable(object.parameters.icon, self:sToScreen(position), objectScale * scale, "white", angle)
    end
  end

  for uuid,object in pairs(mappedObjects) do
    local config = celestial.objectTypeConfig(object.typeName)
    if config.permanent then
      local position = celestial.orbitPosition(object.orbit)
      local direction = vec2.norm(vec2.rotate(position, object.orbit.direction * math.pi / 2))

      local flip = direction[1] > 0 and 1 or -1
      local angle = math.atan(direction[2], math.abs(direction[1])) * flip
      View.canvas:drawImageDrawable(config.parameters.icon, self:sToScreen(position), {objectScale * flip, objectScale}, "white", angle)
    end
  end
end

function View:renderPlayerShip(args, dt)
  local location = celestial.shipLocation()
  if location and location[1] == "object" then
    local position = self:sToScreen(celestial.objectPosition(location[2]))
    position = vec2.add(position, self.settings.positionMarkerOffset)
    View.canvas:drawImage(self.settings.positionMarkerImage, position, 0.5, "white", true)
  else
    local flip = self.player.direction[1] > 0 and 1 or -1
    local angle = math.atan(self.player.direction[2], math.abs(self.player.direction[1])) * flip
    local color = {100, 255, 100, args.opacity * 255}
    local position = self.player.position

    if self.playerWarpIn then
      local ratio = self.playerWarpIn / self.settings.playerWarpTime
      local distance = interp.linear(ratio ^ (1/4), self.settings.playerWarpDistance, 0)
      position = vec2.add(position, vec2.withAngle(vec2.angle(position), distance))
    end

    if location and (location[1] == "orbit" or location[1] == "coordinate") then
      local target = location[1] == "orbit" and location[2].target or location[2]

      local planetPosition = celestial.planetPosition(target)
      local radius = vec2.mag(vec2.sub(self.player.position, planetPosition)) * self.systemCamera.scale
      View.canvas:drawPoly(self:circle(radius, self:sToScreen(planetPosition)), self.settings.playerOrbitColor, 0.5)
    end

    View.canvas:drawImageDrawable(self.settings.playerShipIcon, self:sToScreen(position), {args.scale * 0.5 * flip, args.scale * 0.5}, color, angle)
  end
end

function View:renderStars(args, dt)
  local imageScale = View.universeCamera.scale / View:scale("universe", "universe");
  for _,line in pairs(args.lines) do
    local color = self.settings.constellationLineColor
    View.canvas:drawLine(self:uToScreen(line[1]), self:uToScreen(line[2]), {color[1], color[2], color[3], args.lineOpacity * color[4]}, 1.0)
  end

  for _,system in pairs(args.systems) do
    local opacity = 1.0
    if compare(system, args.currentSystem) then
      opacity = args.currentOpacity
    end
    local pos = self:uToScreen({system.location[1], system.location[2]})
    local color = {255, 255, 255, opacity * 255}
    for _,pair in pairs(celestial.starImages(system, View.twinkleTimer)) do
      View.canvas:drawImage(pair[1], pos, pair[2] * imageScale, color, true)
    end
  end

  if args.hoverSystem then
    local position = vec2.floor(self:uToScreen({args.hoverSystem.location[1], args.hoverSystem.location[2]}))
    View.canvas:drawImage(self.settings.hoverImage, position, 1, "white", true)
  end
  if args.currentSystem and args.displayMarker then
    local position = vec2.floor(self:uToScreen({args.currentSystem.location[1], args.currentSystem.location[2]}))
    position = vec2.add(position, self.settings.positionMarkerOffset)
    View.canvas:drawImage(self.settings.positionMarkerImage, position, 0.5, "white", true)
  end
end

function View:renderTravel(args, dt)
  args.lastPosition = args.lastPosition or copy(self.universeCamera.position)

  local prevRegion = self:systemScanRegion(args.lastPosition)
  local region = self:systemScanRegion()
  local regionSize = rect.size(region)
  local movement = vec2.sub(self.universeCamera.position, args.lastPosition)

  for _,line in pairs(args.lines) do
    local color = self.settings.constellationLineColor
    View.canvas:drawLine(self:uToScreen(line[1]), self:uToScreen(line[2]), {color[1], color[2], color[3], args.lineOpacity * color[4]}, 1.0)
  end

  if args.travelLine then
    if args.travelLineTimer == nil then args.travelLineTimer = 0 end
    args.travelLineTimer = args.travelLineTimer + dt

    local line = {
      args.travelLine[1],
      args.travelLine[2]
    }
    local dir = vec2.norm(vec2.sub(line[2], line[1]))
    if not rect.contains(region, line[1]) then
      line[1] = vec2.add(self.universeCamera.position, vec2.withAngle(vec2.angle(dir) + math.pi, vec2.mag(regionSize)))
    end
    if not rect.contains(region, line[2]) then
      line[2] = vec2.add(self.universeCamera.position, vec2.withAngle(vec2.angle(dir), vec2.mag(regionSize)))
    end

    line = {
      self:uToScreen(line[1]),
      self:uToScreen(line[2])
    }
    local lines = dashedLine(line, self.settings.travelLine.dash, self.settings.travelLine.gap, 1 - (args.travelLineTimer * 2), "white", 1.0)
    for _,l in pairs(lines) do
      View.canvas:drawLine(l[1], l[2], self.settings.travelLine.color, 1.0)
    end
  end

  local stepDistance = 3
  local trailSteps = math.max(1, math.min(math.floor(vec2.mag(movement) / stepDistance), 8))
  local trailDirection = vec2.norm(vec2.mul(movement, 1))
  for _,star in pairs(args.stars) do
    local system, pos = star[1], star[2]
    if #args.finalStars == 0 or not rect.contains(args.finalRegion, pos) then
      if not rect.contains(region, pos) then
        if pos[1] < region[1] then
          pos[1] = region[3] - (math.random() * math.min(regionSize[1], movement[1]))
          pos[2] = region[2] + (math.random() * (region[4] - region[2]))
        elseif pos[1] > region[3] then
          pos[1] = region[1] - (math.random() * math.max(-regionSize[1], movement[1]))
          pos[2] = region[2] + (math.random() * (region[4] - region[2]))
        elseif pos[2] < region[2] then
          pos[1] = region[1] + (math.random() * (region[3] - region[1]))
          pos[2] = region[4] - (math.random() * math.min(regionSize[2], movement[2]))
        elseif pos[2] > region[4] then
          pos[1] = region[1] + (math.random() * (region[3] - region[1]))
          pos[2] = region[2] - (math.random() * math.max(-regionSize[2], movement[2]))
        end
      end
      pos = self:uToScreen(pos)
      for _,pair in pairs(celestial.starImages(system, View.twinkleTimer)) do
        for i = 1, trailSteps do
          local opacity = ((trailSteps - (i - 1)) / trailSteps) * 255
          local color = {255, 255, 255, opacity}
          View.canvas:drawImage(pair[1], vec2.add(pos, vec2.mul(trailDirection, (i - 1) * stepDistance)), pair[2], color, true)
        end
      end
    end
  end

  if #args.finalStars > 0 and rect.intersects(region, args.finalRegion) then
    for _,system in pairs(args.finalStars) do
      local pos = systemPosition(system)
      if rect.contains(region, pos) then
        pos = self:uToScreen(pos)
        for _,pair in pairs(celestial.starImages(system, View.twinkleTimer)) do
          for i = 1, trailSteps do
            local opacity = ((trailSteps - (i - 1)) / trailSteps) * 255
            local color = {255, 255, 255, opacity}
            View.canvas:drawImage(pair[1], vec2.add(pos, vec2.mul(trailDirection, (i - 1) * stepDistance)), pair[2], color, true)
          end
        end
      end
    end
  end

  if args.currentSystem and args.displayMarker then
    local position = vec2.floor(self:uToScreen({args.currentSystem.location[1], args.currentSystem.location[2]}))
    position = vec2.add(position, self.settings.positionMarkerOffset)
    View.canvas:drawImage(self.settings.positionMarkerImage, position, 0.5, "white", true)
  end

  -- local ll = self:uToScreen(rect.ll(args.finalRegion))
  -- local ur = self:uToScreen(rect.ur(args.finalRegion))
  -- self.canvas:drawLine(ll, {ll[1], ur[2]}, "yellow")
  -- self.canvas:drawLine({ll[1], ur[2]}, ur, "yellow")
  -- self.canvas:drawLine(ur, {ur[1], ll[2]}, "yellow")
  -- self.canvas:drawLine({ur[1], ll[2]}, ll, "yellow")

  args.lastPosition = self.universeCamera.position
end

function View:renderBackground()
  local center = {-self.universeCamera.position[1] % self.settings.backgroundSize[1], -self.universeCamera.position[2] % self.settings.backgroundSize[2]}
  -- get the lower left texture offset from the center of the screen
  -- this is way more complicated than it should be
  local offset = vec2.add(vec2.mul(center, self.backgroundScale), vec2.mul(vec2.div(self.windowSize, 2), (1.0 - self.backgroundScale)))

  local screenCoords = {0, 0, self.windowSize[1], self.windowSize[2]}
  for _,background in pairs(self.settings.backgrounds) do
    self.canvas:drawTiledImage(background, offset, screenCoords, self.backgroundScale, self.settings.backgroundColor)
  end
end

function View:drawSystemPlanet(planet, opacity, parameters, visitable)
  local position = celestial.planetPosition(planet)
  local color = {255, 255, 255, opacity * 255}
  local planetSize = celestial.planetSize(planet)

  if parameters and parameters.worldType == "FloatingDungeon" then
    local images = celestial.planetaryObjectImages(planet)
    for _,image in pairs(images) do
      local scale = (planetSize * self.systemCamera.scale) / root.imageSize(image[1])[1]
      self.canvas:drawImage(image[1], self:sToScreen(position), scale, color, true)
    end
  else
    if planetSize then
      local image
      if parameters and parameters.worldType == "GasGiant" then
        image = "/interface/cockpit/planets/gasgiant.png"
      elseif visitable then
        image = string.format("/interface/cockpit/planets/%s.png", visitable.typeName)
      else
        image = config.getParameter("planetSmallImage")
      end

      local scale = (planetSize * self.systemCamera.scale) / root.imageSize(image)[1]
      self.canvas:drawImage(image, self:sToScreen(position), scale, color, true)
    end
  end
end

function View:drawAsteroidField(planet, count)
  local seed = sb.staticRandomI32(string.format("%s.%s.%s.%s", planet.location[1], planet.location[2], planet.location[3], planet.planet))
  local rand = sb.makeRandomSource(seed)

  local anchor = celestial.planetPosition(planet)
  local center = self:sToScreen({0, 0})
  for i = 1, count do
    local angleOffset = (rand:randf() - 0.5) * (math.pi * 2 / count)
    local distanceOffset = (rand:randf() * self.settings.asteroidBelt.distanceOffset - (self.settings.asteroidBelt.distanceOffset / 2))
    local angle = vec2.angle(anchor) + (i * (math.pi * 2 / count) + angleOffset)
    local position = vec2.add(center, vec2.mul(vec2.withAngle(angle, vec2.mag(anchor) + distanceOffset), self.systemCamera.scale))
    local scale = self.systemCamera.scale
    local image = self.settings.asteroidImages[rand:randInt(1, #self.settings.asteroidImages)]
    self.canvas:drawImageDrawable(image, position, scale, {255, 255, 255}, rand:randf() * math.pi * 2)
  end
end

function View:drawWorld(object)
  local position = celestial.planetPosition(object)
  local planetSize = celestial.planetSize(object)
  if planetSize then
    local images = celestial.worldImages(object)
    local scale = (planetSize * self.systemCamera.scale) / root.imageSize(images[1][1])[1]
    for i,image in pairs(images) do
      self.canvas:drawImageDrawable(image[1], self:sToScreen(position), scale, "white", angle)
    end
  end
end
