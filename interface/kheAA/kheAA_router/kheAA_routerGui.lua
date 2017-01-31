local inputList = "inputSlotScrollArea.inputSlotList";
local outputList = "outputSlotScrollArea.outputSlotList";


function init()
	inputSlots = {};
	outputSlots = {};
	if filterInverted == nil then
		filterInverted={}
		filterInverted[1]=true
		for i=2,5 do
			filterInverted[i]=false;
		end
	end
	if filterType == nil then
		filterType={};
		filterType[1]=true
		for i=2,5 do
			filterType[i]=-1;
		end
	end
	initialized = nil;
end

function initialize(conf)
	inputSlots={}
	for k,v in pairs(conf[1]) do
		inputSlots[k]={v,"-1"}
	end
	for k,v in pairs(conf[2]) do
		outputSlots[k]={v,"-1"}
	end
	filterInverted=conf[3]
	filterType=conf[4]
	--dbg({"conf3",conf[3],"conf4",conf[4]})
	--dbg({"filterinv",filterInverted,"filtertype",filterType})
	redrawInputSlotList()
	redrawOutputSlotList()
	redrawItemFilters()
	redrawInvertButtons()
end

function update()
	if initialized==nil then
		--redrawItemFilters()
		--redrawInvertButtons()
		myBox=pane.containerEntityId()
		position=world.entityPosition(myBox);
		promise = world.sendEntityMessage(myBox, "sendConfig")
		initialized=false
		return
	end
	if not initialized then
		if promise:finished() and promise:succeeded() then
			initialize(promise:result())
			initialized = true;
		elseif promise:finished() and not promise:succeeded() then
			promise = world.sendEntityMessage(myBox, "sendConfig")
		end
		return;
	end
end

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

function addOutputSlot()
	local text = widget.getText("outputSlotCount")
	if text ~= "" and tonumber(text) >= 0 then
		local slot = tonumber(text);
		for _,v in pairs(outputSlots) do
			if v[1] == slot then
				return;
			end
		end
		local item = widget.addListItem(outputList);
		widget.setText(outputList .. "." .. item .. ".slotNr", slot .. "");
		table.insert(outputSlots, {slot, item})
		syncOutputSlots();
	end
end

function subInputSlot()
	local item = widget.getListSelected(inputList)
	if item ~= nil then
		for k,v in pairs(inputSlots) do
			if v[2] == item then
				table.remove(inputSlots,k)
				redrawInputSlotList()
				syncInputSlots();
				return;
			end
		end
	end

end

function redrawInputSlotList()
	widget.clearListItems(inputList)
	for _,v in pairs(inputSlots) do
		local item = widget.addListItem(inputList);
		widget.setText(inputList .. "." .. item .. ".slotNr", v[1] .. "");
		v[2] = item;
	end
end

function subOutputSlot()
	local item = widget.getListSelected(outputList)
	if item ~= nil then
		for k,v in pairs(outputSlots) do
			if v[2] == item then
				table.remove(outputSlots, k)
				syncOutputSlots();
				redrawOutputSlotList()
				return;
			end
		end
	end
end

function redrawOutputSlotList()
	widget.clearListItems(outputList)
	for _,v in pairs(outputSlots) do
		local item = widget.addListItem(outputList);
		widget.setText(outputList .. "." .. item .. ".slotNr", v[1] .. "");
		v[2] = item;
	end
end

function syncInputSlots()
	local temp={}
	for _,v in pairs(inputSlots) do
		table.insert(temp,v[1])
	end
	world.sendEntityMessage(myBox, "setInputSlots", temp);
end

function syncOutputSlots()
	local temp={}
	for _,v in pairs(outputSlots) do
		table.insert(temp,v[1])
	end
	world.sendEntityMessage(myBox, "setOutputSlots", temp);
end

function redrawItemFilters() --int widget.getSelectedOption(String widgetName)
	for i=1,5 do
		widget.setSelectedOption("item"..i.."Filter",filterType[i])
	end
end

function redrawInvertButtons()
	for i=1,5 do
		widget.setChecked("item"..i.."ButtonInvert",filterInverted[i])
	end
end

function itemFilters() --int widget.getSelectedOption(String widgetName)
	if not initialized==true then return end
	for i=1,5 do
		filterType[i]=widget.getSelectedOption("item"..i.."Filter")
	end
	--dbg(filterType)
	world.sendEntityMessage(myBox, "setFilters", filterType);
end

function invertButtons()
	if not initialized==true then return end
	for i=1,5 do
		filterInverted[i]=widget.getChecked("item"..i.."ButtonInvert")
	end
	world.sendEntityMessage(myBox, "setInverts", filterInverted);
end



function dbg(args)
	sb.logInfo(sb.printJson(args))
end