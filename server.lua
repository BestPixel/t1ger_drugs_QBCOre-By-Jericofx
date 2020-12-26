-------------------------------------
------- Created by T1GER#9080 -------
------------------------------------- 

RSCore = nil

TriggerEvent('RSCore:GetObject', function(obj) RSCore = obj end)

-- START TEST
local JobCooldown 		= {}
local ConvertTimer		= {}
local DrugEffectTimer	= {}
local soldAmount 		= {}

RegisterServerEvent("t1ger_drugs:syncJobsData")
AddEventHandler("t1ger_drugs:syncJobsData",function(data)
	TriggerClientEvent("t1ger_drugs:syncJobsData",-1,data)
end)

-- Server side table, to store cooldown for players:
RegisterServerEvent("t1ger_drugs:addCooldownToSource")
AddEventHandler("t1ger_drugs:addCooldownToSource",function(source)
	table.insert(JobCooldown,{cooldown = GetPlayerIdentifier(source), time = (Config.CooldownTime * 60000)})
end)

-- Server side table, to store convert timer for players:
RegisterServerEvent("t1ger_drugs:addConvertingTimer")
AddEventHandler("t1ger_drugs:addConvertingTimer",function(source,timer)
	table.insert(ConvertTimer,{convertWait = GetPlayerIdentifier(source), timeB = timer})
end)

-- Server side table, to store drug effect timer for players:
RegisterServerEvent("t1ger_drugs:addDrugEffectTimer")
AddEventHandler("t1ger_drugs:addDrugEffectTimer",function(source,timer)
	table.insert(DrugEffectTimer,{effectWait = GetPlayerIdentifier(source), timeC = timer})
end)

-- CreateThread Function for timer:
Citizen.CreateThread(function() -- do not touch this thread function!
	while true do
	Citizen.Wait(1000)
		for k,v in pairs(JobCooldown) do
			if v.time <= 0 then
				RemoveCooldown(v.cooldown)
			else
				v.time = v.time - 1000
			end
		end
		for k,v in pairs(ConvertTimer) do
			if v.timeB <= 0 then
				RemoveConvertTimer(v.convertWait)
			else
				v.timeB = v.timeB - 1000
			end
		end
		for k,v in pairs(DrugEffectTimer) do
			if v.timeC <= 0 then
				RemoveDrugEffectTimer(v.effectWait)
			else
				v.timeC = v.timeC - 1000
			end
		end
	end
end)

-- Usable item to start drugs jobs:
RSCore.Functions.CreateUseableItem('drugItem', function(source)
	local xPlayer = RSCore.Functions.GetPlayer(source)
	if not HasCooldown(GetPlayerIdentifier(source)) then
		if xPlayer.Functions.GetItemByName(Config.HackerDevice).amount >= 1 then
			TriggerClientEvent("t1ger_drugs:UsableItem",source)
		else
			TriggerClientEvent('RSCore:Notify', source, "You need a ~r~Hacking Device~s~ to use the ~y~USB~s~")
		end
 	else
	 	TriggerClientEvent("RSCore:Notify",source,string.format("~y~USB~s~ is usable in: ~b~%s minutes~s~",GetCooldownTime(GetPlayerIdentifier(source))))
  	end
end)

-- Server Event for Buying Drug Job:
RegisterServerEvent("t1ger_drugs:GetSelectedJob")
AddEventHandler("t1ger_drugs:GetSelectedJob", function(drugType,BuyPrice,minReward,maxReward)
	local xPlayer = RSCore.Functions.GetPlayer(source)
	local itemLabel = RSCore.Functions.GetItemByName(itemName)
	if xPlayer.PlayerData.money >= BuyPrice then
		xPlayer.Functions.RemoveMoney(BuyPrice)
		TriggerEvent("t1ger_drugs:addCooldownToSource",source)
		TriggerClientEvent("t1ger_drugs:BrowseAvailableJobs",source, 0, drugType, minReward, maxReward)
		if drugType == "coke" then
			label = "Coke"
		elseif drugType == "meth" then
			label = "Meth"
		elseif drugType == "weed" then
			label = "Weed"
		end	
		TriggerClientEvent("RSCore:Notify",source,"You paid ~g~$"..BuyPrice.."~s~ for a ~r~"..label.."~s~ job")
	else
		TriggerClientEvent("RSCore:Notify",source,"You don't have enough money")
	end
end)

-- Server Event for Job Reward:
RegisterServerEvent("t1ger_drugs:JobReward")
AddEventHandler("t1ger_drugs:JobReward",function(minReward,maxReward,typeDrug)
	local minDrugReward = minReward
	local maxDrugReward = maxReward
	local xPlayer = RSCore.Functions.GetPlayer(source)
	drugAmount = math.random(minDrugReward,maxDrugReward)
	xPlayer.Function.Additem(typeDrug.."brick",math.ceil(drugAmount))
end)

-- Usable item for drug effects:
Citizen.CreateThread(function()
	for k,v in pairs(Config.DrugEffects) do 
		RSCore.Functions.CreateUseableItem(v.UsableItem, function(source)
			local xPlayer = RSCore.Functions.GetPlayer(source)
			local itemLabel = RSCore.Functions.GetItemByName(v.UsableItem)
			
			if not DrugEffect(GetPlayerIdentifier(source)) then
				TriggerEvent("t1ger_drugs:addDrugEffectTimer",source,v.UsableTime)
				xPlayer.Functions.RemoveItem(v.UsableItem,1)
				TriggerClientEvent("t1ger_drugs:DrugEffects",source,k,v)
			else
				TriggerClientEvent("RSCore:Notify",source,string.format("You are ~b~already~s~ consuming a drug",GetDrugEffectTime(GetPlayerIdentifier(source))))	
			end	
		end)
	end
end)

-- Usable item to convert drugs:
Citizen.CreateThread(function()
	for k,v in pairs(Config.DrugConversion) do 
		RSCore.Functions.CreateUseableItem(v.UsableItem, function(source)
			local xPlayer = RSCore.Functions.GetPlayer(source)
			local itemLabel = RSCore.Functions.GetItemByName(v.UsableItem)
			local drugOutput
			local requiredItems
			
			local scale = xPlayer.Functions.GetItemByName(v.hqscale).amount >= 1
			if v.HighQualityScale then
				if scale then
					drugOutput = v.RewardAmount.b
					requiredItems = v.RequiredItemAmount.d
				else
					drugOutput = v.RewardAmount.a
					requiredItems = v.RequiredItemAmount.c
				end
			else
				drugOutput = v.RewardAmount
				requiredItems = v.RequiredItemAmount
			end
				
			local reqItems = xPlayer.Functions.GetItemByName(v.RequiredItem).amount >= requiredItems
			if not reqItems then
				local reqItemLabel = RSCore.Functions.GetItemByName(v.RequiredItem)
				TriggerClientEvent("RSCore:Notify",source,"You ~r~do not have~s~ enough ~y~"..reqItemLabel.."~s~")
				return
			end
			
			if xPlayer.Functions.GetItemByName(v.RewardItem).count <= v.MaxRewardItemInv.f or (not scale and xPlayer.Functions.GetItemByName(v.RewardItem).count <= v.MaxRewardItemInv.e) then
				if not Converting(GetPlayerIdentifier(source)) then
					TriggerEvent("t1ger_drugs:addConvertingTimer",source,v.ConversionTime)
					xPlayer.Functions.RemoveItem(v.UsableItem,1)
					xPlayer.Functions.RemoveItem(v.RequiredItem,requiredItems)
					TriggerClientEvent("t1ger_drugs:ConvertProcess",source,k,v)
					Citizen.Wait(v.ConversionTime)
					xPlayer.Functions.AddItem(v.RewardItem,drugOutput)
				else
					TriggerClientEvent("RSCore:Notify",source,string.format("You are ~b~already~s~ converting",GetConvertTime(GetPlayerIdentifier(source))))	
				end	
			else
				TriggerClientEvent("RSCore:Notify",source,"You ~r~do not have~s~ enough ~b~empty space~s~ for more ~y~"..itemLabel.."~s~")
			end
		end)
	end
end)

RegisterServerEvent('t1ger_drugs:DrugJobInProgress')
AddEventHandler('t1ger_drugs:DrugJobInProgress', function(targetCoords, streetName)
	TriggerClientEvent('t1ger_drugs:outlawNotify', -1,string.format("^0Shots fired and ongoing grand theft auto at ^5%s^0",streetName))
	TriggerClientEvent('t1ger_drugs:OutlawBlipEvent', -1, targetCoords)
end)

RegisterServerEvent('t1ger_drugs:DrugSaleInProgress')
AddEventHandler('t1ger_drugs:DrugSaleInProgress', function(targetCoords, streetName)
	TriggerClientEvent('t1ger_drugs:outlawNotify', -1,string.format("^0Possible drug sale at ^5%s^0",streetName))
	TriggerClientEvent('t1ger_drugs:OutlawBlipEvent', -1, targetCoords)
end)

RegisterServerEvent("t1ger_drugs:sellDrugs")
AddEventHandler("t1ger_drugs:sellDrugs", function()
	local xPlayer = RSCore.Functions.GetPlayer(source)
	local weed = xPlayer.Functions.GetItemByName(Config.WeedDrug).count
	local meth = xPlayer.Functions.GetItemByName(Config.MethDrug).count
	local coke = xPlayer.Functions.GetItemByName(Config.CokeDrug).count
	local drugamount = 0
	local price = 0
	local drugType = nil
	
	if weed > 0 then
		drugType = Config.WeedDrug
		if weed == 1 then
			drugamount = 1
		elseif weed == 2 then
			drugamount = math.random(1,2)
		elseif weed == 3 then	
			drugamount = math.random(1,3)
		elseif weed >= 4 then	
			drugamount = math.random(1,4)
		end
		
	elseif meth > 0 then
		drugType = Config.MethDrug
		if meth == 1 then
			drugamount = 1
		elseif meth == 2 then
			drugamount = math.random(1,2)
		elseif meth >= 3 then	
			drugamount = math.random(1,3)
		end
		
	elseif coke > 0 then
		drugType = Config.CokeDrug
		if coke == 1 then
			drugamount = 1
		elseif coke == 2 then
			drugamount = math.random(1,2)
		elseif coke >= 3 then	
			drugamount = math.random(1,3)
		end
	
	else
		TriggerClientEvent('RSCore:Notify', source, "You have ~r~no more~r~ ~y~drugs~s~ on you")
		return
	end
	
	if drugType==Config.WeedDrug then
		price = math.random(Config.WeedSale.min,Config.WeedSale.max) * 10 * drugamount
	elseif drugType==Config.MethDrug then
		price = math.random(Config.MethSale.min,Config.MethSale.max) * 10 * drugamount
	elseif drugType==Config.CokeDrug then
		price = math.random(Config.CokeSale.min,Config.CokeSale.max) * 10 * drugamount
	end
	
	if drugType ~= nil then
		local drugLabel = RSCore.Functions.GetItemByName(drugType)
		AddToSoldAmount(xPlayer.getIdentifier(),drugamount)
		xPlayer.Functions.RemoveItem(drugType, drugamount)
		if Config.ReceiveDirtyCash then
			xPlayer.Functions.AddMoney('cash', price)
		else
			xPlayer.Functions.AddMoney(price)
		end
		TriggerClientEvent('RSCore:Notify', source, "You sold ~b~"..drugamount.."x~s~ ~y~"..drugLabel.."~s~ for ~r~$"..price.."~s~")
	end		
end)

RegisterServerEvent("t1ger_drugs:canSellDrugs")
AddEventHandler("t1ger_drugs:canSellDrugs", function()
	local xPlayer = RSCore.Functions.GetPlayer(source)
	if xPlayer ~= nil then
	--
	--print(xPlayer.Functions.GetItemByName("coke1g").amount)
		local coke = xPlayer.Functions.GetItemByName("coke1g")
		local meth = xPlayer.Functions.GetItemByName("meth1g")
		local weed = xPlayer.Functions.GetItemByName("weed4g")
	--	print(coke.." | "..meth.." | "..weed)
		local cantidad = ( coke.amount > 0 or meth.amount > 0 or weed.amount > 0)
		local soldAmount = cantidad and CheckSoldAmount(xPlayer.PlayerData.steam) < Config.maxCap
		TriggerClientEvent("t1ger_drugs:canSellDrugs",source,soldAmount)
	end
end)

function AddToSoldAmount(source,amount)
	for k,v in pairs(soldAmount) do
		if v.id == source then
			v.amount = v.amount + amount
			return
		end
	end
end
function CheckSoldAmount(source)
	for k,v in pairs(soldAmount) do
		if v.id == source then
			return v.amount
		end
	end
	table.insert(soldAmount,{id = source, amount = 0})
	return CheckSoldAmount(source)
end

-- Do not touch these 6 functions!
function RemoveCooldown(source)
	for k,v in pairs(JobCooldown) do
		if v.cooldown == source then
			table.remove(JobCooldown,k)
		end
	end
end
function GetCooldownTime(source)
	for k,v in pairs(JobCooldown) do
		if v.cooldown == source then
			return math.ceil(v.time/60000)
		end
	end
end
function HasCooldown(source)
	for k,v in pairs(JobCooldown) do
		if v.cooldown == source then
			return true
		end
	end
	return false
end
function RemoveDrugEffectTimer(source)
	for k,v in pairs(DrugEffectTimer) do
		if v.effectWait == source then
			table.remove(DrugEffectTimer,k)
		end
	end
end
function GetDrugEffectTime(source)
	for k,v in pairs(DrugEffectTimer) do
		if v.effectWait == source then
			return math.ceil(v.timeC/1000)
		end
	end
end
function DrugEffect(source)
	for k,v in pairs(DrugEffectTimer) do
		if v.effectWait == source then
			return true
		end
	end
	return false
end
function RemoveConvertTimer(source)
	for k,v in pairs(ConvertTimer) do
		if v.convertWait == source then
			table.remove(ConvertTimer,k)
		end
	end
end
function GetConvertTime(source)
	for k,v in pairs(ConvertTimer) do
		if v.convertWait == source then
			return math.ceil(v.timeB/1000)
		end
	end
end
function Converting(source)
	for k,v in pairs(ConvertTimer) do
		if v.convertWait == source then
			return true
		end
	end
	return false
end
