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

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(playerId, xPlayer)
    if not xPlayer then
        return
    end

    exports.pefcl:loadPlayer(playerId, {
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

    local xPlayers = ESX.GetExtendedPlayers()
    for _, xPlayer in pairs(xPlayers) do
        Citizen.Wait(50)
        exports.pefcl:loadPlayer(xPlayer.source, {
            source = xPlayer.source,
            identifier = xPlayer.getIdentifier(),
            name = xPlayer.getName()
        })
    end
end)

exports("addCash", addCash)
exports("removeCash", removeCash)
exports("getCash", getCash)
