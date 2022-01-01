require "/scripts/util.lua"
local deltatime=0

function init()
	promise=nil
	self={}
	items = {}
	deltatime=30
	pos = world.entityPosition(pane.containerEntityId())
	widget.addListItem("scrollArea.itemList")
	filterText = ""
	--widget.focus("filterBox")
	maxItemsAddedPerUpdate = config.getParameter("maxItemsAddedPerUpdate", 5000)
	maxSortsPerUpdate = config.getParameter("maxSortsPerUpdate", 50000)
	maxItemsForSorting = config.getParameter("maxItemsForSorting", 1000)
	refresh()
end

function refresh()
	if not self then init() end

	items={}
	if self.inContainers then
		for id, pos in pairs(self.inContainers) do
			if id and world.entityExists(id) then
				for i, item in pairs(world.containerItems(id) or {}) do
					table.insert(items, {{id, i}, item, root.itemConfig(item, item.level, item.seed), pos})
				end
			end
		end
	end
	refreshingList = coroutine.create(refreshList)
end

function update(dt)
	deltatime=deltatime+dt

	if updateFilterQueueTimer then
		if updateFilterQueueTimer<=0.0 then
			filterText = widget.getText("filterBox")
			refreshingList = coroutine.create(refreshList)
			updateFilterQueueTimer=nil
		else
			updateFilterQueueTimer=updateFilterQueueTimer-dt
		end
	end
	if refreshingList and coroutine.status(refreshingList) ~= "dead" then
		local a, b = coroutine.resume(refreshingList)
		--sb.logInfo(tostring(a).." : "..tostring(b))
	end

	promise = promise or world.sendEntityMessage(pane.containerEntityId(), "transferUtil.sendConfig")

	if promise:finished() then
		if promise:succeeded() then
			self = promise:result()
			if deltatime > 30 then
				refresh()
				deltatime=0
			end
		end
		promise = nil
	end
end

function clearInputs()
	widget.setText("filterBox", "")
	widget.setText("requestAmount", "")
	refreshingList = coroutine.create(refreshList)
end

function getIcon(item, conf, listItem)
	local icon = item.parameters.inventoryIcon or conf.config.inventoryIcon or conf.config[(conf.config.category or "").."Icon"] or conf.config.icon
	if icon then
		if type(icon) == "string" then
			icon = absolutePath(conf.directory, icon)
			widget.setImage("scrollArea.itemList." .. listItem .. ".itemIcon", icon)
		elseif type(icon) == "table" then
			for _,v in pairs(icon) do
				local listSubItem = widget.addListItem("scrollArea.itemList" .. "." .. listItem .. ".compositeIcon")
				widget.setImage("scrollArea.itemList." .. listItem .. ".compositeIcon." .. listSubItem ..".icon", absolutePath(conf.directory, v.image))
			end
		end
	end
end

function refreshList()
	widget.clearListItems("scrollArea.itemList")
	if #items <= maxItemsForSorting then
		sortItems()
	end
	for i = 1, #items do
		local item = items[i][2]
		local conf = items[i][3]
		local name = item.parameters.shortdescription or conf.config.shortdescription

		if filterText == "" or comparableName(name):find(comparableFilter()) then
			local listItem = widget.addListItem("scrollArea.itemList")
			widget.setText("scrollArea.itemList." .. listItem .. ".itemName", name)
			widget.setText("scrollArea.itemList." .. listItem .. ".amount", "×" .. item.count)
			pcall(getIcon, item, conf, listItem)
			widget.setData("scrollArea.itemList." .. listItem, items[i])
		end

		if i % maxItemsAddedPerUpdate == 0 then
			coroutine.yield()
		end
	end
end

function filterBox()
	updateFilterQueueTimer=0.10
end

function comparableFilter()
	return filterText:gsub('([%(%)%%%.%+%-%*%[%]%?%^%$])', '%%%1'):upper()
end

function comparableName(name)
	return name:gsub('%^#?%w+;', '') -- removes the color encoding from names, e.g. ^blue;Madness^reset; -> Madness
		:gsub('ū', 'u')
		:upper()
end

function request()
	local selected = widget.getListSelected("scrollArea.itemList")
	local data = widget.getData("scrollArea.itemList." .. tostring(selected))
	if data then
		requestItem(selected, data[2].count)
	end
end

function updateListItem(selectedItem, count)
	if count > 0 then
		widget.setText("scrollArea.itemList." .. selectedItem .. ".amount", "×" .. count)
		deltatime=0
	else
		deltatime=29.9
		refreshingList = coroutine.create(refreshList)
	end
end

function requestAllButOne()
	local selected = widget.getListSelected("scrollArea.itemList")
	local data = widget.getData("scrollArea.itemList." .. tostring(selected))
	if data then
		requestItem(selected, data[2].count - 1)
	end
end

--[[

function addInputSlot()
	local text = widget.getText("inputSlotCount")
	if text ~= "" and tonumber(text) >= 0 then
		local slot = tonumber(text)
		for _,v in pairs(inputSlots) do
			if v[1] == slot then
				return
			end
		end
		local item = widget.addListItem(inputList)
		widget.setText(inputList .. "." .. item .. ".slotNr", slot .. "")
		table.insert(inputSlots, {slot, item})
		syncInputSlots()
	end
end


]]

function requestOne()
	local text = widget.getText("requestAmount")
	if text == "" then
		text = "1"
	end
	if tonumber(text) >= 0 then
		local selected = widget.getListSelected("scrollArea.itemList")
		local data = widget.getData("scrollArea.itemList." .. tostring(selected))
		if data then
			requestItem(selected, math.min(tonumber(text), data[2].count))
		end
	end
end

function absolutePath(directory, path)
	if type(path) ~= "string" then
		return false
	end
	if string.sub(path, 1, 1) == "/" then
		return path
	else
		return directory..path
	end
end

function requestItem(selected, amount)
	local data = widget.getData("scrollArea.itemList." .. selected)
	if data then
		local itemToSend = copy(data)
		itemToSend[2].count = amount
		table.insert(itemToSend,world.entityPosition(pane.playerEntityId()))
		world.sendEntityMessage(pane.containerEntityId(), "transferItem", itemToSend)
		local newCount = data[2].count - amount
		data[2].count = newCount
		updateListItem(selected, newCount)
		return
	end
end

--Quicksort code (based on https://www.geeksforgeeks.org/quick-sort/ )
function sortItems(low, high)
	low = low or 1
	high = high or #items
	numSorts = numSorts or 1
	if low < high then
		local part = partition(low, high)
		sortItems(low, part - 1)
		sortItems(part + 1, high)
	end
end

function partition(low, high)
	pivot = items[high]
	i = (low - 1)
	for j = low, high - 1 do
		if compareByName(items[j], pivot) then
			i = i + 1
			items[i], items[j] = items[j], items[i]
		end

		numSorts = numSorts + 1
		if numSorts % maxSortsPerUpdate == 0 then
			coroutine.yield()
		end
	end
	items[i + 1], items[high] = items[high], items[i + 1]
	return i + 1
end

function compareByName(itemA, itemB)
	local a = comparableName(itemA[3].config.shortdescription)
	local b = comparableName(itemB[3].config.shortdescription)
	return a == b and itemA[2].count < itemB[2].count or a < b
end
