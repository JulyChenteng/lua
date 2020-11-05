local llStdTotalVol	= 0;	-- 整个会话标准化后的资源量(包含本条分话单的资源量)
local llStdAddVol	= 0;	-- 整个会话标准化后的累计资源量(包含本条分话单的资源量)
local llStdUpVol	= 0;	-- 本条分话单标准化后的上行资源量
local llStdDnVol	= 0;	-- 本条分话单标准化后的下行资源量
local llStdSumVol	= 0;	-- 本条分话单标准化后的下行资源量
local llStdDnVol1 = 0;


local t_lUpVolume = 765
local t_lDnVolume = 587
-- UP_VOLUME向下规整为1024的倍数,剩下的部分加到DOWN_VOLUME中并向上规整为1024的倍数
llStdUpVol	= (math.floor(t_lUpVolume / 1024)) * 1024;
llStdDnVol	= (math.floor( ( (t_lUpVolume % 1024) + t_lDnVolume + 1023 ) / 1024 )) * 1024;

print(llStdUpVol)
print(llStdDnVol)
print("")

local t_lFlowRatingRes  = 0;
local t_iMesureUnit     = 0;
local t_iVolumeAddUpSwitch = 0
local retTotalVolume = 0;

local t_lDataFlowUp1 = 0
local t_lDataFlowDn1 = 0
local t_lDataFlowUp2 = 765
local t_lDataFlowDn2 = 587
local t_iVolumeAddUp = 1352

--AMOUNT_RES规整为:原AMOUNT_RES + VOLUME_ADDUP向上规整 - VOLUME_ADDUP向上规整
--BEGIN_RES置为0
llStdTotalVol = ( math.floor( ( t_lDataFlowUp1 + t_lDataFlowDn1 +t_iVolumeAddUp + math.floor( ( (t_lDataFlowUp2 + t_lDataFlowDn2 + t_iVolumeAddUpSwitch ) * 100 + 99) / 100) + 1023 ) / 1024 ) ) * 1024;
llStdAddVol	= ( math.floor( (t_iVolumeAddUp + math.floor( (t_iVolumeAddUpSwitch * 100 + 99) / 100) + 1023) / 1024 	) ) * 1024; 

retTotalVolume	= llStdTotalVol - llStdAddVol;

print(llStdTotalVol)
print(llStdAddVol)
print(retTotalVolume)
-- UP_VOLUME向下规整为1024的倍数,剩下的部分加到DOWN_VOLUME中并向上规整为1024的倍数
llStdUpVol	= (math.floor(t_lUpVolume / 1024)) * 1024;
llStdDnVol	= (math.floor( ( (t_lUpVolume % 1024) + t_lDnVolume + 1023 ) / 1024 )) * 1024;
if llStdUpVol + llStdDnVol >= retTotalVolume	then
     llStdDnVol	= retTotalVolume - llStdUpVol;
end

print(math.floor((t_lDataFlowUp2 * 100+99) / 100))
print(math.floor((t_lDataFlowDn2 * 100+99) / 100))

tp = string.gsub("0001111","^[0]+","")
print(tp)

lc = string.sub(string.gsub("012", "^[0]+", ""), -4, -1)
print(lc)
lc = string.sub("160F8264F00077EA64F00007898603",2,6)
print(lc)
lc = string.sub("160F8264F00077EA64F00007898603",4)
print(lc)