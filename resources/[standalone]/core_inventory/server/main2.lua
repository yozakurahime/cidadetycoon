local L0_1, L1_1, L2_1, L3_1, L4_1
L0_1 = {}
ActiveIncentories = L0_1
L0_1 = {}
Inventory = L0_1
L0_1 = {}
Drops = L0_1
L0_1 = {}
DynamicItems = L0_1
L0_1 = {}
UsedItems = L0_1
L0_1 = {}
Items = L0_1
ESX = _G.ESX
L0_1 = function(...) end
L1_1 = ""
function L2_1(A0_2)
end
L0_1(L1_1, L2_1)
L0_1 = Citizen
L0_1 = L0_1.CreateThread
function L1_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2
  L0_2 = exports
  L0_2 = L0_2.oxmysql
  L1_2 = L0_2
  L0_2 = L0_2.query
  L2_2 = "SELECT * FROM items WHERE 1"
  L3_2 = {}
  function L4_2(A0_3)
    local L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3
    L1_3 = ipairs
    L2_3 = A0_3
    L1_3, L2_3, L3_3, L4_3 = L1_3(L2_3)
    for L5_3, L6_3 in L1_3, L2_3, L3_3, L4_3 do
      L7_3 = Items
      L8_3 = L6_3.name
      L7_3[L8_3] = L6_3
    end
  end
  L0_2(L1_2, L2_2, L3_2, L4_2)
end
L0_1(L1_1)
L0_1 = ESX
L0_1 = L0_1.RegisterServerCallback
L1_1 = "core_inventory:server:getInventory"
function L2_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = ESX
  L2_2 = L2_2.GetPlayerFromId
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  L3_2 = A1_2
  L4_2 = getInventory
  L5_2 = "content-"
  L6_2 = L2_2.getcitizenid
  L6_2 = L6_2()
  L7_2 = L6_2
  L6_2 = L6_2.gsub
  L8_2 = ":"
  L9_2 = ""
  L6_2 = L6_2(L7_2, L8_2, L9_2)
  L5_2 = L5_2 .. L6_2
  L4_2, L5_2, L6_2, L7_2, L8_2, L9_2 = L4_2(L5_2)
  L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2)
end
L0_1(L1_1, L2_1)
L0_1 = ESX
L0_1 = L0_1.RegisterServerCallback
L1_1 = "core_inventory:server:getBackpacks"
function L2_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L2_2 = ESX
  L2_2 = L2_2.GetPlayerFromId
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  L3_2 = ActiveIncentories
  L4_2 = "content-"
  L5_2 = L2_2.getcitizenid
  L5_2 = L5_2()
  L6_2 = L5_2
  L5_2 = L5_2.gsub
  L7_2 = ":"
  L8_2 = ""
  L5_2 = L5_2(L6_2, L7_2, L8_2)
  L4_2 = L4_2 .. L5_2
  L3_2 = L3_2[L4_2]
  if L3_2 then
    L3_2 = ActiveIncentories
    L4_2 = "content-"
    L5_2 = L2_2.getcitizenid
    L5_2 = L5_2()
    L6_2 = L5_2
    L5_2 = L5_2.gsub
    L7_2 = ":"
    L8_2 = ""
    L5_2 = L5_2(L6_2, L7_2, L8_2)
    L4_2 = L4_2 .. L5_2
    L3_2 = L3_2[L4_2]
    L3_2 = L3_2.content
    L4_2 = {}
    L5_2 = pairs
    L6_2 = L3_2
    L5_2, L6_2, L7_2, L8_2 = L5_2(L6_2)
    for L9_2, L10_2 in L5_2, L6_2, L7_2, L8_2 do
      L11_2 = L10_2.backpackModel
      if L11_2 then
        L4_2[L9_2] = L10_2
      end
    end
    L5_2 = A1_2
    L6_2 = L4_2
    L5_2(L6_2)
  else
    L3_2 = A1_2
    L4_2 = {}
    L3_2(L4_2)
  end
end
L0_1(L1_1, L2_1)
L0_1 = RegisterServerEvent
L1_1 = "core_inventory:server:addDynamicItem"
function L2_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L5_2 = source
  L6_2 = ESX
  L6_2 = L6_2.GetPlayerFromId
  L7_2 = L5_2
  L6_2 = L6_2(L7_2)
  if not A3_2 then
    L7_2 = "content-"
    L8_2 = L6_2.getcitizenid
    L8_2 = L8_2()
    L9_2 = L8_2
    L8_2 = L8_2.gsub
    L10_2 = ":"
    L11_2 = ""
    L8_2 = L8_2(L9_2, L10_2, L11_2)
    L7_2 = L7_2 .. L8_2
    A3_2 = L7_2
  end
  L7_2 = DynamicItems
  L7_2[A0_2] = A4_2
  L7_2 = addItem
  L8_2 = A3_2
  L9_2 = A0_2
  L10_2 = A1_2
  L11_2 = A2_2
  L7_2(L8_2, L9_2, L10_2, L11_2)
end
L0_1(L1_1, L2_1)
L0_1 = ESX
L0_1 = L0_1.RegisterCommand
L1_1 = "giveitem"
L2_1 = "admin"
function L3_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L3_2 = ESX
  L3_2 = L3_2.GetPlayerFromId
  L4_2 = tonumber
  L5_2 = A1_2[1]
  L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2 = L4_2(L5_2)
  L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2)
  L4_2 = tonumber
  L5_2 = A1_2[3]
  L4_2 = L4_2(L5_2)
  L5_2 = Items
  L6_2 = tostring
  L7_2 = A1_2[2]
  L6_2 = L6_2(L7_2)
  L7_2 = L6_2
  L6_2 = L6_2.lower
  L6_2 = L6_2(L7_2)
  L5_2 = L5_2[L6_2]
  if L4_2 > 0 and nil ~= L3_2 then
    if nil ~= L5_2 then
      L6_2 = A1_2[1]
      L7_2 = tonumber
      L8_2 = A1_2[1]
      L7_2 = L7_2(L8_2)
      if nil ~= L7_2 then
        L7_2 = "content-"
        L8_2 = L3_2.getcitizenid
        L8_2 = L8_2()
        L9_2 = L8_2
        L8_2 = L8_2.gsub
        L10_2 = ":"
        L11_2 = ""
        L8_2 = L8_2(L9_2, L10_2, L11_2)
        L7_2 = L7_2 .. L8_2
        L6_2 = L7_2
      end
      L7_2 = json
      L7_2 = L7_2.decode
      L8_2 = A1_2[4]
      L7_2 = L7_2(L8_2)
      if not L7_2 then
        L7_2 = {}
      end
      L8_2 = defaultMetadata
      L9_2 = source
      L10_2 = L5_2
      L11_2 = L7_2
      L8_2 = L8_2(L9_2, L10_2, L11_2)
      L7_2 = L8_2
      L8_2 = addItem
      L9_2 = L6_2
      L10_2 = A1_2[2]
      L11_2 = L4_2
      L12_2 = L7_2
      L8_2(L9_2, L10_2, L11_2, L12_2)
    else
      L6_2 = sendTextMessage
      L7_2 = tonumber
      L8_2 = A1_2[1]
      L7_2 = L7_2(L8_2)
      L8_2 = Config
      L8_2 = L8_2.Text
      L8_2 = L8_2.item_does_not_exist
      L6_2(L7_2, L8_2)
    end
  else
    L6_2 = sendTextMessage
    L7_2 = tonumber
    L8_2 = A1_2[1]
    L7_2 = L7_2(L8_2)
    L8_2 = Config
    L8_2 = L8_2.Text
    L8_2 = L8_2.wrong_syntax
    L6_2(L7_2, L8_2)
  end
end
L0_1(L1_1, L2_1, L3_1)
L0_1 = ESX
L0_1 = L0_1.RegisterCommand
L1_1 = "removeitem"
L2_1 = "admin"
function L3_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L3_2 = ESX
  L3_2 = L3_2.GetPlayerFromId
  L4_2 = tonumber
  L5_2 = A1_2[1]
  L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2 = L4_2(L5_2)
  L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2)
  L4_2 = tonumber
  L5_2 = A1_2[3]
  L4_2 = L4_2(L5_2)
  L5_2 = Items
  L6_2 = tostring
  L7_2 = A1_2[2]
  L6_2 = L6_2(L7_2)
  L7_2 = L6_2
  L6_2 = L6_2.lower
  L6_2 = L6_2(L7_2)
  L5_2 = L5_2[L6_2]
  if L4_2 > 0 and nil ~= L3_2 then
    if nil ~= L5_2 then
      L6_2 = A1_2[1]
      L7_2 = tonumber
      L8_2 = A1_2[1]
      L7_2 = L7_2(L8_2)
      if nil ~= L7_2 then
        L7_2 = "content-"
        L8_2 = L3_2.getcitizenid
        L8_2 = L8_2()
        L9_2 = L8_2
        L8_2 = L8_2.gsub
        L10_2 = ":"
        L11_2 = ""
        L8_2 = L8_2(L9_2, L10_2, L11_2)
        L7_2 = L7_2 .. L8_2
        L6_2 = L7_2
      end
      L7_2 = removeItem
      L8_2 = L6_2
      L9_2 = A1_2[2]
      L10_2 = L4_2
      L7_2(L8_2, L9_2, L10_2)
    else
      L6_2 = sendTextMessage
      L7_2 = tonumber
      L8_2 = A1_2[1]
      L7_2 = L7_2(L8_2)
      L8_2 = Config
      L8_2 = L8_2.Text
      L8_2 = L8_2.item_does_not_exist
      L6_2(L7_2, L8_2)
    end
  else
    L6_2 = sendTextMessage
    L7_2 = tonumber
    L8_2 = A1_2[1]
    L7_2 = L7_2(L8_2)
    L8_2 = Config
    L8_2 = L8_2.Text
    L8_2 = L8_2.wrong_syntax
    L6_2(L7_2, L8_2)
  end
end
L4_1 = "admin"
L0_1(L1_1, L2_1, L3_1, L4_1)
L0_1 = ESX
L0_1 = L0_1.RegisterCommand
L1_1 = "clearinventory"
L2_1 = "admin"
function L3_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L3_2 = ESX
  L3_2 = L3_2.GetPlayerFromId
  L4_2 = tonumber
  L5_2 = A1_2[1]
  L4_2, L5_2, L6_2, L7_2, L8_2, L9_2 = L4_2(L5_2)
  L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2)
  if nil ~= L3_2 then
    L4_2 = A1_2[1]
    L5_2 = tonumber
    L6_2 = A1_2[1]
    L5_2 = L5_2(L6_2)
    if nil ~= L5_2 then
      L5_2 = "content-"
      L6_2 = L3_2.getcitizenid
      L6_2 = L6_2()
      L7_2 = L6_2
      L6_2 = L6_2.gsub
      L8_2 = ":"
      L9_2 = ""
      L6_2 = L6_2(L7_2, L8_2, L9_2)
      L5_2 = L5_2 .. L6_2
      L4_2 = L5_2
    end
    L5_2 = clearInventory
    L6_2 = L4_2
    L5_2(L6_2)
  else
    L4_2 = sendTextMessage
    L5_2 = tonumber
    L6_2 = A1_2[1]
    L5_2 = L5_2(L6_2)
    L6_2 = Config
    L6_2 = L6_2.Text
    L6_2 = L6_2.wrong_syntax
    L4_2(L5_2, L6_2)
  end
end
L4_1 = "admin"
L0_1(L1_1, L2_1, L3_1, L4_1)
function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = TriggerClientEvent
  L3_2 = "core_inventory:client:sendTextMessage"
  L4_2 = A0_2
  L5_2 = A1_2
  L2_2(L3_2, L4_2, L5_2)
end
sendTextMessage = L0_1
function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2
  L3_2 = ActiveIncentories
  L3_2 = L3_2[A0_2]
  L3_2 = L3_2.content
  L3_2 = L3_2[A1_2]
  L3_2 = L3_2.metadata
  L3_2 = L3_2.durability
  if not L3_2 then
    L3_2 = nil
  end
  if L3_2 then
    L4_2 = L3_2 - A2_2
    if L4_2 >= 0 then
      L4_2 = ActiveIncentories
      L4_2 = L4_2[A0_2]
      L4_2 = L4_2.content
      L4_2 = L4_2[A1_2]
      L4_2 = L4_2.metadata
      L5_2 = L3_2 - A2_2
      L4_2.durability = L5_2
    end
  end
end
removeDurability = L0_1
function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2
  L3_2 = ActiveIncentories
  L3_2 = L3_2[A0_2]
  L3_2 = L3_2.content
  L3_2 = L3_2[A1_2]
  L3_2 = L3_2.metadata
  L3_2 = L3_2.durability
  if not L3_2 then
    L3_2 = nil
  end
  if L3_2 and (A2_2 >= 0 or A2_2 <= 100) then
    L4_2 = ActiveIncentories
    L4_2 = L4_2[A0_2]
    L4_2 = L4_2.content
    L4_2 = L4_2[A1_2]
    L4_2 = L4_2.metadata
    L4_2.durability = A2_2
  end
end
setDurability = L0_1
function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L2_2 = ESX
  L2_2 = L2_2.GetPlayerFromId
  L3_2 = A1_2
  L2_2 = L2_2(L3_2)
  if L2_2 then
    L3_2 = L2_2.getcitizenid
    L3_2 = L3_2()
    L4_2 = Config
    L4_2 = L4_2.SyncOldInventory
    if L4_2 then
      L4_2 = exports
      L4_2 = L4_2.oxmysql
      L5_2 = L4_2
      L4_2 = L4_2.query
      L6_2 = "SELECT inventory FROM players WHERE citizenid = :cid"
      L7_2 = {}
      L7_2.cid = L3_2
      function L8_2(A0_3)
        local L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3, L12_3
        L1_3 = A0_3[1]
        if nil ~= L1_3 then
          L1_3 = json
          L1_3 = L1_3.decode
          L2_3 = A0_3[1]
          L2_3 = L2_3.inventory
          L1_3 = L1_3(L2_3)
          L2_3 = pairs
          L3_3 = L1_3
          L2_3, L3_3, L4_3, L5_3 = L2_3(L3_3)
          for L6_3, L7_3 in L2_3, L3_3, L4_3, L5_3 do
            L8_3 = addItem
            L9_3 = A0_2
            L10_3 = L6_3
            L11_3 = L7_3.count
            L12_3 = L7_3.metadata
            if not L12_3 then
              L12_3 = {}
            end
            L8_3(L9_3, L10_3, L11_3, L12_3)
          end
          L2_3 = exports
          L2_3 = L2_3.oxmysql
          L3_3 = L2_3
          L2_3 = L2_3.update
          L4_3 = "UPDATE `players` SET `inventory` = '[]' WHERE citizenid = :cid"
          L5_3 = {}
          L6_3 = L3_2
          L5_3.cid = L6_3
          function L6_3()
            local L0_4, L1_4
          end
          L2_3(L3_3, L4_3, L5_3, L6_3)
        end
      end
      L4_2(L5_2, L6_2, L7_2, L8_2)
    end
    L4_2 = pairs
    L5_2 = Config
    L5_2 = L5_2.StartItems
    L4_2, L5_2, L6_2, L7_2 = L4_2(L5_2)
    for L8_2, L9_2 in L4_2, L5_2, L6_2, L7_2 do
      L10_2 = addItem
      L11_2 = A0_2
      L12_2 = L8_2
      L13_2 = L9_2.amount
      L14_2 = L9_2.metadata
      L10_2(L11_2, L12_2, L13_2, L14_2)
    end
  end
end
firstInventory = L0_1
function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2
  L5_2 = "loot-"
  L6_2 = math
  L6_2 = L6_2.random
  L7_2 = 1
  L8_2 = 9999
  L6_2 = L6_2(L7_2, L8_2)
  L5_2 = L5_2 .. L6_2
  L6_2 = preopenInventory
  L7_2 = A0_2
  L8_2 = L5_2
  L9_2 = A1_2
  L10_2 = nil
  L11_2 = nil
  L12_2 = true
  L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2)
  L6_2 = Wait
  L7_2 = 500
  L6_2(L7_2)
  L6_2 = 1
  L7_2 = math
  L7_2 = L7_2.random
  L8_2 = A3_2
  L9_2 = A4_2
  L7_2 = L7_2(L8_2, L9_2)
  L8_2 = 1
  for L9_2 = L6_2, L7_2, L8_2 do
    L10_2 = Wait
    L11_2 = math
    L11_2 = L11_2.random
    L12_2 = 500
    L13_2 = 2000
    L11_2, L12_2, L13_2, L14_2, L15_2, L16_2 = L11_2(L12_2, L13_2)
    L10_2(L11_2, L12_2, L13_2, L14_2, L15_2, L16_2)
    L10_2 = false
    while not L10_2 do
      L11_2 = math
      L11_2 = L11_2.random
      L12_2 = 1
      L13_2 = #A2_2
      L11_2 = L11_2(L12_2, L13_2)
      L12_2 = math
      L12_2 = L12_2.random
      L13_2 = 1
      L14_2 = 100
      L12_2 = L12_2(L13_2, L14_2)
      L13_2 = A2_2[L11_2]
      L13_2 = L13_2[2]
      if L12_2 <= L13_2 then
        L12_2 = addItem
        L13_2 = L5_2
        L14_2 = tostring
        L15_2 = A2_2[L11_2]
        L15_2 = L15_2[1]
        L14_2 = L14_2(L15_2)
        L15_2 = 1
        L16_2 = {}
        L12_2(L13_2, L14_2, L15_2, L16_2)
        L10_2 = true
      end
    end
  end
end
openLoot = L0_1
function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2
  L2_2 = {}
  L3_2 = ActiveIncentories
  L3_2 = L3_2[A0_2]
  L3_2 = L3_2.rows
  L4_2 = ActiveIncentories
  L4_2 = L4_2[A0_2]
  L4_2 = L4_2.slots
  L5_2 = pairs
  L6_2 = ActiveIncentories
  L6_2 = L6_2[A0_2]
  L6_2 = L6_2.content
  L5_2, L6_2, L7_2, L8_2 = L5_2(L6_2)
  for L9_2, L10_2 in L5_2, L6_2, L7_2, L8_2 do
    L11_2 = L10_2.slot
    L12_2 = L10_2.slot
    L13_2 = L10_2.y
    L13_2 = L13_2 - 1
    L13_2 = L13_2 * L3_2
    L12_2 = L12_2 + L13_2
    L13_2 = L3_2
    for L14_2 = L11_2, L12_2, L13_2 do
      L15_2 = L14_2
      L16_2 = L10_2.x
      L16_2 = L16_2 - 1
      L16_2 = L14_2 + L16_2
      L17_2 = 1
      for L18_2 = L15_2, L16_2, L17_2 do
        L2_2[L18_2] = true
      end
    end
  end
  L5_2 = 0
  L6_2 = L4_2
  L7_2 = 1
  for L8_2 = L5_2, L6_2, L7_2 do
    L9_2 = false
    L10_2 = L8_2
    L11_2 = A1_2.y
    L11_2 = L11_2 - 1
    L11_2 = L11_2 * L3_2
    L11_2 = L8_2 + L11_2
    L12_2 = L3_2
    for L13_2 = L10_2, L11_2, L12_2 do
      L14_2 = A1_2.x
      L14_2 = L13_2 + L14_2
      L15_2 = math
      L15_2 = L15_2.ceil
      L16_2 = L13_2 + 1
      L16_2 = L16_2 / L3_2
      L15_2 = L15_2(L16_2)
      L15_2 = L15_2 * L3_2
      if L14_2 > L15_2 then
        L9_2 = true
      else
        L14_2 = L13_2
        L15_2 = A1_2.x
        L15_2 = L15_2 - 1
        L15_2 = L13_2 + L15_2
        L16_2 = 1
        for L17_2 = L14_2, L15_2, L16_2 do
          L18_2 = L2_2[L17_2]
          if true == L18_2 or L4_2 < L17_2 then
            L9_2 = true
          end
        end
      end
    end
    if not L9_2 then
      return L8_2
    end
  end
  L5_2 = nil
  return L5_2
end
getAvailableSlot = L0_1
function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = Items
  L2_2 = L2_2[A1_2]
  L3_2 = ActiveIncentories
  L3_2 = L3_2[A0_2]
  if L3_2 and L2_2 then
    L2_2.count = 0
    L3_2 = L2_2.metadata
    L2_2.info = L3_2
    L3_2 = pairs
    L4_2 = ActiveIncentories
    L4_2 = L4_2[A0_2]
    L4_2 = L4_2.content
    L3_2, L4_2, L5_2, L6_2 = L3_2(L4_2)
    for L7_2, L8_2 in L3_2, L4_2, L5_2, L6_2 do
      L9_2 = L8_2.name
      if L9_2 == A1_2 then
        L9_2 = L8_2.amount
        if not L9_2 then
          L9_2 = 1
        end
        L10_2 = L2_2.count
        L10_2 = L10_2 + L9_2
        L2_2.count = L10_2
      end
    end
    return L2_2
  else
    L3_2 = nil
    return L3_2
  end
end
getItem = L0_1
function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2
  L2_2 = Items
  L2_2 = L2_2[A1_2]
  L3_2 = ActiveIncentories
  L3_2 = L3_2[A0_2]
  if L3_2 and L2_2 then
    L3_2 = {}
    L4_2 = pairs
    L5_2 = ActiveIncentories
    L5_2 = L5_2[A0_2]
    L5_2 = L5_2.content
    L4_2, L5_2, L6_2, L7_2 = L4_2(L5_2)
    for L8_2, L9_2 in L4_2, L5_2, L6_2, L7_2 do
      L10_2 = L9_2.name
      if L10_2 == A1_2 then
        L10_2 = copy
        L11_2 = L2_2
        L10_2 = L10_2(L11_2)
        L11_2 = L9_2.metadata
        L10_2.info = L11_2
        L11_2 = L9_2.metadata
        L10_2.metadata = L11_2
        L10_2.count = 1
        L11_2 = L9_2.amount
        if L11_2 then
          L11_2 = 1
          L12_2 = L9_2.amount
          L13_2 = 1
          for L14_2 = L11_2, L12_2, L13_2 do
            L15_2 = table
            L15_2 = L15_2.insert
            L16_2 = L3_2
            L17_2 = L10_2
            L15_2(L16_2, L17_2)
          end
        else
          L11_2 = table
          L11_2 = L11_2.insert
          L12_2 = L3_2
          L13_2 = L10_2
          L11_2(L12_2, L13_2)
        end
      end
    end
    return L3_2
  else
    L3_2 = nil
    return L3_2
  end
end
getItems = L0_1
function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L3_2 = ActiveIncentories
  L3_2 = L3_2[A0_2]
  L3_2 = L3_2.content
  L3_2 = L3_2[A1_2]
  if L3_2 then
    L3_2 = ActiveIncentories
    L3_2 = L3_2[A0_2]
    L3_2 = L3_2.content
    L3_2 = L3_2[A1_2]
    L3_2.metadata = A2_2
  end
  L3_2 = saveInventory
  L4_2 = A0_2
  L3_2(L4_2)
  L3_2 = pairs
  L4_2 = ActiveIncentories
  L4_2 = L4_2[A0_2]
  L4_2 = L4_2.spectators
  L3_2, L4_2, L5_2, L6_2 = L3_2(L4_2)
  for L7_2, L8_2 in L3_2, L4_2, L5_2, L6_2 do
    if L8_2 then
      L9_2 = TriggerClientEvent
      L10_2 = "core_inventory:client:sync"
      L11_2 = L7_2
      L12_2 = A0_2
      L13_2 = ActiveIncentories
      L13_2 = L13_2[A0_2]
      L9_2(L10_2, L11_2, L12_2, L13_2)
    end
  end
end
updateMetadata = L0_1
function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2
  L1_2 = ActiveIncentories
  L1_2 = L1_2[A0_2]
  if L1_2 then
    L1_2 = {}
    L2_2 = {}
    L3_2 = pairs
    L4_2 = ActiveIncentories
    L4_2 = L4_2[A0_2]
    L4_2 = L4_2.content
    L3_2, L4_2, L5_2, L6_2 = L3_2(L4_2)
    for L7_2, L8_2 in L3_2, L4_2, L5_2, L6_2 do
      L9_2 = Items
      L10_2 = L8_2.name
      L9_2 = L9_2[L10_2]
      if L9_2 then
        L9_2 = L8_2.name
        L9_2 = L2_2[L9_2]
        if not L9_2 then
          L9_2 = 0
          L10_2 = pairs
          L11_2 = ActiveIncentories
          L11_2 = L11_2[A0_2]
          L11_2 = L11_2.content
          L10_2, L11_2, L12_2, L13_2 = L10_2(L11_2)
          for L14_2, L15_2 in L10_2, L11_2, L12_2, L13_2 do
            L16_2 = L15_2.name
            L17_2 = L8_2.name
            if L16_2 == L17_2 then
              L16_2 = L15_2.amount
              if not L16_2 then
                L16_2 = 1
              end
              L9_2 = L9_2 + L16_2
            end
          end
          L10_2 = copy
          L11_2 = Items
          L12_2 = L8_2.name
          L11_2 = L11_2[L12_2]
          L10_2 = L10_2(L11_2)
          L11_2 = L8_2.metadata
          L10_2.info = L11_2
          L11_2 = L8_2.metadata
          L10_2.metadata = L11_2
          L11_2 = L8_2.id
          L10_2.id = L11_2
          L10_2.count = L9_2
          L11_2 = L8_2.name
          L2_2[L11_2] = true
          L11_2 = table
          L11_2 = L11_2.insert
          L12_2 = L1_2
          L13_2 = L10_2
          L11_2(L12_2, L13_2)
        end
      end
    end
    return L1_2
  else
    L1_2 = {}
    return L1_2
  end
end
getInventory = L0_1
function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2
  L3_2 = {}
  L4_2 = 1
  L5_2 = A2_2
  L6_2 = 1
  for L7_2 = L4_2, L5_2, L6_2 do
    L8_2 = A1_2
    L9_2 = "-"
    L10_2 = math
    L10_2 = L10_2.random
    L11_2 = 0
    L12_2 = 99999
    L10_2 = L10_2(L11_2, L12_2)
    L8_2 = L8_2 .. L9_2 .. L10_2
    L9_2 = Items
    L9_2 = L9_2[A1_2]
    if not L9_2 then
      L10_2 = DynamicItems
      L10_2 = L10_2[A1_2]
      if L10_2 then
        L10_2 = DynamicItems
        L9_2 = L10_2[A1_2]
      end
    end
    L10_2 = ActiveIncentories
    L10_2 = L10_2[A0_2]
    if L10_2 and L9_2 then
      L10_2 = L9_2.category
      if not L10_2 then
        L10_2 = "misc"
      end
      L11_2 = L9_2.x
      if not L11_2 then
        L11_2 = Config
        L11_2 = L11_2.DefaultItemSizeX
      end
      L9_2.x = L11_2
      L11_2 = L9_2.y
      if not L11_2 then
        L11_2 = Config
        L11_2 = L11_2.DefaultItemSizeY
      end
      L9_2.y = L11_2
      L11_2 = getAvailableSlot
      L12_2 = A0_2
      L13_2 = L9_2
      L11_2 = L11_2(L12_2, L13_2)
      L12_2 = ActiveIncentories
      L12_2 = L12_2[A0_2]
      L12_2 = L12_2.content
      L13_2 = {}
      L14_2 = L9_2.x
      if not L14_2 then
        L14_2 = 1
      end
      L13_2.x = L14_2
      L14_2 = L9_2.y
      if not L14_2 then
        L14_2 = 1
      end
      L13_2.y = L14_2
      L13_2.slot = 0
      L13_2.id = L8_2
      L13_2.name = A1_2
      L13_2.flipped = 0
      L14_2 = L10_2 or L14_2
      if not L10_2 then
        L14_2 = "misc"
      end
      L13_2.category = L14_2
      L14_2 = metadata
      if not L14_2 then
        L14_2 = {}
      end
      L13_2.metadata = L14_2
      L12_2[L8_2] = L13_2
      if nil == L11_2 then
        L12_2 = sendTextMessage
        L13_2 = Config
        L13_2 = L13_2.Text
        L13_2 = L13_2.no_space
        L12_2(L13_2)
        L12_2 = ActiveIncentories
        L12_2 = L12_2[A0_2]
        L12_2 = L12_2.content
        L12_2[L8_2] = nil
        L12_2 = pairs
        L13_2 = L3_2
        L12_2, L13_2, L14_2, L15_2 = L12_2(L13_2)
        for L16_2, L17_2 in L12_2, L13_2, L14_2, L15_2 do
          L18_2 = removeItemExact
          L19_2 = A0_2
          L20_2 = L16_2
          L18_2(L19_2, L20_2)
        end
        L12_2 = false
        return L12_2
      else
        L3_2[L8_2] = true
        L12_2 = ActiveIncentories
        L12_2 = L12_2[A0_2]
        L12_2 = L12_2.content
        L12_2 = L12_2[L8_2]
        L12_2.slot = L11_2
      end
      L12_2 = L9_2.componentHash
      if L12_2 then
        L12_2 = ActiveIncentories
        L12_2 = L12_2[A0_2]
        L12_2 = L12_2.content
        L12_2 = L12_2[L8_2]
        L13_2 = L9_2.componentHash
        L12_2.componentHash = L13_2
      end
      L12_2 = L9_2.componentTint
      if L12_2 then
        L12_2 = ActiveIncentories
        L12_2 = L12_2[A0_2]
        L12_2 = L12_2.content
        L12_2 = L12_2[L8_2]
        L13_2 = L9_2.componentTint
        L12_2.componentTint = L13_2
      end
      L12_2 = L9_2.backpackModel
      if L12_2 then
        L12_2 = ActiveIncentories
        L12_2 = L12_2[A0_2]
        L12_2 = L12_2.content
        L12_2 = L12_2[L8_2]
        L13_2 = L9_2.backpackModel
        L12_2.backpackModel = L13_2
        L12_2 = ActiveIncentories
        L12_2 = L12_2[A0_2]
        L12_2 = L12_2.content
        L12_2 = L12_2[L8_2]
        L13_2 = L9_2.backpackTexture
        if not L13_2 then
          L13_2 = 1
        end
        L12_2.backpackTexture = L13_2
      end
      L12_2 = Config
      L12_2 = L12_2.ItemCategories
      L12_2 = L12_2[L10_2]
      L12_2 = L12_2.durability
      if L12_2 then
        L12_2 = ActiveIncentories
        L12_2 = L12_2[A0_2]
        L12_2 = L12_2.content
        L12_2 = L12_2[L8_2]
        L12_2 = L12_2.metadata
        L13_2 = Config
        L13_2 = L13_2.DefaultDurability
        L12_2.durability = L13_2
      end
      L12_2 = Config
      L12_2 = L12_2.ItemCategories
      L12_2 = L12_2[L10_2]
      L12_2 = L12_2.serial
      if L12_2 then
        L12_2 = ActiveIncentories
        L12_2 = L12_2[A0_2]
        L12_2 = L12_2.content
        L12_2 = L12_2[L8_2]
        L12_2 = L12_2.metadata
        L13_2 = string
        L13_2 = L13_2.upper
        L14_2 = string
        L14_2 = L14_2.char
        L15_2 = math
        L15_2 = L15_2.random
        L16_2 = 97
        L17_2 = 122
        L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2 = L15_2(L16_2, L17_2)
        L14_2 = L14_2(L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2)
        L15_2 = string
        L15_2 = L15_2.char
        L16_2 = math
        L16_2 = L16_2.random
        L17_2 = 97
        L18_2 = 122
        L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2 = L16_2(L17_2, L18_2)
        L15_2 = L15_2(L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2)
        L16_2 = math
        L16_2 = L16_2.random
        L17_2 = 0
        L18_2 = 9
        L16_2 = L16_2(L17_2, L18_2)
        L17_2 = math
        L17_2 = L17_2.random
        L18_2 = 0
        L19_2 = 9
        L17_2 = L17_2(L18_2, L19_2)
        L18_2 = math
        L18_2 = L18_2.random
        L19_2 = 0
        L20_2 = 9
        L18_2 = L18_2(L19_2, L20_2)
        L19_2 = math
        L19_2 = L19_2.random
        L20_2 = 0
        L21_2 = 9
        L19_2 = L19_2(L20_2, L21_2)
        L20_2 = math
        L20_2 = L20_2.random
        L21_2 = 0
        L22_2 = 9
        L20_2 = L20_2(L21_2, L22_2)
        L21_2 = math
        L21_2 = L21_2.random
        L22_2 = 0
        L23_2 = 9
        L21_2 = L21_2(L22_2, L23_2)
        L14_2 = L14_2 .. L15_2 .. L16_2 .. L17_2 .. L18_2 .. L19_2 .. L20_2 .. L21_2
        L13_2 = L13_2(L14_2)
        L12_2.serial = L13_2
      end
      L12_2 = ActiveIncentories
      L12_2 = L12_2[A0_2]
      L12_2 = L12_2.content
      L12_2 = L12_2[L8_2]
      L12_2 = L12_2.category
      if "weapons" == L12_2 then
        L12_2 = ActiveIncentories
        L12_2 = L12_2[A0_2]
        L12_2 = L12_2.content
        L12_2 = L12_2[L8_2]
        L12_2 = L12_2.metadata
        L13_2 = {}
        L12_2.attachments = L13_2
        L12_2 = ActiveIncentories
        L12_2 = L12_2[A0_2]
        L12_2 = L12_2.content
        L12_2 = L12_2[L8_2]
        L12_2 = L12_2.metadata
        L12_2.ammo = 0
        L12_2 = ActiveIncentories
        L12_2 = L12_2[A0_2]
        L12_2 = L12_2.content
        L12_2 = L12_2[L8_2]
        L12_2 = L12_2.metadata
        L12_2.aquired = A0_2
      end
      L12_2 = saveInventory
      L13_2 = A0_2
      L12_2(L13_2)
      L12_2 = pairs
      L13_2 = ActiveIncentories
      L13_2 = L13_2[A0_2]
      L13_2 = L13_2.spectators
      L12_2, L13_2, L14_2, L15_2 = L12_2(L13_2)
      for L16_2, L17_2 in L12_2, L13_2, L14_2, L15_2 do
        if L17_2 then
          L18_2 = TriggerClientEvent
          L19_2 = "core_inventory:client:sync"
          L20_2 = L16_2
          L21_2 = A0_2
          L22_2 = ActiveIncentories
          L22_2 = L22_2[A0_2]
          L18_2(L19_2, L20_2, L21_2, L22_2)
        end
      end
    end
  end
  L4_2 = pairs
  L5_2 = L3_2
  L4_2, L5_2, L6_2, L7_2 = L4_2(L5_2)
  for L8_2, L9_2 in L4_2, L5_2, L6_2, L7_2 do
    L10_2 = removeItemExact
    L11_2 = A0_2
    L12_2 = L8_2
    L10_2(L11_2, L12_2)
  end
  L4_2 = true
  return L4_2
end
canCarry = L0_1
function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2
  L4_2 = {}
  L5_2 = Items
  L5_2 = L5_2[A1_2]
  if not L5_2 then
    return
  end
  L6_2 = L5_2.category
  if not L6_2 then
    L6_2 = "misc"
  end
  L7_2 = A2_2
  L8_2 = Config
  L8_2 = L8_2.ItemCategories
  L8_2 = L8_2[L6_2]
  L8_2 = L8_2.stack
  if L8_2 then
    L8_2 = math
    L8_2 = L8_2.floor
    L9_2 = Config
    L9_2 = L9_2.ItemCategories
    L9_2 = L9_2[L6_2]
    L9_2 = L9_2.stack
    L9_2 = A2_2 / L9_2
    L9_2 = L9_2 + 0.5
    L8_2 = L8_2(L9_2)
    A2_2 = L8_2
    if 0 == A2_2 then
      A2_2 = 1
    end
  end
  L8_2 = 1
  L9_2 = A2_2
  L10_2 = 1
  for L11_2 = L8_2, L9_2, L10_2 do
    L12_2 = A1_2
    L13_2 = "-"
    L14_2 = math
    L14_2 = L14_2.random
    L15_2 = 0
    L16_2 = 99999
    L14_2 = L14_2(L15_2, L16_2)
    L12_2 = L12_2 .. L13_2 .. L14_2
    if not L5_2 then
      L13_2 = DynamicItems
      L13_2 = L13_2[A1_2]
      if L13_2 then
        L13_2 = DynamicItems
        L5_2 = L13_2[A1_2]
      end
    end
    L13_2 = ActiveIncentories
    L13_2 = L13_2[A0_2]
    if L13_2 and L5_2 then
      L13_2 = L5_2.x
      if not L13_2 then
        L13_2 = Config
        L13_2 = L13_2.DefaultItemSizeX
      end
      L5_2.x = L13_2
      L13_2 = L5_2.y
      if not L13_2 then
        L13_2 = Config
        L13_2 = L13_2.DefaultItemSizeY
      end
      L5_2.y = L13_2
      L13_2 = getAvailableSlot
      L14_2 = A0_2
      L15_2 = L5_2
      L13_2 = L13_2(L14_2, L15_2)
      L14_2 = ActiveIncentories
      L14_2 = L14_2[A0_2]
      L14_2 = L14_2.content
      L15_2 = {}
      L16_2 = L5_2.x
      if not L16_2 then
        L16_2 = 1
      end
      L15_2.x = L16_2
      L16_2 = L5_2.y
      if not L16_2 then
        L16_2 = 1
      end
      L15_2.y = L16_2
      L15_2.slot = 0
      L15_2.id = L12_2
      L15_2.name = A1_2
      L15_2.flipped = 0
      L16_2 = L6_2 or L16_2
      if not L6_2 then
        L16_2 = "misc"
      end
      L15_2.category = L16_2
      L16_2 = A3_2 or L16_2
      if not A3_2 then
        L16_2 = {}
      end
      L15_2.metadata = L16_2
      L14_2[L12_2] = L15_2
      if nil == L13_2 then
        L14_2 = sendTextMessage
        L15_2 = Config
        L15_2 = L15_2.Text
        L15_2 = L15_2.no_space
        L14_2(L15_2)
        L14_2 = ActiveIncentories
        L14_2 = L14_2[A0_2]
        L14_2 = L14_2.content
        L14_2[L12_2] = nil
        L14_2 = pairs
        L15_2 = L4_2
        L14_2, L15_2, L16_2, L17_2 = L14_2(L15_2)
        for L18_2, L19_2 in L14_2, L15_2, L16_2, L17_2 do
          L20_2 = removeItemExact
          L21_2 = A0_2
          L22_2 = L18_2
          L20_2(L21_2, L22_2)
        end
        L14_2 = false
        return L14_2
      else
        L4_2[L12_2] = true
        L14_2 = ActiveIncentories
        L14_2 = L14_2[A0_2]
        L14_2 = L14_2.content
        L14_2 = L14_2[L12_2]
        L14_2.slot = L13_2
      end
      L14_2 = Config
      L14_2 = L14_2.ItemCategories
      L14_2 = L14_2[L6_2]
      L14_2 = L14_2.stack
      if L14_2 then
        L14_2 = Config
        L14_2 = L14_2.ItemCategories
        L14_2 = L14_2[L6_2]
        L14_2 = L14_2.stack
        if L7_2 >= L14_2 then
          L14_2 = ActiveIncentories
          L14_2 = L14_2[A0_2]
          L14_2 = L14_2.content
          L14_2 = L14_2[L12_2]
          L15_2 = Config
          L15_2 = L15_2.ItemCategories
          L15_2 = L15_2[L6_2]
          L15_2 = L15_2.stack
          L14_2.amount = L15_2
          L14_2 = Config
          L14_2 = L14_2.ItemCategories
          L14_2 = L14_2[L6_2]
          L14_2 = L14_2.stack
          L7_2 = L7_2 - L14_2
        else
          L14_2 = ActiveIncentories
          L14_2 = L14_2[A0_2]
          L14_2 = L14_2.content
          L14_2 = L14_2[L12_2]
          L14_2.amount = L7_2
          L7_2 = 0
        end
      end
      L14_2 = L5_2.componentHash
      if L14_2 then
        L14_2 = ActiveIncentories
        L14_2 = L14_2[A0_2]
        L14_2 = L14_2.content
        L14_2 = L14_2[L12_2]
        L15_2 = L5_2.componentHash
        L14_2.componentHash = L15_2
      end
      L14_2 = L5_2.componentTint
      if L14_2 then
        L14_2 = ActiveIncentories
        L14_2 = L14_2[A0_2]
        L14_2 = L14_2.content
        L14_2 = L14_2[L12_2]
        L15_2 = L5_2.componentTint
        L14_2.componentTint = L15_2
      end
      L14_2 = L5_2.backpackModel
      if L14_2 then
        L14_2 = ActiveIncentories
        L14_2 = L14_2[A0_2]
        L14_2 = L14_2.content
        L14_2 = L14_2[L12_2]
        L15_2 = L5_2.backpackModel
        L14_2.backpackModel = L15_2
        L14_2 = ActiveIncentories
        L14_2 = L14_2[A0_2]
        L14_2 = L14_2.content
        L14_2 = L14_2[L12_2]
        L15_2 = L5_2.backpackTexture
        if not L15_2 then
          L15_2 = 1
        end
        L14_2.backpackTexture = L15_2
      end
      L14_2 = Config
      L14_2 = L14_2.ItemCategories
      L14_2 = L14_2[L6_2]
      L14_2 = L14_2.durability
      if L14_2 then
        L14_2 = ActiveIncentories
        L14_2 = L14_2[A0_2]
        L14_2 = L14_2.content
        L14_2 = L14_2[L12_2]
        L14_2 = L14_2.metadata
        L15_2 = Config
        L15_2 = L15_2.DefaultDurability
        L14_2.durability = L15_2
      end
      L14_2 = Config
      L14_2 = L14_2.ItemCategories
      L14_2 = L14_2[L6_2]
      L14_2 = L14_2.serial
      if L14_2 then
        L14_2 = ActiveIncentories
        L14_2 = L14_2[A0_2]
        L14_2 = L14_2.content
        L14_2 = L14_2[L12_2]
        L14_2 = L14_2.metadata
        L15_2 = string
        L15_2 = L15_2.upper
        L16_2 = string
        L16_2 = L16_2.char
        L17_2 = math
        L17_2 = L17_2.random
        L18_2 = 97
        L19_2 = 122
        L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2 = L17_2(L18_2, L19_2)
        L16_2 = L16_2(L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2)
        L17_2 = string
        L17_2 = L17_2.char
        L18_2 = math
        L18_2 = L18_2.random
        L19_2 = 97
        L20_2 = 122
        L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2 = L18_2(L19_2, L20_2)
        L17_2 = L17_2(L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2)
        L18_2 = math
        L18_2 = L18_2.random
        L19_2 = 0
        L20_2 = 9
        L18_2 = L18_2(L19_2, L20_2)
        L19_2 = math
        L19_2 = L19_2.random
        L20_2 = 0
        L21_2 = 9
        L19_2 = L19_2(L20_2, L21_2)
        L20_2 = math
        L20_2 = L20_2.random
        L21_2 = 0
        L22_2 = 9
        L20_2 = L20_2(L21_2, L22_2)
        L21_2 = math
        L21_2 = L21_2.random
        L22_2 = 0
        L23_2 = 9
        L21_2 = L21_2(L22_2, L23_2)
        L22_2 = math
        L22_2 = L22_2.random
        L23_2 = 0
        L24_2 = 9
        L22_2 = L22_2(L23_2, L24_2)
        L23_2 = math
        L23_2 = L23_2.random
        L24_2 = 0
        L25_2 = 9
        L23_2 = L23_2(L24_2, L25_2)
        L16_2 = L16_2 .. L17_2 .. L18_2 .. L19_2 .. L20_2 .. L21_2 .. L22_2 .. L23_2
        L15_2 = L15_2(L16_2)
        L14_2.serial = L15_2
      end
      L14_2 = ActiveIncentories
      L14_2 = L14_2[A0_2]
      L14_2 = L14_2.content
      L14_2 = L14_2[L12_2]
      L14_2 = L14_2.category
      if "weapons" == L14_2 then
        L14_2 = ActiveIncentories
        L14_2 = L14_2[A0_2]
        L14_2 = L14_2.content
        L14_2 = L14_2[L12_2]
        L14_2 = L14_2.metadata
        L15_2 = {}
        L14_2.attachments = L15_2
        L14_2 = ActiveIncentories
        L14_2 = L14_2[A0_2]
        L14_2 = L14_2.content
        L14_2 = L14_2[L12_2]
        L14_2 = L14_2.metadata
        L14_2.ammo = 0
        L14_2 = ActiveIncentories
        L14_2 = L14_2[A0_2]
        L14_2 = L14_2.content
        L14_2 = L14_2[L12_2]
        L14_2 = L14_2.metadata
        L14_2.aquired = A0_2
      end
      L14_2 = saveInventory
      L15_2 = A0_2
      L14_2(L15_2)
      L14_2 = pairs
      L15_2 = ActiveIncentories
      L15_2 = L15_2[A0_2]
      L15_2 = L15_2.spectators
      L14_2, L15_2, L16_2, L17_2 = L14_2(L15_2)
      for L18_2, L19_2 in L14_2, L15_2, L16_2, L17_2 do
        if L19_2 then
          L20_2 = TriggerClientEvent
          L21_2 = "core_inventory:client:sync"
          L22_2 = L18_2
          L23_2 = A0_2
          L24_2 = ActiveIncentories
          L24_2 = L24_2[A0_2]
          L20_2(L21_2, L22_2, L23_2, L24_2)
        end
      end
    end
  end
  L8_2 = true
  return L8_2
end
addItem = L0_1
function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L1_2 = ActiveIncentories
  L1_2 = L1_2[A0_2]
  if L1_2 then
    L1_2 = ActiveIncentories
    L1_2 = L1_2[A0_2]
    L2_2 = {}
    L1_2.content = L2_2
    L1_2 = saveInventory
    L2_2 = A0_2
    L1_2(L2_2)
    L1_2 = pairs
    L2_2 = ActiveIncentories
    L2_2 = L2_2[A0_2]
    L2_2 = L2_2.spectators
    L1_2, L2_2, L3_2, L4_2 = L1_2(L2_2)
    for L5_2, L6_2 in L1_2, L2_2, L3_2, L4_2 do
      if L6_2 then
        L7_2 = TriggerClientEvent
        L8_2 = "core_inventory:client:sync"
        L9_2 = L5_2
        L10_2 = A0_2
        L11_2 = ActiveIncentories
        L11_2 = L11_2[A0_2]
        L7_2(L8_2, L9_2, L10_2, L11_2)
      end
    end
  end
end
clearInventory = L0_1
function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  if A2_2 then
    L3_2 = ActiveIncentories
    L3_2 = L3_2[A0_2]
    L3_2 = L3_2.content
    L3_2 = L3_2[A1_2]
    L3_2 = L3_2.amount
    if A2_2 < L3_2 then
      L3_2 = ActiveIncentories
      L3_2 = L3_2[A0_2]
      L3_2 = L3_2.content
      L3_2 = L3_2[A1_2]
      L4_2 = ActiveIncentories
      L4_2 = L4_2[A0_2]
      L4_2 = L4_2.content
      L4_2 = L4_2[A1_2]
      L4_2 = L4_2.amount
      L4_2 = L4_2 - A2_2
      L3_2.amount = L4_2
    else
      L3_2 = ActiveIncentories
      L3_2 = L3_2[A0_2]
      L3_2 = L3_2.content
      L3_2[A1_2] = nil
    end
  else
    L3_2 = ActiveIncentories
    L3_2 = L3_2[A0_2]
    L3_2 = L3_2.content
    L3_2[A1_2] = nil
  end
  L3_2 = saveInventory
  L4_2 = A0_2
  L3_2(L4_2)
  L3_2 = pairs
  L4_2 = ActiveIncentories
  L4_2 = L4_2[A0_2]
  L4_2 = L4_2.spectators
  L3_2, L4_2, L5_2, L6_2 = L3_2(L4_2)
  for L7_2, L8_2 in L3_2, L4_2, L5_2, L6_2 do
    if L8_2 then
      L9_2 = TriggerClientEvent
      L10_2 = "core_inventory:client:sync"
      L11_2 = L7_2
      L12_2 = A0_2
      L13_2 = ActiveIncentories
      L13_2 = L13_2[A0_2]
      L9_2(L10_2, L11_2, L12_2, L13_2)
    end
  end
end
removeItemExact = L0_1
function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2
  if 1 == A2_2 then
    L3_2 = UsedItems
    L3_2 = L3_2[A0_2]
    if L3_2 then
      L3_2 = ActiveIncentories
      L3_2 = L3_2[A0_2]
      L3_2 = L3_2.content
      L4_2 = UsedItems
      L4_2 = L4_2[A0_2]
      L3_2 = L3_2[L4_2]
      if L3_2 then
        L3_2 = ActiveIncentories
        L3_2 = L3_2[A0_2]
        L3_2 = L3_2.content
        L4_2 = UsedItems
        L4_2 = L4_2[A0_2]
        L3_2 = L3_2[L4_2]
        L3_2 = L3_2.name
        if L3_2 == A1_2 then
          L3_2 = removeItemExact
          L4_2 = A0_2
          L5_2 = UsedItems
          L5_2 = L5_2[A0_2]
          L6_2 = 1
          L3_2(L4_2, L5_2, L6_2)
          L3_2 = UsedItems
          L3_2[A0_2] = nil
          L3_2 = true
          return L3_2
        end
      end
    end
  end
  L3_2 = A2_2
  L4_2 = 1
  L5_2 = A2_2
  L6_2 = 1
  for L7_2 = L4_2, L5_2, L6_2 do
    if 0 == L3_2 then
      break
    end
    L8_2 = Items
    L8_2 = L8_2[A1_2]
    L9_2 = L8_2.category
    if not L9_2 then
      L9_2 = "misc"
    end
    L10_2 = ActiveIncentories
    L10_2 = L10_2[A0_2]
    if L10_2 then
      L10_2 = false
      L11_2 = pairs
      L12_2 = ActiveIncentories
      L12_2 = L12_2[A0_2]
      L12_2 = L12_2.content
      L11_2, L12_2, L13_2, L14_2 = L11_2(L12_2)
      for L15_2, L16_2 in L11_2, L12_2, L13_2, L14_2 do
        L17_2 = L16_2.name
        if L17_2 == A1_2 then
          L17_2 = L16_2.metadata
          L18_2 = {}
          if L17_2 == L18_2 then
            L10_2 = true
            L17_2 = Config
            L17_2 = L17_2.ItemCategories
            L17_2 = L17_2[L9_2]
            L17_2 = L17_2.stack
            if L17_2 then
              L17_2 = ActiveIncentories
              L17_2 = L17_2[A0_2]
              L17_2 = L17_2.content
              L17_2 = L17_2[L15_2]
              L17_2 = L17_2.amount
              if L3_2 < L17_2 then
                L17_2 = ActiveIncentories
                L17_2 = L17_2[A0_2]
                L17_2 = L17_2.content
                L17_2 = L17_2[L15_2]
                L18_2 = ActiveIncentories
                L18_2 = L18_2[A0_2]
                L18_2 = L18_2.content
                L18_2 = L18_2[L15_2]
                L18_2 = L18_2.amount
                L18_2 = L18_2 - L3_2
                L17_2.amount = L18_2
                L3_2 = 0
              else
                L17_2 = ActiveIncentories
                L17_2 = L17_2[A0_2]
                L17_2 = L17_2.content
                L17_2 = L17_2[L15_2]
                L17_2 = L17_2.amount
                L3_2 = L3_2 - L17_2
                L17_2 = ActiveIncentories
                L17_2 = L17_2[A0_2]
                L17_2 = L17_2.content
                L17_2[L15_2] = nil
              end
            else
              L17_2 = ActiveIncentories
              L17_2 = L17_2[A0_2]
              L17_2 = L17_2.content
              L17_2[L15_2] = nil
            end
            L17_2 = saveInventory
            L18_2 = A0_2
            L17_2(L18_2)
            L17_2 = pairs
            L18_2 = ActiveIncentories
            L18_2 = L18_2[A0_2]
            L18_2 = L18_2.spectators
            L17_2, L18_2, L19_2, L20_2 = L17_2(L18_2)
            for L21_2, L22_2 in L17_2, L18_2, L19_2, L20_2 do
              if L22_2 then
                L23_2 = TriggerClientEvent
                L24_2 = "core_inventory:client:sync"
                L25_2 = L21_2
                L26_2 = A0_2
                L27_2 = ActiveIncentories
                L27_2 = L27_2[A0_2]
                L23_2(L24_2, L25_2, L26_2, L27_2)
              end
            end
            break
          end
        end
      end
      if not L10_2 then
        L11_2 = pairs
        L12_2 = ActiveIncentories
        L12_2 = L12_2[A0_2]
        L12_2 = L12_2.content
        L11_2, L12_2, L13_2, L14_2 = L11_2(L12_2)
        for L15_2, L16_2 in L11_2, L12_2, L13_2, L14_2 do
          L17_2 = L16_2.name
          if L17_2 == A1_2 then
            L10_2 = true
            L17_2 = Config
            L17_2 = L17_2.ItemCategories
            L17_2 = L17_2[L9_2]
            L17_2 = L17_2.stack
            if L17_2 then
              L17_2 = ActiveIncentories
              L17_2 = L17_2[A0_2]
              L17_2 = L17_2.content
              L17_2 = L17_2[L15_2]
              L17_2 = L17_2.amount
              if L3_2 < L17_2 then
                L17_2 = ActiveIncentories
                L17_2 = L17_2[A0_2]
                L17_2 = L17_2.content
                L17_2 = L17_2[L15_2]
                L18_2 = ActiveIncentories
                L18_2 = L18_2[A0_2]
                L18_2 = L18_2.content
                L18_2 = L18_2[L15_2]
                L18_2 = L18_2.amount
                L18_2 = L18_2 - L3_2
                L17_2.amount = L18_2
                L3_2 = 0
              else
                L17_2 = ActiveIncentories
                L17_2 = L17_2[A0_2]
                L17_2 = L17_2.content
                L17_2 = L17_2[L15_2]
                L17_2 = L17_2.amount
                L3_2 = L3_2 - L17_2
                L17_2 = ActiveIncentories
                L17_2 = L17_2[A0_2]
                L17_2 = L17_2.content
                L17_2[L15_2] = nil
              end
            else
              L17_2 = ActiveIncentories
              L17_2 = L17_2[A0_2]
              L17_2 = L17_2.content
              L17_2[L15_2] = nil
            end
            L17_2 = saveInventory
            L18_2 = A0_2
            L17_2(L18_2)
            L17_2 = pairs
            L18_2 = ActiveIncentories
            L18_2 = L18_2[A0_2]
            L18_2 = L18_2.spectators
            L17_2, L18_2, L19_2, L20_2 = L17_2(L18_2)
            for L21_2, L22_2 in L17_2, L18_2, L19_2, L20_2 do
              if L22_2 then
                L23_2 = TriggerClientEvent
                L24_2 = "core_inventory:client:sync"
                L25_2 = L21_2
                L26_2 = A0_2
                L27_2 = ActiveIncentories
                L27_2 = L27_2[A0_2]
                L23_2(L24_2, L25_2, L26_2, L27_2)
              end
            end
            break
          end
        end
      end
      if not L10_2 then
        L11_2 = sendTextMessage
        L12_2 = Config
        L12_2 = L12_2.Text
        L12_2 = L12_2.no_such_item
        L11_2(L12_2)
        L11_2 = false
        return L11_2
      end
    end
  end
  L4_2 = true
  return L4_2
end
removeItem = L0_1
function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L2_2 = ActiveIncentories
  L2_2 = L2_2[A1_2]
  if L2_2 then
    L2_2 = ActiveIncentories
    L2_2 = L2_2[A1_2]
    L2_2 = L2_2.spectators
    L2_2[A0_2] = true
    L2_2 = TriggerClientEvent
    L3_2 = "core_inventory:client:openHolder"
    L4_2 = A0_2
    L5_2 = ActiveIncentories
    L5_2 = L5_2[A1_2]
    L5_2 = L5_2.name
    L6_2 = ActiveIncentories
    L6_2 = L6_2[A1_2]
    L6_2 = L6_2.slots
    L7_2 = ActiveIncentories
    L7_2 = L7_2[A1_2]
    L7_2 = L7_2.rows
    L8_2 = ActiveIncentories
    L8_2 = L8_2[A1_2]
    L8_2 = L8_2.content
    L9_2 = ActiveIncentories
    L9_2 = L9_2[A1_2]
    L9_2 = L9_2.label
    L10_2 = ActiveIncentories
    L10_2 = L10_2[A1_2]
    L10_2 = L10_2.x
    L11_2 = ActiveIncentories
    L11_2 = L11_2[A1_2]
    L11_2 = L11_2.y
    L12_2 = ActiveIncentories
    L12_2 = L12_2[A1_2]
    L12_2 = L12_2.restrictedTo
    L13_2 = ActiveIncentories
    L13_2 = L13_2[A1_2]
    L13_2 = L13_2.hidden
    L14_2 = ActiveIncentories
    L14_2 = L14_2[A1_2]
    L14_2 = L14_2.type
    L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2)
  end
end
openHolder = L0_1
function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L2_2 = ActiveIncentories
  L2_2 = L2_2[A1_2]
  if L2_2 then
    L2_2 = ActiveIncentories
    L2_2 = L2_2[A1_2]
    L2_2 = L2_2.spectators
    L2_2[A0_2] = true
    L2_2 = TriggerClientEvent
    L3_2 = "core_inventory:client:openInventory"
    L4_2 = A0_2
    L5_2 = ActiveIncentories
    L5_2 = L5_2[A1_2]
    L5_2 = L5_2.name
    L6_2 = ActiveIncentories
    L6_2 = L6_2[A1_2]
    L6_2 = L6_2.slots
    L7_2 = ActiveIncentories
    L7_2 = L7_2[A1_2]
    L7_2 = L7_2.rows
    L8_2 = ActiveIncentories
    L8_2 = L8_2[A1_2]
    L8_2 = L8_2.content
    L9_2 = ActiveIncentories
    L9_2 = L9_2[A1_2]
    L9_2 = L9_2.label
    L10_2 = ActiveIncentories
    L10_2 = L10_2[A1_2]
    L10_2 = L10_2.x
    L11_2 = ActiveIncentories
    L11_2 = L11_2[A1_2]
    L11_2 = L11_2.y
    L12_2 = ActiveIncentories
    L12_2 = L12_2[A1_2]
    L12_2 = L12_2.hidden
    L13_2 = ActiveIncentories
    L13_2 = L13_2[A1_2]
    L13_2 = L13_2.type
    L14_2 = ActiveIncentories
    L14_2 = L14_2[A1_2]
    L14_2 = L14_2.restrictedTo
    L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2)
  end
end
openInventory = L0_1
function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = ActiveIncentories
  L1_2 = L1_2[A0_2]
  if not L1_2 then
    return
  end
  L1_2 = exports
  L1_2 = L1_2.oxmysql
  L2_2 = L1_2
  L1_2 = L1_2.update
  L3_2 = "DELETE FROM coreinventories WHERE name = :inventory"
  L4_2 = {}
  L4_2.inventory = A0_2
  function L5_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3
    L0_3 = next
    L1_3 = ActiveIncentories
    L2_3 = A0_2
    L1_3 = L1_3[L2_3]
    L1_3 = L1_3.content
    L0_3 = L0_3(L1_3)
    if nil ~= L0_3 then
      L0_3 = ActiveIncentories
      L1_3 = A0_2
      L0_3 = L0_3[L1_3]
      L0_3 = L0_3.type
      if nil ~= L0_3 then
        goto lbl_25
      end
    end
    L0_3 = Config
    L0_3 = L0_3.Inventories
    L1_3 = ActiveIncentories
    L2_3 = A0_2
    L1_3 = L1_3[L2_3]
    L1_3 = L1_3.type
    L0_3 = L0_3[L1_3]
    L0_3 = L0_3.alwaysSave
    ::lbl_25::
    if L0_3 then
      L0_3 = exports
      L0_3 = L0_3.oxmysql
      L1_3 = L0_3
      L0_3 = L0_3.update
      L2_3 = "REPLACE INTO coreinventories (name, data) values(:inventory, :data)"
      L3_3 = {}
      L4_3 = A0_2
      L3_3.inventory = L4_3
      L4_3 = json
      L4_3 = L4_3.encode
      L5_3 = ActiveIncentories
      L6_3 = A0_2
      L5_3 = L5_3[L6_3]
      L4_3 = L4_3(L5_3)
      L3_3.data = L4_3
      function L4_3()
        local L0_4, L1_4
      end
      L0_3(L1_3, L2_3, L3_3, L4_3)
    end
  end
  L1_2(L2_2, L3_2, L4_2, L5_2)
end
saveInventory = L0_1
function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = A0_2
  L3_2 = L1_2
  L2_2 = L1_2.gsub
  L4_2 = " "
  L5_2 = ""
  L2_2 = L2_2(L3_2, L4_2, L5_2)
  L1_2 = L2_2
  return L1_2
end
fixNaming = L0_1
function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2, A6_2)
  local L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2
  L7_2 = Config
  L7_2 = L7_2.Inventories
  L7_2 = L7_2[A2_2]
  L8_2 = fixNaming
  L9_2 = A1_2
  L8_2 = L8_2(L9_2)
  A1_2 = L8_2
  if nil == L7_2 then
    L8_2 = print
    L9_2 = "[Core Inventory] Holder type not found! (Create type "
    L10_2 = A2_2
    L11_2 = " in Config)"
    L9_2 = L9_2 .. L10_2 .. L11_2
    L8_2(L9_2)
    return
  end
  if nil == A3_2 or nil == A4_2 then
    L8_2 = L7_2.x
    A3_2 = L8_2 or A3_2
    if not L8_2 then
      A3_2 = 1
    end
    L8_2 = L7_2.y
    A4_2 = L8_2 or A4_2
    if not L8_2 then
      A4_2 = 1
    end
  end
  L8_2 = ActiveIncentories
  L8_2 = L8_2[A1_2]
  if not L8_2 then
    L8_2 = exports
    L8_2 = L8_2.oxmysql
    L9_2 = L8_2
    L8_2 = L8_2.query
    L10_2 = "SELECT data FROM coreinventories WHERE name = :name"
    L11_2 = {}
    L11_2.name = A1_2
    function L12_2(A0_3)
      local L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3, L12_3, L13_3
      L1_3 = nil
      L2_3 = A0_3[1]
      if nil == L2_3 then
        L2_3 = {}
        L3_3 = A6_2
        if not L3_3 then
          L3_3 = {}
        end
        L2_3.content = L3_3
        L3_3 = A3_2
        L2_3.x = L3_3
        L3_3 = A4_2
        L2_3.y = L3_3
        L2_3.hidden = false
        L1_3 = L2_3
      else
        L2_3 = json
        L2_3 = L2_3.decode
        L3_3 = A0_3[1]
        L3_3 = L3_3.data
        L2_3 = L2_3(L3_3)
        L1_3 = L2_3
      end
      L2_3 = ActiveIncentories
      L3_3 = A1_2
      L4_3 = {}
      L5_3 = L1_3.content
      if not L5_3 then
        L5_3 = {}
      end
      L4_3.content = L5_3
      L5_3 = {}
      L4_3.spectators = L5_3
      L5_3 = L1_3.hidden
      if not L5_3 then
        L5_3 = false
      end
      L4_3.hidden = L5_3
      L5_3 = A2_2
      L4_3.type = L5_3
      L5_3 = L7_2.restrictedTo
      if not L5_3 then
        L5_3 = nil
      end
      L4_3.restrictedTo = L5_3
      L5_3 = L7_2.slots
      L4_3.slots = L5_3
      L5_3 = L7_2.rows
      L4_3.rows = L5_3
      L5_3 = A1_2
      L4_3.name = L5_3
      L5_3 = L7_2.label
      L4_3.label = L5_3
      L5_3 = L1_3.x
      L4_3.x = L5_3
      L5_3 = L1_3.y
      L4_3.y = L5_3
      L2_3[L3_3] = L4_3
      L2_3 = false
      L3_3 = pairs
      L4_3 = ActiveIncentories
      L5_3 = A1_2
      L4_3 = L4_3[L5_3]
      L4_3 = L4_3.content
      L3_3, L4_3, L5_3, L6_3 = L3_3(L4_3)
      for L7_3, L8_3 in L3_3, L4_3, L5_3, L6_3 do
        L2_3 = true
        L9_3 = TriggerClientEvent
        L10_3 = "core_inventory:client:holderData"
        L11_3 = A0_2
        L12_3 = A1_2
        L13_3 = L8_3
        L9_3(L10_3, L11_3, L12_3, L13_3)
      end
      if not L2_3 then
        L3_3 = TriggerClientEvent
        L4_3 = "core_inventory:client:holderData"
        L5_3 = A0_2
        L6_3 = A1_2
        L7_3 = nil
        L3_3(L4_3, L5_3, L6_3, L7_3)
      end
      L3_3 = A5_2
      if L3_3 then
        L3_3 = openHolder
        L4_3 = A0_2
        L5_3 = A1_2
        L3_3(L4_3, L5_3)
      end
    end
    L8_2(L9_2, L10_2, L11_2, L12_2)
  else
    if A5_2 then
      L8_2 = openHolder
      L9_2 = A0_2
      L10_2 = A1_2
      L8_2(L9_2, L10_2)
    end
    L8_2 = false
    L9_2 = pairs
    L10_2 = ActiveIncentories
    L10_2 = L10_2[A1_2]
    L10_2 = L10_2.content
    L9_2, L10_2, L11_2, L12_2 = L9_2(L10_2)
    for L13_2, L14_2 in L9_2, L10_2, L11_2, L12_2 do
      L8_2 = true
      L15_2 = TriggerClientEvent
      L16_2 = "core_inventory:client:holderData"
      L17_2 = A0_2
      L18_2 = A1_2
      L19_2 = L14_2
      L15_2(L16_2, L17_2, L18_2, L19_2)
    end
    if not L8_2 then
      L9_2 = TriggerClientEvent
      L10_2 = "core_inventory:client:holderData"
      L11_2 = A0_2
      L12_2 = A1_2
      L13_2 = nil
      L9_2(L10_2, L11_2, L12_2, L13_2)
    end
  end
end
preopenHolder = L0_1
function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2, A6_2)
  local L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L7_2 = Config
  L7_2 = L7_2.Inventories
  L7_2 = L7_2[A2_2]
  L8_2 = fixNaming
  L9_2 = A1_2
  L8_2 = L8_2(L9_2)
  A1_2 = L8_2
  if nil == L7_2 then
    L8_2 = print
    L9_2 = "[Core Inventory] Inventory type not found! (Create type "
    L10_2 = A2_2
    L11_2 = " in Config)"
    L9_2 = L9_2 .. L10_2 .. L11_2
    L8_2(L9_2)
    return
  end
  if nil == A3_2 or nil == A4_2 then
    L8_2 = L7_2.x
    A3_2 = L8_2 or A3_2
    if not L8_2 then
      A3_2 = 1
    end
    L8_2 = L7_2.y
    A4_2 = L8_2 or A4_2
    if not L8_2 then
      A4_2 = 1
    end
  end
  L8_2 = ActiveIncentories
  L8_2 = L8_2[A1_2]
  if not L8_2 then
    L8_2 = exports
    L8_2 = L8_2.oxmysql
    L9_2 = L8_2
    L8_2 = L8_2.query
    L10_2 = "SELECT data FROM coreinventories WHERE name = :name"
    L11_2 = {}
    L11_2.name = A1_2
    function L12_2(A0_3)
      local L1_3, L2_3, L3_3, L4_3, L5_3, L6_3
      L1_3 = nil
      L2_3 = false
      L3_3 = A0_3[1]
      if nil == L3_3 then
        L3_3 = {}
        L4_3 = A6_2
        if not L4_3 then
          L4_3 = {}
        end
        L3_3.content = L4_3
        L4_3 = A3_2
        L3_3.x = L4_3
        L4_3 = A4_2
        L3_3.y = L4_3
        L3_3.hidden = false
        L1_3 = L3_3
        L2_3 = true
      else
        L3_3 = json
        L3_3 = L3_3.decode
        L4_3 = A0_3[1]
        L4_3 = L4_3.data
        L3_3 = L3_3(L4_3)
        L1_3 = L3_3
      end
      L3_3 = ActiveIncentories
      L4_3 = A1_2
      L5_3 = {}
      L6_3 = L1_3.content
      if not L6_3 then
        L6_3 = {}
      end
      L5_3.content = L6_3
      L6_3 = {}
      L5_3.spectators = L6_3
      L6_3 = L1_3.hidden
      if not L6_3 then
        L6_3 = false
      end
      L5_3.hidden = L6_3
      L6_3 = L7_2.restrictedTo
      if not L6_3 then
        L6_3 = nil
      end
      L5_3.restrictedTo = L6_3
      L6_3 = A2_2
      L5_3.type = L6_3
      L6_3 = L7_2.slots
      L5_3.slots = L6_3
      L6_3 = L7_2.rows
      L5_3.rows = L6_3
      L6_3 = A1_2
      L5_3.name = L6_3
      L6_3 = L7_2.label
      L5_3.label = L6_3
      L6_3 = L1_3.x
      L5_3.x = L6_3
      L6_3 = L1_3.y
      L5_3.y = L6_3
      L3_3[L4_3] = L5_3
      L3_3 = A5_2
      if L3_3 then
        L3_3 = openInventory
        L4_3 = A0_2
        L5_3 = A1_2
        L3_3(L4_3, L5_3)
      end
      if L2_3 then
        L3_3 = A2_2
        if "content" == L3_3 then
          L3_3 = firstInventory
          L4_3 = A1_2
          L5_3 = A0_2
          L3_3(L4_3, L5_3)
        end
      end
    end
    L8_2(L9_2, L10_2, L11_2, L12_2)
  elseif A5_2 then
    L8_2 = openInventory
    L9_2 = A0_2
    L10_2 = A1_2
    L8_2(L9_2, L10_2)
  end
end
preopenInventory = L0_1
L0_1 = RegisterServerEvent
L1_1 = "core_inventory:server:openLoot"
L0_1(L1_1)
L0_1 = AddEventHandler
L1_1 = "core_inventory:server:openLoot"
function L2_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L4_2 = source
  L5_2 = openLoot
  L6_2 = L4_2
  L7_2 = A0_2
  L8_2 = A1_2
  L9_2 = A2_2
  L10_2 = A3_2
  L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
end
L0_1(L1_1, L2_1)
L0_1 = RegisterServerEvent
L1_1 = "core_inventory:server:removeThrowable"
L0_1(L1_1)
L0_1 = AddEventHandler
L1_1 = "core_inventory:server:removeThrowable"
function L2_1(A0_2)
  local L1_2, L2_2
  L1_2 = clearInventory
  L2_2 = A0_2
  L1_2(L2_2)
end
L0_1(L1_1, L2_1)
function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L1_2 = type
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if "table" ~= L1_2 then
    return A0_2
  end
  L1_2 = {}
  L2_2 = pairs
  L3_2 = A0_2
  L2_2, L3_2, L4_2, L5_2 = L2_2(L3_2)
  for L6_2, L7_2 in L2_2, L3_2, L4_2, L5_2 do
    L8_2 = copy
    L9_2 = L6_2
    L8_2 = L8_2(L9_2)
    L9_2 = copy
    L10_2 = L7_2
    L9_2 = L9_2(L10_2)
    L1_2[L8_2] = L9_2
  end
  return L1_2
end
copy = L0_1
L0_1 = RegisterServerEvent
L1_1 = "core_inventory:server:splitItems"
L0_1(L1_1)
L0_1 = AddEventHandler
L1_1 = "core_inventory:server:splitItems"
function L2_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2
  L5_2 = ActiveIncentories
  L5_2 = L5_2[A2_2]
  L5_2 = L5_2.content
  L5_2 = L5_2[A0_2]
  L5_2 = L5_2.name
  L6_2 = "-"
  L7_2 = math
  L7_2 = L7_2.random
  L8_2 = 0
  L9_2 = 99999
  L7_2 = L7_2(L8_2, L9_2)
  L5_2 = L5_2 .. L6_2 .. L7_2
  L6_2 = ActiveIncentories
  L6_2 = L6_2[A2_2]
  L6_2 = L6_2.content
  L6_2 = L6_2[A0_2]
  L6_2 = L6_2.amount
  L6_2 = L6_2 - A4_2
  if L6_2 > 0 then
    L6_2 = ActiveIncentories
    L6_2 = L6_2[A2_2]
    L6_2 = L6_2.content
    L6_2 = L6_2[A0_2]
    L7_2 = ActiveIncentories
    L7_2 = L7_2[A2_2]
    L7_2 = L7_2.content
    L7_2 = L7_2[A0_2]
    L7_2 = L7_2.amount
    L7_2 = L7_2 - A4_2
    L6_2.amount = L7_2
    L6_2 = ActiveIncentories
    L6_2 = L6_2[A3_2]
    L6_2 = L6_2.content
    L7_2 = copy
    L8_2 = ActiveIncentories
    L8_2 = L8_2[A2_2]
    L8_2 = L8_2.content
    L8_2 = L8_2[A0_2]
    L7_2 = L7_2(L8_2)
    L6_2[L5_2] = L7_2
    L6_2 = ActiveIncentories
    L6_2 = L6_2[A3_2]
    L6_2 = L6_2.content
    L6_2 = L6_2[L5_2]
    L6_2.slot = A1_2
    L6_2 = ActiveIncentories
    L6_2 = L6_2[A3_2]
    L6_2 = L6_2.content
    L6_2 = L6_2[L5_2]
    L6_2.id = L5_2
    L6_2 = ActiveIncentories
    L6_2 = L6_2[A3_2]
    L6_2 = L6_2.content
    L6_2 = L6_2[L5_2]
    L6_2.amount = A4_2
    L6_2 = ActiveIncentories
    L6_2 = L6_2[A3_2]
    if L6_2 then
      L6_2 = pairs
      L7_2 = ActiveIncentories
      L7_2 = L7_2[A3_2]
      L7_2 = L7_2.spectators
      L6_2, L7_2, L8_2, L9_2 = L6_2(L7_2)
      for L10_2, L11_2 in L6_2, L7_2, L8_2, L9_2 do
        if L11_2 then
          L12_2 = TriggerClientEvent
          L13_2 = "core_inventory:client:sync"
          L14_2 = L10_2
          L15_2 = A3_2
          L16_2 = ActiveIncentories
          L16_2 = L16_2[A3_2]
          L12_2(L13_2, L14_2, L15_2, L16_2)
        end
      end
    end
    L6_2 = ActiveIncentories
    L6_2 = L6_2[A2_2]
    if L6_2 and A2_2 ~= A3_2 then
      L6_2 = pairs
      L7_2 = ActiveIncentories
      L7_2 = L7_2[A2_2]
      L7_2 = L7_2.spectators
      L6_2, L7_2, L8_2, L9_2 = L6_2(L7_2)
      for L10_2, L11_2 in L6_2, L7_2, L8_2, L9_2 do
        if L11_2 then
          L12_2 = TriggerClientEvent
          L13_2 = "core_inventory:client:sync"
          L14_2 = L10_2
          L15_2 = A2_2
          L16_2 = ActiveIncentories
          L16_2 = L16_2[A2_2]
          L12_2(L13_2, L14_2, L15_2, L16_2)
        end
      end
    end
    if A2_2 ~= A3_2 then
      L6_2 = saveInventory
      L7_2 = A2_2
      L6_2(L7_2)
      L6_2 = saveInventory
      L7_2 = A3_2
      L6_2(L7_2)
    else
      L6_2 = saveInventory
      L7_2 = A2_2
      L6_2(L7_2)
    end
  end
end
L0_1(L1_1, L2_1)
L0_1 = RegisterServerEvent
L1_1 = "core_inventory:server:giveItem"
L0_1(L1_1)
L0_1 = AddEventHandler
L1_1 = "core_inventory:server:giveItem"
function L2_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2
  L2_2 = source
  L3_2 = ESX
  L3_2 = L3_2.GetPlayerFromId
  L4_2 = L2_2
  L3_2 = L3_2(L4_2)
  L4_2 = ESX
  L4_2 = L4_2.GetPlayerFromId
  L5_2 = A1_2
  L4_2 = L4_2(L5_2)
  L5_2 = "content-"
  L6_2 = L3_2.getcitizenid
  L6_2 = L6_2()
  L7_2 = L6_2
  L6_2 = L6_2.gsub
  L8_2 = ":"
  L9_2 = ""
  L6_2 = L6_2(L7_2, L8_2, L9_2)
  L5_2 = L5_2 .. L6_2
  L6_2 = "content-"
  L7_2 = L4_2.getcitizenid
  L7_2 = L7_2()
  L8_2 = L7_2
  L7_2 = L7_2.gsub
  L9_2 = ":"
  L10_2 = ""
  L7_2 = L7_2(L8_2, L9_2, L10_2)
  L6_2 = L6_2 .. L7_2
  L7_2 = copy
  L8_2 = ActiveIncentories
  L8_2 = L8_2[L5_2]
  L8_2 = L8_2.content
  L8_2 = L8_2[A0_2]
  L7_2 = L7_2(L8_2)
  L8_2 = ActiveIncentories
  L8_2 = L8_2[L6_2]
  if not L8_2 then
    L8_2 = preopenInventory
    L9_2 = L2_2
    L10_2 = L6_2
    L11_2 = "content"
    L12_2 = nil
    L13_2 = nil
    L14_2 = false
    L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2)
    L8_2 = Wait
    L9_2 = 100
    L8_2(L9_2)
  end
  L8_2 = getAvailableSlot
  L9_2 = L6_2
  L10_2 = L7_2
  L8_2 = L8_2(L9_2, L10_2)
  if L8_2 then
    L9_2 = removeItemExact
    L10_2 = L5_2
    L11_2 = A0_2
    L9_2(L10_2, L11_2)
    L7_2.slot = L8_2
    L9_2 = ActiveIncentories
    L9_2 = L9_2[L6_2]
    L9_2 = L9_2.content
    L9_2[A0_2] = L7_2
    L9_2 = ActiveIncentories
    L9_2 = L9_2[L6_2]
    if L9_2 then
      L9_2 = pairs
      L10_2 = ActiveIncentories
      L10_2 = L10_2[L6_2]
      L10_2 = L10_2.spectators
      L9_2, L10_2, L11_2, L12_2 = L9_2(L10_2)
      for L13_2, L14_2 in L9_2, L10_2, L11_2, L12_2 do
        if L14_2 then
          L15_2 = TriggerClientEvent
          L16_2 = "core_inventory:client:sync"
          L17_2 = L13_2
          L18_2 = L6_2
          L19_2 = ActiveIncentories
          L19_2 = L19_2[L6_2]
          L15_2(L16_2, L17_2, L18_2, L19_2)
        end
      end
    end
    L9_2 = ActiveIncentories
    L9_2 = L9_2[L5_2]
    if L9_2 and L5_2 ~= L6_2 then
      L9_2 = pairs
      L10_2 = ActiveIncentories
      L10_2 = L10_2[L5_2]
      L10_2 = L10_2.spectators
      L9_2, L10_2, L11_2, L12_2 = L9_2(L10_2)
      for L13_2, L14_2 in L9_2, L10_2, L11_2, L12_2 do
        if L14_2 then
          L15_2 = TriggerClientEvent
          L16_2 = "core_inventory:client:sync"
          L17_2 = L13_2
          L18_2 = L5_2
          L19_2 = ActiveIncentories
          L19_2 = L19_2[L5_2]
          L15_2(L16_2, L17_2, L18_2, L19_2)
        end
      end
    end
    L9_2 = TriggerClientEvent
    L10_2 = "core_inventory:client:handshake"
    L11_2 = L2_2
    L12_2 = A1_2
    L9_2(L10_2, L11_2, L12_2)
    L9_2 = TriggerClientEvent
    L10_2 = "core_inventory:client:handshake"
    L11_2 = A1_2
    L12_2 = L2_2
    L9_2(L10_2, L11_2, L12_2)
    if L5_2 ~= L6_2 then
      L9_2 = saveInventory
      L10_2 = L5_2
      L9_2(L10_2)
      L9_2 = saveInventory
      L10_2 = L6_2
      L9_2(L10_2)
    else
      L9_2 = saveInventory
      L10_2 = L5_2
      L9_2(L10_2)
    end
  end
end
L0_1(L1_1, L2_1)
L0_1 = RegisterServerEvent
L1_1 = "core_inventory:server:putItems"
L0_1(L1_1)
L0_1 = AddEventHandler
L1_1 = "core_inventory:server:putItems"
function L2_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2
  L4_2 = source
  L5_2 = copy
  L6_2 = ActiveIncentories
  L6_2 = L6_2[A1_2]
  L6_2 = L6_2.content
  L6_2 = L6_2[A0_2]
  L5_2 = L5_2(L6_2)
  L6_2 = ActiveIncentories
  L6_2 = L6_2[A2_2]
  if not L6_2 then
    L6_2 = preopenInventory
    L7_2 = L4_2
    L8_2 = A2_2
    L9_2 = A3_2
    L10_2 = nil
    L11_2 = nil
    L12_2 = false
    L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2)
    L6_2 = Wait
    L7_2 = 100
    L6_2(L7_2)
  end
  L6_2 = getAvailableSlot
  L7_2 = A2_2
  L8_2 = L5_2
  L6_2 = L6_2(L7_2, L8_2)
  if L6_2 then
    L7_2 = removeItemExact
    L8_2 = A1_2
    L9_2 = A0_2
    L7_2(L8_2, L9_2)
    L5_2.slot = L6_2
    L7_2 = ActiveIncentories
    L7_2 = L7_2[A2_2]
    L7_2 = L7_2.content
    L7_2[A0_2] = L5_2
    L7_2 = ActiveIncentories
    L7_2 = L7_2[A2_2]
    if L7_2 then
      L7_2 = pairs
      L8_2 = ActiveIncentories
      L8_2 = L8_2[A2_2]
      L8_2 = L8_2.spectators
      L7_2, L8_2, L9_2, L10_2 = L7_2(L8_2)
      for L11_2, L12_2 in L7_2, L8_2, L9_2, L10_2 do
        if L12_2 then
          L13_2 = TriggerClientEvent
          L14_2 = "core_inventory:client:sync"
          L15_2 = L11_2
          L16_2 = A2_2
          L17_2 = ActiveIncentories
          L17_2 = L17_2[A2_2]
          L13_2(L14_2, L15_2, L16_2, L17_2)
        end
      end
    end
    L7_2 = ActiveIncentories
    L7_2 = L7_2[A1_2]
    if L7_2 and A1_2 ~= A2_2 then
      L7_2 = pairs
      L8_2 = ActiveIncentories
      L8_2 = L8_2[A1_2]
      L8_2 = L8_2.spectators
      L7_2, L8_2, L9_2, L10_2 = L7_2(L8_2)
      for L11_2, L12_2 in L7_2, L8_2, L9_2, L10_2 do
        if L12_2 then
          L13_2 = TriggerClientEvent
          L14_2 = "core_inventory:client:sync"
          L15_2 = L11_2
          L16_2 = A1_2
          L17_2 = ActiveIncentories
          L17_2 = L17_2[A1_2]
          L13_2(L14_2, L15_2, L16_2, L17_2)
        end
      end
    end
    if A1_2 ~= A2_2 then
      L7_2 = saveInventory
      L8_2 = A1_2
      L7_2(L8_2)
      L7_2 = saveInventory
      L8_2 = A2_2
      L7_2(L8_2)
    else
      L7_2 = saveInventory
      L8_2 = A1_2
      L7_2(L8_2)
    end
  end
end
L0_1(L1_1, L2_1)
L0_1 = RegisterServerEvent
L1_1 = "core_inventory:server:stackItems"
L0_1(L1_1)
L0_1 = AddEventHandler
L1_1 = "core_inventory:server:stackItems"
function L2_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2
  L4_2 = ActiveIncentories
  L4_2 = L4_2[A2_2]
  L4_2 = L4_2.content
  L4_2 = L4_2[A0_2]
  L5_2 = ActiveIncentories
  L5_2 = L5_2[A3_2]
  L5_2 = L5_2.content
  L5_2 = L5_2[A1_2]
  L6_2 = L4_2.name
  L7_2 = L5_2.name
  if L6_2 == L7_2 then
    L6_2 = L4_2.amount
    if L6_2 then
      L6_2 = L4_2.amount
      L7_2 = L5_2.amount
      L6_2 = L6_2 + L7_2
      L7_2 = Config
      L7_2 = L7_2.ItemCategories
      L8_2 = L4_2.category
      L7_2 = L7_2[L8_2]
      L7_2 = L7_2.stack
      if L6_2 <= L7_2 then
        L6_2 = ActiveIncentories
        L6_2 = L6_2[A3_2]
        L6_2 = L6_2.content
        L6_2 = L6_2[A1_2]
        L7_2 = L4_2.amount
        L8_2 = L5_2.amount
        L7_2 = L7_2 + L8_2
        L6_2.amount = L7_2
        L6_2 = ActiveIncentories
        L6_2 = L6_2[A2_2]
        L6_2 = L6_2.content
        L6_2[A0_2] = nil
        L6_2 = ActiveIncentories
        L6_2 = L6_2[A3_2]
        if L6_2 then
          L6_2 = pairs
          L7_2 = ActiveIncentories
          L7_2 = L7_2[A3_2]
          L7_2 = L7_2.spectators
          L6_2, L7_2, L8_2, L9_2 = L6_2(L7_2)
          for L10_2, L11_2 in L6_2, L7_2, L8_2, L9_2 do
            if L11_2 then
              L12_2 = TriggerClientEvent
              L13_2 = "core_inventory:client:sync"
              L14_2 = L10_2
              L15_2 = A3_2
              L16_2 = ActiveIncentories
              L16_2 = L16_2[A3_2]
              L12_2(L13_2, L14_2, L15_2, L16_2)
            end
          end
        end
        L6_2 = ActiveIncentories
        L6_2 = L6_2[A2_2]
        if L6_2 and A2_2 ~= A3_2 then
          L6_2 = pairs
          L7_2 = ActiveIncentories
          L7_2 = L7_2[A2_2]
          L7_2 = L7_2.spectators
          L6_2, L7_2, L8_2, L9_2 = L6_2(L7_2)
          for L10_2, L11_2 in L6_2, L7_2, L8_2, L9_2 do
            if L11_2 then
              L12_2 = TriggerClientEvent
              L13_2 = "core_inventory:client:sync"
              L14_2 = L10_2
              L15_2 = A2_2
              L16_2 = ActiveIncentories
              L16_2 = L16_2[A2_2]
              L12_2(L13_2, L14_2, L15_2, L16_2)
            end
          end
        end
        if A2_2 ~= A3_2 then
          L6_2 = saveInventory
          L7_2 = A2_2
          L6_2(L7_2)
          L6_2 = saveInventory
          L7_2 = A3_2
          L6_2(L7_2)
        else
          L6_2 = saveInventory
          L7_2 = A2_2
          L6_2(L7_2)
        end
      end
    end
  end
end
L0_1(L1_1, L2_1)
L0_1 = RegisterServerEvent
L1_1 = "core_inventory:server:changeItemLocation"
L0_1(L1_1)
L0_1 = AddEventHandler
L1_1 = "core_inventory:server:changeItemLocation"
function L2_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2
  L5_2 = source
  L6_2 = ESX
  L6_2 = L6_2.GetPlayerFromId
  L7_2 = L5_2
  L6_2 = L6_2(L7_2)
  L7_2 = ActiveIncentories
  L7_2 = L7_2[A3_2]
  if L7_2 then
    L7_2 = ActiveIncentories
    L7_2 = L7_2[A3_2]
    L7_2 = L7_2.content
    L7_2 = L7_2[A0_2]
    if not L7_2 then
      L7_2 = print
      L8_2 = "[Core Inventory] Attempted trigger manipulation by (ID: "
      L9_2 = L5_2
      L10_2 = ")"
      L8_2 = L8_2 .. L9_2 .. L10_2
      L7_2(L8_2)
      return
    end
    L7_2 = ActiveIncentories
    L7_2 = L7_2[A3_2]
    L7_2 = L7_2.content
    L7_2[A0_2] = nil
  end
  L7_2 = A4_2.slot
  if L7_2 ~= A2_2 then
    A4_2.slot = A2_2
  end
  L7_2 = ActiveIncentories
  L7_2 = L7_2[A1_2]
  if L7_2 then
    L7_2 = ActiveIncentories
    L7_2 = L7_2[A1_2]
    L7_2 = L7_2.content
    L7_2[A0_2] = A4_2
  end
  L7_2 = ActiveIncentories
  L7_2 = L7_2[A1_2]
  if L7_2 then
    L7_2 = pairs
    L8_2 = ActiveIncentories
    L8_2 = L8_2[A1_2]
    L8_2 = L8_2.spectators
    L7_2, L8_2, L9_2, L10_2 = L7_2(L8_2)
    for L11_2, L12_2 in L7_2, L8_2, L9_2, L10_2 do
      if L12_2 then
        L13_2 = TriggerClientEvent
        L14_2 = "core_inventory:client:sync"
        L15_2 = L11_2
        L16_2 = A1_2
        L17_2 = ActiveIncentories
        L17_2 = L17_2[A1_2]
        L13_2(L14_2, L15_2, L16_2, L17_2)
      end
    end
  end
  L7_2 = ActiveIncentories
  L7_2 = L7_2[A3_2]
  if L7_2 and A3_2 ~= A1_2 then
    L7_2 = pairs
    L8_2 = ActiveIncentories
    L8_2 = L8_2[A3_2]
    L8_2 = L8_2.spectators
    L7_2, L8_2, L9_2, L10_2 = L7_2(L8_2)
    for L11_2, L12_2 in L7_2, L8_2, L9_2, L10_2 do
      if L12_2 then
        L13_2 = TriggerClientEvent
        L14_2 = "core_inventory:client:sync"
        L15_2 = L11_2
        L16_2 = A3_2
        L17_2 = ActiveIncentories
        L17_2 = L17_2[A3_2]
        L13_2(L14_2, L15_2, L16_2, L17_2)
      end
    end
    if A3_2 ~= A1_2 then
      L7_2 = saveInventory
      L8_2 = A3_2
      L7_2(L8_2)
      L7_2 = saveInventory
      L8_2 = A1_2
      L7_2(L8_2)
    else
      L7_2 = saveInventory
      L8_2 = A3_2
      L7_2(L8_2)
    end
  end
end
L0_1(L1_1, L2_1)
L0_1 = RegisterServerEvent
L1_1 = "core_inventory:server:loadClothes"
L0_1(L1_1)
L0_1 = AddEventHandler
L1_1 = "core_inventory:server:loadClothes"
function L2_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2
  L0_2 = source
  L1_2 = ESX
  L1_2 = L1_2.GetPlayerFromId
  L2_2 = L0_2
  L1_2 = L1_2(L2_2)
  L2_2 = Config
  L2_2 = L2_2.DisableClothing
  if L2_2 then
    return
  end
  if L1_2 then
    L2_2 = L1_2.getcitizenid
    L2_2 = L2_2()
    L3_2 = L2_2
    L2_2 = L2_2.gsub
    L4_2 = ":"
    L5_2 = ""
    L2_2 = L2_2(L3_2, L4_2, L5_2)
    L3_2 = pairs
    L4_2 = Config
    L4_2 = L4_2.InventoryClothing
    L3_2, L4_2, L5_2, L6_2 = L3_2(L4_2)
    for L7_2, L8_2 in L3_2, L4_2, L5_2, L6_2 do
      L9_2 = Config
      L9_2 = L9_2.Inventories
      L9_2 = L9_2[L7_2]
      if not L9_2 then
        L9_2 = print
        L10_2 = "[Core Inventory] No inventory created for clothing "
        L11_2 = L7_2
        L10_2 = L10_2 .. L11_2
        L9_2(L10_2)
        return
      end
      L9_2 = preopenHolder
      L10_2 = L0_2
      L11_2 = L7_2
      L12_2 = "-"
      L13_2 = L2_2
      L11_2 = L11_2 .. L12_2 .. L13_2
      L12_2 = L7_2
      L13_2 = nil
      L14_2 = nil
      L15_2 = false
      L9_2(L10_2, L11_2, L12_2, L13_2, L14_2, L15_2)
    end
  end
end
L0_1(L1_1, L2_1)
L0_1 = RegisterServerEvent
L1_1 = "core_inventory:server:loadInventory"
L0_1(L1_1)
L0_1 = AddEventHandler
L1_1 = "core_inventory:server:loadInventory"
function L2_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L0_2 = source
  L1_2 = ESX
  L1_2 = L1_2.GetPlayerFromId
  L2_2 = L0_2
  L1_2 = L1_2(L2_2)
  if L1_2 then
    L2_2 = L1_2.getcitizenid
    L2_2 = L2_2()
    L3_2 = L2_2
    L2_2 = L2_2.gsub
    L4_2 = ":"
    L5_2 = ""
    L2_2 = L2_2(L3_2, L4_2, L5_2)
    L3_2 = exports
    L3_2 = L3_2.oxmysql
    L4_2 = L3_2
    L3_2 = L3_2.scalar
    L5_2 = "SELECT inventorysettings FROM players WHERE citizenid = :cid"
    L6_2 = {}
    L6_2.cid = L2_2
    function L7_2(A0_3)
      local L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3, L12_3, L13_3
      if A0_3 or "" ~= A0_3 then
        L1_3 = json
        L1_3 = L1_3.decode
        L2_3 = A0_3
        L1_3 = L1_3(L2_3)
        A0_3 = L1_3
        L1_3 = TriggerClientEvent
        L2_3 = "core_inventory:client:setSettings"
        L3_3 = L0_2
        L4_3 = A0_3
        L5_3 = Items
        L1_3(L2_3, L3_3, L4_3, L5_3)
      end
      L1_3 = preopenInventory
      L2_3 = L0_2
      L3_3 = "content-"
      L4_3 = L2_2
      L3_3 = L3_3 .. L4_3
      L4_3 = "content"
      L5_3 = nil
      L6_3 = nil
      L7_3 = false
      L1_3(L2_3, L3_3, L4_3, L5_3, L6_3, L7_3)
      L1_3 = preopenHolder
      L2_3 = L0_2
      L3_3 = "primary-"
      L4_3 = L2_2
      L3_3 = L3_3 .. L4_3
      L4_3 = "primary"
      L5_3 = nil
      L6_3 = nil
      L7_3 = false
      L1_3(L2_3, L3_3, L4_3, L5_3, L6_3, L7_3)
      L1_3 = preopenHolder
      L2_3 = L0_2
      L3_3 = "secondry-"
      L4_3 = L2_2
      L3_3 = L3_3 .. L4_3
      L4_3 = "secondry"
      L5_3 = nil
      L6_3 = nil
      L7_3 = false
      L1_3(L2_3, L3_3, L4_3, L5_3, L6_3, L7_3)
      L1_3 = Config
      L1_3 = L1_3.DisableClothing
      if not L1_3 then
        L1_3 = pairs
        L2_3 = Config
        L2_3 = L2_3.InventoryClothing
        L1_3, L2_3, L3_3, L4_3 = L1_3(L2_3)
        for L5_3, L6_3 in L1_3, L2_3, L3_3, L4_3 do
          L7_3 = Config
          L7_3 = L7_3.Inventories
          L7_3 = L7_3[L5_3]
          if not L7_3 then
            L7_3 = print
            L8_3 = "[Core Inventory] No inventory created for clothing "
            L9_3 = L5_3
            L8_3 = L8_3 .. L9_3
            L7_3(L8_3)
            return
          end
          L7_3 = preopenHolder
          L8_3 = L0_2
          L9_3 = L5_3
          L10_3 = "-"
          L11_3 = L2_2
          L9_3 = L9_3 .. L10_3 .. L11_3
          L10_3 = L5_3
          L11_3 = nil
          L12_3 = nil
          L13_3 = false
          L7_3(L8_3, L9_3, L10_3, L11_3, L12_3, L13_3)
        end
      end
    end
    L3_2(L4_2, L5_2, L6_2, L7_2)
  end
end
L0_1(L1_1, L2_1)
L0_1 = RegisterServerEvent
L1_1 = "core_inventory:server:handleAttachment"
L0_1(L1_1)
L0_1 = AddEventHandler
L1_1 = "core_inventory:server:handleAttachment"
function L2_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L3_2 = source
  L4_2 = ESX
  L4_2 = L4_2.GetPlayerFromId
  L5_2 = L3_2
  L4_2 = L4_2(L5_2)
  L5_2 = L4_2.getcitizenid
  L5_2 = L5_2()
  L6_2 = L5_2
  L5_2 = L5_2.gsub
  L7_2 = ":"
  L8_2 = ""
  L5_2 = L5_2(L6_2, L7_2, L8_2)
  L6_2 = ActiveIncentories
  L7_2 = "content-"
  L8_2 = L5_2
  L7_2 = L7_2 .. L8_2
  L6_2 = L6_2[L7_2]
  L6_2 = L6_2.content
  L6_2 = L6_2[A0_2]
  L6_2 = L6_2.metadata
  L6_2 = L6_2.attachments
  L6_2[A1_2] = A2_2
end
L0_1(L1_1, L2_1)
L0_1 = RegisterServerEvent
L1_1 = "core_inventory:server:updateSettings"
L0_1(L1_1)
L0_1 = AddEventHandler
L1_1 = "core_inventory:server:updateSettings"
function L2_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = source
  L2_2 = ESX
  L2_2 = L2_2.GetPlayerFromId
  L3_2 = L1_2
  L2_2 = L2_2(L3_2)
  L3_2 = L2_2.getcitizenid
  L3_2 = L3_2()
  L4_2 = exports
  L4_2 = L4_2.oxmysql
  L5_2 = L4_2
  L4_2 = L4_2.update
  L6_2 = "UPDATE `players` SET `inventorysettings`= :settings WHERE `citizenid` = :cid"
  L7_2 = {}
  L8_2 = json
  L8_2 = L8_2.encode
  L9_2 = A0_2
  L8_2 = L8_2(L9_2)
  L7_2.settings = L8_2
  L7_2.cid = L3_2
  function L8_2()
    local L0_3, L1_3
  end
  L4_2(L5_2, L6_2, L7_2, L8_2)
end
L0_1(L1_1, L2_1)
L0_1 = RegisterServerEvent
L1_1 = "core_inventory:server:createDrop"
L0_1(L1_1)
L0_1 = AddEventHandler
L1_1 = "core_inventory:server:createDrop"
function L2_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L2_2 = source
  L3_2 = ESX
  L3_2 = L3_2.GetPlayerFromId
  L4_2 = L2_2
  L3_2 = L3_2(L4_2)
  L4_2 = L3_2.getcitizenid
  L4_2 = L4_2()
  L5_2 = L4_2
  L4_2 = L4_2.gsub
  L6_2 = ":"
  L7_2 = ""
  L4_2 = L4_2(L5_2, L6_2, L7_2)
  L5_2 = {}
  L6_2 = ActiveIncentories
  L7_2 = "content-"
  L8_2 = L4_2
  L7_2 = L7_2 .. L8_2
  L6_2 = L6_2[L7_2]
  L6_2 = L6_2.content
  L6_2 = L6_2[A0_2]
  L5_2[A0_2] = L6_2
  L6_2 = L5_2[A0_2]
  L6_2.slot = 1
  L6_2 = removeItemExact
  L7_2 = "content-"
  L8_2 = L4_2
  L7_2 = L7_2 .. L8_2
  L8_2 = A0_2
  L6_2(L7_2, L8_2)
  L6_2 = "drop-"
  L7_2 = math
  L7_2 = L7_2.random
  L8_2 = 0
  L9_2 = 9999
  L7_2 = L7_2(L8_2, L9_2)
  L6_2 = L6_2 .. L7_2
  L7_2 = Drops
  L8_2 = {}
  L8_2.coords = A1_2
  L7_2[L6_2] = L8_2
  L7_2 = Config
  L7_2 = L7_2.Inventories
  L7_2 = L7_2.drop
  if not L7_2 then
    L7_2 = {}
  end
  L8_2 = ActiveIncentories
  L9_2 = {}
  L9_2.content = L5_2
  L10_2 = {}
  L9_2.spectators = L10_2
  L9_2.type = "drop"
  L9_2.restrictedTo = "drop"
  L10_2 = L5_2[A0_2]
  L10_2 = L10_2.x
  L11_2 = L5_2[A0_2]
  L11_2 = L11_2.y
  L10_2 = L10_2 * L11_2
  L9_2.slots = L10_2
  L9_2.hidden = false
  L10_2 = L5_2[A0_2]
  L10_2 = L10_2.x
  L9_2.rows = L10_2
  L9_2.name = L6_2
  L10_2 = L7_2.label
  if not L10_2 then
    L10_2 = "DROP"
  end
  L9_2.label = L10_2
  L10_2 = L7_2.x
  if not L10_2 then
    L10_2 = 1
  end
  L9_2.x = L10_2
  L10_2 = L7_2.y
  if not L10_2 then
    L10_2 = 1
  end
  L9_2.y = L10_2
  L8_2[L6_2] = L9_2
  L8_2 = TriggerClientEvent
  L9_2 = "core_inventory:client:syncDrops"
  L10_2 = -1
  L11_2 = Drops
  L8_2(L9_2, L10_2, L11_2)
  L8_2 = openHolder
  L9_2 = L2_2
  L10_2 = L6_2
  L8_2(L9_2, L10_2)
end
L0_1(L1_1, L2_1)
L0_1 = RegisterServerEvent
L1_1 = "core_inventory:server:openDrop"
L0_1(L1_1)
L0_1 = AddEventHandler
L1_1 = "core_inventory:server:openDrop"
function L2_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = source
  L2_2 = openHolder
  L3_2 = L1_2
  L4_2 = A0_2
  L2_2(L3_2, L4_2)
end
L0_1(L1_1, L2_1)
L0_1 = RegisterServerEvent
L1_1 = "core_inventory:server:openPersonalInventory"
L0_1(L1_1)
L0_1 = AddEventHandler
L1_1 = "core_inventory:server:openPersonalInventory"
function L2_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2
  L0_2 = source
  L1_2 = ESX
  L1_2 = L1_2.GetPlayerFromId
  L2_2 = L0_2
  L1_2 = L1_2(L2_2)
  L2_2 = L1_2.getcitizenid
  L2_2 = L2_2()
  L3_2 = L2_2
  L2_2 = L2_2.gsub
  L4_2 = ":"
  L5_2 = ""
  L2_2 = L2_2(L3_2, L4_2, L5_2)
  L3_2 = preopenInventory
  L4_2 = L0_2
  L5_2 = "content-"
  L6_2 = L2_2
  L5_2 = L5_2 .. L6_2
  L6_2 = "content"
  L7_2 = nil
  L8_2 = nil
  L9_2 = true
  L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2)
  L3_2 = preopenHolder
  L4_2 = L0_2
  L5_2 = "primary-"
  L6_2 = L2_2
  L5_2 = L5_2 .. L6_2
  L6_2 = "primary"
  L7_2 = nil
  L8_2 = nil
  L9_2 = true
  L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2)
  L3_2 = preopenHolder
  L4_2 = L0_2
  L5_2 = "secondry-"
  L6_2 = L2_2
  L5_2 = L5_2 .. L6_2
  L6_2 = "secondry"
  L7_2 = nil
  L8_2 = nil
  L9_2 = true
  L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2)
  L3_2 = Config
  L3_2 = L3_2.DisableClothing
  if not L3_2 then
    L3_2 = pairs
    L4_2 = Config
    L4_2 = L4_2.InventoryClothing
    L3_2, L4_2, L5_2, L6_2 = L3_2(L4_2)
    for L7_2, L8_2 in L3_2, L4_2, L5_2, L6_2 do
      L9_2 = Config
      L9_2 = L9_2.Inventories
      L9_2 = L9_2[L7_2]
      if not L9_2 then
        L9_2 = print
        L10_2 = "[Core Inventory] No inventory created for clothing "
        L11_2 = L7_2
        L10_2 = L10_2 .. L11_2
        L9_2(L10_2)
        return
      end
      L9_2 = preopenHolder
      L10_2 = L0_2
      L11_2 = L7_2
      L12_2 = "-"
      L13_2 = L2_2
      L11_2 = L11_2 .. L12_2 .. L13_2
      L12_2 = L7_2
      L13_2 = nil
      L14_2 = nil
      L15_2 = true
      L9_2(L10_2, L11_2, L12_2, L13_2, L14_2, L15_2)
    end
  end
end
L0_1(L1_1, L2_1)
L0_1 = RegisterServerEvent
L1_1 = "core_inventory:server:updateInventory"
L0_1(L1_1)
L0_1 = AddEventHandler
L1_1 = "core_inventory:server:updateInventory"
function L2_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L2_2 = source
  L3_2 = ActiveIncentories
  L3_2 = L3_2[A0_2]
  L3_2.content = A1_2
  L3_2 = pairs
  L4_2 = ActiveIncentories
  L4_2 = L4_2[A0_2]
  L4_2 = L4_2.spectators
  L3_2, L4_2, L5_2, L6_2 = L3_2(L4_2)
  for L7_2, L8_2 in L3_2, L4_2, L5_2, L6_2 do
    if L8_2 then
      L9_2 = TriggerClientEvent
      L10_2 = "core_inventory:client:sync"
      L11_2 = L7_2
      L12_2 = A0_2
      L13_2 = ActiveIncentories
      L13_2 = L13_2[A0_2]
      L9_2(L10_2, L11_2, L12_2, L13_2)
    end
  end
end
L0_1(L1_1, L2_1)
L0_1 = RegisterServerEvent
L1_1 = "core_inventory:server:useItem"
L0_1(L1_1)
L0_1 = AddEventHandler
L1_1 = "core_inventory:server:useItem"
function L2_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = source
  L3_2 = ESX
  L3_2 = L3_2.GetPlayerFromId
  L4_2 = source
  L3_2 = L3_2(L4_2)
  L4_2 = L3_2.getcitizenid
  L4_2 = L4_2()
  L5_2 = L4_2
  L4_2 = L4_2.gsub
  L6_2 = ":"
  L7_2 = ""
  L4_2 = L4_2(L5_2, L6_2, L7_2)
  L5_2 = ActiveIncentories
  L6_2 = "content-"
  L7_2 = L4_2
  L6_2 = L6_2 .. L7_2
  L5_2 = L5_2[L6_2]
  L5_2 = L5_2.content
  L5_2 = L5_2[A1_2]
  if L5_2 then
    L5_2 = UsedItems
    L6_2 = "content-"
    L7_2 = L4_2
    L6_2 = L6_2 .. L7_2
    L5_2[L6_2] = A1_2
    L5_2 = copy
    L6_2 = ActiveIncentories
    L7_2 = "content-"
    L8_2 = L4_2
    L7_2 = L7_2 .. L8_2
    L6_2 = L6_2[L7_2]
    L6_2 = L6_2.content
    L6_2 = L6_2[A1_2]
    L5_2 = L5_2(L6_2)
    L6_2 = L5_2.metadata
    L5_2.info = L6_2
    L6_2 = ESX
    L6_2 = L6_2.UseItem
    L7_2 = L2_2
    L8_2 = A0_2
    L9_2 = L5_2
    L6_2(L7_2, L8_2, L9_2)
  else
    L5_2 = getItems
    L6_2 = "content-"
    L7_2 = L4_2
    L6_2 = L6_2 .. L7_2
    L7_2 = A0_2
    L5_2 = L5_2(L6_2, L7_2)
    L5_2 = #L5_2
    if L5_2 > 0 then
      L5_2 = getItems
      L6_2 = "content-"
      L7_2 = L4_2
      L6_2 = L6_2 .. L7_2
      L7_2 = A0_2
      L5_2 = L5_2(L6_2, L7_2)
      L5_2 = L5_2[1]
      L6_2 = L5_2.metadata
      L5_2.info = L6_2
      L6_2 = ESX
      L6_2 = L6_2.UseItem
      L7_2 = L2_2
      L8_2 = A0_2
      L9_2 = L5_2
      L6_2(L7_2, L8_2, L9_2)
    end
  end
end
L0_1(L1_1, L2_1)
L0_1 = RegisterServerEvent
L1_1 = "core_inventory:server:openHolder"
L0_1(L1_1)
L0_1 = AddEventHandler
L1_1 = "core_inventory:server:openHolder"
function L2_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L4_2 = source
  L5_2 = preopenHolder
  L6_2 = L4_2
  L7_2 = A0_2
  L8_2 = A1_2
  L9_2 = A2_2
  L10_2 = A3_2
  L11_2 = true
  L5_2(L6_2, L7_2, L8_2, L9_2, L10_2, L11_2)
end
L0_1(L1_1, L2_1)
L0_1 = RegisterServerEvent
L1_1 = "core_inventory:server:openInventory"
L0_1(L1_1)
L0_1 = AddEventHandler
L1_1 = "core_inventory:server:openInventory"
function L2_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L4_2 = source
  if "otherplayer" == A1_2 then
    L5_2 = ESX
    L5_2 = L5_2.GetPlayerFromId
    L6_2 = A0_2
    L5_2 = L5_2(L6_2)
    L6_2 = preopenInventory
    L7_2 = L4_2
    L8_2 = "content-"
    L9_2 = L5_2.getcitizenid
    L9_2 = L9_2()
    L10_2 = L9_2
    L9_2 = L9_2.gsub
    L11_2 = ":"
    L12_2 = ""
    L9_2 = L9_2(L10_2, L11_2, L12_2)
    L8_2 = L8_2 .. L9_2
    L9_2 = "content"
    L10_2 = nil
    L11_2 = nil
    L12_2 = true
    L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2)
    L6_2 = preopenInventory
    L7_2 = L4_2
    L8_2 = "primary-"
    L9_2 = L5_2.getcitizenid
    L9_2 = L9_2()
    L10_2 = L9_2
    L9_2 = L9_2.gsub
    L11_2 = ":"
    L12_2 = ""
    L9_2 = L9_2(L10_2, L11_2, L12_2)
    L8_2 = L8_2 .. L9_2
    L9_2 = "primary"
    L10_2 = nil
    L11_2 = nil
    L12_2 = true
    L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2)
    L6_2 = preopenInventory
    L7_2 = L4_2
    L8_2 = "secondry-"
    L9_2 = L5_2.getcitizenid
    L9_2 = L9_2()
    L10_2 = L9_2
    L9_2 = L9_2.gsub
    L11_2 = ":"
    L12_2 = ""
    L9_2 = L9_2(L10_2, L11_2, L12_2)
    L8_2 = L8_2 .. L9_2
    L9_2 = "secondry"
    L10_2 = nil
    L11_2 = nil
    L12_2 = true
    L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2)
  else
    L5_2 = preopenInventory
    L6_2 = L4_2
    L7_2 = A0_2
    L8_2 = A1_2
    L9_2 = A2_2
    L10_2 = A3_2
    L11_2 = true
    L5_2(L6_2, L7_2, L8_2, L9_2, L10_2, L11_2)
  end
end
L0_1(L1_1, L2_1)
L0_1 = RegisterServerEvent
L1_1 = "core_inventory:server:updateAmmo"
L0_1(L1_1)
L0_1 = AddEventHandler
L1_1 = "core_inventory:server:updateAmmo"
function L2_1(A0_2, A1_2, A2_2)
  local L3_2
  L3_2 = ActiveIncentories
  L3_2 = L3_2[A1_2]
  if L3_2 and A2_2 then
    L3_2 = ActiveIncentories
    L3_2 = L3_2[A1_2]
    L3_2 = L3_2.content
    L3_2 = L3_2[A0_2]
    if L3_2 then
      L3_2 = ActiveIncentories
      L3_2 = L3_2[A1_2]
      L3_2 = L3_2.content
      L3_2 = L3_2[A0_2]
      L3_2 = L3_2.metadata
      L3_2.ammo = A2_2
    end
  end
end
L0_1(L1_1, L2_1)
L0_1 = RegisterServerEvent
L1_1 = "core_inventory:server:removeDurability"
L0_1(L1_1)
L0_1 = AddEventHandler
L1_1 = "core_inventory:server:removeDurability"
function L2_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2
  L3_2 = removeDurability
  L4_2 = A1_2
  L5_2 = A0_2
  L6_2 = A2_2
  L3_2(L4_2, L5_2, L6_2)
end
L0_1(L1_1, L2_1)
L0_1 = RegisterServerEvent
L1_1 = "core_inventory:server:openTrunk"
L0_1(L1_1)
L0_1 = AddEventHandler
L1_1 = "core_inventory:server:openTrunk"
function L2_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L3_2 = source
  L4_2 = Config
  L4_2 = L4_2.Trunks
  L4_2 = L4_2[A1_2]
  if A2_2 then
    L5_2 = Config
    L5_2 = L5_2.SpecificTrunks
    L5_2 = L5_2[A2_2]
    if L5_2 then
      L5_2 = Config
      L5_2 = L5_2.SpecificTrunks
      L4_2 = L5_2[A2_2]
    end
  end
  L5_2 = preopenInventory
  L6_2 = L3_2
  L7_2 = "trunk-"
  L9_2 = A0_2
  L8_2 = A0_2.gsub
  L10_2 = " "
  L11_2 = "-"
  L8_2 = L8_2(L9_2, L10_2, L11_2)
  L7_2 = L7_2 .. L8_2
  L8_2 = L4_2
  L9_2 = nil
  L10_2 = nil
  L11_2 = true
  L5_2(L6_2, L7_2, L8_2, L9_2, L10_2, L11_2)
end
L0_1(L1_1, L2_1)
L0_1 = RegisterServerEvent
L1_1 = "core_inventory:server:openGlovebox"
L0_1(L1_1)
L0_1 = AddEventHandler
L1_1 = "core_inventory:server:openGlovebox"
function L2_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = source
  L2_2 = preopenInventory
  L3_2 = L1_2
  L4_2 = "glovebox-"
  L6_2 = A0_2
  L5_2 = A0_2.gsub
  L7_2 = " "
  L8_2 = "-"
  L5_2 = L5_2(L6_2, L7_2, L8_2)
  L4_2 = L4_2 .. L5_2
  L5_2 = "glovebox"
  L6_2 = nil
  L7_2 = nil
  L8_2 = true
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2)
end
L0_1(L1_1, L2_1)
L0_1 = RegisterServerEvent
L1_1 = "core_inventory:server:closeInventory"
L0_1(L1_1)
L0_1 = AddEventHandler
L1_1 = "core_inventory:server:closeInventory"
function L2_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = source
  L3_2 = ActiveIncentories
  L3_2 = L3_2[A0_2]
  L3_2 = L3_2.spectators
  L3_2[L2_2] = nil
  L3_2 = ActiveIncentories
  L3_2 = L3_2[A0_2]
  L4_2 = A1_2.x
  L3_2.x = L4_2
  L3_2 = ActiveIncentories
  L3_2 = L3_2[A0_2]
  L4_2 = A1_2.y
  L3_2.y = L4_2
  L3_2 = ActiveIncentories
  L3_2 = L3_2[A0_2]
  L4_2 = A1_2.hidden
  L3_2.hidden = L4_2
  L3_2 = ActiveIncentories
  L3_2 = L3_2[A0_2]
  L3_2 = L3_2.type
  if "drop" == L3_2 then
    L3_2 = ActiveIncentories
    L3_2 = L3_2[A0_2]
    L3_2 = L3_2.spectators
    L3_2 = #L3_2
    if 0 == L3_2 then
      L3_2 = next
      L4_2 = ActiveIncentories
      L4_2 = L4_2[A0_2]
      L4_2 = L4_2.content
      L3_2 = L3_2(L4_2)
      if nil == L3_2 then
        L3_2 = Drops
        L3_2[A0_2] = nil
        L3_2 = TriggerClientEvent
        L4_2 = "core_inventory:client:syncDrops"
        L5_2 = -1
        L6_2 = Drops
        L3_2(L4_2, L5_2, L6_2)
      end
    end
  end
  L3_2 = ActiveIncentories
  L3_2 = L3_2[A0_2]
  L3_2 = L3_2.spectators
  L3_2 = #L3_2
  if 0 == L3_2 then
    L3_2 = saveInventory
    L4_2 = A0_2
    L3_2(L4_2)
  end
end
L0_1(L1_1, L2_1)
L0_1 = exports
L1_1 = "openHolder"
L2_1 = preopenHolder
L0_1(L1_1, L2_1)
L0_1 = exports
L1_1 = "openInventory"
L2_1 = preopenInventory
L0_1(L1_1, L2_1)
L0_1 = exports
L1_1 = "addItem"
L2_1 = addItem
L0_1(L1_1, L2_1)
L0_1 = exports
L1_1 = "canCarry"
L2_1 = canCarry
L0_1(L1_1, L2_1)
L0_1 = exports
L1_1 = "removeItem"
L2_1 = removeItem
L0_1(L1_1, L2_1)
L0_1 = exports
L1_1 = "removeItemExact"
L2_1 = removeItemExact
L0_1(L1_1, L2_1)
L0_1 = exports
L1_1 = "clearInventory"
L2_1 = clearInventory
L0_1(L1_1, L2_1)
L0_1 = exports
L1_1 = "getItem"
L2_1 = getItem
L0_1(L1_1, L2_1)
L0_1 = exports
L1_1 = "updateMetadata"
L2_1 = updateMetadata
L0_1(L1_1, L2_1)
L0_1 = exports
L1_1 = "openLoot"
L2_1 = openLoot
L0_1(L1_1, L2_1)
L0_1 = exports
L1_1 = "getItems"
L2_1 = getItems
L0_1(L1_1, L2_1)
L0_1 = exports
L1_1 = "getInventory"
L2_1 = getInventory
L0_1(L1_1, L2_1)
L0_1 = exports
L1_1 = "removeDurability"
L2_1 = removeDurability
L0_1(L1_1, L2_1)
L0_1 = exports
L1_1 = "setDurability"
L2_1 = setDurability
L0_1(L1_1, L2_1)
