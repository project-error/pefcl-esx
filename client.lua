RegisterNetEvent("pefcl:newDefaultAccountBalance", function(balance)
	TriggerServerEvent("pefcl-esx:server:SyncMoney")
end)
