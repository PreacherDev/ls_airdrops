-- Item Handler
local lootDroppedAndLooted = false
RegisterNetEvent('ls_airdrops:server:ItemHandler', function(kind, item, amount)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if kind == 'add' then
        xPlayer.addInventoryItem(item, amount)
    elseif kind == 'remove' then
        xPlayer.removeInventoryItem(item, amount)
    end    
end)

-- get amount of cops online and on duty
ESX.RegisterServerCallback('ls_airdrops:getCops', function(source, cb)
    local count = 0
    for _, job in pairs(Config.PoliceJobs) do
        for k, v in pairs(ESX.GetExtendedPlayers('job', job)) do 
            count = (count+1)
        end
    end	
    cb(count)
end)

CreateThread(function()
    for k, v in pairs(Config.ItemDrops) do 
        ESX.RegisterUsableItem(k, function(source)
            local source = source 
            local xPlayer = ESX.GetPlayerFromId(source)   
            if not lootDroppedAndLooted then 
                lootDroppedAndLooted = true
                TriggerClientEvent('ls_airdrops:createDrop', source, k, true, 400)  
            else 
                xPlayer.showNotification(Config.Lang(Config.Lang['already_thrown']))          
            end
        end)
    end
end)

RegisterNetEvent('dropLooted', function()
    lootDroppedAndLooted = false
end)

RegisterNetEvent('ls_airdrops:itemHandler', function(type, items)
    local source  = source    
    local xPlayer = ESX.GetPlayerFromId(source)
    if type == 'remove' then 
        xPlayer.removeInventoryItem(items, 1)
    elseif type == 'add' then 
        for k, v in pairs(items) do 
            if v.type == 'weapon' then  
                xPlayer.addWeapon(v.name, v.amount)
            elseif v.type == 'item' then 
                if xPlayer.canCarryItem(v.name, v.amount) then
                    xPlayer.addInventoryItem(v.name, v.amount)
                else 
                    xPlayer.showNotification(Config.Lang(Config.Lang['cant_carry']))
                end
            end
        end
    end
end)