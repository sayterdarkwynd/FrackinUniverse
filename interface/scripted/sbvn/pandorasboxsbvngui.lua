require "/scripts/util.lua"

function init()
  -- global because dynamic dt is annoying in coroutines
  dt = script.updateDt()

  self.bgFadeTime = 0.3
  self.fgTweenTime = 0.4
  self.screenSize = {300, 200}

  self.bgCanvas = widget.bindCanvas("cvsBackground")
  self.fgCanvas = widget.bindCanvas("cvsForeground")
  self.overlayCanvas = widget.bindCanvas("cvsOverlay")
  widget.focus("cvsOverlay")

  local gameFile = config.getParameter("gameFile")
  local savedState = config.getParameter("gameState")
  self.itemName = config.getParameter("itemName")
  loadGame(gameFile, savedState)
end

function update(dt)
  self.transitions = util.filter(self.transitions, function(t)
      local s = coroutine.resume(t)
      return s
    end)

  if (not player.primaryHandItem() or player.primaryHandItem().name ~= self.itemName) and (not player.altHandItem() or player.altHandItem().name ~= self.itemName) then
    pane.dismiss()
  end

  widget.setVisible("imgContinueHint", (self.scene and self.scene.continue) or #self.transitions > 0)
end

function canvasClickEvent(position, button, isButtonDown)
  -- no mouse input, at least for now
end

function uninit()
  world.sendEntityMessage(pane.sourceEntity(), "stopAltMusic", 2.0)
end

function canvasKeyEvent(key, isKeyDown)
  if isKeyDown then
    if key == 5 or key == 3 then -- space bar or enter
      advance()
    elseif key == 46 or key == 89 then -- D or right arrow
      moveSelection(1)
    elseif key == 43 or key == 90 then -- A or left arrow
      moveSelection(-1)
    end
  end
end

function loadGame(gameFile, savedState)
  self.scene = nil
  self.transitions = {}

  local gameConfig = root.assetJson(gameFile)

  self.gameConfig = gameConfig
  self.gamePath = util.pathDirectory(gameFile)
  self.gameScenes = gameConfig.scenes

  setupDisplay(gameConfig.displayConfig)

  setTitleScene(savedState)
end

function setupDisplay(displayConfig)
  pane.setTitle(" " .. displayConfig.title, displayConfig.subtitle and " " .. displayConfig.subtitle or "")

  widget.setImage("imgTextbox", imagePath("textbox"))
  widget.setImage("imgContinueHint", imagePath("continuehint"))
  widget.setFontColor("lblText", displayConfig.textColor)

  self.selFormat = displayConfig.selFormat
  self.unselFormat = displayConfig.unselFormat
  self.textRate = displayConfig.textRate
end

function advance()
  if #self.transitions > 0 then
    self.transitions = {}
    setScene(self.scene, false)
  elseif self.scene.continue then
    setScene(pickScene(self.scene.continue), true)
  elseif self.options and self.selected and #self.options >= self.selected then
    processOption(self.options[self.selected])
  else
    self.gameState = nil
    saveState()
    setTitleScene()
  end
end

function setTitleScene(savedState)
  self.gameState = nil

  local titleScene = copy(self.gameConfig.titleScene)
  titleScene.options = {
    {"New Game", "NEW"}
  }

  if savedState then
    table.insert(titleScene.options, {"Continue", "LOAD", savedState})
  end

  setScene(titleScene, false)
end

function setScene(scene, withTransition)
  if type(scene) == "string" then
    if not self.gameScenes[scene] then
      sb.logError("scene '%s' not found!", scene)
      return
    end

    self.gameState = self.gameState or {flags={}}
    self.gameState.scene = scene
    saveState()

    scene = self.gameScenes[scene]
  end

  -- sb.logInfo("setting scene %s", scene)

  self.bgCanvas:clear()
  if scene.background then
    if withTransition and (self.scene and self.scene.background) and scene.background ~= self.scene.background then
      local t = coroutine.create(function()
          local ratio = 0
          local rate = dt / self.bgFadeTime

          local oldBg = imagePath(self.scene.background)
          local newBg = imagePath(scene.background)

          while ratio < 1.0 do
            ratio = math.min(1.0, ratio + rate)

            local alpha = math.ceil(ratio * 255)

            self.bgCanvas:clear()
            self.bgCanvas:drawImage(oldBg, {0, 0})
            self.bgCanvas:drawImage(newBg, {0, 0}, 1.0, {255, 255, 255, alpha})

            coroutine.yield()
          end

          self.bgCanvas:clear()
          self.bgCanvas:drawImage(newBg, {0, 0})
        end)

      coroutine.resume(t)

      table.insert(self.transitions, t)
    else
      self.bgCanvas:drawImage(imagePath(scene.background), {0, 0})
    end
  end

  self.fgCanvas:clear()
  if withTransition and scene.foreground ~= self.scene.foreground then
    local t = coroutine.create(function()
        local ratio = 0
        local rate = dt / self.fgTweenTime

        local oldChar = self.scene.foreground and imagePath(self.scene.foreground, self.scene.foregroundFrame)
        local newChar = scene.foreground and imagePath(scene.foreground, scene.foregroundFrame)

        if oldChar then
          while ratio < 1.0 do
            ratio = math.min(1.0, ratio + rate)

            self.fgCanvas:clear()
            self.fgCanvas:drawImage(oldChar, {util.interpolateSigmoid(ratio, 0, self.screenSize[1]), 0})

            coroutine.yield()
          end
        end

        ratio = 1.0

        if newChar then
          while ratio > 0 do
            ratio = math.max(0, ratio - rate)

            self.fgCanvas:clear()
            self.fgCanvas:drawImage(newChar, {util.interpolateSigmoid(ratio, 0, -self.screenSize[1]), 0})

            coroutine.yield()
          end
        end

        self.fgCanvas:clear()
        self.fgCanvas:drawImage(newChar, {0, 0})
      end)

    coroutine.resume(t)

    table.insert(self.transitions, t)
  elseif scene.foreground then
    self.fgCanvas:drawImage(imagePath(scene.foreground, scene.foregroundFrame), {0, 0})
  end

  if scene.text and withTransition then
    widget.setVisible("lblOptions", false)
    widget.setText("lblText", "^clear;" .. scene.text)

    local t = coroutine.create(function()
        local ratio = 0
        local rate = dt / (scene.text:len() / self.textRate)

        while ratio < 1.0 do
          ratio = math.min(1.0, ratio + rate)

          local i = math.ceil(ratio * scene.text:len())
          if i < scene.text:len() then
            local outStr = scene.text:sub(1, i) .. "^clear;" .. scene.text:sub(i + 1, scene.text:len())
            widget.setText("lblText", outStr)
          else
            widget.setText("lblText", scene.text)
          end

          coroutine.yield()
        end

        widget.setVisible("lblOptions", true)
      end)

    coroutine.resume(t)

    table.insert(self.transitions, t)
  else
    widget.setText("lblText", scene.text or "")
    widget.setVisible("lblOptions", true)
  end

  if scene.music or (self.scene and self.scene.music) then
	if scene.music and scene.music ~= self.scene.music then
	  music = {}
	  table.insert(music, scene.music)
      world.sendEntityMessage(pane.sourceEntity(), "playAltMusic", music, 2.0)
	elseif not scene.music then
	  world.sendEntityMessage(pane.sourceEntity(), "stopAltMusic", 2.0)
    end
  end

  self.scene = scene
  self.selected = 1
  setOptions(self.scene.options)
end

function moveSelection(offset)
  if self.options and #self.options > 1 then
    self.selected = (self.selected + offset - 1) % #self.options + 1
    setOptions(self.options)
  end
end

function processOption(option)
  if option[2] == "NEW" then
    setScene(self.gameConfig.entryScene, true)
  elseif option[2] == "LOAD" then
    self.gameState = option[3]
    setScene(self.gameState.scene, false)
  else
    if option[4] then
      for _, flagStr in pairs(option[4]) do
        setFlag(flagStr)
      end
    end

    setScene(pickScene(option[2]), true)
  end
end

function pickScene(sceneOrList)
  if type(sceneOrList) == "table" then
    for _, flagScenePair in pairs(sceneOrList) do
      if type(flagScenePair) == "table" then
        if checkFlag(flagScenePair[1]) then
          return flagScenePair[2]
        end
      else
        return flagScenePair
      end
    end
  else
    return sceneOrList
  end
end

function setOptions(options)
  if options then
    options = util.filter(options, function(option)
        if option[2] == "NEW" or option[2] == "LOAD" then
          return true
        else
          if option[3] then
            for _, flagStr in pairs(option[3]) do
              if not checkFlag(flagStr) then
                return false
              end
            end
          end
          return true
        end
      end)
  end

  self.options = options

  local optStr = ""

  if options then
    for i, option in ipairs(options) do
      if i > 1 then
        optStr = optStr .. "        "
      end

      optStr = optStr .. string.format(i == self.selected and self.selFormat or self.unselFormat, option[1])
    end
  end

  widget.setText("lblOptions", optStr)
end

function imagePath(imageName, frameName)
  return self.gamePath .. imageName .. ".png" .. (frameName and (":" .. frameName) or "")
end

function saveState()
  world.sendEntityMessage(pane.sourceEntity(), "saveState", self.gameState)
end

function setFlag(flagStr)
  local f, v = splitFlagStr(flagStr, "=")
  if f then
    self.gameState.flags[f] = v
    return
  end

  f, v = splitFlagStr(flagStr, "+")
  if f then
    self.gameState.flags[f] = (self.gameState.flags[f] or 0) + v
    return
  end

  f, v = splitFlagStr(flagStr, "-")
  if f then
    self.gameState.flags[f] = (self.gameState.flags[f] or 0) - v
    return
  end
end

function checkFlag(flagStr)
  local f, v = splitFlagStr(flagStr, "=")
  if f then
    return (self.gameState.flags[f] or 0) == v
  end

  f, v = splitFlagStr(flagStr, "<")
  if f then
    return (self.gameState.flags[f] or 0) < v
  end

  f, v = splitFlagStr(flagStr, ">")
  if f then
    return (self.gameState.flags[f] or 0) > v
  end
end

function splitFlagStr(flagStr, op)
  local i = flagStr:find(op)
  if i then
    return flagStr:sub(0, i - 1), tonumber(flagStr:sub(i + 1))
  end
end
