#!/bin/bash
# do not FUCKING use this script unless you have a RTL8821CE chip (which you probably dont, so dont do it)
# make sure the config dirs exist
WP_DIR="$HOME/.config/wireplumber/wireplumber.conf.d"
PW_DIR="$HOME/.config/pipewire/pipewire.conf.d"
mkdir -p "$WP_DIR" "$PW_DIR" "/etc/modprobe.d"

# fuck the stupid ass chip i hate it
cat << 'EOF' | sudo tee /etc/modprobe.d/btusb.conf
options btusb auto_suspend=0 disable_scofix=1
EOF

cat << 'EOF' | sudo tee /etc/modprobe.d/rtw88.conf
options rtw88_core disable_lps_deep=y
options rtw88_pci disable_aspm=y
options rtw88_8821ce disable_aspm=y
EOF

cat << 'EOF' | sudo tee /etc/modprobe.d/8821ce.conf
options 8821ce rtw_power_mgnt=0 rtw_enusbss=0 rtw_ips_mode=0
EOF


# ban codec-switching and disable link powersaving
cat << 'EOF' > "$WP_DIR/15-rtl-bluetooth-stability.conf"
wireplumber.settings = {
    # Stop automatically switching to garbage mono quality
    bluetooth.autoswitch-to-headset-profile = false
}

monitor.bluez.rules = [
  {
    matches = [
      {
        node.name = "~bluez_card.*"
      }
    ]
    actions = {
      update-properties = {
        # Keep connection open even during silence to prevent wake-up stutters
        session.suspend-timeout-seconds = 0

        # Hard-cap the MTU size so the RTL chip doesn't choke on huge packets
        bluetooth.enc.mtu = 979
        bluetooth.dec.mtu = 979

        # Disallow ultra-low bitrates. Force a reliable floor.
        bluetooth.sbc.hq.min-bpim = 53
        bluetooth.sbc.hq.max-bpim = 53
      }
    }
  }
]
EOF


# now onto pipewire, we lock the buffer size (quantum) to stop audio freezes
cat << 'EOF' > "$PW_DIR/10-lock-quantum.conf"
context.properties = {
    # Lock processing loop at a steady 1024 frames.
    # Prevents apps from dynamically resizing the buffer and crashing the RTL stream.
    default.clock.quantum = 1024
    default.clock.min-quantum = 1024
    default.clock.max-quantum = 1024
}
EOF

echo "reboot now to apply the RTL8821CE kernel changes."
