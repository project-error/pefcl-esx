
RegisterNetEvent("pefcl:newDefaultAccountBalance", function(balance)
    print(balance)
	TriggerServerEvent("pefcl-esx:server:SyncMoney")
end)