Config = {}

Config.Paycheck = {
    Enable = false,
    Interval = 7 -- Every 7 Minutes
}

Config.OxInventory = ESX.GetConfig().OxInventory

Config.EnableCompanyPayouts = true

-- You should not need BusinessAccounts when using ESX & esx_society
Config.BusinessAccounts = {
    -- ['police'] = { -- Job Name
    --     AccountName = 'Los Santos Police', -- Display name for bank account
    --     ContributorRole = 2, -- Minimum role required to contribute to the account
    --     AdminRole = 3 -- Minumum role to be able to add/remove money from the account
    -- },
    -- ['ambulance'] = { -- Job Name
    --     AccountName = 'Los Santos EMS', -- Display name for bank account
    --     ContributorRole = 2, -- Minimum role required to contribute to the account
    --     AdminRole = 3 -- Minumum role to be able to add/remove money from the account
    -- }
}

Config.Locale = {
    deposited = "Deposited money into society account",
    withdrew = "Withdrew money from society account",
    addItemSuccess = 'You got new Visa.',
    addItemFailed = 'Failed to give new visa, reason:',
    welfareCheck = 'Welfare Check',
    bankName = 'Maze Bank',
    receivedPayCheck = 'Received paycheck',
    receivedHelp = 'You have been paid your welfare check: $',
    transferPayCheck = 'Transfer paycheck',
    receivedSalary = 'You have been paid: $',
    companyCantAfford = 'the company you\'re employeed at is too poor to pay out your salary'
}
