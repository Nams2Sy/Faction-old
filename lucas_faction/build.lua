local build
local flashlightObject = nil
local prop = nil
local distance = 3
local up = 0
local confirm = false

Citizen.CreateThread(function()
    while true do
        Wait(0)
        if prop then
            if IsControlPressed(0, 73) then
                build = nil
            end
            if IsControlJustReleased(0, 191) then
                confirm = true
            end
            local pos = GetEntityCoords(prop)
            local playerpos = GetEntityCoords(PlayerPedId())
            if IsControlPressed(0, 174) then
                pos = vec3(pos.x-0.03, pos.y, pos.z)
                if GetDistanceBetweenCoords(pos.x, pos.y, pos.z, playerpos.x, playerpos.y, playerpos.z, true) < 3.5 then
                    SetEntityCoordsNoOffset(prop, pos.x, pos.y, pos.z, true, true, true)
                end
            end
            if IsControlPressed(0, 175) then
                pos = vec3(pos.x+0.03, pos.y, pos.z)
                if GetDistanceBetweenCoords(pos.x, pos.y, pos.z, playerpos.x, playerpos.y, playerpos.z, true) < 3.5 then
                    SetEntityCoordsNoOffset(prop, pos.x, pos.y, pos.z, true, true, true)
                end
            end
            if IsControlPressed(0, 172) then
                if IsControlPressed(0, 348) then
                    pos = vec3(pos.x, pos.y, pos.z+0.03)
                    if GetDistanceBetweenCoords(pos.x, pos.y, pos.z, playerpos.x, playerpos.y, playerpos.z, true) < 3.5 then
                        SetEntityCoordsNoOffset(prop, pos.x, pos.y, pos.z, true, true, true)
                    end
                else
                    pos = vec3(pos.x, pos.y+0.03, pos.z)
                    if GetDistanceBetweenCoords(pos.x, pos.y, pos.z, playerpos.x, playerpos.y, playerpos.z, true) < 3.5 then
                        SetEntityCoordsNoOffset(prop, pos.x, pos.y, pos.z, true, true, true)
                    end
                end
            end
            if IsControlPressed(0, 173) then
                if IsControlPressed(0, 348) then
                    pos = vec3(pos.x, pos.y, pos.z-0.03)
                    if GetDistanceBetweenCoords(pos.x, pos.y, pos.z, playerpos.x, playerpos.y, playerpos.z, true) < 3.5 then
                        SetEntityCoordsNoOffset(prop, pos.x, pos.y, pos.z, true, true, true)
                    end
                else
                    pos = vec3(pos.x, pos.y-0.03, pos.z)
                    if GetDistanceBetweenCoords(pos.x, pos.y, pos.z, playerpos.x, playerpos.y, playerpos.z, true) < 3.5 then
                        SetEntityCoordsNoOffset(prop, pos.x, pos.y, pos.z, true, true, true)
                    end
                end
            end
            if IsControlPressed(0, 348) then
                
            end
            if IsControlPressed(0, 96) then
                SetEntityHeading(prop, GetEntityHeading(prop)+2)
            end
            if IsControlPressed(0, 97) then
                SetEntityHeading(prop, GetEntityHeading(prop)-2)
            end

        end
    end
end)
Citizen.CreateThread(function()
    local interval = 500
    while true do
        Wait(interval)
        interval = 500
        if build then
            interval = 0
            if not prop then
                local coords = GetEntityCoords(PlayerPedId())
                local forwardVector = GetEntityForwardVector(PlayerPedId())
                local offset = 3
                local pos = coords + forwardVector * offset
                RequestModel(build.name)
                while not HasModelLoaded(build.name) do
                    Wait(500)
                end
                prop = CreateObject(build.name, pos.x, pos.y, pos.z, false, true, true)
                SetEntityAlpha(prop, 150, false)
                SetModelAsNoLongerNeeded(build.name)
                FreezeEntityPosition(prop, true)
                SetEntityCollision(prop, false, false)
                flashlightObject = CreateObject(GetHashKey(build.name), pos.x, pos.y, pos.z, true, true, true)
                AttachEntityToEntity(flashlightObject, PlayerPedId(), GetPedBoneIndex(PlayerPedId(), 18905), 0.12, 0.03, 0.0, 0.0, 180.0, 0.0, true, true, false, true, 1, true)
            else
                local coords = GetEntityCoords(PlayerPedId())
                if GetDistanceBetweenCoords(GetEntityCoords(prop).x, GetEntityCoords(prop).y, GetEntityCoords(prop).z, coords.x, coords.y, coords.z, true) >= 3.5 then
                    local forwardVector = GetEntityForwardVector(PlayerPedId())
                    local offset = distance
                    local pos = coords + forwardVector * offset
                    local groundZ, groundZ2 = GetGroundZAndNormalFor_3dCoord(pos.x, pos.y, pos.z)
                    local pos = vec3(pos.x, pos.y, up+groundZ2)
                    SetEntityCoordsNoOffset(prop, pos.x, pos.y, pos.z, true, true, true)
                end
                FreezeEntityPosition(prop, true)
                SetEntityCollision(prop, false, false)
                if confirm == true then
                    confirm = false
                    DeleteEntity(flashlightObject)
                    if lib.progressBar({
                        duration = 6000,
                        label = 'Construction',
                        useWhileDead = false,
                        canCancel = true,
                        disable = {
                            move = true,
                            car = true,
                            combat = true,
                            mouse = true,
                            sprint = true,
                        },
                        anim = {
                            dict = 'melee@large_wpn@streamed_core',
                            clip = 'ground_attack_on_spot',
                            flags = 49
                        },
                        prop = {
                            model = 'prop_tool_hammer',
                            pos = vec3(0.05, 0.07, 0),
                            rot = vec3(-110, -90, 0.5)
                        },
                    }) then
                        ESX.TriggerServerCallback('grvsc_faction:getItem', function(result)
                            if result > 0 then
                                ESX.TriggerServerCallback('grvsc_faction:getFaction', function(faction)
                                    faction = faction[1]
                                    ESX.TriggerServerCallback('grvsc_faction:getPlayer', function(player)
                                        player = player[1]
                                        local position = {
                                            faction = json.decode(faction.coords),
                                            entity = GetEntityCoords(prop)
                                        }
                                        local distance = GetDistanceBetweenCoords(position.faction.x, position.faction.y, position.faction.z, position.entity.x, position.entity.y, position.entity.z, false)
                                        if distance > tonumber(faction.distance) then
                                            DeleteEntity(prop)
                                            build = nil
                                            prop = nil
                                            return
                                        end
                                        ResetEntityAlpha(prop, 0, false)
                                        SetEntityCollision(prop, true, true)
                                        exports.ox_inventory:useItem(build.data, function(data)
                                        end)
                                        build['data'] = nil
                                        local pushCoords = {
                                            ['x'] = GetEntityCoords(prop).x,
                                            ['y'] = GetEntityCoords(prop).y,
                                            ['z'] = GetEntityCoords(prop).z
                                        }
                                        pushCoords = json.encode(pushCoords)
                                        if build.chest then
                                            build.chest['password'] = 'nopassword' 
                                        end
                                        TriggerServerEvent('grvsc_faction:addProp', player.member, faction.id, build, pushCoords, GetEntityHeading(prop))
                                        build = nil
                                    end)
                                end)
                            else
                                DeleteEntity(flashlightObject)
                                DeleteEntity(prop)
                                build = nil
                                prop = nil
                                return
                            end
                        end, build.data.name)
                    end
                end
            end
        elseif prop then
            DeleteEntity(prop)
            DeleteEntity(flashlightObject)
            prop = nil
        end
    end
end)
Citizen.CreateThread(function()
    local allItem = exports.ox_inventory:Items()
    for k,v in pairs(allItem) do
        if v.metadata then
            if v.metadata.placable == true then
                exports(v.name, function(data, slot)
                    build = v.metadata
                    build['data'] = data
                end)
            end
        end
    end
end)


