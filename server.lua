math.randomseed(os.time())

local charset = {}  do -- [0-9a-zA-Z]
    for c = 48, 57  do table.insert(charset, string.char(c)) end
    for c = 65, 90  do table.insert(charset, string.char(c)) end
    for c = 97, 122 do table.insert(charset, string.char(c)) end
end

local function randomString(length)
    if not length or length <= 0 then return '' end
    return randomString(length - 1) .. charset[math.random(1, #charset)]
end

local AVOID_SYNC = randomString(20)

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

local function syncBankBalance(account)
    if not account.isDefault then
        return
    end

    local xPlayer = ESX.GetPlayerFromIdentifier(account.ownerIdentifier)

    if not xPlayer then
        return
    end

    xPlayer.setAccountMoney('bank', account.balance, AVOID_SYNC)
end

local function getBank(src)
    local xPlayer = ESX.GetPlayerFromId(src)
    local account = xPlayer.getAccount('bank')
    return account.money
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

-- Exports
exports("addCash", addCash)
exports("removeCash", removeCash)
exports("getCash", getCash)
exports("getBank", getBank)

-- EVENTS: GLOBAL
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

-- EVENTS: ESX
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

AddEventHandler('esx:addAccountMoney', function(playerSrc, accountName, amount, message)
    if accountName ~= "bank" or message == AVOID_SYNC then
        return
    end

    exports.pefcl:addBankBalance(playerSrc, {
        amount = amount,
        message = message
    })
end)

AddEventHandler('esx:removeAccountMoney', function(playerSrc, accountName, amount, message)
    if accountName ~= "bank" or message == AVOID_SYNC then
        return
    end

    exports.pefcl:removeBankBalance(playerSrc, {
        amount = amount,
        message = message
    })
end)

AddEventHandler('esx:setAccountMoney', function(playerSrc, accountName, amount, message)
    if accountName ~= "bank" or message == AVOID_SYNC then
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

-- EVENTS: PEFCL
AddEventHandler('pefcl:newAccountBalance', function(account)
    syncBankBalance(account)
end)

AddEventHandler('pefcl:changedDefaultAccount', function(account)
    syncBankBalance(account)
end)

