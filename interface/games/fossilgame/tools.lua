require "/scripts/vec2.lua"
require "/interface/games/fossilgame/sprite.lua"

Tool = {}
Tool.name = "Tool"
Tool.area = {{0,0}}
Tool.size = {1,1}
Tool.sprite = Sprite:new("/interface/games/fossilgame/images/brushtool.png", {16,16}, {2,1}, 2)

function Tool:new(tileLevel, uses)
  local newTool = {
    level = tileLevel,
    uses = uses or 0,
    frame=1,
    triggerPosition = {0,0},
    tileList={}
  }
  setmetatable(newTool, extend(self))
  return newTool
end

function Tool:release()
end

function Tool:update(dt)
  self.tileList = self:hoverTiles()

  local volume = hit and 1.0 or 0.4

  if self:updateAnimation(dt) then
    self:strike(self.triggerPosition)
  end
end

function Tool:startAnimation(loop)
  self.animationLoops = loop or false
  self.animationTimer = self.animationTimer or 0
end

function Tool:updateAnimation(dt)
  self.frame = self.cursorFrame
  if self.animationTimer then
    local prevFrame = math.floor((self.animationTimer / self.animationSpeed) * #self.frames) + 1
    if self.animationTimer == 0 then prevFrame = 0 end

    self.animationTimer = self.animationTimer + dt
    if self.animationTimer > self.animationSpeed then
      if self.animationLoops then
        self.animationTimer = self.animationTimer - self.animationSpeed
      else
        self:stopAnimation()
        return false
      end
    end
    local frame = math.floor((self.animationTimer / self.animationSpeed) * #self.frames) + 1
    self.frame = self.frames[frame]

    -- Edge triggered sounds
    if frame ~= prevFrame then
      local soundIndex = self.soundTriggerSequence[frame]
      if soundIndex and self.sound[soundIndex] then
        pane.playSound(self.sound[soundIndex], 0, volume)
      end
      if frame == self.strikeFrame then return true end
    end
  end
  return false
end

function Tool:animating()
  return self.animationTimer ~= nil
end

function Tool:stopAnimation()
  self.animationTimer = nil
end

function Tool:hoverTiles()
  local tiles = {}
  for _,offset in ipairs(self.area) do
    local screenOffset = {offset[1] * self.level.tileSize, offset[2] * self.level.tileSize}
    local screenTilePos = vec2.add(self:position(), screenOffset)
    local tilePos = self.level:tilePosition(screenTilePos)
    if tilePos == false then
      return {}
    end
    table.insert(tiles, tilePos)
  end
  return tiles
end

function Tool:tileArea(tilePosition)
  local area = {}
  local offset = {0,0}
  for _,tile in pairs(self.area) do
    tile = {math.floor(tile[1]), math.floor(tile[2])}
    if tile[1] < -offset[1] then
      offset[1] = -tile[1]
    end
    if tile[2] < -offset[2] then
      offset[2] = -tile[2]
    end
    table.insert(area, tile)
  end
  for k,tile in pairs(area) do
    area[k] = vec2.add(tile, offset)
  end
  return area
end

function Tool:position()
  if self.animationTimer then
    return self.triggerPosition
  else
    return mousePosition()
  end
end

function Tool:canUse()
  return self.uses > 0 or self.uses == -1
end

function Tool:draw()
  if self:canUse() and not self.animationTimer then
    for _,tile in ipairs(self.tileList) do
      local screenX = tile[1] * self.level.tileSize + self.level.position[1]
      local screenY = tile[2] * self.level.tileSize + self.level.position[2]
      gameCanvas:drawRect({screenX, screenY, screenX + self.level.tileSize, screenY + self.level.tileSize}, {255, 255, 255, 100})
    end
  end

  if self.sprite then
    self.sprite:setCell(self.frame-1)
    self.sprite:draw(self:position())
  end
end

function Tool:trigger()
  if self:canUse() and #self.tileList>0 then
    self.triggerPosition = mousePosition()
    self:startAnimation()
  end
end

function Tool:strike()
  if #self.tileList > 0 then
    self.uses = self.uses - 1
    for _,tile in ipairs(self.tileList) do
      if self.level:rockAt(tile) then
        self.level:removeRock(tile)
      else
        if self.level:dirtAt(tile) then
          self.level:removeDirt(tile)
        end
        if self.level:fossilAt(tile) then
          self.level:damageFossil()
        end
        if self.level:treasureAt(tile) then
          self.level:removeTreasure()
        end
      end
    end
  end
end

function Tool:calculateUses(toolUses)
  for toolName,uses in pairs(toolUses) do
    if self.name == toolName then
      return uses or 0
    end
  end
  return 0
end

---------------------------------------

BrushTool = Tool:new()
BrushTool.name = "Brush"
BrushTool.cursorFrame = 2
BrushTool.animationSpeed = 0.3
BrushTool.frames = {3,2,1,2}
BrushTool.soundTriggerSequence = {}
BrushTool.strikeFrame = 1

BrushTool.sprite = Sprite:new("/interface/games/fossilgame/images/brushtool.png", {20,20}, {3,1}, 3)
BrushTool.buttonIcon = "/interface/games/fossilgame/images/brushicon.png"
BrushTool.buttonBackground = "/interface/games/fossilgame/images/fullbutton.png"
BrushTool.sprite.origin = {10,-1}
BrushTool.sprite.scale = 2
BrushTool.sound = "/sfx/blocks/footstep_sand2.ogg"

function BrushTool:trigger()
  self:startAnimation(true)
  if self:canUse() and #self.tileList>0 then
    self.firing = true
  end
end

function BrushTool:release()
  self:stopAnimation()
  self.firing = false
end

function BrushTool:update(dt)
  self.triggerPosition = mousePosition()

  self.tileList = self:hoverTiles()
  self:updateAnimation(dt)

  if self.firing then
    if self:strike() then
      pane.playSound(self.sound)
    end
  end
end

function BrushTool:strike()
  local removed = false
  if #self.tileList > 0 then
    for _,tile in ipairs(self.tileList) do
      if not self.level:rockAt(tile) and self.level:dirtAt(tile) then
        self.level:removeDirt(tile)
        removed = true
      end
    end
  end
  return removed
end

function BrushTool:calculateUses(toolUses)
  return -1
end

----------------------

SquareTool = Tool:new()
SquareTool.name = "Square"
SquareTool.area = {{-0.5, -0.5}, {0.5, -0.5}, {-0.5, 0.5}, {0.5, 0.5}}
SquareTool.size = {2,2}

SquareTool.cursorFrame=1
SquareTool.animationSpeed = 0.5
SquareTool.frames={2,1,2,1}
SquareTool.soundTriggerSequence={1,0,1,0}
SquareTool.strikeFrame=3

SquareTool.sprite = Sprite:new("/interface/games/fossilgame/images/hammertool.png", {20,20}, {3,1}, 3)
SquareTool.buttonIcon = "/interface/games/fossilgame/images/squareicon.png"
SquareTool.buttonBackground = "/interface/games/fossilgame/images/halfbutton.png"
SquareTool.sprite.origin = {0,0}
SquareTool.sprite.scale = 2
SquareTool.sound = {"/sfx/tools/pickaxe_hit.ogg"}


----------------------

CrossTool = Tool:new()
CrossTool.name = "Cross"
CrossTool.area = {{0,0},{1,0},{-1,0},{0,1},{0,-1}}
CrossTool.size = {3,3}

CrossTool.cursorFrame=1
CrossTool.animationSpeed = 1.25
CrossTool.frames={1,2,2,3,3}
CrossTool.soundTriggerSequence={1,0,0,0,2}
CrossTool.strikeFrame=5

CrossTool.sprite = Sprite:new("/interface/games/fossilgame/images/dynamitetool.png", {20,20}, {3,1}, 3)
CrossTool.buttonIcon = "/interface/games/fossilgame/images/crossicon.png"
CrossTool.buttonBackground = "/interface/games/fossilgame/images/halfbutton.png"
CrossTool.sprite.origin = {0,0}
CrossTool.sprite.scale = 2
CrossTool.sound = {"/sfx/projectiles/acid_hit.ogg","/sfx/projectiles/blast_small1.ogg"}

----------------------

VRect = Tool:new()
VRect.name = "VRect"
VRect.area = {{0, -0.5}, {0, 0.5}}
VRect.size = {1,2}

VRect.cursorFrame=1
VRect.animationSpeed = 0.4
VRect.frames={2,1,2,1}
VRect.soundTriggerSequence={1,0,1,0}
VRect.strikeFrame=3

VRect.sprite = Sprite:new("/interface/games/fossilgame/images/mattockvrect.png", {20,20}, {3,1}, 3)
VRect.buttonIcon = "/interface/games/fossilgame/images/vrecticon.png"
VRect.buttonBackground = "/interface/games/fossilgame/images/halfbutton.png"
VRect.sprite.origin = {0,0}
VRect.sprite.scale = 2
VRect.sound = {"/sfx/tools/pickaxe_hit.ogg"}

function VRect:calculateUses(toolUses)
  for toolName,uses in pairs(toolUses) do
    if toolName=="Square" then
      return uses
    end
  end
end

----------------------

HRect = Tool:new()
HRect.name = "HRect"
HRect.area = {{-0.5,0}, {0.5,0}}
HRect.size = {1,2}

HRect.cursorFrame=1
HRect.animationSpeed = 0.4
HRect.frames={2,1,2,1}
HRect.soundTriggerSequence={1,0,1,0}
HRect.strikeFrame=3

HRect.sprite = Sprite:new("/interface/games/fossilgame/images/mattockhrect.png", {20,20}, {3,1}, 3)
HRect.buttonIcon = "/interface/games/fossilgame/images/hrecticon.png"
HRect.buttonBackground = "/interface/games/fossilgame/images/halfbutton.png"
HRect.sprite.origin = {0,0}
HRect.sprite.scale = 2
HRect.sound = {"/sfx/tools/pickaxe_hit.ogg"}

function HRect:calculateUses(toolUses)
  for toolName,uses in pairs(toolUses) do
    if toolName=="Square" then
      return uses
    end
  end
end

----------------------

TLeft = Tool:new()
TLeft.name = "TLeft"
TLeft.area = {{0,0},{-1,0},{0,1},{0,-1}}
TLeft.size = {3,3}

TLeft.cursorFrame=2
TLeft.animationSpeed = 0.8
TLeft.frames={1,1,2,3,2,3,2,3}
TLeft.soundTriggerSequence={0,0,0,1,0,1,0,1}
TLeft.strikeFrame=7

TLeft.sprite = Sprite:new("/interface/games/fossilgame/images/drilltooltleft.png", {20,20}, {3,1}, 3)
TLeft.buttonIcon = "/interface/games/fossilgame/images/tlefticon.png"
TLeft.buttonBackground = "/interface/games/fossilgame/images/halfbutton.png"
TLeft.sprite.origin = {0,0}
TLeft.sprite.scale = 2
TLeft.sound = {"/sfx/tools/pickaxe_orebckup.ogg"}


function TLeft:calculateUses(toolUses)
  for toolName,uses in pairs(toolUses) do
    if toolName=="Cross" then
      return math.floor(uses / 2)
    end
  end
end

----------------------

TRight = Tool:new()
TRight.name = "TRight"
TRight.area = {{0,0},{1,0},{0,1},{0,-1}}
TRight.size = {3,3}

TRight.cursorFrame=2
TRight.animationSpeed = 0.8
TRight.frames={1,1,2,3,2,3,2,3}
TRight.soundTriggerSequence={0,0,0,1,0,1,0,1}
TRight.strikeFrame=7

TRight.sprite = Sprite:new("/interface/games/fossilgame/images/drilltooltright.png", {20,20}, {3,1}, 3)
TRight.buttonIcon = "/interface/games/fossilgame/images/trighticon.png"
TRight.buttonBackground = "/interface/games/fossilgame/images/halfbutton.png"
TRight.sprite.origin = {16,0}
TRight.sprite.scale = 2
TRight.sound = {"/sfx/tools/pickaxe_orebckup.ogg"}


function TRight:calculateUses(toolUses)
  for toolName,uses in pairs(toolUses) do
    if toolName=="Cross" then
      return math.ceil(uses / 2)
    end
  end
end

----------------------

Dot = Tool:new()
Dot.name = "Dot"
Dot.area = {{0,0}}
Dot.size = {1,1}

Dot.cursorFrame=1
Dot.animationSpeed = 0.4
Dot.frames={2,3,2,3}
Dot.soundTriggerSequence={1,0,1,0}
Dot.strikeFrame=3

Dot.sprite = Sprite:new("/interface/games/fossilgame/images/chiseltool.png", {20,20}, {3,1}, 3)
Dot.buttonIcon = "/interface/games/fossilgame/images/doticon.png"
Dot.buttonBackground = "/interface/games/fossilgame/images/halfbutton.png"
Dot.sprite.origin = {0,0}
Dot.sprite.scale = 2
Dot.sound = {"/sfx/tools/pickaxe_orebckup.ogg"}


function Dot:calculateUses(toolUses)
  for toolName,uses in pairs(toolUses) do
    if toolName=="Cross" then
      return uses
    end
  end
end

----------------------

Dot2 = Tool:new()
Dot2.name = "Dot2"
Dot2.area = {{0,0}}
Dot2.size = {1,1}

Dot2.cursorFrame=1
Dot2.animationSpeed = 0.4
Dot2.frames={2,3,2,3}
Dot2.soundTriggerSequence={1,0,1,0}
Dot2.strikeFrame=3

Dot2.sprite = Sprite:new("/interface/games/fossilgame/images/chiseltool.png", {20,20}, {3,1}, 3)
Dot2.buttonIcon = "/interface/games/fossilgame/images/doticon.png"
Dot2.buttonBackground = "/interface/games/fossilgame/images/halfbutton.png"
Dot2.sprite.origin = {0,0}
Dot2.sprite.scale = 2
Dot2.sound = {"/sfx/tools/pickaxe_orebckup.ogg"}


function Dot2:calculateUses(toolUses)
  for toolName,uses in pairs(toolUses) do
    if toolName=="Square" then
      return math.ceil(uses + 2)
    end
  end
end

----------------------

ExTool = Tool:new()
ExTool.name = "ExTool"
ExTool.area = {{0,0},{-1,-1},{-1,0},{-1,1},{0,1},{1,1},{1,0},{1,-1},{0,-1}}
ExTool.size = {3,3}

ExTool.cursorFrame=1
ExTool.animationSpeed = 0.4
ExTool.frames={2,1,2,1}
ExTool.soundTriggerSequence={1,0,1,0}
ExTool.strikeFrame=3

ExTool.sprite = Sprite:new("/interface/games/fossilgame/images/mattockhrect.png", {20,20}, {3,1}, 3)
ExTool.buttonIcon = "/interface/games/fossilgame/images/extoolicon.png"
ExTool.buttonBackground = "/interface/games/fossilgame/images/halfbutton.png"
ExTool.sprite.origin = {0,0}
ExTool.sprite.scale = 2
ExTool.sound = {"/sfx/tools/pickaxe_hit.ogg"}

function ExTool:calculateUses(toolUses)
  for toolName,uses in pairs(toolUses) do
    if toolName=="Square" then
      return math.ceil(uses / 2)
    end
  end
end