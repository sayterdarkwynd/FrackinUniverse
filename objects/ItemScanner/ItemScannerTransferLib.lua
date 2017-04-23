require "/scripts/kheAA/transferUtil.lua"

function scanButton()
	if not transferUtil.itemTypes then
		transferUtil.initTypes()
	end
	bag=widget.itemGridItems("itemGrid")
	if bag and #bag then
		for _,item in pairs(bag) do
			sb.logInfo("%s",item)
			sb.logInfo("%s",root.itemConfig(item))
			sb.logInfo("%s",{ transferUtil.getType(item), transferUtil.getCategory(item)})
		end
	end
end

function bye()
	pane.dismiss()

end