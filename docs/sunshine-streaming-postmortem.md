# Sunshine Virtual Display Streaming - Post-Mortem

**Date**: 2026-02-08
**Hardware**: AMD RX 9070 XT (RDNA 4, Navi 48) on NixOS (Korriban)
**Goal**: Stream games via Sunshine/Moonlight using a virtual display, not the main KDE Plasma display

## Summary

After exhaustive testing of 4 different approaches, **none produced a working virtual display for Sunshine KMS capture on RDNA 4**. The fundamental issue is that software-only virtual displays don't allocate real GPU CRTCs, which KMS capture requires.

---

## Approaches Tried

### 1. `amdgpu.virtual_display` Kernel Parameter

**Status**: FAILED - Boot hangs

**What it does**: Creates a virtual connector in the amdgpu driver without requiring physical hardware.

**Configuration**:
```nix
boot.kernelParams = [ "amdgpu.virtual_display=0000:03:00.0,1" ];
```

**Result**: Caused boot hangs on RDNA 4, especially with early amdgpu loading in initrd. The parameter disables physical outputs which breaks the boot process.

**Why it failed**: RDNA 4 (Navi 48) doesn't handle `virtual_display` gracefully. The driver initialization path differs from older architectures.

---

### 2. Headless Sway + wlroots Capture

**Status**: FAILED - Sunshine regression

**What it does**: Run a separate Sway compositor with `WLR_BACKENDS=headless` and use Sunshine's wlroots capture method.

**Configuration**:
```nix
systemd.user.services.sway-sunshine = {
  environment = {
    WLR_BACKENDS = "headless";
    WLR_LIBINPUT_NO_DEVICES = "1";
    XDG_SESSION_TYPE = "wayland";
  };
  serviceConfig.ExecStart = "${pkgs.sway}/bin/sway -c /etc/sway-sunshine.conf";
};
```

**Result**: "Unable to initialize capture method" error. Sunshine's wlroots capture has a known regression.

**Why it failed**: GitHub issue #4050 - broken since PR #3783. The Vulkan format handling in recent Sunshine versions doesn't work with wlroots headless backends.

**Potential fix**: Downgrade to Sunshine v2025.122.141614 where wlroots capture worked.

---

### 3. Headless Sway + KMS Capture

**Status**: FAILED - Connector type not recognized

**What it does**: Same headless Sway setup, but use KMS capture instead of wlroots.

**Configuration**:
```
capture = kms
adapter_name = /dev/dri/card1
```

**Result**: "Unknown Monitor connector type [HEADLESS]" error.

**Why it failed**: KMS capture enumerates DRM connectors and doesn't recognize the "HEADLESS" connector type that wlroots creates. KMS capture expects real connector types like DP, HDMI, etc.

---

### 4. EDID Firmware on Unused Port (DP-2)

**Status**: FAILED - No CRTC allocated

**What it does**: Load a fake EDID file on an unused GPU port, making the kernel think a real display is connected.

**Configuration**:
```nix
# Custom EDID firmware
hardware.firmware = [
  (pkgs.runCommand "edid-firmware" {} ''
    mkdir -p $out/lib/firmware/edid
    echo '...' | base64 -d > $out/lib/firmware/edid/samsung-q800t.bin
  '')
];

boot.kernelParams = [
  "drm.edid_firmware=DP-2:edid/samsung-q800t.bin"
  "video=DP-2:e"  # Force enable
];
```

**Result**:
- DP-2 shows as "connected" in `/sys/class/drm/card1-DP-2/status`
- KDE detects and "enables" DP-2 as a 3840x2160@120Hz display
- But Sunshine shows `crtc_id: 0` for DP-2 (no CRTC assigned)
- Error: "Couldn't find monitor [23172]"

**Why it failed**: The EDID trick fools the kernel's "connected" status check, but without a physical display sink, the GPU doesn't allocate a real CRTC or create a framebuffer. KMS capture needs actual GPU rendering output, not just a connected status.

---

## This Session's Debugging

### Capability Issue (Fixed)

The custom `sunshine-streaming.service` was running the unwrapped Sunshine binary:
```nix
ExecStart = "${pkgs.sunshine}/bin/sunshine /etc/sunshine-streaming.conf";
```

This bypassed the NixOS capability wrapper. Fixed by using:
```nix
ExecStart = "/run/wrappers/bin/sunshine /etc/sunshine-streaming.conf";
```

Verified capability is now `cap_sys_admin=ep` (effective + permitted).

### CRTC Discovery

Sunshine enumeration showed:
```
Monitor connector: DP-1 id: 3, crtc_id: 0
Monitor connector: DP-2 id: 23172, crtc_id: 0
```

Both connectors have `crtc_id: 0`, meaning no CRTC is assigned. The kernel reports DP-2 as connected, but no rendering pipeline exists.

---

## Root Cause

**Virtual displays without physical output don't get CRTCs.**

A CRTC (CRT Controller) is hardware that scans out a framebuffer to a display. Without a real display:
- `amdgpu.virtual_display` - driver issue on RDNA 4
- Headless compositor - wlroots backend creates fake connectors, KMS doesn't understand them
- EDID firmware - kernel sees "connected" but GPU has nothing to render to

KMS capture requires a real CRTC with an active framebuffer. All software-only solutions fail at this hardware requirement.

---

## Recommended Solutions

### 1. Dummy HDMI/DP Plug (~$5-15)

**Most reliable**. A physical dummy plug provides a real signal termination, forcing the GPU to allocate a CRTC and render to it. The display doesn't need to be visible - it just needs to exist electrically.

```nix
# No special config needed - plug appears as real display
# Configure Sunshine to capture that output
output_name = HDMI-A-1  # or whatever the dummy shows as
```

### 2. Downgrade Sunshine for wlroots Capture

Use v2025.122.141614 where wlroots capture worked:

```nix
services.sunshine.package = pkgs.sunshine.overrideAttrs (old: {
  version = "2025.122.141614";
  src = pkgs.fetchFromGitHub {
    owner = "LizardByte";
    repo = "Sunshine";
    rev = "v2025.122.141614";
    # ... hash
  };
});
```

Then use headless Sway + wlroots capture.

### 3. Wait for Sunshine Fix

GitHub issue #4050 tracks the wlroots capture regression. Once fixed, headless Sway becomes viable again.

---

## Known Issues

### RDNA 4 VAAPI Crashes

Encoding with VAAPI on RX 9070 XT causes segfaults in Mesa's libgallium. May need software encoding:

```
encoder = software
```

Or wait for Mesa fixes for RDNA 4.

---

## Files Modified

- `host/korriban/configuration.nix` - Sunshine service, EDID firmware, kernel params
- `/etc/sunshine-streaming.conf` - KMS capture config pointing to DP-2

---

## Conclusion

For RDNA 4 + NixOS + Wayland, the **dummy plug is the pragmatic solution**. Software virtual displays fundamentally can't provide what KMS capture needs (a real CRTC). The wlroots regression in Sunshine blocks the compositor-based approach.

Future options:
- Sunshine wlroots fix (issue #4050)
- Mesa VAAPI fixes for RDNA 4
- Potential amdgpu driver improvements for virtual_display on newer architectures
