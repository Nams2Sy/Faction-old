ESX.RegisterServerCallback('grvsc_faction:getFaction', function(source, cb)
    local player = ESX.GetPlayerFromId(source)
    if player then
        local id = MySQL.Sync.fetchScalar('SELECT faction_id FROM faction_members WHERE member = @member', {['@member'] = player.identifier})
        if id then
            local faction = MySQL.Sync.fetchAll("SELECT * FROM faction_list WHERE id = @id", {['@id'] = id})
            cb(faction)
        else
            cb(false) -- n'a pas de faction
        end
    end
end)
ESX.RegisterServerCallback('grvsc_faction:getAllFaction', function(source, cb)
    local faction = MySQL.Sync.fetchAll("SELECT * FROM faction_list")
    cb(faction)
end)
ESX.RegisterServerCallback('grvsc_faction:DoesPermission', function(source, cb)
    local player = ESX.GetPlayerFromId(source)
    -- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    -- ICI PLUS TARD FAIRE UN SYSTEM QUI RENVOIE true (pas la permission) SI LE JOUEUR NA PAS UNE COMPETENCE LEVEL 5 PAR EXEMPLE
    -- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    cb(false)
end)
ESX.RegisterServerCallback('grvsc_faction:getPlayer', function(source, cb)
    local player = ESX.GetPlayerFromId(source)
    if player then
        local id = MySQL.Sync.fetchAll('SELECT * FROM faction_members WHERE member = @member', {['@member'] = player.identifier})
        cb(id)
    else
        cb(false)
    end
end)
ESX.RegisterServerCallback('grvsc_faction:fetchAllMembers', function(source, cb)
    local player = ESX.GetPlayerFromId(source)
    if player then
        local id = MySQL.Sync.fetchScalar('SELECT faction_id FROM faction_members WHERE member = @member', {['@member'] = player.identifier})
        local members = MySQL.Sync.fetchAll('SELECT * FROM faction_members WHERE faction_id = @id', {['@id'] = id})
        cb(members)
    else
        cb(false)
    end
end)
ESX.RegisterServerCallback('grvsc_faction:getPermissions', function(source, cb, faction_id)
    local faction = MySQL.Sync.fetchScalar("SELECT permissions FROM faction_list WHERE id = @id", {['@id'] = faction_id})
    cb(faction)
end)
ESX.RegisterServerCallback('grvsc_faction:getMemberfromrank', function(source, cb, faction_id, rank)
    local members = MySQL.Sync.fetchAll('SELECT * FROM faction_members WHERE faction_id = @id AND grade = @rank', {['@id'] = faction_id, ['@rank'] = rank})
    cb(#members)
end)
ESX.RegisterServerCallback('grvsc_faction:getItem', function(source, cb, item)
    local count = exports.ox_inventory:GetItemCount(source, item)
    cb(count)
end)
ESX.RegisterServerCallback('grvsc_faction:getProps', function(source, cb, faction_id)
    local props = MySQL.Sync.fetchAll('SELECT * FROM faction_props WHERE faction_id = @faction_id', {['@faction_id'] = faction_id})
    cb(props)
end)
ESX.RegisterServerCallback('grvsc_faction:getProp', function(source, cb, id)
    local prop = MySQL.Sync.fetchScalar('SELECT data FROM faction_props WHERE id = @id', {['@id'] = id})
    cb(prop)
end)
ESX.RegisterServerCallback('grvsc_faction:getFuelItem', function(source, cb)
    local item = exports.ox_inventory:GetItem(source, 'WEAPON_PETROLCAN')
    cb(item.count)
end)
RegisterNetEvent('grvsc_faction:createFaction')
AddEventHandler('grvsc_faction:createFaction', function(name, blip, color)
    local source = source
    local permissions = {
        ['Chef'] = {
            hierarchy = 15, -- MAXIMUM
            -- MEMBER
            recruit = true,
            kick = true,
            promote = true,
            -- GRADE
            creategrade = true,
            modifygrade = true,
            deletegrade = true,
            -- FACTION
            modifyfactionname = true,
            modifyfactioncolor = true,
            modifyfactionblip = true,
            modifyfactioncoords = true,
            -- BUILDING
            builddestroy = true,
            default = false
        },
        ['Membre'] = {
            hierarchy = 0,
            -- MEMBER
            recruit = false,
            kick = false,
            promote = false,
            -- GRADE
            creategrade = false,
            modifygrade = false,
            deletegrade = false,
            -- FACTION
            modifyfactionname = false,
            modifyfactioncolor = false,
            modifyfactionblip = false,
            modifyfactioncoords = false,
            -- BUILDING
            builddestroy = false,
            default = true
        }
    }
    local player = ESX.GetPlayerFromId(source)
    MySQL.Sync.execute("INSERT INTO `faction_list`(`faction_name`, `color`, `blip`, `permissions`, `creator`) VALUES (@name, @color, @blip, @permissions, @creator)", {['@name'] = name, ['@color'] = color, ['@blip'] = blip, ['@permissions'] = json.encode(permissions), ['@creator'] = player.identifier})
    local id = MySQL.Sync.fetchScalar("SELECT id FROM `faction_list` WHERE creator = @creator",{['@creator'] = player.identifier})
    MySQL.Sync.execute("INSERT INTO `faction_members`(`member`, `grade`, `faction_id`) VALUES (@member, 'Chef', @id)", {['@member'] = player.identifier, ['@id'] = id})
    TriggerClientEvent('okokNotify:Alert', source, 'Une nouvelle aventure qui commence', 'Votre faction est créée', 3000, 'success', true)
 
end)
RegisterNetEvent('grvsc_faction:newClaim')
AddEventHandler('grvsc_faction:newClaim', function(faction, coords)
    local source = source
    MySQL.Async.execute("UPDATE `faction_list` SET `coords`=@coords WHERE id = @id", {['@id'] = faction, ['@coords'] = json.encode(coords)})
    -- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    -- BIEN PENSER A APPELLER LEVENT/FONCTION QUI DELETE TOUT LES PROPS DE LA BASE DE DONNEE DE LANCIEN TERRITOIRE
    -- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    TriggerClientEvent('okokNotify:Alert', source, 'Nouveau territoire', 'Construisez et défendez', 3000, 'success', true)
end)
RegisterNetEvent('grvsc_faction:updateName')
AddEventHandler('grvsc_faction:updateName', function(faction, name)
    local source = source
    MySQL.Async.execute("UPDATE `faction_list` SET `faction_name`=@name WHERE id = @id", {['@id'] = faction, ['@name'] = name})
    TriggerClientEvent('okokNotify:Alert', source, 'Modification effectué', 'Nouveau nom pour votre faction', 3000, 'success', true)
end)
RegisterNetEvent('grvsc_faction:updateColor')
AddEventHandler('grvsc_faction:updateColor', function(faction, color)
    local source = source
    MySQL.Async.execute("UPDATE `faction_list` SET `color`=@color WHERE id = @id", {['@id'] = faction, ['@color'] = color})
    TriggerClientEvent('okokNotify:Alert', source, 'Modification effectué', 'Nouvelle couleur de blip', 3000, 'success', true)
end)
RegisterNetEvent('grvsc_faction:updateBlip')
AddEventHandler('grvsc_faction:updateBlip', function(faction, blip)
    local source = source
    MySQL.Async.execute("UPDATE `faction_list` SET `blip`=@blip WHERE id = @id", {['@id'] = faction, ['@blip'] = blip})
    TriggerClientEvent('okokNotify:Alert', source, 'Modification effectué', 'Nouveau blip', 3000, 'success', true)
end)
RegisterNetEvent('grvsc_faction:kickPlayer')
AddEventHandler('grvsc_faction:kickPlayer', function(target, faction, auteur)
    local source = source
    local gradeauteur = MySQL.Sync.fetchScalar("SELECT grade FROM faction_members WHERE faction_id = @faction AND member = @member", {['@faction'] = faction, ['@member'] = auteur})
    local gradetarget = MySQL.Sync.fetchScalar("SELECT grade FROM faction_members WHERE faction_id = @faction AND member = @member", {['@faction'] = faction, ['@member'] = target})
    local permissions = MySQL.Sync.fetchScalar("SELECT permissions FROM faction_list WHERE id = @faction", {['@faction'] = faction})
    permissions = json.decode(permissions)
    if permissions[gradeauteur].hierarchy > permissions[gradetarget].hierarchy then
        if permissions[gradeauteur].kick then
            MySQL.Async.execute("DELETE FROM `faction_members` WHERE member=@member", {['@member'] = target})
            TriggerClientEvent('okokNotify:Alert', source, 'Membre exclus', 'La groupe se rétrécit..', 3000, 'success', true)
        else
            TriggerClientEvent('okokNotify:Alert', source, 'Permissions refusé', 'Vous ne pouvez pas exclure de joueur', 3000, 'denied', true)
        end
    else
        TriggerClientEvent('okokNotify:Alert', source, 'Permissions refusé', 'Vous ne pouvez pas exclure un membre plus haut que vous', 3000, 'denied', true)
    end
end)
RegisterNetEvent('grvsc_faction:promote')
AddEventHandler('grvsc_faction:promote', function(target, faction, auteur, rank)
    local source = source
    local gradeauteur = MySQL.Sync.fetchScalar("SELECT grade FROM faction_members WHERE faction_id = @faction AND member = @member", {['@faction'] = faction, ['@member'] = auteur})
    local gradetarget = MySQL.Sync.fetchScalar("SELECT grade FROM faction_members WHERE faction_id = @faction AND member = @member", {['@faction'] = faction, ['@member'] = target})
    local permissions = MySQL.Sync.fetchScalar("SELECT permissions FROM faction_list WHERE id = @faction", {['@faction'] = faction})
    permissions = json.decode(permissions)
    if permissions[gradeauteur].hierarchy > permissions[gradetarget].hierarchy then
        if permissions[gradeauteur].promote then
            MySQL.Async.execute("UPDATE `faction_members` SET `grade`=@rank WHERE member=@member", {['@member'] = target, ['@rank'] = rank})
            TriggerClientEvent('okokNotify:Alert', source, 'Grade changé', 'Vous avez attribué un nouveau grade', 3000, 'success', true)
        else
            TriggerClientEvent('okokNotify:Alert', source, 'Permissions refusé', 'Vous ne pouvez pas promouvoir de membre', 3000, 'denied', true)
        end
    else
        TriggerClientEvent('okokNotify:Alert', source, 'Permissions refusé', 'Vous ne pouvez pas promouvoir un membre plus haut que vous', 3000, 'denied', true)
    end
end)
RegisterNetEvent('grvsc_faction:setPermission')
AddEventHandler('grvsc_faction:setPermission', function(auteur, faction, permissionName, value, grade)
    local source = source
    local gradeauteur = MySQL.Sync.fetchScalar("SELECT grade FROM faction_members WHERE faction_id = @faction AND member = @member", {['@faction'] = faction, ['@member'] = auteur})
    local permissions = MySQL.Sync.fetchScalar("SELECT permissions FROM faction_list WHERE id = @faction", {['@faction'] = faction})
    permissions = json.decode(permissions)
    if permissions[gradeauteur].hierarchy > permissions[grade].hierarchy then
        if permissions[gradeauteur][permissionName] then
            if value then
                permissions[grade][permissionName] = false
                TriggerClientEvent('okokNotify:Alert', source, 'Modification effectué', 'Nouvelle permissions retiré', 3000, 'success', true)
            else
                permissions[grade][permissionName] = true
                TriggerClientEvent('okokNotify:Alert', source, 'Modification effectué', 'Nouvelle permissions accordé', 3000, 'success', true)
            end
            permissions = json.encode(permissions)
            MySQL.Async.execute("UPDATE `faction_list` SET `permissions`='"..permissions.."' WHERE id="..faction.."")
        else
            TriggerClientEvent('okokNotify:Alert', source, 'Permissions refusé', 'Vous ne possèdez pas cette permission', 3000, 'denied', true)
        end
    else
        TriggerClientEvent('okokNotify:Alert', source, 'Permissions refusé', 'Vous ne pouvez modifier un grade plus haut que vous', 3000, 'denied', true)
    end
end)
RegisterNetEvent('grvsc_faction:changeRankName')
AddEventHandler('grvsc_faction:changeRankName', function(grade, faction, auteur, name)
    local source = source
    local gradeauteur = MySQL.Sync.fetchScalar("SELECT grade FROM faction_members WHERE faction_id = @faction AND member = @member", {['@faction'] = faction, ['@member'] = auteur})
    local permissions = MySQL.Sync.fetchScalar("SELECT permissions FROM faction_list WHERE id = @faction", {['@faction'] = faction})
    permissions = json.decode(permissions)
    if permissions[gradeauteur].hierarchy > permissions[grade].hierarchy then
        permissions[name] = permissions[grade]
        permissions[grade] = nil
        permissions = json.encode(permissions)
        MySQL.Async.execute("UPDATE `faction_list` SET `permissions`='"..permissions.."' WHERE id="..faction.."")
        MySQL.Async.execute("UPDATE `faction_members` SET `grade`=@name WHERE grade=@grade AND faction_id=@faction",{['@grade'] = grade, ['@name'] = name, ['@faction']=faction})
        TriggerClientEvent('okokNotify:Alert', source, 'Modification effectué', 'Nouveau nom attribué', 3000, 'success', true)
    else
        TriggerClientEvent('okokNotify:Alert', source, 'Permissions refusé', 'Vous ne pouvez modifier un grade plus haut que vous', 3000, 'denied', true)
    end
end)
RegisterNetEvent('grvsc_faction:changeRankHierarchy')
AddEventHandler('grvsc_faction:changeRankHierarchy', function(grade, faction, auteur, number)
    local source = source
    local gradeauteur = MySQL.Sync.fetchScalar("SELECT grade FROM faction_members WHERE faction_id = @faction AND member = @member", {['@faction'] = faction, ['@member'] = auteur})
    local permissions = MySQL.Sync.fetchScalar("SELECT permissions FROM faction_list WHERE id = @faction", {['@faction'] = faction})
    permissions = json.decode(permissions)
    if permissions[gradeauteur].hierarchy > permissions[grade].hierarchy and permissions[gradeauteur].hierarchy > number then
        permissions[grade].hierarchy = number
        permissions = json.encode(permissions)
        MySQL.Async.execute("UPDATE `faction_list` SET `permissions`='"..permissions.."' WHERE id="..faction.."")
        TriggerClientEvent('okokNotify:Alert', source, 'Modification effectué', 'Nouvelle hierarchie attribué', 3000, 'success', true)
    else
        TriggerClientEvent('okokNotify:Alert', source, 'Permissions refusé', 'Vous ne pouvez pas attribué une hierarchie plus haute que vous', 3000, 'denied', true)
    end
end)
RegisterNetEvent('grvsc_faction:addMember')
AddEventHandler('grvsc_faction:addMember', function(auteur, target, name, faction)
    local source = source
    local allmember = MySQL.Sync.fetchAll("SELECT member FROM faction_members WHERE faction_id = @faction AND member = @member", {['@faction'] = faction, ['@member'] = auteur})
    local maxmember = MySQL.Sync.fetchScalar("SELECT max_players FROM faction_list WHERE id = @faction", {['@faction'] = faction})
    if #allmember < maxmember then
        local gradeauteur = MySQL.Sync.fetchScalar("SELECT grade FROM faction_members WHERE faction_id = @faction AND member = @member", {['@faction'] = faction, ['@member'] = auteur})
        local permissions = MySQL.Sync.fetchScalar("SELECT permissions FROM faction_list WHERE id = @faction", {['@faction'] = faction})
        permissions = json.decode(permissions)
        if permissions[gradeauteur].recruit == true then
            for k, v in pairs(permissions) do
                if v.default == true then
                    local player = ESX.GetPlayerFromId(target)
                    if player then
                        local exist = MySQL.Sync.fetchScalar("SELECT faction_id FROM faction_members WHERE member = @member", {['@member'] = player.identifier})
                        if not exist then
                            MySQL.Sync.execute("INSERT INTO `faction_members`(`member`, `grade`, `faction_id`, `member_name`) VALUES (@member,@grade,@id,@name)", {['@member'] = player.identifier,['@grade'] = k ,['@id'] = faction, ['@name'] = name})
                            TriggerClientEvent('okokNotify:Alert', source, 'Recrutement effectué', 'Nous membre dans votre faction', 3000, 'success', true)
                            return
                        else
                            TriggerClientEvent('okokNotify:Alert', source, 'Recrutement impossible', 'Ce membre est déjà dans une faction', 3000, 'denied', true)
                            return
                        end
                    end
                end
            end
            TriggerClientEvent('okokNotify:Alert', source, 'Contactez un administrateur', 'Aucun grade par defaut n\'a pu être trouvé', 3000, 'error', true)
        else
            TriggerClientEvent('okokNotify:Alert', source, 'Permissions refusé', 'Vous ne pouvez pas recruter de membre', 3000, 'denied', true)
        end
    else
        TriggerClientEvent('okokNotify:Alert', source, 'Faction surchargé', 'Vous avez atteint le limite de membre', 3000, 'denied', true)
    end
end)
RegisterNetEvent('grvsc_faction:createRank')
AddEventHandler('grvsc_faction:createRank', function(auteur, name, hierarchy, faction)
    local source = source
    local gradeauteur = MySQL.Sync.fetchScalar("SELECT grade FROM faction_members WHERE faction_id = @faction AND member = @member", {['@faction'] = faction, ['@member'] = auteur})
    local permissions = MySQL.Sync.fetchScalar("SELECT permissions FROM faction_list WHERE id = @faction", {['@faction'] = faction})
    permissions = json.decode(permissions)
    local i = 0
    for k, v in pairs(permissions) do
        i = i+1
    end
    if i < 15 then
        if permissions[gradeauteur].creategrade == true then
            permissions[name] = {
                hierarchy = hierarchy, -- MAXIMUM
                -- MEMBER
                recruit = false,
                kick = false,
                promote = false,
                -- GRADE
                creategrade = false,
                modifygrade = false,
                deletegrade = false,
                -- FACTION
                modifyfactionname = false,
                modifyfactioncolor = false,
                modifyfactionblip = false,
                modifyfactioncoords = false,
                -- BUILDING
                builddestroy = false,
                default = false
            }
            permissions = json.encode(permissions)
            MySQL.Async.execute("UPDATE `faction_list` SET `permissions`='"..permissions.."' WHERE id="..faction.."")
            TriggerClientEvent('okokNotify:Alert', source, 'Création effectué', 'Nouveau grade disponible', 3000, 'success', true)
        else
            TriggerClientEvent('okokNotify:Alert', source, 'Permissions refusé', 'Vous ne pouvez pas créer de grade', 3000, 'denied', true)
        end
    else
        TriggerClientEvent('okokNotify:Alert', source, 'Création impossible', 'Vous ne pouvez pas créer plus de grade', 3000, 'denied', true)
    end
end)
RegisterNetEvent('grvsc_faction:deleteRank')
AddEventHandler('grvsc_faction:deleteRank', function(auteur, grade, faction)
    local source = source
    local gradeauteur = MySQL.Sync.fetchScalar("SELECT grade FROM faction_members WHERE faction_id = @faction AND member = @member", {['@faction'] = faction, ['@member'] = auteur})
    local permissions = MySQL.Sync.fetchScalar("SELECT permissions FROM faction_list WHERE id = @faction", {['@faction'] = faction})
    permissions = json.decode(permissions)
    if permissions[gradeauteur].hierarchy > permissions[grade].hierarchy then
        local members = MySQL.Sync.fetchAll('SELECT * FROM faction_members WHERE faction_id = @id AND grade = @rank', {['@id'] = faction, ['@rank'] = grade})
        if #members == 0 then
            permissions[grade] = nil
            permissions = json.encode(permissions)
            MySQL.Async.execute("UPDATE `faction_list` SET `permissions`='"..permissions.."' WHERE id="..faction.."")
            TriggerClientEvent('okokNotify:Alert', source, 'Suppression effectué', 'Vous avez supprimer un grade', 3000, 'success', true)
        else
            TriggerClientEvent('okokNotify:Alert', source, 'Suppression impossible', 'Des membres occupe actuellement ce grade', 3000, 'denied', true)
        end
    else
        TriggerClientEvent('okokNotify:Alert', source, 'Permissions refusée', 'Vous ne pouvez pas supprimer de grade', 3000, 'denied', true)
    end
end)
RegisterNetEvent('grvsc_faction:leaveFaction')
AddEventHandler('grvsc_faction:leaveFaction', function(auteur, faction)
    local source = source
    local gradeauteur = MySQL.Sync.fetchScalar("SELECT grade FROM faction_members WHERE faction_id = @faction AND member = @member", {['@faction'] = faction, ['@member'] = auteur})
    if gradeauteur ~= 'Chef' then
        MySQL.Sync.execute('DELETE FROM `faction_members` WHERE faction_id = @faction AND member = @member', {['@faction'] = faction, ['@member'] = auteur})
        TriggerClientEvent('okokNotify:Alert', source, 'Faction quitté', 'Cette faction s\'en sortira mieux..', 3000, 'success', true)
    else
        TriggerClientEvent('okokNotify:Alert', source, 'Action impossible', 'Vous ne pouvez pas quitter en tant que Chef de faction', 3000, 'denied', true)
    end
end)
RegisterNetEvent('grvsc_faction:addProp')
AddEventHandler('grvsc_faction:addProp', function(auteur, faction_id, prop, coords, heading)
    local source = source
    local gradeauteur = MySQL.Sync.fetchScalar("SELECT grade FROM faction_members WHERE faction_id = @faction AND member = @member", {['@faction'] = faction_id, ['@member'] = auteur})
    local permissions = MySQL.Sync.fetchScalar("SELECT permissions FROM faction_list WHERE id = @faction", {['@faction'] = faction_id})
    local max_props = MySQL.Sync.fetchScalar("SELECT max_props FROM faction_list WHERE id = @faction", {['@faction'] = faction_id})
    permissions = json.decode(permissions)
    if permissions[gradeauteur].builddestroy then
        local propsNumber = MySQL.Sync.fetchAll("SELECT * FROM faction_props WHERE faction_id = @faction", {['@faction'] = faction_id})
        if max_props > #propsNumber then
            prop = json.encode(prop)
            MySQL.Sync.execute("INSERT INTO `faction_props`(`faction_id`, `data`, `coords`, `heading`) VALUES ("..faction_id..",'"..prop.."','"..coords.."',"..heading..")")
            TriggerClientEvent('okokNotify:Alert', source, 'Construction effectué', 'Nouvelle fabrication', 3000, 'success', true)
        else
            exports.ox_inventory:AddItem(source, prop.name, 1)
            TriggerClientEvent('okokNotify:Alert', source, 'Construction impossible', 'Cette faction à atteint la limite d\'bjet', 3000, 'denied', true)
        end
    else
        TriggerClientEvent('okokNotify:Alert', source, 'Permissions refusé', 'Vous ne pouvez pas construire', 3000, 'denied', true)
    end
end)
RegisterNetEvent('grvsc_faction:removeProp')
AddEventHandler('grvsc_faction:removeProp', function(auteur, faction_id, id)
    local source = source
    local gradeauteur = MySQL.Sync.fetchScalar("SELECT grade FROM faction_members WHERE faction_id = @faction AND member = @member", {['@faction'] = faction_id, ['@member'] = auteur})
    local permissions = MySQL.Sync.fetchScalar("SELECT permissions FROM faction_list WHERE id = @faction", {['@faction'] = faction_id})
    permissions = json.decode(permissions)
    if permissions[gradeauteur].builddestroy then
        MySQL.Sync.execute("DELETE FROM `faction_props` WHERE id = @id", {['@id'] = id.id})
        exports.ox_inventory:AddItem(source, id.data.name, 1)
        TriggerClientEvent('okokNotify:Alert', source, 'Construction récupéré', 'Vous avez démonter un objet', 3000, 'success', true)
    else
        TriggerClientEvent('okokNotify:Alert', source, 'Permissions refusé', 'Vous ne pouvez pas récupérer cette construction', 3000, 'denied', true)
    end
end)
RegisterNetEvent('grvsc_faction:updateProp')
AddEventHandler('grvsc_faction:updateProp', function(dataProp)
    if dataProp then
        local propsExist = MySQL.Sync.fetchScalar("SELECT * FROM faction_props WHERE id = @id", {['@id'] = dataProp.id})
        if propsExist then
            local data = json.encode(dataProp.data)
            local coords = json.encode(dataProp.coords)
            local heading = json.encode(dataProp.heading)
            MySQL.Sync.execute("UPDATE `faction_props` SET `data`='"..data.."', `coords`='"..coords.."', `heading`="..heading.." WHERE id="..dataProp.id.."")
        end
    end
end)
RegisterNetEvent('grvsc_faction:checkStash')
AddEventHandler('grvsc_faction:checkStash', function(id)
    local inventory = exports.ox_inventory:GetInventory('chest:'..id)
    if not inventory then
        exports.ox_inventory:RegisterStash('chest:'..id, 'Coffre', 10, 10000)
    end
end)
RegisterNetEvent('grvsc_faction:addFuel')
AddEventHandler('grvsc_faction:addFuel', function(prop, fuel)
    exports.ox_inventory:RemoveItem(source, 'WEAPON_PETROLCAN', 1)
    TriggerEvent('grvsc_faction:updateProp', prop)
end)

function round(num, numDecimalPlaces)
    local mult = 10^(numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end
Citizen.CreateThread(function()
    while true do
        Wait(60000)
        local props = MySQL.Sync.fetchAll("SELECT * FROM faction_props")
        for k, v in pairs(props) do
            v.data = json.decode(v.data)
            if v.data.generator then
                if v.data.generator.active then
                    v.data.generator.fuel = round(v.data.generator.fuel-v.data.generator.consum/60, 2)
                    if v.data.generator.fuel <= 0 then
                        v.data.generator.fuel = 0
                        v.data.generator.active = false
                    end
                    v.coords = json.decode(v.coords)
                    TriggerEvent('grvsc_faction:updateProp', v)
                end
            end
        end
    end
end)