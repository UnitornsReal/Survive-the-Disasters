--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Variables
local Client: Player = Players.LocalPlayer
local PlayerGui = Client.PlayerGui
local Hud = PlayerGui:WaitForChild("Hud")
local Left = Hud.Left
local Top = Hud.Top
local Holder = Left.Holder

local Values = ReplicatedStorage:WaitForChild("Values")
local statusVal: StringValue = Values:WaitForChild("Status")
local timeVal: IntValue = Values:WaitForChild("Time")

--// Modules
local FrameController = {}
local Modules = require(ReplicatedStorage.Modules)

function FrameController.Init()
    FrameController.InitButtons();
    FrameController.InitStatus();
end

function FrameController.InitStatus()
    local statusText, timeText: TextLabel = Top.Status, Top.Time
    statusText.Text = statusVal.Value timeText.Text = tostring(timeVal.Value)
    statusVal:GetPropertyChangedSignal("Value"):Connect(function() statusText.Text = statusVal.Value end)
    timeVal:GetPropertyChangedSignal("Value"):Connect(function() timeText.Text = tostring(timeVal.Value) end)
end

function FrameController.InitButtons()
    for _, button in pairs(Holder:GetChildren()) do
        if button:IsA("TextButton") then
            local click = Modules.UIController.Connection(button)
            local uiGradient = button.TextLabel.UIGradient
            local firstColor = uiGradient.Color.Keypoints[2].Value

            click:RegisterDefaultTweens()
            click:AddShadow({
                Shape = "Circle", 
                Spread = 70,
                Transparency = 0.25,
                Color = firstColor,
                Events = {"MouseEnter", "MouseLeave"}
            })
        end
    end
end

return FrameController