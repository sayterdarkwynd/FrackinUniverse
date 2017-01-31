local itemList = "scrollArea.itemList";
local deltatime=0;

function init()
	promise=nil
	storage={}
	storage.inContainers={}
	items = {};
	deltatime=30;
	pos = world.entityPosition(pane.containerEntityId());
	initialized = false;
	widget.addListItem("scrollArea.itemList")
	filterText = "";
	widget.focus("filterBox")
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
		return
	end
	if storage.inContainers==nil then
		return
	end
	if not #storage.inContainers then
		return
	end
	items={};
	for x,_ in pairs(storage.inContainers) do
		containerFound(x)
	end
end

function containerFound(containerID)
	local containerItems = world.containerItems(containerID)
	for i,v in pairs(containerItems) do
		local conf = root.itemConfig(v, v.level or nil, v.seed or nil)
		table.insert(items, {{containerID, i}, v, conf})
	end
	refreshList()
	return true;
end


function sortByName(itemA, itemB)
	local sort = itemA[3].config.shortdescription < itemB[3].config.shortdescription;
	if itemA[3].config.shortdescription == itemB[3].config.shortdescription then
		sort = itemA[2].count < itemB[2].count;
	end
	return sort; 
end

function getIcon(item, conf, listItem)
	local icon = item.parameters.inventoryIcon or conf.config.inventoryIcon
	if icon ~= nil and type(icon) == "string" then
			icon = absolutePath(conf.directory, icon)
			widget.setImage(itemList .. "." .. listItem .. ".itemIcon", icon)
		elseif icon ~= nil and type(icon) == "table" then
			for i,v in pairs(icon) do
				local item = widget.addListItem(itemList .. "." .. listItem .. ".compositeIcon")
				widget.setImage(itemList .. "." .. listItem .. ".compositeIcon." .. item ..".icon", absolutePath(conf.directory, v.image))
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
				local name = conf.config.shortdescription
				
				if filterText ~= "" then
			if string.find(string.upper(name), string.upper(filterText)) == nil then
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
	local selected = widget.getListSelected(itemList)
	if selected ~= nil and listItems ~= nil and listItems[selected] ~= nil then
		world.sendEntityMessage(pane.containerEntityId(), "transferItem", listItems[selected][1])
		for i = 1, #items do
			if items[i] == listItems[selected] then
				table.remove(items, i);
				refreshList();
				return;
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