using HTTP, JSON3, Crayons

# --- Configuration for Animation ---
const BOX_WIDTH = 38 # Width inside the box borders
const TEXT_LINES = [
    "      Subdomain Finder          ",
    "      Powered by crt.sh         ",
    "         Author: Muffin         "
]
const BOX_CHARS = Dict(
    :topLeft => '╔', :topRight => '╗',
    :bottomLeft => '╚', :bottomRight => '╝',
    :horizontal => '═', :vertical => '║'
)
const SPINNER_CHARS = ['|', '/', '-', '\\']
const CRAYON_STYLE = Crayons.crayon"bold blue"

# --- Helper Function for Animation ---
"""Pads text to the specified width, centering it."""
function pad_center(text::String, width::Int)
    padding_total = max(0, width - length(text))
    padding_left = padding_total ÷ 2
    padding_right = padding_total - padding_left
    return ' '^padding_left * text * ' '^padding_right
end

# --- Main Animation Function ---
"""
    animate_loading_logo(box_delay, spin_delay, text_delay, spin_cycles)

Animates the logo by:
1. Drawing the box outline character by character.
2. Showing a spinner animation inside the box.
3. Revealing the text inside character by character.
"""
function animate_loading_logo(
    box_delay::Float64 = 0.005,
    spin_delay::Float64 = 0.1,
    text_delay::Float64 = 0.015,
    spin_cycles::Int = 15 # Number of times the spinner updates
)
    num_text_lines = length(TEXT_LINES)
    total_height = num_text_lines + 2 # Text lines + top/bottom borders

    # --- Phase 1: Draw Box Outline ---
    println(CRAYON_STYLE, BOX_CHARS[:topLeft] * repeat(BOX_CHARS[:horizontal], BOX_WIDTH) * BOX_CHARS[:topRight])
    flush(stdout)
    sleep(box_delay * BOX_WIDTH) # Simulate delay for top border

    empty_line_content = ' '^BOX_WIDTH
    empty_full_line = BOX_CHARS[:vertical] * empty_line_content * BOX_CHARS[:vertical]

    for _ in 1:num_text_lines
        println(CRAYON_STYLE, empty_full_line)
        flush(stdout)
        sleep(box_delay)
    end

    println(CRAYON_STYLE, BOX_CHARS[:bottomLeft] * repeat(BOX_CHARS[:horizontal], BOX_WIDTH) * BOX_CHARS[:bottomRight])
    flush(stdout)
    sleep(box_delay)

    # --- Phase 2: Spinner Animation ---
    for i in 1:spin_cycles
        spinner_char = SPINNER_CHARS[(i-1) % length(SPINNER_CHARS) + 1]
        target_line_index = ceil(Int, num_text_lines / 2)

        for j in 1:num_text_lines
            print("\r")
            flush(stdout)
            line_content = if j == target_line_index
                pad_center(string(spinner_char), BOX_WIDTH)
            else
                ' '^BOX_WIDTH
            end
            println(CRAYON_STYLE, BOX_CHARS[:vertical] * line_content * BOX_CHARS[:vertical])
            flush(stdout)
        end
        sleep(spin_delay)
    end

    # --- Phase 3: Reveal Text ---
    for j in 1:num_text_lines
        print("\r")
        print(CRAYON_STYLE, BOX_CHARS[:vertical])
        flush(stdout)
        sleep(text_delay)

        current_text = pad_center(TEXT_LINES[j], BOX_WIDTH)
        for char in current_text
            print(CRAYON_STYLE, char)
            flush(stdout)
            sleep(text_delay)
        end

        println(CRAYON_STYLE, BOX_CHARS[:vertical])
        flush(stdout)
        sleep(text_delay)
    end
    println() # Ensure cursor is below box
end

# --- Subdomain Fetching Function ---
function get_subdomains(domain)
    url = "https://crt.sh/?q=%25.$domain&output=json"

    try
        response = HTTP.get(url)

        if response.status != 200
            println(Crayons.crayon"bold red"("Error: Failed to fetch data. HTTP Status: $(response.status)"))
            return []
        end

        data = JSON3.read(response.body)  # Parse JSON response

        # Extract and clean subdomains
        subdomains = Set()
        for entry in data
            if haskey(entry, "name_value")
                for sub in split(entry["name_value"], '\n')  # Handle multi-line entries
                    clean_sub = strip(sub)  # Remove extra spaces
                    if !startswith(clean_sub, "*")  # Remove wildcard entries
                        push!(subdomains, clean_sub)
                    end
                end
            end
        end

        return sort(collect(subdomains))  # Return sorted unique subdomains

    catch e
        println(Crayons.crayon"bold red"("Error occurred: $e"))
        return []
    end
end

# --- Logo Print Function ---
function print_logo()
    animate_loading_logo()
end

# UI Header
print_logo()

# User Input
print(Crayons.crayon"bold yellow"("\nEnter the domain to search subdomains for: "))
domain = strip(readline())

if isempty(domain)
    println(Crayons.crayon"bold red"("\nError: Domain cannot be empty!"))
else
    subdomains = get_subdomains(domain)

    if isempty(subdomains)
        println(Crayons.crayon"bold red"("\nNo subdomains found for $domain.\n"))
    else
        println(Crayons.crayon"bold green"("\n[+] Found $(length(subdomains)) subdomains for $domain:\n"))
        for sub in subdomains
            println(Crayons.crayon"cyan"(" - $sub"))
        end
    end
end
