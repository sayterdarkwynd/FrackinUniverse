epoch={}

function epoch.currentToTable()
	return(epoch.toTable(os.time()))
end

function epoch.toTable(secs)
    local secscopy=secs
    local day=secs/86400
    local year=1970
    local month=1
    local daysperyear=365
    while (day>=daysperyear) do
       daysperyear=365
       if ((year%4)==0) or (((year%100)==0) and ((year%400)==0)) then
          daysperyear=366
       end
       day=day-daysperyear
       year=year+1
    end
    local dayspermonth={31,28,31,30,31,30,31,31,30,31,30,31}
    if ((year%4)==0) or (((year%100)==0) and ((year%400)==0)) then
       dayspermonth={31,29,31,30,31,30,31,31,30,31,30,31}
    end
    while (day>=dayspermonth[month]) do
       day=day-dayspermonth[month]
       month=month+1
    end
    day=day+1

    local hour=(secs%86400)/3600
    local minute=(secs%3600)/60
    local second=secs%60



    if (((secscopy%86400)/3600))<0 then
       day=day-1
       if day<1 then
          month=month-1
          if month<1 then
             month=12
             day=31
             year=year-1
          else
             day=dayspermonth[month]
          end
       end
    end
	hour=math.floor(hour)
	minute=math.floor(minute)
	second=math.floor(second)
	month=math.floor(month)
	day=math.floor(day)
	year=math.floor(year)
	    -- if the hour is '24' set it to '0'
    if hour==24 then
       hour=0
    end
	
    return {hour=hour,minute=minute,second=second,month=month,day=day,year=year}
end