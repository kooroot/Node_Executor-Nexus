#!/bin/bash

# Nexus Advanced Node Manager
# 사용자 정의 노드 개수와 스레드 설정 지원

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Base directory
BASE_DIR="$HOME/nexus_nodes"
CONFIG_FILE="$BASE_DIR/config.txt"
mkdir -p "$BASE_DIR"

# System info
TOTAL_CORES=$(sysctl -n hw.ncpu)
TOTAL_MEMORY=$(( $(sysctl -n hw.memsize) / 1024 / 1024 / 1024 ))

# Find nexus-network binary
find_nexus_binary() {
    echo -e "${BLUE}Finding nexus-network binary...${NC}"
    
    # Common paths
    NEXUS_PATHS=(
        "$HOME/.nexus/nexus-network"
        "$HOME/.nexus/bin/nexus-network"
        "/usr/local/bin/nexus-network"
        "$HOME/nexus/nexus-network"
    )
    
    NEXUS_BIN=""
    for path in "${NEXUS_PATHS[@]}"; do
        if [[ -f "$path" ]]; then
            NEXUS_BIN="$path"
            echo -e "${GREEN}✓ Found nexus at: $NEXUS_BIN${NC}"
            break
        fi
    done
    
    # Search if not found
    if [[ -z "$NEXUS_BIN" ]]; then
        echo -e "${YELLOW}Searching for nexus-network...${NC}"
        FOUND=$(find "$HOME" -name "nexus-network" -type f 2>/dev/null | head -1)
        if [[ -n "$FOUND" ]]; then
            NEXUS_BIN="$FOUND"
            echo -e "${GREEN}✓ Found at: $NEXUS_BIN${NC}"
        else
            echo -e "${RED}✗ nexus-network not found!${NC}"
            echo -e "${YELLOW}Installing Nexus...${NC}"
            curl https://cli.nexus.xyz/ | sh
            sleep 2
            NEXUS_BIN=$(find "$HOME" -name "nexus-network" -type f 2>/dev/null | head -1)
            
            if [[ -z "$NEXUS_BIN" ]]; then
                echo -e "${RED}Installation failed!${NC}"
                exit 1
            fi
        fi
    fi
    
    chmod +x "$NEXUS_BIN"
}

# Save configuration
save_config() {
    local node_count=$1
    local threads_per_node=$2
    local nodeids=("${@:3}")
    
    {
        echo "NODE_COUNT=$node_count"
        echo "THREADS_PER_NODE=$threads_per_node"
        echo "NODEIDS=(${nodeids[@]})"
    } > "$CONFIG_FILE"
}

# Load configuration
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        source "$CONFIG_FILE"
        return 0
    fi
    return 1
}

# System resource check
check_resources() {
    local node_count=$1
    local threads_per_node=$2
    local total_threads=$((node_count * threads_per_node))
    
    echo -e "\n${BLUE}=== Resource Check ===${NC}"
    echo -e "${CYAN}System specs:${NC}"
    echo "  CPU cores: $TOTAL_CORES"
    echo "  Memory: ${TOTAL_MEMORY}GB"
    
    echo -e "\n${CYAN}Requested resources:${NC}"
    echo "  Nodes: $node_count"
    echo "  Threads per node: $threads_per_node"
    echo "  Total threads: $total_threads"
    
    if [[ $total_threads -gt $TOTAL_CORES ]]; then
        echo -e "\n${YELLOW}⚠ Warning: Total threads ($total_threads) exceeds CPU cores ($TOTAL_CORES)${NC}"
        echo -e "${YELLOW}This may cause performance issues.${NC}"
        read -p "Continue anyway? (y/n): " confirm
        [[ "$confirm" != "y" ]] && return 1
    else
        echo -e "\n${GREEN}✓ Resource allocation looks good${NC}"
        echo -e "  Free cores for system: $((TOTAL_CORES - total_threads))"
    fi
    
    return 0
}

# Setup nodes
setup_nodes() {
    local node_count=$1
    local threads_per_node=$2
    shift 2
    local nodeids=("$@")
    
    # Stop existing nodes
    echo -e "\n${BLUE}Stopping existing nodes...${NC}"
    pkill -f nexus-network 2>/dev/null
    screen -wipe 2>/dev/null
    
    # Create and start nodes
    echo -e "\n${BLUE}Creating $node_count nodes with $threads_per_node threads each...${NC}"
    
    for i in $(seq 0 $((node_count - 1))); do
        NODE_NUM=$((i + 1))
        NODE_ID=${nodeids[$i]}
        NODE_DIR="$BASE_DIR/node$NODE_NUM"
        
        if [[ -n "$NODE_ID" ]]; then
            echo -e "\n${CYAN}Setting up Node $NODE_NUM (ID: $NODE_ID)${NC}"
            
            # Create isolated directory
            mkdir -p "$NODE_DIR/.nexus"
            
            # Create config
            cat > "$NODE_DIR/.nexus/config.json" << EOF
{
    "node_id": "$NODE_ID",
    "threads": $threads_per_node
}
EOF
            
            # Create run script
            cat > "$NODE_DIR/run.sh" << EOF
#!/bin/bash
echo "=== Nexus Node $NODE_NUM ==="
echo "NodeID: $NODE_ID"
echo "Threads: $threads_per_node"
echo "Home: $NODE_DIR"
echo "Binary: $NEXUS_BIN"
echo "================================"

export HOME="$NODE_DIR"

if [[ ! -f "$NEXUS_BIN" ]]; then
    echo "Error: Binary not found at $NEXUS_BIN"
    exit 1
fi

"$NEXUS_BIN" start --node-id $NODE_ID --max-threads $threads_per_node

echo "Node stopped. Press Enter to exit..."
read
EOF
            
            chmod +x "$NODE_DIR/run.sh"
            
            # Start in screen
            screen -dmS "nexus_node$NODE_NUM" "$NODE_DIR/run.sh"
            
            echo -e "${GREEN}✓ Node $NODE_NUM started${NC}"
            sleep 2
        fi
    done
    
    # Save configuration
    save_config "$node_count" "$threads_per_node" "${nodeids[@]}"
    
    echo -e "\n${GREEN}All nodes started!${NC}"
}

# Check status with detailed info
check_status() {
    echo -e "\n${BLUE}=== Node Status ===${NC}"
    echo -e "${CYAN}Nexus binary: $NEXUS_BIN${NC}"
    
    # Load saved config
    if load_config; then
        echo -e "${CYAN}Configuration:${NC}"
        echo "  Total nodes: $NODE_COUNT"
        echo "  Threads per node: $THREADS_PER_NODE"
        echo "  Total threads: $((NODE_COUNT * THREADS_PER_NODE))"
    fi
    
    echo -e "\n${CYAN}Nodes:${NC}"
    
    local running_count=0
    for dir in "$BASE_DIR"/node*; do
        if [[ -d "$dir" ]]; then
            NODE_NUM=$(basename "$dir" | sed 's/node//')
            
            if screen -list | grep -q "nexus_node$NODE_NUM"; then
                echo -e "Node $NODE_NUM: ${GREEN}● Running${NC}"
                ((running_count++))
                
                # Get NodeID from config
                if [[ -f "$dir/.nexus/config.json" ]]; then
                    NODE_ID=$(grep -o '"node_id"[[:space:]]*:[[:space:]]*"[^"]*"' "$dir/.nexus/config.json" | cut -d'"' -f4)
                    THREADS=$(grep -o '"threads"[[:space:]]*:[[:space:]]*[0-9]*' "$dir/.nexus/config.json" | cut -d':' -f2 | tr -d ' ')
                    echo "  NodeID: $NODE_ID"
                    echo "  Threads: $THREADS"
                fi
            else
                echo -e "Node $NODE_NUM: ${RED}○ Stopped${NC}"
            fi
        fi
    done
    
    echo -e "\n${CYAN}System:${NC}"
    echo "CPU usage: $(ps -A -o %cpu | awk '{s+=$1} END {printf "%.1f%%", s}')"
    echo "Running nodes: $running_count"
    echo "Nexus processes: $(pgrep -f nexus-network | wc -l)"
}

# Quick setup wizard
quick_setup() {
    echo -e "\n${PURPLE}=== Quick Setup Wizard ===${NC}"
    
    # Get node count
    read -p "How many nodes do you want to run? (1-10): " node_count
    if ! [[ "$node_count" =~ ^[1-9]$|^10$ ]]; then
        echo -e "${RED}Invalid number! Must be between 1-10${NC}"
        return 1
    fi
    
    # Get threads per node
    echo -e "\n${CYAN}System has $TOTAL_CORES CPU cores${NC}"
    local suggested_threads=$((TOTAL_CORES / node_count))
    [[ $suggested_threads -eq 0 ]] && suggested_threads=1
    
    read -p "Threads per node (suggested: $suggested_threads): " threads_per_node
    if ! [[ "$threads_per_node" =~ ^[1-9][0-9]*$ ]]; then
        echo -e "${RED}Invalid number!${NC}"
        return 1
    fi
    
    # Check resources
    if ! check_resources "$node_count" "$threads_per_node"; then
        return 1
    fi
    
    # Get NodeIDs
    echo -e "\n${YELLOW}Enter $node_count NodeIDs:${NC}"
    local nodeids=()
    for i in $(seq 1 $node_count); do
        read -p "NodeID $i: " nodeid
        nodeids+=("$nodeid")
    done
    
    # Setup nodes
    setup_nodes "$node_count" "$threads_per_node" "${nodeids[@]}"
}

# Advanced setup
advanced_setup() {
    echo -e "\n${PURPLE}=== Advanced Setup ===${NC}"
    
    # Import NodeIDs from file
    echo -e "${CYAN}1) Enter NodeIDs manually${NC}"
    echo -e "${CYAN}2) Import from file${NC}"
    read -p "Select option: " import_option
    
    local nodeids=()
    
    if [[ "$import_option" == "2" ]]; then
        read -p "Enter file path: " filepath
        if [[ -f "$filepath" ]]; then
            while IFS= read -r line; do
                [[ -n "$line" ]] && nodeids+=("$line")
            done < "$filepath"
            echo -e "${GREEN}Imported ${#nodeids[@]} NodeIDs${NC}"
        else
            echo -e "${RED}File not found!${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}Enter NodeIDs (empty line to finish):${NC}"
        while true; do
            read -p "NodeID: " nodeid
            [[ -z "$nodeid" ]] && break
            nodeids+=("$nodeid")
        done
    fi
    
    local node_count=${#nodeids[@]}
    if [[ $node_count -eq 0 ]]; then
        echo -e "${RED}No NodeIDs provided!${NC}"
        return 1
    fi
    
    echo -e "\n${GREEN}Total NodeIDs: $node_count${NC}"
    
    # Get threads configuration
    echo -e "\n${CYAN}Thread allocation:${NC}"
    echo "1) Same threads for all nodes"
    echo "2) Custom threads per node"
    read -p "Select option: " thread_option
    
    if [[ "$thread_option" == "1" ]]; then
        local suggested_threads=$((TOTAL_CORES / node_count))
        [[ $suggested_threads -eq 0 ]] && suggested_threads=1
        
        read -p "Threads per node (suggested: $suggested_threads): " threads_per_node
        check_resources "$node_count" "$threads_per_node" && \
        setup_nodes "$node_count" "$threads_per_node" "${nodeids[@]}"
    else
        echo -e "${YELLOW}Custom thread allocation not implemented yet${NC}"
    fi
}

# Main menu
show_menu() {
    echo -e "\n${PURPLE}=== Nexus Advanced Node Manager ===${NC}"
    echo -e "${CYAN}System: $TOTAL_CORES cores, ${TOTAL_MEMORY}GB RAM${NC}"
    echo ""
    echo -e "${CYAN}1) Quick setup${NC}"
    echo -e "${CYAN}2) Advanced setup${NC}"
    echo -e "${CYAN}3) Start saved configuration${NC}"
    echo -e "${CYAN}4) Stop all nodes${NC}"
    echo -e "${CYAN}5) Check status${NC}"
    echo -e "${CYAN}6) Monitor nodes${NC}"
    echo -e "${CYAN}0) Exit${NC}"
}

# Monitor nodes
monitor_nodes() {
    echo -e "${CYAN}Monitoring nodes... Press Ctrl+C to stop${NC}"
    
    while true; do
        clear
        echo -e "${BLUE}=== Nexus Node Monitor ===${NC}"
        echo -e "${CYAN}$(date)${NC}"
        
        check_status
        
        echo -e "\n${YELLOW}Refreshing in 5 seconds...${NC}"
        sleep 5
    done
}

# Main
find_nexus_binary

while true; do
    show_menu
    read -p "Select option: " option
    
    case $option in
        1) quick_setup ;;
        2) advanced_setup ;;
        3)
            if load_config; then
                echo -e "${BLUE}Loading saved configuration...${NC}"
                setup_nodes "$NODE_COUNT" "$THREADS_PER_NODE" "${NODEIDS[@]}"
            else
                echo -e "${RED}No saved configuration found!${NC}"
            fi
            ;;
        4)
            echo -e "${YELLOW}Stopping all nodes...${NC}"
            pkill -f nexus-network
            screen -ls | grep nexus | awk '{print $1}' | xargs -I {} screen -X -S {} quit
            echo -e "${GREEN}✓ All nodes stopped${NC}"
            ;;
        5) check_status ;;
        6) monitor_nodes ;;
        0)
            echo -e "${GREEN}Goodbye!${NC}"
            exit 0
            ;;
        *) echo -e "${RED}Invalid option!${NC}" ;;
    esac
    
    [[ $option != 6 ]] && read -p "Press Enter to continue..."
done
