local barsOldInit = init

function init()
    barsOldInit()
    self.barsList = {}
    message.setHandler("setBar", function(_, _, barName, barPercentage, barColor)
        setBar(barName,barPercentage,barColor)
    end)
    message.setHandler("removeBar", function(_, _, barName)
        removeBar(barName)
    end)
    
end

function overheadBars()
  local bars = {}

  if status.statPositive("shieldHealth") then
    table.insert(bars, {
      percentage = status.resource("shieldStamina"),
      color = status.resourcePositive("perfectBlock") and {255, 255, 200, 255} or {200, 200, 0, 255}
    })
  end
  for k,v in pairs(self.barsList) do
    table.insert(bars,{
        percentage = v.percentage,
        color = v.color
    })
  end

  return bars
end

function removeBar(barName)
    self.barsList[barName] = nil
end

function setBar(barName,barPercentage,barColor)
    self.barsList[barName] = {
        percentage = barPercentage,
        color = barColor,
        stat = barStat
    }
    sb.logInfo("%s  %s  %s",barName,barPercentage,barColor)
end