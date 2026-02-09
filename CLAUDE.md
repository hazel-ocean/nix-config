# Nix Config

NixOS and nix-darwin configuration flake for multiple hosts.

## Hosts

- **korriban** - Primary NixOS desktop (x86_64-linux), AMD Ryzen + RX 9070 XT (RDNA 4)
- **pigeon** - macOS (aarch64-darwin)
- **espeon** - macOS (aarch64-darwin)
- **ghastly** - NixOS server (aarch64-linux)

## Structure

- `flake.nix` - Main flake with `mkNixosHost` and `mkDarwinHost` helpers
- `host/<hostname>/configuration.nix` - Host-specific NixOS/darwin config
- `host/<hostname>/home-configuration.nix` - Host-specific home-manager config
- `home/` - Shared home-manager configurations
- `programs/` - Program-specific configurations (helix, zed, claude, etc.)
- `layers/` - Shared configuration layers (fonts, etc.)
- `overlay/` - Nixpkgs overlays

## Korriban: Sunshine Streaming Setup

### Goal
Stream games via Sunshine/Moonlight using a **virtual display** - not the main KDE Plasma display.

### Hardware
- GPU: AMD RX 9070 XT (RDNA 4, Navi 48) at PCI 03:00.0
- Render device: `/dev/dri/renderD128`
- Main display: DP-1 (KDE Plasma Wayland)
- Virtual display: DP-2 (via EDID firmware)

### Approaches Tried

#### 1. `amdgpu.virtual_display` kernel parameter - FAILED
- Caused boot hangs on RDNA 4, especially with early amdgpu loading in initrd
- The parameter disables physical outputs which breaks things

#### 2. Headless Sway + wlroots capture - FAILED
- Set up `WLR_BACKENDS=headless` Sway session
- Sunshine's wlroots capture has a regression (GitHub issue #4050)
- "Unable to initialize capture method" error
- Known bug with Vulkan format handling in recent Sunshine versions

#### 3. Headless Sway + KMS capture - FAILED
- KMS capture doesn't recognize headless connector types
- "Unknown Monitor connector type [HEADLESS]" error

#### 4. EDID Firmware Method - CURRENT APPROACH
- Uses an unused GPU port (DP-2) with fake EDID file
- Kernel thinks a real display is connected
- KMS capture should work on this "real" display
- Requires reboot for kernel params

### Current Configuration

```nix
# Virtual display via EDID on unused DP-2 port
hardware.firmware = [
  (pkgs.runCommand "edid-firmware" {} ''
    mkdir -p $out/lib/firmware/edid
    # Samsung Q800T HDMI 2.1 EDID (supports 4K/120Hz)
    echo '...' | base64 -d > $out/lib/firmware/edid/samsung-q800t.bin
  '')
];
boot.kernelParams = [
  "drm.edid_firmware=DP-2:edid/samsung-q800t.bin"
  "video=DP-2:e"
];

# Sunshine with KMS capture on DP-2
services.sunshine = {
  enable = true;
  autoStart = false;
  openFirewall = true;
  capSysAdmin = true;  # Required for KMS capture
};

# Custom config pointing to DP-2
environment.etc."sunshine-streaming.conf".text = ''
  encoder = vaapi
  capture = kms
  adapter_name = /dev/dri/card1
  output_name = DP-2
  ...
'';
```

### Known Issues

1. **RDNA 4 VAAPI crashes** - Encoding with VAAPI on RX 9070 XT causes segfaults in Mesa's libgallium. May need software encoding as fallback.

2. **Sunshine wlroots regression** - GitHub issue #4050, broken since PR #3783. Working version: v2025.122.141614

### Next Steps

# 1. Rebuild
sudo nixos-rebuild switch --flake ~/.config/nix-config#korriban

# 2. Reboot (required for kernel params)
sudo reboot

# 3. After reboot, verify DP-2 shows as connected
for p in /sys/class/drm/*/status; do con=${p%/status}; echo -n "${con#*/card?-}: "; cat $p; done

# 4. Check Sunshine logs
journalctl --user -u sunshine-streaming -f

1. Reboot to apply EDID kernel parameters
2. Verify DP-2 appears as connected display
3. Test Sunshine KMS capture on DP-2
4. If VAAPI crashes, fall back to software encoding
5. Configure KDE to ignore DP-2 (kscreen-doctor)

### Fallback Options

- **Dummy HDMI plug** (~$5) - Most reliable, physical solution
- **Downgrade Sunshine** - Use v2025.122.141614 for working wlroots capture

## Rebuilding

```bash
# From repo root
sudo nixos-rebuild switch --flake .#korriban

# Or with just (see Justfile)
just switch
```
