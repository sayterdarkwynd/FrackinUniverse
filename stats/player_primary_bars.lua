local barsOldInit = init

function init()
	barsOldInit()
	self.barsList = {}
	message.setHandler("setBar", function(_, l, barName, barPercentage, barColor)
		if not l then return end
		setBar(barName,barPercentage,barColor)
    end)
	message.setHandler("removeBar", function(_, l, barName)
		if not l then return end
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
end