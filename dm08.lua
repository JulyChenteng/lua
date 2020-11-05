local t_startTime = 20200101000010
t_startTime = math.floor(t_startTime/1000000)
print(t_startTime)
local t_day = t_startTime % 100
print(t_day)
local t_month =math.floor((t_startTime % 10000)/100)
print(t_month)
local t_year = math.floor(t_startTime/10000)
print(t_year)
local t_time = os.time{year=t_year, month=t_month, day=t_day, hour=0, min = 0, sec=0}
print(t_time)
time=t_time-86400                                                                                                                    
time = os.date("%Y%m%d%H%M%S",time)
print(time)

