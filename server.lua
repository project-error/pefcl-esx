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

        if playerLastJob ~= nil and playerLastJob.name ~= playerJob.name then
            print(string.format("Removing from last job: %s", playerLastJob.name))

            if Config.BusinessAccounts[playerLastJob.name] then
                if playerLastJob.grade >= Config.BusinessAccounts[playerLastJob.name].ContributorRole then
                    local data = {
                        userIdentifier = player.getIdentifier(),
                        accountIdentifier = playerLastJob.name
                    }
                    exports.pefcl:removeUserFromUniqueAccount(playerSrc, data)
                end
            end
        end

        if playerLastJob.name == playerJob.name and playerLastJob.grade ~= playerJob.grade then
            if playerJob.grade > playerLastJob.grade then -- neuer Job ist höher
                if playerLastJob.grade >= Config.BusinessAccounts[playerJob.name].ContributorRole then
                    local data = {
                        userIdentifier = player.getIdentifier(),
                        accountIdentifier = playerLastJob.name
                    }
                    exports.pefcl:removeUserFromUniqueAccount(playerSrc, data)
                end
            else -- alter job war höher
                if playerLastJob.grade >= Config.BusinessAccounts[playerLastJob.name].AdminRole and playerJob.grade < Config.BusinessAccounts[playerLastJob.name].AdminRole then
                    local data = {
                        userIdentifier = player.getIdentifier(),
                        accountIdentifier = playerLastJob.name
                    }
                    exports.pefcl:removeUserFromUniqueAccount(playerSrc, data)
                end
            end
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
    elseif Config.BusinessAccounts[playerLastJob.name] then
        local data = {
            userIdentifier = player.getIdentifier(),
            accountIdentifier = playerLastJob.name
        }
        exports.pefcl:removeUserFromUniqueAccount(playerSrc, data)
    end
end

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(playerSrc, xPlayer)
    if not xPlayer then
        return
    end

    exports.pefcl:loadPlayer(playerSrc, {
        source = playerSrc,
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
        Wait(50)

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

AddEventHandler('esx:setJob', function(playerSrc, job, lastJob)
    local xPlayer = ESX.GetPlayerFromId(playerSrc)

    if not xPlayer then
        return
    end

    updateJobAccount(xPlayer, job, lastJob)
end)

AddEventHandler('pefcl-esx:server:GetJobConfig', function(cb)
    cb(Config.BusinessAccounts)
end)

RegisterNetEvent("pefcl-esx:server:SyncMoney", function()
	local xPlayer = ESX.GetPlayerFromId(source)
    xPlayer.SyncMoney() -- SnycMoney
end)
