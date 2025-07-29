#!/bin/bash

# Define IP list file
IP_FILE="ip_list.txt"
LOG_FILE="iperf_results.log"

# Create log file if it doesn't exist
if [ ! -f "$LOG_FILE" ]; then
    echo "Timestamp,IP Address,Test Type,Max Throughput (Mbits/sec)" > "$LOG_FILE"
fi

# Check if IP file exists
if [ ! -f "$IP_FILE" ]; then
    echo "❌ IP list file '$IP_FILE' not found!"
    exit 1
fi

# Function to run iperf test
run_test_and_find_max() {
    local ip=$1
    local iperf_options=$2
    local test_type=$3

    echo "--- Starting $test_type Test on $ip (10 seconds) ---"
    local output
    output=$(iperf3 -c "$ip" -i1 -t10 -P8 $iperf_options 2>&1)

    echo "$output"

    if ! echo "$output" | grep -q "connected to"; then
        echo "⚠️  Error: Could not connect to $ip"
        return
    fi

    local max_speed
    max_speed=$(echo "$output" | grep '\[SUM\]' | grep -v 'sender' | grep -v 'receiver' | awk '{print $6}' | sort -nr | head -n 1)

    if [ -n "$max_speed" ]; then
        local timestamp
        timestamp=$(date "+%Y-%m-%d %H:%M:%S")
        local log_entry="$timestamp,$ip,$test_type,$max_speed"
        echo "$log_entry" >> "$LOG_FILE"
        echo "📈 $test_type Max Throughput for $ip: $max_speed Mbits/sec"
        echo "💾 Result saved to $LOG_FILE"
    else
        echo "⚠️  Could not determine max throughput for $ip"
    fi
}

# Loop through each IP in the file
while IFS= read -r ip || [[ -n "$ip" ]]; do
    ip=$(echo "$ip" | xargs) # trim spaces
    if [ -n "$ip" ]; then
        run_test_and_find_max "$ip" "" "DOWNLOAD"
        run_test_and_find_max "$ip" "-R" "UPLOAD"
        echo
    fi
done < "$IP_FILE"
