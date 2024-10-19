ESX = exports["es_extended"]:getSharedObject()

local keybind = lib.addKeybind({
    name = 'faction',
    description = 'Ouvrir le menu des factions',
    defaultKey = 'F6',
    onPressed = function(self)
        openFaction('main')
    end,
})

RegisterCommand('open', function()
    exports.ox_inventory:openInventory('stash', {id='test'})
end,false)

Citizen.CreateThread(function()
    local blipzone
    local blip
    local blipcolor
    local blipname
    local blipdistance
    local blipcoords
    local blipblip
    local change = true
    while true do
        Wait(2000)
        ESX.TriggerServerCallback('grvsc_faction:getFaction', function(blips)
            if blips then
                blips = blips[1]
                if blips.coords then
                    if blipcolor ~= tonumber(blips.color) then
                        blipcolor = blips.color
                        change = true
                    end
                    if blipdistance ~= blips.distance then
                        blipdistance = blips.distance
                        change = true
                    end
                    if blipname ~= blips.faction_name then
                        blipname = blips.faction_name
                        change = true
                    end
                    if blipcoords ~= blips.coords then
                        blipcoords = blips.coords
                        change = true
                    end
                    if blipblip ~= blips.blip then
                        blipblip = blips.blip
                        change = true
                    end
                    blipcolor = tonumber(blipcolor)
                    if change then
                        change = nil
                        RemoveBlip(blip)
                        RemoveBlip(blipzone)
                        blips.coords = json.decode(blips.coords)
                        blipzone = AddBlipForRadius(blips.coords.x, blips.coords.y, blips.coords.z, blips.distance+1.0-1.0)  -- Ajoute le rayon à la fonction
                        SetBlipHighDetail(blipzone, true)
                        SetBlipDisplay(blipzone, 4)
                        SetBlipColour(blipzone, blipcolor)
                        SetBlipAlpha(blipzone, 128)
                        blip = AddBlipForCoord(blips.coords.x, blips.coords.y, blips.coords.z)
                        SetBlipSprite(blip, blips.blip)
                        SetBlipDisplay(blip, 3)
                        SetBlipScale(blip, 1.0)
                        SetBlipColour(blip, blipcolor)
                        SetBlipAsShortRange(blip, true)
                        BeginTextCommandSetBlipName("STRING")
                        AddTextComponentString("[FACTION] "..blips.faction_name)
                        EndTextCommandSetBlipName(blip)
                    end
                end
            else
                if blip then
                    RemoveBlip(blip)
                end
                if blipzone then
                    RemoveBlip(blipzone)
                end
            end
        end)
    end
end)

function openFaction(info)
    if info == 'main' then
        ESX.TriggerServerCallback('grvsc_faction:getFaction', function(result)
            if result then
                ESX.TriggerServerCallback('grvsc_faction:getPlayer', function(player)
                    result = result[1]
                    local permissions = json.decode(result.permissions)
                    player = player[1]
                    if not permissions[player.grade] then
                        print('ERREUR: Votre grade ne possède aucune permissions. Contactez l\'administration')
                        return
                    end
                    local options = {}
                    options[#options + 1] = {
                        title = '',
                        description = '↓ Information personnel ↓',
                        disabled = true,
                    }
                    options[#options + 1] = {
                        title = 'Vous êtes '..player.grade,
                        icon = 'fa-solid fa-user-tie',
                        iconColor = 'green'
                    }
                    options[#options + 1] = {
                        title = '',
                        description = '↓ Information de la faction ↓',
                        disabled = true,
                    }
                    options[#options + 1] = {
                        title = result.level,
                        description = 'Rayon de construction: '..result.distance..' mètres',
                        icon = 'fa-solid fa-campground',
                        onSelect = function()
                            lib.alertDialog({
                                header = result.level..' ['..result.distance..'M]',
                                content = 'Ceci est votre grade de faction, au plus votre faction évolue dans le temps et au plus votre grade augmentera afin de vous offrir un plus grand rayon d\'action.',
                                centered = true,
                            })
                            openFaction('main')
                        end
                    }
                    if permissions[player.grade].modifyfactioncoords then
                        if not result.coords then
                            options[#options + 1] = {
                                title = 'Vous n\'avez pas encore de territoire',
                                description = 'Cliquez pour installer votre territoire sur votre position',
                                icon = 'fa-solid fa-circle-exclamation',
                                iconColor = 'red',
                                onSelect = function()
                                    claimZone(result.id, GetEntityCoords(PlayerPedId()))
                                end
                            }
                        else
                            options[#options + 1] = {
                                title = 'Vous avez un territoire',
                                description = 'Cliquez pour redéfinir votre territoire sur votre position',
                                icon = 'fa-solid fa-circle-exclamation',
                                iconColor = 'green',
                                onSelect = function()
                                    claimZone(result.id, GetEntityCoords(PlayerPedId()))
                                end
                            }
                        end
                    end
                    options[#options + 1] = {
                        title = '',
                        description = '↓ Vos permissions et action ↓',
                        disabled = true,
                    }
                    if permissions[player.grade].modifyfactionname or permissions[player.grade].modifyfactioncolor or permissions[player.grade].modifyfactionblip then
                        local indexOptions = {}
                        if permissions[player.grade].modifyfactionname then
                            indexOptions[#indexOptions + 1] = {
                                title = 'Modifier le nom',
                                description = 'Permet de modifier le nom de votre faction',
                                icon = 'fa-solid fa-signature',
                                iconColor = 'yellow',
                                onSelect = function()
                                    local input = lib.inputDialog(result.faction_name, {
                                        {type = 'input', label = 'Quel sera le nom de votre faction ?', description = 'Veuillez préter attention au réglement', required = true, min = 4, max = 25},
                                      })
                                    if not input then openFaction('main') return end
                                    input[1] = input[1]:gsub("[^%w%s]", "") --gsub("[^%w]", "")
                                    TriggerServerEvent('grvsc_faction:updateName', result.id, input[1])
                                    Wait(0)
                                    openFaction('main')
                                end
                            }
                        end
                        if permissions[player.grade].modifyfactioncolor then
                            indexOptions[#indexOptions + 1] = {
                                title = 'Modifier la couleur',
                                description = 'Permet de modifier la couleur de votre faction',
                                icon = 'fa-solid fa-palette',
                                iconColor = 'yellow',
                                onSelect = function()
                                    local input = lib.inputDialog(result.faction_name, {
                                        {type = 'number', label = 'Quel couleur souhaitez vous ?', description = 'https://docs.fivem.net/docs/game-references/blips/#blip-colors', required = true, min = 1, max = 85},
                                      })
                                    if not input then openFaction('main') return end
                                    TriggerServerEvent('grvsc_faction:updateColor', result.id, input[1])
                                    Wait(0)
                                    openFaction('main')
                                end
                            }
                        end
                        if permissions[player.grade].modifyfactionblip then
                            indexOptions[#indexOptions + 1] = {
                                title = 'Modifier le blip',
                                description = 'Permet de modifier le blip de votre faction',
                                icon = 'fa-solid fa-tag',
                                iconColor = 'yellow',
                                onSelect = function()
                                    local input = lib.inputDialog(result.faction_name, {
                                        {type = 'number', label = 'Quel blip souhaitez vous ?', description = 'https://docs.fivem.net/docs/game-references/blips/', required = true, min = 0, max = 883},
                                      })
                                    if not input then openFaction('main') return end
                                    TriggerServerEvent('grvsc_faction:updateBlip', result.id, input[1])
                                    Wait(0)
                                    openFaction('main')
                                end
                            }
                        end
                        options[#options + 1] = {
                            title = 'Gérer la faction',
                            icon = 'fa-solid fa-flag',
                            iconColor = 'orange',
                            onSelect = function()
                                lib.registerContext({
                                    id = 'ManageFaction',
                                    title = '[FACTION] '..result.faction_name,
                                    menu  = 'Menufaction',
                                    options = indexOptions
                                })
                                Wait(100)
                                lib.showContext('ManageFaction')
                            end
                        }
                    end
                    if permissions[player.grade].kick or permissions[player.grade].promote then
                        options[#options + 1] = {
                            title = 'Gérer les membres',
                            icon = 'fa-solid fa-user-pen',
                            iconColor = 'orange',
                            onSelect = function()
                                local indexOptions = {}
                                ESX.TriggerServerCallback('grvsc_faction:fetchAllMembers', function(members)
                                    for k, v in pairs(members) do
                                        if permissions[v.grade].hierarchy < permissions[player.grade].hierarchy then
                                            indexOptions[#indexOptions + 1 ] = {
                                                title = '['..v.grade..'] '..v.member_name,
                                                description = 'Cliquez pour intéragir',
                                                icon = 'fa-solid fa-user-tie',
                                                onSelect = function()
                                                    local indexOptions2 = {}
                                                    if permissions[player.grade].kick then
                                                        indexOptions2[#indexOptions2 + 1 ] = {
                                                            title = 'Virer '..v.member_name,
                                                            icon = 'fa-solid fa-ban',
                                                            iconColor = 'red',
                                                            onSelect = function()
                                                                TriggerServerEvent('grvsc_faction:kickPlayer', v.member, result.id, player.member)
                                                                Wait(10)
                                                                openFaction('main')
                                                            end
                                                        }
                                                    end
                                                    if permissions[player.grade].promote then
                                                        indexOptions2[#indexOptions2 + 1 ] = {
                                                            title = 'Rétrograder/Promouvoir '..v.member_name,
                                                            icon = 'fa-solid fa-plus',
                                                            iconColor = 'orange',
                                                            onSelect = function()
                                                                local indexOptions3 = {}
                                                                -- Création d'une table temporaire pour stocker les éléments triés
                                                                local sortedOptions = {}
                                                                -- Boucle pour trier les éléments en fonction du niveau hiérarchique
                                                                for k, v2 in pairs(permissions) do
                                                                    if permissions[player.grade].hierarchy > v2.hierarchy then
                                                                        if player.grade == k then
                                                                            sortedOptions[#sortedOptions + 1] = {
                                                                                title = k..' (actif)',
                                                                                icon = 'fa-solid fa-biohazard',
                                                                                iconColor = 'orange',
                                                                            }
                                                                        else
                                                                            sortedOptions[#sortedOptions + 1] = {
                                                                                title = k,
                                                                                description = 'Cliquez pour attribuer ce grade',
                                                                                icon = 'fa-solid fa-biohazard',
                                                                                iconColor = 'orange',
                                                                                onSelect = function()
                                                                                    TriggerServerEvent('grvsc_faction:promote', v.member, result.id, player.member, k)
                                                                                    Wait(100)
                                                                                    openFaction('main')
                                                                                end
                                                                            }
                                                                        end
                                                                    end
                                                                end
                                                                indexOptions3 = sortedOptions
                                                                lib.registerContext({
                                                                    id = 'ManageMember3',
                                                                    title = '[FACTION] '..result.faction_name,
                                                                    menu  = 'ManageMember',
                                                                    options = indexOptions3
                                                                })
                                                                Wait(100)
                                                                lib.showContext('ManageMember3')
                                                            end
                                                        }
                                                    end

                                                    lib.registerContext({
                                                        id = 'ManageMember2',
                                                        title = '[FACTION] '..result.faction_name,
                                                        menu  = 'ManageMember',
                                                        options = indexOptions2
                                                    })
                                                    Wait(100)
                                                    lib.showContext('ManageMember2')
                                                end
                                            }
                                        end
                                    end
                                    if #indexOptions == 0 then
                                        indexOptions[#indexOptions + 1 ] = {
                                            title = 'Aucun membre ne vous est accessible',
                                            icon = 'fa-solid fa-circle-exclamation',
                                            iconColor = 'red'
                                        }
                                    end
                                    lib.registerContext({
                                        id = 'ManageMember',
                                        title = '[FACTION] '..result.faction_name,
                                        menu  = 'Menufaction',
                                        options = indexOptions
                                    })
                                    Wait(100)
                                    lib.showContext('ManageMember')
                                end)
                            end
                        }
                    end
                    if permissions[player.grade].creategrade or permissions[player.grade].modifygrade or permissions[player.grade].deletegrade then
                        options[#options + 1] = {
                            title = 'Gérer les grades',
                            icon = 'fa-solid fa-file-pen',
                            iconColor = 'orange',
                            onSelect = function()
                                local sortedOptions = {}
                                if permissions[player.grade].creategrade then
                                    sortedOptions[#sortedOptions + 1] = {
                                        title = 'Créer un nouveau grade',
                                        icon = 'folder-plus',
                                        iconColor = 'green',
                                        onSelect = function()
                                            local input = lib.inputDialog('Création de grade', {
                                                {type = 'input', label = 'Quel est le nom du grade ?', required = true, min = 1, max = 200},
                                                {type = 'number', label = 'Quel est son niveau de permission ?', description='0 étant le plus bas et 15 étant celui du chef', min = 0, max = 14, required = true,},
                                            })
                                            if input then
                                                input[1] = input[1]:gsub("[^%w]", "") --gsub("[^%w]", "")
                                                TriggerServerEvent('grvsc_faction:createRank', player.member, input[1], input[2], result.id)
                                                Wait(100)
                                                openFaction('main')
                                            else
                                                openFaction('main')
                                            end
                                        end
                                    }
                                    sortedOptions[#sortedOptions + 1] = {
                                        title = '',
                                        disabled = true,
                                    }
                                end
                                for k, v2 in pairs(permissions) do
                                    if permissions[player.grade].hierarchy > v2.hierarchy then
                                        sortedOptions[#sortedOptions + 1] = {
                                            title = k,
                                            description = 'Cliquez pour modifier ce grade',
                                            icon = 'fa-solid fa-biohazard',
                                            iconColor = 'orange',
                                            onSelect = function()
                                                refreshPermissions(player.grade, k, result.id, result.faction_name, player.member)
                                            end
                                        }
                                    end
                                end
                                lib.registerContext({
                                    id = 'ManageRank',
                                    title = '[FACTION] '..result.faction_name,
                                    menu  = 'Menufaction',
                                    options = sortedOptions
                                })
                                Wait(100)
                                lib.showContext('ManageRank')
                            end
                        }
                    end
                    if permissions[player.grade].recruit then
                        options[#options + 1] = {
                            title = 'Recruter joueur proche',
                            icon = 'fa-solid fa-user-plus',
                            iconColor = 'green',
                            onSelect = function()
                                local closestPlayer, closestPlayerDistance = ESX.Game.GetClosestPlayer()
                                local indexOptions = {}
                                if closestPlayer ~= -1 and closestPlayerDistance < 5.0 then 
                                    indexOptions[#indexOptions+1] = {
                                        title = 'Recruter ce joueur ? '..'(Voir le marqueur)'
                                    }
                                    indexOptions[#indexOptions+1] = {
                                        title = '',
                                        disabled = true,
                                    }
                                    indexOptions[#indexOptions+1] = {
                                        title = 'Confirmer',
                                        icon = 'user-plus',
                                        iconColor = 'green',
                                        onSelect = function()
                                            local input = lib.inputDialog('Recrutement faction', {
                                                {type = 'input', label = 'Quel nom voulez vous lui attribué ?', description = 'Ce nom sera visible par les membres de votre faction', required = true, min = 2, max = 16},
                                              })
                                            if input then
                                                input[1] = input[1]:gsub("[^%w%s]", "") --gsub("[^%w]", "")
                                                local playerId = GetPlayerServerId(closestPlayer)
                                                TriggerServerEvent('grvsc_faction:addMember', player.member, playerId, input[1], result.id)
                                            end
                                        end
                                    }
                                    indexOptions[#indexOptions+1] = {
                                        title = 'Annuler',
                                        icon = 'user-minus',
                                        iconColor = 'red',
                                        onSelect = function()
                                            lib.showContext('Menufaction')
                                        end
                                    }
                                    Citizen.CreateThread(function()
                                        Wait(100)
                                        while lib.getOpenContextMenu() == 'recruitMember' do
                                            Wait(5)
                                            local pos = GetEntityCoords(GetPlayerPed(closestPlayer))
                                            if pos then
                                                local amplitude = 0.1
                                                local height = amplitude * math.sin(GetGameTimer() * 0.005)  
                                                DrawMarker(0, pos.x, pos.y, pos.z+1.2 + height, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.2, 0.2, 0.2, 0, 255, 0, 200, false, true, 2, false, false, false, false)
                                            end
                                        end
                                    end)
                                else
                                    indexOptions[#indexOptions+1] = {
                                        title = 'Aucun joueur proche',
                                        icon = 'ban',
                                        iconColor = 'red'
                                    }
                                end
                                lib.registerContext({
                                    id = 'recruitMember',
                                    menu  = 'Menufaction',
                                    title = '[FACTION] '..result.faction_name,
                                    options = indexOptions
                                })
                                Wait(100)
                                lib.showContext('recruitMember')
                            end
                        }
                    end
                    options[#options + 1] = {
                        title = '',
                        disabled = true,
                    }
                    options[#options + 1] = {
                        title = 'Quittez la faction',
                        icon = 'ban',
                        iconColor = 'red',
                        onSelect = function()
                            TriggerServerEvent('grvsc_faction:leaveFaction', player.member, result.id)
                        end
                    }
                    
                    lib.registerContext({
                        id = 'Menufaction',
                        title = '[FACTION] '..result.faction_name,
                        options = options
                    })
                    Wait(100)
                    lib.showContext('Menufaction')
                end)
            else
                openFaction('create')
            end
        end)
    elseif info == 'create' then
        ESX.TriggerServerCallback('grvsc_faction:DoesPermission', function(result)
            lib.registerContext({
                id = 'Createfaction',
                title = 'Menu de faction',
                options = {
                  {
                    title = 'Vous n\'avez pas faction',
                    icon = 'fa-solid fa-triangle-exclamation',
                    iconColor = 'red'
                  },
                  {
                    title = 'Créer une faction',
                    description = 'Tentez une nouvelle aventure',
                    icon = 'fa-solid fa-plus',
                    iconColor = 'green',
                    disabled = result,
                    onSelect = function()
                        local input = lib.inputDialog('Création de faction', {
                            {type = 'input', label = 'Quel sera le nom de votre faction ?', description = 'Attention a respecter le réglement', required = true, min = 4, max = 16},
                            {type = 'number', label = 'Quel blip souhaitez vous ?', default = '1', required = true, min = 1},
                            {type = 'number', label = 'Quel sera la couleur du blip ?', default = '1', description = 'Cela représentera la couleur du blip', required = true, min = 1},
                          })
                        if input then
                            input[1] = input[1]:gsub("[^%w]", "")
                            TriggerServerEvent('grvsc_faction:createFaction', input[1], input[2], input[3])
                            Wait(100)
                            openFaction('main')
                        else
                            lib.showContext('Createfaction')
                        end
                    end,
                  }
                }
              })
            Wait(100)
            lib.showContext('Createfaction')
        end)
    end
end

function claimZone(faction, coords)
    ESX.TriggerServerCallback('grvsc_faction:getFaction', function(result)
        ESX.TriggerServerCallback('grvsc_faction:getAllFaction', function(result) 
            local claim = true
            if result then
                for _, v in pairs(result) do
                    if v.coords then
                        v.coords = json.decode(v.coords)
                        local f_coords = vec3(v.coords.x, v.coords.y, v.coords.z)
                        local p_coords = GetEntityCoords(PlayerPedId())
                        if GetDistanceBetweenCoords(f_coords.x, f_coords.y, f_coords.z, p_coords.x, p_coords.y, p_coords.z, true) < 300 then
                            claim = false
                        end
                    end
                end
            end
            if claim then
                result = result[1]
                if result.coords then
                    local alert = lib.alertDialog({
                        header = 'Réfléchissez bien avant de faire ceci',
                        content = 'Cela supprimmera définitivement toute les constructions présente sur votre térritoire',
                        centered = true,
                        cancel = true
                    })
                    if alert == 'confirm' then
                        TriggerServerEvent('grvsc_faction:newClaim', faction, coords)
                    end 
                else
                    TriggerServerEvent('grvsc_faction:newClaim', faction, coords)
                end
            end
            openFaction('main')
        end)
    end)
end

function refreshPermissions(playerGrade, k, factionid, factionName, auteur)
    ESX.TriggerServerCallback('grvsc_faction:getPermissions', function(permissions)
        ESX.TriggerServerCallback('grvsc_faction:getMemberfromrank', function(result)
            permissions = json.decode(permissions)
            local indexOptions = {}
            if permissions[playerGrade].modifygrade then
                if permissions[k].default == true then 
                    indexOptions[#indexOptions + 1] = {
                        title = 'Grade par défaut',
                        description = 'Ce grade est obtenue par les nouveaux membres',
                        icon = 'warning',
                        iconColor = 'yellow'
                    }
                end
                indexOptions[#indexOptions + 1] = {
                    title = '',
                    description = '↓ Les informations général ↓',
                    disabled = true,
                }
                indexOptions[#indexOptions + 1 ] = {
                    title = 'Modifier le nom',
                    description = 'Nom actuel: '..k,
                    icon = 'fa-solid fa-circle-exclamation',
                    iconColor = 'green',
                    onSelect = function()
                        local input = lib.inputDialog(k, {
                            {type = 'input', label = 'Nouveau nom', description = 'Veuillez prêter attention au règlement', required = true, min = 2, max = 16},
                        })
                        if not input then 
                            lib.showContext('ManageRank2') 
                        else
                            input[1] = input[1]:gsub("[^%w]", "")
                            TriggerServerEvent('grvsc_faction:changeRankName', k, factionid, auteur, input[1])
                            Wait(50)
                            refreshPermissions(playerGrade, input[1], factionid, factionName, auteur)
                        end
                    end
                }
                indexOptions[#indexOptions + 1 ] = {
                    title = 'Modifier le niveau hierachique',
                    description = 'Niveau actuel: '..permissions[k].hierarchy,
                    icon = 'fa-solid fa-circle-exclamation',
                    iconColor = 'green',
                    onSelect = function()
                        local input = lib.inputDialog(k, {
                            {type = 'number', label = 'Quel niveau hierachique souhaitez ?', description = 'Plus le niveau est haut, plus le grade sera haut placé', required = true, min = 0, max = permissions[playerGrade].hierarchy-1},
                        })
                        if not input then 
                            lib.showContext('ManageRank2')
                        else
                            TriggerServerEvent('grvsc_faction:changeRankHierarchy', k, factionid, auteur, input[1])
                            Wait(50)
                            refreshPermissions(playerGrade, k, factionid, factionName, auteur)
                        end
                    end
                }
                indexOptions[#indexOptions + 1] = {
                    title = '',
                    description = '↓ Les permissions ↓',
                    disabled = true,
                }
                local permissionActif
                local iconActif
                local iconColor
                for k2, v2 in pairs(permissions[k]) do
                    if k2 ~= 'hierarchy' and k2 ~= 'default' then
                        permissionActif = 'Désactivé [Clique pour activé]'
                        iconActif = 'fa-solid fa-toggle-off'
                        iconColor = '#a2462f'
                        if v2 then 
                            permissionActif = 'Activé [Clique pour désactivé]'
                            iconActif = 'fa-solid fa-toggle-on'
                            iconColor = '#2FA246'
                        end
                        if permissions[playerGrade][k2] then
                            indexOptions[#indexOptions + 1] = {
                                title = Config.permissions[k2],
                                description = permissionActif,
                                icon = iconActif,
                                iconColor = iconColor,
                                onSelect = function()
                                    TriggerServerEvent('grvsc_faction:setPermission', auteur, factionid, k2, v2, k)
                                    Wait(50)
                                    refreshPermissions(playerGrade, k, factionid, factionName, auteur)
                                end
                            }
                        else
                            if Config.permissions[k2] then
                                indexOptions[#indexOptions + 1] = {
                                    title = Config.permissions[k2],
                                    description = 'Vous n\'avez pas la permission de modifier cette permission',
                                    disabled = true,
                                    icon = iconActif,
                                    iconColor = iconColor
                                }
                            end
                        end
                    end
                end
                indexOptions[#indexOptions + 1] = {
                    title = '',
                    disabled = true,
                }
                if not permissions[k].default then
                    if result == 0 then
                        indexOptions[#indexOptions + 1 ] = {
                            title = 'Supprimer le grade',
                            icon = 'fa-solid fa-trash',
                            iconColor = 'red',
                            onSelect = function()
                                TriggerServerEvent('grvsc_faction:deleteRank', auteur, k, factionid)
                            end
                        }
                    else
                        indexOptions[#indexOptions + 1 ] = {
                            title = 'Supprimer le grade',
                            description = 'Actuellement: '..result..' membre(s) ont ce grade. Veuillez retirer ce grade à chacun avant de le supprimer',
                            icon = 'fa-solid fa-trash',
                            disabled = true,
                            iconColor = 'red',
                        }
                    end
                end
            end
            lib.registerContext({
                id = 'ManageRank2',
                title = '[FACTION] '..factionName,
                menu  = 'ManageRank',
                options = indexOptions
            })
            Wait(100)
            lib.showContext('ManageRank2')
        end, factionid, k)
    end, factionid)
end