liquidLib = {}
liquidLib.liquidIds={}
liquidLib.liquidIds[100]="liquidaether";
liquidLib.liquidIds[69]="liquidwastewater";
liquidLib.liquidIds[68]="liquidmetallichydrogen";
liquidLib.liquidIds[67]="liquiddeuterium";
liquidLib.liquidIds[66]="fu_hydrogenmetallic";
liquidLib.liquidIds[65]="sand";
liquidLib.liquidIds[64]="liquidbioooze";
liquidLib.liquidIds[63]="fu_nitrogen";
liquidLib.liquidIds[62]="fu_hydrogen";
liquidLib.liquidIds[61]="liquidcrystal";
liquidLib.liquidIds[60]="liquiddarkwater";
liquidLib.liquidIds[59]="liquidcrystal";
liquidLib.liquidIds[58]="liquidwastewater";
liquidLib.liquidIds[57]="fu_liquidhoney";
liquidLib.liquidIds[56]="liquidnitrogenitem";
liquidLib.liquidIds[55]="liquidalienjuice";
liquidLib.liquidIds[54]="fu_liquidhoney";
liquidLib.liquidIds[53]="liquidpus";
liquidLib.liquidIds[52]="liquidironfu";
liquidLib.liquidIds[51]="liquidgravrain";
liquidLib.liquidIds[50]="shadowgasliquid";
liquidLib.liquidIds[49]="helium3gasliquid";
liquidLib.liquidIds[48]="ff_mercury";
liquidLib.liquidIds[47]="liquidirradium";
liquidLib.liquidIds[46]="liquidsulphuricacid";
liquidLib.liquidIds[45]="liquidelderfluid";
liquidLib.liquidIds[44]="vialproto";
liquidLib.liquidIds[43]="liquidorganicsoup";
liquidLib.liquidIds[42]="liquidblacktar";
liquidLib.liquidIds[41]="liquidbioooze";
liquidLib.liquidIds[40]="liquidblood";
liquidLib.liquidIds[13]="liquidslime";
liquidLib.liquidIds[12]="swampwater";
liquidLib.liquidIds[11]="liquidfuel";
liquidLib.liquidIds[9]="liquidcoffee";
liquidLib.liquidIds[7]="liquidmilk";
liquidLib.liquidIds[6]="liquidhealing";
liquidLib.liquidIds[5]="liquidoil";
liquidLib.liquidIds[4]="liquidalienjuice";
liquidLib.liquidIds[3]="liquidpoison";
liquidLib.liquidIds[2]="liquidlava";
liquidLib.liquidIds[1]="liquidwater";

function liquidLib.itemToLiquidId(item)
	for i,v in liquidLib.liquidIds do
		if item.name==v then
			return i
		end 
	end
	return nil
end

function liquidLib.itemToLiquidLevel(itemDescriptor)
	for i,v in ipairs(liquidLib.liquidIds) do
		if itemDescriptor.name==v then
			return {i,itemDescriptor.count}
		end 
	end

	return nil
end

function liquidLib.liquidLevelToItem(liqLvl)
	return liquidLib.liquidToItem(liqLvl[1],liqLvl[2])
end

function liquidLib.liquidToItem(liquidId,level)
	for i,v in liquidLib.liquidIds do
	if i==liquidid then
		temp=i;
		break;
	end
	end
	if(temp~=nil)then
		if(#level>0) then
			return{name=temp,count=level,parameters={}}
		else
		return temp
		end
	end
	return nil
end

function liquidLib.canReceiveLiquid()
		if storage.receiveLiquid~=nil then
		if storage.receiveLiquid then
			return true
		end
	end
	return nil
end
--[[
function receiveLiquid(liquidId, liquidLevel, pathIds)
	return transferUtil.sendLiquid(liquidId, liquidLevel, entity.id(), pathIds)
end]]--

--[[
function liquidLib.sendLiquid(liquidType, liquidLevel, fromId, pathIds)
	if pathIds==nil then pathIds={} end
	pathIds[fromId] = #pathIds

	local outputIds = liquidLib.getOutputIds()
	local remainingLiquid = liquidLevel
	for _, outputId in ipairs(outputIds) do 
		if pathIds[outputId]==nil and world.callScriptedEntity(outputId, "canReceiveLiquid", liquidType, remainingLiquid) then
			remainingLiquid = world.callScriptedEntity(outputId, "receiveLiquid", liquidType, remainingLiquid, pathIds )
			if remainingLiquid == 0 then
				break
			end 
		end
	end

	return remainingLiquid	
end]]--