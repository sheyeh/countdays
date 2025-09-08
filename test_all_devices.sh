#!/bin/bash

# Your SDK path (update the version number as needed)
SDK_PATH=$(ls -d "$HOME/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-"* | head -1)
PROJECT_NAME="countdays"
DEVELOPER_KEY="../../developer_key"  # Full path to your key

# Extract device IDs from manifest.xml
devices=$(grep -o 'product id="[^"]*"' manifest.xml | cut -d'"' -f2)

echo "Found devices:"
for device in $devices; do
    echo "  - $device"
done
echo ""

# Create bin directory if it doesn't exist
mkdir -p bin

# Test each device
for device in $devices; do
    echo "=== Testing device: $device ==="
    echo "- Building"
    
    PRG_FILE="bin/${PROJECT_NAME}_${device}.prg"
    
    # Use the same Java command as VS Code (but with monkeyc instead of monkeybrains.jar)
    java -Xms1g -Dfile.encoding=UTF-8 -Dapple.awt.UIElement=true \
        -jar "$SDK_PATH/bin/monkeybrains.jar" \
        -o "$PRG_FILE" \
        -f monkey.jungle \
        -y "$DEVELOPER_KEY" \
        -d "${device}_sim" \
        -w
    
    if [ $? -eq 0 ]; then
        echo "✓ Build successful for $device"
        echo ""
    else
        echo "✗ Build failed for $device"
        echo ""
    fi

    echo "- Running"
    "${SDK_PATH}/bin/monkeydo" "$PRG_FILE" "${device}" &
    sleep 5  # Give it some time to start
    echo "- Taking screenshot"
    SCREENSHOT_PATH="screenshots/${PROJECT_NAME}_${device}.png"
    WINDOW_ID=$(getwindowid "Connect IQ Device Simulator" --list | grep CIQ | awk -F'id=' '{print $2}')

    if [ -z "$WINDOW_ID" ]; then
        echo "Error: Could not find the CIQ Simulator window ID."
    else
      # Take the screenshot using the extracted ID
        /usr/sbin/screencapture -l"$WINDOW_ID" "${SCREENSHOT_PATH}"
        echo "Screenshot saved to ${SCREENSHOT_PATH}"
    fi
    echo ""
    echo "- Stopping simulator"
    pkill -f "monkeydo $PRG_FILE"
    sleep 2  # Give it some time to stop
    echo ""

done

echo "=== Testing Summary ==="
echo "Total devices tested: $(echo $devices | wc -w)"