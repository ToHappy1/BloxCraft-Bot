local whitelist = { -- item name : max price to pay
    ["Spider TV"] = 25000,
    ["Chef TV Man"] = 17500,
    ["Engineer Cameraman"] = 16500,
    ["Healer TV Woman"] = 2500,
    ["Corrupted Cameraman"] = 72500,
    ["Chief Clockman"] = 175000,
    ["Titan Clover Man"] = 42500,
    ["Speaker Repair Drone"] = 3500
}

local purchased_webhook = "https://discord.com/api/webhooks/1250361596635643915/7UaeGC4GxqSXQwsjS_Sp1IbRQ77ZYD6djHx7RRvrHbzho5ZUoPhzyvfFnJt-x6Ot7HlM"
local current_gem_webhook = "https://discord.com/api/webhooks/1250361599928045680/Igsk32_7qut7J5cdfjhdrJrhVLPdyL5MPGTVimj2pid6jeZHUJZsio3PskWVetvDQjUS" -- will send on script execution and everytime something is purchased

repeat task.wait() until game:IsLoaded()
task.wait(10) -- make sure everything is loaded

print('script executed')
local PlazaPlaceID = 14682939953
if game.PlaceId ~= PlazaPlaceID then
    game:GetService("TeleportService"):Teleport(PlazaPlaceID, game.Players.LocalPlayer)
end
print('tpd to plaza')
local HS = game:GetService("HttpService")
local GS = game:GetService("GuiService")
local VIM = game:GetService("VirtualInputManager")
local P = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
request = http_request or request or HttpPost or syn.request or http.request

local MultiboxFramework = require(RS:WaitForChild("MultiboxFramework"))
local RunService = game:GetService("RunService")
while not MultiboxFramework.Loaded do
    RunService.Heartbeat:Wait()
end

local player = P.LocalPlayer
local PlayerGui = player.PlayerGui

local function getCurGems()
    local replica = MultiboxFramework.Replicate:WaitForReplica("PlayerData-" .. player.UserId)
    local data = replica:GetData()
    return data.Currencies.Gems
end

local function webhook(link, data)

    local hts = game:GetService("HttpService"):JSONEncode(data)

    local headers = {["content-type"] = "application/json"}
    local abAL = {Url = link, Body = hts, Method = "POST", Headers = headers}
    request(abAL)
end

function getAvatarThumbnail(UserId)
    local Url = "https://thumbnails.roproxy.com/v1/users/avatar-headshot?userIds="..UserId.."&size=180x180&format=Png&isCircular=false"
    local Response = request({
        Url = Url,
        Method = "GET",
        Headers = {},
        Body = nil
    })
    if Response.Success then
        local Data = HS:JSONDecode(Response.Body)
        return Data["data"][1]["imageUrl"]
    else
        return ""
    end
end


local function bought_unit(unit_name, unit_price)

    unit_name, unit_price = tostring(unit_name), tostring(unit_price)

    local data = {
        ["content"] = nil,
        ["embeds"] = {
            {
                ["description"] = "Unit Purchased: "..unit_name.."\nPrice: "..unit_price,
                ["color"] = nil,
                ["author"] = {
                    ["name"] = player.DisplayName
                }
            }
        },
        ["username"] = "Gem Update",
        ["avatar_url"] = getAvatarThumbnail(player.UserId),
        ["attachments"] = {}
    }

    webhook(purchased_webhook, data)

end


local function gem_update()

    local data = {
        ["content"] = nil,
        ["embeds"] = {
            {
                ["description"] = "Current Gems: "..tostring(getCurGems()),
                ["color"] = nil,
                ["author"] = {
                    ["name"] = player.DisplayName
                }
            }
        },
        ["username"] = "Gem Update",
        ["avatar_url"] = getAvatarThumbnail(player.UserId),
        ["attachments"] = {}
    }

    webhook(current_gem_webhook, data)

end

gem_update()

local function clickGUIButton(buttonInst)
    GS.SelectedObject = buttonInst
    VIM:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
    task.wait(0.1)
    VIM:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
    task.wait(1)
end

local function clickOkButton()
    local clicked = false
    if PlayerGui.MainFrames.NotificationFrame.Visible then
        pcall(function()
            clickGUIButton(PlayerGui.MainFrames.NotificationFrame.BigNotification.Buttons.OkButton.Btn)
            task.wait(1)
            clicked = true
        end)
    end
    return clicked
end

local function getMarketplace()
    local marketplace = {}

    local allUnits = PlayerGui.Lobby.MarketplaceFrame.MarketplaceMain.MainFrame.BuyMenu.AllUnits
    for _, unitFrame in pairs(allUnits:GetChildren()) do
        local stock_amount, buy_button, unit_name, unit_price = nil, nil, nil, nil

        pcall(function()
            
            stock_amount = unitFrame.MainFrame.StockAmount.Text

            buy_button = unitFrame.MainFrame.UnitInfo.Buttons.BuyUnit.BuyButton

            unit_name = unitFrame.MainFrame.UnitInfo.UnitName.Text

            unit_price = unitFrame.MainFrame.UnitInfo.BestPrice.BestPrice.Text
            if unit_price:match("k") then
                unit_price = unit_price:gsub("k","")
                unit_price = (tonumber(unit_price) * 1000) + 100
            end
            unit_price = tonumber(unit_price) or nil

        end)

        if (stock_amount and stock_amount ~= "Stock: 0") and buy_button and unit_name and unit_price then
            marketplace[buy_button] = {
                unit_name = unit_name,
                unit_price = unit_price
            }
        end
    end

    --[[ 

    local marketplace = {
        [buy_button] = {
            unit_name = "corrupted item unit",
            unit_price = 10000
        }
    }

    ]]

    return marketplace
end

local function handle_purchase(buy_button)

    local LoadingFrame = PlayerGui.LoadingGui.LoadingFrame

    local MarketplaceFrame = PlayerGui.Lobby.MarketplaceFrame

    local PopupConfirmationFrame = PlayerGui.Lobby.MarketplaceFrame.MarketplaceMain.MainFrame.ConfirmPopup
    local CancelBut = PopupConfirmationFrame.Options.Cancel.CancelButton
    local ConfirmBut = PopupConfirmationFrame.Options.Confirm.ConfirmButton

    if not MarketplaceFrame.Visible then
        MarketplaceFrame.Visible = true
        task.wait(.5)
    end

    if PopupConfirmationFrame.Visible then
        clickGUIButton(CancelBut)
    end

    clickGUIButton(buy_button)

    local timeout = 0
    repeat task.wait(1) timeout += 1 until PopupConfirmationFrame.Visible or timeout > 20
    if PopupConfirmationFrame.Visible then
        clickGUIButton(ConfirmBut)
    end

    local timeout = 0
    repeat task.wait(1) timeout += 1 until not LoadingFrame.Visible or timeout > 20
    if timeout > 20 then
        LoadingFrame.Visible = false
    end
    
    task.wait(3)

end




local function handle_buy(buy_button, unit)

    task.wait(1)

    local unit_name, unit_price = unit.unit_name, unit.unit_price

    local oldGems = getCurGems()
    local bought = handle_purchase(buy_button)
    local newGems = getCurGems()

    local success = oldGems ~= newGems
    if success then
        local diff = (newGems - oldGems)
        local curGems = getCurGems()

        bought_unit(unit_name, unit_price)
        gem_update()
        
    end

    return success
end

local function whitelist_match(unit_name, unit_price)
    for item_name, max_price in pairs(whitelist) do
        if unit_name == item_name and unit_price <= max_price then
            return true
        end
    end

    return false
end

local s,f = nil, nil
local bought = false
repeat
    clickOkButton()
    bought = false
    s,f = pcall(function()
        for buy_button, unit in pairs(getMarketplace()) do
            if whitelist_match(unit.unit_name, unit.unit_price) then
                bought = handle_buy(buy_button, unit)
            end
        end
    end)
    task.wait(3)
    local clicked = clickOkButton()
    if clicked and not bought then
        bought = true
    end
until not bought or f

-- join new server


local visitedServersFileName = game.Players.LocalPlayer.Name.."visitedServersFORAUTOBUY.json"

local RS = game:GetService("ReplicatedStorage")
local HS = game:GetService("HttpService")
local TPS = game:GetService("TeleportService")

if not isfile(visitedServersFileName) then
    writefile(visitedServersFileName, HS:JSONEncode({}))
end


local function getVisitedServers()
    local servers = HS:JSONDecode(readfile(visitedServersFileName))
    if #servers > 100 then
        table.remove(servers, 1)
    end
    writefile(visitedServersFileName, HS:JSONEncode(servers))
    return servers
end

local function applyVisitedServer(ServerID)
    local visitedServers = getVisitedServers()
    table.insert(visitedServers, ServerID)
    writefile(visitedServersFileName, HS:JSONEncode(visitedServers))
end

local function hopToUnvisitedServer()
    local visitedServers = getVisitedServers()

    local Api = "https://games.roblox.com/v1/games/"
    local _place = game.PlaceId
    local _servers = Api.._place.."/servers/Public?sortOrder=Asc&limit=100"
    function ListServers(cursor)
        local Raw = game:HttpGet(_servers .. ((cursor and "&cursor="..cursor) or ""))
        return HS:JSONDecode(Raw)
    end

    local ServerID
    local Servers = ListServers(Next)
    local v = 0
    repeat  
        v += 1

        local ServerData = Servers.data[v]

        if ServerData and ServerData.playing >= 30 and not table.find(visitedServers, ServerData.id) then
            ServerID = ServerData.id
        elseif not ServerData then
            Servers = ListServers(Servers.nextPageCursor)
            v = 0
        end

        task.wait(.01)
    until ServerID

    applyVisitedServer(ServerID)

    while task.wait() do
        TPS:TeleportToPlaceInstance(_place,ServerID,game.Players.LocalPlayer)
        task.wait(1)
    end

end


hopToUnvisitedServer()
