local inputList = "inputSlotScrollArea.inputSlotList";
local outputList = "outputSlotScrollArea.outputSlotList";

buttons = {
	invertButtons = {
		item1ButtonInvert = 1,
		item2ButtonInvert = 2,
		item3ButtonInvert = 3,
		item4ButtonInvert = 4,
		item5ButtonInvert = 5
	}
}

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
	for k,v in pairs(conf[1] or {}) do
		inputSlots[k]={v,"-1"}
	end
	for k,v in pairs(conf[2] or {}) do
		outputSlots[k]={v,"-1"}
	end
	filterInverted=conf[3]
	filterType=conf[4]
	invertSlots=conf[5]
	widget.setChecked("roundRobinMode", conf[6])
	widget.setChecked("roundRobinSlotMode", conf[7])
	redrawListSlots(inputList, inputSlots);
	redrawListSlots(outputList, outputSlots);
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
	addListSlot("inputSlotCount", inputList, inputSlots, "setInputSlots")
end

function addOutputSlot()
	addListSlot("outputSlotCount", outputList, outputSlots, "setOutputSlots")
end

function addListSlot(label, list, slots, notify)
	local text = widget.getText(label)
	if text ~= "" and tonumber(text) >= 0 then
		local slot = tonumber(text);
		widget.setText(label, slot + 1);
		for _,v in pairs(slots) do
			if v[1] == slot then
				return;
			end
		end
		local item = widget.addListItem(list);
		widget.setText(list .. "." .. item .. ".slotNr", slot .. "");
		table.insert(slots, {slot, item})
		syncListSlots(slots, notify)
	end
end

function subInputSlot()
	subFromListSlots(inputList, inputSlots, "setInputSlots");
end

function subOutputSlot()
  subFromListSlots(outputList, outputSlots, "setOutputSlots");
end

function subFromListSlots(list, slots, notify)
	local item = widget.getListSelected(list)
	if item then
		for k,v in pairs(slots) do
			if v[2] == item then
				table.remove(slots, k)
				syncListSlots(slots, notify);
				redrawListSlots(list, slots);
				remaining = #slots;
				if remaining == 0 then
				elseif k >= remaining then
					widget.setListSelected(list, slots[remaining][2]);
				else
					widget.setListSelected(list, slots[k][2]);
				end
				return;
			end
		end
	end
end

function redrawListSlots(list, slots)
	widget.clearListItems(list)
	for _,v in pairs(slots) do
		local item = widget.addListItem(list);
		widget.setText(list .. "." .. item .. ".slotNr", v[1] .. "");
		v[2] = item;
	end
end

function invSlots()
	if not initialized then return end
	invertSlots[1]=widget.getChecked("invInputSlot")
	invertSlots[2]=widget.getChecked("invOutputSlot")
	world.sendEntityMessage(myBox, "setInvertSlots", invertSlots);
end

function syncListSlots(slots, notify)
	local temp={}
	for _,v in pairs(slots) do
		table.insert(temp,v[1])
	end
	world.sendEntityMessage(myBox, notify, temp);
end

function redrawItemFilters()
	for i=1,5 do
		widget.setSelectedOption("item"..i.."Filter",filterType[i])
	end
end

function redrawInvertButtons()
	for name,i in pairs(buttons.invertButtons) do
		widget.setChecked(name,filterInverted[i])
	end
end

function redrawInvertSlotButtons()
	widget.setChecked("invInputSlot",invertSlots[1])
	widget.setChecked("invOutputSlot",invertSlots[2])
end

function itemFilters()
	if not initialized then return end
	for i=1,5 do
		filterType[i]=widget.getSelectedOption("item"..i.."Filter")
	end
	world.sendEntityMessage(myBox, "setFilters", filterType);
end

function invertButtons(name)
	if not initialized then return end
	filterInverted[buttons.invertButtons[name]] = widget.getChecked(name)
	world.sendEntityMessage(myBox, "setInverts", filterInverted);
end

function roundRobinToggle(name)
	roundRobin = widget.getChecked(name)
	world.sendEntityMessage(myBox, "setRR", roundRobin)
end

function roundRobinSlotToggle(name)
	roundRobin = widget.getChecked(name)
	world.sendEntityMessage(myBox, "setRRS", roundRobin)
end



function dbg(args)
	sb.logInfo(sb.printJson(args))
end
