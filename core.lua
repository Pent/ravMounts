local ADDON_NAME, ns = ...
local L = ns.L

local _, className = UnitClass("player")
local travelFormCondition = (IsOutdoors() or IsSubmerged())

function ravMounts_OnLoad(self)
    self:RegisterEvent("PLAYER_LOGIN")
    self:RegisterEvent("ADDON_LOADED")
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    self:RegisterEvent("MOUNT_JOURNAL_SEARCH_UPDATED")
    self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    self:RegisterEvent("UPDATE_SHAPESHIFT_FORMS")
    self:RegisterEvent("GROUP_ROSTER_UPDATE")
    self:RegisterEvent("CHAT_MSG_ADDON")
    self:RegisterEvent("BAG_UPDATE")
    if className == "DRUID" then
        self:RegisterEvent("ZONE_CHANGED")
    end
end

function ravMounts_OnEvent(self, event, arg, ...)
    if event == "PLAYER_LOGIN" then
        ns:SetDefaultSettings()
        ns:CreateSettingsPanel()
        if not ns.version:match("-") then
            if not RAV_version then
                ns:PrettyPrint(L.Install:format(ns.color, ns.version))
            elseif RAV_version ~= ns.version then
                ns:PrettyPrint(L.Update:format(ns.color, ns.version))
            end
            RAV_version = ns.version
        end
        ns:MountListHandler()
        self:UnregisterEvent("PLAYER_LOGIN")
    elseif event == "ADDON_LOADED" and arg == "Blizzard_Collections" then
        ns:CreateOpenSettingsButton()
        self:UnregisterEvent("ADDON_LOADED")
    elseif event == "ZONE_CHANGED_NEW_AREA" or event == "MOUNT_JOURNAL_SEARCH_UPDATED" or event =="PLAYER_SPECIALIZATION_CHANGED" or event == "UPDATE_SHAPESHIFT_FORMS" then
        ns:MountListHandler()
        ns:EnsureMacro()
    elseif event == "ZONE_CHANGED" and travelFormCondition ~= (IsOutdoors() or IsSubmerged()) then
        travelFormCondition = (IsOutdoors() or IsSubmerged())
        ns:MountListHandler()
        ns:EnsureMacro()
    elseif event == "GROUP_ROSTER_UPDATE" then
        local partyMembers = GetNumSubgroupMembers()
        local raidMembers = IsInRaid() and GetNumGroupMembers() or 0
        if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and (partyMembers > ns.data.partyMembers or raidMembers > ns.data.raidMembers) then
            ns:SendUpdate("INSTANCE_CHAT")
        elseif raidMembers == 0 and partyMembers > ns.data.partyMembers then
            ns:SendUpdate("PARTY")
        elseif raidMembers > ns.data.raidMembers then
            ns:SendUpdate("RAID")
        end
        ns.data.partyMembers = partyMembers
        ns.data.raidMembers = raidMembers
    elseif event == "CHAT_MSG_ADDON" and arg == ADDON_NAME then
        local message, channel, sender, _ = ...
        if message:match("V:") and not ns.updateFound then
            local version = message:gsub("V:", "")
            if not version:match("-") then
                local v1, v2, v3 = strsplit(".", version)
                local c1, c2, c3 = strsplit(".", ns.version)
                if v1 > c1 or (v1 == c1 and v2 > c2) or (v1 == c1 and v2 == c2 and v3 > c3) then
                    ns:PrettyPrint(L.UpdateFound:format(version))
                    ns.updateFound = true
                end
            end
        end
    elseif event == "BAG_UPDATE" then
        ns:MountListHandler()
    end
end

SlashCmdList["RAVMOUNTS"] = function(message)
    if message == "version" or message == "v" then
        ns:PrettyPrint(L.Version:format(ns.version))
    elseif message == "c" or message:match("con") or message == "h" or message:match("help") or message == "o" or message:match("opt") or message == "s" or message:match("sett") or message:match("togg") then
        PlaySound(SOUNDKIT.IG_MAINMENU_OPEN)
        Settings.OpenToCategory(ns.name)
    elseif message == "id" then
        ns:MountIdentifier()
    elseif message == "f" or message:match("force") then
        ns:PrettyPrint(L.Force)
        ns:MountListHandler()
        ns:EnsureMacro()
    else
        ns:MountUpHandler(message)
    end
end
SLASH_RAVMOUNTS1 = "/ravm"
SLASH_RAVMOUNTS2 = "/ravmounts"
SLASH_RAVMOUNTS3 = "/ravenousmounts"
