require "/scripts/epoch.lua"

function scanButton()
	sb.logInfo("%s",epoch.currentToTable())
end

function bye()
	pane.dismiss()

end