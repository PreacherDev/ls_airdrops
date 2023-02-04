local safe = {}

function drop(items, planeSpawnDistance, dropCoords)
    CreateThread(function()
        SetTimeout(100, function()
            ESX.ShowNotification(Config.Lang['pilot_dropping_soon'])
            for k, models in pairs(Config.ModelsToLoad) do
                print(models)
                RequestModel(GetHashKey(models))
                while not HasModelLoaded(GetHashKey(models)) do
                    Wait(0)
                end
            end
            RequestAnimDict(Config.Models.ParachuteModel)
            while not HasAnimDictLoaded(Config.Models.ParachuteModel) do
                Wait(0)
            end            
            RequestWeaponAsset(GetHashKey(Config.Models.FlareName))
            while not HasWeaponAssetLoaded(GetHashKey(Config.Models.FlareName)) do
                Wait(0)
            end           
            local playerCoords    = GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0.0, 10.0, 0.0)  
            
            local rHeading        = math.random(0, 360) + 0.0
            local spawnDistance   = 1000.0
            local theta           = (rHeading / 180.0) * 3.14
            local spawn           = vector3(playerCoords.x, playerCoords.y, playerCoords.z) - vector3(math.cos(theta) * spawnDistance, math.sin(theta) * spawnDistance, -500.0)
            local dx              = playerCoords.x - spawn.x
            local dy              = playerCoords.y - spawn.y
            local heading         = GetHeadingFromVector_2d(dx, dy)

            local aircraft, pilot = createPlane({
                planemodel  = Config.Models.PlaneModel,
                coords      = spawn,
                heading     = heading,
                pedmodel    = Config.Models.PlanePilotModel
            })    
            Wait(1000)
            SetPlaneMinHeightAboveTerrain(aircraft, 50)
            TaskVehicleDriveToCoord(pilot, aircraft, vector3(playerCoords.x, playerCoords.y, playerCoords.z) + vector3(0.0, 0.0, 500.0), 60.0, 0, GetHashKey(Config.Models.PlanePilotModel), 262144, 15.0, -1.0) -- to the dropsite, could be replaced with a task sequence
            local droparea = vector2(playerCoords.x, playerCoords.y)
            local planeLocation = vector2(GetEntityCoords(aircraft).x, GetEntityCoords(aircraft).y)
            while not IsEntityDead(pilot) and #(planeLocation - droparea) > 5.0 do
                Wait(100)
                planeLocation = vector2(GetEntityCoords(aircraft).x, GetEntityCoords(aircraft).y)
            end
            if IsEntityDead(pilot) then 
                --exports['mv_notify']:Alert('Information', Config.Lang['pilot_crashed'], 3000, 'error')
                ESX.ShowNotification(Config.Lang['pilot_crashed'])
                TriggerServerEvent('dropLooted')
                Wait(3000)
                delete(Config.Models.PlaneModel)
                return
            end
            TaskVehicleDriveToCoord(pilot, aircraft, 0.0, 0.0, 500.0, 60.0, 0, GetHashKey(Config.Models.PlaneModel), 262144, -1.0, -1.0)
            SetEntityAsNoLongerNeeded(pilot) 
            SetEntityAsNoLongerNeeded(aircraft)  
            ESX.ShowNotification(Config.Lang['crate_dropping'])
            local crate = createObject({
                objectname  = Config.Models.CrateModel, 
                coords      = vector3(playerCoords.x, playerCoords.y, GetEntityCoords(aircraft).z - 5.0) 
            })
            SetEntityLodDist(crate, 1000)
            ActivatePhysics(crate)
            SetDamping(crate, 2, 0.1)
            SetEntityVelocity(crate, 0.0, 0.0, -0.2)
            local parachute = createObject({
                objectname  = Config.Models.ParachuteModel, 
                coords      = vector3(playerCoords.x, playerCoords.y, GetEntityCoords(aircraft).z - 5.0) 
            })

            SetEntityLodDist(parachute, 1000)
            SetEntityVelocity(parachute, 0.0, 0.0, -0.2)       
            AttachEntityToEntity(parachute, crate, 0, 0.0, 0.0, 0.1, 0.0, 0.0, 0.0, false, false, false, false, 2, true)            
            safe['sound'] = GetSoundId()
            PlaySoundFromEntity(safe['sound'], 'Crate_Beeps', parachute, 'MP_CRATE_DROP_SOUNDS', true, 0) 
            local parachuteCoords = vector3(GetEntityCoords(parachute))  
            while #(parachuteCoords - playerCoords) > 5.0 do        
                Wait(100)
                parachuteCoords = vector3(GetEntityCoords(parachute))
            end  
            DetachEntity(parachute, true, true)            
            delete(Config.Models.ParachuteModel)
            StopSound(safe['sound'])
            ReleaseSoundId(safe['sound'])
            for k, models in pairs(Config.ModelsToLoad) do
                Wait(0)
                SetModelAsNoLongerNeeded(GetHashKey(models))
            end
            RemoveWeaponAsset(GetHashKey(Config.Models.FlareName))  
            OpenCrate(items)
        end)
    end)
end


function OpenCrate(items)
    Wait(1000)
    local droppedFlare = false
    local finished = false
    CreateThread(function()
        while true do 
            local coords = GetEntityCoords(safe[Config.Models.CrateModel])
            local sleep = 100
            local playerCoords = GetEntityCoords(PlayerPedId())
            local distance = #(coords - playerCoords)
            if distance <= 25.0 then 
                if not droppedFlare then 

                    droppedFlare = true 
                    ShootSingleBulletBetweenCoords(coords, coords - vector3(0.0001, 0.0001, 0.0001), 0, false, GetHashKey(Config.Models.FlareName), 0, true, false, -1.0)            
                end
            end
            if distance <= 2.0 then 
                sleep = 1
                if IsControlJustPressed(0, 38) then 
                    ESX.Progressbar('Lootdrop', 5000,{
                        FreezePlayer = false, 
                        animation ={
                            type = 'anim',
                            dict = 'amb@prop_human_parking_meter@male@base', 
                            lib  = 'base' 
                        }, 
                        onFinish = function()
                            TriggerServerEvent('dropLooted')
                            TriggerServerEvent('ls_airdrops:itemHandler', 'add', items)     
                            delete(Config.Models.CrateModel)
                            ESX.ShowNotification(Config.Lang['item_recieved'])
                            finished = true
                        end
                    })
                end
                if finished then 
                    break
                end
            end
            Wait(sleep)
        end
    end)
end

function startDrop(items, roofCheck, planeSpawnDistance, dropCoords)
    CreateThread(function()          
        if not dropCoords.x and not dropCoords.y and not dropCoords.z and not tonumber(dropCoords.x) and not tonumber(dropCoords.y) and not tonumber(dropCoords.z) then            
            dropCoords = {0.0, 0.0, 72.0}            
        end
        RequestWeaponAsset(GetHashKey(Config.Models.FlareName))
        while not HasWeaponAssetLoaded(GetHashKey(Config.Models.FlareName)) do
            Wait(0)
        end
        ShootSingleBulletBetweenCoords(GetEntityCoords(PlayerPedId()), GetEntityCoords(PlayerPedId()) - vector3(0.0001, 0.0001, 0.0001), 0, false, GetHashKey(Config.Models.FlareName), 0, true, false, -1.0)
        if roofCheck and roofCheck ~= 'false' then
            local ray = StartShapeTestRay(vector3(dropCoords.x, dropCoords.y, dropCoords.z) + vector3(0.0, 0.0, 500.0), vector3(dropCoords.x, dropCoords.y, dropCoords.z), -1, -1, 0)
            local _, hit, impactCoords = GetShapeTestResult(ray)
            if hit == 0 or (hit == 1 and #(vector3(dropCoords.x, dropCoords.y, dropCoords.z) - vector3(impactCoords)) < 10.0) then             
                drop(items, planeSpawnDistance, dropCoords)
            else
                return
            end
        else            
            drop(items, planeSpawnDistance, dropCoords)
        end

    end)
end

RegisterNetEvent('ls_airdrops:createDrop', function(itemUsed, roofCheck, planeSpawnDistance)
    local playerCoords = GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0.0, 10.0, 0.0)        
    local items = GetRandomItemData(itemUsed)
    if Config.RequiredCops == 0 then 
        ESX.ShowNotification(Config.Lang['contacted_mafia'])
        TriggerServerEvent('ls_airdrops:itemHandler', 'remove', itemUsed)
        startDrop(items, roofCheck or false, planeSpawnDistance or 1000.0, vector3(playerCoords.x, playerCoords.y, playerCoords.z))
    else 
        ESX.TriggerServerCallback('ls_airdrops:getCops', function(copCount)
            if copCount >= Config.RequiredCops then 
                ESX.ShowNotification(Config.Lang['pilot_contact'])
                PoliceAlert()    
                TriggerServerEvent('ls_airdrops:itemHandler', 'remove', itemUsed)
                startDrop(items, roofCheck or false, planeSpawnDistance or 1000.0, vector3(playerCoords.x, playerCoords.y, playerCoords.z))
            else 
                ESX.ShowNotification(Config.Lang['no_cops'])
            end
        end)
    end
end)

function PoliceAlert()
    -- put your own dispatch here and comment the below event
    TriggerServerEvent('police:server:policeAlert', 'Suspicious activity')
end

function GetRandomItemData(item)
    -- if Config.ItemDrops[item] then
    --     local Items = Config.ItemDrops[item]
    --     local randomItem = Items[math.random(1, #Items)]
    --     return randomItem['name'], randomItem['amount'], randomItem
    -- end    
    if  Config.ItemDrops[item] then 
        return Config.ItemDrops[item]
    end
end

function delete(id)
    if safe[id] then 
        DeleteEntity(safe[id])
        safe[id] = nil
    else 
        print('delete(id): no such id')
    end
end

function createObject(tab)
    local object = CreateObject(GetHashKey(tab.objectname), tab.coords, true, true, true)
    safe[tab.objectname] = object
    return object
end

function createPlane(tab)                                     --rPlaneSpawn
    local aircraft = CreateVehicle(GetHashKey(tab.planemodel), tab.coords, tab.heading, true, true)
    SetEntityHeading(aircraft, heading)
    SetVehicleDoorsLocked(aircraft, 2)
    SetEntityDynamic(aircraft, true)
    ActivatePhysics(aircraft)
    SetVehicleForwardSpeed(aircraft, 60.0)
    SetHeliBladesFullSpeed(aircraft)
    SetVehicleEngineOn(aircraft, true, true, false)
    ControlLandingGear(aircraft, 3)
    OpenBombBayDoors(aircraft)
    SetEntityProofs(aircraft, true, false, true, false, false, false, false, false)

    local pilot = CreatePedInsideVehicle(aircraft, 1, GetHashKey(tab.pedmodel), -1, true, true)
    SetBlockingOfNonTemporaryEvents(pilot, true)
    SetPedRandomComponentVariation(pilot, false)
    SetPedKeepTask(pilot, true)
   
    safe[tab.planemodel] = aircraft
    safe[tab.pedmodel] = pilot
    print(safe[tab.planemodel])
    print(safe[tab.pedmodel])
    return aircraft, pilot
end

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        SetEntityAsMissionEntity(pilot, false, true)
        SetEntityAsMissionEntity(aircraft, false, true)

        delete(Config.Models.PlanePilotModel)
        delete(Config.Models.PlaneModel)
        delete(Config.Models.ParachuteModel)
        delete(Config.Models.CrateModel)
        
        -- RemovePickup(pickup) -- ???????????????????
        -- RemoveBlip(blip) -- ?????????????????????????????????????????????????????
        StopSound(safe['sound'])
        ReleaseSoundId(safe['sound'])
        for k, models in pairs(Config.ModelsToLoad) do
            Wait(0)
            SetModelAsNoLongerNeeded(GetHashKey(models))
        end
    end
end)