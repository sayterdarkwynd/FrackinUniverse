require "/scripts/util.lua"
require "/interface/games/util.lua"
require "/scripts/vec2.lua"
require "/interface/games/fossilgame/generator.lua"
require "/interface/games/fossilgame/tools.lua"
require "/interface/games/fossilgame/tileset.lua"
require "/interface/games/fossilgame/ui.lua"

function init()
  gameCanvas = widget.bindCanvas("gameCanvas")

  self.toolButtonSet = RadioButtonSet:new()

  world.sendEntityMessage(pane.sourceEntity(), "setInUse", true)

  getFossilParameters()

  initGame()

  self.state = FSM:new()
  self.state:set(playState)
end

-- Init
function getFossilParameters()
  local fossilId = pane.sourceEntity()

  local fossilPool = root.createTreasure(world.getObjectParameter(fossilId, "fossilPool"), world.threatLevel())
  self.fossilItem = fossilPool[1].name

  local treasure = world.getObjectParameter(fossilId, "treasure")
  self.treasureType = treasure.type

  local treasurePool = treasure.pool
  if treasurePool then
    local treasure = root.createTreasure(treasurePool, world.threatLevel())
    self.treasureItem = treasure[1]
    local config = root.itemConfig(self.treasureItem)
    self.treasureIcon = util.absolutePath(config.directory, config.config.inventoryIcon)
  end

  self.treasureComplete = false

  local materials = world.getObjectParameter(fossilId, "materials")
  self.tileData = {}
  for _, material in ipairs(materials) do
    local materialConfig = root.materialConfig(material)
    local texture = util.absolutePath(util.pathDirectory(materialConfig.path), materialConfig.config.renderParameters.texture)
    table.insert(self.tileData, {texturePath = texture, variants = materialConfig.config.renderParameters.variants or 1})
  end
end

function initGame()
  self.drawActions = {}

  local treasureTypes = config.getParameter("treasureConfig")
  local treasure = treasureTypes[self.treasureType]

  local generator = LevelGenerator:new({SquareTool, CrossTool}, treasure)

  generator.toolRockChance = config.getParameter("toolRockChance", 0.5)
  generator.randomRockChance = config.getParameter("randomRockChance", 0.3)

  local size = {10, 9}
  local position = {30, 39}

  local level, toolUses = generator:generate(size, 16, position, self.tileData[1], self.tileData[2], self.tileData[3], treasure)
  self.level = level

  if config.getParameter("toolType") == "ultra" then
    self.tools = {
      BrushTool:new(self.level),
      SquareTool:new(self.level, 2),
      TLeft:new(self.level, 2),
      TRight:new(self.level , 2),
      Dot:new(self.level, 2)
    }
  elseif config.getParameter("toolType") == "master" then
    self.tools = {
      BrushTool:new(self.level),
      SquareTool:new(self.level, 0),
      TLeft:new(self.level, 0),
      TRight:new(self.level, 0),
      Dot:new(self.level, 0)
    }    
  elseif config.getParameter("toolType") == "student" then
    self.tools = {
      BrushTool:new(self.level),
      VRect:new(self.level, 0),
      HRect:new(self.level, 0),
      CrossTool:new(self.level, 0)
    }
  else
    self.tools = {
      BrushTool:new(self.level),
      SquareTool:new(self.level, 0),
      CrossTool:new(self.level, 0)
    }
  end

  for _,tool in pairs(self.tools) do
    tool.uses = tool:calculateUses(toolUses)
  end

  initGui(self.tools)
end

function initGui(tools)
  local buttonOrigin = {218, 89}
  local buttonPos = {0, 0}
  local maxWidth = 90

  local buttonSpacingH = 1
  local buttonSpacingV = 2

  for _,tool in pairs(tools) do
    local buttonRect = {buttonOrigin[1] + buttonPos[1], buttonOrigin[2] + buttonPos[2]}
    local newButton = ToggleButton:new(tool.buttonIcon, tool.buttonBackground, buttonRect)
    newButton.data = tool

    self.toolButtonSet:add(newButton)

    buttonPos[1] = buttonPos[1] + newButton.size[1] + buttonSpacingH
    if buttonPos[1] >= maxWidth then
      buttonPos[1] = 0;
      buttonPos[2] = buttonPos[2] - newButton.size[2] - buttonSpacingV
    end
  end

  self.frame = Sprite:new("/interface/games/fossilgame/images/frame.png", {314, 221})
  self.fossilCounter = Sprite:new("/interface/games/fossilgame/images/fossilcountericon.png", {21, 21}, {1, 1})
  self.treasureIndicator = Sprite:new("/interface/games/fossilgame/treasurechest.png", {16, 16}, {1, 1})
  self.winScreen = Sprite:new("/interface/games/fossilgame/images/winningframe.png", {314, 221})
  self.loseScreen = Sprite:new("/interface/games/fossilgame/images/losingframe.png", {314, 221})
  self.incompleteScreen = Sprite:new("/interface/games/fossilgame/images/incompleteframe.png", {314, 221})
end

function update(dt)
  if not self.hideCursor then
    activeTool():update(dt)
  end
  self.level:update(dt)

  self.state:update(dt)

  draw()
end

-- Game states

function playState(dt)
  while true do
    if not activeTool():animating() then
      -- lose conditions
      if self.level.fossilDamaged then
        self.state:set(loseState)
      end
      if toolUsesRemaining() == 0 and self.level:fossilCoveredByRock() then
        self.state:set(incompleteState)
      end

      -- win conditions
      if self.level:fossilUncovered() then
        if not self.level.hasTreasure
          or self.level:treasureUncovered()
          or (toolUsesRemaining() == 0 and self.level:treasureCoveredByRock()) then
            self.state:set(winState)
        end
      end
    end

    coroutine.yield()
  end

  self.state:set(winState)
end

function loseState()
  self.hideCursor = true

  clearBoard()
  pane.playSound(config.getParameter("loseSound"))

  util.wait(1.0)

  self.level:removeFossil()
  self.level:removeTreasure()

  util.wait(2.0)

  util.wait(5.0, function()
    drawSprite(self.loseScreen, {0, 0}, "foreground")
  end)

  pane.dismiss()
end

function incompleteState()
  self.hideCursor = true

  clearBoard()

  util.wait(1.0)

  pane.playSound(config.getParameter("incompleteSound"))

  util.wait(1.0)

  util.wait(5.0, function()
    drawSprite(self.incompleteScreen, {0, 0}, "foreground")
  end)

  pane.dismiss()
end

function winState()
  self.hideCursor = true

  -- Check for treasure
  if self.level:treasureUncovered() then
    pane.playSound(config.getParameter("treasureFoundSound"))
    self.treasureUncovered = true

    util.wait(1.0)

    self.level:removeTreasure(
    pane.playSound(config.getParameter("treasureOpenSound")))

    local treasurePos = self.level:screenPosition(self.level.treasurePos)
    local timer, interval, bobHeight, hoverTime, fadeTime = 0, 0.5, 4, 2.5, 1.5
    local treasureIcon = Sprite:new(self.treasureIcon)
    local size = vec2.mul(self.level.treasure.size, self.level.tileSize)
    treasureIcon:fitToBox(size[1] - 8, size[2] - 8)
    while timer < hoverTime do
      timer = timer + script.updateDt()
      local ratio = math.sin((timer % interval) / interval * math.pi)
      if timer > fadeTime then
        local opacity = (1 - ((timer - fadeTime) / (hoverTime - fadeTime))) * 255
        treasureIcon.color = {255, 255, 255, math.min(opacity, 255)}
      end
      drawSprite(treasureIcon, vec2.add(vec2.add(treasurePos, {4, 4}), {0, bobHeight * ratio}), "middle")
      coroutine.yield()
    end

    world.sendEntityMessage(pane.sourceEntity(), "addDrop", self.treasureItem)
  end

  world.sendEntityMessage(pane.sourceEntity(), "addDrop", self.fossilItem)

  clearBoard()

  util.wait(0.5)

  if not self.treasureUncovered then
    self.level:removeTreasure()
  end

  util.wait(0.5)

  pane.playSound(config.getParameter("winSound"))

  util.wait(2.0)

  local treasureIcon, treasurePos
  if self.treasureIcon then
    treasureIcon = Sprite:new(self.treasureIcon)
    treasureIcon:fitToBox(32, 32)
    treasurePos = {157 - (treasureIcon.size[1] * treasureIcon.scale) / 2, 68 - treasureIcon.size[2] * treasureIcon.scale}
  end

  local fossilIcon = Sprite:new(root.itemConfig(self.fossilItem).config.displayImage)
  fossilIcon:fitToBox(120, 66)
  local fossilPos = {157 - (fossilIcon.size[1] * fossilIcon.scale) / 2, 160 - fossilIcon.size[2] * fossilIcon.scale}

  -- Draw splash screen
  util.wait(5.0, function()
    drawSprite(self.winScreen, {0, 0}, "foreground")

    drawSprite(fossilIcon, fossilPos, "foreground")
    local name = root.itemConfig(self.fossilItem).config.shortdescription
    drawText(name, {position = {157, 170}, width = 88, horizontalAnchor = "mid"}, 12, "foreground")

    if self.treasureUncovered then
      drawSprite(treasureIcon, treasurePos, "foreground")

      local name = root.itemConfig(self.treasureItem).config.shortdescription
      drawText(name, {position = {157, 80}, width = 88, horizontalAnchor = "mid"}, 10, "foreground")
    end
  end)

  pane.dismiss()
end

-- Helpers

function clearBoard()
  for y = 0, self.level.size[2] - 1 do
    local removed = false
    for x = 0, self.level.size[1] - 1 do
      local pos = {x, y}
      if self.level:rockAt(pos) then
        removed = true
        self.level:removeRock(pos)
      end
    end
    if removed then
      util.wait(0.1)
      pane.playSound(config.getParameter("clearRockSound"), 0, 0.5)
    end
  end

  for y = 0, self.level.size[2] - 1 do
    local removed = false
    for x = 0, self.level.size[1] - 1 do
      local pos = {x, y}
      if self.level:dirtAt(pos) then
        removed = true
        self.level:removeDirt(pos)
      end
    end
    if removed then
      util.wait(0.1)
      pane.playSound(config.getParameter("clearDirtSound"))
    end
  end
end

function activeTool()
  return self.toolButtonSet:data()
end

function toolUsesRemaining()
  local count = 0
  --count starts at 2 because we don't want to include the brush
  for _,tool in pairs(self.tools) do
    if tool.uses > -1 then
      count = count + tool.uses
    end
  end
  return count
end

-- Drawing

function drawSprite(sprite, position, layer)
  table.insert(self.drawActions, {type = "sprite", sprite = sprite, position = position, layer = layer})
end

function drawText(text, parameters, size, layer)
  table.insert(self.drawActions, {type = "text", text = text, parameters = parameters, size = size, layer = layer})
end

function doDrawAction(action)
  if action.type == "sprite" then
    action.sprite:draw(action.position)
  elseif action.type == "text" then
    gameCanvas:drawText(action.text, action.parameters, action.size)
  end
end

function draw()
  gameCanvas:clear()

  for _,action in ipairs(util.filter(self.drawActions, function(s) return s.layer == "background" end)) do
    doDrawAction(action)
  end

  self.level:draw()

  for _,action in ipairs(util.filter(self.drawActions, function(s) return s.layer == "middle" end)) do
    doDrawAction(action)
  end

  self.level:drawParticles()

  drawGui()

  for _,action in ipairs(util.filter(self.drawActions, function(s) return s.layer == "foreground" end)) do
    doDrawAction(action)
  end

  if not self.hideCursor then
    activeTool():draw()
  end

  self.drawActions = {}
end

function drawGui()
  self.frame:draw({0, 0})

  gameCanvas:drawText("EXCAVATION", {position = {230, 183}, width = 88}, 12)
  gameCanvas:drawText("PROGRESS", {position = {235, 171}, width = 88}, 12)
  local progressColor = {255,255,255}
  if self.level.fossilDamaged then
    progressColor = {255, 0, 0}
  end
  gameCanvas:drawText(self.level.progress .. "/" .. #self.level.fossilTiles, {position = {255, 153}}, 12, progressColor)
  self.fossilCounter:draw({225, 136})

  if (self.treasureComplete) then
    self.treasureIndicator:draw({285, 140})
  end

  self.toolButtonSet:draw()

  for i,button in pairs(self.toolButtonSet.buttons) do
    local tool = button.data
    if tool.uses >= 0 then
      local textCol = self.tools[i].uses == 0 and {255, 0, 0} or {255, 255, 255}
      local textPos = {button.position[1] + button.size[1] - 8, button.position[2] + 8}
      gameCanvas:drawText(tool.uses, {position = textPos}, 8, textCol)
    end
  end
end

-- Canvas callbacks

function mousePosition()
  local position = gameCanvas:mousePosition()
  position[1] = position[1] - 1
  return position
end

function canvasClickEvent(position, button, isButtonDown)
  if isButtonDown then
    -- sb.logInfo("Button %s was pressed at %s", button, position)
    if self.splash then
      sb.logInfo("dismissing in canvasClickEvent")
      pane.dismiss()
    else
      if not activeTool():animating() then
        activeTool():trigger()
        self.toolButtonSet:handleClick({position = position, button = button})
      end
    end
  else
    -- sb.logInfo("Button %s was released at %s", button, position)
    activeTool():release()
  end
end

function canvasKeyEvent(key, isKeyDown)
  if isKeyDown then
    if not activeTool():animating() then
      if key == 21 then
        self.toolButtonSet:selectIndex(1)
      end
      if key == 22 then
        self.toolButtonSet:selectIndex(2)
      end
      if key == 23 then
        self.toolButtonSet:selectIndex(3)
      end
      if key == 24 then
        self.toolButtonSet:selectIndex(4)
      end
      if key == 25 then
        self.toolButtonSet:selectIndex(5)
      end
    end
  end
end

function dismissed()
  world.sendEntityMessage(pane.sourceEntity(), "smash")

  world.sendEntityMessage(config.getParameter("ownerId"), "fossilGameClosed")
end
