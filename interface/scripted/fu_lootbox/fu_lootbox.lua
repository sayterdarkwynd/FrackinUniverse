

--		TO DO:
--	Support for more than 3 boxes
--	Modifiers based on consumed loot box
--	Add the 'rollDice' and 'fadeHex' to a separate .lua file so others can use it freely

-- Used in fading hex colors
-- Do not touch unless you plan on reworking stuff
cb = {}
cb[70] = 15
cb[69] = 14
cb[68] = 13
cb[67] = 12
cb[66] = 11
cb[65] = 10
cb[57] = 9
cb[56] = 8
cb[55] = 7
cb[54] = 6
cb[53] = 5
cb[52] = 4
cb[51] = 3
cb[50] = 2
cb[49] = 1
cb[48] = 0

isAnimating = false
timerActive = false
isOpening = false
isOpen = false
lootPool = nil
hovered = nil
canvas = nil
rarity = nil
data = nil
timer = 0
vfx = {}

funcs = {
	--	Functions here can return a table to override some parameters. Example table:
	--	{title = "Bees!", subtitle = "Oh no not the bees!", image = "/items/bees/bees/normal/queen.png", textColor = "#FFFF00", flashColor = "#FF0000" }
	--	'itemLevelMod' field can be used to modify item level
	spawnMonsters = function(params)
		local r = math.random(5)
		if r == 1 then
			--bees
			world.spawnProjectile("fu_beebriefcasetemp", world.entityPosition(player.id()))
			return {title = "Bees!", subtitle = "Oh no not the bees!", image = "/items/bees/bees/normal/queen.png", textColor = "#FFFF00", flashColor = "#FF0000" }
			
		elseif r == 2 then
			-- poptops
			world.spawnProjectile("fu_poptopsack", world.entityPosition(player.id()))
			return {title = "Poptops!", subtitle = "Adorable Rabid Poptops!", image = "/items/bees/bees/normal/queen.png", textColor = "#FFCCAA", flashColor = "#FFCCAA" }
		
		elseif r == 3 then
			-- chicks
			world.spawnProjectile("fu_chicks", world.entityPosition(player.id()))
			return {title = "Chickens!", subtitle = "Aww! Babies!", image = "/items/bees/bees/normal/queen.png", textColor = "#0000AA", flashColor = "#0000AA" }
		
		
		elseif r == 4 then
			-- wolves
			world.spawnProjectile("fuwolfcase2", world.entityPosition(player.id()))
			return {title = "Wolves!", subtitle = "Rabid Angry Carnivores!", image = "/items/bees/bees/normal/queen.png", textColor = "#FFFF00", flashColor = "#FF0000" }		
		
		
		else
			-- chicks
			world.spawnProjectile("fu_chicks", world.entityPosition(player.id()))
			return {title = "Chickens!", subtitle = "Aww! Babies!", image = "/items/bees/bees/normal/queen.png", textColor = "#0000AA", flashColor = "#0000AA" }		
		end
	end,
	
	levelMod = function(params)
		return {itemLevelMod = pramas.itemLevelMod}
	end
}

function init()
	self.random = math.random(10)
	canvas = widget.bindCanvas("canvas")
	data = root.assetJson("/interface/scripted/fu_lootbox/lootboxData.config")
	vfx = data.vfx
	
	for i, _ in ipairs(data.boxes) do
		table.insert(vfx.boxes.instances, {index = i, pos = {0,0}, targetPos = {0,0}, scale = 1, targetScale = 1})
	end
	
	local canvasSize = canvas:size()
	vfx.title.position = {canvasSize[1] * 0.5, canvasSize[2] * 0.5 + vfx.title.yOffset}
	vfx.subtitle.position = {canvasSize[1] * 0.5, canvasSize[2] * 0.5 + vfx.subtitle.yOffset}
	
	self.level = world.threatLevel()
	
	setNewPos(true)
end

function update(dt)
	if timerActive then
		timer = timer + dt
	end
	
	if isOpening then
		if vfx.confetti.emitDuration > 0 then
			vfx.confetti.emitDuration = vfx.confetti.emitDuration - dt
			addConfetti(vfx.confetti.amountPerDelta)
		end
		
		if timer > vfx.openingTime then
			doneOpening()
		end
	end
	
	animate()
	draw()
end

function canvasClickEvent(position, button, pressed)
	if not isOpening then
		if pressed then
			if button == 0 then
				if hovered then
					if hovered == 1 then
						startOpening()
					elseif hovered == 2 then
						rotateButtons("left")
					elseif hovered == #vfx.boxes.instances then
						rotateButtons("right")
					end
				end
			end
		end
	end
end

function draw()
	canvas:clear()
	
	if isOpen then
		canvas:drawImageDrawable(vfx.flash.img, vfx.flash.pos, vfx.flash.scale, vfx.flash.color, vfx.flash.rot)
		
		local imgSize = root.imageSize(data.boxes[vfx.boxes.instances[1].index].img)
		local midPoint = {vfx.boxes.instances[1].pos[1] + (imgSize[1] * 0.5), vfx.boxes.instances[1].pos[2] + (imgSize[2] * 0.5)}
		
		canvas:drawImage("/interface/scripted/fu_lootbox/presentWhite.png", midPoint, vfx.boxes.instances[1].scale, "#FFFFFF"..vfx.boxes.fadeIn, true)
		canvas:drawText(vfx.title.text, {position = {vfx.title.position[1]+1, vfx.title.position[2]}, horizontalAnchor = "mid"}, vfx.title.fontSize, "#000000"..vfx.title.alpha)
		canvas:drawText(vfx.title.text, {position = {vfx.title.position[1]-1, vfx.title.position[2]}, horizontalAnchor = "mid"}, vfx.title.fontSize, "#000000"..vfx.title.alpha)
		canvas:drawText(vfx.title.text, {position = {vfx.title.position[1], vfx.title.position[2]+1}, horizontalAnchor = "mid"}, vfx.title.fontSize, "#000000"..vfx.title.alpha)
		canvas:drawText(vfx.title.text, {position = {vfx.title.position[1], vfx.title.position[2]-1}, horizontalAnchor = "mid"}, vfx.title.fontSize, "#000000"..vfx.title.alpha)
		canvas:drawText(vfx.title.text, {position = {vfx.title.position[1]+1, vfx.title.position[2]+1}, horizontalAnchor = "mid"}, vfx.title.fontSize, "#000000"..vfx.title.alpha)
		canvas:drawText(vfx.title.text, {position = {vfx.title.position[1]+1, vfx.title.position[2]-1}, horizontalAnchor = "mid"}, vfx.title.fontSize, "#000000"..vfx.title.alpha)
		canvas:drawText(vfx.title.text, {position = {vfx.title.position[1]-1, vfx.title.position[2]-1}, horizontalAnchor = "mid"}, vfx.title.fontSize, "#000000"..vfx.title.alpha)
		canvas:drawText(vfx.title.text, {position = {vfx.title.position[1]-1, vfx.title.position[2]+1}, horizontalAnchor = "mid"}, vfx.title.fontSize, "#000000"..vfx.title.alpha)
		canvas:drawText(vfx.title.text, {position = vfx.title.position, horizontalAnchor = "mid"}, vfx.title.fontSize, vfx.title.color..vfx.title.alpha)
		
		canvas:drawText(vfx.subtitle.text, {position = {vfx.subtitle.position[1]+1, vfx.subtitle.position[2]}, horizontalAnchor = "mid"}, vfx.subtitle.fontSize, "#000000"..vfx.subtitle.alpha)
		canvas:drawText(vfx.subtitle.text, {position = {vfx.subtitle.position[1]-1, vfx.subtitle.position[2]}, horizontalAnchor = "mid"}, vfx.subtitle.fontSize, "#000000"..vfx.subtitle.alpha)
		canvas:drawText(vfx.subtitle.text, {position = {vfx.subtitle.position[1], vfx.subtitle.position[2]+1}, horizontalAnchor = "mid"}, vfx.subtitle.fontSize, "#000000"..vfx.subtitle.alpha)
		canvas:drawText(vfx.subtitle.text, {position = {vfx.subtitle.position[1], vfx.subtitle.position[2]-1}, horizontalAnchor = "mid"}, vfx.subtitle.fontSize, "#000000"..vfx.subtitle.alpha)
		canvas:drawText(vfx.subtitle.text, {position = {vfx.subtitle.position[1]+1, vfx.subtitle.position[2]+1}, horizontalAnchor = "mid"}, vfx.subtitle.fontSize, "#000000"..vfx.subtitle.alpha)
		canvas:drawText(vfx.subtitle.text, {position = {vfx.subtitle.position[1]+1, vfx.subtitle.position[2]-1}, horizontalAnchor = "mid"}, vfx.subtitle.fontSize, "#000000"..vfx.subtitle.alpha)
		canvas:drawText(vfx.subtitle.text, {position = {vfx.subtitle.position[1]-1, vfx.subtitle.position[2]-1}, horizontalAnchor = "mid"}, vfx.subtitle.fontSize, "#000000"..vfx.subtitle.alpha)
		canvas:drawText(vfx.subtitle.text, {position = {vfx.subtitle.position[1]-1, vfx.subtitle.position[2]+1}, horizontalAnchor = "mid"}, vfx.subtitle.fontSize, "#000000"..vfx.subtitle.alpha)
		canvas:drawText(vfx.subtitle.text, {position = vfx.subtitle.position, horizontalAnchor = "mid"}, vfx.subtitle.fontSize, vfx.subtitle.color..vfx.subtitle.alpha)
	else
		local mousePos = canvas:mousePosition()
		hovered = nil
		
		if isOpening then
			local toRemove = {}
			for i, tbl in ipairs(vfx.confetti.instances) do
					canvas:drawLine(tbl.pos, {tbl.pos[1]+1, tbl.pos[2]+1}, tbl.color, tbl.size)
				if distanceToPoint(tbl.pos, vfx.confetti.striveTo) <= vfx.confetti.removeAtDistance  then
					table.insert(toRemove, i)
				end
			end
			
			for i = 1, #toRemove do
				table.remove(vfx.confetti.instances, toRemove[#toRemove - i + 1])
			end
			
		else
			if not isAnimating then
				for i, tbl in ipairs(vfx.boxes.instances) do
					if i == 1 or i == 2 or i == #vfx.boxes.instances then
						local imgSize = root.imageSize(data.boxes[tbl.index].img)
						if mousePos[1] >= tbl.pos[1] and mousePos[1] <= tbl.pos[1] + imgSize[1] then
							if mousePos[2] >= tbl.pos[2] and mousePos[2] <= tbl.pos[2] + imgSize[2] then
								hovered = i
								break
							end
						end
					end
				end
			end
		end
		
		for i, _ in ipairs(vfx.boxes.instances) do
			if i == #vfx.boxes.instances then
				local ind = i
				local tbl = vfx.boxes.instances[ind]
				
				local imgSize = root.imageSize(data.boxes[tbl.index].img)
				local midPoint = {}
				local color = "#FFFFFF"
				
				midPoint[1] = tbl.pos[1] + (imgSize[1] * 0.5)
				midPoint[2] = tbl.pos[2] + (imgSize[2] * 0.5)
				
				if isOpening then
					if ind == 1 then
						color = "#FFFFFF"
					elseif ind == 2 or ind == #vfx.boxes.instances then
						color = "#666666"..vfx.boxes.fadeOut
					else
						color = "#333333"..vfx.boxes.fadeOut
					end

					if ind == 1 then
						local rotation = math.random(math.floor(vfx.openingTime*-20), math.floor(vfx.openingTime*20))*0.01
						canvas:drawImageDrawable(data.boxes[tbl.index].img, midPoint, tbl.scale, color, rotation)
						canvas:drawImageDrawable("/interface/scripted/fu_lootbox/presentWhite.png", midPoint, tbl.scale, "#FFFFFF"..vfx.boxes.fadeIn, rotation)
					else
						canvas:drawImage(data.boxes[tbl.index].img, midPoint, tbl.scale, color, true)
					end
				else
					if ind == 1 then
						color = "#FFFFFF"
					elseif ind == 2 or ind == #vfx.boxes.instances then
						color = "#666666"
					else
						color = "#333333"
					end
					
					if hovered == ind then
						if ind == 1 then
							canvas:drawImageDrawable(data.boxes[tbl.index].img, midPoint, tbl.scale, color, math.random(-10, 10) * 0.01)
						else
							canvas:drawImage(data.boxes[tbl.index].img, midPoint, tbl.scale + 0.1, color, true)
						end
					else
						canvas:drawImage(data.boxes[tbl.index].img, midPoint, tbl.scale, color, true)
					end
				end
			end
			
			local ind = #vfx.boxes.instances - i + 1
			if ind < #vfx.boxes.instances then
				local tbl = vfx.boxes.instances[ind]
				
				local imgSize = root.imageSize(data.boxes[tbl.index].img)
				local midPoint = {}
				local color = "#FFFFFF"
				
				midPoint[1] = tbl.pos[1] + (imgSize[1] * 0.5)
				midPoint[2] = tbl.pos[2] + (imgSize[2] * 0.5)
				
				if isOpening then
					if ind == 1 then
						color = "#FFFFFF"
					elseif ind == 2 or ind == #vfx.boxes.instances then
						color = "#666666"..vfx.boxes.fadeOut
					else
						color = "#333333"..vfx.boxes.fadeOut
					end

					if ind == 1 then
						local rotation = math.random(math.floor(vfx.openingTime*-20), math.floor(vfx.openingTime*20))*0.01
						canvas:drawImageDrawable(data.boxes[tbl.index].img, midPoint, tbl.scale, color, rotation)
						canvas:drawImageDrawable("/interface/scripted/fu_lootbox/presentWhite.png", midPoint, tbl.scale, "#FFFFFF"..vfx.boxes.fadeIn, rotation)
					else
						canvas:drawImage(data.boxes[tbl.index].img, midPoint, tbl.scale, color, true)
					end
				else
					if ind == 1 then
						color = "#FFFFFF"
					elseif ind == 2 or ind == #vfx.boxes.instances then
						color = "#666666"
					else
						color = "#333333"
					end
					
					if hovered == ind then
						if ind == 1 then
							canvas:drawImageDrawable(data.boxes[tbl.index].img, midPoint, tbl.scale, color, math.random(-10, 10) * 0.01)
						else
							canvas:drawImage(data.boxes[tbl.index].img, midPoint, tbl.scale + 0.1, color, true)
						end
					else
						canvas:drawImage(data.boxes[tbl.index].img, midPoint, tbl.scale, color, true)
					end
				end
			end
		end
		
		canvas:drawText(vfx.title.text, {position = {vfx.title.position[1]+1, vfx.title.position[2]}, horizontalAnchor = "mid"}, vfx.title.fontSize, "#000000"..vfx.title.alpha)
		canvas:drawText(vfx.title.text, {position = {vfx.title.position[1]-1, vfx.title.position[2]}, horizontalAnchor = "mid"}, vfx.title.fontSize, "#000000"..vfx.title.alpha)
		canvas:drawText(vfx.title.text, {position = {vfx.title.position[1], vfx.title.position[2]+1}, horizontalAnchor = "mid"}, vfx.title.fontSize, "#000000"..vfx.title.alpha)
		canvas:drawText(vfx.title.text, {position = {vfx.title.position[1], vfx.title.position[2]-1}, horizontalAnchor = "mid"}, vfx.title.fontSize, "#000000"..vfx.title.alpha)
		canvas:drawText(vfx.title.text, {position = {vfx.title.position[1]+1, vfx.title.position[2]+1}, horizontalAnchor = "mid"}, vfx.title.fontSize, "#000000"..vfx.title.alpha)
		canvas:drawText(vfx.title.text, {position = {vfx.title.position[1]+1, vfx.title.position[2]-1}, horizontalAnchor = "mid"}, vfx.title.fontSize, "#000000"..vfx.title.alpha)
		canvas:drawText(vfx.title.text, {position = {vfx.title.position[1]-1, vfx.title.position[2]-1}, horizontalAnchor = "mid"}, vfx.title.fontSize, "#000000"..vfx.title.alpha)
		canvas:drawText(vfx.title.text, {position = {vfx.title.position[1]-1, vfx.title.position[2]+1}, horizontalAnchor = "mid"}, vfx.title.fontSize, "#000000"..vfx.title.alpha)
		canvas:drawText(vfx.title.text, {position = vfx.title.position, horizontalAnchor = "mid"}, vfx.title.fontSize, vfx.title.color..vfx.title.alpha)
		
		canvas:drawText(vfx.subtitle.text, {position = {vfx.subtitle.position[1]+1, vfx.subtitle.position[2]}, horizontalAnchor = "mid"}, vfx.subtitle.fontSize, "#000000"..vfx.subtitle.alpha)
		canvas:drawText(vfx.subtitle.text, {position = {vfx.subtitle.position[1]-1, vfx.subtitle.position[2]}, horizontalAnchor = "mid"}, vfx.subtitle.fontSize, "#000000"..vfx.subtitle.alpha)
		canvas:drawText(vfx.subtitle.text, {position = {vfx.subtitle.position[1], vfx.subtitle.position[2]+1}, horizontalAnchor = "mid"}, vfx.subtitle.fontSize, "#000000"..vfx.subtitle.alpha)
		canvas:drawText(vfx.subtitle.text, {position = {vfx.subtitle.position[1], vfx.subtitle.position[2]-1}, horizontalAnchor = "mid"}, vfx.subtitle.fontSize, "#000000"..vfx.subtitle.alpha)
		canvas:drawText(vfx.subtitle.text, {position = {vfx.subtitle.position[1]+1, vfx.subtitle.position[2]+1}, horizontalAnchor = "mid"}, vfx.subtitle.fontSize, "#000000"..vfx.subtitle.alpha)
		canvas:drawText(vfx.subtitle.text, {position = {vfx.subtitle.position[1]+1, vfx.subtitle.position[2]-1}, horizontalAnchor = "mid"}, vfx.subtitle.fontSize, "#000000"..vfx.subtitle.alpha)
		canvas:drawText(vfx.subtitle.text, {position = {vfx.subtitle.position[1]-1, vfx.subtitle.position[2]-1}, horizontalAnchor = "mid"}, vfx.subtitle.fontSize, "#000000"..vfx.subtitle.alpha)
		canvas:drawText(vfx.subtitle.text, {position = {vfx.subtitle.position[1]-1, vfx.subtitle.position[2]+1}, horizontalAnchor = "mid"}, vfx.subtitle.fontSize, "#000000"..vfx.subtitle.alpha)
		canvas:drawText(vfx.subtitle.text, {position = vfx.subtitle.position, horizontalAnchor = "mid"}, vfx.subtitle.fontSize, vfx.subtitle.color..vfx.subtitle.alpha)
	end
	
	canvas:drawImageDrawable(vfx.ring.img, vfx.ring.pos, vfx.ring.scale, nil, nil)
end

function addConfetti(amount)
	for i = 1, amount do
		local color = "#FFFFFF"
		local distance =  math.random(vfx.confetti.distance[1], vfx.confetti.distance[2])
		local pos = {math.floor(math.random(0, distance)), 0}
		pos[2] = math.sqrt(distance^2 - pos[1]^2)
		
		if math.random() < 0.5 then
			pos[1] = pos[1] * -1 end
		
		if math.random() < 0.5 then
			pos[2] = pos[2] * -1 end
		
		pos[1] = pos[1] + vfx.confetti.striveTo[1]
		pos[2] = pos[2] + vfx.confetti.striveTo[2]
		
		table.insert(vfx.confetti.instances, {pos = pos, color = vfx.confetti.colors[math.random(1, #vfx.confetti.colors)], radian = targetedVecAngle(pos, vfx.confetti.striveTo), size = math.random(vfx.confetti.size[1], vfx.confetti.size[2])})
	end
end

function startOpening()
	local imgSize = root.imageSize(data.boxes[vfx.boxes.instances[1].index].img)
	vfx.confetti.striveTo[1] = vfx.confetti.striveTo[1] + (imgSize[1] * 0.5)
	vfx.confetti.striveTo[2] = vfx.confetti.striveTo[2] + (imgSize[2] * 0.5)
	
	vfx.ring.pos = vfx.confetti.striveTo
	vfx.flash.pos = vfx.confetti.striveTo
	
	addConfetti(vfx.confetti.initialAmount)
	isOpening = true
	timerActive = true
end

function doneOpening()
	isOpening = false
	
	-- local lootbox = player.consumeItem({name = "fu_lootbox"}, true)
	local hasLootbox = false
	local itemLevel = 0
	
	for i = 0, 10 do
		if player.consumeItem({name = "fu_lootbox", parameters = {level = i}}, true, true) then
			hasLootbox = true
			itemLevel = i
			break
		end
	end
	
	if not hasLootbox then
		if player.consumeItem({name = "fu_lootbox"}, true) then
			hasLootbox = true
			itemLevel = roundNum(world.threatLevel())
		end
	end
	
	if hasLootbox then
		local rolled = rollDice(data.loot.dice, data.loot.diceSides)
		local requirement = 0
		local subtitle = nil
		local title = nil
		local item = nil
		local flashColor = nil
		local textColor = nil
		
		lootPool = data.boxes[vfx.boxes.instances[1].index].pool
		if not lootPool or not data.loot.pools[lootPool] then
			sb.logError("")
			sb.logError("ERROR - 'lootPool' either nil or non existant")
			sb.logError("'lootPool' is '%s'", lootPool)
			sb.logError("Box index - %s", vfx.boxes.instances[1].index)
			sb.logError("Set to '%s' to prevent a crash", data.loot.defaultPool)
			
			lootPool = data.loot.defaultPool
			title = "^FF0000;An Error occured. Report this."
		end
		
		for _, r in ipairs(data.loot.poolData.rarityOrder) do
			requirement = requirement + data.loot.poolData[r].weight
		end
		
		for _, r in ipairs(data.loot.poolData.rarityOrder) do
			requirement = requirement - data.loot.poolData[r].weight
			if rolled >= requirement then
				rarity = r
				break
			end
		end
		
		if not rarity or not data.loot.pools[lootPool][rarity] then
			sb.logError("")
			sb.logError("ERROR - 'rarity' either nil or non-existant in the '%s' loot pool", lootPool)
			sb.logError("'rarity' is '%s'", rarity)
			sb.logError("set to %s to prevent a crash", data.loot.defaultRarity)
			
			rarity = data.loot.defaultRarity
			title = "^FF0000;An Error occured. Report this."
		end
		
		lootData = data.loot.pools[lootPool][rarity][math.random(1, #data.loot.pools[lootPool][rarity])]
		
		if lootData.func then
			local funcData = funcs[lootData.func](lootData.params)
			
			if funcData.title then
				title = funcData.title end
			
			if funcData.subtitle then
				subtitle = funcData.subtitle end
			
			if funcData.image then
				local imagePosition = {vfx.confetti.striveTo[1]+6, vfx.confetti.striveTo[2]+6}
				local imageSize = root.imageSize(funcData.image)
				imagePosition[1] = imagePosition[1] - imageSize[1] * 0.5
				imagePosition[2] = imagePosition[2] - imageSize[2] * 0.5
				
				widget.setPosition("itemBG", imagePosition)
				widget.setImage("itemBG", funcData.image)
				widget.setVisible("itemBG", true)
				widget.setVisible("item", false)
			end
			
			if funcData.textColor then
				textColor = funcData.textColor
			end
			
			if funcData.flashColor then
				flashColor = funcData.flashColor
			end
			
			if funcData.itemLevelMod then
				itemLevel = math.max(itemLevel + funcData.itemLevelMod, 0)
			end
		end
		
		if (lootData.treasurePool and root.isTreasurePool(lootData.treasurePool)) or lootData.item then
			local cfg = nil
			local item = nil
			
			if lootData.treasurePool and root.isTreasurePool(lootData.treasurePool) then
				local treasure = root.createTreasure(lootData.treasurePool, lootData.level or itemLevel or 1)
				cfg = root.itemConfig(treasure[1].name)
				item = root.createItem(treasure[1].name, lootData.level or itemLevel, lootData.seed)
				item.shortdescription = cfg.config.shortdescription
				item.count = treasure[1].count or 1
			else
				cfg = root.itemConfig(lootData.item)
				item = root.createItem(lootData.item, lootData.level or itemLevel, lootData.seed)
				item.shortdescription = cfg.config.shortdescription
				item.count = lootData.amount or 1
			end
			
			if item then
				if not item.name then
					item.name = cfg.config.itemName
				end
				
				world.spawnItem(item, world.entityPosition(player.id()))
				
				if not title then
					title = item.shortdescription
					if title then
						if item.count and item.count > 1 then
							title = title.." x"..item.count
						end
						
						if root.itemHasTag(item.name, "weapon") then
							if lootData.level or itemLevel then
								title = "Tier "..(lootData.level or itemLevel).." "..title
							end
						end
					else
						title = item.name
						if title then
							if item.count and item.count > 1 then
								title = title.." x"..item.count
							end
							
							if root.itemHasTag(item.name, "weapon") then
								if lootData.level or itemLevel then
									title = "Tier "..(lootData.level or itemLevel).." "..title
								end
							end
						else
							title = "No title. Report this."
						end
					end
				end
				
				if not subtitle then
					subtitle = data.loot.poolData[rarity].name
				end
				
				if not flashColor then
					flashColor = data.loot.poolData[rarity].color
				end
				
				if not textColor then
					textColor = data.loot.poolData[rarity].color
				end
				
				widget.setPosition("itemBG", {vfx.confetti.striveTo[1]-9+6, vfx.confetti.striveTo[2]-9+6})
				widget.setPosition("item", {vfx.confetti.striveTo[1]-9+6, vfx.confetti.striveTo[2]-9+6})
				widget.setItemSlotItem("item", item)
				widget.setVisible("itemBG", true)
				widget.setVisible("item", true)
			end
		end
		
		vfx.flash.targetColor = flashColor or "#FFFFFF"
		
		vfx.title.text = title or "ERROR - Report what you got"
		vfx.title.color = textColor or "#FFFFFF"
		
		vfx.subtitle.text = subtitle or "ERROR - Report what you got"
		vfx.subtitle.color = textColor or "#FFFFFF"
	else
		vfx.title.text = "Nothing!"
		vfx.subtitle.text = "No lootbox, no loot."
	end
	
	isOpen = true
end

function rotateButtons(side)
	if side == "left" then
		table.insert(vfx.boxes.instances, table.remove(vfx.boxes.instances, 1))
	elseif side == "right" then
		table.insert(vfx.boxes.instances, 1, table.remove(vfx.boxes.instances, #vfx.boxes.instances))
	end
	
	setNewPos()
end

function setNewPos(isInit)
	if isInit then
		for i, tbl in ipairs(vfx.boxes.instances) do
			if i == 1 then
				tbl.pos[1] = vfx.boxes.frontPos[1]
				tbl.pos[2] = vfx.boxes.frontPos[2]
				tbl.targetPos[1] = vfx.boxes.frontPos[1]
				tbl.targetPos[2] = vfx.boxes.frontPos[2]
				tbl.targetScale = vfx.boxes.frontScale
				tbl.scale = vfx.boxes.frontScale
			elseif i == 2 then
				tbl.pos[1] = vfx.boxes.leftPos[1]
				tbl.pos[2] = vfx.boxes.leftPos[2]
				tbl.targetPos[1] = vfx.boxes.leftPos[1]
				tbl.targetPos[2] = vfx.boxes.leftPos[2]
				tbl.targetScale = vfx.boxes.sideScale
				tbl.scale = vfx.boxes.sideScale
			elseif i == #vfx.boxes.instances then
				tbl.pos[1] = vfx.boxes.rightPos[1]
				tbl.pos[2] = vfx.boxes.rightPos[2]
				tbl.targetPos[1] = vfx.boxes.rightPos[1]
				tbl.targetPos[2] = vfx.boxes.rightPos[2]
				tbl.targetScale = vfx.boxes.sideScale
				tbl.scale = vfx.boxes.sideScale
			else
				tbl.pos[1] = (vfx.boxes.rightPos[1] - vfx.boxes.leftPos[1]) / (#vfx.boxes.instances - 3) * (i - 2)
				tbl.pos[2] = vfx.boxes.backYOffset
				tbl.targetPos[1] = (vfx.boxes.rightPos[1] - vfx.boxes.leftPos[1]) / (#vfx.boxes.instances - 3) * (i - 2)
				tbl.targetPos[2] = vfx.boxes.backYOffset
				tbl.targetScale = vfx.boxes.backScale
				tbl.scale = vfx.boxes.backScale
			end
		end
	else
		for i, tbl in ipairs(vfx.boxes.instances) do
			if i == 1 then
				tbl.targetPos[1] = vfx.boxes.frontPos[1]
				tbl.targetPos[2] = vfx.boxes.frontPos[2]
				tbl.targetScale = vfx.boxes.frontScale
			elseif i == 2 then
				tbl.targetPos[1] = vfx.boxes.leftPos[1]
				tbl.targetPos[2] = vfx.boxes.leftPos[2]
				tbl.targetScale = vfx.boxes.sideScale
			elseif i == #vfx.boxes.instances then
				tbl.targetPos[1] = vfx.boxes.rightPos[1]
				tbl.targetPos[2] = vfx.boxes.rightPos[2]
				tbl.targetScale = vfx.boxes.sideScale
			else
				tbl.targetPos[1] = (vfx.boxes.rightPos[1] - vfx.boxes.leftPos[1]) / (#vfx.boxes.instances - 3) * (i - 2)
				tbl.targetPos[2] = vfx.boxes.backYOffset
				tbl.targetScale = vfx.boxes.backScale
			end
		end
	end
	
	vfx.title.text = data.boxes[vfx.boxes.instances[1].index].name
	vfx.subtitle.text = data.boxes[vfx.boxes.instances[1].index].description
end

function animate()
	isAnimating = false
	
	if vfx.ring.spawnTime <= timer then
		vfx.ring.scale = vfx.ring.scale + vfx.ring.scaleSpeed
	end
	
	if vfx.flash.spawnTime <= timer then
		vfx.flash.rot = vfx.flash.rot + vfx.flash.rotationSpeed
		if vfx.flash.scale < vfx.flash.scaleTarget then
			vfx.flash.scale = vfx.flash.scale + vfx.flash.scaleSpeed
		end
	end
	
	if isOpening then
		for _, tbl in ipairs(vfx.confetti.instances) do
			tbl.pos[1] = tbl.pos[1] - math.cos(tbl.radian) * vfx.confetti.speed
			tbl.pos[2] = tbl.pos[2] - math.sin(tbl.radian) * vfx.confetti.speed
		end
		
		vfx.boxes.fadeOut = fadeHex(vfx.boxes.fadeOut, "out", 15)
		vfx.boxes.fadeIn = fadeHex(vfx.boxes.fadeIn, "in", 15)
		
		vfx.title.alpha = fadeHex(vfx.title.alpha, "out", vfx.title.alphaFade)
		vfx.subtitle.alpha = fadeHex(vfx.subtitle.alpha, "out", vfx.subtitle.alphaFade)
		
	elseif isOpen then
		if rarity then
			vfx.boxes.fadeIn = fadeHex(vfx.boxes.fadeIn, "out", 7)
			
			local r = string.sub(vfx.flash.color, 2, 3)
			local g = string.sub(vfx.flash.color, 4, 5)
			local b = string.sub(vfx.flash.color, 6, 7)
			local rt = string.sub(vfx.flash.targetColor or "#FFFFFF", 2, 3)
			local gt = string.sub(vfx.flash.targetColor or "#FFFFFF", 4, 5)
			local bt = string.sub(vfx.flash.targetColor or "#FFFFFF", 6, 7)
			
			r = fadeHex(r, "out", vfx.flash.colorFade, rt)
			g = fadeHex(g, "out", vfx.flash.colorFade, gt)
			b = fadeHex(b, "out", vfx.flash.colorFade, bt)
			
			vfx.flash.color = "#"..r..g..b
		end
		
		vfx.title.alpha = fadeHex(vfx.title.alpha, "in", vfx.title.alphaFade)
		vfx.subtitle.alpha = fadeHex(vfx.subtitle.alpha, "in", vfx.subtitle.alphaFade)
	else
		
		for i, tbl in ipairs(vfx.boxes.instances) do
			if distanceToPoint(tbl.pos, tbl.targetPos) > 0.5 then
				isAnimating = true
				
				local movX = (tbl.targetPos[1] - tbl.pos[1]) * 0.2
				local movY = (tbl.targetPos[2] - tbl.pos[2]) * 0.2
				
				if movX < 0 then
					movX = movX - 0.5
				elseif movX > 0 then
					movX = movX + 0.5
				end
				
				if movY < 0 then
					movY = movY - 0.5
				elseif movY > 0 then
					movY = movY + 0.5
				end
				
				tbl.pos[1] = roundNum(tbl.pos[1] + movX)
				tbl.pos[2] = roundNum(tbl.pos[2] + movY)
			end
			
			if not (tbl.scale <= tbl.targetScale + 0.02 and tbl.scale >= tbl.targetScale - 0.02) then
				local mod = 0
				
				if tbl.scale < tbl.targetScale then
					mod = math.max((tbl.targetScale - tbl.scale) * 0.2, 0.02)
				else
					mod = math.min((tbl.targetScale - tbl.scale) * 0.2, -0.02)
				end
				
				tbl.scale = tbl.scale + mod
			end
		end
	end
end

-- Util Functions
function fadeHex(hex, fade, amount, target)
	hex = string.upper(hex)
	amount = math.ceil(amount)
	if target then
		target = string.upper(target)
	end
	
	if hex == target then
		return hex
	end
	
	if fade == "out" then
		local tens = cb[string.byte(string.sub(hex, 1, 1))]
		local units = cb[string.byte(string.sub(hex, 2, 2))]
		units = units - amount
		
		while units < 0 do
			units = units + 15
			tens = tens - 1
			
			if target then
				local tTens = cb[string.byte(string.sub(target, 1, 1))]
				local tUnits = cb[string.byte(string.sub(target, 2, 2))]
				
				if tens <= tTens then
					return target
				end
			elseif tens < 0 then
				tens = 0
				units = 0
				break
			end
		end
		
		for i, j in pairs(cb) do
			if units == j then
				units = i
			end
			
			if tens == j then
				tens = i
			end
		end
		
		return string.char(tens)..string.char(units)
		
	elseif fade == "in" then
		local tens = cb[string.byte(string.sub(hex, 1, 1))]
		local units = cb[string.byte(string.sub(hex, 2, 2))]
		units = units + amount
		
		while units > 15 do
			units = units - 15
			tens = tens + 1
			
			if target then
				local tTens = cb[string.byte(string.sub(target, 1, 1))]
				local tUnits = cb[string.byte(string.sub(target, 2, 2))]
				
				if tens >= tTens then
					return target
				end
			elseif tens > 15 then
				tens = 15
				units = 15
				break
			end
		end
		
		for i, j in pairs(cb) do
			if units == j then
				units = i
			end
			
			if tens == j then
				tens = i
			end
		end
		
		return string.char(tens)..string.char(units)
	end
end

function distanceToPoint(p1, p2)
	return math.sqrt((p2[1] - p1[1])^2 + (p2[2] - p1[2])^2)
end

function roundNum(num)
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

function targetedVecAngle(pos, target)
	local v1 = pos[1] - target[1]
	local v2 = pos[2] - target[2]
	
	local angle = math.atan(v2, v1)
	if angle < 0 then angle = angle + 2 * math.pi end
	return angle
end

function rollDice(dice, sides, mod)
	local sum = mod or 0
	
	for i = 1, dice do
		sum = sum + math.random(1, sides)
	end
	
	return sum
end