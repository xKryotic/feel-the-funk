local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xKryotic/feel-the-funk/main/main1.lua"))()

local framework, scrollHandler
while true do
    for _, obj in next, getgc(true) do
        if type(obj) == 'table' and rawget(obj, 'GameUI') then
            framework = obj;
            break
        end 
    end

    for _, module in next, getloadedmodules() do
        if module.Name == 'ScrollHandler' then
            scrollHandler = module;
            break;
        end
    end

    if (type(framework) == 'table') and (typeof(scrollHandler) == 'Instance') then
        break
    end

    wait(1)
end

local runService = game:GetService('RunService')
local userInputService = game:GetService('UserInputService')
local client = game:GetService('Players').LocalPlayer;
local random = Random.new()

local task = task or getrenv().task;
local fastWait, fastSpawn = task.wait, task.spawn;

local fireSignal, rollChance do
    local set_identity = (type(syn) == 'table' and syn.set_thread_identity) or setidentity or setthreadcontext
    function fireSignal(target, signal, ...)    
        set_identity(2) 
        for _, signal in next, getconnections(signal) do
            if type(signal.Function) == 'function' and islclosure(signal.Function) then
                local scr = rawget(getfenv(signal.Function), 'script')
                if scr == target then
                    pcall(signal.Function, ...)
                end
            end
        end
        set_identity(7)
    end


    function rollChance()
        if (library.flags.autoPlayerMode == 'Manual') then
            if (library.flags.sickHeld) then return 'Sick' end
            if (library.flags.goodHeld) then return 'Good' end
            if (library.flags.okayHeld) then return 'Ok' end
            if (library.flags.missHeld) then return 'Bad' end

            return 'Bad' 
        end

        local chances = {
            { type = 'Sick', value = library.flags.sickChance },
            { type = 'Good', value = library.flags.goodChance },
            { type = 'Ok', value = library.flags.okChance },
            { type = 'Bad', value = library.flags.badChance },
            { type = 'Miss' , value = library.flags.missChance },
        }
        
        table.sort(chances, function(a, b) 
            return a.value > b.value 
        end)

        local sum = 0;
        for i = 1, #chances do
            sum += chances[i].value
        end

        if sum == 0 then

            return chances[random:NextInteger(1, #chances)].type 
        end

        local initialWeight = random:NextInteger(0, sum)
        local weight = 0;

        for i = 1, #chances do
            weight = weight + chances[i].value

            if weight > initialWeight then
                return chances[i].type
            end
        end

        return 'Sick' 
    end
end

local map = { [0] = 'Left', [1] = 'Down', [2] = 'Up', [3] = 'Right', }
local keys = { Up = Enum.KeyCode.Up; Down = Enum.KeyCode.Down; Left = Enum.KeyCode.Left; Right = Enum.KeyCode.Right; }

local chanceValues = {
    Sick = 96,
    Good = 92,
    Ok = 87,
    Bad = 75,
    Miss = 0
}

local hitChances = {}

if shared._id then
    pcall(runService.UnbindFromRenderStep, runService, shared._id)
end

shared._id = game:GetService('HttpService'):GenerateGUID(false)
runService:BindToRenderStep(shared._id, 1, function()
    if (not library.flags.autoPlayer) then return end

    local arrows = {}
    for _, obj in next, framework.UI.ActiveSections do
        arrows[#arrows + 1] = obj;
    end

    for idx = 1, #arrows do
        local arrow = arrows[idx]
        if type(arrow) ~= 'table' then 
            continue
        end

        if (arrow.Side == framework.UI.CurrentSide) and (not arrow.Marked) then
            local indice = (arrow.Data.Position % 4)
            local position = map[indice]
            
            if (position) then
                local currentTime = framework.SongPlayer.CurrentlyPlaying.TimePosition
                local distance = (1 - math.abs(arrow.Data.Time - currentTime)) * 100

                if (arrow.Data.Time == 0) then
                    continue
                end

                local result = rollChance()
                arrow._hitChance = arrow._hitChance or result;

                local hitChance = (library.flags.autoPlayerMode == 'Manual' and result or arrow._hitChance)
                if distance >= chanceValues[hitChance] then
                    fastSpawn(function()
                        arrow.Marked = true;
                        fireSignal(scrollHandler, userInputService.InputBegan, { KeyCode = keys[position], UserInputType = Enum.UserInputType.Keyboard }, false)

                        if arrow.Data.Length > 0 then
                            fastWait(arrow.Data.Length + (random:NextInteger(0, library.flags.autoDelay) / 1000))
                        else
                            fastWait(library.flags.autoDelay / 1000) 
                        end

                        fireSignal(scrollHandler, userInputService.InputEnded, { KeyCode = keys[position], UserInputType = Enum.UserInputType.Keyboard }, false)
                        arrow.Marked = nil;
                    end)
                end
            end
        end
    end
end)

local window = library:CreateWindow('xKryotics Destroyer') do
    local folder = window:AddFolder('Autoplayer') do
        local toggle = folder:AddToggle({ text = 'Autoplayer', flag = 'autoPlayer' })

        folder:AddBind({ text = 'Autoplayer toggle', flag = 'autoPlayerToggle', key = Enum.KeyCode.End, callback = function() 
            toggle:SetState(not toggle.state)
        end })


        folder:AddSlider({ text = 'Sick %', flag = 'sickChance', min = 0, max = 100, value = 100 })
        folder:AddSlider({ text = 'Good %', flag = 'goodChance', min = 0, max = 100, value = 0 })
        folder:AddSlider({ text = 'Ok %', flag = 'okChance', min = 0, max = 100, value = 0 })
        folder:AddSlider({ text = 'Bad %', flag = 'badChance', min = 0, max = 100, value = 0 })
        folder:AddSlider({ text = 'Miss %', flag = 'missChance', min = 0, max = 100, value = 0 })
        folder:AddSlider({ text = 'Release delay (ms)', flag = 'autoDelay', min = 40, max = 350, value = 50 })
    end


    window:AddBind({ text = 'Menu toggle', key = Enum.KeyCode.Delete, callback = function() library:Close() end })
end

library:Init()