---@diagnostic disable: undefined-field, lowercase-global
local MenuLib = {
    version = "1.2",
    author = "Starz, edited by Casey",
    description = "A customizable draggable menu library for perception.cx api"
}

-- Define key names for game controls
MenuLib.keyNames = {
    "None", "A", "B", "C", "D", "E", "F", "G", "H", "I",
    "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S",
    "T", "U", "V", "W", "X", "Y", "Z",
    "0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
    "Space", "Enter", "Shift", "Ctrl", "Alt", "Tab", "Caps", "Back", "Delete", "Insert",
    "Home", "Left", "Up", "Right", "Down",
    "Mouse1", "Mouse2", "Mouse3", "Mouse4", "Mouse5"
}

-- Define key codes that correspond to the key names
MenuLib.keyCodes = {
    0x00, -- none
    0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49, -- A-I
    0x4A, 0x4B, 0x4C, 0x4D, 0x4E, 0x4F, 0x50, 0x51, 0x52, 0x53, -- J-S
    0x54, 0x55, 0x56, 0x57, 0x58, 0x59, 0x5A, -- T-Z
    0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, -- 0-9
    0x20, -- Space
    0x0D, -- Enter
    0x10, -- Shift
    0x11, -- Ctrl
    0x12, -- Alt
    0x09, -- Tab
    0x14, -- CapsLock
    0x08, -- Backspace
    0x2E, -- Delete
    0x2D, -- Insert
    0x24, -- Home
    0x25, -- Left Arrow
    0x26, -- Up Arrow
    0x27, -- Right Arrow
    0x28, -- Down Arrow
    0x01, -- Mouse1 (Left click)
    0x02, -- Mouse2 (Right click)
    0x04, -- Mouse3 (Middle click / Mousewheel click)
    0x05, -- Side1 (Mouse4, XButton1)
    0x06  -- Side2 (Mouse5, XButton2)
}

-- Initialize default configuration with enhanced draggable support
function MenuLib.initialize(configOverrides)
    -- Get screen dimensions for rendering
    local screen_size_x, screen_size_y = render.get_viewport_size()

    -- Default configuration with draggable enhancements
    local defaultConfig = {
        menu = {
            x = screen_size_x / 2 - 100,
            y = screen_size_y / 2 - 100,
            isVisible = false,
            width = 300,
            height = 400,
            title = "MenuLib",
            font = "verdana.ttf",
            snapDistance = 20,       -- Distance for snapping to edges
            snapToEdges = true, -- Enable edge snapping
            configNames = {"menu_config1.txt","menu_config1.txt","menu_config1.txt"},
            color = {60, 150, 255, 255},
        },
        tabs = {},
        options = {}
    }

    -- Merge with overrides if provided
    MenuLib.config = MenuLib.merge_tables(defaultConfig, configOverrides or {})
    
    -- Initialize key integers
    MenuLib.keyInts = {}
    for i = 0, #MenuLib.keyNames do
        MenuLib.keyInts[i] = i
    end

    MenuLib.draggable = MenuLib.create_draggable("main_menu", MenuLib.config.menu.x, MenuLib.config.menu.y)

    -- Load saved config if exists
    -- MenuLib.load_config(MenuLib.config.menu.configNames[1])    
    
    return MenuLib.config
end

-- Helper function to deep merge tables
function MenuLib.merge_tables(t1, t2)
    for k, v in pairs(t2) do
        if type(v) == "table" then
            if type(t1[k] or false) == "table" then
                MenuLib.merge_tables(t1[k] or {}, t2[k] or {})
            else
                t1[k] = v
            end
        else
            t1[k] = v
        end
    end
    return t1
end

--MOUSE AND DRAGGING FUNCS
function MenuLib.get_mouse()
    local curPosx, curPosy = input.get_mouse_position()
    return { x = curPosx, y = curPosy }
end

function MenuLib.inbox(minx, maxx, miny, maxy)
    local mouse = MenuLib.get_mouse()
    return mouse.x > minx and mouse.x < maxx and mouse.y > miny and mouse.y < maxy
end

--------- MENU FUNCTIONS ---------
function MenuLib.create_draggable(name, initial_x, initial_y)
    local obj = {
        name = name,
        x = initial_x or 0,
        y = initial_y or 0,
        is_dragging = false,
        drag_offset_x = 0,
        drag_offset_y = 0
    }

    function obj:get()
        return self.x, self.y
    end

    function obj:set(nx, ny)
        self.x = nx
        self.y = ny
    end

    function obj:drag(width, height)
        local mouse_x, mouse_y = input.get_mouse_position()
        local viewport_width, viewport_height = render.get_viewport_size()
        
        -- Check if mouse is over the draggable area (title bar)
        local is_hovered = mouse_x >= self.x and mouse_x <= self.x + width and
                           mouse_y >= self.y and mouse_y <= self.y + 30  -- Only top 30px for dragging
        
        -- Start dragging
        if not self.is_dragging and is_hovered and input.is_key_pressed(0x01) then
            self.is_dragging = true
            self.drag_offset_x = mouse_x - self.x
            self.drag_offset_y = mouse_y - self.y
        end
        
        -- Stop dragging
        if self.is_dragging and not input.is_key_down(0x01) then
            self.is_dragging = false
        end
        
        -- Handle dragging
        if self.is_dragging then
            self.x = mouse_x - self.drag_offset_x
            self.y = mouse_y - self.drag_offset_y
            
            -- Apply edge snapping if enabled
            if MenuLib.config.menu.snapToEdges then
                -- Left edge
                if math.abs(self.x) < MenuLib.config.menu.snapDistance then
                    self.x = 0
                end
                -- Right edge
                if math.abs(self.x + width - viewport_width) < MenuLib.config.menu.snapDistance then
                    self.x = viewport_width - width
                end
                -- Top edge
                if math.abs(self.y) < MenuLib.config.menu.snapDistance then
                    self.y = 0
                end
                -- Bottom edge
                if math.abs(self.y + (height + 137) - viewport_height) < MenuLib.config.menu.snapDistance then
                    self.y = viewport_height - (height + 137)
                end
            end
            
            -- Ensure menu stays within bounds
            self.x = math.max(0, math.min(viewport_width - width, self.x))
            self.y = math.max(0, math.min(viewport_height - (height + 137), self.y))
        end
        
        return self.x, self.y, self.is_dragging and "c" or (is_hovered and "o" or "n")
    end

    return obj
end

function MenuLib.draw_gradient_rect(x, y, width, height, r1, g1, b1, a1, r2, g2, b2, a2)
    for i = 0, height - 1 do
        local t = i / height
        local r = r1 * (1 - t) + r2 * t
        local g = g1 * (1 - t) + g2 * t
        local b = b1 * (1 - t) + b2 * t
        local a = a1 * (1 - t) + a2 * t
        render.draw_rectangle(x, y + i, width, 1, r, g, b, a, 0, true)
    end
end

function MenuLib.draw_triangle_gradient(x1, y1, x2, y2, x3, y3, r1,b1,g1,a1, r2,b2,g2,a2, steps)
    local gradient_start = -0.02
    for i = 0, steps do
        local t = i / steps
        -- Make sure gradient only happens towards the top
        local gradient_factor = math.max(0, (t + gradient_start) * (1 + gradient_start))
        
        -- Interpolate colors
        local r = math.floor(r1* (1 - gradient_factor) + r2 * t)
        local g = math.floor(b1* (1 - gradient_factor) + b2 * t)
        local b = math.floor(g1* (1 - gradient_factor) + g2 * t)
        local a = math.floor(a1* (1 - gradient_factor) + a2 * t)
        
        -- Offset the middle point to create layers
        local mx = x1 * (1 - t) + x2 * t
        local my = y1 * (1 - t) + y2 * t
        
        render.draw_triangle(mx, my, x2, y2, x3, y3, r, g, b, a, 0, true)
    end
end

function MenuLib.create_tab(title, x, y, width, height, tab_key, Disabled)
    local is_selected = MenuLib.config.tabs[tab_key] and MenuLib.config.tabs[tab_key][1] or false

    local disabled = Disabled or false

    if is_selected then
        render.draw_rectangle(x, y, width, height, 15, 15, 15, 255, 0, true, 5)
        local text_width = render.measure_text(render.create_font(MenuLib.config.menu.font, 13), title)
        render.draw_text(render.create_font(MenuLib.config.menu.font, 13), title, x + (width / 2) - (text_width / 2), y + (height / 2) - 8, 232, 232, 232, 255, 0, 0, 0, 0, 0)

        render.draw_line(x, (y + height) + 5, x + width, (y + height) + 5, MenuLib.config.menu.color[1], MenuLib.config.menu.color[2], MenuLib.config.menu.color[3], 255, 1)
        render.draw_line(x, (y + height) + 4, x + width, (y + height) + 4, MenuLib.config.menu.color[1], MenuLib.config.menu.color[2], MenuLib.config.menu.color[3], 170, 1)
        render.draw_line(x, (y + height) + 3, x + width, (y + height) + 3, MenuLib.config.menu.color[1], MenuLib.config.menu.color[2], MenuLib.config.menu.color[3], 85, 1)

    else
        render.draw_rectangle(x, y, width, height, 10, 10, 10, 255, 0, true, 5)
        local text_width = render.measure_text(render.create_font(MenuLib.config.menu.font, 13), title)
        render.draw_text(render.create_font(MenuLib.config.menu.font, 13), title, x + (width / 2) - (text_width / 2), y + (height / 2) - 8, 66, 66, 66, 255, 0, 0, 0, 0, 0)

        if disabled then
            render.draw_line(x + (width / 2) - (text_width / 2) - 1, y + (height / 2) , x + (width / 2) - (text_width / 2) + text_width + 1, y + (height / 2) , 66, 66, 66, 255, 1)
        end

    end



    if MenuLib.inbox(x, x + width, y, y + height) and input.is_key_pressed(0x01) and not disabled then
        for key, _ in pairs(MenuLib.config.tabs) do
            if key:find("_tab") then
                MenuLib.config.tabs[key][1] = false
            end
        end
        MenuLib.config.tabs[tab_key][1] = true
    end
end

function MenuLib.create_group(title, x, y, width, height)
    render.draw_rectangle(x, y, width, height, 100, 100, 100, 255, 0, false)
    render.draw_text(render.create_font(MenuLib.config.menu.font, 13), title, x + 5, y - 15, 255, 255, 255, 255, 0, 0, 0, 0, 0)
end

function MenuLib.create_optionSelect(title, x, y, item)
    local selected = MenuLib.config.options[item][1]
    local options = MenuLib.config.options[item][2]

    -- Dropdown state
    MenuLib.dropdown_states = MenuLib.dropdown_states or {}
    MenuLib.dropdown_states[item] = MenuLib.dropdown_states[item] or { open = false }

    local is_open = MenuLib.dropdown_states[item].open
    local font = render.create_font(MenuLib.config.menu.font, 13)

    x = x - 2.5 

    if is_open or MenuLib.inbox(x, x + 168, (y + 17), (y + 17) + 20) then
        render.draw_text(font, title, x, y, 232, 232, 232, 255, 0, 0, 0, 0, 0)
    else
        render.draw_text(font, title, x, y, 66, 66, 66, 255, 0, 0, 0, 0, 0)
    end


    y = y + 17

    -- Draw main box
    render.draw_rectangle(x + 0.5, y - 0.5, 169, 20 + 2, 45, 45, 45, 255, 0, true)
    render.draw_rectangle(x + 1.0, y + 0.5, 167.5, 20, 18, 18, 18, 255, 0, true)

    if is_open or MenuLib.inbox(x, x + 168, y, y + 20) then
        render.draw_text(font, options[selected], x + 5, y + 3, 232, 232, 232, 255, 0, 0, 0, 0, 0)
    else
        render.draw_text(font, options[selected], x + 5, y + 3, 66, 66, 66, 255, 0, 0, 0, 0, 0)
    end

    -- Draw dropdown arrow
    if is_open then
        render.draw_text(font, "<", x + 155, y + 3, 66, 66, 66, 255, 0, 0, 0, 0, 0)
    else
        render.draw_text(font, "v", x + 155, y + 3, 66, 66, 66, 255, 0, 0, 0, 0, 0)
    end


    -- Handle open/close dropdown
    if MenuLib.inbox(x, x + 168, y, y + 20) and input.is_key_pressed(0x01) then
        MenuLib.dropdown_states[item].open = not is_open
    end

    if input.is_key_pressed(0x01) and not MenuLib.inbox(x, x + 168, y, y + 20) then
        MenuLib.dropdown_states[item].open = false
    end

    -- If dropdown open, draw options
    if is_open then
        MenuLib.config.options[item][3] = true

        for i = 1, #options do
            local option_y = y + (19.5 * i)
            local is_hovering = MenuLib.inbox(x, x + 168, option_y, option_y + 19)

            -- Determine color based on state
            local r, g, b, a = 66, 66, 66, 255 -- default
            if i == selected then
                r, g, b, a = 232, 232, 232, 255 -- selected color
            end
            
            if is_hovering then
                r, g, b, a = 232, 232, 232, 255  -- hover color
            end

            render.draw_rectangle(x + 1, option_y, 167.5, 20, 18, 18, 18, a, 0, true)
            render.draw_text(font, options[i], x + 5, option_y + 3, r, g, b, a, 0, 0, 0, 0, 0)

            if is_hovering and input.is_key_pressed(0x01) then
                MenuLib.config.options[item][1] = i
                MenuLib.dropdown_states[item].open = false
            end
        end
    else
        MenuLib.config.options[item][3] = false
    end
end

function MenuLib.create_multiOption(title, x, y, item, r, g, b, a)
    local font = render.create_font(MenuLib.config.menu.font, 13)
    local options = MenuLib.config.options[item][2]
    local toggled = MenuLib.config.options[item][3] or {}

    -- Dropdown state (open or closed)
    MenuLib.dropdown_states = MenuLib.dropdown_states or {}
    MenuLib.dropdown_states[item] = MenuLib.dropdown_states[item] or { open = false }
    local menu_open = MenuLib.dropdown_states[item].open

    x = x - 2.5

    -- Title
    if menu_open or MenuLib.inbox(x, x + 168, y + 20, y + 40) then
        render.draw_text(font, title, x, y, 232, 232, 232, 255, 0, 0, 0, 0, 0)
    else
        render.draw_text(font, title, x, y, 66, 66, 66, 255, 0, 0, 0, 0, 0)
    end

    y = y + 17

    -- Selection box
    local box_w, box_h = 165, 20
    render.draw_rectangle(x + 0.5, y - 0.5, 169, 20 + 2, 45, 45, 45, 255, 0, true)
    render.draw_rectangle(x + 1.0, y + 0.5, 167.5, 20, 18, 18, 18, 255, 0, true)

    if menu_open then
        render.draw_text(font, "<", x + 155, y + 3, 66, 66, 66, 255, 0, 0, 0, 0, 0)
    else
        render.draw_text(font, "v", x + 155, y + 3, 66, 66, 66, 255, 0, 0, 0, 0, 0)
    end

    -- Create a list of selected options
    local selected_options = {}
    for i = 1, #options do
        if toggled[i] then
            table.insert(selected_options, options[i])
        end
    end

    -- Show selected options or default text
    local display_text = #selected_options > 0 and table.concat(selected_options, ", ") or "-"
    if #selected_options > 3 then
        display_text = table.concat(selected_options, ", ", 1, 3) .. "..."
    end

    if menu_open or MenuLib.inbox(x, x + 168, y, y + 20) then
        render.draw_text(font, display_text, x + 5, y + 3, 232, 232, 232, 255, 0, 0, 0, 0, 0)
    else
        render.draw_text(font, display_text, x + 5, y + 3, 66, 66, 66, 255, 0, 0, 0, 0, 0)
    end


    -- Handle opening/closing dropdown
    if MenuLib.inbox(x, x + 168, y, y + 20) and input.is_key_pressed(0x01) then
        MenuLib.dropdown_states[item].open = not menu_open
    end

    local o_amount = #options * 20

    if input.is_key_pressed(0x01) and not MenuLib.inbox(x, x + 168, y, y + 20 + o_amount) then
        MenuLib.dropdown_states[item].open = false
    end

    y = y + 20

    -- If open, draw options
    if menu_open then
        MenuLib.config.options[item][4] = true

        for i = 1, #options do
            local option_text = options[i]
            local is_selected = toggled[i]
            local hovered = MenuLib.inbox(x, x + 168, y, y + 20)

            -- Option background
            render.draw_rectangle(x + 1, y, 167.5, 22.5, 18, 18, 18, 255, 0, true)


            -- Hover effect
            if MenuLib.inbox(x + 1, x + 167.5, y, y + 22.5) then
                if input.is_key_pressed(0x01) then
                    toggled[i] = not is_selected
                    MenuLib.config.options[item][3] = toggled
                end
            end

            -- Text
            local text_color = (is_selected or hovered) and {232, 232, 232, 255} or {66, 66, 66, 255}
            render.draw_text(font, option_text, x + 5, y + 3, text_color[1], text_color[2], text_color[3], text_color[4], 0, 0, 0, 0, 0)

            y = y + 22
        end
    else
        MenuLib.config.options[item][4] = false
    end
end


function MenuLib.create_slider(title, x, y, min, max, item,r,g,b,a,unit)
    x = x - 2.5
    local value = MenuLib.config.options[item][1]
    local bar_width = 164
    local normalized = (value - min) / (max - min)
    local slider_x = x + (normalized * bar_width + 3)


    --Slider background
    render.draw_rectangle(x + 0.5, y + 4, bar_width + 6 - 1, 6, 66, 66, 66, 255, 0, true, 2)
    render.draw_rectangle(x + 1 , y + 4 + 0.5, bar_width + 4, 5, 18, 18, 18, 255, 0, true, 2)

    --Slider bar
    render.draw_rectangle(x + 1, y + 4.5, slider_x - (x - 1), 5, MenuLib.config.menu.color[1], MenuLib.config.menu.color[2], MenuLib.config.menu.color[3], 225, 1, true, 2)

    --Slider Knob
    render.draw_circle(slider_x, y + 6.5, 5, 255, 255, 255, 255, 1, true)
    render.draw_circle(slider_x, y + 6.5, 2.5, 193, 193, 193, 255, 1, true)
   
    unit = unit or ""
    
    -- Dragging logic
    local mouse = {input.get_mouse_position()}
    local is_hovering = MenuLib.inbox(x, x + bar_width, y, y + 12)

    -- Draw slider value text
    if is_hovering or MenuLib.dragging_slider == item then
        render.draw_text(render.create_font(MenuLib.config.menu.font, 13), title, x, y - 12, 232, 232, 232, 255, 0, 0, 0, 0, 0)
        local valueT_x, valueT_y = render.measure_text(render.create_font(MenuLib.config.menu.font, 13), value..unit)
        render.draw_text(render.create_font(MenuLib.config.menu.font, 13), value..unit, x + bar_width + 5.5 - valueT_x, y - 12, 232, 232, 232, 255, 0, 0, 0, 0, 0)
    else
        render.draw_text(render.create_font(MenuLib.config.menu.font, 13), title, x, y - 12, 66, 66, 66, 255, 0, 0, 0, 0, 0)
        local valueT_x, valueT_y = render.measure_text(render.create_font(MenuLib.config.menu.font, 13), value..unit)
        render.draw_text(render.create_font(MenuLib.config.menu.font, 13), value..unit, x + bar_width + 5.5 - valueT_x, y - 12, 66, 66, 66, 255, 0, 0, 0, 0, 0)
    end

    if input.is_key_pressed(37) and is_hovering then
        MenuLib.config.options[item][1] = math.max(min, math.min(max, math.floor(value - 1)))
    end

    if input.is_key_pressed(39) and is_hovering then
        MenuLib.config.options[item][1] = math.max(min, math.min(max, math.floor(value + 1)))
    end

    if input.is_key_pressed(0x01) and is_hovering then
        MenuLib.dragging_slider = item  -- Track which slider is being dragged
    end

    if not input.is_key_down(0x01) then
        MenuLib.dragging_slider = nil  -- Stop dragging when mouse is released
    end

    if MenuLib.dragging_slider == item then
        local new_value = min + ((mouse[1] - x) / bar_width) * (max - min)
        MenuLib.config.options[item][1] = math.max(min, math.min(max, math.floor(new_value)))
    end
end

function MenuLib.create_keybind(title, x, y, item)
    local key = MenuLib.config.options[item][1]
    local is_binding = MenuLib.config.options[item][2]
    local display_text = "None"

    x = x + 47
    
    for i = 1, #MenuLib.keyCodes do
        if key == MenuLib.keyCodes[i] then
            display_text = MenuLib.keyNames[i]
            break
        end
    end

    if is_binding then
        display_text = "..."
    end
    
    local Tx, Ty = render.measure_text(render.create_font(MenuLib.config.menu.font, 13),  "["..display_text.."]")
    local title_width, title_height = render.measure_text(render.create_font(MenuLib.config.menu.font, 13), title)

    local isHovered = false
    if title == "None" then
        isHovered = MenuLib.inbox(x + 121 - (Tx), x + 121, y + 2, y + 16)
    else
        isHovered = (MenuLib.inbox(x + 121 - (Tx), x + 121, y + 2, y + 16) or MenuLib.inbox(x - 50, x - 50 + title_width, y, y + 16))
    end

    local color = isHovered and {232, 232, 232, 255} or {66, 66, 66, 255}

    if title ~= "None" then
        render.draw_text(render.create_font(MenuLib.config.menu.font, 13), title .. ":", x - 50, y, color[1], color[2], color[3], color[4], 0, 0, 0, 0, 0)
    end

    render.draw_text(render.create_font(MenuLib.config.menu.font, 13), "["..display_text.."]", x + 121 - (Tx), y, color[1], color[2], color[3], color[4], 0, 0, 0, 0, 0)

    
    if isHovered and input.is_key_pressed(0x01) then
        MenuLib.config.options[item][2] = true
    end
    
    if is_binding then
        for i = 1, #MenuLib.keyCodes do
            if input.is_key_pressed(MenuLib.keyCodes[i]) then
                MenuLib.config.options[item][1] = MenuLib.keyCodes[i]
                MenuLib.config.options[item][2] = false
                break
            end
        end
        if input.is_key_pressed(0x1B) then -- Escape key to cancel
            MenuLib.config.options[item][1] = 0x00
            MenuLib.config.options[item][2] = false
        end
    end
end

function MenuLib.create_checkbox(title, x, y, item, r, g, b, a)
    local state = MenuLib.config.options[item][1]

    local titlePos = {x = x - 2, y = y}
    local checkboxPos = {x = x + 155, y = y + 2}
    
    local titleWidth, titleHeight = render.measure_text(render.create_font(MenuLib.config.menu.font, 13), title)


    if MenuLib.inbox(checkboxPos.x, checkboxPos.x + 11, checkboxPos.y, checkboxPos.y + 11) or MenuLib.inbox(titlePos.x, titlePos.x + titleWidth, titlePos.y, titlePos.y + titleHeight) then
        render.draw_rectangle(checkboxPos.x - 1, checkboxPos.y - 1, 13, 13, MenuLib.config.menu.color[1], MenuLib.config.menu.color[2], MenuLib.config.menu.color[3], 255, 0, true, 3)
        render.draw_rectangle(checkboxPos.x, checkboxPos.y, 11, 11, 20, 20, 20, 255, 0, true, 3)

        render.draw_line(checkboxPos.x + 2, checkboxPos.y + 6, checkboxPos.x + 4, checkboxPos.y + 8, MenuLib.config.menu.color[1], MenuLib.config.menu.color[2], MenuLib.config.menu.color[3], 255, 1)
        render.draw_line(checkboxPos.x + 4, checkboxPos.y + 8, checkboxPos.x + 9, checkboxPos.y + 3, MenuLib.config.menu.color[1], MenuLib.config.menu.color[2], MenuLib.config.menu.color[3], 255, 1)
    else
        render.draw_rectangle(checkboxPos.x - 1, checkboxPos.y - 1, 13, 13, 45, 45, 45, 255, 0, true, 3)
        render.draw_rectangle(checkboxPos.x, checkboxPos.y, 11, 11, 20, 20, 20, 255, 0, true, 3)
    end

    
    if state then
        render.draw_rectangle(checkboxPos.x - 1, checkboxPos.y - 1, 13, 13, MenuLib.config.menu.color[1], MenuLib.config.menu.color[2], MenuLib.config.menu.color[3], 225, 0, true, 3)
        render.draw_line(checkboxPos.x + 2, checkboxPos.y + 6, checkboxPos.x + 4, checkboxPos.y + 8, 20, 20, 20, 255, 1)
        render.draw_line(checkboxPos.x + 4, checkboxPos.y + 8, checkboxPos.x + 9, checkboxPos.y + 3, 20, 20, 20, 255, 1)

        render.draw_text(render.create_font(MenuLib.config.menu.font, 13), title, titlePos.x, titlePos.y, 232, 232, 232, 255, 0, 0, 0, 0, 0)
    elseif MenuLib.inbox(checkboxPos.x, checkboxPos.x + 11, checkboxPos.y, checkboxPos.y + 11) or MenuLib.inbox(titlePos.x, titlePos.x + titleWidth, titlePos.y, titlePos.y + titleHeight) then
        render.draw_text(render.create_font(MenuLib.config.menu.font, 13), title, titlePos.x, titlePos.y, 232, 232, 232, 255, 0, 0, 0, 0, 0)
    else
        render.draw_text(render.create_font(MenuLib.config.menu.font, 13), title, titlePos.x, titlePos.y, 66, 66, 66, 255, 0, 0, 0, 0, 0)
    end
    
    if (MenuLib.inbox(checkboxPos.x, checkboxPos.x + 11, checkboxPos.y, checkboxPos.y + 11) or MenuLib.inbox(titlePos.x, titlePos.x + titleWidth, titlePos.y, titlePos.y + titleHeight)) and input.is_key_pressed(0x01) then
        MenuLib.config.options[item][1] = not MenuLib.config.options[item][1]
    end
end

-- Helper function to convert HSV to RGB
function hsv_to_rgb(hue, saturation, value)
    local c = value * saturation
    local x = c * (1 - math.abs((hue / 60) % 2 - 1))
    local m = value - c
    local r, g, b

    if hue >= 0 and hue < 60 then
        r, g, b = c, x, 0
    elseif hue >= 60 and hue < 120 then
        r, g, b = x, c, 0
    elseif hue >= 120 and hue < 180 then
        r, g, b = 0, c, x
    elseif hue >= 180 and hue < 240 then
        r, g, b = 0, x, c
    elseif hue >= 240 and hue < 300 then
        r, g, b = x, 0, c
    else
        r, g, b = c, 0, x
    end

    return (r + m) * 255, (g + m) * 255, (b + m) * 255
end

function LPrint(msg)
    engine.log(msg, 255, 255, 255, 255)
end

function validate_color_picker_values(color)
    if not color or #color < 6 then
        LPrint("Error: Invalid color table")
        return false
    end
    
    if type(color[1]) ~= "number" or color[1] < 0 or color[1] > 255 then
        LPrint("Error: Invalid red value")
        return false
    end
    if type(color[2]) ~= "number" or color[2] < 0 or color[2] > 255 then
        LPrint("Error: Invalid green value")
        return false
    end
    if type(color[3]) ~= "number" or color[3] < 0 or color[3] > 255 then
        LPrint("Error: Invalid blue value")
        return false
    end
    if type(color[4]) ~= "number" or color[4] < 0 or color[4] > 255 then
        LPrint("Error: Invalid alpha value")
        return false
    end
    if type(color[5]) ~= "boolean" then
        LPrint("Error: Invalid open state value")
        return false
    end
    if type(color[6]) ~= "number" or color[6] < 0 or color[6] > 360 then
        LPrint("Error: Invalid hue value")
        return false
    end

    return true
end

local color_picker_active_zone = nil
local color_picker_active_zone2 = nil
local color_picker_open_time  = 0

function MenuLib.create_colorpicker(title, label_x, label_y, configKey, x, y)
    if not MenuLib.config.options[configKey] then
        MenuLib.config.options[configKey] = {255, 255, 255, 255, false, 0} -- Default RGBA, closed, hue 0
    end
    
    local color = MenuLib.config.options[configKey]

    if not validate_color_picker_values(color) then
        return
    end

    local isOpen = color[5] 

    local picker_x = (x and x + 530) or (label_x and label_x + 0) or 0
    local picker_y = (y and y + 25) or (label_y and label_y + 30) or 0
    picker_x = picker_x - 5

    local TW, TH = render.measure_text(render.create_font(MenuLib.config.menu.font, 13), title)

    local previewpos = {x = label_x + 154, y = label_y + 5}

    if string.sub(title, 1, 2) ~= "##" then

        if color[5] or (MenuLib.inbox(label_x + 154, label_x + 167, label_y + 5, label_y + 18) or MenuLib.inbox(label_x  - 2, label_x - 2 + TW, label_y + 5, label_y + 5 + TH)) then
            render.draw_text(render.create_font(MenuLib.config.menu.font, 13), title, label_x - 2, label_y + 5, 232, 232, 232, 255, 0, 0, 0, 0, 0)
        else
            render.draw_text(render.create_font(MenuLib.config.menu.font, 13), title, label_x - 2, label_y + 5, 66, 66, 66, 255, 0, 0, 0, 0, 0)

        end

        previewpos = {x = label_x + 154, y = label_y + 5}
    else
        previewpos = {x = label_x, y = label_y}
    end
    

    render.draw_rectangle(previewpos.x, previewpos.y, 13, 13, 66, 66, 66, 255, 0, true, 3)
    render.draw_rectangle(previewpos.x + 1, previewpos.y + 1, 11, 11, 144, 144, 144, 255, 0, true, 3) --144
    render.draw_rectangle(previewpos.x + 7 - 0.5, previewpos.y + 7 - 0.5, 4 + 0.5, 4 + 0.5, 200, 200, 200, 255, 0, true)
    render.draw_rectangle(previewpos.x + 1 + 0.5, previewpos.y + 1 + 0.5, 4 + 0.5, 4 + 0.5, 200, 200, 200, 255, 0, true)
    render.draw_rectangle(previewpos.x + 0.75, previewpos.y + 0.75, 11.5, 11.5, color[1], color[2], color[3], color[4], 0, true, 3)

    -- Handle button click to toggle color picker

    local CrashBypass = false
    if string.sub(title, 1, 2) ~= "##" then
        CrashBypass = MenuLib.inbox(previewpos.x, previewpos.x + 11, previewpos.y, previewpos.y + 11)
                  or MenuLib.inbox(label_x - 2, label_x - 2 + TW, label_y + 5, label_y + 5 + TH)
    else
        CrashBypass = MenuLib.inbox(previewpos.x, previewpos.x + 11, previewpos.y, previewpos.y + 11)
    end
    
    
    if CrashBypass and input.is_key_pressed(0x01) then
        if not color[5] then
            color_picker_open_time = winapi.get_tickcount64()
        end
        color[5] = not isOpen
    end

    -- If color picker open
    if color[5] then

        render.draw_rectangle(picker_x - 15, picker_y - 5, 171, 181, 23, 23, 23, 255, 0, true, 3)
        render.draw_rectangle(picker_x - 15, picker_y - 25, 171, 30, 15, 15, 15, 255, 0, true, 3)
        render.draw_line(picker_x - 15, picker_y + 5, (picker_x - 15) + 171, (picker_y + 5), 45, 45, 45, 255, 1)

        if string.sub(title, 1, 2) == "##" then
            title = string.sub(title, 3)
        end

        render.draw_text(render.create_font("Verdana", 13), title, picker_x, picker_y - 18, 255, 255, 255, 255, 0, 0, 0, 0, 0)
        
        picker_y = picker_y + 20

        local color_field_width = 125
        local color_field_height = 125
        local hue_bar_width = 10
        local alpha_bar_width = color_field_width


        local mouse_x, mouse_y = input.get_mouse_position()
        local leftclick_down = input.is_key_down(0x01)
        local leftclick_pressed = input.is_key_pressed(0x01)

        local step = 4

        -- Draw Color Field
        for j = 0, color_field_height - 1 do
            local value = 1 - (j / (color_field_height - 1))
            for i = 0, color_field_width - step, step do
                local saturation = i / (color_field_width - 1)
                local next_saturation = (i + step) / (color_field_width - 1)
        
                local r1, g1, b1 = hsv_to_rgb(color[6] or 0, saturation, value)
                local r2, g2, b2 = hsv_to_rgb(color[6] or 0, next_saturation, value)
        
                -- Interpolate between r1,g1,b1 and r2,g2,b2 (approximate with average)
                local r = (r1 + r2) / 2
                local g = (g1 + g2) / 2
                local b = (b1 + b2) / 2
        
                render.draw_line(
                    picker_x + i,
                    picker_y + j,
                    picker_x + i + step,
                    picker_y + j,
                    r, g, b, 255,
                    1
                )
            end
        end
        
        

        -- Draw Hue Bar
        render.draw_rectangle(picker_x + color_field_width + 6, picker_y, hue_bar_width, color_field_height, 255, 0, 0, 255, 0, true)
        for j = 0, color_field_height - 1 do
            local hue = (j / (color_field_height - 1)) * 360
            local r, g, b = hsv_to_rgb(hue, 1, 1)
            render.draw_rectangle(picker_x + color_field_width + 6, picker_y + j, hue_bar_width, 1, r, g, b, 255, 0, true)
        end

        -- Draw Alpha Bar
        render.draw_rectangle(picker_x, picker_y + color_field_height + 6, alpha_bar_width, 9, 45, 45, 45, 255, 0, true)
        render.draw_rectangle(picker_x, picker_y + color_field_height + 6, (color[4] / 255) * alpha_bar_width, 9, color[1], color[2], color[3], color[4], 0, true)

        if mouse_x >= picker_x and mouse_x <= picker_x + color_field_width and mouse_y >= picker_y and mouse_y <= picker_y + color_field_height then
            color_picker_active_zone2 = "color_field"
        elseif mouse_x >= picker_x + color_field_width + 10 and mouse_x <= picker_x + color_field_width + 10 + hue_bar_width and mouse_y >= picker_y and mouse_y <= picker_y + color_field_height then
            color_picker_active_zone2 = "hue_bar"
        elseif mouse_x >= picker_x and mouse_x <= picker_x + alpha_bar_width and mouse_y >= picker_y + color_field_height + 10 and mouse_y <= picker_y + color_field_height + 20 then
            color_picker_active_zone2 = "alpha_bar"
        else
            color_picker_active_zone2 = false
        end

        -- Handle mouse input
        if leftclick_pressed then
            -- Set active zone when mouse first clicks
            if mouse_x >= picker_x and mouse_x <= picker_x + color_field_width and mouse_y >= picker_y and mouse_y <= picker_y + color_field_height then
                color_picker_active_zone = "color_field"
            elseif mouse_x >= picker_x + color_field_width + 6 and mouse_x <= picker_x + color_field_width + 6 + hue_bar_width and mouse_y >= picker_y and mouse_y <= picker_y + color_field_height then
                color_picker_active_zone = "hue_bar"
            elseif mouse_x >= picker_x and mouse_x <= picker_x + alpha_bar_width and mouse_y >= picker_y + color_field_height + 6 and mouse_y <= picker_y + color_field_height + 16 then
                color_picker_active_zone = "alpha_bar"
            else
                color_picker_active_zone = nil
            end
        elseif not leftclick_down then
            -- Clear active zone when mouse button released
            color_picker_active_zone = nil
        end



        -- If holding mouse button, apply only to active zone
        if leftclick_down and color_picker_active_zone ~= nil then
            if color_picker_active_zone == "color_field" then
                local rel_x = math.min(math.max(mouse_x - picker_x, 0), color_field_width - 1)
                local rel_y = math.min(math.max(mouse_y - picker_y, 0), color_field_height - 1)
                local saturation = rel_x / (color_field_width - 1)
                local value = 1 - (rel_y / (color_field_height - 1))
                local r, g, b = hsv_to_rgb(color[6] or 0, saturation, value)
                color[1], color[2], color[3] = r, g, b
            elseif color_picker_active_zone == "hue_bar" then
                local rel_y = math.min(math.max(mouse_y - picker_y, 0), color_field_height - 1)
                local new_hue = (rel_y / (color_field_height - 1)) * 360
                color[6] = new_hue
                local r, g, b = hsv_to_rgb(new_hue, 1, 1)
                color[1], color[2], color[3] = r, g, b
            elseif color_picker_active_zone == "alpha_bar" then
                local rel_x = math.min(math.max(mouse_x - picker_x, 0), alpha_bar_width)
                local new_alpha = (rel_x / alpha_bar_width) * 255
                color[4] = math.max(0, math.min(255, new_alpha))
            end
        end

        local current_time = winapi.get_tickcount64()
        local elapsed_time = current_time - color_picker_open_time
        
        if leftclick_pressed and (color_picker_active_zone == nil) and not color_picker_active_zone2 and elapsed_time > 200 then
            -- allow closing only if 200ms have passed since opening
            color[5] = false
        end
        
    end
end


-- RGB Helper functions
function MenuLib.rainbow_rgba(time_interval, alpha)
    local time_ms = winapi.get_tickcount64() 
    local time = (time_ms % (time_interval * 1000)) / (time_interval * 1000) 
    local hue = (time * 360) / 360 
    
    local r, g, b = MenuLib.hsv_to_rgb(hue, 1, 1) 
    return r * 255, g * 255, b * 255, alpha or 255  
end

function MenuLib.rgb_to_hue(r, g, b)
    local max = math.max(r, g, b)
    local min = math.min(r, g, b)
    local delta = max - min
    
    if delta == 0 then
        return 0  -- grayscale
    end
    
    local hue
    if max == r then
        hue = (g - b) / delta
        if g < b then hue = hue + 6 end
    elseif max == g then
        hue = (b - r) / delta + 2
    else -- max == b
        hue = (r - g) / delta + 4
    end
    
    hue = hue / 6  -- Normalize to 0-1
    
    if hue < 0 then
        hue = hue + 1
    end
    
    return hue
end

function MenuLib.rgb_to_hsv(r, g, b)
    local max, min = math.max(r, g, b), math.min(r, g, b)
    local h, s, v
    v = max
    
    local d = max - min
    if max == 0 then
        s = 0
    else
        s = d / max
    end
    
    if max == min then
        h = 0 -- achromatic
    else
        if max == r then
            h = (g - b) / d
            if g < b then h = h + 6 end
        elseif max == g then
            h = (b - r) / d + 2
        elseif max == b then
            h = (r - g) / d + 4
        end
        h = h / 6
    end
    
    return h, s, v
end

function MenuLib.hsv_to_rgb(h, s, v)
    local r, g, b
    
    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)
    
    i = i % 6
    
    if i == 0 then
        r, g, b = v, t, p
    elseif i == 1 then
        r, g, b = q, v, p
    elseif i == 2 then
        r, g, b = p, v, t
    elseif i == 3 then
        r, g, b = p, q, v
    elseif i == 4 then
        r, g, b = t, p, v
    elseif i == 5 then
        r, g, b = v, p, q
    end
    
    return r, g, b
end

-- Config management
function MenuLib.save_config(Name)
    local configData = ""
    
    -- Helper function to properly convert values for saving
    local function valueToString(val)
        if type(val) == "boolean" then
            return val and "true" or "false"
        end
        return tostring(val)
    end

    -- Save menu properties
    configData = configData .. "menu_x=" .. MenuLib.config.menu.x .. "\n"
    configData = configData .. "menu_y=" .. MenuLib.config.menu.y .. "\n"
    configData = configData .. "menu_isVisible=" .. valueToString(MenuLib.config.menu.isVisible) .. "\n"
    configData = configData .. "menu_snapToEdges=" .. valueToString(MenuLib.config.menu.snapToEdges) .. "\n"
    
    -- Save tabs state
    for tabName, state in pairs(MenuLib.config.tabs) do
        configData = configData .. "tab_" .. tabName .. "=" .. valueToString(state[1]) .. "\n"
    end
    
    -- Save options
    for key, value in pairs(MenuLib.config.options) do
        if type(value) == "table" then
            local values = {}
            for i, v in ipairs(value) do
                if type(v) == "table" then
                    local subvalues = {}
                    for _, sub in ipairs(v) do
                        table.insert(subvalues, valueToString(sub))
                    end
                    table.insert(values, table.concat(subvalues, ","))
                else
                    table.insert(values, valueToString(v))
                end
            end
            configData = configData .. key .. "=" .. table.concat(values, "|") .. "\n"
        else
            configData = configData .. key .. "=" .. valueToString(value) .. "\n"
        end
    end
    
    -- Write to file
    local success, err = pcall(function()
        fs.write_to_file(Name, net.base64_encode(configData))
    end)
    
    if not success then
        engine.log("Failed to save ".. Name .. ": " .. tostring(err), 255, 0, 0, 255)
    else
        engine.log(Name .. " saved successfully", 255, 255, 255, 255)
    end
end

function MenuLib.export_config(Name)
    local configData = ""
    
    -- Helper function to properly convert values for saving
    local function valueToString(val)
        if type(val) == "boolean" then
            return val and "true" or "false"
        end
        return tostring(val)
    end

    -- Save menu properties
    configData = configData .. "menu_x=" .. MenuLib.config.menu.x .. "\n"
    configData = configData .. "menu_y=" .. MenuLib.config.menu.y .. "\n"
    configData = configData .. "menu_isVisible=" .. valueToString(MenuLib.config.menu.isVisible) .. "\n"
    configData = configData .. "menu_snapToEdges=" .. valueToString(MenuLib.config.menu.snapToEdges) .. "\n"
    
    -- Save tabs state
    for tabName, state in pairs(MenuLib.config.tabs) do
        configData = configData .. "tab_" .. tabName .. "=" .. valueToString(state[1]) .. "\n"
    end
    
    -- Save options
    for key, value in pairs(MenuLib.config.options) do
        if type(value) == "table" then
            local values = {}
            for i, v in ipairs(value) do
                if type(v) == "table" then
                    local subvalues = {}
                    for _, sub in ipairs(v) do
                        table.insert(subvalues, valueToString(sub))
                    end
                    table.insert(values, table.concat(subvalues, ","))
                else
                    table.insert(values, valueToString(v))
                end
            end
            configData = configData .. key .. "=" .. table.concat(values, "|") .. "\n"
        else
            configData = configData .. key .. "=" .. valueToString(value) .. "\n"
        end
    end
    
    -- Write to file
    local success, err = pcall(function()
        input.set_clipboard(net.base64_encode(configData))
    end)
    
    if not success then
        engine.log("Failed to export ".. Name .. ": " .. tostring(err), 255, 0, 0, 255)
    else
        engine.log(Name .. " exported successfully", 255, 255, 255, 255)
    end
end

function MenuLib.load_config(Name)
    if fs.does_file_exist(Name) then
        local configData = fs.read_from_file(Name)
        configData = net.base64_decode(configData)
        for line in configData:gmatch("[^\n]+") do
            local key, value = line:match("(.-)=(.+)")
            if key and value then
                -- Handle menu properties
                if key == "menu_x" then
                    MenuLib.config.menu.x = tonumber(value)
                elseif key == "menu_y" then
                    MenuLib.config.menu.y = tonumber(value)
                elseif key == "menu_isVisible" then
                    MenuLib.config.menu.isVisible = value == "true"
                elseif key == "menu_snapToEdges" then
                    MenuLib.config.menu.snapToEdges = value == "true"
                
                -- Handle tabs
                elseif key:find("^tab_") then
                    local tabName = key:sub(5)
                    if MenuLib.config.tabs[tabName] then
                        MenuLib.config.tabs[tabName][1] = value == "true"
                    end
                
                -- Handle options - this is where we fix boolean conversion
                else
                    local parts = {}
                    for v in value:gmatch("[^|]+") do
                        if v:find(",") then
                            local subparts = {}
                            for sub in v:gmatch("[^,]+") do
                                -- Convert string booleans to real booleans
                                if sub == "true" then
                                    table.insert(subparts, true)
                                elseif sub == "false" then
                                    table.insert(subparts, false)
                                else
                                    -- Try to convert to number, fall back to string
                                    local num = tonumber(sub)
                                    table.insert(subparts, num or sub)
                                end
                            end
                            table.insert(parts, subparts)
                        else
                            -- Handle single values (like checkbox_example)
                            if v == "true" then
                                table.insert(parts, true)
                            elseif v == "false" then
                                table.insert(parts, false)
                            else
                                local num = tonumber(v)
                                table.insert(parts, num or v)
                            end
                        end
                    end
                    
                    -- Reconstruct the exact table structure
                    if MenuLib.config.options[key] then
                        -- Update existing table to preserve references
                        for i = 1, #parts do
                            if MenuLib.config.options[key][i] ~= nil then
                                MenuLib.config.options[key][i] = parts[i]
                            else
                                MenuLib.config.options[key][i] = parts[i]
                            end
                        end
                    else
                        MenuLib.config.options[key] = parts
                    end
                end
            end
        end
    end
    engine.log(Name .. " imported successfully\n\n", 255, 255, 255, 255)
end

function MenuLib.import_config(Name)
    local configData = input.get_clipboard()
    configData = net.base64_decode(configData)
    for line in configData:gmatch("[^\n]+") do
        local key, value = line:match("(.-)=(.+)")
        if key and value then
            -- Handle menu properties
            if key == "menu_x" then
                MenuLib.config.menu.x = tonumber(value)
            elseif key == "menu_y" then
                MenuLib.config.menu.y = tonumber(value)
            elseif key == "menu_isVisible" then
                MenuLib.config.menu.isVisible = value == "true"
            elseif key == "menu_snapToEdges" then
                MenuLib.config.menu.snapToEdges = value == "true"
            
            -- Handle tabs
            elseif key:find("^tab_") then
                local tabName = key:sub(5)
                if MenuLib.config.tabs[tabName] then
                    MenuLib.config.tabs[tabName][1] = value == "true"
                end
            
            -- Handle options - this is where we fix boolean conversion
            else
                local parts = {}
                for v in value:gmatch("[^|]+") do
                    if v:find(",") then
                        local subparts = {}
                        for sub in v:gmatch("[^,]+") do
                            -- Convert string booleans to real booleans
                            if sub == "true" then
                                table.insert(subparts, true)
                            elseif sub == "false" then
                                table.insert(subparts, false)
                            else
                                -- Try to convert to number, fall back to string
                                local num = tonumber(sub)
                                table.insert(subparts, num or sub)
                            end
                        end
                        table.insert(parts, subparts)
                    else
                        -- Handle single values (like checkbox_example)
                        if v == "true" then
                            table.insert(parts, true)
                        elseif v == "false" then
                            table.insert(parts, false)
                        else
                            local num = tonumber(v)
                            table.insert(parts, num or v)
                        end
                    end
                end
                
                -- Reconstruct the exact table structure
                if MenuLib.config.options[key] then
                    -- Update existing table to preserve references
                    for i = 1, #parts do
                        if MenuLib.config.options[key][i] ~= nil then
                            MenuLib.config.options[key][i] = parts[i]
                        else
                            MenuLib.config.options[key][i] = parts[i]
                        end
                    end
                else
                    MenuLib.config.options[key] = parts
                end
            end
        end
    end
    engine.log(Name .. " imported successfully\n\n", 255, 255, 255, 255)
end

function MenuLib.create_config_buttons(x, y, r, g, b, a)
    local button_width = 100
    local button_height = 25
    local spacing = 30 -- space between buttons
    local text_offset = 5 -- space for the text above the buttons
    local section_offset = 0 -- initial offset for horizontal layout

    -- "Legit", "Semi", and "Rage" config buttons horizontally aligned
    local config_names = {"Legit", "Semi", "Rage"}
    local current_x = x -- starting x position

    for _, config_name in ipairs(config_names) do
        -- Draw config label
        render.draw_text(render.create_font(MenuLib.config.menu.font, 13), config_name, current_x + 10, y, 255, 255, 255, 255, 0, 0, 0, 0, 0)

        -- Load Button for current config
        render.draw_rectangle(current_x, y + text_offset + 20, button_width, button_height, r, g, b, a, 0, true)
        render.draw_text(render.create_font(MenuLib.config.menu.font, 13), "Load", current_x + 10, y + text_offset + 25, 255, 255, 255, 255, 0, 0, 0, 0, 0)
        if MenuLib.inbox(current_x, current_x + button_width, y + text_offset + 20, y + text_offset + 45) and input.is_key_pressed(0x01) then
            MenuLib.load_config(MenuLib.config.menu.configNames[_])
        end

        -- Save Button for current config
        render.draw_rectangle(current_x, y + text_offset + 50, button_width, button_height, r, g, b, a, 0, true)
        render.draw_text(render.create_font(MenuLib.config.menu.font, 13), "Save", current_x + 10, y + text_offset + 55, 255, 255, 255, 255, 0, 0, 0, 0, 0)
        if MenuLib.inbox(current_x, current_x + button_width, y + text_offset + 50, y + text_offset + 75) and input.is_key_pressed(0x01) then
            MenuLib.save_config(MenuLib.config.menu.configNames[_])
        end

        -- Update the x position for the next config
        current_x = current_x + button_width + spacing
    end
end


-- engine.log("V: " .. MenuLib.version, 0,255,255,255)
-- engine.log("Author: " .. MenuLib.author, 0,255,255,255)
-- engine.log("description: " .. MenuLib.description, 0,255,255,255)

return MenuLib
