frackinRaces = false

function init()
	self.data = root.assetJson("/interface/scripted/statWindow/statWindow.config")
	self.elements = self.data.elements
	self.statuses = self.data.statuses

	widget.setText("characterName", "^blue;"..world.entityName(player.id()))

	local playerRace = player.species()
	widget.setImage("characterSuit", "/interface/scripted/techupgrade/suits/"..playerRace.."-"..player.gender()..".png")

	if frackinRaces then
		-- widget.setText("racialLabel", "Racial traits - "..playerRace)
		widget.setVisible("racialDesc", true)
	else
		widget.setText("racialLabel", "SoonTM")
	end

	populateRacialDescription()
end

function update()
	for _, element in ipairs(self.elements) do
		widget.setText(element.."Resist", math.floor(status.stat(element.."Resistance")*100+0.5).."%")
	end

	widget.clearListItems("immunitiesList.textList")
	for thing,stuff in pairs(self.statuses) do
		local skipping = false

		for _,skipped in ipairs(stuff.skip or {}) do
			if status.stat(skipped) >= 1 then
				skipping = true
				break
			end
		end

		if not skipping then
			if status.stat(thing) >= 1 then
				local listItem = "immunitiesList.textList."..widget.addListItem("immunitiesList.textList")
				widget.setText(listItem..".immunity", stuff.name)
			end
		end
	end
end

function populateRacialDescription()
	widget.clearListItems("racialDesc.textList")

	-- using 'for i' loop because 'i/pairs' tends to fuck up order

	--[[
	for i = 1, #racialDescription.positive do
		local listItem = "racialDesc.textList."..widget.addListItem("racialDesc.textList")
		local text = "^green;"..racialDescription.positive[i]
		widget.setText(listItem..".trait", text)
	end

	for i = 1, #racialDescription.negative do
		local listItem = "racialDesc.textList."..widget.addListItem("racialDesc.textList")
		local text = "^red;"..racialDescription.negative[i]
		widget.setText(listItem..".trait", text)
	end]]
end
