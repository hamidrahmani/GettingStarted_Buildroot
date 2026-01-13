# About Repository
## Purpose 
This repository provides a minimal, customized embedded Linux system configured for the BeagleBone board. Its purpose is to demonstrate how all components fit together to build a robust and reliable Linux solution for embedded applications. Focus is on:
- showing the anatomy of buildroot and how everything get configured and works
- showing how to build a simple but reliabe working ustomized embedded linux 
- integrating the user applications into finale binary
  
## Structure of the Repository
- buildroot/                   # Upstream Buildroot source (renamed from buildroot-master_from-github)
- overlays/                    # Board overlays and board-specific configurations
  - beaglebone/                 # BeagleBone-specific files
    - rootfs-overlay/            # Root filesystem overlay files
- docs/                        # Documentation and how-to guides
- scripts/                     # Flash scripts and helper scripts (e.g., flash_beaglebone_*.sh)
- examples/                    # Small runnable examples (e.g., Lighttpd config, tests)
- .gitignore
- README.md

# Available Releases
The following releases are currently available. 
- v1.0 → Base code from the official Buildroot source
- artifact_v → Includes the compiled build artifacts
- sdcard_v → Contains the complete sdcard.img for flashing

