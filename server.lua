ESX = nil

TriggerEvent('esx:getSharedObject', function(obj)
    ESX = obj
end)

local function addCash(src, amount)
    local xPlayer = ESX.GetPlayerFromId(src)
    xPlayer.addMoney(amount)
end

local function removeCash(src, amount)
    local xPlayer = ESX.GetPlayerFromId(src)
    xPlayer.removeMoney(amount)
end

local function getCash(src)
    local xPlayer = ESX.GetPlayerFromId(src)
    return xPlayer.getMoney()
end

local function updateJobAccount(player, playerJob, playerLastJob)
    local citizenid = player.identifier
    local playerSrc = player.source

    if Config.BusinessAccounts[playerJob.name] then
        local currentUniqueAccount = exports.pefcl:getUniqueAccount(playerSrc, playerJob.name).data;

        if playerLastJob ~= nil and currentUniqueAccount and playerLastJob.name ~= playerJob.name then
            print("Removing from last job ..", playerLastJob.name)

            local data = {
                userIdentifier = player.getIdentifier(),
                accountIdentifier = playerLastJob.name
            }
            exports.pefcl:removeUserFromUniqueAccount(playerSrc, data)
        end

        if playerJob.grade < Config.BusinessAccounts[playerJob.name].ContributorRole then
            print("Grade below Contributor role. Returning.")
            return
        end

        -- If account doesn't exist, lets create it.
        if not exports.pefcl:getUniqueAccount(playerSrc, playerJob.name).data then
            local data = {
                name = Config.BusinessAccounts[playerJob.name].AccountName,
                type = 'shared',
                identifier = playerJob.name
            }
            exports.pefcl:createUniqueAccount(playerSrc, data)
        end

        local role = 'contributor'
        if playerJob.grade >= Config.BusinessAccounts[playerJob.name].AdminRole then
            role = 'admin'
        end

        if role then
            local data = {
                role = role,
                accountIdentifier = playerJob.name,
                userIdentifier = citizenid,
                source = playerSrc
            }
            exports.pefcl:addUserToUniqueAccount(playerSrc, data)
        end
    end
end

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(playerSrc, xPlayer)
    if not xPlayer then
        return
    end

    exports.pefcl:loadPlayer(playerSrc, {
        source = playerId,
        identifier = xPlayer.getIdentifier(),
        name = xPlayer.getName()
    })
end)

AddEventHandler("playerDropped", function()
    local src = source
    exports.pefcl:unloadPlayer(src)
end)

AddEventHandler("onServerResourceStart", function(resName)
    local resourceName = GetCurrentResourceName();

    if resName ~= resourceName and resName ~= "pefcl" then
        return
    end

    if not GetResourceState("pefcl") == 'started' then
        return
    end

    local xPlayers = ESX.GetExtendedPlayers()
    for _, xPlayer in pairs(xPlayers) do
        Citizen.Wait(50)

        updateJobAccount(xPlayer, xPlayer.getJob())
        exports.pefcl:loadPlayer(xPlayer.source, {
            source = xPlayer.source,
            identifier = xPlayer.identifier,
            name = xPlayer.getName()
        })
    end
end)

exports("addCash", addCash)
exports("removeCash", removeCash)
exports("getCash", getCash)

AddEventHandler('esx:addAccountMoney', function(playerSrc, accountName, amount, message)
    if accountName ~= "bank" then
        return
    end

    exports.pefcl:addBankBalance(playerSrc, {
        amount = amount,
        message = message
    })
end)

AddEventHandler('esx:removeAccountMoney', function(playerSrc, accountName, amount, message)
    if accountName ~= "bank" then
        return
    end

    exports.pefcl:removeBankBalance(playerSrc, {
        amount = amount,
        message = message
    })
end)

AddEventHandler('esx:setAccountMoney', function(playerSrc, accountName, amount, message)
    if accountName ~= "bank" then
        return
    end

    exports.pefcl:setBankBalance(playerSrc, {
        amount = amount,
        message = message
    })
end)

AddEventHandler('esx:setJob', function(playerSrc, job, lastJob)
    local xPlayer = ESX.GetPlayerFromId(playerSrc)

    if not xPlayer then
        return
    end

    updateJobAccount(xPlayer, job, lastJob)
end)

