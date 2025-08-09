-- Yes, there's no doubt far better ways of implimenting this but it is what it is. 

local GCM = _G["GuildCaseManager"]

-- Tab-based Main Frame
function GCM.CreateMainFrame()
    if GCM.MainFrame then return end
    
    -- Main Window
    GCM.MainFrame = CreateFrame("Frame", "GCM_MainFrame", UIParent, "BasicFrameTemplate")
    GCM.MainFrame:SetSize(900, 650)
    GCM.MainFrame:SetPoint("CENTER")
    GCM.MainFrame:SetMovable(true)
    GCM.MainFrame:SetResizable(true)
    GCM.MainFrame:EnableMouse(true)
    GCM.MainFrame:RegisterForDrag("LeftButton")
    GCM.MainFrame:SetScript("OnDragStart", GCM.MainFrame.StartMoving)
    GCM.MainFrame:SetScript("OnDragStop", GCM.MainFrame.StopMovingOrSizing)
    
    -- Add resize grip
    local resizeButton = CreateFrame("Button", nil, GCM.MainFrame)
    resizeButton:SetSize(16, 16)
    resizeButton:SetPoint("BOTTOMRIGHT", -6, 6)
    resizeButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resizeButton:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    resizeButton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    resizeButton:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            GCM.MainFrame:StartSizing("BOTTOMRIGHT")
        end
    end)
    resizeButton:SetScript("OnMouseUp", function(self, button)
        GCM.MainFrame:StopMovingOrSizing()
    end)
    
    -- Title
    GCM.MainFrame.title = GCM.MainFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    GCM.MainFrame.title:SetPoint("TOP", 0, -10)
    GCM.MainFrame.title:SetText("Guild Case Manager")
    
    -- Create tab system
    GCM.CreateTabSystem()
    
    -- Close Button
    local closeBtn = CreateFrame("Button", nil, GCM.MainFrame, "UIPanelButtonTemplate")
    closeBtn:SetSize(80, 25)
    closeBtn:SetPoint("BOTTOMRIGHT", -10, 10)
    closeBtn:SetText("Close")
    closeBtn:SetScript("OnClick", function()
        GCM.MainFrame:Hide()
    end)
    
    GCM.MainFrame:Hide()
end

-- Create Tab System
function GCM.CreateTabSystem()
    if not GCM.MainFrame then return end
    
    -- Check if tab system already exists
    if GCM.MainFrame.tabContainer then return end
    
    -- Tab container on the left side
    local tabContainer = CreateFrame("Frame", nil, GCM.MainFrame)
    tabContainer:SetSize(150, 550)
    tabContainer:SetPoint("TOPLEFT", 10, -30)
    GCM.MainFrame.tabContainer = tabContainer
    
    -- Content area on the right side
    local contentFrame = CreateFrame("Frame", nil, GCM.MainFrame, "BackdropTemplate")
    contentFrame:SetSize(720, 550)
    contentFrame:SetPoint("TOPLEFT", 170, -30)
    contentFrame:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    contentFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
    contentFrame:SetBackdropBorderColor(0.8, 0.8, 0.8, 1)
    GCM.MainFrame.contentFrame = contentFrame
    
    -- Initialize tabs
    GCM.MainFrame.tabs = {}
    GCM.MainFrame.tabButtons = {}
    GCM.MainFrame.activeTab = nil
    
    -- Define tabs
    local tabData = {
        {id = "welcome", name = "Welcome", icon = "Interface\\Icons\\Achievement_Guild_Doctoring"},
        {id = "cases", name = "Cases", icon = "Interface\\Icons\\INV_Scroll_08"},
        {id = "people", name = "People", icon = "Interface\\Icons\\Achievement_Guild_ClassyMage"},
        {id = "map", name = "Map", icon = "Interface\\Icons\\INV_Misc_Map_01"},
        {id = "staff", name = "Staff", icon = "Interface\\Icons\\Achievement_Guild_DoGuildDungeonsDifficultCount"},
        {id = "gjle", name = "GJLE", icon = "Interface\\Icons\\INV_Misc_Coin_17"},
        {id = "kirintor", name = "Kirin Tor", icon = "Interface\\Icons\\Achievement_Dungeon_DalaranNexus_Heroic"},
        {id = "about", name = "About", icon = "Interface\\Icons\\INV_Misc_QuestionMark"}
    }
    
    -- Create tab buttons
    local yOffset = -5
    for i, data in ipairs(tabData) do
        local tabButton = CreateFrame("Button", nil, tabContainer, "UIPanelButtonTemplate")
        tabButton:SetSize(140, 28)  -- Reduced height to 28
        tabButton:SetPoint("TOPLEFT", 5, yOffset)
        tabButton:SetText(data.name)
        tabButton:SetNormalFontObject("GameFontNormalSmall")  -- Use smaller font
        tabButton.tabId = data.id
        
        -- Add icon if available
        if data.icon then
            local icon = tabButton:CreateTexture(nil, "ARTWORK")
            icon:SetSize(12, 12)  -- Smaller icons
            icon:SetPoint("LEFT", 4, 0)
            icon:SetTexture(data.icon)
            tabButton:GetFontString():SetPoint("LEFT", icon, "RIGHT", 3, 0)
        end
        
        tabButton:SetScript("OnClick", function(self)
            GCM.SelectTab(self.tabId)
        end)
        
        GCM.MainFrame.tabButtons[data.id] = tabButton
        yOffset = yOffset - 32  -- Reduced spacing to 32 pixels between buttons
    end
    
    -- Create tab content frames
    GCM.CreateTabContent()
    
    -- Select the welcome tab by default
    GCM.SelectTab("welcome")
end

-- Select a tab
function GCM.SelectTab(tabId)
    if not GCM.MainFrame or not GCM.MainFrame.tabs then return end
    
    -- Hide all tabs
    for id, tab in pairs(GCM.MainFrame.tabs) do
        tab:Hide()
    end
    
    -- Reset all tab button states
    for id, button in pairs(GCM.MainFrame.tabButtons) do
        button:SetNormalTexture("Interface\\Buttons\\UI-Panel-Button-Up")
        button:SetPushedTexture("Interface\\Buttons\\UI-Panel-Button-Down")
        button:SetHighlightTexture("Interface\\Buttons\\UI-Panel-Button-Highlight")
    end
    
    -- Show selected tab
    if GCM.MainFrame.tabs[tabId] then
        GCM.MainFrame.tabs[tabId]:Show()
        GCM.MainFrame.activeTab = tabId
        
        -- Highlight selected tab button
        local activeButton = GCM.MainFrame.tabButtons[tabId]
        if activeButton then
            activeButton:SetNormalTexture("Interface\\Buttons\\UI-Panel-Button-Down")
        end
        
        -- Handle special tab initialization
        if tabId == "cases" then
            GCM.RefreshCasesTab()
        elseif tabId == "people" then
            GCM.RefreshPeopleTab()
        elseif tabId == "map" then
            GCM.InitializeMapTab()
        end
    end
end

-- Create tab content frames
function GCM.CreateTabContent()
    if not GCM.MainFrame or not GCM.MainFrame.contentFrame then return end
    
    local contentFrame = GCM.MainFrame.contentFrame
    
    -- Welcome Tab
    GCM.MainFrame.tabs.welcome = GCM.CreateWelcomeTab(contentFrame)
    
    -- Cases Tab  
    GCM.MainFrame.tabs.cases = GCM.CreateCasesTab(contentFrame)
    
    -- People Tab
    GCM.MainFrame.tabs.people = GCM.CreatePeopleTab(contentFrame)
    
    -- Map Tab
    GCM.MainFrame.tabs.map = GCM.CreateMapTab(contentFrame)
    
    -- Staff Tab
    GCM.MainFrame.tabs.staff = GCM.CreateStaffTab(contentFrame)
    
    -- GJLE Tab
    GCM.MainFrame.tabs.gjle = GCM.CreateGJLETab(contentFrame)
    
    -- Kirin Tor Tab
    GCM.MainFrame.tabs.kirintor = GCM.CreateKirinTorTab(contentFrame)
    
    -- About Tab
    GCM.MainFrame.tabs.about = GCM.CreateAboutTab(contentFrame)
end

-- Initialize delete confirmation dialog
function GCM.InitializeDeleteDialog()
    StaticPopupDialogs["GCM_CONFIRM_DELETE"] = {
        text = "Delete this case permanently?",
        button1 = "Delete",
        button2 = "Cancel",
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,  -- Avoids taint issues
        showAlert = true,    -- Shows as red alert
        OnAccept = function(self, data)
            if data and data.caseId then
                GCM.DeleteCase(data.caseId)
                -- Refresh the cases tab if it's currently active
                if GCM.MainFrame and GCM.MainFrame.tabs and GCM.MainFrame.tabs.cases and GCM.MainFrame.tabs.cases:IsShown() then
                    GCM.RefreshCasesTab()
                end
                -- Also refresh the old cases frame if it exists and is shown
                if GCM.CasesFrame and GCM.CasesFrame:IsShown() then
                    GCM.RefreshCasesList()
                end
            end
        end,
        OnCancel = function() end
    }
    
    StaticPopupDialogs["GCM_CONFIRM_DELETE_PERSON"] = {
        text = "Delete this person record permanently?",
        button1 = "Delete",
        button2 = "Cancel",
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
        showAlert = true,
        OnAccept = function(self, data)
            if data and data.personId then
                GCM.DeletePerson(data.personId)
                -- Refresh the people tab if it's currently active
                if GCM.MainFrame and GCM.MainFrame.tabs and GCM.MainFrame.tabs.people and GCM.MainFrame.tabs.people:IsShown() then
                    GCM.RefreshPeopleTab()
                end
                -- Also refresh the old people frame if it exists and is shown
                if GCM.PeopleFrame and GCM.PeopleFrame:IsShown() then
                    GCM.RefreshPeopleList()
                end
            end
        end,
        OnCancel = function() end
    }
end

-- Call this in your initialization
GCM.InitializeDeleteDialog()

------------------------------------------------------------------------------

-- Cases Management Frame
function GCM.ShowCasesFrame()
    -- Hide Main Frame
    if GCM.MainFrame then GCM.MainFrame:Hide() end
    
    -- Create Cases Frame if it doesn't exist
    if not GCM.CasesFrame then
        GCM.CasesFrame = CreateFrame("Frame", "GCM_CasesFrame", UIParent, "BasicFrameTemplate")
        GCM.CasesFrame:SetSize(600, 500)
        GCM.CasesFrame:SetPoint("CENTER")
        GCM.CasesFrame:SetMovable(true)
        GCM.CasesFrame:SetResizable(true)
        GCM.CasesFrame:EnableMouse(true)
        GCM.CasesFrame:RegisterForDrag("LeftButton")
        GCM.CasesFrame:SetScript("OnDragStart", GCM.CasesFrame.StartMoving)
        GCM.CasesFrame:SetScript("OnDragStop", GCM.CasesFrame.StopMovingOrSizing)
        
        -- Add resize grip
        local resizeButton = CreateFrame("Button", nil, GCM.CasesFrame)
        resizeButton:SetSize(16, 16)
        resizeButton:SetPoint("BOTTOMRIGHT", -6, 6)
        resizeButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
        resizeButton:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
        resizeButton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
        resizeButton:SetScript("OnMouseDown", function(self, button)
            if button == "LeftButton" then
                GCM.CasesFrame:StartSizing("BOTTOMRIGHT")
            end
        end)
        resizeButton:SetScript("OnMouseUp", function(self, button)
            GCM.CasesFrame:StopMovingOrSizing()
        end)
        
        -- Title
        GCM.CasesFrame.title = GCM.CasesFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        GCM.CasesFrame.title:SetPoint("TOP", 0, -10)
        GCM.CasesFrame.title:SetText("Case Management")
        
        -- Back Button
        local backBtn = CreateFrame("Button", nil, GCM.CasesFrame, "UIPanelButtonTemplate")
        backBtn:SetSize(100, 25)
        backBtn:SetPoint("TOPLEFT", 10, -10)
        backBtn:SetText("Back")
        backBtn:SetScript("OnClick", function()
            GCM.CasesFrame:Hide()
            if GCM.MainFrame then GCM.MainFrame:Show() end
        end)
        
        -- Create New Case Button
        local newCaseBtn = CreateFrame("Button", nil, GCM.CasesFrame, "UIPanelButtonTemplate")
        newCaseBtn:SetSize(120, 30)
        newCaseBtn:SetPoint("TOPRIGHT", -10, -10)
        newCaseBtn:SetText("New Case")
        newCaseBtn:SetScript("OnClick", function()
            GCM.ShowCaseEditFrame()
        end)
        
        -- Cases List (Scrollable)
        GCM.CasesFrame.scrollFrame = CreateFrame("ScrollFrame", nil, GCM.CasesFrame, "UIPanelScrollFrameTemplate")
        GCM.CasesFrame.scrollFrame:SetPoint("TOPLEFT", 10, -50)
        GCM.CasesFrame.scrollFrame:SetPoint("BOTTOMRIGHT", -30, 50)
        
        GCM.CasesFrame.scrollChild = CreateFrame("Frame")
        GCM.CasesFrame.scrollChild:SetSize(GCM.CasesFrame.scrollFrame:GetWidth(), 0)
        GCM.CasesFrame.scrollFrame:SetScrollChild(GCM.CasesFrame.scrollChild)
    end
    
    -- Refresh Cases List
    GCM.RefreshCasesList()
    GCM.CasesFrame:Show()
end

-- Refreshes the list of cases
function GCM.RefreshCasesList()
    if not GCM.CasesFrame then return end
    
    -- Clear existing entries
    for _, child in ipairs({GCM.CasesFrame.scrollChild:GetChildren()}) do
        child:Hide()
    end
    
    -- Add cases to the list
    local yOffset = -10
    for _, case in ipairs(GCM_Database.cases) do
        local caseEntry = CreateFrame("Frame", nil, GCM.CasesFrame.scrollChild)
        caseEntry:SetSize(GCM.CasesFrame.scrollChild:GetWidth() - 20, 30)
        caseEntry:SetPoint("TOPLEFT", 10, yOffset)
        
        -- Case Title (now takes less width to make room for buttons)
        local title = caseEntry:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("LEFT")
        title:SetWidth(200) -- Reduced width
        title:SetText(case.title or "Untitled Case")
        
        -- View Button (leftmost)
        local viewBtn = CreateFrame("Button", nil, caseEntry, "UIPanelButtonTemplate")
        viewBtn:SetSize(60, 22)
        viewBtn:SetPoint("RIGHT", -190, 0) -- Adjusted position
        viewBtn:SetText("View")
        viewBtn:SetScript("OnClick", function()
            GCM.ShowCaseViewFrame(case)
        end)
        
        -- Edit Button (middle)
        local editBtn = CreateFrame("Button", nil, caseEntry, "UIPanelButtonTemplate")
        editBtn:SetSize(60, 22)
        editBtn:SetPoint("RIGHT", -120, 0) -- Adjusted position
        editBtn:SetText("Edit")
        editBtn:SetScript("OnClick", function()
            GCM.ShowCaseEditFrame(case)
        end)
        
        -- Delete Button (rightmost)
        local deleteBtn = CreateFrame("Button", nil, caseEntry, "UIPanelButtonTemplate")
        deleteBtn:SetSize(60, 22)
        deleteBtn:SetPoint("RIGHT", -50, 0) -- Adjusted position
        deleteBtn:SetText("Delete")
        deleteBtn:SetNormalFontObject("GameFontRed")
        deleteBtn:SetScript("OnClick", function()
            StaticPopup_Show("GCM_CONFIRM_DELETE", nil, nil, {caseId = case.id})
        end)
        
        yOffset = yOffset - 35
    end
    
    -- Adjust scroll height
    GCM.CasesFrame.scrollChild:SetHeight(math.abs(yOffset) + 10)
end

-- Case View Frame (Read-only)
function GCM.ShowCaseViewFrame(caseData)
    -- Hide other frames
    if GCM.CasesFrame then GCM.CasesFrame:Hide() end
    
    -- Create View Frame if it doesn't exist
    if not GCM.CaseViewFrame then
        GCM.CaseViewFrame = CreateFrame("Frame", "GCM_CaseViewFrame", UIParent, "BasicFrameTemplate")
        GCM.CaseViewFrame:SetSize(500, 400)
        GCM.CaseViewFrame:SetPoint("CENTER")
        
        -- Back Button
        local backBtn = CreateFrame("Button", nil, GCM.CaseViewFrame, "UIPanelButtonTemplate")
        backBtn:SetSize(100, 25)
        backBtn:SetPoint("TOPLEFT", 10, -10)
        backBtn:SetText("Back")
        backBtn:SetScript("OnClick", function()
            GCM.CaseViewFrame:Hide()
            if GCM.CasesFrame then GCM.CasesFrame:Show() end
        end)
        
        -- Case Content Area
        GCM.CaseViewFrame.scrollFrame = CreateFrame("ScrollFrame", nil, GCM.CaseViewFrame, "UIPanelScrollFrameTemplate")
        GCM.CaseViewFrame.scrollFrame:SetPoint("TOPLEFT", 10, -40)
        GCM.CaseViewFrame.scrollFrame:SetPoint("BOTTOMRIGHT", -30, 40)
        
        GCM.CaseViewFrame.scrollChild = CreateFrame("Frame")
        GCM.CaseViewFrame.scrollChild:SetSize(GCM.CaseViewFrame.scrollFrame:GetWidth(), 0)
        GCM.CaseViewFrame.scrollFrame:SetScrollChild(GCM.CaseViewFrame.scrollChild)
        
        -- Case Fields
        GCM.CaseViewFrame.titleText = GCM.CaseViewFrame.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        GCM.CaseViewFrame.titleText:SetPoint("TOPLEFT", 10, -10)
        GCM.CaseViewFrame.titleText:SetWidth(GCM.CaseViewFrame.scrollChild:GetWidth() - 20)
        
        GCM.CaseViewFrame.detailsText = GCM.CaseViewFrame.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        GCM.CaseViewFrame.detailsText:SetPoint("TOPLEFT", 10, -50)
        GCM.CaseViewFrame.detailsText:SetWidth(GCM.CaseViewFrame.scrollChild:GetWidth() - 20)
        GCM.CaseViewFrame.detailsText:SetJustifyH("LEFT")
        GCM.CaseViewFrame.detailsText:SetJustifyV("TOP")
    end
    
    -- Populate case data
    GCM.CaseViewFrame.titleText:SetText(caseData.title or "Untitled Case")
    
    local function CreateDetailLine(label, value)
        return string.format("|cff00ccff%s:|r %s", label, value or "N/A")
    end

    local details = {
        CreateDetailLine("Created By", caseData.createdBy),
        CreateDetailLine("Date", caseData.createdAt),
        "\n" .. CreateDetailLine("Case Type", caseData.caseType),
        CreateDetailLine("Priority", caseData.priority),
        CreateDetailLine("Status", caseData.status),
        "\n" .. CreateDetailLine("Location", caseData.location),
        CreateDetailLine("Assigned Detective", caseData.assignedTo),
        CreateDetailLine("Client/Requester", caseData.client),
        CreateDetailLine("Incident Date", caseData.incidentDate),
        "\n" .. CreateDetailLine("Related Cases", caseData.relatedCases),
        "\n|cff00ccffDescription:|r\n" .. (caseData.description or ""),
        "\n|cff00ccffSuspects:|r\n" .. (caseData.suspects or ""),
        "\n|cff00ccffLeads:|r\n" .. (caseData.leads or ""),
        "\n|cff00ccffWitnesses:|r\n" .. (caseData.witnesses or ""),
        "\n|cff00ccffEvidence Chain of Custody:|r\n" .. (caseData.evidenceChain or ""),
        "\n|cff00ccffInterview Notes:|r\n" .. (caseData.interviewNotes or ""),
        "\n|cff00ccffCase Notes:|r\n" .. (caseData.caseNotes or ""),
        "\n|cff00ccffNext Steps:|r\n" .. (caseData.nextSteps or ""),
    }

    GCM.CaseViewFrame.detailsText:SetText(table.concat(details, "\n"))
    
    -- Adjust scroll height
    GCM.CaseViewFrame.scrollChild:SetHeight(GCM.CaseViewFrame.detailsText:GetStringHeight() + 100)
    
    GCM.CaseViewFrame:Show()
end

-- Case Edit Frame (Create/Edit)
function GCM.ShowCaseEditFrame(caseData)
    -- Hide other frames
    if GCM.CasesFrame then GCM.CasesFrame:Hide() end
    
    -- Create Edit Frame if it doesn't exist
    if not GCM.CaseEditFrame then
        GCM.CaseEditFrame = CreateFrame("Frame", "GCM_CaseEditFrame", UIParent, "BasicFrameTemplate")
        GCM.CaseEditFrame:SetSize(600, 650)
        GCM.CaseEditFrame:SetPoint("CENTER")
        
        -- Back Button
        local backBtn = CreateFrame("Button", nil, GCM.CaseEditFrame, "UIPanelButtonTemplate")
        backBtn:SetSize(100, 25)
        backBtn:SetPoint("TOPLEFT", 10, -10)
        backBtn:SetText("Cancel")
        backBtn:SetScript("OnClick", function()
            GCM.CaseEditFrame:Hide()
            if GCM.CasesFrame then GCM.CasesFrame:Show() end
        end)
        
        -- Save Button
        local saveBtn = CreateFrame("Button", nil, GCM.CaseEditFrame, "UIPanelButtonTemplate")
        saveBtn:SetSize(100, 25)
        saveBtn:SetPoint("TOPRIGHT", -10, -10)
        saveBtn:SetText("Save")
        saveBtn:SetScript("OnClick", function() GCM.SaveCurrentCase() end)
        
        -- Scroll Frame
        GCM.CaseEditFrame.scrollFrame = CreateFrame("ScrollFrame", nil, GCM.CaseEditFrame, "UIPanelScrollFrameTemplate")
        GCM.CaseEditFrame.scrollFrame:SetPoint("TOPLEFT", 10, -40)
        GCM.CaseEditFrame.scrollFrame:SetPoint("BOTTOMRIGHT", -30, 40)
        
        local scrollChild = CreateFrame("Frame")
        scrollChild:SetSize(GCM.CaseEditFrame.scrollFrame:GetWidth(), 1200) -- Increased height
        GCM.CaseEditFrame.scrollChild = scrollChild
        GCM.CaseEditFrame.scrollFrame:SetScrollChild(scrollChild)

        local yOffset = -10

        -- Helper to create an input field
        local function CreateInputField(label, width, height, isMultiLine)
            local labelStr = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            labelStr:SetPoint("TOPLEFT", 10, yOffset)
            labelStr:SetText(label)
            yOffset = yOffset - 20

            local editBox = CreateFrame("EditBox", nil, scrollChild, "InputBoxTemplate")
            editBox:SetSize(width, height)
            editBox:SetPoint("TOPLEFT", 10, yOffset)
            editBox:SetAutoFocus(false)
            editBox:SetFontObject("GameFontHighlight")
            if isMultiLine then
                editBox:SetMultiLine(true)
            end
            yOffset = yOffset - height - 10
            return editBox
        end

        -- Create all the new fields
        GCM.CaseEditFrame.titleInput = CreateInputField("Case Title:", 520, 24)
        GCM.CaseEditFrame.descriptionInput = CreateInputField("Description:", 520, 150, true)
        GCM.CaseEditFrame.caseTypeInput = CreateInputField("Case Type/Category:", 250, 24)
        GCM.CaseEditFrame.priorityInput = CreateInputField("Priority Level:", 250, 24)
        GCM.CaseEditFrame.statusInput = CreateInputField("Case Status:", 250, 24)
        GCM.CaseEditFrame.locationInput = CreateInputField("Location/Scene:", 520, 24)
        GCM.CaseEditFrame.assignedToInput = CreateInputField("Assigned Detective:", 250, 24)
        GCM.CaseEditFrame.clientInput = CreateInputField("Client/Requester:", 250, 24)
        GCM.CaseEditFrame.incidentDateInput = CreateInputField("Date of Incident:", 250, 24)
        GCM.CaseEditFrame.relatedCasesInput = CreateInputField("Related Cases:", 520, 24)
        GCM.CaseEditFrame.suspectsInput = CreateInputField("Suspects:", 520, 60, true)
        GCM.CaseEditFrame.leadsInput = CreateInputField("Leads:", 520, 60, true)
        GCM.CaseEditFrame.witnessesInput = CreateInputField("Witnesses:", 520, 60, true)
        GCM.CaseEditFrame.evidenceChainInput = CreateInputField("Evidence Chain of Custody:", 520, 80, true)
        GCM.CaseEditFrame.interviewNotesInput = CreateInputField("Interview Notes:", 520, 180, true)
        GCM.CaseEditFrame.caseNotesInput = CreateInputField("Case Notes/Updates:", 520, 120, true)
        GCM.CaseEditFrame.nextStepsInput = CreateInputField("Next Steps/Action Items:", 520, 120, true)
    end
    
    -- Populate fields
    local case = caseData or {}
    GCM.CaseEditFrame.editingCaseID = case.id
    GCM.CaseEditFrame.titleInput:SetText(case.title or "")
    GCM.CaseEditFrame.descriptionInput:SetText(case.description or "")
    GCM.CaseEditFrame.caseTypeInput:SetText(case.caseType or "")
    GCM.CaseEditFrame.priorityInput:SetText(case.priority or "")
    GCM.CaseEditFrame.statusInput:SetText(case.status or "")
    GCM.CaseEditFrame.locationInput:SetText(case.location or "")
    GCM.CaseEditFrame.assignedToInput:SetText(case.assignedTo or "")
    GCM.CaseEditFrame.clientInput:SetText(case.client or "")
    GCM.CaseEditFrame.incidentDateInput:SetText(case.incidentDate or "")
    GCM.CaseEditFrame.relatedCasesInput:SetText(case.relatedCases or "")
    GCM.CaseEditFrame.suspectsInput:SetText(case.suspects or "")
    GCM.CaseEditFrame.leadsInput:SetText(case.leads or "")
    GCM.CaseEditFrame.witnessesInput:SetText(case.witnesses or "")
    GCM.CaseEditFrame.evidenceChainInput:SetText(case.evidenceChain or "")
    GCM.CaseEditFrame.interviewNotesInput:SetText(case.interviewNotes or "")
    GCM.CaseEditFrame.caseNotesInput:SetText(case.caseNotes or "")
    GCM.CaseEditFrame.nextStepsInput:SetText(case.nextSteps or "")
    
    GCM.CaseEditFrame:Show()
end


-- Save case from edit frame
function GCM.SaveCurrentCase()
    if not GCM.CaseEditFrame then return end
    
    local caseData = {
        id = GCM.CaseEditFrame.editingCaseID,
        title = GCM.CaseEditFrame.titleInput:GetText(),
        description = GCM.CaseEditFrame.descriptionInput:GetText(),
        caseType = GCM.CaseEditFrame.caseTypeInput:GetText(),
        priority = GCM.CaseEditFrame.priorityInput:GetText(),
        status = GCM.CaseEditFrame.statusInput:GetText(),
        location = GCM.CaseEditFrame.locationInput:GetText(),
        assignedTo = GCM.CaseEditFrame.assignedToInput:GetText(),
        client = GCM.CaseEditFrame.clientInput:GetText(),
        incidentDate = GCM.CaseEditFrame.incidentDateInput:GetText(),
        relatedCases = GCM.CaseEditFrame.relatedCasesInput:GetText(),
        suspects = GCM.CaseEditFrame.suspectsInput:GetText(),
        leads = GCM.CaseEditFrame.leadsInput:GetText(),
        witnesses = GCM.CaseEditFrame.witnessesInput:GetText(),
        evidenceChain = GCM.CaseEditFrame.evidenceChainInput:GetText(),
        interviewNotes = GCM.CaseEditFrame.interviewNotesInput:GetText(),
        caseNotes = GCM.CaseEditFrame.caseNotesInput:GetText(),
        nextSteps = GCM.CaseEditFrame.nextStepsInput:GetText()
    }
    
    -- Add creation metadata if this is a new case
    if not GCM.CaseEditFrame.editingCaseID then
        caseData.createdBy = UnitName("player")
        caseData.createdAt = date("%Y-%m-%d %H:%M:%S")
    end
    
    GCM.SaveCase(caseData)
    GCM.CaseEditFrame:Hide()
    GCM.ShowCasesFrame()
end

-----------------PEOPLE BUTTON-----------------------

function GCM.ShowPeopleFrame()
    -- Hide Main Frame
    if GCM.MainFrame then GCM.MainFrame:Hide() end
    
    -- Create People Frame if it doesn't exist
    if not GCM.PeopleFrame then
        GCM.PeopleFrame = CreateFrame("Frame", "GCM_PeopleFrame", UIParent, "BasicFrameTemplate")
        GCM.PeopleFrame:SetSize(600, 500)
        GCM.PeopleFrame:SetPoint("CENTER")
        GCM.PeopleFrame:SetMovable(true)
        GCM.PeopleFrame:SetResizable(true)
        GCM.PeopleFrame:EnableMouse(true)
        GCM.PeopleFrame:RegisterForDrag("LeftButton")
        GCM.PeopleFrame:SetScript("OnDragStart", GCM.PeopleFrame.StartMoving)
        GCM.PeopleFrame:SetScript("OnDragStop", GCM.PeopleFrame.StopMovingOrSizing)
        
        -- Add resize grip
        local resizeButton = CreateFrame("Button", nil, GCM.PeopleFrame)
        resizeButton:SetSize(16, 16)
        resizeButton:SetPoint("BOTTOMRIGHT", -6, 6)
        resizeButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
        resizeButton:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
        resizeButton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
        resizeButton:SetScript("OnMouseDown", function(self, button)
            if button == "LeftButton" then
                GCM.PeopleFrame:StartSizing("BOTTOMRIGHT")
            end
        end)
        resizeButton:SetScript("OnMouseUp", function(self, button)
            GCM.PeopleFrame:StopMovingOrSizing()
        end)
        
        -- Title
        GCM.PeopleFrame.title = GCM.PeopleFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        GCM.PeopleFrame.title:SetPoint("TOP", 0, -10)
        GCM.PeopleFrame.title:SetText("People Management")
        
        -- Back Button
        local backBtn = CreateFrame("Button", nil, GCM.PeopleFrame, "UIPanelButtonTemplate")
        backBtn:SetSize(100, 25)
        backBtn:SetPoint("TOPLEFT", 10, -10)
        backBtn:SetText("Back")
        backBtn:SetScript("OnClick", function()
            GCM.PeopleFrame:Hide()
            if GCM.MainFrame then GCM.MainFrame:Show() end
        end)
        
        -- Add New Person Button
        local newPersonBtn = CreateFrame("Button", nil, GCM.PeopleFrame, "UIPanelButtonTemplate")
        newPersonBtn:SetSize(120, 30)
        newPersonBtn:SetPoint("TOPRIGHT", -10, -10)
        newPersonBtn:SetText("Add Person")
        newPersonBtn:SetScript("OnClick", function()
            GCM.ShowPersonEditFrame()
        end)
        
        -- People List (Scrollable)
        GCM.PeopleFrame.scrollFrame = CreateFrame("ScrollFrame", nil, GCM.PeopleFrame, "UIPanelScrollFrameTemplate")
        GCM.PeopleFrame.scrollFrame:SetPoint("TOPLEFT", 10, -50)
        GCM.PeopleFrame.scrollFrame:SetPoint("BOTTOMRIGHT", -30, 50)
        
        GCM.PeopleFrame.scrollChild = CreateFrame("Frame")
        GCM.PeopleFrame.scrollChild:SetSize(GCM.PeopleFrame.scrollFrame:GetWidth(), 0)
        GCM.PeopleFrame.scrollFrame:SetScrollChild(GCM.PeopleFrame.scrollChild)
    end
    
    -- Refresh People List
    GCM.RefreshPeopleList()
    GCM.PeopleFrame:Show()
end

function GCM.RefreshPeopleList()
    if not GCM.PeopleFrame then return end
    
    -- Clear existing entries
    for _, child in ipairs({GCM.PeopleFrame.scrollChild:GetChildren()}) do
        child:Hide()
    end
    
    -- Add people to the list
    local yOffset = -10
    for _, person in ipairs(GCM_Database.people or {}) do
        local personEntry = CreateFrame("Frame", nil, GCM.PeopleFrame.scrollChild)
        personEntry:SetSize(GCM.PeopleFrame.scrollChild:GetWidth() - 20, 30)
        personEntry:SetPoint("TOPLEFT", 10, yOffset)
        
        -- Person Name
        local name = personEntry:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        name:SetPoint("LEFT")
        name:SetWidth(200)
        name:SetText(person.name or "Unknown")
        
        -- View Button
        local viewBtn = CreateFrame("Button", nil, personEntry, "UIPanelButtonTemplate")
        viewBtn:SetSize(60, 22)
        viewBtn:SetPoint("RIGHT", -190, 0)
        viewBtn:SetText("View")
        viewBtn:SetScript("OnClick", function()
            GCM.ShowPersonViewFrame(person)
        end)
        
        -- Edit Button
        local editBtn = CreateFrame("Button", nil, personEntry, "UIPanelButtonTemplate")
        editBtn:SetSize(60, 22)
        editBtn:SetPoint("RIGHT", -120, 0)
        editBtn:SetText("Edit")
        editBtn:SetScript("OnClick", function()
            GCM.ShowPersonEditFrame(person)
        end)
        
        -- Delete Button
        local deleteBtn = CreateFrame("Button", nil, personEntry, "UIPanelButtonTemplate")
        deleteBtn:SetSize(60, 22)
        deleteBtn:SetPoint("RIGHT", -50, 0)
        deleteBtn:SetText("Delete")
        deleteBtn:SetNormalFontObject("GameFontRed")
        deleteBtn:SetScript("OnClick", function()
            StaticPopup_Show("GCM_CONFIRM_DELETE_PERSON", nil, nil, {personId = person.id})
        end)
        
        yOffset = yOffset - 35
    end
    
    -- Adjust scroll height
    GCM.PeopleFrame.scrollChild:SetHeight(math.abs(yOffset) + 10)
end

function GCM.ShowPersonViewFrame(personData)
    if GCM.PeopleFrame then GCM.PeopleFrame:Hide() end
    
    if not GCM.PersonViewFrame then
        GCM.PersonViewFrame = CreateFrame("Frame", "GCM_PersonViewFrame", UIParent, "BasicFrameTemplate")
        GCM.PersonViewFrame:SetSize(500, 400)
        GCM.PersonViewFrame:SetPoint("CENTER")
        
        -- Back Button
        local backBtn = CreateFrame("Button", nil, GCM.PersonViewFrame, "UIPanelButtonTemplate")
        backBtn:SetSize(100, 25)
        backBtn:SetPoint("TOPLEFT", 10, -10)
        backBtn:SetText("Back")
        backBtn:SetScript("OnClick", function()
            GCM.PersonViewFrame:Hide()
            if GCM.PeopleFrame then GCM.PeopleFrame:Show() end
        end)
        
        -- Scroll Frame
        GCM.PersonViewFrame.scrollFrame = CreateFrame("ScrollFrame", nil, GCM.PersonViewFrame, "UIPanelScrollFrameTemplate")
        GCM.PersonViewFrame.scrollFrame:SetPoint("TOPLEFT", 10, -40)
        GCM.PersonViewFrame.scrollFrame:SetPoint("BOTTOMRIGHT", -30, 40)
        
        GCM.PersonViewFrame.scrollChild = CreateFrame("Frame")
        GCM.PersonViewFrame.scrollChild:SetSize(GCM.PersonViewFrame.scrollFrame:GetWidth(), 0)
        GCM.PersonViewFrame.scrollFrame:SetScrollChild(GCM.PersonViewFrame.scrollChild)
        
        -- Title
        GCM.PersonViewFrame.titleText = GCM.PersonViewFrame.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        GCM.PersonViewFrame.titleText:SetPoint("TOPLEFT", 10, -10)
        GCM.PersonViewFrame.titleText:SetWidth(GCM.PersonViewFrame.scrollChild:GetWidth() - 20)
        
        -- Details
        GCM.PersonViewFrame.detailsText = GCM.PersonViewFrame.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        GCM.PersonViewFrame.detailsText:SetPoint("TOPLEFT", 10, -50)
        GCM.PersonViewFrame.detailsText:SetWidth(GCM.PersonViewFrame.scrollChild:GetWidth() - 20)
        GCM.PersonViewFrame.detailsText:SetJustifyH("LEFT")
        GCM.PersonViewFrame.detailsText:SetJustifyV("TOP")
    end
    
    -- Populate data
    GCM.PersonViewFrame.titleText:SetText(personData.name or "Unknown Person")
    
    local function CreateDetailLine(label, value)
        return string.format("|cff00ccff%s:|r %s", label, value or "N/A")
    end

    local details = {
        -- Basic Information
        CreateDetailLine("Race", personData.race),
        CreateDetailLine("Gender", personData.gender),
        CreateDetailLine("Age", personData.age),
        CreateDetailLine("Occupation", personData.occupation),
        "\n" .. CreateDetailLine("Aliases/Known Names", personData.aliases),
        CreateDetailLine("Last Known Address", personData.address),
        CreateDetailLine("Contact Information", personData.contact),
        "\n" .. CreateDetailLine("Relationship Status", personData.relationshipStatus),
        CreateDetailLine("Threat Level", personData.threatLevel),
        CreateDetailLine("Vehicle Information", personData.vehicle),
        "\n" .. CreateDetailLine("Last Seen Location", personData.lastSeenLocation),
        CreateDetailLine("Last Seen Date", personData.lastSeenDate),
        "\n" .. CreateDetailLine("Photo/Mugshot URL", personData.photoUrl),
        "\n|cff00ccffPhysical Description:|r\n" .. (personData.physicalDesc or "None"),
        "\n|cff00ccffDistinguishing Marks/Tattoos/Scars:|r\n" .. (personData.distinguishingMarks or "None"),
        "\n|cff00ccffCriminal History:|r\n" .. (personData.criminalHistory or "None"),
        "\n|cff00ccffBehavioral Notes:|r\n" .. (personData.behavioralNotes or "None"),
        "\n|cff00ccffKnown Associates:|r\n" .. (personData.associates or "None"),
        "\n|cff00ccffEvidence Connected To:|r\n" .. (personData.evidenceConnected or "None"),
        "\n|cff00ccffAdditional Notes:|r\n" .. (personData.notes or "None"),
        "\n|cff00ccffLast Updated:|r " .. (personData.updated or "Unknown")
    }
    
    local detailsText = table.concat(details, "\n")
    GCM.PersonViewFrame.detailsText:SetText(detailsText)
    
    -- Adjust scroll height
    GCM.PersonViewFrame.scrollChild:SetHeight(GCM.PersonViewFrame.detailsText:GetStringHeight() + 100)
    
    GCM.PersonViewFrame:Show()
end

function GCM.ShowPersonEditFrame(personData)
    if GCM.PeopleFrame then GCM.PeopleFrame:Hide() end
    
    if not GCM.PersonEditFrame then
        GCM.PersonEditFrame = CreateFrame("Frame", "GCM_PersonEditFrame", UIParent, "BasicFrameTemplate")
        GCM.PersonEditFrame:SetSize(600, 700)
        GCM.PersonEditFrame:SetPoint("CENTER")
        
        -- Back Button
        local backBtn = CreateFrame("Button", nil, GCM.PersonEditFrame, "UIPanelButtonTemplate")
        backBtn:SetSize(100, 25)
        backBtn:SetPoint("TOPLEFT", 10, -10)
        backBtn:SetText("Cancel")
        backBtn:SetScript("OnClick", function()
            GCM.PersonEditFrame:Hide()
            if GCM.PeopleFrame then GCM.PeopleFrame:Show() end
        end)
        
        -- Save Button
        local saveBtn = CreateFrame("Button", nil, GCM.PersonEditFrame, "UIPanelButtonTemplate")
        saveBtn:SetSize(100, 25)
        saveBtn:SetPoint("TOPRIGHT", -10, -10)
        saveBtn:SetText("Save")
        saveBtn:SetScript("OnClick", function() GCM.SaveCurrentPerson() end)
        
        -- Scroll Frame
        GCM.PersonEditFrame.scrollFrame = CreateFrame("ScrollFrame", nil, GCM.PersonEditFrame, "UIPanelScrollFrameTemplate")
        GCM.PersonEditFrame.scrollFrame:SetPoint("TOPLEFT", 10, -40)
        GCM.PersonEditFrame.scrollFrame:SetPoint("BOTTOMRIGHT", -30, 40)
        
        local scrollChild = CreateFrame("Frame")
        scrollChild:SetSize(GCM.PersonEditFrame.scrollFrame:GetWidth(), 1500) -- Increased height
        GCM.PersonEditFrame.scrollChild = scrollChild
        GCM.PersonEditFrame.scrollFrame:SetScrollChild(scrollChild)

        local yOffset = -10

        -- Helper to create an input field with proper spacing
        local function CreateInputField(label, width, height, isMultiLine)
            local labelStr = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            labelStr:SetPoint("TOPLEFT", 10, yOffset)
            labelStr:SetText(label)
            yOffset = yOffset - 18 -- Consistent label spacing

            local editBox = CreateFrame("EditBox", nil, scrollChild, "InputBoxTemplate")
            editBox:SetSize(width, height)
            editBox:SetPoint("TOPLEFT", 10, yOffset)
            editBox:SetAutoFocus(false)
            editBox:SetFontObject("GameFontHighlight")
            if isMultiLine then
                editBox:SetMultiLine(true)
            end
            yOffset = yOffset - height - 15 -- Consistent field spacing
            return editBox
        end

        -- Create all the new fields
        GCM.PersonEditFrame.nameInput = CreateInputField("Name:", 250, 24)
        GCM.PersonEditFrame.raceInput = CreateInputField("Race:", 250, 24)
        GCM.PersonEditFrame.genderInput = CreateInputField("Gender:", 250, 24)
        GCM.PersonEditFrame.ageInput = CreateInputField("Age:", 250, 24)
        GCM.PersonEditFrame.occupationInput = CreateInputField("Occupation:", 250, 24)
        GCM.PersonEditFrame.aliasesInput = CreateInputField("Aliases/Known Names:", 520, 24)
        GCM.PersonEditFrame.addressInput = CreateInputField("Last Known Address:", 520, 24)
        GCM.PersonEditFrame.contactInput = CreateInputField("Phone/Contact Information:", 520, 24)
        GCM.PersonEditFrame.relationshipStatusInput = CreateInputField("Relationship Status:", 250, 24)
        GCM.PersonEditFrame.threatLevelInput = CreateInputField("Threat Level:", 250, 24)
        GCM.PersonEditFrame.vehicleInput = CreateInputField("Vehicle Information:", 520, 24)
        GCM.PersonEditFrame.lastSeenLocationInput = CreateInputField("Last Seen Location:", 250, 24)
        GCM.PersonEditFrame.lastSeenDateInput = CreateInputField("Last Seen Date:", 250, 24)
        GCM.PersonEditFrame.photoUrlInput = CreateInputField("Photo/Mugshot URL:", 520, 24)
        GCM.PersonEditFrame.physicalDescInput = CreateInputField("Physical Description:", 520, 100, true)
        GCM.PersonEditFrame.distinguishingMarksInput = CreateInputField("Distinguishing Marks/Tattoos/Scars:", 520, 80, true)
        GCM.PersonEditFrame.criminalHistoryInput = CreateInputField("Criminal History:", 520, 100, true)
        GCM.PersonEditFrame.behavioralNotesInput = CreateInputField("Behavioral Notes:", 520, 120, true)
        GCM.PersonEditFrame.associatesInput = CreateInputField("Known Associates:", 520, 80, true)
        GCM.PersonEditFrame.evidenceConnectedInput = CreateInputField("Evidence Connected To:", 520, 80, true)
        GCM.PersonEditFrame.notesInput = CreateInputField("Additional Notes:", 520, 100, true)
    end
    
    -- Populate fields if editing
    local person = personData or {}
    GCM.PersonEditFrame.editingPersonID = person.id
    GCM.PersonEditFrame.nameInput:SetText(person.name or "")
    GCM.PersonEditFrame.raceInput:SetText(person.race or "")
    GCM.PersonEditFrame.genderInput:SetText(person.gender or "")
    GCM.PersonEditFrame.ageInput:SetText(person.age or "")
    GCM.PersonEditFrame.occupationInput:SetText(person.occupation or "")
    GCM.PersonEditFrame.aliasesInput:SetText(person.aliases or "")
    GCM.PersonEditFrame.addressInput:SetText(person.address or "")
    GCM.PersonEditFrame.contactInput:SetText(person.contact or "")
    GCM.PersonEditFrame.relationshipStatusInput:SetText(person.relationshipStatus or "")
    GCM.PersonEditFrame.threatLevelInput:SetText(person.threatLevel or "")
    GCM.PersonEditFrame.vehicleInput:SetText(person.vehicle or "")
    GCM.PersonEditFrame.lastSeenLocationInput:SetText(person.lastSeenLocation or "")
    GCM.PersonEditFrame.lastSeenDateInput:SetText(person.lastSeenDate or "")
    GCM.PersonEditFrame.photoUrlInput:SetText(person.photoUrl or "")
    GCM.PersonEditFrame.physicalDescInput:SetText(person.physicalDesc or "")
    GCM.PersonEditFrame.distinguishingMarksInput:SetText(person.distinguishingMarks or "")
    GCM.PersonEditFrame.criminalHistoryInput:SetText(person.criminalHistory or "")
    GCM.PersonEditFrame.behavioralNotesInput:SetText(person.behavioralNotes or "")
    GCM.PersonEditFrame.associatesInput:SetText(person.associates or "")
    GCM.PersonEditFrame.evidenceConnectedInput:SetText(person.evidenceConnected or "")
    GCM.PersonEditFrame.notesInput:SetText(person.notes or "")
    
    GCM.PersonEditFrame:Show()
end

function GCM.SaveCurrentPerson()
    if not GCM.PersonEditFrame then return end
    
    local personData = {
        id = GCM.PersonEditFrame.editingPersonID,
        name = GCM.PersonEditFrame.nameInput:GetText(),
        race = GCM.PersonEditFrame.raceInput:GetText(),
        gender = GCM.PersonEditFrame.genderInput:GetText(),
        age = GCM.PersonEditFrame.ageInput:GetText(),
        occupation = GCM.PersonEditFrame.occupationInput:GetText(),
        aliases = GCM.PersonEditFrame.aliasesInput:GetText(),
        address = GCM.PersonEditFrame.addressInput:GetText(),
        contact = GCM.PersonEditFrame.contactInput:GetText(),
        relationshipStatus = GCM.PersonEditFrame.relationshipStatusInput:GetText(),
        threatLevel = GCM.PersonEditFrame.threatLevelInput:GetText(),
        vehicle = GCM.PersonEditFrame.vehicleInput:GetText(),
        lastSeenLocation = GCM.PersonEditFrame.lastSeenLocationInput:GetText(),
        lastSeenDate = GCM.PersonEditFrame.lastSeenDateInput:GetText(),
        photoUrl = GCM.PersonEditFrame.photoUrlInput:GetText(),
        physicalDesc = GCM.PersonEditFrame.physicalDescInput:GetText(),
        distinguishingMarks = GCM.PersonEditFrame.distinguishingMarksInput:GetText(),
        criminalHistory = GCM.PersonEditFrame.criminalHistoryInput:GetText(),
        behavioralNotes = GCM.PersonEditFrame.behavioralNotesInput:GetText(),
        associates = GCM.PersonEditFrame.associatesInput:GetText(),
        evidenceConnected = GCM.PersonEditFrame.evidenceConnectedInput:GetText(),
        notes = GCM.PersonEditFrame.notesInput:GetText(),
        updated = date("%Y-%m-%d %H:%M:%S")
    }
    
    -- Use the core save function which handles sync and creation metadata
    GCM.SavePerson(personData)
    
    GCM.PersonEditFrame:Hide()
    GCM.ShowPeopleFrame()
end

---------------------------------MAP BUTTON------------------------------------------------------

function GCM.ShowMapFrame()
    GCM.MainFrame:Hide()
    
    if not GCM.MapFrame then
        GCM.MapFrame = CreateFrame("Frame", "GCM_MapFrame", UIParent, "BasicFrameTemplate")
        GCM.MapFrame:SetSize(600, 500)
        GCM.MapFrame:SetPoint("CENTER")
        GCM.MapFrame:SetMovable(true)
        GCM.MapFrame:SetResizable(true)
        GCM.MapFrame:EnableMouse(true)
        GCM.MapFrame:RegisterForDrag("LeftButton")
        GCM.MapFrame:SetScript("OnDragStart", GCM.MapFrame.StartMoving)
        GCM.MapFrame:SetScript("OnDragStop", GCM.MapFrame.StopMovingOrSizing)
        GCM.MapFrame:SetScript("OnSizeChanged", function(self)
            -- Adjust map container size when window resizes
            if GCM.MapFrame.mapContainer then
                GCM.MapFrame.mapContainer:ClearAllPoints()
                GCM.MapFrame.mapContainer:SetPoint("TOPLEFT", 10, -50)
                GCM.MapFrame.mapContainer:SetPoint("BOTTOMRIGHT", -10, 60)
                
                -- Reposition markers and lines when map resizes
                GCM.RepositionMarkersOnResize()
            end
        end)
        
        -- Add resize grip
        local resizeButton = CreateFrame("Button", nil, GCM.MapFrame)
        resizeButton:SetSize(16, 16)
        resizeButton:SetPoint("BOTTOMRIGHT", -6, 6)
        resizeButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
        resizeButton:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
        resizeButton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
        resizeButton:SetScript("OnMouseDown", function(self, button)
            if button == "LeftButton" then
                GCM.MapFrame:StartSizing("BOTTOMRIGHT")
            end
        end)
        resizeButton:SetScript("OnMouseUp", function(self, button)
            GCM.MapFrame:StopMovingOrSizing()
        end)
        
        -- Title
        GCM.MapFrame.title = GCM.MapFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        GCM.MapFrame.title:SetPoint("TOP", 0, -10)
        GCM.MapFrame.title:SetText("Map Markers")
        
        -- Back Button
        local backBtn = CreateFrame("Button", nil, GCM.MapFrame, "UIPanelButtonTemplate")
        backBtn:SetSize(100, 25)
        backBtn:SetPoint("TOPLEFT", 10, -10)
        backBtn:SetText("Back")
        backBtn:SetScript("OnClick", function()
            GCM.MapFrame:Hide()
            GCM.MainFrame:Show()
        end)
        
        
        -- Toggle Lines Button
        local toggleLinesBtn = CreateFrame("Button", nil, GCM.MapFrame, "UIPanelButtonTemplate")
        toggleLinesBtn:SetSize(100, 25)
        toggleLinesBtn:SetPoint("TOPRIGHT", -10, -10)
        toggleLinesBtn:SetText("Connect Dots")
        toggleLinesBtn:SetScript("OnClick", function()
            GCM.ToggleMarkerLines()
        end)
        GCM.MapFrame.toggleLinesBtn = toggleLinesBtn
        
        -- Legend Button
        local legendBtn = CreateFrame("Button", nil, GCM.MapFrame, "UIPanelButtonTemplate")
        legendBtn:SetSize(100, 25)
        legendBtn:SetPoint("TOPRIGHT", -230, -10)
        legendBtn:SetText("Color Legend")
        legendBtn:SetScript("OnClick", function()
            GCM.ShowColorLegend()
        end)
        
        -- Clear Markers Button
        local clearBtn = CreateFrame("Button", nil, GCM.MapFrame, "UIPanelButtonTemplate")
        clearBtn:SetSize(100, 25)
        clearBtn:SetPoint("TOPRIGHT", -120, -10)
        clearBtn:SetText("Clear All")
        clearBtn:SetScript("OnClick", function()
            GCM.ClearAllMarkers()
        end)
        
        -- Map Container
        local mapContainer = CreateFrame("Frame", nil, GCM.MapFrame, "BackdropTemplate")
        mapContainer:SetPoint("TOPLEFT", 10, -50)
        mapContainer:SetPoint("BOTTOMRIGHT", -10, 60)
        mapContainer:SetBackdrop({
            bgFile = "Interface/Tooltips/UI-Tooltip-Background",
            edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        mapContainer:SetBackdropColor(0.1, 0.1, 0.3, 1)
        mapContainer:SetBackdropBorderColor(0.8, 0.8, 0.8, 1)
        
        -- Map Background (solid color for now to ensure something shows)
        local mapBG = mapContainer:CreateTexture(nil, "BACKGROUND")
        mapBG:SetAllPoints(mapContainer)
        mapBG:SetColorTexture(0.2, 0.3, 0.2, 1) -- Dark green background
        
        -- Try to load custom map, fallback to colored background
        local map = mapContainer:CreateTexture(nil, "ARTWORK")
        map:SetAllPoints(mapContainer)
        
        -- Try multiple texture paths
        local textureLoaded = false
        local texturePaths = {
            "Interface/AddOns/GuildCaseManager/media/custom_map",
            "Interface\\AddOns\\GuildCaseManager\\media\\custom_map",
            "Interface/AddOns/GuildCaseManager/media/custom_map.tga"
        }
        
        for _, path in ipairs(texturePaths) do
            map:SetTexture(path)
            if map:GetTexture() then
                textureLoaded = true
                print("Map texture loaded: " .. path)
                break
            end
        end
        
        if not textureLoaded then
            -- Fallback: create a grid pattern
            map:SetColorTexture(0.3, 0.4, 0.3, 1)
            print("Using fallback map background - custom texture not found")
        end
        
        GCM.MapFrame.map = map
        GCM.MapFrame.mapContainer = mapContainer
        
        -- Add some grid lines for visual reference
        for i = 1, 4 do
            local vLine = mapContainer:CreateTexture(nil, "OVERLAY")
            vLine:SetColorTexture(0.5, 0.5, 0.5, 0.3)
            vLine:SetSize(1, mapContainer:GetHeight())
            vLine:SetPoint("LEFT", mapContainer, "LEFT", i * mapContainer:GetWidth() / 5, 0)
            
            local hLine = mapContainer:CreateTexture(nil, "OVERLAY")
            hLine:SetColorTexture(0.5, 0.5, 0.5, 0.3)
            hLine:SetSize(mapContainer:GetWidth(), 1)
            hLine:SetPoint("TOP", mapContainer, "TOP", 0, -i * mapContainer:GetHeight() / 5)
        end
        
        -- Instructions
        local instructions = GCM.MapFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        instructions:SetPoint("BOTTOM", 0, 40)
        instructions:SetText("Right-click to add markers | Left-click markers to remove")
        instructions:SetTextColor(0.8, 0.8, 0.8, 1)
        
        -- Case Filter Dropdown for line connections (moved to bottom)
        local caseFilterLabel = GCM.MapFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        caseFilterLabel:SetPoint("BOTTOMLEFT", 20, 20)
        caseFilterLabel:SetText("Connect lines for:")
        
        local caseFilterDropdown = CreateFrame("Frame", "GCM_MapCaseFilterDropdown", GCM.MapFrame, "UIDropDownMenuTemplate")
        caseFilterDropdown:SetPoint("BOTTOMLEFT", 130, 10)
        GCM.MapFrame.caseFilterDropdown = caseFilterDropdown
        
        -- Enable mouse events
        mapContainer:EnableMouse(true)
        
        -- Store reference to map container for resize handling
        GCM.MapFrame.mapContainer = mapContainer
        
        -- Mouse clicking for markers
        mapContainer:SetScript("OnMouseDown", function(self, button)
            if button == "RightButton" then
                local cursorX, cursorY = GetCursorPosition()
                local scale = self:GetEffectiveScale()
                local x = (cursorX / scale - self:GetLeft())
                local y = (self:GetTop() - cursorY / scale)
                GCM.ShowMarkerCaseDialog(x, y)
            end
        end)
    end
    
    -- Load saved markers when map frame is shown
    GCM.LoadSavedMarkers()
    
    -- Initialize case filter dropdown
    GCM.UpdateCaseFilterDropdown()
    
    GCM.MapFrame:Show()
end

-- This function is now deprecated - use GCM.AddMapMarkerWithCase instead
function GCM.AddMapMarker(x, y)
    GCM.AddMapMarkerWithCase(x, y, nil, "")
end

function GCM.ClearAllMarkers()
    if GCM.MapFrame and GCM.MapFrame.markers then
        for _, marker in ipairs(GCM.MapFrame.markers) do
            marker:Hide()
        end
        GCM.MapFrame.markers = {}
        
        -- Clear all connection lines
        if GCM.MapFrame.markerLines then
            for _, line in ipairs(GCM.MapFrame.markerLines) do
                line:Hide()
            end
            GCM.MapFrame.markerLines = {}
        end
        
        -- Clear from database
        GCM.ClearAllMapMarkers()
        
        print("All markers cleared")
    end
end

-- Renumber all markers to maintain sequential numbering after removal
function GCM.RenumberMarkers()
    if not GCM.MapFrame or not GCM.MapFrame.markers then
        return
    end
    
    for i, marker in ipairs(GCM.MapFrame.markers) do
        if marker and marker:IsShown() then
            -- Update the marker number
            marker.markerNumber = i
            
            -- Find and update the number label
            local regions = {marker:GetRegions()}
            for _, region in ipairs(regions) do
                if region:GetObjectType() == "FontString" then
                    region:SetText(tostring(i))
                    break
                end
            end
        end
    end
end

-- Update the case filter dropdown with available cases
function GCM.UpdateCaseFilterDropdown()
    if not GCM.MapFrame or not GCM.MapFrame.caseFilterDropdown then
        return
    end
    
    local dropdown = GCM.MapFrame.caseFilterDropdown
    
    local function OnClick(self)
        GCM.MapFrame.selectedFilterCaseId = self.value
        UIDropDownMenu_SetText(dropdown, self:GetText())
        CloseDropDownMenus()
        -- Update lines when case selection changes
        if GCM.MapFrame.showLines then
            GCM.UpdateMarkerLines()
        end
    end
    
    local function Initialize(self, level)
        local info = UIDropDownMenu_CreateInfo()
        
        -- All markers option
        info.text = "All Markers"
        info.value = "all"
        info.func = OnClick
        UIDropDownMenu_AddButton(info)
        
        -- Standalone markers only
        info.text = "Standalone Only"
        info.value = "standalone"
        info.func = OnClick
        UIDropDownMenu_AddButton(info)
        
        -- Get unique case IDs from current markers
        local caseIds = {}
        if GCM.MapFrame.markers then
            for _, marker in ipairs(GCM.MapFrame.markers) do
                if marker.caseId and not caseIds[marker.caseId] then
                    caseIds[marker.caseId] = true
                end
            end
        end
        
        -- Add each case that has markers
        for caseId, _ in pairs(caseIds) do
            local case = GCM.GetCase(caseId)
            if case then
                info.text = string.format("Case #%s: %s", case.id or "?", case.title or "Untitled")
                info.value = caseId
                info.func = OnClick
                UIDropDownMenu_AddButton(info)
            end
        end
    end
    
    UIDropDownMenu_Initialize(dropdown, Initialize)
    UIDropDownMenu_SetWidth(dropdown, 200)
    UIDropDownMenu_SetText(dropdown, "All Markers")
    
    -- Set default selection
    GCM.MapFrame.selectedFilterCaseId = "all"
end

-- Toggle marker connection lines
function GCM.ToggleMarkerLines()
    if not GCM.MapFrame then return end
    
    GCM.MapFrame.showLines = not GCM.MapFrame.showLines
    
    if GCM.MapFrame.showLines then
        GCM.MapFrame.toggleLinesBtn:SetText("Hide Lines")
        GCM.UpdateMarkerLines()
        print("Marker connection lines enabled")
    else
        GCM.MapFrame.toggleLinesBtn:SetText("Connect Dots")
        GCM.HideMarkerLines()
        print("Marker connection lines disabled")
    end
end

-- Update connection lines between markers
function GCM.UpdateMarkerLines()
    if not GCM.MapFrame or not GCM.MapFrame.markers or not GCM.MapFrame.showLines then
        return
    end
    
    -- Clear existing lines
    GCM.HideMarkerLines()
    
    -- Get filtered markers based on selected case
    local filteredMarkers = GCM.GetFilteredMarkers()
    
    -- Don't draw lines if we have fewer than 2 filtered markers
    if #filteredMarkers < 2 then
        local filterType = GCM.MapFrame.selectedFilterCaseId or "all"
        if filterType == "all" then
            print("Not enough markers to draw lines (need at least 2)")
        else
            print(string.format("Not enough markers for selected filter to draw lines (need at least 2, found %d)", #filteredMarkers))
        end
        return
    end
    
    -- Initialize line container if needed
    if not GCM.MapFrame.markerLines then
        GCM.MapFrame.markerLines = {}
    end
    
    local filterType = GCM.MapFrame.selectedFilterCaseId or "all"
    print(string.format("Drawing lines between %d filtered markers (filter: %s)", #filteredMarkers, filterType))
    
    -- Connect each filtered marker to the next one in sequence
    for i = 1, #filteredMarkers - 1 do
        local marker1 = filteredMarkers[i]
        local marker2 = filteredMarkers[i + 1]
        
        if marker1 and marker2 and marker1:IsShown() and marker2:IsShown() then
            print(string.format("Creating line %d: marker at (%.1f,%.1f) to marker at (%.1f,%.1f)", 
                i, marker1.x, marker1.y, marker2.x, marker2.y))
            GCM.CreateLineBetweenMarkers(marker1, marker2)
        else
            print(string.format("Skipping line %d: markers not valid or not shown", i))
        end
    end
    
    print(string.format("Total lines created: %d", #GCM.MapFrame.markerLines))
end

-- Reposition all markers when map is resized to maintain relative positions
function GCM.RepositionMarkersOnResize()
    if not GCM.MapFrame or not GCM.MapFrame.markers or not GCM.MapFrame.markerContainer then
        return
    end
    
    -- Get current container dimensions
    local mapWidth = GCM.MapFrame.markerContainer:GetWidth()
    local mapHeight = GCM.MapFrame.markerContainer:GetHeight()
    
    -- Skip if dimensions aren't valid yet
    if mapWidth <= 0 or mapHeight <= 0 then
        -- Try again after a short delay
        C_Timer.After(0.1, function()
            GCM.RepositionMarkersOnResize()
        end)
        return
    end
    
    -- Get saved markers from database
    local savedMarkers = {}
    if GCM_Database and GCM_Database.mapMarkers then
        savedMarkers = GCM_Database.mapMarkers
    end
    
    -- Create lookup table for marker data by ID
    local markerDataLookup = {}
    for _, markerData in ipairs(savedMarkers) do
        if markerData.id then
            markerDataLookup[markerData.id] = markerData
        end
    end
    
    -- Reposition each marker based on its stored relative coordinates
    for _, marker in ipairs(GCM.MapFrame.markers) do
        if marker and marker.markerId and marker:IsShown() then
            -- Get marker data from lookup table
            local markerData = markerDataLookup[marker.markerId]
            if markerData then
                -- Convert relative coordinates back to absolute coordinates with new dimensions
                local newX = markerData.x * mapWidth
                local newY = markerData.y * mapHeight
                
                -- Update marker's stored absolute coordinates
                marker.x = newX
                marker.y = newY
                
                -- Reposition the marker
                marker:ClearAllPoints()
                marker:SetPoint("CENTER", GCM.MapFrame.markerContainer, "BOTTOMLEFT", newX, mapHeight - newY)
            end
        end
    end
    
    -- Update lines if they're currently shown
    if GCM.MapFrame.showLines then
        GCM.UpdateMarkerLines()
    end
    
    print(string.format("Repositioned %d markers for new map size: %.0fx%.0f", #GCM.MapFrame.markers, mapWidth, mapHeight))
end

-- Get markers filtered by the selected case
function GCM.GetFilteredMarkers()
    if not GCM.MapFrame or not GCM.MapFrame.markers then
        return {}
    end
    
    local selectedFilter = GCM.MapFrame.selectedFilterCaseId or "all"
    local filteredMarkers = {}
    
    for _, marker in ipairs(GCM.MapFrame.markers) do
        if marker and marker:IsShown() then
            local shouldInclude = false
            
            if selectedFilter == "all" then
                shouldInclude = true
            elseif selectedFilter == "standalone" then
                shouldInclude = (marker.caseId == nil)
            else
                -- Specific case selected
                shouldInclude = (marker.caseId == selectedFilter)
            end
            
            if shouldInclude then
                table.insert(filteredMarkers, marker)
            end
        end
    end
    
    return filteredMarkers
end

-- Create a line between two markers
function GCM.CreateLineBetweenMarkers(marker1, marker2)
    -- Calculate distance and angle
    local x1, y1 = marker1.x, marker1.y
    local x2, y2 = marker2.x, marker2.y
    
    local dx = x2 - x1
    local dy = y2 - y1
    local distance = math.sqrt(dx * dx + dy * dy)
    
    -- Skip if markers are too close (prevents zero-length lines)
    if distance < 5 then
        return
    end
    
    local angle = math.atan2(-dy, dx) -- Negative dy because WoW Y coordinates are flipped
    
    -- Create line texture with higher visibility
    local line = GCM.MapFrame.markerContainer:CreateTexture(nil, "ARTWORK")
    line:SetColorTexture(0.9, 0.9, 0.9, 0.8) -- Brighter, more visible gray
    line:SetSize(distance, 3) -- 3 pixel thick line for better visibility
    
    -- Position line at the exact midpoint between markers
    local midX = x1 + dx / 2
    local midY = y1 + dy / 2
    
    -- Convert to screen coordinates (WoW uses bottom-left origin)
    local screenY = GCM.MapFrame.markerContainer:GetHeight() - midY
    line:SetPoint("CENTER", GCM.MapFrame.markerContainer, "BOTTOMLEFT", midX, screenY)
    
    -- Rotate line to connect markers
    line:SetRotation(angle)
    
    -- Make sure line is visible
    line:Show()
    
    -- Debug output
    print(string.format("Line created: (%.1f,%.1f) to (%.1f,%.1f), distance=%.1f, angle=%.2f", 
        x1, y1, x2, y2, distance, angle))
    
    table.insert(GCM.MapFrame.markerLines, line)
end

-- Hide all marker connection lines
function GCM.HideMarkerLines()
    if GCM.MapFrame and GCM.MapFrame.markerLines then
        print(string.format("Hiding %d lines", #GCM.MapFrame.markerLines))
        for _, line in ipairs(GCM.MapFrame.markerLines) do
            line:Hide()
        end
        GCM.MapFrame.markerLines = {}
    end
end

-- Show dialog to link marker to case
function GCM.ShowMarkerCaseDialog(x, y)
    if not GCM.MarkerCaseDialog then
        GCM.MarkerCaseDialog = CreateFrame("Frame", "GCM_MarkerCaseDialog", UIParent, "BasicFrameTemplate")
        GCM.MarkerCaseDialog:SetSize(350, 250)
        GCM.MarkerCaseDialog:SetPoint("CENTER")
        GCM.MarkerCaseDialog:SetFrameStrata("DIALOG")
        GCM.MarkerCaseDialog:SetMovable(true)
        GCM.MarkerCaseDialog:EnableMouse(true)
        GCM.MarkerCaseDialog:RegisterForDrag("LeftButton")
        GCM.MarkerCaseDialog:SetScript("OnDragStart", GCM.MarkerCaseDialog.StartMoving)
        GCM.MarkerCaseDialog:SetScript("OnDragStop", GCM.MarkerCaseDialog.StopMovingOrSizing)
        
        -- Title
        local title = GCM.MarkerCaseDialog:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        title:SetPoint("TOP", 0, -15)
        title:SetText("Add Map Marker")
        
        -- Instructions
        local instructions = GCM.MarkerCaseDialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        instructions:SetPoint("TOPLEFT", 20, -40)
        instructions:SetWidth(310)
        instructions:SetText("Link this marker to a case (optional):")
        instructions:SetJustifyH("LEFT")
        
        -- Case dropdown
        local caseDropdown = CreateFrame("Frame", "GCM_MarkerCaseDropdown", GCM.MarkerCaseDialog, "UIDropDownMenuTemplate")
        caseDropdown:SetPoint("TOPLEFT", 10, -70)
        
        -- Description input
        local descLabel = GCM.MarkerCaseDialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        descLabel:SetPoint("TOPLEFT", 20, -110)
        descLabel:SetText("Marker Description (optional):")
        
        local descInput = CreateFrame("EditBox", nil, GCM.MarkerCaseDialog, "InputBoxTemplate")
        descInput:SetSize(300, 24)
        descInput:SetPoint("TOPLEFT", 20, -135)
        descInput:SetAutoFocus(false)
        descInput:SetFontObject("GameFontHighlight")
        
        -- Buttons
        local createBtn = CreateFrame("Button", nil, GCM.MarkerCaseDialog, "UIPanelButtonTemplate")
        createBtn:SetSize(100, 25)
        createBtn:SetPoint("BOTTOMRIGHT", -20, 20)
        createBtn:SetText("Add Marker")
        
        local cancelBtn = CreateFrame("Button", nil, GCM.MarkerCaseDialog, "UIPanelButtonTemplate")
        cancelBtn:SetSize(100, 25)
        cancelBtn:SetPoint("BOTTOMRIGHT", -130, 20)
        cancelBtn:SetText("Cancel")
        
        -- Store references
        GCM.MarkerCaseDialog.caseDropdown = caseDropdown
        GCM.MarkerCaseDialog.descInput = descInput
        GCM.MarkerCaseDialog.createBtn = createBtn
        GCM.MarkerCaseDialog.cancelBtn = cancelBtn
        
        -- Button scripts
        cancelBtn:SetScript("OnClick", function()
            GCM.MarkerCaseDialog:Hide()
        end)
        
        createBtn:SetScript("OnClick", function()
            local selectedCase = GCM.MarkerCaseDialog.selectedCaseId
            local description = descInput:GetText()
            GCM.AddMapMarkerWithCase(GCM.MarkerCaseDialog.markerX, GCM.MarkerCaseDialog.markerY, selectedCase, description)
            GCM.MarkerCaseDialog:Hide()
        end)
    end
    
    -- Store coordinates
    GCM.MarkerCaseDialog.markerX = x
    GCM.MarkerCaseDialog.markerY = y
    
    -- Update dropdown with current cases
    GCM.UpdateMarkerCaseDropdown()
    
    -- Clear previous input
    GCM.MarkerCaseDialog.descInput:SetText("")
    GCM.MarkerCaseDialog.selectedCaseId = nil
    
    GCM.MarkerCaseDialog:Show()
end

-- Update the case dropdown with available cases
function GCM.UpdateMarkerCaseDropdown()
    local dropdown = GCM.MarkerCaseDialog.caseDropdown
    
    local function OnClick(self)
        GCM.MarkerCaseDialog.selectedCaseId = self.value
        UIDropDownMenu_SetText(dropdown, self:GetText())
        CloseDropDownMenus()
    end
    
    local function Initialize(self, level)
        local info = UIDropDownMenu_CreateInfo()
        
        -- None option
        info.text = "No case (standalone marker)"
        info.value = nil
        info.func = OnClick
        UIDropDownMenu_AddButton(info)
        
        -- Add each case
        for _, case in ipairs(GCM_Database.cases or {}) do
            info.text = string.format("Case #%s: %s", case.id or "?", case.title or "Untitled")
            info.value = case.id
            info.func = OnClick
            UIDropDownMenu_AddButton(info)
        end
    end
    
    UIDropDownMenu_Initialize(dropdown, Initialize)
    UIDropDownMenu_SetWidth(dropdown, 300)
    UIDropDownMenu_SetText(dropdown, "No case (standalone marker)")
end

-- Get marker color based on case properties
function GCM.GetMarkerColor(caseId)
    if not caseId then
        return {1, 0, 0, 1} -- Red for standalone markers
    end
    
    local case = GCM.GetCase(caseId)
    if not case then
        return {0.5, 0.5, 0.5, 1} -- Gray for missing cases
    end
    
    -- Color by priority first (most important)
    if case.priority then
        local priority = string.lower(case.priority)
        if string.find(priority, "critical") or string.find(priority, "urgent") or string.find(priority, "high") then
            return {1, 0.2, 0.2, 1} -- Bright red for high priority
        elseif string.find(priority, "medium") or string.find(priority, "normal") then
            return {1, 0.8, 0, 1} -- Orange for medium priority
        elseif string.find(priority, "low") then
            return {0.4, 0.8, 0.4, 1} -- Green for low priority
        end
    end
    
    -- Color by case type if no priority match
    if case.caseType then
        local caseType = string.lower(case.caseType)
        if string.find(caseType, "murder") or string.find(caseType, "homicide") or string.find(caseType, "death") then
            return {0.8, 0, 0, 1} -- Dark red for serious crimes
        elseif string.find(caseType, "theft") or string.find(caseType, "robbery") or string.find(caseType, "burglary") then
            return {0.8, 0.4, 0, 1} -- Dark orange for theft
        elseif string.find(caseType, "missing") or string.find(caseType, "disappear") then
            return {0.6, 0, 0.8, 1} -- Purple for missing persons
        elseif string.find(caseType, "fraud") or string.find(caseType, "embezzle") then
            return {0.8, 0.6, 0, 1} -- Gold for financial crimes
        elseif string.find(caseType, "assault") or string.find(caseType, "violence") then
            return {0.9, 0.3, 0.3, 1} -- Light red for violence
        elseif string.find(caseType, "investigation") or string.find(caseType, "inquiry") then
            return {0, 0.6, 0.9, 1} -- Light blue for investigations
        end
    end
    
    -- Color by status if no type match
    if case.status then
        local status = string.lower(case.status)
        if string.find(status, "closed") or string.find(status, "solved") or string.find(status, "complete") then
            return {0.3, 0.7, 0.3, 1} -- Green for closed cases
        elseif string.find(status, "cold") or string.find(status, "suspended") then
            return {0.4, 0.4, 0.6, 1} -- Blue-gray for cold cases
        elseif string.find(status, "active") or string.find(status, "ongoing") then
            return {0, 0.8, 1, 1} -- Cyan for active cases
        end
    end
    
    -- Default blue for case-linked markers with no specific classification
    return {0, 0.8, 1, 1}
end

-- Show color legend window
function GCM.ShowColorLegend()
    if not GCM.ColorLegendFrame then
        GCM.ColorLegendFrame = CreateFrame("Frame", "GCM_ColorLegendFrame", UIParent, "BasicFrameTemplate")
        GCM.ColorLegendFrame:SetSize(350, 450)
        GCM.ColorLegendFrame:SetPoint("CENTER")
        GCM.ColorLegendFrame:SetFrameStrata("DIALOG")
        GCM.ColorLegendFrame:SetMovable(true)
        GCM.ColorLegendFrame:EnableMouse(true)
        GCM.ColorLegendFrame:RegisterForDrag("LeftButton")
        GCM.ColorLegendFrame:SetScript("OnDragStart", GCM.ColorLegendFrame.StartMoving)
        GCM.ColorLegendFrame:SetScript("OnDragStop", GCM.ColorLegendFrame.StopMovingOrSizing)
        
        -- Title
        local title = GCM.ColorLegendFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        title:SetPoint("TOP", 0, -15)
        title:SetText("Map Marker Color Legend")
        
        -- Close Button
        local closeBtn = CreateFrame("Button", nil, GCM.ColorLegendFrame, "UIPanelButtonTemplate")
        closeBtn:SetSize(80, 25)
        closeBtn:SetPoint("BOTTOM", 0, 15)
        closeBtn:SetText("Close")
        closeBtn:SetScript("OnClick", function()
            GCM.ColorLegendFrame:Hide()
        end)
        
        -- Content area
        local scrollFrame = CreateFrame("ScrollFrame", nil, GCM.ColorLegendFrame, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", 15, -40)
        scrollFrame:SetPoint("BOTTOMRIGHT", -35, 50)
        
        local scrollChild = CreateFrame("Frame")
        scrollChild:SetSize(scrollFrame:GetWidth(), 800)
        scrollFrame:SetScrollChild(scrollChild)
        
        local yOffset = -10
        
        -- Helper function to create legend entries
        local function CreateLegendEntry(color, text)
            local entry = CreateFrame("Frame", nil, scrollChild)
            entry:SetSize(scrollChild:GetWidth() - 10, 20)
            entry:SetPoint("TOPLEFT", 5, yOffset)
            
            -- Color sample
            local colorSample = entry:CreateTexture(nil, "OVERLAY")
            colorSample:SetSize(12, 12)
            colorSample:SetPoint("LEFT", 5, 0)
            colorSample:SetColorTexture(color[1], color[2], color[3], color[4])
            
            -- Black border around color sample
            local border = entry:CreateTexture(nil, "BORDER")
            border:SetSize(14, 14)
            border:SetPoint("CENTER", colorSample, "CENTER")
            border:SetColorTexture(0, 0, 0, 1)
            
            -- Text description
            local label = entry:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            label:SetPoint("LEFT", colorSample, "RIGHT", 10, 0)
            label:SetText(text)
            label:SetJustifyH("LEFT")
            
            yOffset = yOffset - 25
        end
        
        -- Priority-based colors (highest priority)
        local priorityHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        priorityHeader:SetPoint("TOPLEFT", 5, yOffset)
        priorityHeader:SetText("|cffFFD700Priority-Based Colors:|r")
        yOffset = yOffset - 30
        
        CreateLegendEntry({1, 0.2, 0.2, 1}, "High/Critical/Urgent Priority")
        CreateLegendEntry({1, 0.8, 0, 1}, "Medium/Normal Priority")
        CreateLegendEntry({0.4, 0.8, 0.4, 1}, "Low Priority")
        
        yOffset = yOffset - 10
        
        -- Case type colors
        local typeHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        typeHeader:SetPoint("TOPLEFT", 5, yOffset)
        typeHeader:SetText("|cffFFD700Case Type Colors:|r")
        yOffset = yOffset - 30
        
        CreateLegendEntry({0.8, 0, 0, 1}, "Murder/Homicide/Death")
        CreateLegendEntry({0.8, 0.4, 0, 1}, "Theft/Robbery/Burglary")
        CreateLegendEntry({0.6, 0, 0.8, 1}, "Missing Persons")
        CreateLegendEntry({0.8, 0.6, 0, 1}, "Fraud/Financial Crimes")
        CreateLegendEntry({0.9, 0.3, 0.3, 1}, "Assault/Violence")
        CreateLegendEntry({0, 0.6, 0.9, 1}, "General Investigation")
        
        yOffset = yOffset - 10
        
        -- Status colors
        local statusHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        statusHeader:SetPoint("TOPLEFT", 5, yOffset)
        statusHeader:SetText("|cffFFD700Case Status Colors:|r")
        yOffset = yOffset - 30
        
        CreateLegendEntry({0.3, 0.7, 0.3, 1}, "Closed/Solved/Complete")
        CreateLegendEntry({0.4, 0.4, 0.6, 1}, "Cold/Suspended Cases")
        CreateLegendEntry({0, 0.8, 1, 1}, "Active/Ongoing Cases")
        
        yOffset = yOffset - 10
        
        -- Special markers
        local specialHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        specialHeader:SetPoint("TOPLEFT", 5, yOffset)
        specialHeader:SetText("|cffFFD700Special Markers:|r")
        yOffset = yOffset - 30
        
        CreateLegendEntry({1, 0, 0, 1}, "Standalone (No Case Link)")
        CreateLegendEntry({0.5, 0.5, 0.5, 1}, "Missing/Deleted Case")
        CreateLegendEntry({0, 0.8, 1, 1}, "Default Case Marker")
        
        -- Add note
        yOffset = yOffset - 10
        local note = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        note:SetPoint("TOPLEFT", 5, yOffset)
        note:SetWidth(scrollChild:GetWidth() - 10)
        note:SetText("|cffCCCCCCNote: Colors are determined by priority first, then case type, then status. The first matching condition determines the marker color.|r")
        note:SetJustifyH("LEFT")
        
        -- Adjust scroll height
        scrollChild:SetHeight(math.abs(yOffset) + 50)
    end
    
    GCM.ColorLegendFrame:Show()
end

-- Enhanced marker creation with case linking
function GCM.AddMapMarkerWithCase(x, y, caseId, description)
    local mapContainer, markerContainer, markers, markerLines, showLines
    
    -- Check if we're using the tab-based interface
    if GCM.MainFrame and GCM.MainFrame.tabs and GCM.MainFrame.tabs.map and GCM.MainFrame.tabs.map:IsShown() then
        -- Tab-based interface
        local mapTab = GCM.MainFrame.tabs.map
        mapContainer = mapTab.mapContainer
        
        if not mapContainer then
            print("Error: Tab map container not initialized")
            return
        end
        
        -- Initialize tab marker container if it doesn't exist
        if not GCM.MainFrame.tabMapContainer then
            GCM.MainFrame.tabMapContainer = CreateFrame("Frame", nil, mapContainer)
            GCM.MainFrame.tabMapContainer:SetAllPoints(mapContainer)
        end
        
        -- Initialize tab marker arrays if they don't exist
        if not GCM.MainFrame.tabMarkers then
            GCM.MainFrame.tabMarkers = {}
        end
        if not GCM.MainFrame.tabMarkerLines then
            GCM.MainFrame.tabMarkerLines = {}
        end
        if GCM.MainFrame.tabShowLines == nil then
            GCM.MainFrame.tabShowLines = false
        end
        
        -- Use tab-based references
        markerContainer = GCM.MainFrame.tabMapContainer
        markers = GCM.MainFrame.tabMarkers
        markerLines = GCM.MainFrame.tabMarkerLines
        showLines = GCM.MainFrame.tabShowLines
        
        print("Adding marker to tab interface")
        
    elseif GCM.MapFrame then
        -- Standalone map frame interface
        mapContainer = GCM.MapFrame.mapContainer
        
        if not mapContainer then
            print("Error: Map container not initialized")
            return
        end
        
        -- Initialize marker container if it doesn't exist
        if not GCM.MapFrame.markerContainer then
            GCM.MapFrame.markerContainer = CreateFrame("Frame", nil, mapContainer)
            GCM.MapFrame.markerContainer:SetAllPoints(mapContainer)
        end
        
        -- Initialize marker arrays if they don't exist
        if not GCM.MapFrame.markers then
            GCM.MapFrame.markers = {}
        end
        if not GCM.MapFrame.markerLines then
            GCM.MapFrame.markerLines = {}
        end
        if GCM.MapFrame.showLines == nil then
            GCM.MapFrame.showLines = false
        end
        
        -- Use standalone frame references
        markerContainer = GCM.MapFrame.markerContainer
        markers = GCM.MapFrame.markers
        markerLines = GCM.MapFrame.markerLines
        showLines = GCM.MapFrame.showLines
        
        print("Adding marker to standalone interface")
        
    else
        print("Error: No map interface is currently active")
        return
    end
    
    -- Ensure markers is a valid table
    if type(markers) ~= "table" then
        print("Error: markers is not a valid table")
        return
    end
    
    local pin = CreateFrame("Button", nil, markerContainer)
    pin:SetSize(14, 14)
    pin:SetPoint("CENTER", markerContainer, "BOTTOMLEFT", x, markerContainer:GetHeight() - y)
    
    -- Store marker data
    pin.caseId = caseId
    pin.description = description or ""
    pin.x = x
    pin.y = y
    
    -- Convert absolute coordinates to relative percentages for storage
    local mapWidth = markerContainer:GetWidth()
    local mapHeight = markerContainer:GetHeight()
    
    -- Prevent division by zero
    local relativeX = (mapWidth > 0) and (x / mapWidth) or 0
    local relativeY = (mapHeight > 0) and (y / mapHeight) or 0
    
    -- Calculate marker number safely
    local markerNumber = #markers + 1
    
    -- Create marker data for database (store relative coordinates)
    local markerData = {
        x = relativeX,
        y = relativeY,
        caseId = caseId,
        description = description or "",
        markerNumber = markerNumber
    }
    
    -- Save to database and get the ID
    local markerId = GCM.SaveMapMarker(markerData)
    pin.markerId = markerId
    
    -- Create triangular marker using multiple textures
    local triangleSize = 10
    
    -- Main triangle (pointing up)
    local triangle = pin:CreateTexture(nil, "OVERLAY")
    triangle:SetSize(triangleSize, triangleSize)
    triangle:SetPoint("CENTER")
    
    -- Get color based on case properties
    local color = GCM.GetMarkerColor(caseId)
    triangle:SetColorTexture(color[1], color[2], color[3], color[4])
    
    -- Create triangle shape using 3 small rectangles to form triangle outline
    -- Top point
    local top = pin:CreateTexture(nil, "BORDER")
    top:SetSize(2, 4)
    top:SetPoint("CENTER", triangle, "TOP", 0, -1)
    top:SetColorTexture(0, 0, 0, 1)
    
    -- Left side
    local left = pin:CreateTexture(nil, "BORDER")
    left:SetSize(1, 6)
    left:SetPoint("CENTER", triangle, "BOTTOMLEFT", 2, 2)
    left:SetColorTexture(0, 0, 0, 1)
    left:SetRotation(0.5) -- Angle for triangle side
    
    -- Right side
    local right = pin:CreateTexture(nil, "BORDER")
    right:SetSize(1, 6)
    right:SetPoint("CENTER", triangle, "BOTTOMRIGHT", -2, 2)
    right:SetColorTexture(0, 0, 0, 1)
    right:SetRotation(-0.5) -- Angle for triangle side
    
    -- Bottom edge
    local bottom = pin:CreateTexture(nil, "BORDER")
    bottom:SetSize(8, 1)
    bottom:SetPoint("CENTER", triangle, "BOTTOM", 0, 1)
    bottom:SetColorTexture(0, 0, 0, 1)
    
    -- Add number label to show marker order
    local numberLabel = pin:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    numberLabel:SetPoint("CENTER", triangle, "CENTER", 0, 0)
    numberLabel:SetText(tostring(markerNumber))
    numberLabel:SetTextColor(1, 1, 1, 1) -- White text
    numberLabel:SetFont("Fonts\\FRIZQT__.TTF", 8, "OUTLINE") -- Small font with outline for visibility
    
    -- Store the marker number for reference
    pin.markerNumber = markerNumber
    
    -- Enhanced tooltip functionality with case details
    pin:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")
        
        if self.caseId then
            local case = GCM.GetCase(self.caseId)
            if case then
                -- Main title
                GameTooltip:SetText(string.format("|cff00ccff%s|r", case.title or "Untitled Case"), 1, 1, 1)
                GameTooltip:AddLine(string.format("Case #%s", case.id), 0.8, 0.8, 1)
                
                -- Add a separator line
                GameTooltip:AddLine(" ")
                
                -- Case details
                if case.status and case.status ~= "" then
                    GameTooltip:AddLine(string.format("|cffffcc00Status:|r %s", case.status), 1, 1, 1)
                end
                
                if case.priority and case.priority ~= "" then
                    GameTooltip:AddLine(string.format("|cffffcc00Priority:|r %s", case.priority), 1, 1, 1)
                end
                
                if case.assignedTo and case.assignedTo ~= "" then
                    GameTooltip:AddLine(string.format("|cffffcc00Detective:|r %s", case.assignedTo), 1, 1, 1)
                end
                
                if case.location and case.location ~= "" then
                    GameTooltip:AddLine(string.format("|cffffcc00Location:|r %s", case.location), 1, 1, 1)
                end
                
                -- Brief description if available
                if case.description and case.description ~= "" then
                    local briefDesc = case.description
                    if string.len(briefDesc) > 80 then
                        briefDesc = string.sub(briefDesc, 1, 77) .. "..."
                    end
                    GameTooltip:AddLine(" ")
                    GameTooltip:AddLine(briefDesc, 0.9, 0.9, 0.9)
                end
                
            else
                GameTooltip:SetText("Case Marker (Case Not Found)", 1, 0.5, 0.5)
            end
        else
            GameTooltip:SetText("Map Marker", 1, 1, 1)
        end
        
        -- Marker-specific description
        if self.description and self.description ~= "" then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(string.format("|cff88ff88Marker Note:|r %s", self.description), 1, 1, 1)
        end
        
        -- Position and instructions
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(string.format("Marker #%d | Position: %.0f, %.0f", self.markerNumber or 0, self.x, self.y), 0.7, 0.7, 0.7)
        
        if self.caseId then
            GameTooltip:AddLine("Left-click to remove | Right-click to view case", 0.5, 0.5, 0.5)
        else
            GameTooltip:AddLine("Left-click to remove", 0.5, 0.5, 0.5)
        end
        
        GameTooltip:Show()
    end)
    
    pin:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    -- Enhanced click handling
    pin:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            -- Remove marker from database
            if self.markerId then
                GCM.DeleteMapMarker(self.markerId)
            end
            
            -- Remove marker from UI - use the correct markers array
            self:Hide()
            local markersToRemoveFrom
            if GCM.MainFrame and GCM.MainFrame.tabs and GCM.MainFrame.tabs.map and GCM.MainFrame.tabs.map:IsShown() then
                markersToRemoveFrom = GCM.MainFrame.tabMarkers
            else
                markersToRemoveFrom = GCM.MapFrame.markers
            end
            
            if markersToRemoveFrom then
                for i, marker in ipairs(markersToRemoveFrom) do
                    if marker == self then
                        table.remove(markersToRemoveFrom, i)
                        break
                    end
                end
                
                -- Renumber remaining markers after removal
                GCM.RenumberMarkers()
                
                -- Update case filter dropdown after marker removal
                if GCM.MainFrame and GCM.MainFrame.tabs and GCM.MainFrame.tabs.map and GCM.MainFrame.tabs.map:IsShown() then
                    GCM.UpdateTabCaseFilterDropdown()
                    -- Update lines after marker removal
                    if GCM.MainFrame.tabShowLines then
                        GCM.UpdateTabMarkerLines()
                    end
                else
                    GCM.UpdateCaseFilterDropdown()
                    -- Update lines after marker removal
                    if GCM.MapFrame.showLines then
                        GCM.UpdateMarkerLines()
                    end
                end
            end
        elseif button == "RightButton" then
            -- Show marker options
            GCM.ShowMarkerOptions(self)
        end
    end)
    
    -- Add marker to the appropriate array
    table.insert(markers, pin)
    
    -- Update case filter dropdown to include new cases
    if GCM.MainFrame and GCM.MainFrame.tabs and GCM.MainFrame.tabs.map and GCM.MainFrame.tabs.map:IsShown() then
        GCM.UpdateTabCaseFilterDropdown()
        -- Update connection lines if they're enabled
        if GCM.MainFrame.tabShowLines then
            GCM.UpdateTabMarkerLines()
        end
    else
        GCM.UpdateCaseFilterDropdown()
        -- Update connection lines if they're enabled
        if GCM.MapFrame.showLines then
            GCM.UpdateMarkerLines()
        end
    end
    
    if caseId then
        local case = GCM.GetCase(caseId)
        local caseTitle = case and case.title or "Unknown Case"
        print(string.format("Marker #%d: Case marker added for '%s' at position: %.0f, %.0f (%.1f%%, %.1f%%)", markerNumber, caseTitle, x, y, relativeX*100, relativeY*100))
    else
        print(string.format("Marker #%d: Standalone marker added at position: %.0f, %.0f (%.1f%%, %.1f%%)", markerNumber, x, y, relativeX*100, relativeY*100))
    end
end

-- Show marker options menu
function GCM.ShowMarkerOptions(marker)
    if marker.caseId then
        local case = GCM.GetCase(marker.caseId)
        if case then
            -- Show case view
            GCM.MapFrame:Hide()
            GCM.ShowCaseViewFrame(case)
        else
            print("Associated case not found!")
        end
    end
end

-- Load saved markers from database
function GCM.LoadSavedMarkers()
    -- Only load if map frame exists
    if not GCM.MapFrame or not GCM.MapFrame.mapContainer then
        return
    end
    
    -- Initialize marker container if it doesn't exist
    if not GCM.MapFrame.markerContainer then
        GCM.MapFrame.markerContainer = CreateFrame("Frame", nil, GCM.MapFrame.mapContainer)
        GCM.MapFrame.markerContainer:SetAllPoints(GCM.MapFrame.mapContainer)
        GCM.MapFrame.markers = {}
        GCM.MapFrame.markerLines = {}
        GCM.MapFrame.showLines = false
    end
    
    -- Clear existing markers first
    if GCM.MapFrame.markers then
        for _, marker in ipairs(GCM.MapFrame.markers) do
            marker:Hide()
        end
        GCM.MapFrame.markers = {}
    end
    
    -- Load markers from database
    local savedMarkers = GCM.GetMapMarkers()
    if not savedMarkers or #savedMarkers == 0 then
        return
    end
    
    -- Sort markers by creation time to maintain order
    table.sort(savedMarkers, function(a, b)
        return (a.createdAt or "") < (b.createdAt or "")
    end)
    
    -- Check if marker container has valid dimensions
    local mapWidth = GCM.MapFrame.markerContainer:GetWidth()
    local mapHeight = GCM.MapFrame.markerContainer:GetHeight()
    
    if mapWidth <= 0 or mapHeight <= 0 then
        print("Warning: Map container not ready yet, deferring marker load...")
        -- Try again after a short delay
        C_Timer.After(0.1, function()
            GCM.LoadSavedMarkers()
        end)
        return
    end
    
    print(string.format("Loading %d saved map markers... (Map size: %.0fx%.0f)", #savedMarkers, mapWidth, mapHeight))
    
    -- Create UI markers for each saved marker
    for _, markerData in ipairs(savedMarkers) do
        GCM.CreateMarkerFromData(markerData)
    end
    
    -- Update connection lines if they're enabled
    if GCM.MapFrame.showLines then
        GCM.UpdateMarkerLines()
    end
end

-- Create a tab marker from saved data
function GCM.CreateTabMarkerFromData(markerData)
    if not GCM.MainFrame or not GCM.MainFrame.tabMapContainer then
        return
    end
    
    -- Convert relative coordinates back to absolute coordinates
    local mapWidth = GCM.MainFrame.tabMapContainer:GetWidth()
    local mapHeight = GCM.MainFrame.tabMapContainer:GetHeight()
    
    -- Ensure we have valid dimensions
    if mapWidth <= 0 or mapHeight <= 0 then
        print("Warning: Tab map container has invalid dimensions, skipping marker load")
        return
    end
    
    local x = markerData.x * mapWidth
    local y = markerData.y * mapHeight
    
    local caseId = markerData.caseId
    local description = markerData.description or ""
    
    local pin = CreateFrame("Button", nil, GCM.MainFrame.tabMapContainer)
    pin:SetSize(14, 14)
    pin:SetPoint("CENTER", GCM.MainFrame.tabMapContainer, "BOTTOMLEFT", x, GCM.MainFrame.tabMapContainer:GetHeight() - y)
    
    -- Store marker data
    pin.caseId = caseId
    pin.description = description
    pin.x = x
    pin.y = y
    pin.markerId = markerData.id
    
    -- Create triangular marker using multiple textures
    local triangleSize = 10
    
    -- Main triangle (pointing up)
    local triangle = pin:CreateTexture(nil, "OVERLAY")
    triangle:SetSize(triangleSize, triangleSize)
    triangle:SetPoint("CENTER")
    
    -- Get color based on case properties
    local color = GCM.GetMarkerColor(caseId)
    triangle:SetColorTexture(color[1], color[2], color[3], color[4])
    
    -- Create triangle shape using rectangles to form triangle outline
    local top = pin:CreateTexture(nil, "BORDER")
    top:SetSize(2, 4)
    top:SetPoint("CENTER", triangle, "TOP", 0, -1)
    top:SetColorTexture(0, 0, 0, 1)
    
    local left = pin:CreateTexture(nil, "BORDER")
    left:SetSize(1, 6)
    left:SetPoint("CENTER", triangle, "BOTTOMLEFT", 2, 2)
    left:SetColorTexture(0, 0, 0, 1)
    left:SetRotation(0.5)
    
    local right = pin:CreateTexture(nil, "BORDER")
    right:SetSize(1, 6)
    right:SetPoint("CENTER", triangle, "BOTTOMRIGHT", -2, 2)
    right:SetColorTexture(0, 0, 0, 1)
    right:SetRotation(-0.5)
    
    local bottom = pin:CreateTexture(nil, "BORDER")
    bottom:SetSize(8, 1)
    bottom:SetPoint("CENTER", triangle, "BOTTOM", 0, 1)
    bottom:SetColorTexture(0, 0, 0, 1)
    
    -- Add number label
    local markerNumber = #GCM.MainFrame.tabMarkers + 1
    local numberLabel = pin:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    numberLabel:SetPoint("CENTER", triangle, "CENTER", 0, 0)
    numberLabel:SetText(tostring(markerNumber))
    numberLabel:SetTextColor(1, 1, 1, 1)
    numberLabel:SetFont("Fonts\\FRIZQT__.TTF", 8, "OUTLINE")
    
    pin.markerNumber = markerNumber
    
    -- Enhanced tooltip functionality
    pin:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")
        
        if self.caseId then
            local case = GCM.GetCase(self.caseId)
            if case then
                GameTooltip:SetText(string.format("|cff00ccff%s|r", case.title or "Untitled Case"), 1, 1, 1)
                GameTooltip:AddLine(string.format("Case #%s", case.id), 0.8, 0.8, 1)
                GameTooltip:AddLine(" ")
                
                if case.status and case.status ~= "" then
                    GameTooltip:AddLine(string.format("|cffffcc00Status:|r %s", case.status), 1, 1, 1)
                end
                
                if case.priority and case.priority ~= "" then
                    GameTooltip:AddLine(string.format("|cffffcc00Priority:|r %s", case.priority), 1, 1, 1)
                end
                
                if case.assignedTo and case.assignedTo ~= "" then
                    GameTooltip:AddLine(string.format("|cffffcc00Detective:|r %s", case.assignedTo), 1, 1, 1)
                end
                
                if case.location and case.location ~= "" then
                    GameTooltip:AddLine(string.format("|cffffcc00Location:|r %s", case.location), 1, 1, 1)
                end
                
                if case.description and case.description ~= "" then
                    local briefDesc = case.description
                    if string.len(briefDesc) > 80 then
                        briefDesc = string.sub(briefDesc, 1, 77) .. "..."
                    end
                    GameTooltip:AddLine(" ")
                    GameTooltip:AddLine(briefDesc, 0.9, 0.9, 0.9)
                end
            else
                GameTooltip:SetText("Case Marker (Case Not Found)", 1, 0.5, 0.5)
            end
        else
            GameTooltip:SetText("Map Marker", 1, 1, 1)
        end
        
        if self.description and self.description ~= "" then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(string.format("|cff88ff88Marker Note:|r %s", self.description), 1, 1, 1)
        end
        
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(string.format("Marker #%d | Position: %.0f, %.0f", self.markerNumber or 0, self.x, self.y), 0.7, 0.7, 0.7)
        
        if self.caseId then
            GameTooltip:AddLine("Left-click to remove | Right-click to view case", 0.5, 0.5, 0.5)
        else
            GameTooltip:AddLine("Left-click to remove", 0.5, 0.5, 0.5)
        end
        
        GameTooltip:Show()
    end)
    
    pin:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    -- Enhanced click handling for tab markers
    pin:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            -- Remove marker from database
            if self.markerId then
                GCM.DeleteMapMarker(self.markerId)
            end
            
            -- Remove marker from UI
            self:Hide()
            for i, marker in ipairs(GCM.MainFrame.tabMarkers) do
                if marker == self then
                    table.remove(GCM.MainFrame.tabMarkers, i)
                    break
                end
            end
            
            -- Renumber remaining markers
            for i, marker in ipairs(GCM.MainFrame.tabMarkers) do
                if marker and marker:IsShown() then
                    marker.markerNumber = i
                    local regions = {marker:GetRegions()}
                    for _, region in ipairs(regions) do
                        if region:GetObjectType() == "FontString" then
                            region:SetText(tostring(i))
                            break
                        end
                    end
                end
            end
            
            -- Update case filter dropdown and lines
            GCM.UpdateTabCaseFilterDropdown()
            if GCM.MainFrame.tabShowLines then
                GCM.UpdateTabMarkerLines()
            end
            
        elseif button == "RightButton" then
            -- Show marker options
            if self.caseId then
                local case = GCM.GetCase(self.caseId)
                if case then
                    GCM.ShowCaseViewFrame(case)
                else
                    print("Associated case not found!")
                end
            end
        end
    end)
    
    table.insert(GCM.MainFrame.tabMarkers, pin)
end

-- Create a UI marker from saved data
function GCM.CreateMarkerFromData(markerData)
    if not GCM.MapFrame or not GCM.MapFrame.mapContainer then
        return
    end
    
    -- Initialize marker container if it doesn't exist
    if not GCM.MapFrame.markerContainer then
        GCM.MapFrame.markerContainer = CreateFrame("Frame", nil, GCM.MapFrame.mapContainer)
        GCM.MapFrame.markerContainer:SetAllPoints(GCM.MapFrame.mapContainer)
        GCM.MapFrame.markers = {}
        GCM.MapFrame.markerLines = {}
        GCM.MapFrame.showLines = false
    end
    
    -- Convert relative coordinates back to absolute coordinates
    local mapWidth = GCM.MapFrame.markerContainer:GetWidth()
    local mapHeight = GCM.MapFrame.markerContainer:GetHeight()
    
    -- Ensure we have valid dimensions
    if mapWidth <= 0 or mapHeight <= 0 then
        print("Warning: Map container has invalid dimensions, skipping marker load")
        return
    end
    
    local x = markerData.x * mapWidth
    local y = markerData.y * mapHeight
    
    local caseId = markerData.caseId
    local description = markerData.description or ""
    
    local pin = CreateFrame("Button", nil, GCM.MapFrame.markerContainer)
    pin:SetSize(14, 14)
    pin:SetPoint("CENTER", GCM.MapFrame.markerContainer, "BOTTOMLEFT", x, GCM.MapFrame.markerContainer:GetHeight() - y)
    
    -- Store marker data
    pin.caseId = caseId
    pin.description = description
    pin.x = x
    pin.y = y
    pin.markerId = markerData.id
    
    -- Create triangular marker using multiple textures
    local triangleSize = 10
    
    -- Main triangle (pointing up)
    local triangle = pin:CreateTexture(nil, "OVERLAY")
    triangle:SetSize(triangleSize, triangleSize)
    triangle:SetPoint("CENTER")
    
    -- Get color based on case properties
    local color = GCM.GetMarkerColor(caseId)
    triangle:SetColorTexture(color[1], color[2], color[3], color[4])
    
    -- Create triangle shape using 3 small rectangles to form triangle outline
    -- Top point
    local top = pin:CreateTexture(nil, "BORDER")
    top:SetSize(2, 4)
    top:SetPoint("CENTER", triangle, "TOP", 0, -1)
    top:SetColorTexture(0, 0, 0, 1)
    
    -- Left side
    local left = pin:CreateTexture(nil, "BORDER")
    left:SetSize(1, 6)
    left:SetPoint("CENTER", triangle, "BOTTOMLEFT", 2, 2)
    left:SetColorTexture(0, 0, 0, 1)
    left:SetRotation(0.5) -- Angle for triangle side
    
    -- Right side
    local right = pin:CreateTexture(nil, "BORDER")
    right:SetSize(1, 6)
    right:SetPoint("CENTER", triangle, "BOTTOMRIGHT", -2, 2)
    right:SetColorTexture(0, 0, 0, 1)
    right:SetRotation(-0.5) -- Angle for triangle side
    
    -- Bottom edge
    local bottom = pin:CreateTexture(nil, "BORDER")
    bottom:SetSize(8, 1)
    bottom:SetPoint("CENTER", triangle, "BOTTOM", 0, 1)
    bottom:SetColorTexture(0, 0, 0, 1)
    
    -- Add number label to show marker order
    local markerNumber = #GCM.MapFrame.markers + 1
    local numberLabel = pin:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    numberLabel:SetPoint("CENTER", triangle, "CENTER", 0, 0)
    numberLabel:SetText(tostring(markerNumber))
    numberLabel:SetTextColor(1, 1, 1, 1) -- White text
    numberLabel:SetFont("Fonts\\FRIZQT__.TTF", 8, "OUTLINE") -- Small font with outline for visibility
    
    -- Store the marker number for reference
    pin.markerNumber = markerNumber
    
    -- Add tooltip functionality (same as AddMapMarkerWithCase)
    pin:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")
        
        if self.caseId then
            local case = GCM.GetCase(self.caseId)
            if case then
                -- Main title
                GameTooltip:SetText(string.format("|cff00ccff%s|r", case.title or "Untitled Case"), 1, 1, 1)
                GameTooltip:AddLine(string.format("Case #%s", case.id), 0.8, 0.8, 1)
                
                -- Add a separator line
                GameTooltip:AddLine(" ")
                
                -- Case details
                if case.status and case.status ~= "" then
                    GameTooltip:AddLine(string.format("|cffffcc00Status:|r %s", case.status), 1, 1, 1)
                end
                
                if case.priority and case.priority ~= "" then
                    GameTooltip:AddLine(string.format("|cffffcc00Priority:|r %s", case.priority), 1, 1, 1)
                end
                
                if case.assignedTo and case.assignedTo ~= "" then
                    GameTooltip:AddLine(string.format("|cffffcc00Detective:|r %s", case.assignedTo), 1, 1, 1)
                end
                
                if case.location and case.location ~= "" then
                    GameTooltip:AddLine(string.format("|cffffcc00Location:|r %s", case.location), 1, 1, 1)
                end
                
                -- Brief description if available
                if case.description and case.description ~= "" then
                    local briefDesc = case.description
                    if string.len(briefDesc) > 80 then
                        briefDesc = string.sub(briefDesc, 1, 77) .. "..."
                    end
                    GameTooltip:AddLine(" ")
                    GameTooltip:AddLine(briefDesc, 0.9, 0.9, 0.9)
                end
                
            else
                GameTooltip:SetText("Case Marker (Case Not Found)", 1, 0.5, 0.5)
            end
        else
            GameTooltip:SetText("Map Marker", 1, 1, 1)
        end
        
        -- Marker-specific description
        if self.description and self.description ~= "" then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(string.format("|cff88ff88Marker Note:|r %s", self.description), 1, 1, 1)
        end
        
        -- Position and instructions
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(string.format("Marker #%d | Position: %.0f, %.0f", self.markerNumber or 0, self.x, self.y), 0.7, 0.7, 0.7)
        
        if self.caseId then
            GameTooltip:AddLine("Left-click to remove | Right-click to view case", 0.5, 0.5, 0.5)
        else
            GameTooltip:AddLine("Left-click to remove", 0.5, 0.5, 0.5)
        end
        
        GameTooltip:Show()
    end)
    
    pin:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    -- Enhanced click handling (same as AddMapMarkerWithCase)
    pin:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            -- Remove marker from database
            if self.markerId then
                GCM.DeleteMapMarker(self.markerId)
            end
            
            -- Remove marker from UI
            self:Hide()
            for i, marker in ipairs(GCM.MapFrame.markers) do
                if marker == self then
                    table.remove(GCM.MapFrame.markers, i)
                    break
                end
            end
            -- Renumber remaining markers after removal
            GCM.RenumberMarkers()
            -- Update case filter dropdown after marker removal
            GCM.UpdateCaseFilterDropdown()
            -- Update lines after marker removal
            if GCM.MapFrame.showLines then
                GCM.UpdateMarkerLines()
            end
        elseif button == "RightButton" then
            -- Show marker options
            GCM.ShowMarkerOptions(self)
        end
    end)
    
    table.insert(GCM.MapFrame.markers, pin)
end

---------------------------------------- STAFF BUTTON---------------------------------------

function GCM.ShowStaffFrame()
    GCM.MainFrame:Hide()
    
    if not GCM.StaffFrame then
        GCM.StaffFrame = CreateFrame("Frame", "GCM_StaffFrame", UIParent, "BasicFrameTemplate")
        GCM.StaffFrame:SetSize(700, 600)
        GCM.StaffFrame:SetPoint("CENTER")
        GCM.StaffFrame:SetMovable(true)
        GCM.StaffFrame:SetResizable(true)
        GCM.StaffFrame:EnableMouse(true)
        GCM.StaffFrame:RegisterForDrag("LeftButton")
        GCM.StaffFrame:SetScript("OnDragStart", GCM.StaffFrame.StartMoving)
        GCM.StaffFrame:SetScript("OnDragStop", GCM.StaffFrame.StopMovingOrSizing)
        
        -- Add resize grip
        local resizeButton = CreateFrame("Button", nil, GCM.StaffFrame)
        resizeButton:SetSize(16, 16)
        resizeButton:SetPoint("BOTTOMRIGHT", -6, 6)
        resizeButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
        resizeButton:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
        resizeButton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
        resizeButton:SetScript("OnMouseDown", function(self, button)
            if button == "LeftButton" then
                GCM.StaffFrame:StartSizing("BOTTOMRIGHT")
            end
        end)
        resizeButton:SetScript("OnMouseUp", function(self, button)
            GCM.StaffFrame:StopMovingOrSizing()
        end)
        
        -- Title
        GCM.StaffFrame.title = GCM.StaffFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        GCM.StaffFrame.title:SetPoint("TOP", 0, -10)
        GCM.StaffFrame.title:SetText("Arcane Consortium Staff Directory")
        
        -- Back Button
        local backBtn = CreateFrame("Button", nil, GCM.StaffFrame, "UIPanelButtonTemplate")
        backBtn:SetSize(100, 25)
        backBtn:SetPoint("TOPLEFT", 10, -10)
        backBtn:SetText("Back")
        backBtn:SetScript("OnClick", function()
            GCM.StaffFrame:Hide()
            GCM.MainFrame:Show()
        end)
        
        -- Staff Directory
        local scrollFrame = CreateFrame("ScrollFrame", nil, GCM.StaffFrame, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", 10, -40)
        scrollFrame:SetPoint("BOTTOMRIGHT", -30, 40)
        
        local scrollChild = CreateFrame("Frame")
        scrollChild:SetSize(scrollFrame:GetWidth(), 0)
        scrollFrame:SetScrollChild(scrollChild)
        
        -- Enhanced staff profiles with detailed information
        local staff = {
            {
                name = "Professor Charles Magnussen",
                rank = "Detective | Head", 
                department = "Investigations Division",
                specialization = "Forensical Investigation",
                experience = "15+ years",
                location = "Gilneas",
                contact = "Mail or Business Card",
                availability = "Mon-Fri 08:00-18:00",
                background = "Magical consultant for Gilneas, founded and ran the Arcane Consortium 2018, founded and breifly ran Kirin Tor Intelligence 2019 and founded and runs The Arcane Consortium: Detective Bureau 2025",
                notable_cases = "The Eight (Duskwood), Mortimer in Gilneas, The Starlight Slasher",
                skills = "Arcane Detection, Ivestigation, Case Management",
                portrait = "Interface\\AddOns\\GuildCaseManager\\media\\charles_profile.tga"
            },
            {
                name = "Profesor Alec Snowden", 
                rank = "Detective",
                department = "Field Operations",
                specialization = "Exotic Magics",
                experience = "12+ years with the Kirin Tor, previously of the Arane Consortium 2018",
                location = "Gilneas, Stormwind, Redridge",
                contact = "Magical communication crystal, Frequency 7",
                availability = "Varies by assignment, 24/7 emergency response",
                background = "Specializes in forensical investigations and the applied usage of exotic magics within cases",
                notable_cases = "The Nethershard Conspiracy, Black Market Portal Network, Corrupted Mana Crystal Trade",
                skills = "Undercover Operations, Surveillance, Arcane Tracking",
                portrait = "Interface\\AddOns\\GuildCaseManager\\media\\alec_portrait.tga"
            },
            {
                name = "Forensic Specialist Dr. Thalassic Voidbane",
                rank = "Chief Forensic Analyst",
                department = "Scientific Investigation Division",
                specialization = "Magical Forensics & Evidence Analysis",
                experience = "18 years in arcane sciences",
                location = "Dalaran Laboratory Complex, Level B2",
                contact = "Laboratory direct line, emergency pager",
                availability = "Mon-Sat 06:00-20:00, Emergency analysis available",
                background = "PhD in Thaumaturgic Sciences from the University of Dalaran. Pioneered several breakthrough techniques in magical residue analysis.",
                notable_cases = "Developed the \"Voidbane Trace Method\", solved the \"Impossible Teleportation Murder\", identified the Cursed Medallion killer",
                skills = "Magical Residue Analysis, Enchantment Identification, Temporal Evidence Recovery",
                portrait = "Interface\\AddOns\\GuildCaseManager\\media\\staff_forensic.tga"
            },
            {
                name = "Field Agent Coordinator Sarah Brightblade",
                rank = "Senior Agent",
                department = "Intelligence & Reconnaissance",
                specialization = "Information Gathering & Surveillance",
                experience = "8 years, former Alliance Intelligence",
                location = "Various field assignments",
                contact = "Secure messaging system, code clearance required",
                availability = "Assignment dependent, rapid deployment ready",
                background = "Expert in covert surveillance and intelligence gathering. Maintains extensive network of informants across Azeroth.",
                notable_cases = "The Defias Mage Cell Infiltration, Stormwind Noble Corruption Scandal, Twilight Cult Monitoring",
                skills = "Covert Operations, Intelligence Analysis, Network Management",
                portrait = "Interface\\AddOns\\GuildCaseManager\\media\\staff_agent.tga"
            },
            {
                name = "Archivist Keeper Aldric Scrollseeker",
                rank = "Chief Archivist",
                department = "Records & Historical Research",
                specialization = "Case History & Legal Precedent",
                experience = "25 years in magical archives",
                location = "Dalaran Archive Vault, Restricted Section",
                contact = "Archive appointment system, written requests",
                availability = "Mon-Fri 09:00-17:00, Research consultations by appointment",
                background = "Master of historical case law and precedent. Maintains the most comprehensive magical crime database in the known world.",
                notable_cases = "Catalogued over 10,000 magical crimes, Created the \"Scrollseeker Classification System\", Advisor on the Magna Carta Magica",
                skills = "Historical Research, Legal Database Management, Pattern Analysis",
                portrait = "Interface\\AddOns\\GuildCaseManager\\media\\staff_archivist.tga"
            }
        }
        
        local yOffset = -10
        
        for i, member in ipairs(staff) do
            -- Create container frame for each staff member
            local memberFrame = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
            memberFrame:SetSize(scrollChild:GetWidth() - 20, 220)
            memberFrame:SetPoint("TOPLEFT", 10, yOffset)
            memberFrame:SetBackdrop({
                bgFile = "Interface/Tooltips/UI-Tooltip-Background",
                edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
                tile = true,
                tileSize = 16,
                edgeSize = 16,
                insets = { left = 4, right = 4, top = 4, bottom = 4 }
            })
            memberFrame:SetBackdropColor(0.1, 0.1, 0.2, 0.8)
            memberFrame:SetBackdropBorderColor(0.3, 0.5, 0.8, 1)
            
            -- Portrait/Image
            local portrait = memberFrame:CreateTexture(nil, "ARTWORK")
            portrait:SetSize(80, 80)
            portrait:SetPoint("TOPLEFT", 10, -10)
            
            -- Try to load custom portrait, fallback to default
            if member.portrait then
                portrait:SetTexture(member.portrait)
                if not portrait:GetTexture() then
                    -- Fallback to a default portrait based on role
                    if string.find(member.rank, "Detective") then
                        portrait:SetTexture("Interface\\CHARACTERFRAME\\TempPortrait")
                    else
                        portrait:SetTexture("Interface\\CHARACTERFRAME\\TempPortraitMale")
                    end
                end
            else
                portrait:SetTexture("Interface\\CHARACTERFRAME\\TempPortrait")
            end
            
            -- Add border to portrait
            local portraitBorder = memberFrame:CreateTexture(nil, "BORDER")
            portraitBorder:SetSize(84, 84)
            portraitBorder:SetPoint("CENTER", portrait, "CENTER")
            portraitBorder:SetColorTexture(0.6, 0.6, 0.6, 1)
            
            -- Name and Rank (Header)
            local nameText = memberFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            nameText:SetPoint("TOPLEFT", portrait, "TOPRIGHT", 15, 0)
            nameText:SetText(string.format("|cff00ccff%s|r", member.name))
            nameText:SetWidth(memberFrame:GetWidth() - 110)
            nameText:SetJustifyH("LEFT")
            
            local rankText = memberFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            rankText:SetPoint("TOPLEFT", nameText, "BOTTOMLEFT", 0, -3)
            rankText:SetText(string.format("|cffFFD700%s - %s|r", member.rank, member.department))
            rankText:SetWidth(memberFrame:GetWidth() - 110)
            rankText:SetJustifyH("LEFT")
            
            -- Specialization
            local specText = memberFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            specText:SetPoint("TOPLEFT", rankText, "BOTTOMLEFT", 0, -8)
            specText:SetText(string.format("|cff9370dbSpecialization:|r %s", member.specialization))
            specText:SetWidth(memberFrame:GetWidth() - 110)
            specText:SetJustifyH("LEFT")
            
            -- Experience & Location
            local expText = memberFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            expText:SetPoint("TOPLEFT", specText, "BOTTOMLEFT", 0, -5)
            expText:SetText(string.format("|cffcccccc%s\nLocation: %s|r", member.experience, member.location))
            expText:SetWidth(memberFrame:GetWidth() - 110)
            expText:SetJustifyH("LEFT")
            
            -- Detailed information (below portrait)
            local detailsText = memberFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            detailsText:SetPoint("TOPLEFT", portrait, "BOTTOMLEFT", 0, -10)
            detailsText:SetWidth(memberFrame:GetWidth() - 20)
            detailsText:SetJustifyH("LEFT")
            
            local detailsContent = string.format(
                "|cff00ccffBackground:|r %s\n\n" ..
                "|cff00ccffNotable Cases/Achievements:|r %s\n\n" ..
                "|cff00ccffContact:|r %s | %s\n" ..
                "|cff00ccffSkills:|r %s",
                member.background,
                member.notable_cases,
                member.contact, member.availability,
                member.skills
            )
            detailsText:SetText(detailsContent)
            
            yOffset = yOffset - 235
        end
        
        -- Adjust scroll height to fit all content
        scrollChild:SetHeight(math.abs(yOffset) + 20)
    end
    
    GCM.StaffFrame:Show()
end

---------------------------------------- GJLE BUTTON---------------------------------------

function GCM.ShowGJLEFrame()
    GCM.MainFrame:Hide()
    
    if not GCM.GJLEFrame then
        GCM.GJLEFrame = CreateFrame("Frame", "GCM_GJLEFrame", UIParent, "BasicFrameTemplate")
        GCM.GJLEFrame:SetSize(450, 400)
        GCM.GJLEFrame:SetPoint("CENTER")
        GCM.GJLEFrame:SetMovable(true)
        GCM.GJLEFrame:SetResizable(true)
        GCM.GJLEFrame:EnableMouse(true)
        GCM.GJLEFrame:RegisterForDrag("LeftButton")
        GCM.GJLEFrame:SetScript("OnDragStart", GCM.GJLEFrame.StartMoving)
        GCM.GJLEFrame:SetScript("OnDragStop", GCM.GJLEFrame.StopMovingOrSizing)
        
        -- Add resize grip
        local resizeButton = CreateFrame("Button", nil, GCM.GJLEFrame)
        resizeButton:SetSize(16, 16)
        resizeButton:SetPoint("BOTTOMRIGHT", -6, 6)
        resizeButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
        resizeButton:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
        resizeButton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
        resizeButton:SetScript("OnMouseDown", function(self, button)
            if button == "LeftButton" then
                GCM.GJLEFrame:StartSizing("BOTTOMRIGHT")
            end
        end)
        resizeButton:SetScript("OnMouseUp", function(self, button)
            GCM.GJLEFrame:StopMovingOrSizing()
        end)
        
        -- Title
        GCM.GJLEFrame.title = GCM.GJLEFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        GCM.GJLEFrame.title:SetPoint("TOP", 0, -10)
        GCM.GJLEFrame.title:SetText("GJLE Hub")
        
        -- Back Button
        local backBtn = CreateFrame("Button", nil, GCM.GJLEFrame, "UIPanelButtonTemplate")
        backBtn:SetSize(100, 25)
        backBtn:SetPoint("TOPLEFT", 10, -10)
        backBtn:SetText("Back")
        backBtn:SetScript("OnClick", function()
            GCM.GJLEFrame:Hide()
            GCM.MainFrame:Show()
        end)
        
        -- Button settings for GJLE hub
        local buttonWidth = 150
        local buttonHeight = 30
        local buttonSpacing = 20
        
        -- Guidelines Button
        local guidelinesBtn = CreateFrame("Button", nil, GCM.GJLEFrame, "UIPanelButtonTemplate")
        guidelinesBtn:SetSize(buttonWidth, buttonHeight)
        guidelinesBtn:SetPoint("CENTER", 0, 30)
        guidelinesBtn:SetText("Guidelines")
        guidelinesBtn:SetScript("OnClick", function()
            GCM.ShowGuidelinesFrame()
        end)
        
        -- Add visual polish
        guidelinesBtn:SetNormalFontObject("GameFontNormal")
        guidelinesBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
        guidelinesBtn:GetHighlightTexture():SetBlendMode("ADD")
        guidelinesBtn:SetPushedTextOffset(0, -1)
        
        -- Correspondence Button
        local correspondenceBtn = CreateFrame("Button", nil, GCM.GJLEFrame, "UIPanelButtonTemplate")
        correspondenceBtn:SetSize(buttonWidth, buttonHeight)
        correspondenceBtn:SetPoint("CENTER", 0, -20)
        correspondenceBtn:SetText("Correspondence")
        correspondenceBtn:SetScript("OnClick", function()
            GCM.ShowCorrespondenceFrame()
        end)
        
        -- Add visual polish
        correspondenceBtn:SetNormalFontObject("GameFontNormal")
        correspondenceBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
        correspondenceBtn:GetHighlightTexture():SetBlendMode("ADD")
        correspondenceBtn:SetPushedTextOffset(0, -1)
        
        -- Close Button
        local closeBtn = CreateFrame("Button", nil, GCM.GJLEFrame, "UIPanelButtonTemplate")
        closeBtn:SetSize(100, 25)
        closeBtn:SetPoint("BOTTOM", 0, 20)
        closeBtn:SetText("Close")
        closeBtn:SetScript("OnClick", function()
            GCM.GJLEFrame:Hide()
        end)
    end
    
    GCM.GJLEFrame:Show()
end

-- Guidelines Frame
function GCM.ShowGuidelinesFrame()
    if GCM.GJLEFrame then GCM.GJLEFrame:Hide() end
    
    if not GCM.GuidelinesFrame then
        GCM.GuidelinesFrame = CreateFrame("Frame", "GCM_GuidelinesFrame", UIParent, "BasicFrameTemplate")
        GCM.GuidelinesFrame:SetSize(600, 500)
        GCM.GuidelinesFrame:SetPoint("CENTER")
        GCM.GuidelinesFrame:SetMovable(true)
        GCM.GuidelinesFrame:SetResizable(true)
        GCM.GuidelinesFrame:EnableMouse(true)
        GCM.GuidelinesFrame:RegisterForDrag("LeftButton")
        GCM.GuidelinesFrame:SetScript("OnDragStart", GCM.GuidelinesFrame.StartMoving)
        GCM.GuidelinesFrame:SetScript("OnDragStop", GCM.GuidelinesFrame.StopMovingOrSizing)
        
        -- Add resize grip
        local resizeButton = CreateFrame("Button", nil, GCM.GuidelinesFrame)
        resizeButton:SetSize(16, 16)
        resizeButton:SetPoint("BOTTOMRIGHT", -6, 6)
        resizeButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
        resizeButton:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
        resizeButton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
        resizeButton:SetScript("OnMouseDown", function(self, button)
            if button == "LeftButton" then
                GCM.GuidelinesFrame:StartSizing("BOTTOMRIGHT")
            end
        end)
        resizeButton:SetScript("OnMouseUp", function(self, button)
            GCM.GuidelinesFrame:StopMovingOrSizing()
        end)
        
        -- Title
        GCM.GuidelinesFrame.title = GCM.GuidelinesFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        GCM.GuidelinesFrame.title:SetPoint("TOP", 0, -10)
        GCM.GuidelinesFrame.title:SetText("GJLE Guidelines")
        
        -- Back Button
        local backBtn = CreateFrame("Button", nil, GCM.GuidelinesFrame, "UIPanelButtonTemplate")
        backBtn:SetSize(100, 25)
        backBtn:SetPoint("TOPLEFT", 10, -10)
        backBtn:SetText("Back")
        backBtn:SetScript("OnClick", function()
            GCM.GuidelinesFrame:Hide()
            if GCM.GJLEFrame then GCM.GJLEFrame:Show() end
        end)
        
        -- Content Area (Scrollable)
        local scrollFrame = CreateFrame("ScrollFrame", nil, GCM.GuidelinesFrame, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", 10, -40)
        scrollFrame:SetPoint("BOTTOMRIGHT", -30, 40)
        
        local scrollChild = CreateFrame("Frame")
        scrollChild:SetSize(scrollFrame:GetWidth(), 0)
        scrollFrame:SetScrollChild(scrollChild)
        
        -- Guidelines Content
        local content = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        content:SetPoint("TOPLEFT", 10, -10)
        content:SetWidth(scrollChild:GetWidth() - 20)
        content:SetJustifyH("LEFT")
        content:SetText([[
|cff00ccffGilneas Judiciary Law Enforcement Guidelines|r

This section contains guidelines and procedures for members.

|cff00ccffSection 1: General Conduct|r
• Maintain professional standards at all times, remember you represent not only Gilneas but the Kirin Tor also.
• Follow proper chain of command, Detectives report to their respective higherups. 
• Document all activities thoroughly, the truth is in the details. 

|cff00ccffSection 2: Investigation Procedures|r
• Always work in pairs when possible
• Secure evidence properly
• Interview witnesses systematically

|cff00ccffSection 3: Reporting Standards|r
• Use standardized report formats
• Submit reports within 24 hours
• Include all relevant details

|cff00ccffSection 4: Safety Protocols|r
• Assess risks before proceeding
• Maintain communication with headquarters
• Request backup when necessary

|cffFFFF00Note:|r These guidelines are subject to updates. Always refer to the latest version.
]])
        
        -- Adjust scroll height
        scrollChild:SetHeight(content:GetStringHeight() + 20)
    end
    
    GCM.GuidelinesFrame:Show()
end

-- Correspondence Frame
function GCM.ShowCorrespondenceFrame()
    if GCM.GJLEFrame then GCM.GJLEFrame:Hide() end
    
    if not GCM.CorrespondenceFrame then
        GCM.CorrespondenceFrame = CreateFrame("Frame", "GCM_CorrespondenceFrame", UIParent, "BasicFrameTemplate")
        GCM.CorrespondenceFrame:SetSize(600, 500)
        GCM.CorrespondenceFrame:SetPoint("CENTER")
        GCM.CorrespondenceFrame:SetMovable(true)
        GCM.CorrespondenceFrame:SetResizable(true)
        GCM.CorrespondenceFrame:EnableMouse(true)
        GCM.CorrespondenceFrame:RegisterForDrag("LeftButton")
        GCM.CorrespondenceFrame:SetScript("OnDragStart", GCM.CorrespondenceFrame.StartMoving)
        GCM.CorrespondenceFrame:SetScript("OnDragStop", GCM.CorrespondenceFrame.StopMovingOrSizing)
        
        -- Add resize grip
        local resizeButton = CreateFrame("Button", nil, GCM.CorrespondenceFrame)
        resizeButton:SetSize(16, 16)
        resizeButton:SetPoint("BOTTOMRIGHT", -6, 6)
        resizeButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
        resizeButton:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
        resizeButton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
        resizeButton:SetScript("OnMouseDown", function(self, button)
            if button == "LeftButton" then
                GCM.CorrespondenceFrame:StartSizing("BOTTOMRIGHT")
            end
        end)
        resizeButton:SetScript("OnMouseUp", function(self, button)
            GCM.CorrespondenceFrame:StopMovingOrSizing()
        end)
        
        -- Title
        GCM.CorrespondenceFrame.title = GCM.CorrespondenceFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        GCM.CorrespondenceFrame.title:SetPoint("TOP", 0, -10)
        GCM.CorrespondenceFrame.title:SetText("GJLE Correspondence")
        
        -- Back Button
        local backBtn = CreateFrame("Button", nil, GCM.CorrespondenceFrame, "UIPanelButtonTemplate")
        backBtn:SetSize(100, 25)
        backBtn:SetPoint("TOPLEFT", 10, -10)
        backBtn:SetText("Back")
        backBtn:SetScript("OnClick", function()
            GCM.CorrespondenceFrame:Hide()
            if GCM.GJLEFrame then GCM.GJLEFrame:Show() end
        end)
        
        -- Content Area (Scrollable)
        local scrollFrame = CreateFrame("ScrollFrame", nil, GCM.CorrespondenceFrame, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", 10, -40)
        scrollFrame:SetPoint("BOTTOMRIGHT", -30, 40)
        
        local scrollChild = CreateFrame("Frame")
        scrollChild:SetSize(scrollFrame:GetWidth(), 0)
        scrollFrame:SetScrollChild(scrollChild)
        
        -- Correspondence Content
        local content = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        content:SetPoint("TOPLEFT", 10, -10)
        content:SetWidth(scrollChild:GetWidth() - 20)
        content:SetJustifyH("LEFT")
        content:SetText([[
|cff00ccffGJLE Correspondence|r

This section contains official correspondence and communications.

|cff00ccffRecent Communications:|r

|cffFFD700[Date: Current]|r - |cff00ccffFrom: Guild Leadership|r
Subject: Weekly Operations Update
Content: All operatives are reminded to submit their weekly reports by the designated deadline. Recent activities show increased efficiency in case resolution.

|cffFFD700[Date: Previous Week]|r - |cff00ccffFrom: Field Operations|r
Subject: Equipment Requisition Approved
Content: Request for additional investigation tools has been approved. Equipment will be distributed through normal channels.

|cffFFD700[Date: Two Weeks Ago]|r - |cff00ccffFrom: Training Division|r
Subject: New Training Protocols
Content: Updated training protocols are now in effect. All personnel should review the new procedures in the Guidelines section.

|cff00ccffArchived Messages:|r
• Monthly Performance Reviews
• Policy Updates and Changes
• Inter-departmental Memos
• External Agency Communications

|cffFFFF00Note:|r Access to sensitive correspondence may be restricted based on clearance level.
]])
        
        -- Adjust scroll height
        scrollChild:SetHeight(content:GetStringHeight() + 20)
    end
    
    GCM.CorrespondenceFrame:Show()
end

--------------------------------KIRIN TOR BUTTON----------------------------------

function GCM.ShowKirinTorFrame()
    if GCM.MainFrame then GCM.MainFrame:Hide() end
    
    if not GCM.KirinTorFrame then
        GCM.KirinTorFrame = CreateFrame("Frame", "GCM_KirinTorFrame", UIParent, "BasicFrameTemplate")
        GCM.KirinTorFrame:SetSize(500, 550)
        GCM.KirinTorFrame:SetPoint("CENTER")
        GCM.KirinTorFrame:SetMovable(true)
        GCM.KirinTorFrame:SetResizable(true)
        GCM.KirinTorFrame:EnableMouse(true)
        GCM.KirinTorFrame:RegisterForDrag("LeftButton")
        GCM.KirinTorFrame:SetScript("OnDragStart", GCM.KirinTorFrame.StartMoving)
        GCM.KirinTorFrame:SetScript("OnDragStop", GCM.KirinTorFrame.StopMovingOrSizing)
        
        -- Add resize grip
        local resizeButton = CreateFrame("Button", nil, GCM.KirinTorFrame)
        resizeButton:SetSize(16, 16)
        resizeButton:SetPoint("BOTTOMRIGHT", -6, 6)
        resizeButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
        resizeButton:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
        resizeButton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
        resizeButton:SetScript("OnMouseDown", function(self, button)
            if button == "LeftButton" then
                GCM.KirinTorFrame:StartSizing("BOTTOMRIGHT")
            end
        end)
        resizeButton:SetScript("OnMouseUp", function(self, button)
            GCM.KirinTorFrame:StopMovingOrSizing()
        end)
        
        -- Title
        GCM.KirinTorFrame.title = GCM.KirinTorFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        GCM.KirinTorFrame.title:SetPoint("TOP", 0, -10)
        GCM.KirinTorFrame.title:SetText("Kirin Tor Hub")
        
        -- Add Kirin Tor logo
        local logo = GCM.KirinTorFrame:CreateTexture(nil, "ARTWORK")
        logo:SetSize(130, 120)
        logo:SetPoint("TOP", 0, -40)
        logo:SetTexture("Interface\\AddOns\\GuildCaseManager\\media\\KT_LOGO.tga")
        
        -- Back Button
        local backBtn = CreateFrame("Button", nil, GCM.KirinTorFrame, "UIPanelButtonTemplate")
        backBtn:SetSize(100, 20)
        backBtn:SetPoint("TOPLEFT", 10, -10)
        backBtn:SetText("Back")
        backBtn:SetScript("OnClick", function()
            GCM.KirinTorFrame:Hide()
            if GCM.MainFrame then GCM.MainFrame:Show() end
        end)
        
        -- Button settings for Kirin Tor hub
        local buttonWidth = 180
        local buttonHeight = 30
        local buttonSpacing = 15
        local startYOffset = 60
        
        -- Create Kirin Tor sub-buttons
        local kirinTorButtons = {
            {text = "Arcane Archives", onClick = GCM.ShowArcaneArchivesFrame},
            {text = "Portal Nexus", onClick = GCM.ShowPortalNexusFrame},
            {text = "Licences", onClick = GCM.ShowLicencesFrame},
            {text = "Enemies of the Kirin Tor", onClick = GCM.ShowEnemiesFrame},
            {text = "Artifact Database", onClick = GCM.ShowArtifactDatabaseFrame},
            {text = "Magical Theory and Research", onClick = GCM.ShowMagicalResearchFrame},
            {text = "Other Faction Standing", onClick = GCM.ShowFactionStandingFrame}
        }
        
        for i, btnInfo in ipairs(kirinTorButtons) do
            local btn = CreateFrame("Button", nil, GCM.KirinTorFrame, "UIPanelButtonTemplate")
            btn:SetSize(buttonWidth, buttonHeight)
            local yPos = startYOffset + (i - 1) * (buttonHeight + buttonSpacing)
            btn:SetPoint("BOTTOM", 0, yPos)
            btn:SetText(btnInfo.text)
            btn:SetScript("OnClick", btnInfo.onClick)
            
            -- Add visual polish to each button
            btn:SetNormalFontObject("GameFontNormal")
            btn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
            btn:GetHighlightTexture():SetBlendMode("ADD")
            btn:SetPushedTextOffset(0, -1)
        end
        
        -- Close Button
        local closeBtn = CreateFrame("Button", nil, GCM.KirinTorFrame, "UIPanelButtonTemplate")
        closeBtn:SetSize(100, 25)
        closeBtn:SetPoint("BOTTOM", 0, 10)
        closeBtn:SetText("Close")
        closeBtn:SetScript("OnClick", function()
            GCM.KirinTorFrame:Hide()
        end)
    end
    
    GCM.KirinTorFrame:Show()
end

-- Arcane Archives Frame
function GCM.ShowArcaneArchivesFrame()
    if GCM.KirinTorFrame then GCM.KirinTorFrame:Hide() end
    
    if not GCM.ArcaneArchivesFrame then
        GCM.ArcaneArchivesFrame = CreateFrame("Frame", "GCM_ArcaneArchivesFrame", UIParent, "BasicFrameTemplate")
        GCM.ArcaneArchivesFrame:SetSize(600, 500)
        GCM.ArcaneArchivesFrame:SetPoint("CENTER")
        GCM.ArcaneArchivesFrame:SetMovable(true)
        GCM.ArcaneArchivesFrame:SetResizable(true)
        GCM.ArcaneArchivesFrame:EnableMouse(true)
        GCM.ArcaneArchivesFrame:RegisterForDrag("LeftButton")
        GCM.ArcaneArchivesFrame:SetScript("OnDragStart", GCM.ArcaneArchivesFrame.StartMoving)
        GCM.ArcaneArchivesFrame:SetScript("OnDragStop", GCM.ArcaneArchivesFrame.StopMovingOrSizing)
        
        -- Title
        GCM.ArcaneArchivesFrame.title = GCM.ArcaneArchivesFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        GCM.ArcaneArchivesFrame.title:SetPoint("TOP", 0, -10)
        GCM.ArcaneArchivesFrame.title:SetText("Arcane Archives")
        
        -- Back Button
        local backBtn = CreateFrame("Button", nil, GCM.ArcaneArchivesFrame, "UIPanelButtonTemplate")
        backBtn:SetSize(100, 25)
        backBtn:SetPoint("TOPLEFT", 10, -10)
        backBtn:SetText("Back")
        backBtn:SetScript("OnClick", function()
            GCM.ArcaneArchivesFrame:Hide()
            if GCM.KirinTorFrame then GCM.KirinTorFrame:Show() end
        end)
        
        -- Content Area (Scrollable)
        local scrollFrame = CreateFrame("ScrollFrame", nil, GCM.ArcaneArchivesFrame, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", 10, -40)
        scrollFrame:SetPoint("BOTTOMRIGHT", -30, 40)
        
        local scrollChild = CreateFrame("Frame")
        scrollChild:SetSize(scrollFrame:GetWidth(), 0)
        scrollFrame:SetScrollChild(scrollChild)
        
        -- Archives Content
        local content = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        content:SetPoint("TOPLEFT", 10, -10)
        content:SetWidth(scrollChild:GetWidth() - 20)
        content:SetJustifyH("LEFT")
        content:SetText([[
|cff6a5acdArcane Archives - Kirin Tor Knowledge Repository|r

Welcome to the Arcane Archives, the premier magical knowledge repository of the Kirin Tor.

|cff9370dbRecent Acquisitions:|r
• |cffffff00"Theoretical Applications of Temporal Flux in Defensive Enchantments"|r - By Archmage Thessarian
• |cffffff00"Comparative Analysis of Ley Line Convergence Points"|r - Academy Research Division
• |cffffff00"Cataloguing Fel Contamination: A Preventative Guide"|r - Purification Committee
• |cffffff00"Ancient Troll Magical Practices and Their Modern Applications"|r - Cultural Exchange Department

|cff9370dbArchive Categories:|r
|cff00ccff• Arcane Theory and Practice|r
  - Fundamental magical principles
  - Advanced spellcrafting techniques
  - Arcane energy manipulation studies

|cff00ccff• Historical Magical Events|r
  - The War of the Ancients: Magical Perspectives
  - Legion Invasions and Magical Countermeasures
  - Scourge Necromancy Analysis

|cff00ccff• Artifact Documentation|r
  - Catalogued magical artifacts
  - Containment protocols
  - Artifact interaction studies

|cff00ccff• Planar Studies|r
  - Dimensional theory
  - Portal mechanics and safety
  - Extraplanar entity documentation

|cffFFFF00Access Note:|r Many documents require appropriate clearance level. Contact your supervisor for restricted material access.

|cffFFFF00Recent Updates:|r
- New section added: "Post-Shadowlands Magical Anomalies"
- Updated safety protocols for handling Void-touched materials
- Expanded collection of Zandalari magical practices
]])
        
        -- Adjust scroll height
        scrollChild:SetHeight(content:GetStringHeight() + 20)
    end
    
    GCM.ArcaneArchivesFrame:Show()
end

-- Portal Nexus Frame
function GCM.ShowPortalNexusFrame()
    if GCM.KirinTorFrame then GCM.KirinTorFrame:Hide() end
    
    if not GCM.PortalNexusFrame then
        GCM.PortalNexusFrame = CreateFrame("Frame", "GCM_PortalNexusFrame", UIParent, "BasicFrameTemplate")
        GCM.PortalNexusFrame:SetSize(600, 500)
        GCM.PortalNexusFrame:SetPoint("CENTER")
        GCM.PortalNexusFrame:SetMovable(true)
        GCM.PortalNexusFrame:SetResizable(true)
        GCM.PortalNexusFrame:EnableMouse(true)
        GCM.PortalNexusFrame:RegisterForDrag("LeftButton")
        GCM.PortalNexusFrame:SetScript("OnDragStart", GCM.PortalNexusFrame.StartMoving)
        GCM.PortalNexusFrame:SetScript("OnDragStop", GCM.PortalNexusFrame.StopMovingOrSizing)
        
        -- Title
        GCM.PortalNexusFrame.title = GCM.PortalNexusFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        GCM.PortalNexusFrame.title:SetPoint("TOP", 0, -10)
        GCM.PortalNexusFrame.title:SetText("Portal Nexus Control")
        
        -- Back Button
        local backBtn = CreateFrame("Button", nil, GCM.PortalNexusFrame, "UIPanelButtonTemplate")
        backBtn:SetSize(100, 25)
        backBtn:SetPoint("TOPLEFT", 10, -10)
        backBtn:SetText("Back")
        backBtn:SetScript("OnClick", function()
            GCM.PortalNexusFrame:Hide()
            if GCM.KirinTorFrame then GCM.KirinTorFrame:Show() end
        end)
        
        -- Content Area (Scrollable)
        local scrollFrame = CreateFrame("ScrollFrame", nil, GCM.PortalNexusFrame, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", 10, -40)
        scrollFrame:SetPoint("BOTTOMRIGHT", -30, 40)
        
        local scrollChild = CreateFrame("Frame")
        scrollChild:SetSize(scrollFrame:GetWidth(), 0)
        scrollFrame:SetScrollChild(scrollChild)
        
        -- Portal Nexus Content
        local content = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        content:SetPoint("TOPLEFT", 10, -10)
        content:SetWidth(scrollChild:GetWidth() - 20)
        content:SetJustifyH("LEFT")
        content:SetText([[
|cff6a5acdPortal Nexus - Teleportation Network Control|r

Manage and monitor the vast network of magical portals maintained by the Kirin Tor.

|cff9370dbActive Portal Network Status:|r
|cff00ff00• Dalaran Central Hub:|r |cff00ff00OPERATIONAL|r
|cff00ff00• Stormwind Embassy:|r |cff00ff00OPERATIONAL|r
|cff00ff00• Ironforge Mystic Ward:|r |cff00ff00OPERATIONAL|r
|cffFFFF00• Boralus Portal Sanctum:|r |cffFFFF00MAINTENANCE|r
|cff00ff00• Darnassus Memorial Gate:|r |cff00ff00OPERATIONAL|r
|cffFFFF00• Shattrath City:|r |cffFFFF00LIMITED ACCESS|r
|cff00ff00• Shrine of Seven Stars:|r |cff00ff00OPERATIONAL|r
|cff00ff00• Valdrakken:|r |cff00ff00OPERATIONAL|r

|cffff0000• Legion-affected Areas:|r |cffff0000QUARANTINED|r
|cffff0000• Shadowlands Rifts:|r |cffff0000SEALED|r

|cff9370dbRecent Portal Activity:|r
|cffffff00[Today - 14:23]|r Emergency transport to Stormwind - Medical evacuation
|cffffff00[Today - 11:15]|r Routine supply delivery to Valdrakken outpost
|cffffff00[Yesterday - 18:45]|r Diplomatic mission to Boralus (postponed due to maintenance)
|cffffff00[Yesterday - 09:30]|r Academic exchange with Shrine of Seven Stars

|cff9370dbPortal Regulations:|r
|cff00ccff• Authorization Level 1:|r City-to-city civilian transport
|cff00ccff• Authorization Level 2:|r Military and diplomatic missions
|cff00ccff• Authorization Level 3:|r Emergency and rescue operations
|cff00ccff• Authorization Level 4:|r Restricted dimensional research

|cffFFFF00Maintenance Schedule:|r
- Boralus Portal: Estimated completion 48 hours
- Routine network stability check: Weekly on Tuesdays
- Emergency protocol drills: Monthly

|cffff0000WARNING:|r Unauthorized portal creation within 500 yards of established nexus points is strictly prohibited and may result in dimensional instability.
]])
        
        -- Adjust scroll height
        scrollChild:SetHeight(content:GetStringHeight() + 20)
    end
    
    GCM.PortalNexusFrame:Show()
end

-- Licences Frame
function GCM.ShowLicencesFrame()
    if GCM.KirinTorFrame then GCM.KirinTorFrame:Hide() end
    
    if not GCM.LicencesFrame then
        GCM.LicencesFrame = CreateFrame("Frame", "GCM_LicencesFrame", UIParent, "BasicFrameTemplate")
        GCM.LicencesFrame:SetSize(600, 500)
        GCM.LicencesFrame:SetPoint("CENTER")
        GCM.LicencesFrame:SetMovable(true)
        GCM.LicencesFrame:SetResizable(true)
        GCM.LicencesFrame:EnableMouse(true)
        GCM.LicencesFrame:RegisterForDrag("LeftButton")
        GCM.LicencesFrame:SetScript("OnDragStart", GCM.LicencesFrame.StartMoving)
        GCM.LicencesFrame:SetScript("OnDragStop", GCM.LicencesFrame.StopMovingOrSizing)
        
        -- Title
        GCM.LicencesFrame.title = GCM.LicencesFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        GCM.LicencesFrame.title:SetPoint("TOP", 0, -10)
        GCM.LicencesFrame.title:SetText("Magical Licences & Certifications")
        
        -- Back Button
        local backBtn = CreateFrame("Button", nil, GCM.LicencesFrame, "UIPanelButtonTemplate")
        backBtn:SetSize(100, 25)
        backBtn:SetPoint("TOPLEFT", 10, -10)
        backBtn:SetText("Back")
        backBtn:SetScript("OnClick", function()
            GCM.LicencesFrame:Hide()
            if GCM.KirinTorFrame then GCM.KirinTorFrame:Show() end
        end)
        
        -- Content Area (Scrollable)
        local scrollFrame = CreateFrame("ScrollFrame", nil, GCM.LicencesFrame, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", 10, -40)
        scrollFrame:SetPoint("BOTTOMRIGHT", -30, 40)
        
        local scrollChild = CreateFrame("Frame")
        scrollChild:SetSize(scrollFrame:GetWidth(), 0)
        scrollFrame:SetScrollChild(scrollChild)
        
        -- Licences Content
        local content = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        content:SetPoint("TOPLEFT", 10, -10)
        content:SetWidth(scrollChild:GetWidth() - 20)
        content:SetJustifyH("LEFT")
        content:SetText([[
|cff6a5acdMagical Licences & Certifications Registry|r

Official documentation for all magical practice authorizations within Kirin Tor jurisdiction.

|cff9370dbLicence Categories:|r

|cff00ccff• Class A - Basic Magical Practice|r
  - Cantrip and minor spell authorization
  - Valid for: Apprentice-level practitioners
  - Duration: 2 years
  - Renewal required: Written examination

|cff00ccff• Class B - Advanced Arcane Arts|r
  - Intermediate to advanced spellcasting
  - Valid for: Certified mages and specialists
  - Duration: 5 years
  - Renewal required: Practical demonstration + ethics review

|cff00ccff• Class C - Specialized Magical Fields|r
  - Enchantment, divination, transmutation specializations
  - Valid for: Master-level practitioners
  - Duration: 7 years
  - Renewal required: Peer review + continued education

|cff00ccff• Class D - Portal Magic Authorization|r
  - Teleportation and dimensional magic
  - Valid for: Certified portal mages only
  - Duration: 3 years
  - Renewal required: Rigorous testing + psychological evaluation

|cff00ccff• Class E - Dangerous Magic Permit|r
  - Necromancy research, void studies, fel containment
  - Valid for: Senior researchers with security clearance
  - Duration: 1 year
  - Renewal required: Full investigation + supervisor approval

|cff9370dbRecent Licence Actions:|r
|cff00ff00• Approved:|r 15 Class A renewals
|cff00ff00• Approved:|r 8 Class B new applications
|cff00ff00• Approved:|r 2 Class C specialization upgrades
|cffFFFF00• Under Review:|r 3 Class D portal certifications
|cffff0000• Suspended:|r 1 Class E permit (pending investigation)
|cffff0000• Revoked:|r 2 Class B licences (ethical violations)

|cffFFFF00Application Requirements:|r
- Completed application form KT-MAG-001
- Proof of magical education or equivalent experience
- Character references from 2 certified practitioners
- Background security check
- Application fee: 50 gold (non-refundable)

|cffFFFF00Contact Information:|r
- Licence Office: Dalaran, Violet Gate District
- Hours: 8 AM - 6 PM, Monday through Friday
- Emergency licence queries: Contact Duty Magistrate
]])
        
        -- Adjust scroll height
        scrollChild:SetHeight(content:GetStringHeight() + 20)
    end
    
    GCM.LicencesFrame:Show()
end

-- Enemies of the Kirin Tor Frame
function GCM.ShowEnemiesFrame()
    if GCM.KirinTorFrame then GCM.KirinTorFrame:Hide() end
    
    if not GCM.EnemiesFrame then
        GCM.EnemiesFrame = CreateFrame("Frame", "GCM_EnemiesFrame", UIParent, "BasicFrameTemplate")
        GCM.EnemiesFrame:SetSize(600, 500)
        GCM.EnemiesFrame:SetPoint("CENTER")
        GCM.EnemiesFrame:SetMovable(true)
        GCM.EnemiesFrame:SetResizable(true)
        GCM.EnemiesFrame:EnableMouse(true)
        GCM.EnemiesFrame:RegisterForDrag("LeftButton")
        GCM.EnemiesFrame:SetScript("OnDragStart", GCM.EnemiesFrame.StartMoving)
        GCM.EnemiesFrame:SetScript("OnDragStop", GCM.EnemiesFrame.StopMovingOrSizing)
        
        -- Title
        GCM.EnemiesFrame.title = GCM.EnemiesFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        GCM.EnemiesFrame.title:SetPoint("TOP", 0, -10)
        GCM.EnemiesFrame.title:SetText("Enemies of the Kirin Tor")
        
        -- Back Button
        local backBtn = CreateFrame("Button", nil, GCM.EnemiesFrame, "UIPanelButtonTemplate")
        backBtn:SetSize(100, 25)
        backBtn:SetPoint("TOPLEFT", 10, -10)
        backBtn:SetText("Back")
        backBtn:SetScript("OnClick", function()
            GCM.EnemiesFrame:Hide()
            if GCM.KirinTorFrame then GCM.KirinTorFrame:Show() end
        end)
        
        -- Content Area (Scrollable)
        local scrollFrame = CreateFrame("ScrollFrame", nil, GCM.EnemiesFrame, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", 10, -40)
        scrollFrame:SetPoint("BOTTOMRIGHT", -30, 40)
        
        local scrollChild = CreateFrame("Frame")
        scrollChild:SetSize(scrollFrame:GetWidth(), 0)
        scrollFrame:SetScrollChild(scrollChild)
        
        -- Enemies Content
        local content = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        content:SetPoint("TOPLEFT", 10, -10)
        content:SetWidth(scrollChild:GetWidth() - 20)
        content:SetJustifyH("LEFT")
        content:SetText([[
|cffff0000CLASSIFIED - ENEMIES OF THE KIRIN TOR|r
|cffff0000SECURITY CLEARANCE LEVEL 3 REQUIRED|r

|cff9370dbActive Threats - High Priority:|r

|cffff0000• The Defias Spellbreakers|r
  Status: |cffff0000ACTIVE THREAT|r
  Leadership: Unknown masked figure "The Arcane Bane"
  Activities: Sabotaging magical infrastructure, assassinating mages
  Last Known Location: Westfall underground network
  Threat Level: |cffff0000EXTREME|r

|cffff0000• Twilight's Hammer Remnants|r
  Status: |cffff0000ACTIVE THREAT|r
  Leadership: Scattered cell structure
  Activities: Void corruption, dimensional breaches
  Last Known Location: Multiple remote locations
  Threat Level: |cffff0000HIGH|r

|cffFFFF00• Sunreavers (Defector Faction)|r
  Status: |cffFFFF00MONITORING|r
  Leadership: Unknown defector elements
  Activities: Information theft, political manipulation
  Last Known Location: Various
  Threat Level: |cffFFFF00MEDIUM|r

|cff9370dbWanted Individuals:|r

|cffff0000• "The Void Whisperer"|r - Reward: 10,000 Gold
  Description: Former Kirin Tor mage, turned to void magic
  Crimes: Murder of three council members, void corruption
  Warning: |cffff0000EXTREMELY DANGEROUS|r - Do not approach alone

|cffff0000• Magister Shadowbane|r - Reward: 5,000 Gold
  Description: Exiled for forbidden necromancy research
  Crimes: Illegal experimentation, theft of artifacts
  Warning: Known to use mind control magic

|cffFFFF00• The Rogue Enchanter|r - Reward: 2,000 Gold
  Description: Unlicensed magical practice, fraud
  Crimes: Selling cursed items, false magical services
  Warning: Items may have delayed harmful effects

|cff9370dbRecent Intelligence:|r
|cffffff00[Today]|r Increased Defias Spellbreaker activity near Goldshire
|cffffff00[2 days ago]|r Suspicious void energy detected in Duskwood
|cffffff00[1 week ago]|r Unauthorized portal detected in Stranglethorn

|cffff0000SECURITY PROTOCOLS:|r
- Report all suspicious magical activity immediately
- Do not engage high-priority targets without backup
- All void-related incidents require immediate containment
- Magical signature scanning mandatory at all checkpoints

|cffFFFF00For reporting suspected enemies or seeking additional intelligence, contact the Security Division immediately.|r
]])
        
        -- Adjust scroll height
        scrollChild:SetHeight(content:GetStringHeight() + 20)
    end
    
    GCM.EnemiesFrame:Show()
end

-- Artifact Database Frame
function GCM.ShowArtifactDatabaseFrame()
    if GCM.KirinTorFrame then GCM.KirinTorFrame:Hide() end
    
    if not GCM.ArtifactDatabaseFrame then
        GCM.ArtifactDatabaseFrame = CreateFrame("Frame", "GCM_ArtifactDatabaseFrame", UIParent, "BasicFrameTemplate")
        GCM.ArtifactDatabaseFrame:SetSize(600, 500)
        GCM.ArtifactDatabaseFrame:SetPoint("CENTER")
        GCM.ArtifactDatabaseFrame:SetMovable(true)
        GCM.ArtifactDatabaseFrame:SetResizable(true)
        GCM.ArtifactDatabaseFrame:EnableMouse(true)
        GCM.ArtifactDatabaseFrame:RegisterForDrag("LeftButton")
        GCM.ArtifactDatabaseFrame:SetScript("OnDragStart", GCM.ArtifactDatabaseFrame.StartMoving)
        GCM.ArtifactDatabaseFrame:SetScript("OnDragStop", GCM.ArtifactDatabaseFrame.StopMovingOrSizing)
        
        -- Title
        GCM.ArtifactDatabaseFrame.title = GCM.ArtifactDatabaseFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        GCM.ArtifactDatabaseFrame.title:SetPoint("TOP", 0, -10)
        GCM.ArtifactDatabaseFrame.title:SetText("Magical Artifact Database")
        
        -- Back Button
        local backBtn = CreateFrame("Button", nil, GCM.ArtifactDatabaseFrame, "UIPanelButtonTemplate")
        backBtn:SetSize(100, 25)
        backBtn:SetPoint("TOPLEFT", 10, -10)
        backBtn:SetText("Back")
        backBtn:SetScript("OnClick", function()
            GCM.ArtifactDatabaseFrame:Hide()
            if GCM.KirinTorFrame then GCM.KirinTorFrame:Show() end
        end)
        
        -- Content Area (Scrollable)
        local scrollFrame = CreateFrame("ScrollFrame", nil, GCM.ArtifactDatabaseFrame, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", 10, -40)
        scrollFrame:SetPoint("BOTTOMRIGHT", -30, 40)
        
        local scrollChild = CreateFrame("Frame")
        scrollChild:SetSize(scrollFrame:GetWidth(), 0)
        scrollFrame:SetScrollChild(scrollChild)
        
        -- Artifact Database Content
        local content = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        content:SetPoint("TOPLEFT", 10, -10)
        content:SetWidth(scrollChild:GetWidth() - 20)
        content:SetJustifyH("LEFT")
        content:SetText([[
|cff6a5acdMagical Artifact Database - Kirin Tor Registry|r

Comprehensive catalog of magical artifacts under Kirin Tor protection and study.

|cff9370dbRecently Cataloged Artifacts:|r

|cffffff00• Shard of the Sunwell (Replica)|r
  Classification: |cff00ccffClass B - Moderate Power|r
  Location: |cff00ff00Vault 7-A, Secured|r
  Description: Artificially created sunwell crystal fragment
  Properties: Minor holy energy generation, light manipulation
  Containment: Standard magical suppression field

|cffffff00• Tome of Eternal Binding|r
  Classification: |cffFFFF00Class C - High Risk|r
  Location: |cffFFFF00Restricted Vault 12, Level 3 Security|r
  Description: Ancient tome containing powerful binding spells
  Properties: Demon summoning and binding (theoretical)
  Containment: Sealed, blessed containment, 24/7 monitoring

|cffffff00• Crystal of Temporal Echoes|r
  Classification: |cffff0000Class D - Extreme Danger|r
  Location: |cffff0000Maximum Security Vault, Dalaran Core|r
  Description: Crystallized time magic from Caverns of Time
  Properties: Limited temporal manipulation, reality distortion
  Containment: Chronium-lined vault, multiple failsafes

|cffffff00• Pendant of Whispering Shadows|r
  Classification: |cff00ccffClass A - Low Risk|r
  Location: |cff00ff00Study Lab 3, Available for Research|r
  Description: Jewelry piece with minor shadow affinity
  Properties: Enhanced stealth abilities, shadow resistance
  Containment: Standard display case

|cff9370dbArtifact Classifications:|r
|cff00ccff• Class A:|r Low-power, minimal risk, suitable for study
|cffFFFF00• Class B:|r Moderate power, controlled research only
|cffFFFF00• Class C:|r High risk, restricted access, senior researchers
|cffff0000• Class D:|r Extreme danger, council approval required
|cffff0000• Class E:|r World-ending potential, sealed indefinitely

|cff9370dbRecent Acquisitions:|r
- Acquired from Stormwind auction: "Mage's Focus Crystal"
- Confiscated from illegal dealer: "Corrupted Essence Vial"
- Donated by retiring mage: "Scroll of Greater Teleportation"

|cff9370dbMissing/Stolen Artifacts:|r
|cffff0000• Ring of Elemental Command|r - |cffff0000STOLEN 3 weeks ago|r
  Last seen: Stormwind Mage Quarter
  Suspect: Unknown thief with teleportation abilities
  Reward for recovery: 5,000 gold

|cffFFFF00Artifact Research Requests:|r
To request access to artifacts for research purposes, submit Form KT-ART-Research to the Artifact Committee. Include detailed research proposal and security clearance documentation.
]])
        
        -- Adjust scroll height
        scrollChild:SetHeight(content:GetStringHeight() + 20)
    end
    
    GCM.ArtifactDatabaseFrame:Show()
end

-- Magical Theory and Research Frame
function GCM.ShowMagicalResearchFrame()
    if GCM.KirinTorFrame then GCM.KirinTorFrame:Hide() end
    
    if not GCM.MagicalResearchFrame then
        GCM.MagicalResearchFrame = CreateFrame("Frame", "GCM_MagicalResearchFrame", UIParent, "BasicFrameTemplate")
        GCM.MagicalResearchFrame:SetSize(600, 500)
        GCM.MagicalResearchFrame:SetPoint("CENTER")
        GCM.MagicalResearchFrame:SetMovable(true)
        GCM.MagicalResearchFrame:SetResizable(true)
        GCM.MagicalResearchFrame:EnableMouse(true)
        GCM.MagicalResearchFrame:RegisterForDrag("LeftButton")
        GCM.MagicalResearchFrame:SetScript("OnDragStart", GCM.MagicalResearchFrame.StartMoving)
        GCM.MagicalResearchFrame:SetScript("OnDragStop", GCM.MagicalResearchFrame.StopMovingOrSizing)
        
        -- Title
        GCM.MagicalResearchFrame.title = GCM.MagicalResearchFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        GCM.MagicalResearchFrame.title:SetPoint("TOP", 0, -10)
        GCM.MagicalResearchFrame.title:SetText("Magical Theory & Research")
        
        -- Back Button
        local backBtn = CreateFrame("Button", nil, GCM.MagicalResearchFrame, "UIPanelButtonTemplate")
        backBtn:SetSize(100, 25)
        backBtn:SetPoint("TOPLEFT", 10, -10)
        backBtn:SetText("Back")
        backBtn:SetScript("OnClick", function()
            GCM.MagicalResearchFrame:Hide()
            if GCM.KirinTorFrame then GCM.KirinTorFrame:Show() end
        end)
        
        -- Content Area (Scrollable)
        local scrollFrame = CreateFrame("ScrollFrame", nil, GCM.MagicalResearchFrame, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", 10, -40)
        scrollFrame:SetPoint("BOTTOMRIGHT", -30, 40)
        
        local scrollChild = CreateFrame("Frame")
        scrollChild:SetSize(scrollFrame:GetWidth(), 0)
        scrollFrame:SetScrollChild(scrollChild)
        
        -- Research Content
        local content = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        content:SetPoint("TOPLEFT", 10, -10)
        content:SetWidth(scrollChild:GetWidth() - 20)
        content:SetJustifyH("LEFT")
        content:SetText([[
|cff6a5acdMagical Theory & Research Division|r

Advancing magical understanding through rigorous research and experimentation.

|cff9370dbActive Research Projects:|r

|cffffff00• Project: Ley Line Harmonics|r
  Lead Researcher: Archmage Veras Windweaver
  Status: |cff00ff00Phase 3 - Field Testing|r
  Objective: Optimize ley line energy distribution across Azeroth
  Funding: 50,000 gold (Approved)
  Expected Completion: 8 months

|cffffff00• Project: Void Resistance Theory|r
  Lead Researcher: Master Lumina Dawnforge
  Status: |cffFFFF00Phase 2 - Laboratory Analysis|r
  Objective: Develop improved void corruption countermeasures
  Funding: 35,000 gold (Under Review)
  Expected Completion: 12 months

|cffffff00• Project: Arcane Fusion Principles|r
  Lead Researcher: Professor Thalmic Sparkweaver
  Status: |cff00ff00Phase 4 - Practical Application|r
  Objective: Create more efficient spell-weaving techniques
  Funding: 25,000 gold (Approved)
  Expected Completion: 4 months

|cffffff00• Project: Dimensional Anchor Theory|r
  Lead Researcher: Dr. Magistrix Thornfield
  Status: |cffff0000Phase 1 - Theoretical Foundation|r
  Objective: Prevent unwanted dimensional breaches
  Funding: 75,000 gold (Pending Council Approval)
  Expected Completion: 18 months

|cff9370dbRecent Discoveries:|r

|cff00ccff• Mana Crystallization Enhancement:|r
  Breakthrough in creating more stable mana crystals
  Applications: Improved magical item construction
  Status: Patent filed, preparing for implementation

|cff00ccff• Teleportation Safety Protocols:|r
  New safety measures reduce teleportation mishaps by 73%
  Applications: Portal network improvements
  Status: Implementing across all portal stations

|cff00ccff• Elemental Binding Stabilization:|r
  Method to create longer-lasting elemental summons
  Applications: Enhanced magical constructs
  Status: Classified - Military applications being evaluated

|cff9370dbUpcoming Conferences & Symposiums:|r
|cffffff00• Annual Arcane Theory Symposium|r - Next month in Dalaran
|cffffff00• Inter-School Magical Exchange|r - Quarterly meeting with other magical institutions
|cffffff00• Void Studies Workshop|r - Special session on void corruption research

|cff9370dbResearch Funding Applications:|r
Researchers seeking funding should submit proposals using Form KT-RES-Fund.
All applications must include:
- Detailed research methodology
- Expected outcomes and applications
- Risk assessment
- Timeline and budget breakdown
- Peer review recommendations

|cffFFFF00Ethics Committee Reminder:|r
All research involving sentient beings, dangerous magic, or potential weapons development must receive Ethics Committee approval before commencement.
]])
        
        -- Adjust scroll height
        scrollChild:SetHeight(content:GetStringHeight() + 20)
    end
    
    GCM.MagicalResearchFrame:Show()
end

-- Faction Standing Frame
function GCM.ShowFactionStandingFrame()
    if GCM.KirinTorFrame then GCM.KirinTorFrame:Hide() end
    
    if not GCM.FactionStandingFrame then
        GCM.FactionStandingFrame = CreateFrame("Frame", "GCM_FactionStandingFrame", UIParent, "BasicFrameTemplate")
        GCM.FactionStandingFrame:SetSize(600, 500)
        GCM.FactionStandingFrame:SetPoint("CENTER")
        GCM.FactionStandingFrame:SetMovable(true)
        GCM.FactionStandingFrame:SetResizable(true)
        GCM.FactionStandingFrame:EnableMouse(true)
        GCM.FactionStandingFrame:RegisterForDrag("LeftButton")
        GCM.FactionStandingFrame:SetScript("OnDragStart", GCM.FactionStandingFrame.StartMoving)
        GCM.FactionStandingFrame:SetScript("OnDragStop", GCM.FactionStandingFrame.StopMovingOrSizing)
        
        -- Title
        GCM.FactionStandingFrame.title = GCM.FactionStandingFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        GCM.FactionStandingFrame.title:SetPoint("TOP", 0, -10)
        GCM.FactionStandingFrame.title:SetText("Other Faction Relations")
        
        -- Back Button
        local backBtn = CreateFrame("Button", nil, GCM.FactionStandingFrame, "UIPanelButtonTemplate")
        backBtn:SetSize(100, 25)
        backBtn:SetPoint("TOPLEFT", 10, -10)
        backBtn:SetText("Back")
        backBtn:SetScript("OnClick", function()
            GCM.FactionStandingFrame:Hide()
            if GCM.KirinTorFrame then GCM.KirinTorFrame:Show() end
        end)
        
        -- Content Area (Scrollable)
        local scrollFrame = CreateFrame("ScrollFrame", nil, GCM.FactionStandingFrame, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", 10, -40)
        scrollFrame:SetPoint("BOTTOMRIGHT", -30, 40)
        
        local scrollChild = CreateFrame("Frame")
        scrollChild:SetSize(scrollFrame:GetWidth(), 0)
        scrollFrame:SetScrollChild(scrollChild)
        
        -- Faction Standing Content
        local content = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        content:SetPoint("TOPLEFT", 10, -10)
        content:SetWidth(scrollChild:GetWidth() - 20)
        content:SetJustifyH("LEFT")
        content:SetText([[
|cff6a5acdKirin Tor Diplomatic Relations Status|r

Current standings with major factions and organizations across Azeroth.

|cff9370dbAlliance Factions:|r

|cff00ff00• Kingdom of Stormwind|r - |cff00ff00ALLIED|r
  Relationship Status: Strong diplomatic ties
  Recent Cooperation: Joint magical defense initiatives
  Ambassador: Lady Katrana Prestor (liaison)
  Trade Agreements: Magic item exchange, portal services

|cff00ff00• Ironforge|r - |cff00ff00ALLIED|r
  Relationship Status: Excellent, long-standing friendship
  Recent Cooperation: Archaeological expeditions, titan research
  Ambassador: Explorer Brann Bronzebeard (honorary)
  Trade Agreements: Gemstone enhancement, runic research

|cff00ff00• Darnassus (Memorial)|r - |cff00ccffHONORED|r
  Relationship Status: Memorial services, refugee support
  Recent Cooperation: Nature-arcane magic balance research
  Ambassador: Tyrande Whisperwind (memorial council)
  Trade Agreements: Druidic consultation services

|cff00ff00• Gilneas|r - |cff00ff00ALLIED|r
  Relationship Status: Strong cooperation
  Recent Cooperation: Curse research, magical protection
  Ambassador: Genn Greymane
  Trade Agreements: Alchemical research, worgen studies

|cff9370dbHorde Relations:|r

|cffFFFF00• Orgrimmar|r - |cffFFFF00NEUTRAL|r
  Relationship Status: Cautious diplomacy
  Recent Cooperation: Shared threat response (Legion, etc.)
  Ambassador: Thrall (when available)
  Trade Agreements: Limited, case-by-case basis

|cffFFFF00• Silvermoon City|r - |cffFFFF00COMPLEX|r
  Relationship Status: Strained due to Sunreaver incidents
  Recent Cooperation: Minimal, official channels only
  Ambassador: Currently under review
  Trade Agreements: Suspended pending investigation

|cffFFFF00• Thunder Bluff|r - |cff00ccffFRIENDLY|r
  Relationship Status: Respectful cooperation
  Recent Cooperation: Shamanic-arcane research
  Ambassador: Cairne Bloodhoof (memorial), Baine Bloodhoof
  Trade Agreements: Limited magical consultation

|cff9370dbNeutral Organizations:|r

|cff00ff00• Earthen Ring|r - |cff00ff00ALLIED|r
  Relationship Status: Strong professional cooperation
  Recent Cooperation: Elemental balance research

|cff00ff00• Cenarion Circle|r - |cff00ccffFRIENDLY|r
  Relationship Status: Environmental protection partnership
  Recent Cooperation: Arcane pollution cleanup

|cffFFFF00• Argent Dawn|r - |cffFFFF00NEUTRAL|r
  Relationship Status: Professional respect
  Recent Cooperation: Undead threat response

|cff9370dbRecent Diplomatic Events:|r
|cffffff00[This Week]|r Successful trade negotiation with Ironforge
|cffffff00[Last Month]|r Diplomatic incident with Silvermoon resolved
|cffffff00[2 Months Ago]|r Joint research agreement signed with Earthen Ring

|cffFFFF00Diplomatic Protocol Note:|r All faction interactions must be reported to the Diplomatic Corps. Unauthorized negotiations may result in disciplinary action.
]])
        
        -- Adjust scroll height
        scrollChild:SetHeight(content:GetStringHeight() + 20)
    end
    
    GCM.FactionStandingFrame:Show()
end

------------------------------------------ABOUT----------------------------------------------

function GCM.ShowAboutFrame()
    GCM.MainFrame:Hide()
    
    if not GCM.AboutFrame then
        GCM.AboutFrame = CreateFrame("Frame", "GCM_AboutFrame", UIParent, "BasicFrameTemplate")
        GCM.AboutFrame:SetSize(450, 350)
        GCM.AboutFrame:SetPoint("CENTER")
        GCM.AboutFrame:SetMovable(true)
        GCM.AboutFrame:SetResizable(true)
        GCM.AboutFrame:EnableMouse(true)
        GCM.AboutFrame:RegisterForDrag("LeftButton")
        GCM.AboutFrame:SetScript("OnDragStart", GCM.AboutFrame.StartMoving)
        GCM.AboutFrame:SetScript("OnDragStop", GCM.AboutFrame.StopMovingOrSizing)
        
        -- Add resize grip
        local resizeButton = CreateFrame("Button", nil, GCM.AboutFrame)
        resizeButton:SetSize(16, 16)
        resizeButton:SetPoint("BOTTOMRIGHT", -6, 6)
        resizeButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
        resizeButton:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
        resizeButton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
        resizeButton:SetScript("OnMouseDown", function(self, button)
            if button == "LeftButton" then
                GCM.AboutFrame:StartSizing("BOTTOMRIGHT")
            end
        end)
        resizeButton:SetScript("OnMouseUp", function(self, button)
            GCM.AboutFrame:StopMovingOrSizing()
        end)
        
        -- Title
        GCM.AboutFrame.title = GCM.AboutFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        GCM.AboutFrame.title:SetPoint("TOP", 0, -10)
        GCM.AboutFrame.title:SetText("About Guild Case Manager")
        
        -- Back Button
        local backBtn = CreateFrame("Button", nil, GCM.AboutFrame, "UIPanelButtonTemplate")
        backBtn:SetSize(100, 25)
        backBtn:SetPoint("TOPLEFT", 10, -10)
        backBtn:SetText("Back")
        backBtn:SetScript("OnClick", function()
            GCM.AboutFrame:Hide()
            GCM.MainFrame:Show()
        end)
        
        -- Content
        local content = GCM.AboutFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        content:SetPoint("TOPLEFT", 20, -40)
        content:SetWidth(410)
        content:SetJustifyH("LEFT")
        content:SetText([[
|cff00ccffGuild Case Manager v2.0|r
A roleplaying tool for detective work, investigations and IC Interactions/Observations

|cff00ccffCreated by:|r Mágnussen (@LordChristoff)
|cff00ccffFor:|r Argent Dawn 

|cff00ccffUsage:|r
- Track cases and investigations
- Maintain people profiles
- Mark important map locations
- Access staff information
- Plot murders on a map and "connect the dots"
- Acess Kirin Tor directive and archived information.

Type |cff00ff00/acdb|r to open the interface
]])
    end
    
    GCM.AboutFrame:Show()
end

-- ==================== TAB CONTENT CREATION FUNCTIONS ====================

-- Create Welcome Tab Content
function GCM.CreateWelcomeTab(parent)
    local welcomeTab = CreateFrame("Frame", nil, parent)
    welcomeTab:SetAllPoints()
    
    -- Logo
    local logo = welcomeTab:CreateTexture(nil, "ARTWORK")
    logo:SetSize(200, 130)
    logo:SetPoint("TOP", 0, -30)
    logo:SetTexture("Interface\\AddOns\\GuildCaseManager\\media\\acdb_logo.tga")
    
    -- Title
    local title = welcomeTab:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -170)
    title:SetText("|cff00ccffWelcome to Guild Case Manager!|r")
    
    -- Content
    local content = welcomeTab:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    content:SetPoint("TOPLEFT", 20, -200)
    content:SetPoint("BOTTOMRIGHT", -20, 80)
    content:SetJustifyH("LEFT")
    content:SetJustifyV("TOP")
    content:SetText("Thank you for using Guild Case Manager developed by @LordChristoff.\n\n" ..
        "|cff9370dbKey Features:|r\n" ..
        "|cff00ccff• Cases:|r Manage guild investigations and track progress.\n" ..
        "|cff00ccff• People:|r Keep profiles on characters of interest.\n" ..
        "|cff00ccff• Map:|r Mark important locations and connect the dots.\n" ..
        "|cff00ccff• Staff:|r Directory of Arcane Consortium personnel.\n" ..
        "|cff00ccff• GJLE:|r Gilneas Judiciary Law Enforcement hub.\n" ..
        "|cff00ccff• Kirin Tor:|r Access magical archives and information.\n" ..
        "|cff00ccff• Sync:|r Data syncs automatically with all guild members.\n\n" ..
        "|cffffcc00Commands:|r\n" ..
        "• |cff00ff00/acdb|r - Open the main interface\n" ..
        "• |cff00ff00/acdbw|r - Show welcome screen\n\n" ..
        "|cffccccccUse the tabs on the left to navigate between different sections.|r")
    
    welcomeTab:Hide()
    return welcomeTab
end

-- Create Cases Tab Content  
function GCM.CreateCasesTab(parent)
    local casesTab = CreateFrame("Frame", nil, parent)
    casesTab:SetAllPoints()
    
    -- Create main list view
    local listView = CreateFrame("Frame", nil, casesTab)
    listView:SetAllPoints()
    casesTab.listView = listView
    
    -- Title
    local title = listView:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 20, -20)
    title:SetText("|cff00ccffCase Management|r")
    
    -- New Case Button
    local newCaseBtn = CreateFrame("Button", nil, listView, "UIPanelButtonTemplate")
    newCaseBtn:SetSize(120, 30)
    newCaseBtn:SetPoint("TOPRIGHT", -20, -15)
    newCaseBtn:SetText("New Case")
    newCaseBtn:SetScript("OnClick", function()
        GCM.ShowTabCaseEdit(casesTab, nil)
    end)
    
    -- Search Bar
    local searchLabel = listView:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    searchLabel:SetPoint("TOPLEFT", 20, -55)
    searchLabel:SetText("Search:")
    
    local searchBox = CreateFrame("EditBox", nil, listView, "InputBoxTemplate")
    searchBox:SetSize(200, 24)
    searchBox:SetPoint("TOPLEFT", 70, -50)
    searchBox:SetAutoFocus(false)
    searchBox:SetFontObject("GameFontHighlight")
    searchBox:SetScript("OnTextChanged", function(self)
        local text = self:GetText()
        casesTab.searchText = text
        GCM.RefreshCasesTab()
    end)
    casesTab.searchBox = searchBox
    
    -- Case Type Filter Dropdown
    local filterLabel = listView:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    filterLabel:SetPoint("TOPLEFT", 290, -55)
    filterLabel:SetText("Filter:")
    
    local caseTypeFilter = CreateFrame("Frame", "GCM_CaseTypeFilter", listView, "UIDropDownMenuTemplate")
    caseTypeFilter:SetPoint("TOPLEFT", 330, -60)
    UIDropDownMenu_SetWidth(caseTypeFilter, 150)
    UIDropDownMenu_SetText(caseTypeFilter, "All Cases")
    
    -- Initialize the dropdown
    UIDropDownMenu_Initialize(caseTypeFilter, function(self, level)
        local info = UIDropDownMenu_CreateInfo()
        
        -- All Cases option
        info.text = "All Cases"
        info.value = "all"
        info.func = function(self)
            casesTab.filterType = "all"
            UIDropDownMenu_SetText(caseTypeFilter, self:GetText())
            CloseDropDownMenus()
            GCM.RefreshCasesTab()
        end
        UIDropDownMenu_AddButton(info)
        
        -- Get unique case types from database
        local caseTypes = {}
        for _, case in ipairs(GCM_Database.cases or {}) do
            if case.caseType and case.caseType ~= "" and not caseTypes[case.caseType] then
                caseTypes[case.caseType] = true
                info.text = case.caseType
                info.value = case.caseType
                info.func = function(self)
                    casesTab.filterType = self.value
                    UIDropDownMenu_SetText(caseTypeFilter, self:GetText())
                    CloseDropDownMenus()
                    GCM.RefreshCasesTab()
                end
                UIDropDownMenu_AddButton(info)
            end
        end
    end)
    
    casesTab.caseTypeFilter = caseTypeFilter
    casesTab.filterType = "all"
    casesTab.searchText = ""
    
    -- Cases List (Scrollable) - adjusted position for search bar
    local scrollFrame = CreateFrame("ScrollFrame", nil, listView, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 20, -90)
    scrollFrame:SetPoint("BOTTOMRIGHT", -40, 20)
    
    local scrollChild = CreateFrame("Frame")
    scrollChild:SetSize(scrollFrame:GetWidth(), 0)
    scrollFrame:SetScrollChild(scrollChild)
    
    -- Store references for refreshing
    casesTab.scrollFrame = scrollFrame
    casesTab.scrollChild = scrollChild
    
    -- Create edit/view form (initially hidden)
    local formView = CreateFrame("Frame", nil, casesTab)
    formView:SetAllPoints()
    formView:Hide()
    casesTab.formView = formView
    
    -- Back button for form
    local backBtn = CreateFrame("Button", nil, formView, "UIPanelButtonTemplate")
    backBtn:SetSize(80, 25)
    backBtn:SetPoint("TOPLEFT", 10, -10)
    backBtn:SetText("← Back")
    backBtn:SetScript("OnClick", function()
        formView:Hide()
        if casesTab.documentView then casesTab.documentView:Hide() end
        listView:Show()
        GCM.RefreshCasesTab()
    end)
    casesTab.backBtn = backBtn
    
    -- Form title
    local formTitle = formView:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    formTitle:SetPoint("TOP", 0, -15)
    casesTab.formTitle = formTitle
    
    -- Save button (for edit mode)
    local saveBtn = CreateFrame("Button", nil, formView, "UIPanelButtonTemplate")
    saveBtn:SetSize(80, 25)
    saveBtn:SetPoint("TOPRIGHT", -10, -10)
    saveBtn:SetText("Save")
    saveBtn:SetScript("OnClick", function()
        GCM.SaveTabCase(casesTab)
    end)
    casesTab.saveBtn = saveBtn
    
    -- Create document view (for read-only viewing)
    local documentView = CreateFrame("Frame", nil, casesTab)
    documentView:SetAllPoints()
    documentView:Hide()
    casesTab.documentView = documentView
    
    -- Back button for document view (reuse the same back button logic)
    local docBackBtn = CreateFrame("Button", nil, documentView, "UIPanelButtonTemplate")
    docBackBtn:SetSize(80, 25)
    docBackBtn:SetPoint("TOPLEFT", 10, -10)
    docBackBtn:SetText("← Back")
    docBackBtn:SetScript("OnClick", function()
        documentView:Hide()
        listView:Show()
        GCM.RefreshCasesTab()
    end)
    
    -- Document title
    local docTitle = documentView:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    docTitle:SetPoint("TOP", 0, -15)
    casesTab.docTitle = docTitle
    
    -- Document scroll frame
    local docScrollFrame = CreateFrame("ScrollFrame", nil, documentView, "UIPanelScrollFrameTemplate")
    docScrollFrame:SetPoint("TOPLEFT", 10, -50)
    docScrollFrame:SetPoint("BOTTOMRIGHT", -30, 20)
    
    local docScrollChild = CreateFrame("Frame")
    docScrollChild:SetSize(docScrollFrame:GetWidth(), 0)
    docScrollFrame:SetScrollChild(docScrollChild)
    casesTab.docScrollChild = docScrollChild
    
    -- Document content
    local docContent = docScrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    docContent:SetPoint("TOPLEFT", 10, -10)
    docContent:SetWidth(docScrollChild:GetWidth() - 20)
    docContent:SetJustifyH("LEFT")
    docContent:SetJustifyV("TOP")
    casesTab.docContent = docContent
    
    -- Create form content area
    GCM.CreateTabCaseForm(casesTab)
    
    casesTab:Hide()
    return casesTab
end

-- Create People Tab Content
function GCM.CreatePeopleTab(parent)
    local peopleTab = CreateFrame("Frame", nil, parent)
    peopleTab:SetAllPoints()
    
    -- Create main list view
    local listView = CreateFrame("Frame", nil, peopleTab)
    listView:SetAllPoints()
    peopleTab.listView = listView
    
    -- Title
    local title = listView:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 20, -20)
    title:SetText("|cff00ccffPeople Management|r")
    
    -- Add New Person Button
    local newPersonBtn = CreateFrame("Button", nil, listView, "UIPanelButtonTemplate")
    newPersonBtn:SetSize(120, 30)
    newPersonBtn:SetPoint("TOPRIGHT", -20, -15)
    newPersonBtn:SetText("Add Person")
    newPersonBtn:SetScript("OnClick", function()
        GCM.ShowTabPersonEdit(peopleTab, nil)
    end)
    
    -- Search Bar
    local searchLabel = listView:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    searchLabel:SetPoint("TOPLEFT", 20, -55)
    searchLabel:SetText("Search:")
    
    local searchBox = CreateFrame("EditBox", nil, listView, "InputBoxTemplate")
    searchBox:SetSize(200, 24)
    searchBox:SetPoint("TOPLEFT", 70, -50)
    searchBox:SetAutoFocus(false)
    searchBox:SetFontObject("GameFontHighlight")
    searchBox:SetScript("OnTextChanged", function(self)
        local text = self:GetText()
        peopleTab.searchText = text
        GCM.RefreshPeopleTab()
    end)
    peopleTab.searchBox = searchBox
    
    -- Threat Level Filter Dropdown
    local filterLabel = listView:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    filterLabel:SetPoint("TOPLEFT", 290, -55)
    filterLabel:SetText("Filter:")
    
    local threatLevelFilter = CreateFrame("Frame", "GCM_ThreatLevelFilter", listView, "UIDropDownMenuTemplate")
    threatLevelFilter:SetPoint("TOPLEFT", 330, -60)
    UIDropDownMenu_SetWidth(threatLevelFilter, 150)
    UIDropDownMenu_SetText(threatLevelFilter, "All People")
    
    -- Initialize the dropdown
    UIDropDownMenu_Initialize(threatLevelFilter, function(self, level)
        local info = UIDropDownMenu_CreateInfo()
        
        -- All People option
        info.text = "All People"
        info.value = "all"
        info.func = function(self)
            peopleTab.filterType = "all"
            UIDropDownMenu_SetText(threatLevelFilter, self:GetText())
            CloseDropDownMenus()
            GCM.RefreshPeopleTab()
        end
        UIDropDownMenu_AddButton(info)
        
        -- Get unique threat levels from database
        local threatLevels = {}
        for _, person in ipairs(GCM_Database.people or {}) do
            if person.threatLevel and person.threatLevel ~= "" and not threatLevels[person.threatLevel] then
                threatLevels[person.threatLevel] = true
                info.text = person.threatLevel
                info.value = person.threatLevel
                info.func = function(self)
                    peopleTab.filterType = self.value
                    UIDropDownMenu_SetText(threatLevelFilter, self:GetText())
                    CloseDropDownMenus()
                    GCM.RefreshPeopleTab()
                end
                UIDropDownMenu_AddButton(info)
            end
        end
        
        -- Add some common threat levels if none exist
        if not next(threatLevels) then
            local commonLevels = {"Low", "Medium", "High", "Critical"}
            for _, level in ipairs(commonLevels) do
                info.text = level
                info.value = level
                info.func = function(self)
                    peopleTab.filterType = self.value
                    UIDropDownMenu_SetText(threatLevelFilter, self:GetText())
                    CloseDropDownMenus()
                    GCM.RefreshPeopleTab()
                end
                UIDropDownMenu_AddButton(info)
            end
        end
    end)
    
    peopleTab.threatLevelFilter = threatLevelFilter
    peopleTab.filterType = "all"
    peopleTab.searchText = ""
    
    -- People List (Scrollable) - adjusted position for search bar
    local scrollFrame = CreateFrame("ScrollFrame", nil, listView, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 20, -90)
    scrollFrame:SetPoint("BOTTOMRIGHT", -40, 20)
    
    local scrollChild = CreateFrame("Frame")
    scrollChild:SetSize(scrollFrame:GetWidth(), 0)
    scrollFrame:SetScrollChild(scrollChild)
    
    -- Store references for refreshing
    peopleTab.scrollFrame = scrollFrame
    peopleTab.scrollChild = scrollChild
    
    -- Create edit/view form (initially hidden)
    local formView = CreateFrame("Frame", nil, peopleTab)
    formView:SetAllPoints()
    formView:Hide()
    peopleTab.formView = formView
    
    -- Back button for form
    local backBtn = CreateFrame("Button", nil, formView, "UIPanelButtonTemplate")
    backBtn:SetSize(80, 25)
    backBtn:SetPoint("TOPLEFT", 10, -10)
    backBtn:SetText("← Back")
    backBtn:SetScript("OnClick", function()
        formView:Hide()
        if peopleTab.documentView then peopleTab.documentView:Hide() end
        listView:Show()
        GCM.RefreshPeopleTab()
    end)
    peopleTab.backBtn = backBtn
    
    -- Form title
    local formTitle = formView:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    formTitle:SetPoint("TOP", 0, -15)
    peopleTab.formTitle = formTitle
    
    -- Save button (for edit mode)
    local saveBtn = CreateFrame("Button", nil, formView, "UIPanelButtonTemplate")
    saveBtn:SetSize(80, 25)
    saveBtn:SetPoint("TOPRIGHT", -10, -10)
    saveBtn:SetText("Save")
    saveBtn:SetScript("OnClick", function()
        GCM.SaveTabPerson(peopleTab)
    end)
    peopleTab.saveBtn = saveBtn
    
    -- Create document view (for read-only viewing)
    local documentView = CreateFrame("Frame", nil, peopleTab)
    documentView:SetAllPoints()
    documentView:Hide()
    peopleTab.documentView = documentView
    
    -- Back button for document view
    local docBackBtn = CreateFrame("Button", nil, documentView, "UIPanelButtonTemplate")
    docBackBtn:SetSize(80, 25)
    docBackBtn:SetPoint("TOPLEFT", 10, -10)
    docBackBtn:SetText("← Back")
    docBackBtn:SetScript("OnClick", function()
        documentView:Hide()
        listView:Show()
        GCM.RefreshPeopleTab()
    end)
    
    -- Document title
    local docTitle = documentView:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    docTitle:SetPoint("TOP", 0, -15)
    peopleTab.docTitle = docTitle
    
    -- Document scroll frame
    local docScrollFrame = CreateFrame("ScrollFrame", nil, documentView, "UIPanelScrollFrameTemplate")
    docScrollFrame:SetPoint("TOPLEFT", 10, -50)
    docScrollFrame:SetPoint("BOTTOMRIGHT", -30, 20)
    
    local docScrollChild = CreateFrame("Frame")
    docScrollChild:SetSize(docScrollFrame:GetWidth(), 0)
    docScrollFrame:SetScrollChild(docScrollChild)
    peopleTab.docScrollChild = docScrollChild
    
    -- Document content
    local docContent = docScrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    docContent:SetPoint("TOPLEFT", 10, -10)
    docContent:SetWidth(docScrollChild:GetWidth() - 20)
    docContent:SetJustifyH("LEFT")
    docContent:SetJustifyV("TOP")
    peopleTab.docContent = docContent
    
    -- Create form content area
    GCM.CreateTabPersonForm(peopleTab)
    
    peopleTab:Hide()
    return peopleTab
end

-- Create Map Tab Content
function GCM.CreateMapTab(parent)
    local mapTab = CreateFrame("Frame", nil, parent)
    mapTab:SetAllPoints()
    
    -- Title
    local title = mapTab:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 20, -20)
    title:SetText("|cff00ccffMap Markers|r")
    
    -- Top control buttons row (moved dropdown to bottom)
    local buttonY = -15
    
    -- Toggle Lines Button
    local toggleLinesBtn = CreateFrame("Button", nil, mapTab, "UIPanelButtonTemplate")
    toggleLinesBtn:SetSize(100, 25)
    toggleLinesBtn:SetPoint("TOPRIGHT", -20, buttonY)
    toggleLinesBtn:SetText("Connect Dots")
    toggleLinesBtn:SetScript("OnClick", function()
        if GCM.MainFrame.tabMapContainer then
            GCM.ToggleTabMapLines()
        end
    end)
    
    -- Legend Button
    local legendBtn = CreateFrame("Button", nil, mapTab, "UIPanelButtonTemplate")
    legendBtn:SetSize(100, 25)
    legendBtn:SetPoint("TOPRIGHT", -130, buttonY)
    legendBtn:SetText("Color Legend")
    legendBtn:SetScript("OnClick", function()
        GCM.ShowColorLegend()
    end)
    
    -- Clear Markers Button
    local clearBtn = CreateFrame("Button", nil, mapTab, "UIPanelButtonTemplate")
    clearBtn:SetSize(100, 25)
    clearBtn:SetPoint("TOPRIGHT", -240, buttonY)
    clearBtn:SetText("Clear All")
    clearBtn:SetScript("OnClick", function()
        if GCM.MainFrame.tabMapContainer then
            GCM.ClearTabMapMarkers()
        end
    end)
    
    -- Map Container (adjusted to leave more space at bottom for dropdown)
    local mapContainer = CreateFrame("Frame", nil, mapTab, "BackdropTemplate")
    mapContainer:SetPoint("TOPLEFT", 20, -50)
    mapContainer:SetPoint("BOTTOMRIGHT", -40, 90)
    mapContainer:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    mapContainer:SetBackdropColor(0.1, 0.1, 0.3, 1)
    mapContainer:SetBackdropBorderColor(0.8, 0.8, 0.8, 1)
    
    -- Map Background
    local mapBG = mapContainer:CreateTexture(nil, "BACKGROUND")
    mapBG:SetAllPoints(mapContainer)
    mapBG:SetColorTexture(0.2, 0.3, 0.2, 1)
    
    -- Try to load custom map texture
    local map = mapContainer:CreateTexture(nil, "ARTWORK")
    map:SetAllPoints(mapContainer)
    
    local texturePaths = {
        "Interface/AddOns/GuildCaseManager/media/custom_map",
        "Interface\\AddOns\\GuildCaseManager\\media\\custom_map",
        "Interface/AddOns/GuildCaseManager/media/custom_map.tga"
    }
    
    local textureLoaded = false
    for _, path in ipairs(texturePaths) do
        map:SetTexture(path)
        if map:GetTexture() then
            textureLoaded = true
            break
        end
    end
    
    if not textureLoaded then
        map:SetColorTexture(0.3, 0.4, 0.3, 1)
    end
    
    -- Add grid lines
    for i = 1, 4 do
        local vLine = mapContainer:CreateTexture(nil, "OVERLAY")
        vLine:SetColorTexture(0.5, 0.5, 0.5, 0.3)
        vLine:SetSize(1, mapContainer:GetHeight())
        vLine:SetPoint("LEFT", mapContainer, "LEFT", i * mapContainer:GetWidth() / 5, 0)
        
        local hLine = mapContainer:CreateTexture(nil, "OVERLAY")
        hLine:SetColorTexture(0.5, 0.5, 0.5, 0.3)
        hLine:SetSize(mapContainer:GetWidth(), 1)
        hLine:SetPoint("TOP", mapContainer, "TOP", 0, -i * mapContainer:GetHeight() / 5)
    end
    
    -- Instructions
    local instructions = mapTab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    instructions:SetPoint("BOTTOM", 0, 65)
    instructions:SetText("Right-click to add markers | Left-click markers to remove")
    instructions:SetTextColor(0.8, 0.8, 0.8, 1)
    
    -- Case Filter Dropdown for line connections (at bottom with more space)
    local caseFilterLabel = mapTab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    caseFilterLabel:SetPoint("BOTTOMLEFT", 20, 35)
    caseFilterLabel:SetText("Connect lines for:")
    
    local caseFilterDropdown = CreateFrame("Frame", "GCM_TabMapCaseFilterDropdown", mapTab, "UIDropDownMenuTemplate")
    caseFilterDropdown:SetPoint("BOTTOMLEFT", 130, 25)
    
    -- Enable mouse events
    mapContainer:EnableMouse(true)
    mapContainer:SetScript("OnMouseDown", function(self, button)
        if button == "RightButton" then
            local cursorX, cursorY = GetCursorPosition()
            local scale = self:GetEffectiveScale()
            local x = (cursorX / scale - self:GetLeft())
            local y = (self:GetTop() - cursorY / scale)
            GCM.ShowMarkerCaseDialog(x, y)  -- Use existing function
        end
    end)
    
    -- Store references
    mapTab.mapContainer = mapContainer
    mapTab.map = map
    mapTab.caseFilterDropdown = caseFilterDropdown
    mapTab.toggleLinesBtn = toggleLinesBtn
    
    mapTab:Hide()
    return mapTab
end

-- Create Staff Tab Content
function GCM.CreateStaffTab(parent)
    local staffTab = CreateFrame("Frame", nil, parent)
    staffTab:SetAllPoints()
    
    -- Title
    local title = staffTab:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 20, -20)
    title:SetText("|cff6a5acdArcane Consortium Staff Directory|r")
    
    -- Staff Directory (Scrollable)
    local scrollFrame = CreateFrame("ScrollFrame", nil, staffTab, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 20, -50)
    scrollFrame:SetPoint("BOTTOMRIGHT", -40, 20)
    
    local scrollChild = CreateFrame("Frame")
    scrollChild:SetSize(scrollFrame:GetWidth(), 0)
    scrollFrame:SetScrollChild(scrollChild)
    
        -- Staff data
        local staff = {
            {
                name = "Professor Charles Magnussen",
                rank = "Detective | Head", 
                department = "Investigations Division",
                specialization = "Forensical Investigation",
                experience = "15+ years",
                location = "Gilneas",
                contact = "Mail or Business Card",
                availability = "Mon-Fri 08:00-18:00",
                background = "Magical consultant for Gilneas, founded and ran the Arcane Consortium 2018, founded and briefly ran Kirin Tor Intelligence 2019 and founded and runs The Arcane Consortium: Detective Bureau 2025",
                notable_cases = "The Eight (Duskwood), Mortimer in Gilneas, The Starlight Slasher",
                skills = "Arcane Detection, Investigation, Case Management",
                portrait = "Interface\\AddOns\\GuildCaseManager\\media\\charles_profile.tga"
            },
            {
                name = "Professor Alec Snowden", 
                rank = "Detective",
                department = "Field Operations",
                specialization = "Exotic Magics",
                experience = "12+ years with the Kirin Tor, previously of the Arcane Consortium 2018",
                location = "Gilneas, Stormwind, Redridge",
                contact = "Magical communication crystal, Frequency 7",
                availability = "Varies by assignment, 24/7 emergency response",
                background = "Specializes in forensical investigations and the applied usage of exotic magics within cases",
                notable_cases = "The Nethershard Conspiracy, Black Market Portal Network, Corrupted Mana Crystal Trade",
                skills = "Undercover Operations, Surveillance, Arcane Tracking",
                portrait = "Interface\\AddOns\\GuildCaseManager\\media\\alec_portrait.tga"
            },
            {
                name = "Forensic Specialist Dr. Thalassic Voidbane",
                rank = "Chief Forensic Analyst",
                department = "Scientific Investigation Division",
                specialization = "Magical Forensics & Evidence Analysis",
                experience = "18 years in arcane sciences",
                location = "Dalaran Laboratory Complex, Level B2",
                contact = "Laboratory direct line, emergency pager",
                availability = "Mon-Sat 06:00-20:00, Emergency analysis available",
                background = "PhD in Thaumaturgic Sciences from the University of Dalaran. Pioneered several breakthrough techniques in magical residue analysis.",
                notable_cases = "Developed the 'Voidbane Trace Method', solved the 'Impossible Teleportation Murder', identified the Cursed Medallion killer",
                skills = "Magical Residue Analysis, Enchantment Identification, Temporal Evidence Recovery",
                portrait = "Interface\\AddOns\\GuildCaseManager\\media\\staff_forensic.tga"
            },
            {
                name = "Field Agent Coordinator Sarah Brightblade",
                rank = "Senior Agent",
                department = "Intelligence & Reconnaissance",
                specialization = "Information Gathering & Surveillance",
                experience = "8 years, former Alliance Intelligence",
                location = "Various field assignments",
                contact = "Secure messaging system, code clearance required",
                availability = "Assignment dependent, rapid deployment ready",
                background = "Expert in covert surveillance and intelligence gathering. Maintains extensive network of informants across Azeroth.",
                notable_cases = "The Defias Mage Cell Infiltration, Stormwind Noble Corruption Scandal, Twilight Cult Monitoring",
                skills = "Covert Operations, Intelligence Analysis, Network Management",
                portrait = "Interface\\AddOns\\GuildCaseManager\\media\\staff_agent.tga"
            },
            {
                name = "Archivist Keeper Aldric Scrollseeker",
                rank = "Chief Archivist",
                department = "Records & Historical Research",
                specialization = "Case History & Legal Precedent",
                experience = "25 years in magical archives",
                location = "Dalaran Archive Vault, Restricted Section",
                contact = "Archive appointment system, written requests",
                availability = "Mon-Fri 09:00-17:00, Research consultations by appointment",
                background = "Master of historical case law and precedent. Maintains the most comprehensive magical crime database in the known world.",
                notable_cases = "Catalogued over 10,000 magical crimes, Created the 'Scrollseeker Classification System', Advisor on the Magna Carta Magica",
                skills = "Historical Research, Legal Database Management, Pattern Analysis",
                portrait = "Interface\\AddOns\\GuildCaseManager\\media\\staff_archivist.tga"
            }
        }
    
    local yOffset = -10
    
    for i, member in ipairs(staff) do
        -- Create container for each staff member
        local memberFrame = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
        memberFrame:SetSize(scrollChild:GetWidth() - 20, 200)
        memberFrame:SetPoint("TOPLEFT", 10, yOffset)
        memberFrame:SetBackdrop({
            bgFile = "Interface/Tooltips/UI-Tooltip-Background",
            edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        memberFrame:SetBackdropColor(0.1, 0.1, 0.2, 0.8)
        memberFrame:SetBackdropBorderColor(0.3, 0.5, 0.8, 1)
        
        -- Portrait placeholder
        local portrait = memberFrame:CreateTexture(nil, "ARTWORK")
        portrait:SetSize(60, 60)
        portrait:SetPoint("TOPLEFT", 10, -10)
        portrait:SetTexture("Interface\\CHARACTERFRAME\\TempPortrait")
        
        -- Name and Rank
        local nameText = memberFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        nameText:SetPoint("TOPLEFT", portrait, "TOPRIGHT", 10, 0)
        nameText:SetText(string.format("|cff00ccff%s|r", member.name))
        nameText:SetWidth(memberFrame:GetWidth() - 90)
        nameText:SetJustifyH("LEFT")
        
        local rankText = memberFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        rankText:SetPoint("TOPLEFT", nameText, "BOTTOMLEFT", 0, -3)
        rankText:SetText(string.format("|cffFFD700%s - %s|r", member.rank, member.department))
        rankText:SetWidth(memberFrame:GetWidth() - 90)
        rankText:SetJustifyH("LEFT")
        
        -- Details below
        local detailsText = memberFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        detailsText:SetPoint("TOPLEFT", portrait, "BOTTOMLEFT", 0, -10)
        detailsText:SetWidth(memberFrame:GetWidth() - 20)
        detailsText:SetJustifyH("LEFT")
        
        local details = string.format(
            "|cff9370db%s|r\n" ..
            "|cff00ccffExperience:|r %s\n" ..
            "|cff00ccffLocation:|r %s\n" ..
            "|cff00ccffContact:|r %s\n" ..
            "|cff00ccffSkills:|r %s",
            member.specialization, member.experience, member.location, member.contact, member.skills)
        
        detailsText:SetText(details)
        
        yOffset = yOffset - 210
    end
    
    -- Adjust scroll height
    scrollChild:SetHeight(math.abs(yOffset) + 20)
    
    staffTab:Hide()
    return staffTab
end

-- Create GJLE Tab Content
function GCM.CreateGJLETab(parent)
    local gjleTab = CreateFrame("Frame", nil, parent)
    gjleTab:SetAllPoints()
    
    -- Create main menu view
    local mainMenu = CreateFrame("Frame", nil, gjleTab)
    mainMenu:SetAllPoints()
    gjleTab.mainMenu = mainMenu
    
    -- Title
    local title = mainMenu:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -30)
    title:SetText("|cff00ccffGJLE Hub|r")
    
    -- Button settings
    local buttonWidth = 150
    local buttonHeight = 30
    
    -- Guidelines Button
    local guidelinesBtn = CreateFrame("Button", nil, mainMenu, "UIPanelButtonTemplate")
    guidelinesBtn:SetSize(buttonWidth, buttonHeight)
    guidelinesBtn:SetPoint("CENTER", 0, 30)
    guidelinesBtn:SetText("Guidelines")
    guidelinesBtn:SetScript("OnClick", function()
        GCM.ShowGJLEContent(gjleTab, "guidelines")
    end)
    
    -- Correspondence Button
    local correspondenceBtn = CreateFrame("Button", nil, mainMenu, "UIPanelButtonTemplate")
    correspondenceBtn:SetSize(buttonWidth, buttonHeight)
    correspondenceBtn:SetPoint("CENTER", 0, -20)
    correspondenceBtn:SetText("Correspondence")
    correspondenceBtn:SetScript("OnClick", function()
        GCM.ShowGJLEContent(gjleTab, "correspondence")
    end)
    
    -- Info text
    local infoText = mainMenu:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    infoText:SetPoint("CENTER", 0, -80)
    infoText:SetWidth(400)
    infoText:SetJustifyH("CENTER")
    infoText:SetText("|cffccccccGilneas Judiciary Law Enforcement\nGuidelines and Correspondence Hub|r")
    
    -- Create document view frame (initially hidden)
    local documentView = CreateFrame("Frame", nil, gjleTab)
    documentView:SetAllPoints()
    documentView:Hide()
    gjleTab.documentView = documentView
    
    -- Back button for document view
    local docBackBtn = CreateFrame("Button", nil, documentView, "UIPanelButtonTemplate")
    docBackBtn:SetSize(80, 25)
    docBackBtn:SetPoint("TOPLEFT", 10, -10)
    docBackBtn:SetText("← Back")
    docBackBtn:SetScript("OnClick", function()
        documentView:Hide()
        mainMenu:Show()
    end)
    
    -- Document title
    local docTitle = documentView:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    docTitle:SetPoint("TOP", 0, -15)
    gjleTab.docTitle = docTitle
    
    -- Document scroll frame
    local docScrollFrame = CreateFrame("ScrollFrame", nil, documentView, "UIPanelScrollFrameTemplate")
    docScrollFrame:SetPoint("TOPLEFT", 10, -50)
    docScrollFrame:SetPoint("BOTTOMRIGHT", -30, 20)
    
    local docScrollChild = CreateFrame("Frame")
    docScrollChild:SetSize(docScrollFrame:GetWidth(), 0)
    docScrollFrame:SetScrollChild(docScrollChild)
    gjleTab.docScrollChild = docScrollChild
    
    -- Document content
    local docContent = docScrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    docContent:SetPoint("TOPLEFT", 10, -10)
    docContent:SetWidth(docScrollChild:GetWidth() - 20)
    docContent:SetJustifyH("LEFT")
    docContent:SetJustifyV("TOP")
    gjleTab.docContent = docContent
    
    gjleTab:Hide()
    return gjleTab
end

-- Create Kirin Tor Tab Content
function GCM.CreateKirinTorTab(parent)
    local kirinTorTab = CreateFrame("Frame", nil, parent)
    kirinTorTab:SetAllPoints()
    
    -- Create main menu container
    local mainMenu = CreateFrame("Frame", nil, kirinTorTab)
    mainMenu:SetAllPoints()
    kirinTorTab.mainMenu = mainMenu
    
    -- Title
    local title = mainMenu:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -30)
    title:SetText("|cff6a5acdKirin Tor Hub|r")
    
    -- Logo
    local logo = mainMenu:CreateTexture(nil, "ARTWORK")
    logo:SetSize(100, 90)
    logo:SetPoint("TOP", 0, -70)
    logo:SetTexture("Interface\\AddOns\\GuildCaseManager\\media\\KT_LOGO.tga")
    
    -- Button settings
    local buttonWidth = 180
    local buttonHeight = 25
    local buttonSpacing = 10
    local startY = 80
    
    -- Kirin Tor buttons
    local kirinTorButtons = {
        {text = "Arcane Archives", onClick = function() GCM.ShowKirinTorContent(kirinTorTab, "archives") end},
        {text = "Portal Nexus", onClick = function() GCM.ShowKirinTorContent(kirinTorTab, "portal") end},
        {text = "Licences", onClick = function() GCM.ShowKirinTorContent(kirinTorTab, "licences") end},
        {text = "Enemies of the Kirin Tor", onClick = function() GCM.ShowKirinTorContent(kirinTorTab, "enemies") end},
        {text = "Artifact Database", onClick = function() GCM.ShowKirinTorContent(kirinTorTab, "artifacts") end},
        {text = "Magical Theory and Research", onClick = function() GCM.ShowKirinTorContent(kirinTorTab, "research") end},
        {text = "Academic Lectures", onClick = function() GCM.ShowKirinTorContent(kirinTorTab, "lectures") end},
        {text = "Other Faction Standing", onClick = function() GCM.ShowKirinTorContent(kirinTorTab, "factions") end}
    }
    
    for i, btnInfo in ipairs(kirinTorButtons) do
        local btn = CreateFrame("Button", nil, mainMenu, "UIPanelButtonTemplate")
        btn:SetSize(buttonWidth, buttonHeight)
        local yPos = startY - (i - 1) * (buttonHeight + buttonSpacing)
        btn:SetPoint("CENTER", 0, yPos)
        btn:SetText(btnInfo.text)
        btn:SetScript("OnClick", btnInfo.onClick)
        
        -- Visual polish
        btn:SetNormalFontObject("GameFontNormalSmall")
        btn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
        btn:GetHighlightTexture():SetBlendMode("ADD")
    end
    
    -- Create content frame (initially hidden)
    local contentFrame = CreateFrame("Frame", nil, kirinTorTab)
    contentFrame:SetAllPoints()
    contentFrame:Hide()
    kirinTorTab.contentFrame = contentFrame
    
    -- Back button for content frame
    local backBtn = CreateFrame("Button", nil, contentFrame, "UIPanelButtonTemplate")
    backBtn:SetSize(80, 25)
    backBtn:SetPoint("TOPLEFT", 10, -10)
    backBtn:SetText("← Back")
    backBtn:SetScript("OnClick", function()
        contentFrame:Hide()
        mainMenu:Show()
    end)
    kirinTorTab.backBtn = backBtn
    
    -- Content title
    local contentTitle = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    contentTitle:SetPoint("TOP", 0, -15)
    kirinTorTab.contentTitle = contentTitle
    
    -- Scrollable content area
    local scrollFrame = CreateFrame("ScrollFrame", nil, contentFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 10, -50)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 20)
    
    local scrollChild = CreateFrame("Frame")
    scrollChild:SetSize(scrollFrame:GetWidth(), 0)
    scrollFrame:SetScrollChild(scrollChild)
    
    kirinTorTab.scrollFrame = scrollFrame
    kirinTorTab.scrollChild = scrollChild
    
    -- Content text
    local contentText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    contentText:SetPoint("TOPLEFT", 10, -10)
    contentText:SetWidth(scrollChild:GetWidth() - 20)
    contentText:SetJustifyH("LEFT")
    kirinTorTab.contentText = contentText
    
    kirinTorTab:Hide()
    return kirinTorTab
end

-- ==================== TAB REFRESH FUNCTIONS ====================

-- Refresh Cases Tab
function GCM.RefreshCasesTab()
    if not GCM.MainFrame or not GCM.MainFrame.tabs.cases then return end
    
    local casesTab = GCM.MainFrame.tabs.cases
    if not casesTab.scrollChild then return end
    
    -- Clear existing entries
    for _, child in ipairs({casesTab.scrollChild:GetChildren()}) do
        child:Hide()
    end
    
    -- Get search and filter criteria
    local searchText = casesTab.searchText or ""
    local filterType = casesTab.filterType or "all"
    searchText = string.lower(searchText)
    
    -- Filter and search cases
    local filteredCases = {}
    for _, case in ipairs(GCM_Database.cases or {}) do
        -- Apply type filter
        local typeMatch = (filterType == "all") or (case.caseType == filterType)
        
        -- Apply search filter
        local searchMatch = true
        if searchText ~= "" then
            local caseTitle = string.lower(case.title or "")
            local caseDesc = string.lower(case.description or "")
            local caseType = string.lower(case.caseType or "")
            local caseStatus = string.lower(case.status or "")
            local assignedTo = string.lower(case.assignedTo or "")
            
            searchMatch = string.find(caseTitle, searchText, 1, true) or
                         string.find(caseDesc, searchText, 1, true) or
                         string.find(caseType, searchText, 1, true) or
                         string.find(caseStatus, searchText, 1, true) or
                         string.find(assignedTo, searchText, 1, true)
        end
        
        if typeMatch and searchMatch then
            table.insert(filteredCases, case)
        end
    end
    
    -- Add filtered cases to the list
    local yOffset = -10
    for _, case in ipairs(filteredCases) do
        local caseEntry = CreateFrame("Frame", nil, casesTab.scrollChild)
        caseEntry:SetSize(casesTab.scrollChild:GetWidth() - 20, 30)
        caseEntry:SetPoint("TOPLEFT", 10, yOffset)
        
        -- Case Title
        local title = caseEntry:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("LEFT")
        title:SetWidth(200)
        title:SetText(case.title or "Untitled Case")
        
        -- Action buttons
        local viewBtn = CreateFrame("Button", nil, caseEntry, "UIPanelButtonTemplate")
        viewBtn:SetSize(60, 22)
        viewBtn:SetPoint("RIGHT", -190, 0)
        viewBtn:SetText("View")
        viewBtn:SetScript("OnClick", function()
            GCM.ShowTabCaseView(GCM.MainFrame.tabs.cases, case)
        end)
        
        local editBtn = CreateFrame("Button", nil, caseEntry, "UIPanelButtonTemplate")
        editBtn:SetSize(60, 22)
        editBtn:SetPoint("RIGHT", -120, 0)
        editBtn:SetText("Edit")
        editBtn:SetScript("OnClick", function()
            GCM.ShowTabCaseEdit(GCM.MainFrame.tabs.cases, case)
        end)
        
        local deleteBtn = CreateFrame("Button", nil, caseEntry, "UIPanelButtonTemplate")
        deleteBtn:SetSize(60, 22)
        deleteBtn:SetPoint("RIGHT", -50, 0)
        deleteBtn:SetText("Delete")
        deleteBtn:SetNormalFontObject("GameFontRed")
        deleteBtn:SetScript("OnClick", function()
            StaticPopup_Show("GCM_CONFIRM_DELETE", nil, nil, {caseId = case.id})
        end)
        
        yOffset = yOffset - 35
    end
    
    -- Adjust scroll height
    casesTab.scrollChild:SetHeight(math.abs(yOffset) + 10)
end

-- Refresh People Tab
function GCM.RefreshPeopleTab()
    if not GCM.MainFrame or not GCM.MainFrame.tabs.people then return end
    
    local peopleTab = GCM.MainFrame.tabs.people
    if not peopleTab.scrollChild then return end
    
    -- Clear existing entries
    for _, child in ipairs({peopleTab.scrollChild:GetChildren()}) do
        child:Hide()
    end
    
    -- Get search and filter criteria
    local searchText = peopleTab.searchText or ""
    local filterType = peopleTab.filterType or "all"
    searchText = string.lower(searchText)
    
    -- Filter and search people
    local filteredPeople = {}
    for _, person in ipairs(GCM_Database.people or {}) do
        -- Apply threat level filter
        local threatMatch = (filterType == "all") or (person.threatLevel == filterType)
        
        -- Apply search filter
        local searchMatch = true
        if searchText ~= "" then
            local personName = string.lower(person.name or "")
            local personRace = string.lower(person.race or "")
            local personOccupation = string.lower(person.occupation or "")
            local personAliases = string.lower(person.aliases or "")
            local personNotes = string.lower(person.notes or "")
            local personThreat = string.lower(person.threatLevel or "")
            
            searchMatch = string.find(personName, searchText, 1, true) or
                         string.find(personRace, searchText, 1, true) or
                         string.find(personOccupation, searchText, 1, true) or
                         string.find(personAliases, searchText, 1, true) or
                         string.find(personNotes, searchText, 1, true) or
                         string.find(personThreat, searchText, 1, true)
        end
        
        if threatMatch and searchMatch then
            table.insert(filteredPeople, person)
        end
    end
    
    -- Add filtered people to the list
    local yOffset = -10
    for _, person in ipairs(filteredPeople) do
        local personEntry = CreateFrame("Frame", nil, peopleTab.scrollChild)
        personEntry:SetSize(peopleTab.scrollChild:GetWidth() - 20, 30)
        personEntry:SetPoint("TOPLEFT", 10, yOffset)
        
        -- Person Name
        local name = personEntry:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        name:SetPoint("LEFT")
        name:SetWidth(200)
        name:SetText(person.name or "Unknown")
        
        -- Action buttons
        local viewBtn = CreateFrame("Button", nil, personEntry, "UIPanelButtonTemplate")
        viewBtn:SetSize(60, 22)
        viewBtn:SetPoint("RIGHT", -190, 0)
        viewBtn:SetText("View")
        viewBtn:SetScript("OnClick", function()
            GCM.ShowTabPersonView(GCM.MainFrame.tabs.people, person)
        end)
        
        local editBtn = CreateFrame("Button", nil, personEntry, "UIPanelButtonTemplate")
        editBtn:SetSize(60, 22)
        editBtn:SetPoint("RIGHT", -120, 0)
        editBtn:SetText("Edit")
        editBtn:SetScript("OnClick", function()
            GCM.ShowTabPersonEdit(GCM.MainFrame.tabs.people, person)
        end)
        
        local deleteBtn = CreateFrame("Button", nil, personEntry, "UIPanelButtonTemplate")
        deleteBtn:SetSize(60, 22)
        deleteBtn:SetPoint("RIGHT", -50, 0)
        deleteBtn:SetText("Delete")
        deleteBtn:SetNormalFontObject("GameFontRed")
        deleteBtn:SetScript("OnClick", function()
            StaticPopup_Show("GCM_CONFIRM_DELETE_PERSON", nil, nil, {personId = person.id})
        end)
        
        yOffset = yOffset - 35
    end
    
    -- Adjust scroll height
    peopleTab.scrollChild:SetHeight(math.abs(yOffset) + 10)
end

-- Initialize Map Tab
function GCM.InitializeMapTab()
    if not GCM.MainFrame or not GCM.MainFrame.tabs.map then return end
    
    local mapTab = GCM.MainFrame.tabs.map
    if not mapTab.mapContainer then return end
    
    -- Initialize map container for markers
    if not GCM.MainFrame.tabMapContainer then
        GCM.MainFrame.tabMapContainer = CreateFrame("Frame", nil, mapTab.mapContainer)
        GCM.MainFrame.tabMapContainer:SetAllPoints(mapTab.mapContainer)
        GCM.MainFrame.tabMarkers = {}
        GCM.MainFrame.tabMarkerLines = {}
        GCM.MainFrame.tabShowLines = false
    end
    
    -- Load saved markers
    GCM.LoadTabMapMarkers()
    
    -- Initialize case filter dropdown
    GCM.UpdateTabCaseFilterDropdown()
end

-- ==================== TAB MAP FUNCTIONS ====================

-- Toggle map lines for tab map
function GCM.ToggleTabMapLines()
    if not GCM.MainFrame or not GCM.MainFrame.tabs.map then return end
    
    local mapTab = GCM.MainFrame.tabs.map
    if not mapTab.mapContainer then return end
    
    -- Initialize if needed
    if not GCM.MainFrame.tabShowLines then
        GCM.MainFrame.tabShowLines = false
        GCM.MainFrame.tabMarkerLines = {}
    end
    
    GCM.MainFrame.tabShowLines = not GCM.MainFrame.tabShowLines
    
    if GCM.MainFrame.tabShowLines then
        mapTab.toggleLinesBtn:SetText("Hide Lines")
        GCM.UpdateTabMarkerLines()
        print("Tab map connection lines enabled")
    else
        mapTab.toggleLinesBtn:SetText("Connect Dots")
        GCM.HideTabMarkerLines()
        print("Tab map connection lines disabled")
    end
end

-- Update connection lines for tab map
function GCM.UpdateTabMarkerLines()
    if not GCM.MainFrame or not GCM.MainFrame.tabMarkers or not GCM.MainFrame.tabShowLines then
        return
    end
    
    -- Clear existing lines
    GCM.HideTabMarkerLines()
    
    -- Get filtered markers
    local filteredMarkers = GCM.GetTabFilteredMarkers()
    
    -- Don't draw lines if we have fewer than 2 markers
    if #filteredMarkers < 2 then
        print("Not enough tab markers to draw lines (need at least 2)")
        return
    end
    
    -- Initialize line container if needed
    if not GCM.MainFrame.tabMarkerLines then
        GCM.MainFrame.tabMarkerLines = {}
    end
    
    print(string.format("Drawing lines between %d tab markers", #filteredMarkers))
    
    -- Connect each marker to the next one in sequence
    for i = 1, #filteredMarkers - 1 do
        local marker1 = filteredMarkers[i]
        local marker2 = filteredMarkers[i + 1]
        
        if marker1 and marker2 and marker1:IsShown() and marker2:IsShown() then
            GCM.CreateTabLineBetweenMarkers(marker1, marker2)
        end
    end
end

-- Hide all tab marker connection lines
function GCM.HideTabMarkerLines()
    if GCM.MainFrame and GCM.MainFrame.tabMarkerLines then
        for _, line in ipairs(GCM.MainFrame.tabMarkerLines) do
            line:Hide()
        end
        GCM.MainFrame.tabMarkerLines = {}
    end
end

-- Get filtered markers for tab map
function GCM.GetTabFilteredMarkers()
    if not GCM.MainFrame or not GCM.MainFrame.tabMarkers then
        return {}
    end
    
    -- For now, return all markers (can add filtering later)
    local filteredMarkers = {}
    for _, marker in ipairs(GCM.MainFrame.tabMarkers) do
        if marker and marker:IsShown() then
            table.insert(filteredMarkers, marker)
        end
    end
    
    return filteredMarkers
end

-- Create a line between two tab markers
function GCM.CreateTabLineBetweenMarkers(marker1, marker2)
    if not GCM.MainFrame.tabMapContainer then return end
    
    -- Calculate distance and angle
    local x1, y1 = marker1.x, marker1.y
    local x2, y2 = marker2.x, marker2.y
    
    local dx = x2 - x1
    local dy = y2 - y1
    local distance = math.sqrt(dx * dx + dy * dy)
    
    -- Skip if markers are too close
    if distance < 5 then
        return
    end
    
    local angle = math.atan2(-dy, dx)
    
    -- Create line texture
    local line = GCM.MainFrame.tabMapContainer:CreateTexture(nil, "ARTWORK")
    line:SetColorTexture(0.9, 0.9, 0.9, 0.8)
    line:SetSize(distance, 3)
    
    -- Position line at the midpoint
    local midX = x1 + dx / 2
    local midY = y1 + dy / 2
    
    local screenY = GCM.MainFrame.tabMapContainer:GetHeight() - midY
    line:SetPoint("CENTER", GCM.MainFrame.tabMapContainer, "BOTTOMLEFT", midX, screenY)
    
    -- Rotate line
    line:SetRotation(angle)
    line:Show()
    
    table.insert(GCM.MainFrame.tabMarkerLines, line)
end

-- Clear all tab map markers
function GCM.ClearTabMapMarkers()
    if GCM.MainFrame and GCM.MainFrame.tabMarkers then
        for _, marker in ipairs(GCM.MainFrame.tabMarkers) do
            marker:Hide()
        end
        GCM.MainFrame.tabMarkers = {}
        
        -- Clear lines
        GCM.HideTabMarkerLines()
        
        -- Clear from database
        GCM.ClearAllMapMarkers()
        
        print("All tab map markers cleared")
    end
end

-- Load saved markers for tab map
function GCM.LoadTabMapMarkers()
    if not GCM.MainFrame or not GCM.MainFrame.tabMapContainer then
        return
    end
    
    -- Initialize if needed
    if not GCM.MainFrame.tabMarkers then
        GCM.MainFrame.tabMarkers = {}
        GCM.MainFrame.tabMarkerLines = {}
        GCM.MainFrame.tabShowLines = false
    end
    
    -- Clear existing markers first
    if GCM.MainFrame.tabMarkers then
        for _, marker in ipairs(GCM.MainFrame.tabMarkers) do
            marker:Hide()
        end
        GCM.MainFrame.tabMarkers = {}
    end
    
    -- Load markers from database
    local savedMarkers = GCM.GetMapMarkers()
    if not savedMarkers or #savedMarkers == 0 then
        return
    end
    
    -- Sort markers by creation time to maintain order
    table.sort(savedMarkers, function(a, b)
        return (a.createdAt or "") < (b.createdAt or "")
    end)
    
    -- Check if marker container has valid dimensions
    local mapWidth = GCM.MainFrame.tabMapContainer:GetWidth()
    local mapHeight = GCM.MainFrame.tabMapContainer:GetHeight()
    
    if mapWidth <= 0 or mapHeight <= 0 then
        print("Warning: Tab map container not ready yet, deferring marker load...")
        -- Try again after a short delay
        C_Timer.After(0.1, function()
            GCM.LoadTabMapMarkers()
        end)
        return
    end
    
    print(string.format("Loading %d saved tab map markers... (Map size: %.0fx%.0f)", #savedMarkers, mapWidth, mapHeight))
    
    -- Create UI markers for each saved marker
    for _, markerData in ipairs(savedMarkers) do
        GCM.CreateTabMarkerFromData(markerData)
    end
    
    -- Update connection lines if they're enabled
    if GCM.MainFrame.tabShowLines then
        GCM.UpdateTabMarkerLines()
    end
end

-- Show Kirin Tor content within the tab
function GCM.ShowKirinTorContent(kirinTorTab, contentType)
    if not kirinTorTab or not kirinTorTab.contentFrame then return end
    
    -- Hide main menu, show content frame
    kirinTorTab.mainMenu:Hide()
    kirinTorTab.contentFrame:Show()
    
    -- Set title and content based on type
    local title = ""
    local content = ""
    
    if contentType == "archives" then
        title = "Arcane Archives"
        content = [[
|cff6a5acdArcane Archives - Kirin Tor Knowledge Repository|r

Welcome to the Arcane Archives, the premier magical knowledge repository of the Kirin Tor.

|cff9370dbRecent Acquisitions:|r
• |cffffff00"Theoretical Applications of Temporal Flux in Defensive Enchantments"|r - By Archmage Thessarian
• |cffffff00"Comparative Analysis of Ley Line Convergence Points"|r - Academy Research Division
• |cffffff00"Cataloguing Fel Contamination: A Preventative Guide"|r - Purification Committee
• |cffffff00"Ancient Troll Magical Practices and Their Modern Applications"|r - Cultural Exchange Department

|cff9370dbArchive Categories:|r
|cff00ccff• Arcane Theory and Practice|r
  - Fundamental magical principles
  - Advanced spellcrafting techniques
  - Arcane energy manipulation studies

|cff00ccff• Historical Magical Events|r
  - The War of the Ancients: Magical Perspectives
  - Legion Invasions and Magical Countermeasures
  - Scourge Necromancy Analysis

|cff00ccff• Artifact Documentation|r
  - Catalogued magical artifacts
  - Containment protocols
  - Artifact interaction studies

|cff00ccff• Planar Studies|r
  - Dimensional theory
  - Portal mechanics and safety
  - Extraplanar entity documentation

|cffFFFF00Access Note:|r Many documents require appropriate clearance level. Contact your supervisor for restricted material access.

|cffFFFF00Recent Updates:|r
- New section added: "Post-Shadowlands Magical Anomalies"
- Updated safety protocols for handling Void-touched materials
- Expanded collection of Zandalari magical practices
]]
    elseif contentType == "portal" then
        title = "Portal Nexus Control"
        content = [[
|cff6a5acdPortal Nexus - Teleportation Network Control|r

Manage and monitor the vast network of magical portals maintained by the Kirin Tor.

|cff9370dbActive Portal Network Status:|r
|cff00ff00• Dalaran Central Hub:|r |cff00ff00OPERATIONAL|r
|cff00ff00• Stormwind Embassy:|r |cff00ff00OPERATIONAL|r
|cff00ff00• Ironforge Mystic Ward:|r |cff00ff00OPERATIONAL|r
|cffFFFF00• Boralus Portal Sanctum:|r |cffFFFF00MAINTENANCE|r
|cff00ff00• Darnassus Memorial Gate:|r |cff00ff00OPERATIONAL|r
|cffFFFF00• Shattrath City:|r |cffFFFF00LIMITED ACCESS|r
|cff00ff00• Shrine of Seven Stars:|r |cff00ff00OPERATIONAL|r
|cff00ff00• Valdrakken:|r |cff00ff00OPERATIONAL|r

|cffff0000• Legion-affected Areas:|r |cffff0000QUARANTINED|r
|cffff0000• Shadowlands Rifts:|r |cffff0000SEALED|r

|cff9370dbRecent Portal Activity:|r
|cffffff00[Today - 14:23]|r Emergency transport to Stormwind - Medical evacuation
|cffffff00[Today - 11:15]|r Routine supply delivery to Valdrakken outpost
|cffffff00[Yesterday - 18:45]|r Diplomatic mission to Boralus (postponed due to maintenance)
|cffffff00[Yesterday - 09:30]|r Academic exchange with Shrine of Seven Stars

|cff9370dbPortal Regulations:|r
|cff00ccff• Authorization Level 1:|r City-to-city civilian transport
|cff00ccff• Authorization Level 2:|r Military and diplomatic missions
|cff00ccff• Authorization Level 3:|r Emergency and rescue operations
|cff00ccff• Authorization Level 4:|r Restricted dimensional research

|cffFFFF00Maintenance Schedule:|r
- Boralus Portal: Estimated completion 48 hours
- Routine network stability check: Weekly on Tuesdays
- Emergency protocol drills: Monthly

|cffff0000WARNING:|r Unauthorized portal creation within 500 yards of established nexus points is strictly prohibited and may result in dimensional instability.
]]
    elseif contentType == "licences" then
        title = "Magical Licences & Certifications"
        content = [[
|cff6a5acdMagical Licences & Certifications Registry|r

Official documentation for all magical practice authorizations within Kirin Tor jurisdiction.

|cff9370dbLicence Categories:|r

|cff00ccff• Class A - Basic Magical Practice|r
  - Cantrip and minor spell authorization
  - Valid for: Apprentice-level practitioners
  - Duration: 2 years
  - Renewal required: Written examination

|cff00ccff• Class B - Advanced Arcane Arts|r
  - Intermediate to advanced spellcasting
  - Valid for: Certified mages and specialists
  - Duration: 5 years
  - Renewal required: Practical demonstration + ethics review

|cff00ccff• Class C - Specialized Magical Fields|r
  - Enchantment, divination, transmutation specializations
  - Valid for: Master-level practitioners
  - Duration: 7 years
  - Renewal required: Peer review + continued education

|cff00ccff• Class D - Portal Magic Authorization|r
  - Teleportation and dimensional magic
  - Valid for: Certified portal mages only
  - Duration: 3 years
  - Renewal required: Rigorous testing + psychological evaluation

|cff00ccff• Class E - Dangerous Magic Permit|r
  - Necromancy research, void studies, fel containment
  - Valid for: Senior researchers with security clearance
  - Duration: 1 year
  - Renewal required: Full investigation + supervisor approval

|cff9370dbRecent Licence Actions:|r
|cff00ff00• Approved:|r 15 Class A renewals
|cff00ff00• Approved:|r 8 Class B new applications
|cff00ff00• Approved:|r 2 Class C specialization upgrades
|cffFFFF00• Under Review:|r 3 Class D portal certifications
|cffff0000• Suspended:|r 1 Class E permit (pending investigation)
|cffff0000• Revoked:|r 2 Class B licences (ethical violations)

|cffFFFF00Application Requirements:|r
- Completed application form KT-MAG-001
- Proof of magical education or equivalent experience
- Character references from 2 certified practitioners
- Background security check
- Application fee: 50 gold (non-refundable)

|cffFFFF00Contact Information:|r
- Licence Office: Dalaran, Violet Gate District
- Hours: 8 AM - 6 PM, Monday through Friday
- Emergency licence queries: Contact Duty Magistrate
]]
    elseif contentType == "enemies" then
        title = "Enemies of the Kirin Tor"
        content = [[
|cffff0000CLASSIFIED - ENEMIES OF THE KIRIN TOR|r
|cffff0000SECURITY CLEARANCE LEVEL 3 REQUIRED|r

|cff9370dbActive Threats - High Priority:|r

|cffff0000• The Defias Spellbreakers|r
  Status: |cffff0000ACTIVE THREAT|r
  Leadership: Unknown masked figure "The Arcane Bane"
  Activities: Sabotaging magical infrastructure, assassinating mages
  Last Known Location: Westfall underground network
  Threat Level: |cffff0000EXTREME|r

|cffff0000• Twilight's Hammer Remnants|r
  Status: |cffff0000ACTIVE THREAT|r
  Leadership: Scattered cell structure
  Activities: Void corruption, dimensional breaches
  Last Known Location: Multiple remote locations
  Threat Level: |cffff0000HIGH|r

|cffFFFF00• Sunreavers (Defector Faction)|r
  Status: |cffFFFF00MONITORING|r
  Leadership: Unknown defector elements
  Activities: Information theft, political manipulation
  Last Known Location: Various
  Threat Level: |cffFFFF00MEDIUM|r

|cff9370dbWanted Individuals:|r

|cffff0000• "The Void Whisperer"|r - Reward: 10,000 Gold
  Description: Former Kirin Tor mage, turned to void magic
  Crimes: Murder of three council members, void corruption
  Warning: |cffff0000EXTREMELY DANGEROUS|r - Do not approach alone

|cffff0000• Magister Shadowbane|r - Reward: 5,000 Gold
  Description: Exiled for forbidden necromancy research
  Crimes: Illegal experimentation, theft of artifacts
  Warning: Known to use mind control magic

|cffFFFF00• The Rogue Enchanter|r - Reward: 2,000 Gold
  Description: Unlicensed magical practice, fraud
  Crimes: Selling cursed items, false magical services
  Warning: Items may have delayed harmful effects

|cff9370dbRecent Intelligence:|r
|cffffff00[Today]|r Increased Defias Spellbreaker activity near Goldshire
|cffffff00[2 days ago]|r Suspicious void energy detected in Duskwood
|cffffff00[1 week ago]|r Unauthorized portal detected in Stranglethorn

|cffff0000SECURITY PROTOCOLS:|r
- Report all suspicious magical activity immediately
- Do not engage high-priority targets without backup
- All void-related incidents require immediate containment
- Magical signature scanning mandatory at all checkpoints

|cffFFFF00For reporting suspected enemies or seeking additional intelligence, contact the Security Division immediately.|r
]]
    elseif contentType == "artifacts" then
        title = "Magical Artifact Database"
        content = [[
|cff6a5acdMagical Artifact Database - Kirin Tor Registry|r

Comprehensive catalog of magical artifacts under Kirin Tor protection and study.

|cff9370dbRecently Cataloged Artifacts:|r

|cffffff00• Shard of the Sunwell (Replica)|r
  Classification: |cff00ccffClass B - Moderate Power|r
  Location: |cff00ff00Vault 7-A, Secured|r
  Description: Artificially created sunwell crystal fragment
  Properties: Minor holy energy generation, light manipulation
  Containment: Standard magical suppression field

|cffffff00• Tome of Eternal Binding|r
  Classification: |cffFFFF00Class C - High Risk|r
  Location: |cffFFFF00Restricted Vault 12, Level 3 Security|r
  Description: Ancient tome containing powerful binding spells
  Properties: Demon summoning and binding (theoretical)
  Containment: Sealed, blessed containment, 24/7 monitoring

|cffffff00• Crystal of Temporal Echoes|r
  Classification: |cffff0000Class D - Extreme Danger|r
  Location: |cffff0000Maximum Security Vault, Dalaran Core|r
  Description: Crystallized time magic from Caverns of Time
  Properties: Limited temporal manipulation, reality distortion
  Containment: Chronium-lined vault, multiple failsafes

|cffffff00• Pendant of Whispering Shadows|r
  Classification: |cff00ccffClass A - Low Risk|r
  Location: |cff00ff00Study Lab 3, Available for Research|r
  Description: Jewelry piece with minor shadow affinity
  Properties: Enhanced stealth abilities, shadow resistance
  Containment: Standard display case

|cff9370dbArtifact Classifications:|r
|cff00ccff• Class A:|r Low-power, minimal risk, suitable for study
|cffFFFF00• Class B:|r Moderate power, controlled research only
|cffFFFF00• Class C:|r High risk, restricted access, senior researchers
|cffff0000• Class D:|r Extreme danger, council approval required
|cffff0000• Class E:|r World-ending potential, sealed indefinitely

|cff9370dbRecent Acquisitions:|r
- Acquired from Stormwind auction: "Mage's Focus Crystal"
- Confiscated from illegal dealer: "Corrupted Essence Vial"
- Donated by retiring mage: "Scroll of Greater Teleportation"

|cff9370dbMissing/Stolen Artifacts:|r
|cffff0000• Ring of Elemental Command|r - |cffff0000STOLEN 3 weeks ago|r
  Last seen: Stormwind Mage Quarter
  Suspect: Unknown thief with teleportation abilities
  Reward for recovery: 5,000 gold

|cffFFFF00Artifact Research Requests:|r
To request access to artifacts for research purposes, submit Form KT-ART-Research to the Artifact Committee. Include detailed research proposal and security clearance documentation.
]]
    elseif contentType == "research" then
        title = "Magical Theory & Research"
        content = [[
|cff6a5acdMagical Theory & Research Division|r

Advancing magical understanding through rigorous research and experimentation.

|cff9370dbActive Research Projects:|r

|cffffff00• Project: Ley Line Harmonics|r
  Lead Researcher: Archmage Veras Windweaver
  Status: |cff00ff00Phase 3 - Field Testing|r
  Objective: Optimize ley line energy distribution across Azeroth
  Funding: 50,000 gold (Approved)
  Expected Completion: 8 months

|cffffff00• Project: Void Resistance Theory|r
  Lead Researcher: Master Lumina Dawnforge
  Status: |cffFFFF00Phase 2 - Laboratory Analysis|r
  Objective: Develop improved void corruption countermeasures
  Funding: 35,000 gold (Under Review)
  Expected Completion: 12 months

|cffffff00• Project: Arcane Fusion Principles|r
  Lead Researcher: Professor Thalmic Sparkweaver
  Status: |cff00ff00Phase 4 - Practical Application|r
  Objective: Create more efficient spell-weaving techniques
  Funding: 25,000 gold (Approved)
  Expected Completion: 4 months

|cffffff00• Project: Dimensional Anchor Theory|r
  Lead Researcher: Dr. Magistrix Thornfield
  Status: |cffff0000Phase 1 - Theoretical Foundation|r
  Objective: Prevent unwanted dimensional breaches
  Funding: 75,000 gold (Pending Council Approval)
  Expected Completion: 18 months

|cff9370dbRecent Discoveries:|r

|cff00ccff• Mana Crystallization Enhancement:|r
  Breakthrough in creating more stable mana crystals
  Applications: Improved magical item construction
  Status: Patent filed, preparing for implementation

|cff00ccff• Teleportation Safety Protocols:|r
  New safety measures reduce teleportation mishaps by 73%
  Applications: Portal network improvements
  Status: Implementing across all portal stations

|cff00ccff• Elemental Binding Stabilization:|r
  Method to create longer-lasting elemental summons
  Applications: Enhanced magical constructs
  Status: Classified - Military applications being evaluated

|cffFFFF00Ethics Committee Reminder:|r
All research involving sentient beings, dangerous magic, or potential weapons development must receive Ethics Committee approval before commencement.
]]
    elseif contentType == "lectures" then
        title = "Academic Lectures"
        content = [[
|cff6a5acdKirin Tor Academic Lecture Series|r

Regular educational lectures and seminars for the advancement of magical knowledge and scholarly exchange.

|cff9370dbUpcoming Lectures This Month:|r

|cffffff00• "Fundamentals of Arcane Theory"|r
  Lecturer: Archmage Antonidas Memorial Chair Professor Windweaver
  Date: |cff00ff00Next Tuesday, 19:00|r
  Location: Great Hall, Violet Citadel
  Level: |cff00ccffBeginner to Intermediate|r
  Topics: Mana manipulation, spell structure basics, safety protocols
  Duration: 2 hours (includes Q&A session)

|cffffff00• "Advanced Portal Magic: Theory and Practice"|r
  Lecturer: Portal Master Sorenson & Dr. Dimensional Studies Kaelthas
  Date: |cff00ff00Thursday Next Week, 18:30|r
  Location: Portal Laboratory Complex, Level 3
  Level: |cffFFFF00Advanced - Certification Required|r
  Topics: Dimensional stability, portal anchoring, emergency protocols
  Duration: 3 hours (practical demonstration included)
  |cffff0000Prerequisites:|r Class D Portal Magic License or equivalent

|cffffff00• "Historical Analysis: The War of the Ancients from a Magical Perspective"|r
  Lecturer: Chief Historian Brann Bronzebeard (Guest Speaker)
  Date: |cff00ff00Weekend Symposium, 14:00|r
  Location: Archive Amphitheater
  Level: |cff00ccffAll Levels Welcome|r
  Topics: Ancient magical practices, historical spell research, artifact analysis
  Duration: 1.5 hours
  |cff00ccffSpecial Note:|r Rare historical artifacts will be on display

|cffffff00• "Void Magic: Understanding and Containment"|r
  Lecturer: Master Voidbane & Security Division
  Date: |cffff0000Restricted Schedule - Security Clearance Required|r
  Location: |cffff0000Classified|r
  Level: |cffff0000Level 3 Clearance Minimum|r
  Topics: Void corruption identification, containment protocols, safety measures
  Duration: 4 hours (includes practical exercises)
  |cffff0000Warning:|r Dangerous material - full protective gear mandatory

|cff9370dbMonthly Lecture Series:|r

|cff00ccff• First Monday:|r "Enchantment Workshop" - Practical enchanting techniques
|cff00ccff• Second Wednesday:|r "Magical Creatures Studies" - Behavior and magical properties
|cff00ccff• Third Friday:|r "Alchemical Advances" - Latest developments in magical alchemy
|cff00ccff• Fourth Saturday:|r "Inter-Dimensional Studies" - Exploring other planes of existence

|cff9370dbGuest Lecture Program:|r

The Kirin Tor regularly hosts distinguished guest speakers from across Azeroth:

|cffffff00• Recent Guest Speakers:|r
  - Malfurion Stormrage: "Nature vs. Arcane: Finding Balance"
  - Jaina Proudmoore: "Leadership in Times of Magical Crisis"
  - Khadgar: "Lessons from the Dark Portal Expeditions"
  - Velen: "The Light and Arcane Magic: Complementary Forces"

|cffffff00• Upcoming Guest Lectures:|r
  - Tyrande Whisperwind: "Elune's Magic and Arcane Studies" (Tentative)
  - Alleria Windrunner: "Void and Light: A Personal Journey" (Under Review)

|cff9370dbSpecialized Workshops:|r

|cff00ccff• Apprentice Magic Circle:|r Weekly gatherings for new practitioners
|cff00ccff• Master's Roundtable:|r Advanced discussions for experienced mages
|cff00ccff• Research Presentation Series:|r Students and faculty present ongoing research
|cff00ccff• Ethics in Magic Seminars:|r Monthly discussions on magical responsibility

|cffFFFF00Attendance Information:|r
- Most lectures are free for Kirin Tor members and affiliates
- External attendees: 5 gold donation suggested
- Advanced/Restricted lectures require appropriate clearance
- Magical recording devices prohibited unless approved
- Lecture notes available in the Archive within 48 hours

|cffFFFF00Registration:|r
Contact the Academic Affairs Office or submit Form KT-EDU-001 for lecture registration. Popular lectures may require advance booking.

|cff00ccffFor scheduling your own lecture or proposing topics, contact the Lecture Committee through official channels.|r
]]
    elseif contentType == "factions" then
        title = "Other Faction Relations"
        content = [[
|cff6a5acdKirin Tor Diplomatic Relations Status|r

Current standings with major factions and organizations across Azeroth.

|cff9370dbAlliance Factions:|r

|cff00ff00• Kingdom of Stormwind|r - |cff00ff00ALLIED|r
  Relationship Status: Strong diplomatic ties
  Recent Cooperation: Joint magical defense initiatives
  Ambassador: Lady Katrana Prestor (liaison)
  Trade Agreements: Magic item exchange, portal services

|cff00ff00• Ironforge|r - |cff00ff00ALLIED|r
  Relationship Status: Excellent, long-standing friendship
  Recent Cooperation: Archaeological expeditions, titan research
  Ambassador: Explorer Brann Bronzebeard (honorary)
  Trade Agreements: Gemstone enhancement, runic research

|cff00ff00• Darnassus (Memorial)|r - |cff00ccffHONORED|r
  Relationship Status: Memorial services, refugee support
  Recent Cooperation: Nature-arcane magic balance research
  Ambassador: Tyrande Whisperwind (memorial council)
  Trade Agreements: Druidic consultation services

|cff00ff00• Gilneas|r - |cff00ff00ALLIED|r
  Relationship Status: Strong cooperation
  Recent Cooperation: Curse research, magical protection
  Ambassador: Genn Greymane
  Trade Agreements: Alchemical research, worgen studies

|cff9370dbHorde Relations:|r

|cffFFFF00• Orgrimmar|r - |cffFFFF00NEUTRAL|r
  Relationship Status: Cautious diplomacy
  Recent Cooperation: Shared threat response (Legion, etc.)
  Ambassador: Thrall (when available)
  Trade Agreements: Limited, case-by-case basis

|cffFFFF00• Silvermoon City|r - |cffFFFF00COMPLEX|r
  Relationship Status: Strained due to Sunreaver incidents
  Recent Cooperation: Minimal, official channels only
  Ambassador: Currently under review
  Trade Agreements: Suspended pending investigation

|cff9370dbNeutral Organizations:|r

|cff00ff00• Earthen Ring|r - |cff00ff00ALLIED|r
  Relationship Status: Strong professional cooperation
  Recent Cooperation: Elemental balance research

|cff00ff00• Cenarion Circle|r - |cff00ccffFRIENDLY|r
  Relationship Status: Environmental protection partnership
  Recent Cooperation: Arcane pollution cleanup

|cffFFFF00• Argent Dawn|r - |cffFFFF00NEUTRAL|r
  Relationship Status: Professional respect
  Recent Cooperation: Undead threat response

|cff9370dbRecent Diplomatic Events:|r
|cffffff00[This Week]|r Successful trade negotiation with Ironforge
|cffffff00[Last Month]|r Diplomatic incident with Silvermoon resolved
|cffffff00[2 Months Ago]|r Joint research agreement signed with Earthen Ring

|cffFFFF00Diplomatic Protocol Note:|r All faction interactions must be reported to the Diplomatic Corps. Unauthorized negotiations may result in disciplinary action.
]]
    end
    
    -- Set the title and content
    kirinTorTab.contentTitle:SetText("|cff6a5acd" .. title .. "|r")
    kirinTorTab.contentText:SetText(content)
    
    -- Adjust scroll height
    kirinTorTab.scrollChild:SetHeight(kirinTorTab.contentText:GetStringHeight() + 20)
end

-- Show GJLE content within the tab
function GCM.ShowGJLEContent(gjleTab, contentType)
    if not gjleTab or not gjleTab.documentView then return end
    
    -- Hide main menu, show document view
    gjleTab.mainMenu:Hide()
    gjleTab.documentView:Show()
    
    -- Set title and content based on type
    local title = ""
    local content = {}
    
    if contentType == "guidelines" then
        title = "GJLE Guidelines"
        
        -- Build formatted guidelines content
        table.insert(content, "|cff00ccffGilneas Judiciary Law Enforcement Guidelines|r")
        table.insert(content, "")
        table.insert(content, "This document contains official guidelines and procedures for GJLE members.")
        table.insert(content, "")
        
        table.insert(content, "|cffFFD700=== SECTION 1: GENERAL CONDUCT ===|r")
        table.insert(content, "")
        table.insert(content, "|cff00ccff• Professional Standards:|r")
        table.insert(content, "  - Maintain professional standards at all times")
        table.insert(content, "  - Remember you represent not only Gilneas but the Kirin Tor also")
        table.insert(content, "  - Conduct yourself with honor and integrity in all situations")
        table.insert(content, "")
        table.insert(content, "|cff00ccff• Chain of Command:|r")
        table.insert(content, "  - Follow proper chain of command at all times")
        table.insert(content, "  - Detectives report to their respective higher-ups")
        table.insert(content, "  - Escalate issues through appropriate channels")
        table.insert(content, "")
        table.insert(content, "|cff00ccff• Documentation:|r")
        table.insert(content, "  - Document all activities thoroughly")
        table.insert(content, "  - The truth is in the details - record everything accurately")
        table.insert(content, "  - Maintain confidentiality of sensitive information")
        table.insert(content, "")
        
        table.insert(content, "|cffFFD700=== SECTION 2: INVESTIGATION PROCEDURES ===|r")
        table.insert(content, "")
        table.insert(content, "|cff00ccff• Partnership Protocol:|r")
        table.insert(content, "  - Always work in pairs when possible for safety and verification")
        table.insert(content, "  - Maintain communication with your partner at all times")
        table.insert(content, "  - Establish clear roles and responsibilities before proceeding")
        table.insert(content, "")
        table.insert(content, "|cff00ccff• Evidence Handling:|r")
        table.insert(content, "  - Secure evidence properly using established protocols")
        table.insert(content, "  - Maintain chain of custody documentation")
        table.insert(content, "  - Never tamper with or contaminate evidence")
        table.insert(content, "  - Photograph all evidence before collection when possible")
        table.insert(content, "")
        table.insert(content, "|cff00ccff• Witness Interviews:|r")
        table.insert(content, "  - Interview witnesses systematically and thoroughly")
        table.insert(content, "  - Record all statements accurately and completely")
        table.insert(content, "  - Maintain professional demeanor during all interviews")
        table.insert(content, "  - Ensure witness safety and privacy when required")
        table.insert(content, "")
        
        table.insert(content, "|cffFFD700=== SECTION 3: REPORTING STANDARDS ===|r")
        table.insert(content, "")
        table.insert(content, "|cff00ccff• Report Format:|r")
        table.insert(content, "  - Use standardized report formats for all documentation")
        table.insert(content, "  - Include all relevant details and supporting evidence")
        table.insert(content, "  - Maintain objective, factual language throughout")
        table.insert(content, "")
        table.insert(content, "|cff00ccff• Submission Timeline:|r")
        table.insert(content, "  - Submit reports within 24 hours of incident completion")
        table.insert(content, "  - Emergency situations require immediate preliminary reports")
        table.insert(content, "  - Follow up with detailed reports as soon as practical")
        table.insert(content, "")
        table.insert(content, "|cff00ccff• Content Requirements:|r")
        table.insert(content, "  - Include all relevant details and circumstances")
        table.insert(content, "  - Attach supporting documentation and evidence logs")
        table.insert(content, "  - Provide clear recommendations for next steps")
        table.insert(content, "")
        
        table.insert(content, "|cffFFD700=== SECTION 4: SAFETY PROTOCOLS ===|r")
        table.insert(content, "")
        table.insert(content, "|cff00ccff• Risk Assessment:|r")
        table.insert(content, "  - Assess all risks before proceeding with any operation")
        table.insert(content, "  - Consider environmental, personal, and operational hazards")
        table.insert(content, "  - Document risk assessments for review and planning")
        table.insert(content, "")
        table.insert(content, "|cff00ccff• Communication:|r")
        table.insert(content, "  - Maintain regular communication with headquarters")
        table.insert(content, "  - Report status updates at scheduled intervals")
        table.insert(content, "  - Immediately report any changes in situation or threats")
        table.insert(content, "")
        table.insert(content, "|cff00ccff• Backup Procedures:|r")
        table.insert(content, "  - Request backup when necessary - never hesitate")
        table.insert(content, "  - Clearly communicate the nature of assistance required")
        table.insert(content, "  - Wait for backup arrival before proceeding in high-risk situations")
        table.insert(content, "")
        
        table.insert(content, "|cffFFD700=== SECTION 5: ETHICAL STANDARDS ===|r")
        table.insert(content, "")
        table.insert(content, "|cff00ccff• Personal Conduct:|r")
        table.insert(content, "  - Maintain highest ethical standards in all professional activities")
        table.insert(content, "  - Avoid conflicts of interest and declare any potential issues")
        table.insert(content, "  - Treat all individuals with respect and dignity")
        table.insert(content, "")
        table.insert(content, "|cff00ccff• Confidentiality:|r")
        table.insert(content, "  - Protect confidential information and ongoing investigations")
        table.insert(content, "  - Limit information sharing to authorized personnel only")
        table.insert(content, "  - Secure all documents and evidence appropriately")
        table.insert(content, "")
        
        table.insert(content, "|cffFFFF00IMPORTANT NOTE:|r")
        table.insert(content, "These guidelines are subject to updates and revisions. Always refer to the latest version available through official channels. Questions about procedures should be directed to supervising officers or the GJLE administrative office.")
        table.insert(content, "")
        table.insert(content, "|cffccccccLast Updated: Current Date")
        table.insert(content, "Document Classification: Internal Use Only|r")
        
    elseif contentType == "correspondence" then
        title = "GJLE Correspondence"
        
        -- Build formatted correspondence content
        table.insert(content, "|cff00ccffGJLE Official Correspondence Archive|r")
        table.insert(content, "")
        table.insert(content, "This section contains official communications and administrative correspondence.")
        table.insert(content, "")
        
        table.insert(content, "|cffFFD700=== RECENT OFFICIAL COMMUNICATIONS ===|r")
        table.insert(content, "")
        
        table.insert(content, "|cff00ccff[Current Date - Priority: Normal]|r")
        table.insert(content, "|cffffff00From:|r Guild Leadership - Professor Charles Magnussen")
        table.insert(content, "|cffffff00Subject:|r Weekly Operations Update and Performance Review")
        table.insert(content, "")
        table.insert(content, "All operatives are reminded to submit their weekly reports by the designated deadline. Recent activities show increased efficiency in case resolution and improved inter-departmental cooperation.")
        table.insert(content, "")
        table.insert(content, "Key Points:")
        table.insert(content, "• Case clearance rate has improved by 15% this quarter")
        table.insert(content, "• New evidence processing protocols are showing positive results")
        table.insert(content, "• Joint operations with Kirin Tor Intelligence continue to be successful")
        table.insert(content, "")
        table.insert(content, "Action Items:")
        table.insert(content, "• Review updated safety protocols (distributed separately)")
        table.insert(content, "• Complete mandatory training sessions by month end")
        table.insert(content, "• Submit feedback on new reporting system")
        table.insert(content, "")
        table.insert(content, "|cffcccccc--- End of Message ---|r")
        table.insert(content, "")
        
        table.insert(content, "|cff00ccff[Previous Week - Priority: High]|r")
        table.insert(content, "|cffffff00From:|r Field Operations Division - Senior Agent Sarah Brightblade")
        table.insert(content, "|cffffff00Subject:|r Equipment Requisition Approval and Distribution")
        table.insert(content, "")
        table.insert(content, "Request for additional investigation tools and surveillance equipment has been approved by the oversight committee. Equipment will be distributed through normal channels within the next 48 hours.")
        table.insert(content, "")
        table.insert(content, "Approved Items:")
        table.insert(content, "• Enhanced scrying crystals (Quantity: 12)")
        table.insert(content, "• Portable evidence analysis kits (Quantity: 6)")
        table.insert(content, "• Secure communication devices (Quantity: 24)")
        table.insert(content, "• Field documentation supplies (Various)")
        table.insert(content, "")
        table.insert(content, "Distribution Priority: Active field operatives first, followed by support staff.")
        table.insert(content, "Training on new equipment will be provided during next week's briefings.")
        table.insert(content, "")
        table.insert(content, "|cffcccccc--- End of Message ---|r")
        table.insert(content, "")
        
        table.insert(content, "|cff00ccff[Two Weeks Ago - Priority: Normal]|r")
        table.insert(content, "|cffffff00From:|r Training Division - Chief Forensic Analyst Dr. Thalassic Voidbane")
        table.insert(content, "|cffffff00Subject:|r Updated Training Protocols and Certification Requirements")
        table.insert(content, "")
        table.insert(content, "New training protocols are now in effect as of this date. All personnel are required to review the updated procedures available in the Guidelines section of this system.")
        table.insert(content, "")
        table.insert(content, "Key Updates:")
        table.insert(content, "• Magical evidence handling procedures (revised)")
        table.insert(content, "• Void corruption detection and containment")
        table.insert(content, "• Advanced interview and interrogation techniques")
        table.insert(content, "• Crisis management and de-escalation")
        table.insert(content, "")
        table.insert(content, "Certification Requirements:")
        table.insert(content, "• Complete practical assessments by quarter end")
        table.insert(content, "• Attend mandatory safety briefings")
        table.insert(content, "• Submit training completion documentation")
        table.insert(content, "")
        table.insert(content, "Contact the Training Division office for scheduling and additional information.")
        table.insert(content, "")
        table.insert(content, "|cffcccccc--- End of Message ---|r")
        table.insert(content, "")
        
        table.insert(content, "|cffFFD700=== ADMINISTRATIVE NOTICES ===|r")
        table.insert(content, "")
        
        table.insert(content, "|cff00ccff• Monthly Performance Reviews:|r")
        table.insert(content, "  Scheduled for the last week of each month. Individual appointments will be")
        table.insert(content, "  distributed via secure channels. Prepare case summaries and self-assessments.")
        table.insert(content, "")
        
        table.insert(content, "|cff00ccff• Policy Updates and Changes:|r")
        table.insert(content, "  Regular policy updates are distributed through this correspondence system.")
        table.insert(content, "  All personnel are responsible for staying current with policy changes.")
        table.insert(content, "")
        
        table.insert(content, "|cff00ccff• Inter-departmental Communications:|r")
        table.insert(content, "  Coordination with Kirin Tor Intelligence, Stormwind Guard, and other allied")
        table.insert(content, "  organizations. Maintain professional protocols in all external communications.")
        table.insert(content, "")
        
        table.insert(content, "|cff00ccff• External Agency Liaison Updates:|r")
        table.insert(content, "  Regular briefings on joint operations and shared intelligence initiatives.")
        table.insert(content, "  Contact the Administrative Office for specific liaison information.")
        table.insert(content, "")
        
        table.insert(content, "|cffFFD700=== ARCHIVED COMMUNICATIONS ===|r")
        table.insert(content, "")
        table.insert(content, "Archived correspondence is available through the GJLE Records Office.")
        table.insert(content, "Access requires appropriate clearance level and official justification.")
        table.insert(content, "")
        table.insert(content, "Available Archives:")
        table.insert(content, "• Quarterly operational reports (Last 2 years)")
        table.insert(content, "• Policy development correspondence")
        table.insert(content, "• Inter-agency communication logs")
        table.insert(content, "• Training program development records")
        table.insert(content, "• Equipment and resource allocation history")
        table.insert(content, "")
        
        table.insert(content, "|cffFFFF00ACCESS CONTROL NOTE:|r")
        table.insert(content, "Access to sensitive correspondence may be restricted based on clearance level and")
        table.insert(content, "operational necessity. Contact your supervising officer for access requests to")
        table.insert(content, "classified or restricted communications.")
        table.insert(content, "")
        table.insert(content, "|cffccccccFor urgent communications or emergency situations, use designated emergency")
        table.insert(content, "communication protocols rather than this correspondence system.|r")
    end
    
    -- Set the title and content
    gjleTab.docTitle:SetText("|cff00ccff" .. title .. "|r")
    gjleTab.docContent:SetText(table.concat(content, "\n"))
    
    -- Adjust scroll height
    gjleTab.docScrollChild:SetHeight(gjleTab.docContent:GetStringHeight() + 40)
end

-- Update tab case filter dropdown
function GCM.UpdateTabCaseFilterDropdown()
    if not GCM.MainFrame or not GCM.MainFrame.tabs.map then return end
    
    local mapTab = GCM.MainFrame.tabs.map
    if not mapTab.caseFilterDropdown then return end
    
    local dropdown = mapTab.caseFilterDropdown
    
    local function OnClick(self)
        GCM.MainFrame.selectedTabFilterCaseId = self.value
        UIDropDownMenu_SetText(dropdown, self:GetText())
        CloseDropDownMenus()
        -- Update lines when case selection changes
        if GCM.MainFrame.tabShowLines then
            GCM.UpdateTabMarkerLines()
        end
    end
    
    local function Initialize(self, level)
        local info = UIDropDownMenu_CreateInfo()
        
        -- All markers option
        info.text = "All Markers"
        info.value = "all"
        info.func = OnClick
        info.fontObject = "GameFontNormalHuge"  -- Even larger font
        info.minWidth = 400  -- Increased minimum width for menu items
        UIDropDownMenu_AddButton(info)
        
        -- Add cases (this will need integration with actual case data)
        for _, case in ipairs(GCM_Database.cases or {}) do
            info.text = string.format("Case #%s: %s", case.id or "?", case.title or "Untitled")
            info.value = case.id
            info.func = OnClick
            info.fontObject = "GameFontNormalHuge"  -- Even larger font
            info.minWidth = 400  -- Increased minimum width for menu items
            UIDropDownMenu_AddButton(info)
        end
    end
    
    UIDropDownMenu_Initialize(dropdown, Initialize)
    UIDropDownMenu_SetWidth(dropdown, 300)  -- Increased width to 300 pixels
    UIDropDownMenu_SetText(dropdown, "All Markers")
    
    -- Set the dropdown list width to be wider for better readability
    dropdown.maxWidth = 450  -- Make popup menu even wider
end

-- Create About Tab Content
function GCM.CreateAboutTab(parent)
    local aboutTab = CreateFrame("Frame", nil, parent)
    aboutTab:SetAllPoints()
    
    -- Title
    local title = aboutTab:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -30)
    title:SetText("|cff00ccffAbout Guild Case Manager|r")
    
    -- Logo
    local logo = aboutTab:CreateTexture(nil, "ARTWORK")
    logo:SetSize(150, 100)
    logo:SetPoint("TOP", 0, -80)
    logo:SetTexture("Interface\\AddOns\\GuildCaseManager\\media\\acdb_logo.tga")
    
    -- Content
    local content = aboutTab:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    content:SetPoint("TOPLEFT", 40, -200)
    content:SetPoint("BOTTOMRIGHT", -40, 80)
    content:SetJustifyH("LEFT")
    content:SetJustifyV("TOP")
    content:SetText("|cff6a5acdGuild Case Manager v2.0|r\n\n" ..
        "A comprehensive roleplaying tool for detective work, investigations, and IC interactions.\n\n" ..
        "|cff9370dbCreated by:|r Mágnussen (@LordChristoff)\n" ..
        "|cff9370dbFor:|r Argent Dawn RP Community\n\n" ..
        "|cff9370dbKey Features:|r\n" ..
        "|cff00ccff• Cases:|r Track investigations and case progress\n" ..
        "|cff00ccff• People:|r Maintain detailed character profiles\n" ..
        "|cff00ccff• Map:|r Mark important locations with case links\n" ..
        "|cff00ccff• Staff:|r Directory of Arcane Consortium personnel\n" ..
        "|cff00ccff• GJLE:|r Gilneas Judiciary Law Enforcement hub\n" ..
        "|cff00ccff• Kirin Tor:|r Access magical archives and information\n" ..
        "|cff00ccff• Sync:|r Data synchronization between all guild members\n\n" ..
        "|cffffcc00Commands:|r\n" ..
        "• |cff00ff00/acdb|r - Open the main interface\n" ..
        "• |cff00ff00/acdbw|r - Show welcome screen\n\n" ..
        "|cffccccccThis addon enhances detective roleplay by providing tools for case management, character tracking, and collaborative investigations.|r")
    
    aboutTab:Hide()
    return aboutTab
end

-- ==================== TAB CASE MANAGEMENT FUNCTIONS ====================

-- Show case edit form within tab
function GCM.ShowTabCaseEdit(casesTab, caseData)
    if not casesTab or not casesTab.formView then return end
    
    casesTab.listView:Hide()
    casesTab.formView:Show()
    
    -- Set form title
    if caseData then
        casesTab.formTitle:SetText("|cff00ccffEdit Case|r")
        casesTab.editingCaseID = caseData.id
        casesTab.saveBtn:Show()
    else
        casesTab.formTitle:SetText("|cff00ccffNew Case|r")
        casesTab.editingCaseID = nil
        casesTab.saveBtn:Show()
    end
    
    -- Populate fields
    local case = caseData or {}
    casesTab.titleInput:SetText(case.title or "")
    casesTab.descriptionInput:SetText(case.description or "")
    casesTab.caseTypeInput:SetText(case.caseType or "")
    casesTab.priorityInput:SetText(case.priority or "")
    casesTab.statusInput:SetText(case.status or "")
    casesTab.locationInput:SetText(case.location or "")
    casesTab.assignedToInput:SetText(case.assignedTo or "")
    casesTab.clientInput:SetText(case.client or "")
    casesTab.incidentDateInput:SetText(case.incidentDate or "")
    casesTab.relatedCasesInput:SetText(case.relatedCases or "")
    casesTab.suspectsInput:SetText(case.suspects or "")
    casesTab.leadsInput:SetText(case.leads or "")
    casesTab.witnessesInput:SetText(case.witnesses or "")
    casesTab.evidenceChainInput:SetText(case.evidenceChain or "")
    casesTab.interviewNotesInput:SetText(case.interviewNotes or "")
    casesTab.caseNotesInput:SetText(case.caseNotes or "")
    casesTab.nextStepsInput:SetText(case.nextSteps or "")
end

-- Show case view form within tab (read-only document style)
function GCM.ShowTabCaseView(casesTab, caseData)
    if not casesTab or not casesTab.documentView then return end
    
    casesTab.listView:Hide()
    casesTab.formView:Hide()  -- Hide the edit form
    casesTab.documentView:Show()  -- Show the document view
    
    -- Set document title
    casesTab.docTitle:SetText(string.format("|cff00ccff%s|r", caseData.title or "Untitled Case"))
    
    -- Helper function to create formatted lines
    local function CreateDetailLine(label, value)
        if value and value ~= "" then
            return string.format("|cff00ccff%s:|r %s", label, value)
        else
            return string.format("|cff00ccff%s:|r |cff888888N/A|r", label)
        end
    end
    
    -- Build the document content
    local content = {}
    
    -- Case Header Information
    table.insert(content, "|cffFFD700=== CASE INFORMATION ===|r")
    table.insert(content, CreateDetailLine("Case ID", caseData.id))
    table.insert(content, CreateDetailLine("Created By", caseData.createdBy))
    table.insert(content, CreateDetailLine("Date Created", caseData.createdAt))
    table.insert(content, "")
    
    -- Basic Details
    table.insert(content, "|cffFFD700=== CASE DETAILS ===|r")
    table.insert(content, CreateDetailLine("Case Type/Category", caseData.caseType))
    table.insert(content, CreateDetailLine("Priority Level", caseData.priority))
    table.insert(content, CreateDetailLine("Status", caseData.status))
    table.insert(content, CreateDetailLine("Location/Scene", caseData.location))
    table.insert(content, CreateDetailLine("Assigned Detective", caseData.assignedTo))
    table.insert(content, CreateDetailLine("Client/Requester", caseData.client))
    table.insert(content, CreateDetailLine("Date of Incident", caseData.incidentDate))
    table.insert(content, CreateDetailLine("Related Cases", caseData.relatedCases))
    table.insert(content, "")
    
    -- Description
    if caseData.description and caseData.description ~= "" then
        table.insert(content, "|cffFFD700=== CASE DESCRIPTION ===|r")
        table.insert(content, caseData.description)
        table.insert(content, "")
    end
    
    -- Suspects
    if caseData.suspects and caseData.suspects ~= "" then
        table.insert(content, "|cffFFD700=== SUSPECTS ===|r")
        table.insert(content, caseData.suspects)
        table.insert(content, "")
    end
    
    -- Leads
    if caseData.leads and caseData.leads ~= "" then
        table.insert(content, "|cffFFD700=== LEADS ===|r")
        table.insert(content, caseData.leads)
        table.insert(content, "")
    end
    
    -- Witnesses
    if caseData.witnesses and caseData.witnesses ~= "" then
        table.insert(content, "|cffFFD700=== WITNESSES ===|r")
        table.insert(content, caseData.witnesses)
        table.insert(content, "")
    end
    
    -- Evidence
    if caseData.evidenceChain and caseData.evidenceChain ~= "" then
        table.insert(content, "|cffFFD700=== EVIDENCE CHAIN OF CUSTODY ===|r")
        table.insert(content, caseData.evidenceChain)
        table.insert(content, "")
    end
    
    -- Interview Notes
    if caseData.interviewNotes and caseData.interviewNotes ~= "" then
        table.insert(content, "|cffFFD700=== INTERVIEW NOTES ===|r")
        table.insert(content, caseData.interviewNotes)
        table.insert(content, "")
    end
    
    -- Case Notes
    if caseData.caseNotes and caseData.caseNotes ~= "" then
        table.insert(content, "|cffFFD700=== CASE NOTES/UPDATES ===|r")
        table.insert(content, caseData.caseNotes)
        table.insert(content, "")
    end
    
    -- Next Steps
    if caseData.nextSteps and caseData.nextSteps ~= "" then
        table.insert(content, "|cffFFD700=== NEXT STEPS/ACTION ITEMS ===|r")
        table.insert(content, caseData.nextSteps)
    end
    
    -- Set the document content
    casesTab.docContent:SetText(table.concat(content, "\n"))
    
    -- Adjust scroll height
    casesTab.docScrollChild:SetHeight(casesTab.docContent:GetStringHeight() + 40)
end

-- Save case from tab form
function GCM.SaveTabCase(casesTab)
    if not casesTab then return end
    
    local caseData = {
        id = casesTab.editingCaseID,
        title = casesTab.titleInput:GetText(),
        description = casesTab.descriptionInput:GetText(),
        caseType = casesTab.caseTypeInput:GetText(),
        priority = casesTab.priorityInput:GetText(),
        status = casesTab.statusInput:GetText(),
        location = casesTab.locationInput:GetText(),
        assignedTo = casesTab.assignedToInput:GetText(),
        client = casesTab.clientInput:GetText(),
        incidentDate = casesTab.incidentDateInput:GetText(),
        relatedCases = casesTab.relatedCasesInput:GetText(),
        suspects = casesTab.suspectsInput:GetText(),
        leads = casesTab.leadsInput:GetText(),
        witnesses = casesTab.witnessesInput:GetText(),
        evidenceChain = casesTab.evidenceChainInput:GetText(),
        interviewNotes = casesTab.interviewNotesInput:GetText(),
        caseNotes = casesTab.caseNotesInput:GetText(),
        nextSteps = casesTab.nextStepsInput:GetText()
    }
    
    -- Add creation metadata if this is a new case
    if not casesTab.editingCaseID then
        caseData.createdBy = UnitName("player")
        caseData.createdAt = date("%Y-%m-%d %H:%M:%S")
    end
    
    GCM.SaveCase(caseData)
    
    -- Return to list view
    casesTab.formView:Hide()
    casesTab.listView:Show()
    GCM.RefreshCasesTab()
end

-- Create case form within tab
function GCM.CreateTabCaseForm(casesTab)
    if not casesTab or not casesTab.formView then return end
    
    local formView = casesTab.formView
    
    -- Scroll Frame for form
    local scrollFrame = CreateFrame("ScrollFrame", nil, formView, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 10, -50)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 20)
    
    local scrollChild = CreateFrame("Frame")
    scrollChild:SetSize(scrollFrame:GetWidth(), 1400) -- Increased height
    scrollFrame:SetScrollChild(scrollChild)
    
    local yOffset = -15
    
    -- Helper to create input field with proper spacing
    local function CreateInputField(label, width, height, isMultiLine)
        local labelStr = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        labelStr:SetPoint("TOPLEFT", 10, yOffset)
        labelStr:SetText(label)
        yOffset = yOffset - 18 -- Consistent label spacing
        
        local editBox = CreateFrame("EditBox", nil, scrollChild, "InputBoxTemplate")
        editBox:SetSize(width, height)
        editBox:SetPoint("TOPLEFT", 10, yOffset)
        editBox:SetAutoFocus(false)
        editBox:SetFontObject("GameFontHighlight")
        if isMultiLine then
            editBox:SetMultiLine(true)
        end
        yOffset = yOffset - height - 15 -- Consistent field spacing
        return editBox
    end
    
    -- Create all form fields with consistent spacing
    casesTab.titleInput = CreateInputField("Case Title:", 520, 24)
    casesTab.descriptionInput = CreateInputField("Description:", 520, 120, true)
    casesTab.caseTypeInput = CreateInputField("Case Type/Category:", 250, 24)
    casesTab.priorityInput = CreateInputField("Priority Level:", 250, 24)
    casesTab.statusInput = CreateInputField("Case Status:", 250, 24)
    casesTab.locationInput = CreateInputField("Location/Scene:", 520, 24)
    casesTab.assignedToInput = CreateInputField("Assigned Detective:", 250, 24)
    casesTab.clientInput = CreateInputField("Client/Requester:", 250, 24)
    casesTab.incidentDateInput = CreateInputField("Date of Incident:", 250, 24)
    casesTab.relatedCasesInput = CreateInputField("Related Cases:", 520, 24)
    casesTab.suspectsInput = CreateInputField("Suspects:", 520, 60, true)
    casesTab.leadsInput = CreateInputField("Leads:", 520, 60, true)
    casesTab.witnessesInput = CreateInputField("Witnesses:", 520, 60, true)
    casesTab.evidenceChainInput = CreateInputField("Evidence Chain of Custody:", 520, 80, true)
    casesTab.interviewNotesInput = CreateInputField("Interview Notes:", 520, 120, true)
    casesTab.caseNotesInput = CreateInputField("Case Notes/Updates:", 520, 100, true)
    casesTab.nextStepsInput = CreateInputField("Next Steps/Action Items:", 520, 100, true)
end

-- ==================== TAB PERSON MANAGEMENT FUNCTIONS ====================

-- Show person edit form within tab
function GCM.ShowTabPersonEdit(peopleTab, personData)
    if not peopleTab or not peopleTab.formView then return end
    
    peopleTab.listView:Hide()
    peopleTab.formView:Show()
    
    -- Set form title
    if personData then
        peopleTab.formTitle:SetText("|cff00ccffEdit Person|r")
        peopleTab.editingPersonID = personData.id
        peopleTab.saveBtn:Show()
    else
        peopleTab.formTitle:SetText("|cff00ccffNew Person|r")
        peopleTab.editingPersonID = nil
        peopleTab.saveBtn:Show()
    end
    
    -- Populate fields
    local person = personData or {}
    peopleTab.nameInput:SetText(person.name or "")
    peopleTab.raceInput:SetText(person.race or "")
    peopleTab.genderInput:SetText(person.gender or "")
    peopleTab.ageInput:SetText(person.age or "")
    peopleTab.occupationInput:SetText(person.occupation or "")
    peopleTab.aliasesInput:SetText(person.aliases or "")
    peopleTab.addressInput:SetText(person.address or "")
    peopleTab.contactInput:SetText(person.contact or "")
    peopleTab.relationshipStatusInput:SetText(person.relationshipStatus or "")
    peopleTab.threatLevelInput:SetText(person.threatLevel or "")
    peopleTab.vehicleInput:SetText(person.vehicle or "")
    peopleTab.lastSeenLocationInput:SetText(person.lastSeenLocation or "")
    peopleTab.lastSeenDateInput:SetText(person.lastSeenDate or "")
    peopleTab.photoUrlInput:SetText(person.photoUrl or "")
    peopleTab.physicalDescInput:SetText(person.physicalDesc or "")
    peopleTab.distinguishingMarksInput:SetText(person.distinguishingMarks or "")
    peopleTab.criminalHistoryInput:SetText(person.criminalHistory or "")
    peopleTab.behavioralNotesInput:SetText(person.behavioralNotes or "")
    peopleTab.associatesInput:SetText(person.associates or "")
    peopleTab.evidenceConnectedInput:SetText(person.evidenceConnected or "")
    peopleTab.notesInput:SetText(person.notes or "")
end

-- Show person view form within tab (read-only document style)
function GCM.ShowTabPersonView(peopleTab, personData)
    if not peopleTab or not peopleTab.documentView then return end
    
    peopleTab.listView:Hide()
    peopleTab.formView:Hide()  -- Hide the edit form
    peopleTab.documentView:Show()  -- Show the document view
    
    -- Set document title
    peopleTab.docTitle:SetText(string.format("|cff00ccff%s|r", personData.name or "Unknown Person"))
    
    -- Helper function to create formatted lines
    local function CreateDetailLine(label, value)
        if value and value ~= "" then
            return string.format("|cff00ccff%s:|r %s", label, value)
        else
            return string.format("|cff00ccff%s:|r |cff888888N/A|r", label)
        end
    end
    
    -- Build the document content
    local content = {}
    
    -- Person Header Information
    table.insert(content, "|cffFFD700=== PERSON PROFILE ===|r")
    table.insert(content, CreateDetailLine("Full Name", personData.name))
    table.insert(content, CreateDetailLine("Last Updated", personData.updated))
    table.insert(content, "")
    
    -- Basic Information
    table.insert(content, "|cffFFD700=== BASIC INFORMATION ===|r")
    table.insert(content, CreateDetailLine("Race", personData.race))
    table.insert(content, CreateDetailLine("Gender", personData.gender))
    table.insert(content, CreateDetailLine("Age", personData.age))
    table.insert(content, CreateDetailLine("Occupation", personData.occupation))
    table.insert(content, CreateDetailLine("Relationship Status", personData.relationshipStatus))
    table.insert(content, "")
    
    -- Contact & Location
    table.insert(content, "|cffFFD700=== CONTACT & LOCATION ===|r")
    table.insert(content, CreateDetailLine("Aliases/Known Names", personData.aliases))
    table.insert(content, CreateDetailLine("Last Known Address", personData.address))
    table.insert(content, CreateDetailLine("Contact Information", personData.contact))
    table.insert(content, CreateDetailLine("Last Seen Location", personData.lastSeenLocation))
    table.insert(content, CreateDetailLine("Last Seen Date", personData.lastSeenDate))
    table.insert(content, "")
    
    -- Security Information
    table.insert(content, "|cffFFD700=== SECURITY ASSESSMENT ===|r")
    table.insert(content, CreateDetailLine("Threat Level", personData.threatLevel))
    table.insert(content, CreateDetailLine("Vehicle Information", personData.vehicle))
    table.insert(content, CreateDetailLine("Photo/Mugshot URL", personData.photoUrl))
    table.insert(content, "")
    
    -- Physical Description
    if personData.physicalDesc and personData.physicalDesc ~= "" then
        table.insert(content, "|cffFFD700=== PHYSICAL DESCRIPTION ===|r")
        table.insert(content, personData.physicalDesc)
        table.insert(content, "")
    end
    
    -- Distinguishing Marks
    if personData.distinguishingMarks and personData.distinguishingMarks ~= "" then
        table.insert(content, "|cffFFD700=== DISTINGUISHING MARKS/TATTOOS/SCARS ===|r")
        table.insert(content, personData.distinguishingMarks)
        table.insert(content, "")
    end
    
    -- Criminal History
    if personData.criminalHistory and personData.criminalHistory ~= "" then
        table.insert(content, "|cffFFD700=== CRIMINAL HISTORY ===|r")
        table.insert(content, personData.criminalHistory)
        table.insert(content, "")
    end
    
    -- Behavioral Notes
    if personData.behavioralNotes and personData.behavioralNotes ~= "" then
        table.insert(content, "|cffFFD700=== BEHAVIORAL NOTES ===|r")
        table.insert(content, personData.behavioralNotes)
        table.insert(content, "")
    end
    
    -- Associates
    if personData.associates and personData.associates ~= "" then
        table.insert(content, "|cffFFD700=== KNOWN ASSOCIATES ===|r")
        table.insert(content, personData.associates)
        table.insert(content, "")
    end
    
    -- Evidence Connected
    if personData.evidenceConnected and personData.evidenceConnected ~= "" then
        table.insert(content, "|cffFFD700=== EVIDENCE CONNECTED TO ===|r")
        table.insert(content, personData.evidenceConnected)
        table.insert(content, "")
    end
    
    -- Additional Notes
    if personData.notes and personData.notes ~= "" then
        table.insert(content, "|cffFFD700=== ADDITIONAL NOTES ===|r")
        table.insert(content, personData.notes)
    end
    
    -- Set the document content
    peopleTab.docContent:SetText(table.concat(content, "\n"))
    
    -- Adjust scroll height
    peopleTab.docScrollChild:SetHeight(peopleTab.docContent:GetStringHeight() + 40)
end

-- Save person from tab form
function GCM.SaveTabPerson(peopleTab)
    if not peopleTab then return end
    
    local personData = {
        id = peopleTab.editingPersonID,
        name = peopleTab.nameInput:GetText(),
        race = peopleTab.raceInput:GetText(),
        gender = peopleTab.genderInput:GetText(),
        age = peopleTab.ageInput:GetText(),
        occupation = peopleTab.occupationInput:GetText(),
        aliases = peopleTab.aliasesInput:GetText(),
        address = peopleTab.addressInput:GetText(),
        contact = peopleTab.contactInput:GetText(),
        relationshipStatus = peopleTab.relationshipStatusInput:GetText(),
        threatLevel = peopleTab.threatLevelInput:GetText(),
        vehicle = peopleTab.vehicleInput:GetText(),
        lastSeenLocation = peopleTab.lastSeenLocationInput:GetText(),
        lastSeenDate = peopleTab.lastSeenDateInput:GetText(),
        photoUrl = peopleTab.photoUrlInput:GetText(),
        physicalDesc = peopleTab.physicalDescInput:GetText(),
        distinguishingMarks = peopleTab.distinguishingMarksInput:GetText(),
        criminalHistory = peopleTab.criminalHistoryInput:GetText(),
        behavioralNotes = peopleTab.behavioralNotesInput:GetText(),
        associates = peopleTab.associatesInput:GetText(),
        evidenceConnected = peopleTab.evidenceConnectedInput:GetText(),
        notes = peopleTab.notesInput:GetText(),
        updated = date("%Y-%m-%d %H:%M:%S")
    }
    
    GCM.SavePerson(personData)
    
    -- Return to list view
    peopleTab.formView:Hide()
    peopleTab.listView:Show()
    GCM.RefreshPeopleTab()
end

-- Create person form within tab
function GCM.CreateTabPersonForm(peopleTab)
    if not peopleTab or not peopleTab.formView then return end
    
    local formView = peopleTab.formView
    
    -- Scroll Frame for form
    local scrollFrame = CreateFrame("ScrollFrame", nil, formView, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 10, -50)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 20)
    
    local scrollChild = CreateFrame("Frame")
    scrollChild:SetSize(scrollFrame:GetWidth(), 1800) -- Increased height
    scrollFrame:SetScrollChild(scrollChild)
    
    local yOffset = -15
    
    -- Helper to create input field with proper spacing
    local function CreateInputField(label, width, height, isMultiLine)
        local labelStr = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        labelStr:SetPoint("TOPLEFT", 10, yOffset)
        labelStr:SetText(label)
        yOffset = yOffset - 18 -- Consistent label spacing
        
        local editBox = CreateFrame("EditBox", nil, scrollChild, "InputBoxTemplate")
        editBox:SetSize(width, height)
        editBox:SetPoint("TOPLEFT", 10, yOffset)
        editBox:SetAutoFocus(false)
        editBox:SetFontObject("GameFontHighlight")
        if isMultiLine then
            editBox:SetMultiLine(true)
        end
        yOffset = yOffset - height - 15 -- Consistent field spacing
        return editBox
    end
    
    -- Create all form fields with consistent spacing
    peopleTab.nameInput = CreateInputField("Name:", 250, 24)
    peopleTab.raceInput = CreateInputField("Race:", 250, 24)
    peopleTab.genderInput = CreateInputField("Gender:", 250, 24)
    peopleTab.ageInput = CreateInputField("Age:", 250, 24)
    peopleTab.occupationInput = CreateInputField("Occupation:", 250, 24)
    peopleTab.aliasesInput = CreateInputField("Aliases/Known Names:", 520, 24)
    peopleTab.addressInput = CreateInputField("Last Known Address:", 520, 24)
    peopleTab.contactInput = CreateInputField("Phone/Contact Information:", 520, 24)
    peopleTab.relationshipStatusInput = CreateInputField("Relationship Status:", 250, 24)
    peopleTab.threatLevelInput = CreateInputField("Threat Level:", 250, 24)
    peopleTab.vehicleInput = CreateInputField("Vehicle Information:", 520, 24)
    peopleTab.lastSeenLocationInput = CreateInputField("Last Seen Location:", 250, 24)
    peopleTab.lastSeenDateInput = CreateInputField("Last Seen Date:", 250, 24)
    peopleTab.photoUrlInput = CreateInputField("Photo/Mugshot URL:", 520, 24)
    peopleTab.physicalDescInput = CreateInputField("Physical Description:", 520, 80, true)
    peopleTab.distinguishingMarksInput = CreateInputField("Distinguishing Marks/Tattoos/Scars:", 520, 60, true)
    peopleTab.criminalHistoryInput = CreateInputField("Criminal History:", 520, 80, true)
    peopleTab.behavioralNotesInput = CreateInputField("Behavioral Notes:", 520, 80, true)
    peopleTab.associatesInput = CreateInputField("Known Associates:", 520, 60, true)
    peopleTab.evidenceConnectedInput = CreateInputField("Evidence Connected To:", 520, 60, true)
    peopleTab.notesInput = CreateInputField("Additional Notes:", 520, 80, true)
end

-- Note: GUI is initialized on-demand from Core.lua when needed
-- This prevents duplicate initialization

-- Welcome Screen
function GCM.ShowWelcomeScreen()
    if GCM.WelcomeFrame and GCM.WelcomeFrame:IsShown() then return end

    -- Create the welcome frame
    if not GCM.WelcomeFrame then
        GCM.WelcomeFrame = CreateFrame("Frame", "GCM_WelcomeFrame", UIParent, "BasicFrameTemplate")
        GCM.WelcomeFrame:SetSize(500, 400)
        GCM.WelcomeFrame:SetPoint("CENTER")
        GCM.WelcomeFrame:SetFrameStrata("DIALOG")
        GCM.WelcomeFrame:SetMovable(true)
        GCM.WelcomeFrame:EnableMouse(true)
        GCM.WelcomeFrame:RegisterForDrag("LeftButton")
        GCM.WelcomeFrame:SetScript("OnDragStart", GCM.WelcomeFrame.StartMoving)
        GCM.WelcomeFrame:SetScript("OnDragStop", GCM.WelcomeFrame.StopMovingOrSizing)

        -- Logo
        local logo = GCM.WelcomeFrame:CreateTexture(nil, "ARTWORK")
        logo:SetSize(200, 130)
        logo:SetPoint("TOP", 0, -40)
        logo:SetTexture("Interface\\AddOns\\GuildCaseManager\\media\\acdb_logo.tga")
        
        -- Title
        local title = GCM.WelcomeFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOP", 0, -180)
        title:SetText("Welcome to Guild Case Manager!")

        -- Content
        local content = GCM.WelcomeFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        content:SetPoint("TOPLEFT", 20, -210)
        content:SetPoint("BOTTOMRIGHT", -20, 80)
        content:SetJustifyH("LEFT")
        content:SetJustifyV("TOP")
        content:SetText("Thank you for using Guild Case Manager developed by @LordChristoff, here are some key features:\n\n"
            .. "|cff00ccff- Cases:|r Manage guild investigations and track progress.\n"
            .. "|cff00ccff- People:|r Keep profiles on characters of interest.\n"
            .. "|cff00ccff- Map:|r Mark important locations on a custom map.\n"
            .. "|cff00ccff- Sync:|r Data syncs automatically with other guild members.\n\n"
            .. "You can access the addon by typing |cff00ff00/acdb|r in chat.\n"
            .. "You can access this message by typing |cff00ff00/acdbw|r in chat.")

        -- Close button
        local closeBtn = CreateFrame("Button", nil, GCM.WelcomeFrame, "UIPanelButtonTemplate")
        closeBtn:SetSize(120, 30)
        closeBtn:SetPoint("BOTTOM", 0, 20)
        closeBtn:SetText("There's a game afoot!")
        closeBtn:SetScript("OnClick", function()
            GCM.WelcomeFrame:Hide()
            GCM_Database.settings.welcomeShown = true
            print("|cff00ccffGCM:|r You can show the welcome screen again with /acdbw.")
        end)
    end

    GCM.WelcomeFrame:Show()
end
