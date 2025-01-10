type Disaster = {
    StartDisaster: () -> (),
    StopDisaster: () -> (),

    Name: string,
    Time: number,
    Points: number,
    Running: boolean
}

type Properties = {Status: string, Time: number}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Values = ReplicatedStorage.Values
local Disasters = script.Parent.Disasters

local Main = {}
Main.MapDimensions = {
    Vector3.new(-110.102, 0, 168.418),
    Vector3.new(231.748, 0, -160.082)
}

function Main.UpdateValues(properties: Properties)
    if properties.Status then Values.Status.Value = properties.Status end
    if properties.Time then Values.Time.Value = properties.Time end
end

function Main.Init()
    Main.Timer({Status = "Intermission", Time = 20});

    local randomDisaster: Disaster = require(Disasters:GetChildren()[math.random(1, #Disasters:GetChildren())])
    task.spawn(randomDisaster.StartDisaster)

    Main.Timer({Status = randomDisaster.Name, Time = randomDisaster.Time});
    randomDisaster.StopDisaster();
    Main.Init();
end

function Main.Timer(Properties: Properties)
    Main.UpdateValues(Properties)

    for remaining = Properties.Time, 0, -1 do
        Main.UpdateValues({Time = remaining})
        task.wait(1)
    end
end

return Main