# Wi-Fi AP on the WCN785x radio, bridged onto the wired LAN so clients land on
# the same subnet as the moonshine host itself.
{ ... }:
let
  lan = "enp12s0";
  wlan = "wlp11s0";
  bridge = "br0";
in
{
  # hostapd and NetworkManager's wpa_supplicant cannot share the radio.
  networking.networkmanager.unmanaged = [ "interface-name:${wlan}" ];

  # NetworkManager forces networking.useDHCP = false, so the bridge has to be
  # one of its profiles to get an address.
  networking.networkmanager.ensureProfiles.profiles = {
    ${bridge} = {
      connection = {
        id = bridge;
        type = "bridge";
        interface-name = bridge;
        autoconnect-priority = 100;
      };
      bridge = {
        # Pinned to enp12s0 so korriban's LAN address survives wlp11s0 joining.
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

  # wlp11s0 has no profile here: hostapd enslaves it to the bridge itself.
  services.hostapd = {
    enable = true;
    radios.${wlan} = {
      band = "5g";
      channel = 149; # non-DFS at 30 dBm; ACS is unreliable on ath12k
      # No countryCode: the phy is self-managed and already enforces US limits.
      # Setting it makes hostapd hang in COUNTRY_UPDATE and fail to initialise.
      wifi5.operatingChannelWidth = "80";
      wifi6 = {
        enable = true;
        operatingChannelWidth = "80";
      };
      # The module's default HT40 lacks the +/- hostapd parses, leaving no
      # secondary channel. 149 pairs upward with 153.
      wifi4.capabilities = [
        "HT40+"
        "SHORT-GI-20"
        "SHORT-GI-40"
      ];
      # The module never emits the 80 MHz centre-channel index. Without it
      # hostapd derives a negative DFS channel index and aborts on startup.
      settings = {
        vht_oper_centr_freq_seg0_idx = 155;
        he_oper_centr_freq_seg0_idx = 155;
      };
      networks.${wlan} = {
        ssid = "korriban";
        settings.bridge = bridge;
        authentication = {
          mode = "wpa3-sae";
          saePasswords = [ { passwordFile = "/var/lib/hostapd/sae-passphrase"; } ];
        };
      };
    };
  };
}
