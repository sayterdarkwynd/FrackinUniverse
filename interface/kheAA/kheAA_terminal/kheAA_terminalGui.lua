require "/scripts/util.lua"
local itemList = "scrollArea.itemList";
local deltatime=0;

function init()
	promise=nil
	storage={}
	storage.inContainers={}
	items = {};
	deltatime=30;
	pos = world.entityPosition(pane.containerEntityId());
	widget.addListItem("scrollArea.itemList")
	filterText = "";
	--widget.focus("filterBox")
	refresh()
end


function update(dt)
	deltatime=deltatime+dt;
	if promise~=nil and promise:finished() then
		if promise:succeeded() then
			local res=promise:result();
			storage=res
			promise=nil;
			if deltatime > 30 then
				refresh();
				deltatime=0;
			end
		end
		promise=nil
	else
		if promise==nil then
			promise=world.sendEntityMessage(pane.containerEntityId(),"transferUtil.sendConfig")
		end
		if not promise:finished() then
		end
	end
end



function refresh()
	if storage==nil then
		init()
	end

	local blankList=false
	if storage.inContainers==nil then
		blankList=true
	elseif util.tableSize(storage.inContainers) == 0 then
		blankList=true
	end
	items={};
	if not blankList then
		for entId,pos in pairs(storage.inContainers) do
			containerFound(entId,pos)
		end
	end
	refreshList()
end

function containerFound(containerID,pos)
	if containerID == nil then return false end
	--if not world.regionActive(rectPos) then return false end
	if not world.entityExists(containerID) then return false end

	local containerItems = world.containerItems(containerID)
	for index,item in pairs(containerItems) do
		local conf = root.itemConfig(item, item.level or nil, item.seed or nil)
		table.insert(items, {{containerID, index}, item, conf,pos})
	end
	refreshList()
	return true;
end


function sortByName(itemA, itemB)
	local sort = getName(itemA[3].config.shortdescription) < getName(itemB[3].config.shortdescription);
	if itemA[3].config.shortdescription == itemB[3].config.shortdescription then
		sort = itemA[2].count < itemB[2].count;
	end
	return sort;
end

function getName(fullName)
	pattern = "%^#%w%w%w%w%w%w;"
	name = string.gsub(fullName, pattern, "")
	return (fullName:gsub("^%l", string.upper))
end

function getIcon(item, conf, listItem)
	local icon = item.parameters.inventoryIcon or conf.config.inventoryIcon or conf.config[(conf.config.category or "").."Icon"] or conf.config.icon
	if icon then
		if type(icon) == "string" then
			icon = absolutePath(conf.directory, icon)
			widget.setImage(itemList .. "." .. listItem .. ".itemIcon", icon)
			--local imageSize = rect.size(root.nonEmptyRegion(icon))
			--local scaleDown = math.max(math.ceil(imageSize[1] / iconSize[1]), math.ceil(imageSize[2] / iconSize[2]))
			--widget.setImageScale(string.format("%s.%s.icon", self.list, item), 1 / scaleDown)
		elseif type(icon) == "table" then
			--sb.logInfo("%s",icon)
			for i,v in pairs(icon) do
				local item = widget.addListItem(itemList .. "." .. listItem .. ".compositeIcon")
				widget.setImage(itemList .. "." .. listItem .. ".compositeIcon." .. item ..".icon", absolutePath(conf.directory, v.image))
			end
		end
	end
end

function refreshList()
	listItems = {};
	widget.clearListItems(itemList);
	table.sort(items, sortByName);
	for i = 1, #items do
		local item = items[i][2]
		local conf = items[i][3]
		local filterOk = true;
		local name = item.parameters.shortdescription or conf.config.shortdescription

		if filterText ~= "" then
			if string.find(string.upper(name), string.upper(formatpattern(filterText))) == nil then
				filterOk = false;
			end
		end
		if filterOk then
			local listItem = widget.addListItem(itemList)
			widget.setText(itemList .. "." .. listItem .. ".itemName", name);
			widget.setText(itemList .. "." .. listItem .. ".amount", "x" .. item.count);
			pcall(getIcon, item, conf, listItem);
			listItems[listItem] = items[i];
		end
	end
end

function filterBox()
	filterText = widget.getText("filterBox");
	refreshList();
end

function request()
	--pane.playerEntityId()
	local selected = widget.getListSelected(itemList)
	if selected ~= nil and listItems ~= nil and listItems[selected] ~= nil then
		for i = 1, #items do
			if items[i] == listItems[selected] then
				local itemToSend=items[i]
				table.insert(itemToSend,world.entityPosition(pane.playerEntityId()))
				--sb.logInfo(sb.printJson({playerPos=temp}))

				world.sendEntityMessage(pane.containerEntityId(), "transferItem",itemToSend)
				table.remove(items, i);
				refreshList();
				return;
			end
		end
	end
end

function requestAllButOne()
	--pane.playerEntityId()
	local selected = widget.getListSelected(itemList)
	if selected ~= nil and listItems ~= nil and listItems[selected] ~= nil then
		for i = 1, #items do
			if items[i] == listItems[selected] then
				local itemToSend=items[i]
				itemToSend[2].count=itemToSend[2].count-1
				table.insert(itemToSend,world.entityPosition(pane.playerEntityId()))
				--sb.logInfo(sb.printJson({playerPos=temp}))

				world.sendEntityMessage(pane.containerEntityId(), "transferItem",itemToSend)
				--table.remove(items, i);
				items[i][2].count=1
				deltatime=29.9
				refreshList();
				return;
			end
		end
	end
end

--[[

function addInputSlot()
	local text = widget.getText("inputSlotCount")
	if text ~= "" and tonumber(text) >= 0 then
		local slot = tonumber(text);
		for _,v in pairs(inputSlots) do
			if v[1] == slot then
				return;
			end
		end
		local item = widget.addListItem(inputList);
		widget.setText(inputList .. "." .. item .. ".slotNr", slot .. "");
		table.insert(inputSlots, {slot, item})
		syncInputSlots();
	end
end


]]

function requestOne()
	local text = widget.getText("requestAmount")
	if text ~= "" and tonumber(text) >= 0 then
		--pane.playerEntityId()
		--itemData={containerID, index}, itemDescriptor, itemConfig,pos
		local selected = widget.getListSelected(itemList)
		if selected ~= nil and listItems ~= nil and listItems[selected] ~= nil then
			for i = 1, #items do
				if items[i] == listItems[selected] then
					local itemToSend=copy(items[i])
					--sb.logInfo("%s",itemToSend)
					itemToSend[2].count=math.min(tonumber(text),itemToSend[2].count)

					table.insert(itemToSend,world.entityPosition(pane.playerEntityId()))
					--sb.logInfo(sb.printJson({playerPos=temp}))
					world.sendEntityMessage(pane.containerEntityId(), "transferItem",itemToSend)
					--table.remove(items, i);
					items[i][2].count=items[i][2].count-1
					deltatime=29.9
					refreshList();
					return;
				end
			end
		end
	end
end

function absolutePath(directory, path)
	if type(path) ~= "string" then
		return false;
	end
	if string.sub(path, 1, 1) == "/" then
		return path
	else
		return directory..path
	end
end

function formatpattern(str)
  local str = string.gsub(str,"%(","%%(")
  local str = string.gsub(str,"%)","%%)")
  local str = string.gsub(str,"%.","%%.")
  local str = string.gsub(str,"%%","%%%%")
  local str = string.gsub(str,"%+","%%+")
  local str = string.gsub(str,"%-","%%-")
  local str = string.gsub(str,"%*","%%*")
  local str = string.gsub(str,"%?","%%?")
  local str = string.gsub(str,"%[","%%[")
  local str = string.gsub(str,"%]","%%]")
  local str = string.gsub(str,"%^","%%^")
  local str = string.gsub(str,"%$","%%$")
  return str
end
