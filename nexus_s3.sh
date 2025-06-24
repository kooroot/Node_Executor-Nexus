#!/bin/bash

# Nexus Node Auto-Installation Script
# Supports Ubuntu (apt) and MacOS (brew)

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to detect OS
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v apt &> /dev/null; then
            echo "ubuntu"
        else
            echo "unsupported"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    else
        echo "unsupported"
    fi
}

# Function to print colored messages
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to install screen if not installed
install_screen() {
    if ! command -v screen &> /dev/null; then
        print_message "$YELLOW" "Screen is not installed. Installing..."
        if [[ $OS == "ubuntu" ]]; then
            sudo apt install -y screen
        elif [[ $OS == "macos" ]]; then
            brew install screen
        fi
    else
        print_message "$GREEN" "Screen is already installed."
    fi
}

# Function to update and upgrade system
update_system() {
    print_message "$BLUE" "========================================="
    print_message "$BLUE" "Updating and upgrading system packages..."
    print_message "$BLUE" "========================================="
    
    if [[ $OS == "ubuntu" ]]; then
        sudo apt update && sudo apt upgrade -y
    elif [[ $OS == "macos" ]]; then
        brew update && brew upgrade
    fi
    
    print_message "$GREEN" "System update completed!"
}

# Function to install Nexus CLI
install_nexus() {
    print_message "$BLUE" "========================================="
    print_message "$BLUE" "Installing Nexus Network CLI..."
    print_message "$BLUE" "========================================="
    
    # Kill any existing nexus processes
    pkill -f nexus-network 2>/dev/null || true
    
    # Remove old installation if exists
    rm -rf ~/.nexus/bin/nexus-network 2>/dev/null || true
    
    # Install Nexus CLI
    curl -sSL https://cli.nexus.xyz/ | sh
    
    # Wait for installation to complete
    sleep 3
    
    # Find the actual installation path
    NEXUS_PATH=""
    if [[ -f "$HOME/.nexus/bin/nexus-network" ]]; then
        NEXUS_PATH="$HOME/.nexus/bin"
    elif [[ -f "$HOME/.nexus/nexus-network" ]]; then
        NEXUS_PATH="$HOME/.nexus"
    elif [[ -f "/root/.nexus/bin/nexus-network" ]]; then
        NEXUS_PATH="/root/.nexus/bin"
    fi
    
    # Export PATH with the correct nexus location
    if [[ -n "$NEXUS_PATH" ]]; then
        export PATH="$NEXUS_PATH:$PATH"
        
        # Update shell configuration files
        if [[ $OS == "ubuntu" ]]; then
            echo "export PATH=\"$NEXUS_PATH:\$PATH\"" >> ~/.bashrc
            source ~/.bashrc
        elif [[ $OS == "macos" ]]; then
            if [[ -f ~/.zshrc ]]; then
                echo "export PATH=\"$NEXUS_PATH:\$PATH\"" >> ~/.zshrc
                source ~/.zshrc
            else
                echo "export PATH=\"$NEXUS_PATH:\$PATH\"" >> ~/.bash_profile
                source ~/.bash_profile
            fi
        fi
    fi
    
    # Verify installation
    if [[ -n "$NEXUS_PATH" ]] && [[ -f "$NEXUS_PATH/nexus-network" ]]; then
        print_message "$GREEN" "Nexus CLI installation completed successfully!"
        print_message "$GREEN" "Nexus installed at: $NEXUS_PATH"
        # Store the path for later use
        echo "$NEXUS_PATH" > /tmp/nexus_install_path.tmp
    else
        print_message "$RED" "Error: Nexus CLI installation may have failed!"
        exit 1
    fi
}

# Function to run Nexus with NodeID
run_with_nodeid() {
    local node_id=$1
    local nexus_path=$(cat /tmp/nexus_install_path.tmp 2>/dev/null || echo "$HOME/.nexus/bin")
    
    print_message "$BLUE" "Starting Nexus Network with NodeID: $node_id"
    print_message "$YELLOW" "Using Nexus path: $nexus_path"
    
    # Create screen session with proper error handling
    if [[ $OS == "ubuntu" ]]; then
        screen -dmS nexus_node bash -c "
            echo 'Setting up environment...'
            source ~/.bashrc 2>/dev/null || true
            export PATH=\"$nexus_path:\$PATH\"
            
            echo 'Starting Nexus Network with NodeID: $node_id'
            echo 'Nexus path: $nexus_path/nexus-network'
            
            # Try to run nexus-network
            if [[ -f \"$nexus_path/nexus-network\" ]]; then
                \"$nexus_path/nexus-network\" start --node-id $node_id
            else
                echo 'Error: nexus-network not found at $nexus_path'
                echo 'Trying alternative paths...'
                if [[ -f \"\$HOME/.nexus/bin/nexus-network\" ]]; then
                    \"\$HOME/.nexus/bin/nexus-network\" start --node-id $node_id
                elif [[ -f \"/root/.nexus/bin/nexus-network\" ]]; then
                    \"/root/.nexus/bin/nexus-network\" start --node-id $node_id
                else
                    echo 'Error: Could not find nexus-network executable!'
                fi
            fi
            
            # Keep the session alive
            echo 'Press Enter to exit...'
            read
        "
    elif [[ $OS == "macos" ]]; then
        screen -dmS nexus_node zsh -c "
            echo 'Setting up environment...'
            source ~/.zshrc 2>/dev/null || source ~/.bash_profile 2>/dev/null || true
            export PATH=\"$nexus_path:\$PATH\"
            
            echo 'Starting Nexus Network with NodeID: $node_id'
            echo 'Nexus path: $nexus_path/nexus-network'
            
            # Try to run nexus-network
            if [[ -f \"$nexus_path/nexus-network\" ]]; then
                \"$nexus_path/nexus-network\" start --node-id $node_id
            else
                echo 'Error: nexus-network not found at $nexus_path'
                echo 'Trying alternative paths...'
                if [[ -f \"\$HOME/.nexus/bin/nexus-network\" ]]; then
                    \"\$HOME/.nexus/bin/nexus-network\" start --node-id $node_id
                elif [[ -f \"/root/.nexus/bin/nexus-network\" ]]; then
                    \"/root/.nexus/bin/nexus-network\" start --node-id $node_id
                else
                    echo 'Error: Could not find nexus-network executable!'
                fi
            fi
            
            # Keep the session alive
            echo 'Press Enter to exit...'
            read
        "
    fi
    
    # Give screen time to start
    sleep 2
    
    print_message "$GREEN" "Nexus node started in screen session 'nexus_node'"
    print_message "$YELLOW" "To attach to the session, use: screen -r nexus_node"
    print_message "$YELLOW" "To detach from screen: press Ctrl+A, then D"
    print_message "$BLUE" "Checking if node is running..."
    
    # Check if screen session is still running
    if screen -list | grep -q "nexus_node"; then
        print_message "$GREEN" "Screen session is active!"
    else
        print_message "$RED" "Warning: Screen session may have terminated. Check logs with: screen -r nexus_node"
    fi
}

# Function to run Nexus with Wallet Address
run_with_wallet() {
    local wallet_address=$1
    local nexus_path=$(cat /tmp/nexus_install_path.tmp 2>/dev/null || echo "$HOME/.nexus/bin")
    
    print_message "$BLUE" "Registering Nexus Network with Wallet Address: $wallet_address"
    print_message "$YELLOW" "Using Nexus path: $nexus_path"
    
    # Create screen session with proper error handling
    if [[ $OS == "ubuntu" ]]; then
        screen -dmS nexus_node bash -c "
            echo 'Setting up environment...'
            source ~/.bashrc 2>/dev/null || true
            export PATH=\"$nexus_path:\$PATH\"
            
            echo 'Registering Nexus Network with Wallet Address: $wallet_address'
            echo 'Nexus path: $nexus_path/nexus-network'
            
            # Function to run nexus command
            run_nexus() {
                local cmd=\$1
                shift
                if [[ -f \"$nexus_path/nexus-network\" ]]; then
                    \"$nexus_path/nexus-network\" \$cmd \"\$@\"
                elif [[ -f \"\$HOME/.nexus/bin/nexus-network\" ]]; then
                    \"\$HOME/.nexus/bin/nexus-network\" \$cmd \"\$@\"
                elif [[ -f \"/root/.nexus/bin/nexus-network\" ]]; then
                    \"/root/.nexus/bin/nexus-network\" \$cmd \"\$@\"
                else
                    echo 'Error: Could not find nexus-network executable!'
                    return 1
                fi
            }
            
            # Run registration commands
            echo 'Step 1: Registering user...'
            if run_nexus register-user --wallet-address $wallet_address; then
                echo 'User registration successful!'
                
                echo 'Step 2: Registering node...'
                if run_nexus register-node; then
                    echo 'Node registration successful!'
                    
                    echo 'Step 3: Starting node...'
                    run_nexus start
                else
                    echo 'Error: Node registration failed!'
                fi
            else
                echo 'Error: User registration failed!'
            fi
            
            # Keep the session alive
            echo 'Press Enter to exit...'
            read
        "
    elif [[ $OS == "macos" ]]; then
        screen -dmS nexus_node zsh -c "
            echo 'Setting up environment...'
            source ~/.zshrc 2>/dev/null || source ~/.bash_profile 2>/dev/null || true
            export PATH=\"$nexus_path:\$PATH\"
            
            echo 'Registering Nexus Network with Wallet Address: $wallet_address'
            echo 'Nexus path: $nexus_path/nexus-network'
            
            # Function to run nexus command
            run_nexus() {
                local cmd=\$1
                shift
                if [[ -f \"$nexus_path/nexus-network\" ]]; then
                    \"$nexus_path/nexus-network\" \$cmd \"\$@\"
                elif [[ -f \"\$HOME/.nexus/bin/nexus-network\" ]]; then
                    \"\$HOME/.nexus/bin/nexus-network\" \$cmd \"\$@\"
                elif [[ -f \"/root/.nexus/bin/nexus-network\" ]]; then
                    \"/root/.nexus/bin/nexus-network\" \$cmd \"\$@\"
                else
                    echo 'Error: Could not find nexus-network executable!'
                    return 1
                fi
            }
            
            # Run registration commands
            echo 'Step 1: Registering user...'
            if run_nexus register-user --wallet-address $wallet_address; then
                echo 'User registration successful!'
                
                echo 'Step 2: Registering node...'
                if run_nexus register-node; then
                    echo 'Node registration successful!'
                    
                    echo 'Step 3: Starting node...'
                    run_nexus start
                else
                    echo 'Error: Node registration failed!'
                fi
            else
                echo 'Error: User registration failed!'
            fi
            
            # Keep the session alive
            echo 'Press Enter to exit...'
            read
        "
    fi
    
    # Give screen time to start
    sleep 2
    
    print_message "$GREEN" "Nexus node registration started in screen session 'nexus_node'"
    print_message "$YELLOW" "To attach to the session, use: screen -r nexus_node"
    print_message "$YELLOW" "To detach from screen: press Ctrl+A, then D"
    print_message "$BLUE" "Checking if node is running..."
    
    # Check if screen session is still running
    if screen -list | grep -q "nexus_node"; then
        print_message "$GREEN" "Screen session is active!"
    else
        print_message "$RED" "Warning: Screen session may have terminated. Check logs with: screen -r nexus_node"
    fi
}

# Main script execution
main() {
    print_message "$BLUE" "========================================="
    print_message "$BLUE" "  Nexus Node Auto-Installation Script"
    print_message "$BLUE" "========================================="
    
    # Detect OS
    OS=$(detect_os)
    
    if [[ $OS == "unsupported" ]]; then
        print_message "$RED" "Error: Unsupported operating system!"
        print_message "$RED" "This script supports Ubuntu (with apt) and MacOS (with brew) only."
        exit 1
    fi
    
    print_message "$GREEN" "Detected OS: $OS"
    
    # Update system
    update_system
    
    # Install screen
    install_screen
    
    # Install Nexus CLI
    install_nexus
    
    # Ask user for installation option
    print_message "$BLUE" "========================================="
    print_message "$BLUE" "Please select installation option:"
    print_message "$YELLOW" "1) Use existing NodeID"
    print_message "$YELLOW" "2) Use Wallet Address (new node)"
    print_message "$BLUE" "========================================="
    
    read -p "Enter your choice (1 or 2): " choice
    
    case $choice in
        1)
            read -p "Enter your NodeID: " node_id
            if [[ -z "$node_id" ]]; then
                print_message "$RED" "Error: NodeID cannot be empty!"
                exit 1
            fi
            run_with_nodeid "$node_id"
            ;;
        2)
            read -p "Enter your Wallet Address: " wallet_address
            if [[ -z "$wallet_address" ]]; then
                print_message "$RED" "Error: Wallet Address cannot be empty!"
                exit 1
            fi
            run_with_wallet "$wallet_address"
            ;;
        *)
            print_message "$RED" "Error: Invalid choice! Please select 1 or 2."
            exit 1
            ;;
    esac
    
    print_message "$GREEN" "========================================="
    print_message "$GREEN" "Installation completed successfully!"
    print_message "$GREEN" "========================================="
    print_message "$YELLOW" "Useful commands:"
    print_message "$YELLOW" "- List screen sessions: screen -ls"
    print_message "$YELLOW" "- Attach to session: screen -r nexus_node"
    print_message "$YELLOW" "- Detach from session: Ctrl+A, then D"
    print_message "$YELLOW" "- Kill session: screen -X -S nexus_node quit"
    
    # Cleanup temp file
    rm -f /tmp/nexus_install_path.tmp 2>/dev/null || true
}

# Run main function
main
