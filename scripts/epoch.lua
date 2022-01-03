epoch={}

function epoch.currentToTable()
	return(epoch.toTable(os.time()))
end

--new code, from https://stackoverflow.com/questions/17872997/how-do-i-convert-seconds-since-epoch-to-current-date-and-time
-- based on http://www.ethernut.de/api/gmtime_8c_source.html

local floor=math.floor

local DSEC=24*60*60 -- secs in a day
local YSEC=365*DSEC -- secs in a year
local LSEC=YSEC+DSEC    -- secs in a leap year
local FSEC=4*YSEC+DSEC  -- secs in a 4-year interval
local BASE_DOW=4    -- 1970-01-01 was a Thursday
local BASE_YEAR=1970    -- 1970 is the base year

local _days={
    -1, 30, 58, 89, 119, 150, 180, 211, 242, 272, 303, 333, 364
}
local _lpdays={}
for i=1,2  do _lpdays[i]=_days[i]   end
for i=3,13 do _lpdays[i]=_days[i]+1 end

function epoch.toTable(t)
	--print(os.date("!\n%c\t%j",t),t)
    local y,j,m,d,w,h,n,s
    local mdays=_days
    s=t
    -- First calculate the number of four-year-interval, so calculation
    -- of leap year will be simple. Btw, because 2000 IS a leap year and
    -- 2100 is out of range, this formula is so simple.
    y=floor(s/FSEC)
    s=s-y*FSEC
    y=y*4+BASE_YEAR         -- 1970, 1974, 1978, ...
    if s>=YSEC then
        y=y+1           -- 1971, 1975, 1979,...
        s=s-YSEC
        if s>=YSEC then
            y=y+1       -- 1972, 1976, 1980,... (leap years!)
            s=s-YSEC
            if s>=LSEC then
                y=y+1   -- 1971, 1975, 1979,...
                s=s-LSEC
            else        -- leap year
                mdays=_lpdays
            end
        end
    end
    j=floor(s/DSEC)
    s=s-j*DSEC

    m=1
    while mdays[m]<j do m=m+1 end
    m=m-1

    d=j-mdays[m]
    -- Calculate day of week. Sunday is 0
    w=(floor(t/DSEC)+BASE_DOW)%7
    -- Calculate the time of day from the remaining seconds
    h=floor(s/3600)
    s=s-h*3600
    n=floor(s/60)
    s=s-n*60
	return {hour=h,minute=n,second=s,month=m,day=d,year=y,dow=w}
    --[[print("y","j","m","d","w","h","n","s")
    print(y,j+1,m,d,w,h,n,s)]]
	
end
--[[
local t=os.time()
gmtime(t)

t=os.time{year=1970, month=1, day=1, hour=0} gmtime(t)
t=os.time{year=1970, month=1, day=3, hour=0} gmtime(t)
t=os.time{year=1970, month=1, day=2, hour=23-3, min=59, sec=59} gmtime(t)]]

--old, outdated, broke 12-31-2021
--[[function epoch.toTable(secs)
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
		--sb.logInfo("%s",{secscopy,day,year,month,daysperyear})
		while (day>=dayspermonth[month]) do
		--sb.logInfo("%s",{day,dayspermonth,month})
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
end]]
