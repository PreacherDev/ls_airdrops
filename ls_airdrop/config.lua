Config = {}

Config.RequiredCops = 0 -- How many cops are required to drop a gun? -- test this, if not working, join https://discord.gg/6CpQn6EnD5
Config.PoliceJobs = {'police'}

Config.ModelsToLoad = {'w_am_flare', 'p_cargo_chute_s', 'ex_prop_adv_case_sm', 'bombushka', 's_m_m_pilot_02'}

Config.Models = {
    ['FlareName']       = 'weapon_flare',
    ['FlareModel']      = 'w_am_flare', 
    ['PlaneModel']      = 'bombushka',
    ['PlanePilotModel'] = 's_m_m_pilot_02',
    ['ParachuteModel']  = 'p_cargo_chute_s',
    ['CrateModel']      = 'ex_prop_adv_case_sm'
} 

Config.ItemDrops = {
    ['flare'] = { -- add this to your database
        {name = 'WEAPON_COMBATPISTOL', amount = 1, type = 'weapon'},
        {name = 'water', amount = 1, type = 'item'},
    }, 
--     ['flare_green'] = { -- add as many items you want 
--         {name = 'WEAPON_COMBATPISTOL', amount = 1, type = 'weapon'},
--         {name = 'water', amount = 1, type = 'item'},
--     }, 
}

Config.Lang = { 
    ['contacted_mafia'] = 'Du hast die Russische Mafia kontaktiert',
    ['pilot_contact'] = 'in ein paar Minuten wird dich der Pilot kontaktieren',
    ['no_cops'] = 'nicht genug Polozisten im Dienst',
    ['pilot_dropping_soon'] = 'Pilot: Wir bereiten den Lootdrop vor und werden ihn bald abwerfen',
    ['pilot_crashed'] = 'Das Flugzeug ist abgestürzt',
    ['crate_dropping'] = 'Pilot: schau in den Himmel der Lootdrop ist unterwegs',
    ['item_recieved'] = 'Du hast deinen Lootdrop erhalten',
    ['cant_carry'] = 'Das kannst du nicht tragen',
    ['already_thrown'] = 'Du hast bereits eine Fackel geworfen',
}
