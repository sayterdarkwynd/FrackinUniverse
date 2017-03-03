function scanButton()
	bag=widget.itemGridItems("itemGrid")
	if bag and #bag then
		for _,item in pairs(bag) do
			sb.logInfo(sb.printJson(item))
		end
	end
end

function bye()
	pane.dismiss()

end