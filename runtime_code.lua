package_files = {}
do
    local is_compiletime = false

    function IsCompiletime()
        return is_compiletime
    end

    local loaded_packages = {}
    local loading_packages = {}
    function require(package_name)
        package_name = package_name:gsub('[.]+', '.')
        
        if loading_packages[package_name] then
            print('Recursive require detected.')
            return nil
        end

        if not loaded_packages[package_name] then
            if not package_files[package_name] then
                error('Can not find module '..package_name, 2)
            end

            loading_packages[package_name] = true
            loaded_packages[package_name] = package_files[package_name]() or true
            loading_packages[package_name] = nil
        end
        return loaded_packages[package_name]
    end

    function CompiletimeFinalToRuntime(func)
        return func()
    end

    function CompileFinal()
    end
end

function RunInit()
    local success, result = pcall(require, 'init')
    if not success then
        print(result)
    end
end

function RunMain()
    local success, result = pcall(require, 'main')
    if not success then
        print(result)
    end
end

function main()
    SetCameraBounds(-3328.0 + GetCameraMargin(CAMERA_MARGIN_LEFT), -3584.0 + GetCameraMargin(CAMERA_MARGIN_BOTTOM), 3328.0 - GetCameraMargin(CAMERA_MARGIN_RIGHT), 3072.0 - GetCameraMargin(CAMERA_MARGIN_TOP), -3328.0 + GetCameraMargin(CAMERA_MARGIN_LEFT), 3072.0 - GetCameraMargin(CAMERA_MARGIN_TOP), 3328.0 - GetCameraMargin(CAMERA_MARGIN_RIGHT), -3584.0 + GetCameraMargin(CAMERA_MARGIN_BOTTOM))
    SetDayNightModels("Environment\\DNC\\DNCLordaeron\\DNCLordaeronTerrain\\DNCLordaeronTerrain.mdl", "Environment\\DNC\\DNCLordaeron\\DNCLordaeronUnit\\DNCLordaeronUnit.mdl")
    NewSoundEnvironment("Default")
    SetAmbientDaySound("LordaeronSummerDay")
    SetAmbientNightSound("LordaeronSummerNight")
    SetMapMusic("Music", true, 0)
    InitBlizzard()

    RunInit()
    TimerStart(CreateTimer(), 0.1, false, RunMain)
end

function InitCustomPlayerSlots()
    -- Player 0
    SetPlayerStartLocation(Player(0), 0)
    SetPlayerColor(Player(0), ConvertPlayerColor(0))
    SetPlayerRacePreference(Player(0), RACE_PREF_HUMAN)
    SetPlayerRaceSelectable(Player(0), true)
    SetPlayerController(Player(0), MAP_CONTROL_USER)

    -- Player 1
    SetPlayerStartLocation(Player(1), 1)
    SetPlayerColor(Player(1), ConvertPlayerColor(1))
    SetPlayerRacePreference(Player(1), RACE_PREF_ORC)
    SetPlayerRaceSelectable(Player(1), true)
    SetPlayerController(Player(1), MAP_CONTROL_USER)

    -- Player 2
    SetPlayerStartLocation(Player(2), 2)
    SetPlayerColor(Player(2), ConvertPlayerColor(2))
    SetPlayerRacePreference(Player(2), RACE_PREF_UNDEAD)
    SetPlayerRaceSelectable(Player(2), true)
    SetPlayerController(Player(2), MAP_CONTROL_USER)

    -- Player 3
    SetPlayerStartLocation(Player(3), 3)
    SetPlayerColor(Player(3), ConvertPlayerColor(3))
    SetPlayerRacePreference(Player(3), RACE_PREF_NIGHTELF)
    SetPlayerRaceSelectable(Player(3), true)
    SetPlayerController(Player(3), MAP_CONTROL_USER)

    -- Player 4
    SetPlayerStartLocation(Player(4), 4)
    SetPlayerColor(Player(4), ConvertPlayerColor(4))
    SetPlayerRacePreference(Player(4), RACE_PREF_HUMAN)
    SetPlayerRaceSelectable(Player(4), true)
    SetPlayerController(Player(4), MAP_CONTROL_USER)

    -- Player 5
    SetPlayerStartLocation(Player(5), 5)
    SetPlayerColor(Player(5), ConvertPlayerColor(5))
    SetPlayerRacePreference(Player(5), RACE_PREF_ORC)
    SetPlayerRaceSelectable(Player(5), true)
    SetPlayerController(Player(5), MAP_CONTROL_USER)
end

function InitCustomTeams()
    SetPlayerTeam(Player(0), 0)
    SetPlayerTeam(Player(1), 0)
end

function InitAllyPriorities()
    SetStartLocPrioCount(0, 1)
    SetStartLocPrio(0, 0, 3, MAP_LOC_PRIO_HIGH)

    SetStartLocPrioCount(1, 3)
    SetStartLocPrio(1, 0, 0, MAP_LOC_PRIO_HIGH)
    SetStartLocPrio(1, 1, 3, MAP_LOC_PRIO_LOW)
    SetStartLocPrio(1, 2, 4, MAP_LOC_PRIO_LOW)

    SetStartLocPrioCount(2, 1)
    SetStartLocPrio(2, 0, 3, MAP_LOC_PRIO_HIGH)

    SetStartLocPrioCount(3, 2)
    SetStartLocPrio(3, 0, 0, MAP_LOC_PRIO_HIGH)
    SetStartLocPrio(3, 1, 2, MAP_LOC_PRIO_HIGH)

    SetStartLocPrioCount(4, 5)
    SetStartLocPrio(4, 0, 0, MAP_LOC_PRIO_HIGH)
    SetStartLocPrio(4, 1, 1, MAP_LOC_PRIO_HIGH)
    SetStartLocPrio(4, 2, 2, MAP_LOC_PRIO_LOW)
    SetStartLocPrio(4, 3, 3, MAP_LOC_PRIO_HIGH)
    SetStartLocPrio(4, 4, 5, MAP_LOC_PRIO_HIGH)

    SetStartLocPrioCount(5, 3)
    SetStartLocPrio(5, 0, 2, MAP_LOC_PRIO_LOW)
    SetStartLocPrio(5, 1, 3, MAP_LOC_PRIO_LOW)
    SetStartLocPrio(5, 2, 4, MAP_LOC_PRIO_HIGH)
end

function config()
    SetMapName("Just another Warcraft III map")
    SetMapDescription("Nondescript")
    SetPlayers(6)
    SetTeams(6)
    SetGamePlacement(MAP_PLACEMENT_TEAMS_TOGETHER)

    DefineStartLocation(0, 0, 0)
    DefineStartLocation(1, 0, 0)
    DefineStartLocation(2, 0, 0)
    DefineStartLocation(3, 0, 0)
    DefineStartLocation(4, 0, 0)
    DefineStartLocation(5, 0, 0)

    InitCustomPlayerSlots()
    SetPlayerSlotAvailable(Player(0), MAP_CONTROL_USER)
    SetPlayerSlotAvailable(Player(1), MAP_CONTROL_USER)
    SetPlayerSlotAvailable(Player(2), MAP_CONTROL_USER)
    SetPlayerSlotAvailable(Player(3), MAP_CONTROL_USER)
    SetPlayerSlotAvailable(Player(4), MAP_CONTROL_USER)
    SetPlayerSlotAvailable(Player(5), MAP_CONTROL_USER)
    InitGenericPlayerSlots()
    InitAllyPriorities()
end