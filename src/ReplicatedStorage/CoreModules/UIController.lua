--[[
    EXAMPLES:

    local TestClick = UIController.Connection(TestBtn)

    local function ClickFunction(message: string)
        print(message)
    end

    TestClick:RegisterEvent("MouseButton1Down", ClickFunction, {"Hello World!"}) 

    OR

    TestClick:RegisterEvent("MouseButton1Down", function()
       print("Hello World!") 
    end) 

    -----------

    local testClick = UIController.Connection(TestBtn)
    testClick:RegisterDefaultTweens()

    OR

    local size: Udim2 =  UDim2.fromScale(testClick.TweenValues.OriginalSize.Scale.X - 0.01, testClick.TweenValues.OriginalSize.Scale.Y - 0.01)
    testClick:RegisterTweenEvent("MouseButton1Down", size))
]]

--// Types
export type UIController = {
    Interface: GuiObject,
    EventConnections: {
        [string]: {
            connection: RBXScriptConnection,
            functions: {(any?) -> ()}
        }
    },
    
    TweenValues: {
        OriginalPosition: UDim2,
        OriginalSize: UDim2    }
}

type DropShadow = {
    Shape: string,
    Spread: number?,
    Offset: Vector2?,
    Transparency: number?,
    Color: Color3?,
    Events: {string}?
}

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

--// Variables
local tweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Linear)

--// Module
local UIController = {}

-- // Constructor
function UIController.Connection(Interface: GuiObject ) : UIController
    local self = setmetatable({}, {__index = UIController})

    self.Interface = Interface
    self.DropShadow = nil
    self.EventConnections = {}

    self.TweenValues = {
        OriginalPosition = Interface.Position,
        OriginalSize = Interface.Size
    }

    return self
end 

-- // Main Events!
function UIController:CreateEventConnect(eventName: string, callback: () -> ())
    local function callAllFunctions()
        for _, callbackInfo in pairs(self.EventConnections[eventName].functions) do
            local callbackFunction = callbackInfo.func
            local parameters = callbackInfo.parameters
            callbackFunction(table.unpack(parameters))
        end
    end

    self.EventConnections[eventName] = {
        connection = self.Interface[eventName]:Connect(callAllFunctions),
        functions = {callback}
    }
end

function UIController:RegisterEvent(eventName: string, callbackFunction: () -> (), parameters: {any}, id: string?)
    id = id or tostring(callbackFunction) 

    if not self.EventConnections[eventName] then
        self:CreateEventConnect(eventName, {func = callbackFunction, parameters = parameters or {}})
        return
    end

    self.EventConnections[eventName].functions[id] = {
        func = callbackFunction,
        parameters = parameters or {}
    }
end

function UIController:DisconnectEvent(eventName: string)
    if self.EventConnections[eventName] then 
        self.EventConnections[eventName].connection:Disconnect()
        self.EventConnections[eventName] = nil
    end
end

function UIController:RemoveEventFunction(eventName: string, id: string)
    if self.EventConnections[eventName] and self.EventConnections[eventName].functions[id] then
        self.EventConnections[eventName].functions[id] = nil
    end
end

--// Tween Effects
function UIController:RegisterTweenEvent(eventName: string, size: UDim2)
    self:RegisterEvent(eventName, function ()
        local tween: Tween = TweenService:Create(self.Interface, tweenInfo, {Size = size, Position = self.TweenValues.OriginalPosition})
        tween:Play()
    end)
end

function UIController:RegisterDefaultTweens()
    self:RegisterTweenEvent("MouseButton1Down", UDim2.fromScale(self.TweenValues.OriginalSize.X.Scale - 0.025, self.TweenValues.OriginalSize.Y.Scale - 0.025))
    self:RegisterTweenEvent("MouseButton1Up", self.TweenValues.OriginalSize)

    self:RegisterTweenEvent("MouseEnter", UDim2.fromScale(self.TweenValues.OriginalSize.X.Scale + 0.005, self.TweenValues.OriginalSize.Y.Scale + 0.005))
    self:RegisterTweenEvent("MouseLeave", self.TweenValues.OriginalSize)
end

--// Additional Stuff
function UIController:EnableTips(title: string, tip: string)
    if not self.Tooltip then
        local tooltip = Instance.new("TextLabel")
        tooltip.Name = "Tooltip"
        tooltip.Size = UDim2.new(0, 150, 0, 50)
        tooltip.BackgroundColor3 = Color3.new(0, 0, 0)
        tooltip.TextColor3 = Color3.new(1, 1, 1)
        tooltip.TextWrapped = true
        tooltip.Visible = false
        tooltip.Parent = self.Interface.Parent
        
        self.Tooltip = tooltip
    end

    self.Tooltip.Text = title .. "\n" .. tip

    local mouseEnterId = "tooltipMouseEnter"
    local mouseLeaveId = "tooltipMouseLeave"
    local isHovered = false

    self:RegisterEvent("MouseEnter", function()
        if self.Tooltip then
            isHovered = true
            while isHovered do
                local mouseLocation = UserInputService:GetMouseLocation()
                self.Tooltip.Position = UDim2.fromOffset(mouseLocation.X - 150, mouseLocation.Y - 20) -- Offset to avoid overlap
                self.Tooltip.Visible = true
                task.wait()
            end
        end
    end, {}, mouseEnterId)

    self:RegisterEvent("MouseLeave", function()
        if self.Tooltip then
            isHovered = false
            self.Tooltip.Visible = false
        end
    end, {}, mouseLeaveId)
end

function UIController:DisableTips()
    local mouseEnterId = "tooltipMouseEnter"
    local mouseLeaveId = "tooltipMouseLeave"
    
    self:RemoveEventFunction("MouseEnter", mouseEnterId)
    self:RemoveEventFunction("MouseLeave", mouseLeaveId)
    
    if self.Tooltip then
        self.Tooltip:Destroy()
        self.Tooltip = nil
    end
end

--// Drop Shadows
function UIController:AddShadow(properties: DropShadow)
    local shadow = ReplicatedStorage.DropShadows:FindFirstChild(properties.Shape.."Shadow")
    if not shadow then return false end

    local function createShadow()
        if self.DropShadow then return end
        self.DropShadow = shadow:Clone()
        self.DropShadow.Size = UDim2.new(1 + (properties.Spread/100 or 0.1), 0, 1 + (properties.Spread/100 or 0.1), 0)
        self.DropShadow.Parent = self.Interface
        self.DropShadow.Shadow.ImageColor3 = properties.Color or Color3.new(0, 0, 0)
        self.DropShadow.Shadow.ImageTransparency = properties.Transparency
        if properties.Offset then self.DropShadow.Position = self.DropShadow.Position + UDim2.fromScale(properties.Offset.X/100, properties.Offset.Y/100) end
        self.DropShadow.ZIndex = 0
        self.DropShadow.Shadow.ZIndex = 0
    end

    if properties.Events and #properties.Events > 0 then
        self:RegisterEvent(properties.Events[1], function ()
            createShadow()
        end)

        if #properties.Events > 1 then
            self:RegisterEvent(properties.Events[2], function ()
                if not self.DropShadow then return end
                self.DropShadow:Destroy()
                self.DropShadow = nil
            end)
        end
    else
        createShadow()
    end
end

return UIController