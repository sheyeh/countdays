# BringThemHomeNow

A Garmin watchface project that uses the Connect IQ SDK to show the number of days since October 7, 2023 on the watch.

Supported watches are those with SDK level 5.0.0 (System 7) and above with color display (both MIP or AMOLED), as listed in the manifest file. Models with B&W display (Instinct 3 Solar and Instinct E) are not supported.

## Building and Testing on Mac

### Prerequisites
1. Install Garmin ConnectIQ SDK
2. The code looks for the developer key file two folders up (../..). If this is different in your environment then change it.

### Run automated tests
```bash
./test_all_devices.sh
```

Uses /usr/sbin/screencapture and getwindowid.
To nstall getwindowid:

```bash
brew tap smokris/getwindowid
brew install getwindowid

