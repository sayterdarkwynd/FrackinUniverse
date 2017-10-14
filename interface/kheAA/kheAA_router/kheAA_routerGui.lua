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
	if invertSlots==nil then invertSlots={false,false} end
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
	invertSlots=conf[5]
	redrawInputSlotList()
	redrawOutputSlotList()
	redrawItemFilters()
	redrawInvertButtons()
	redrawInvertSlotButtons()
end

function update()
	if initialized==nil then
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
		widget.setText("inputSlotCount", slot + 1);
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
		widget.setText("outputSlotCount", slot + 1);
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

function redrawInputSlotList()
	widget.clearListItems(inputList)
	for _,v in pairs(inputSlots) do
		local item = widget.addListItem(inputList);
		widget.setText(inputList .. "." .. item .. ".slotNr", v[1] .. "");
		v[2] = item;
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

function invSlots()
	if not initialized==true then return end
	invertSlots[1]=widget.getChecked("invInputSlot")
	invertSlots[2]=widget.getChecked("invOutputSlot")
	world.sendEntityMessage(myBox, "setInvertSlots", invertSlots);
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

function redrawItemFilters()
	for i=1,5 do
		widget.setSelectedOption("item"..i.."Filter",filterType[i])
	end
end

function redrawInvertButtons()
	for i=1,5 do
		widget.setChecked("item"..i.."ButtonInvert",filterInverted[i])
	end
end

function redrawInvertSlotButtons()
	widget.setChecked("invInputSlot",invertSlots[1])
	widget.setChecked("invOutputSlot",invertSlots[2])
end

function itemFilters()
	if not initialized==true then return end
	for i=1,5 do
		filterType[i]=widget.getSelectedOption("item"..i.."Filter")
	end
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
