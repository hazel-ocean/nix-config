# Wi-Fi AP on the WCN785x radio, bridged onto the wired LAN.
{ lib, pkgs, ... }:
let
  lan = "enp12s0";
  wlan = "wlp11s0";
  bridge = "br0";
in
{
  environment.systemPackages = [ pkgs.iw ];

  # hostapd and NetworkManager's wpa_supplicant cannot share the radio.
  networking.networkmanager.unmanaged = [ "interface-name:${wlan}" ];

  # NetworkManager forces networking.useDHCP = false, so a native bridge never
  # gets an address.
  networking.networkmanager.ensureProfiles.profiles = {
    ${bridge} = {
      connection = {
        id = bridge;
        type = "bridge";
        interface-name = bridge;
        autoconnect-priority = 100;
      };
      bridge = {
        # Pinned to enp12s0 so the LAN address survives wlp11s0 joining.
        mac-address = "9C:6B:00:C4:89:30";
        stp = false;
      };
      ipv4.method = "auto";
      ipv6 = {
        method = "auto";
        addr-gen-mode = "stable-privacy";
      };
    };

    "${bridge}-${lan}" = {
      connection = {
        id = "${bridge}-${lan}";
        type = "ethernet";
        interface-name = lan;
        master = bridge;
        slave-type = "bridge";
        autoconnect-priority = 100;
      };
    };
  };

  # The card boots into regulatory domain 00, where every 5 GHz channel is
  # receive-only. This board publishes no SMBIOS country and a self-managed phy
  # ignores `iw reg set`, so the only way to reach US is to hear a neighbour's
  # country IE. A soft rfkill block resets the domain the same way.
  systemd.services.hostapd = {
    path = [
      pkgs.iproute2
      pkgs.iw
      pkgs.util-linux
    ];
    preStart = lib.mkBefore ''
      rfkill unblock wlan
      ip link set ${wlan} up
      iw dev ${wlan} scan > /dev/null || true
    '';
  };

  # wlp11s0 has no profile: hostapd enslaves it to the bridge itself.
  services.hostapd = {
    enable = true;
    radios.${wlan} = {
      band = "6g";
      channel = 37; # a PSC, so clients sweeping 6 GHz can find a lone AP
      # countryCode hangs hostapd in COUNTRY_UPDATE: the phy is self-managed.
      wifi4.enable = false; # 6 GHz is HE-only
      wifi5.enable = false;
      wifi6 = {
        enable = true;
        operatingChannelWidth = "80";
      };
      # The module emits no centre-channel index. 39 centres the 33-45 block.
      settings = {
        he_oper_centr_freq_seg0_idx = 39;
        op_class = 133;
        he_6ghz_reg_pwr_type = 3; # indoor enabled AP
      };
      networks.${wlan} = {
        ssid = "korriban";
        settings = {
          bridge = bridge;
          sae_pwe = lib.mkForce 1; # 6 GHz mandates hash-to-element
        };
        authentication = {
          mode = "wpa3-sae";
          saePasswords = [ { passwordFile = "/var/lib/hostapd/sae-passphrase"; } ];
        };
      };
    };
  };
}
