function init()
    self.dialog = config.getParameter("dialog.wakePlayer")
    self.dialogTimer = 0.0
    self.dialogInterval = 14.0
    self.drawMoreIndicator = false
end

function sayNext()
  if self.dialog and #self.dialog > 0 then
    if #self.dialog > 0 then
      local options = {
        drawMoreIndicator = self.drawMoreIndicator
      }
      self.dialogTimer = self.dialogInterval
      if #self.dialog == 1 then
        options.drawMoreIndicator = false
        self.dialogTimer = 0.0
      end

      object.sayPortrait(self.dialog[1][1], self.dialog[1][2], nil, options)
      table.remove(self.dialog, 1)

      return true
    end
  else
    self.dialog = nil
    return false
  end
end

function update(dt)
  if self.dialogTimer then
    self.dialogTimer = math.max(self.dialogTimer - dt, 0.0)
    if self.dialogTimer == 0 and not sayNext() then
      self.dialogTimer = nil
    end
  end
end
