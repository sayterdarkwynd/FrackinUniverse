require "/scripts/util.lua"

function init()
	self.data = root.assetJson("/interface/scripted/statWindow/extraStatsWindow.config")
	canvas = widget.bindCanvas("tooltipHandler")
	self.lifespanCounter = self.data.tooltipLifespan
	self.delayCounter = self.data.tooltipCheckDelay

	widget.setText("tooltip", self.data.defaultTooltip)
end

function update()
	-- Breath calculated separately
	local breatRegen = status.stat("breathRegenerationRate")
	local breathMax = status.stat("maxBreath")

	-- for stat, type in pairs(self.stats) do
	for stat, type in pairs(self.data.stats) do
		local value = status.stat(stat)
		--[[if stat=="healthRegen" then
			sb.logInfo("%s",{stat=stat,value=value})
		end]]

		-- Getting rid of the redundant .0's
		local fraction = math.abs(math.floor(value) - value)
		if fraction == 0 then
			value = math.floor(value)
		end

		if type == "flat" then
			value = tostring(shorten(value))
			widget.setText(stat, value)

		elseif type == "percent" then
			value = tostring(average(value * 100)).."%"
			widget.setText(stat, value)

		elseif type == "crit" then
			if value>0 then
				value = "+"..tostring(util.round(value,1)).."%"
			elseif value<0 then
				value = "-"..tostring(util.round(value,1)).."%"
			else
				value="0%"
			end
			widget.setText(stat, value)

		elseif type == "critmult" then
			value = tostring(average((1.5+value)*100)).."%"
			widget.setText(stat, value)

		elseif type == "food" then
			local foodVal=status.isResource("food") and status.resourceMax("food") or 0
			if foodVal~=0 then
				--value = math.abs(shorten(1 / (value / status.resourceMax("food")) * 0.01))--blatantly wrong
				value=math.abs(shorten(foodVal/(value*60.0)))
				if value % 1 == 0 then
					widget.setText(stat, tostring(math.floor(value)))
				else
					widget.setText(stat, tostring(value))
				end
			else
				widget.setText(stat, "---")
			end

		elseif type == "breath" then
			local breathRate = value
			if breathMax > 0 then
				-- Why divided by 2 you ask? Fuck if I know, it returns double the right value otherwise. <-zimber's note
				--khe: that's because breath timer is decremented twice per update; once in vanilla code, once in FR code.
				widget.setText("breathMaxTime", breathMax / breathRate / 2)
				widget.setText("breathRegenTime", breathMax / breatRegen / 2)
			end
		end
	end

	if self.delayCounter == 0 then
		self.delayCounter = self.data.tooltipLifespan

		local xPos = canvas:mousePosition()[1]
		local yPos = canvas:mousePosition()[2]
		for _, box in ipairs(self.data.tooltipBoxes) do
			if xPos >= box.x1 and xPos < box.x2 then
				if yPos >= box.y1 and yPos < box.y2 then
					local tooltip = box.tooltip
					local length = string.len(tooltip)
					if length >= 25 then
						local findSpace = string.find(tooltip, " ", 25)
						if findSpace and findSpace < length then
							local firstHalf = string.sub(tooltip, 1, findSpace - 1)
							local secondHalf = string.sub(tooltip, findSpace + 1, length)
							tooltip = firstHalf.."\n"..secondHalf
						end
					end
					widget.setText("tooltip", tooltip)

					self.lifespanCounter = self.data.tooltipLifespan
					return
				end
			end
		end

		if self.lifespanCounter == 0 then
			widget.setText("tooltip", self.data.defaultTooltip)
		else
			self.lifespanCounter = self.lifespanCounter - 1
		end
	else
		self.delayCounter = self.delayCounter - 1
	end

end

function average(num)
	local low = math.floor(num)
	local high = math.ceil(num)

	if math.abs(num - low) < math.abs(num - high) then
		if num < 0 then
			return low * -1
		else
			return low
		end
	else
		if num < 0 then
			return high * -1
		else
			return high
		end
	end
end

function shorten(val)
	if type(val) == "number" then
		if val > 9999 then
			-- if its a 5 digit number, just let it overflow out of the box. Can't be reached naturaly, and cheaters can go fuck themselves
			return average(val)
		else
			local str = tostring(val)
			local dotPoint = string.find(str, "%.", 1)

			if string.len(str) < 6 then
				if dotPoint then
					str = string.sub(str, 1, math.min(dotPoint + 2, 5))
				end
			else
				str = string.sub(str, 1, 5)
			end

			return str
		end
	elseif type(val) == "string" then
		-- nothing yet
		return val
	else
		return tostring(val)
	end
end
