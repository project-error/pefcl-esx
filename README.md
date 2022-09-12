<h1 align="center">pefcl-esx</h1>

**This is a compatibility resource that enables PEFCL to function properly with ESX. Please ensure that you have the latest version
of PEFCL and ESX installed**

## Installation Steps:

1. Download this repository and place it in the `resources` directory
2. Add `ensure pefcl-esx` to your `server.cfg`. Start this resource BEFORE `PEFCL`.
3. Navigate to the `config.json` in `PEFCL` and change the following settings:
   - Under `frameworkIntegration`
     - `enabled`: `true`
     - `resource`: `pefcl-esx`
4. Navigate to `es_extended\server\classes\player.lua` and replace those functions:

   - self.setAccountMoney =>

     ```lua
        function self.setAccountMoney (accountName, money, message)
            if money >= 0 then
                local account = self.getAccount(accountName)
                if account then
                    local newMoney = ESX.Math.Round(money)
                    if newMoney ~= account.money then
                        account.money = newMoney
                        if accountName == 'money' then
                            local prevMoney = self.getInventoryItem('cash').count
                            if prevMoney and newMoney > prevMoney then
                                self.addAccountMoney('money', newMoney - prevMoney)
                            elseif prevMoney and newMoney < prevMoney then 
                                self.removeAccountMoney('money', prevMoney - newMoney)
                            end
                            self.triggerEvent('esx:setAccountMoney', account)
                        elseif accountName == 'black_money' then
                            local prevMoney = self.getInventoryItem('black_money').count
                            if prevMoney and newMoney > prevMoney then 
                                self.addAccountMoney('black_money', newMoney - prevMoney)
                            elseif prevMoney and newMoney < prevMoney then 
                                self.removeAccountMoney('black_money', prevMoney - newMoney)
                            end
                            self.triggerEvent('esx:setAccountMoney', account)
                        else
                            self.triggerEvent('esx:setAccountMoney', account)
                            local balance = exports.pefcl:getDefaultAccountBalance(playerId).data
                            if balance < money then
                                exports.pefcl:addBankBalance(playerId, { amount = money - balance, message = message or 'Eingehende Transaktion' })
                            else
                                exports.pefcl:removeBankBalance(playerId, { amount = balance - money, message = message or 'Eingehende Transaktion'  })
                            end
                        end
                    end
                end
            end
        end
     ```

   - self.addAccountMoney =>

     ```lua
        function self.addAccountMoney(accountName, money, message)
            if money > 0 then
                local money = ESX.Math.Round(money)
                if accountName == 'money' then
                    local cash = self.getInventoryItem('cash').count
                    if cash then
                        self.addInventoryItem("cash", money)
                        self.setAccountMoney('money', cash + money, message or '')
                    end
                elseif accountName == 'black_money' then
                    local black_money = self.getInventoryItem('black_money').count
                    if black_money then
                        self.addInventoryItem("black_money", money)
                        self.setAccountMoney('black_money', black_money + money, message or '')
                    end
                else
                    local account = self.getAccount(accountName)
                    account.money = account.money + money
                    self.triggerEvent('esx:setAccountMoney', account)
                    exports.pefcl:addBankBalance(playerId, { amount = money, message = message or 'Eingehende Transaktion'  })
                end
            end
        end
     ```

   - self.removeAccountMoney =>

     ```lua
        function self.removeAccountMoney(accountName, money, message)
            if money > 0 then
                local money = ESX.Math.Round(money)
                if accountName == 'money' then
                    local cash = self.getInventoryItem('cash').count
                    if cash then
                        self.removeInventoryItem("cash", money)
                        local newMoney = cash - money
                        if newMoney >= 0 then
                            self.setAccountMoney('money', newMoney, message or '')
                        else 
                            self.setAccountMoney('money', 0, message or '')
                        end
                    end
                elseif accountName == 'black_money' then
                    local black_money = self.getInventoryItem('black_money').count
                    if black_money then 
                        self.removeInventoryItem("black_money", money)
                        local newMoney = black_money - money
                        if newMoney >= 0 then
                            self.setAccountMoney('black_money', newMoney, message or '')
                        else 
                            self.setAccountMoney('black_money', 0, message or '')
                        end
                    end
                else
                    local account = self.getAccount(accountName)
                    account.money = account.money - money
                    self.triggerEvent('esx:setAccountMoney', account)
                    exports.pefcl:removeBankBalance(playerId, { amount = money, message = message or 'Eingehende Transaktion'})
                end
            end
        end
     ```

5. Navigate to `es_extended\server\classes\player.lua` and add the following function:
    ```lua
        function self.SyncMoney()
            local balance = exports.pefcl:getDefaultAccountBalance(playerId).data
            local account = self.getAccount('bank')
            account.money = balance
            self.triggerEvent('esx:setAccountMoney', account)
        end
    ```
