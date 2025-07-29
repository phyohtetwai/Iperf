#!/bin/bash

# This 'while true' loop will run forever until you choose to exit.
while true; do
    clear
    
    echo "Select an Option"
    echo "----------------"
    echo "1. DOWNLOAD Test"
    echo "2. UPLOAD Test"
    echo "3. EXIT"
    echo "----------------"
    
    read -p "Enter your choice [1-3]: " opt

    # This function runs the test and processes the result
    run_test_and_find_max() {
        # The first argument ($1) will be any extra iperf3 options, like -R
        local iperf_options=$1
        
        echo "--- Starting Test (10 seconds) ---"
        local output
        output=$(iperf3 -c "$ip" -i1 -t10 -P8 $iperf_options)
        
        # Print the full, original output for you to see
        echo "$output"

        # First, check if the iperf3 connection was successful
        if ! echo "$output" | grep -q "connected to"; then
            echo
            echo "----------------------------------------"
            echo "⚠️  Error: Could not connect to IP: $ip"
            echo "----------------------------------------"
            return # Exit the function if connection failed
        fi
        
        # Process the output to find the max speed
        # FIX: The speed value is in column 6, not 7.
        # Also added grep -v 'receiver' for more robust filtering.
        local max_speed
        max_speed=$(echo "$output" | grep '\[SUM\]' | grep -v 'sender' | grep -v 'receiver' | awk '{print $6}' | sort -nr | head -n 1)

        # Check if we successfully found a speed
        if [ -n "$max_speed" ]; then
            echo
            echo "----------------------------------------"
            echo "📈 Maximum Throughput: $max_speed Mbits/sec"
            echo "----------------------------------------"
        else
            echo
            echo "----------------------------------------"
            echo "Could not determine maximum throughput from the test results."
            echo "----------------------------------------"
        fi
    }

    case $opt in
        1)
            read -p "Enter IP: " ip
            run_test_and_find_max ""
            ;;
        2)
            read -p "Enter IP: " ip
            run_test_and_find_max "-R"
            ;;
        3)
            echo "Exiting..."
            break
            ;;
        *)
            echo "Invalid Option! Please try again."
            ;;
    esac
    
    echo
    read -p "Press [Enter] to continue..."
done
