math.randomseed(os.time())
local charset = {}

do -- [0-9a-zA-Z]
    for c = 48, 57 do
        table.insert(charset, string.char(c))
    end
    for c = 65, 90 do
        table.insert(charset, string.char(c))
    end
    for c = 97, 122 do
        table.insert(charset, string.char(c))
    end
end

local function randomString(length)
    if not length or length <= 0 then
        return ''
    end
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

if Config.OxInventory then
    local function getCards(source)
        local xPlayer = ESX.GetPlayerFromId(source)
        local cards = exports.ox_inventory:Search(xPlayer.source, 'search', 'visa')
        local retval = {}
        if cards then 
            for k, v in pairs(cards) do
                retval[#retval+1] = {
                    id = v.info.id,
                    holder = v.info.holder,
                    number = v.info.number
                }
            end
	end
	return retval
    end

    local function giveCard(source, card)
        local xPlayer = ESX.GetPlayerFromId(source)
        local info = {
            id = card.id,
            holder = card.holder,
            number = card.number
        }

        exports.ox_inventory:AddItem(xPlayer.source, 'visa', 1, info, nil, function(success, reason)
            if success then
                xPlayer.showNotification(Config.Locale.addItemSuccess)
            else
                xPlayer.showNotification(string.format("%s %s",Config.Locale.addItemSuccess,reason))
            end
        end)
    end
end


local function syncBankBalance(account)
    local society = nil
    TriggerEvent('esx_society:getSociety', account.ownerIdentifier, function(_society)
        society = _society
    end)

    if society ~= nil then
        TriggerEvent('esx_addonaccount:getSharedAccount', society.account, function(societyAccount)
	  -- TODO: Fix this asap
	  -- societyAccount.setMoney(account.balance)
        end)
    end

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

local function updateSocietyAccountAccess(player, playerJob, playerLastJob)
    local citizenid = player.identifier
    local playerSrc = player.source
    local society = nil

    TriggerEvent('esx_society:getSociety', playerJob.name, function(_society)
        society = _society
    end)

    if society == nil then
        return
    end

    local currentUniqueAccount = exports.pefcl:getUniqueAccount(playerSrc, playerJob.name).data;

    if playerLastJob ~= nil and playerLastJob.name then
        local data = {
            userIdentifier = player.getIdentifier(),
            accountIdentifier = playerLastJob.name
        }
        exports.pefcl:removeUserFromUniqueAccount(playerSrc, data)
    end

    if not currentUniqueAccount then
        local data = {
            name = society.label,
            type = 'shared',
            identifier = playerJob.name
        }
        exports.pefcl:createUniqueAccount(playerSrc, data)
    end

    if playerJob.grade_name == "boss" then
        local data = {
            role = "admin",
            accountIdentifier = playerJob.name,
            userIdentifier = citizenid,
            source = playerSrc
        }
        exports.pefcl:addUserToUniqueAccount(playerSrc, data)
    end

end

local function updateBusinessAccountAccess(player, playerJob, playerLastJob)
    local citizenid = player.identifier
    local playerSrc = player.source
    local currentUniqueAccount = playerLastJob and exports.pefcl:getUniqueAccount(playerSrc, playerLastJob.name).data

    if playerLastJob and currentUniqueAccount and playerLastJob.name ~= playerJob.name and playerLastJob.grade >= Config.BusinessAccounts[playerLastJob.name].ContributorRole then
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

-- Exports
exports("addCash", addCash)
exports("removeCash", removeCash)
exports("getCash", getCash)
exports("getBank", getBank)
if Config.OxInventory then
	exports("giveCard", giveCard)
	exports("getCards", getCards)
end

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

        updateBusinessAccountAccess(xPlayer, xPlayer.getJob())
        updateSocietyAccountAccess(xPlayer, xPlayer.getJob())
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

AddEventHandler('esx:playerLogout', function(playerId)
	exports.pefcl:unloadPlayer(playerId)
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

-- Handle society balance updates
AddEventHandler('esx_addonaccount:addMoney', function(identifier, amount)
    if string.find(identifier, "society_") then
        exports.pefcl:addBankBalanceByIdentifier(0, {
            amount = amount,
            message = Config.Locale.deposited,
            identifier = string.gsub(identifier, "society_", "")
        })
    end
end)

AddEventHandler('esx_addonaccount:removeMoney', function(identifier, amount)
    if string.find(identifier, "society_") then
        exports.pefcl:removeBankBalanceByIdentifier(0, {
            amount = amount,
            message = Config.Locale.withdrew,
            identifier = string.gsub(identifier, "society_", "")
        })
    end
end)

AddEventHandler('esx_addonaccount:setMoney', function(identifier, amount)
    if string.find(identifier, "society_") then
        exports.pefcl:setMoneyByIdentifier(0, {
            amount = amount,
            identifier = string.gsub(identifier, "society_", "")
        })
    end
end)

AddEventHandler('esx:setJob', function(playerSrc, job, lastJob)
    local xPlayer = ESX.GetPlayerFromId(playerSrc)

    if not xPlayer then
        return
    end

    updateBusinessAccountAccess(xPlayer, job, lastJob)
    updateSocietyAccountAccess(xPlayer, job, lastJob)
end)

-- EVENTS: PEFCL
AddEventHandler('pefcl:newAccountBalance', function(account)
    syncBankBalance(account)
end)

AddEventHandler('pefcl:changedDefaultAccount', function(account)
    syncBankBalance(account)
end)

RegisterServerEvent('esx_billing:sendBill')
AddEventHandler('esx_billing:sendBill', function(playerId, sharedAccountName, label, amount)
    local xPlayer = ESX.GetPlayerFromId(source)
    local xTarget = ESX.GetPlayerFromId(playerId)
    amount = ESX.Math.Round(amount)

    if amount > 0 and xTarget then
        TriggerEvent('esx_addonaccount:getSharedAccount', sharedAccountName, function(account)
            if account then
                local akaun = sharedAccountName
                if string.match(akaun, 'society_') then
                    akaun = akaun:gsub('society_', '')
                end

                    exports.pefcl:createInvoice(source, { to = xTarget.getName(), toIdentifier = xTarget.identifier, from = xPlayer.getName(), fromIdentifier = xPlayer.identifier, amount = amount, message = label, receiverAccountIdentifier = akaun, expiresAt = expiresAt})
            else
                    exports.pefcl:createInvoice(source, { to = xTarget.getName(), toIdentifier = xTarget.identifier, from = xPlayer.getName(), fromIdentifier = xPlayer.identifier, amount = amount, message = label, receiverAccountIdentifier = xPlayer.identifier, expiresAt = expiresAt})
            end
        end)
    end
end)

if Config.Paycheck.Enable then
    CreateThread(function()
        while true do
            Wait(Config.Paycheck.Interval * 60000)
            local xPlayers = ESX.GetExtendedPlayers()
            for i = 1, #(xPlayers) do
                local xPlayer = xPlayers[i]
                local job = xPlayer.job.grade_name
                local salary = xPlayer.job.grade_salary

                if salary > 0 then
                    if job == 'unemployed' then -- unemployed
                        exports.pefcl:addBankBalance(xPlayer.source, { amount = salary, message = Config.Locale.welfareCheck })
                        TriggerClientEvent('esx:showAdvancedNotification', xPlayer.source, Config.Locale.bankName, Config.Locale.receivedPayCheck, string.format("%s %s",Config.Locale.receivedHelp,salary), 'CHAR_BANK_MAZE', 9)
                elseif Config.EnableCompanyPayouts then -- possibly a society
                        TriggerEvent('esx_society:getSociety', xPlayer.job.name, function(society)
                            if society ~= nil then -- verified society
                                TriggerEvent('esx_addonaccount:getSharedAccount', society.account, function(account)
                                    if exports.pefcl:getTotalBankBalanceByIdentifier(xPlayer.source, xPlayer.job.name).data >= salary then -- does the society money to pay its employees?
                                        exports.pefcl:addBankBalance(xPlayer.source, { amount = salary, message = Config.Locale.receivedPayCheck })
                                        exports.pefcl:removeBankBalanceByIdentifier(xPlayer.source, { identifier = xPlayer.job.name, amount = salary, message = Config.Locale.transferPayCheck })

                                        TriggerClientEvent('esx:showAdvancedNotification', xPlayer.source, Config.Locale.bankName, Config.Locale.receivedPayCheck, string.format("%s %s",Config.Locale.receivedSalary,salary), 'CHAR_BANK_MAZE', 9)
                                    else
                                        TriggerClientEvent('esx:showAdvancedNotification', xPlayer.source, Config.Locale.bankName, '', Config.Locale.companyCantAfford, 'CHAR_BANK_MAZE', 1)
                                    end
                                end)
                            else -- not a society
                                exports.pefcl:addBankBalance(xPlayer.source, { amount = salary, message = Config.Locale.receivedPayCheck })
                                TriggerClientEvent('esx:showAdvancedNotification', xPlayer.source, Config.Locale.bankName, Config.Locale.receivedPayCheck, string.format("%s %s",Config.Locale.receivedSalary,salary), 'CHAR_BANK_MAZE', 9)
                            end
                        end)
                else -- generic job
                        exports.pefcl:addBankBalance(xPlayer.source, { amount = salary, message = Config.Locale.receivedPayCheck })
                        TriggerClientEvent('esx:showAdvancedNotification', xPlayer.source, Config.Locale.bankName, Config.Locale.receivedPayCheck, string.format("%s %s",Config.Locale.receivedSalary,salary), 'CHAR_BANK_MAZE', 9)
                    end
                end
            end
        end
    end)
end
