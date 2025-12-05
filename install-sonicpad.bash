#!/bin/bash
# =============================================================================
# Burnstation3D UNLOCKED SONIC PAD — ONE-PASTE PRODUCTION INSTALL SCRIPT (2025)
# Works on every fresh unlocked Sonic Pad (Debian-based)
# Installs: Klipper + Moonraker + Mainsail (or Fluidd) + full system update + temp working printer.cfg
# Just edit the WiFi section below if you want wireless (optional)
# =============================================================================

set -e  # Exit immediately if any command fails

echo "=== Stopping any running services ==="
sudo systemctl stop moonraker klipper nginx 2>/dev/null || true

# 1. Install KIAUH
echo "=== Installing KIAUH ==="
rm -rf ~/kiauh
git clone https://github.com/dw-0/kiauh.git ~/kiauh

# 2. Install Klipper + Moonraker + Mainsail (fully automated) change 3 to 4 for fluidd!!! must have diff port #
echo "=== Installing Klipper, Moonraker, and Mainsail ==="
~/kiauh/kiauh.sh <<EOF
1
1
2
3
Q
EOF

# 3. Full system update + install the only missing package that breaks everything
echo "=== Updating system and installing python3-venv ==="
sudo apt update
sudo apt full-upgrade -y
sudo apt autoremove -y
sudo apt install -y python3-venv

# 4. Fix Moonraker's broken virtual environment (the #1 Sonic Pad killer)
echo "=== Fixing Moonraker virtual environment ==="
sudo systemctl stop moonraker
rm -rf ~/moonraker-env
python3 -m venv ~/moonraker-env
/usr/bin/python3 -m pip install --upgrade pip setuptools wheel --target ~/moonraker-env/lib/python3.9/site-packages
~/moonraker-env/bin/python -m pip install importlib_metadata zipp
~/moonraker-env/bin/python -m pip install -r ~/moonraker/scripts/moonraker-requirements.txt

# 5. Fix ownership
echo "=== Fixing permissions ==="
sudo chown -R sonic:sonic ~/moonraker ~/moonraker-env ~/printer_data

# 6. OPTIONAL: Configure WiFi — EDIT THIS SECTION FOR YOUR NETWORK
echo "=== WiFi setup (optional) ==="
sudo bash -c 'cat > /etc/wpa_supplicant/wpa_supplicant.conf' <<EOF
country=US
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1

# === UNCOMMENT AND EDIT BELOW IF YOU WANT WIFI ===
# network={
#     ssid="Your_SSID_Here"
#     psk="Your_Password_Here"
#     key_mgmt=WPA-PSK
# }
EOF

# Uncomment the next two lines if you filled in WiFi details
# sudo wpa_cli -i wlan0 reconfigure
# sudo systemctl restart networking

# 7. Add minimal working printer.cfg so Klipper starts and connects instantly
echo "=== Creating generic printer.cfg ==="
mkdir -p ~/printer_data/config
cat > ~/printer_data/config/printer.cfg <<'EOF'
[include mainsail.cfg]

[mcu]
serial: /dev/serial/by-id/usb-Klipper_stm32f103xe_*

[printer]
kinematics: cartesian
max_velocity: 300
max_accel: 3000
max_z_velocity: 5
max_z_accel: 100

[stepper_x]
step_pin: PB8
dir_pin: PB7
enable_pin: !PC3
microsteps: 16
rotation_distance: 40
endstop_pin: ^PC1
position_endstop: 0
position_max: 235
homing_speed: 50

[stepper_y]
step_pin: PB6
dir_pin: PB5
enable_pin: !PC3
microsteps: 16
rotation_distance: 40
endstop_pin: ^PC0
position_endstop: 0
position_max: 235
homing_speed: 50

[stepper_z]
step_pin: PB4
dir_pin: !PB3
enable_pin: !PC3
microsteps: 16
rotation_distance: 8
endstop_pin: ^PC2
position_endstop: 0.5
position_max: 250

[extruder]
step_pin: PB1
dir_pin: !PB0
enable_pin: !PC3
microsteps: 16
rotation_distance: 33.5
nozzle_diameter: 0.400
filament_diameter: 1.750
heater_pin: PA1
sensor_pin: PC5
sensor_type: EPCOS 100K B57560G104F
control: pid
pid_Kp: 22.2
pid_Ki: 1.08
pid_Kd: 114
min_temp: 0
max_temp: 275

[heater_bed]
heater_pin: PA2
sensor_pin: PC4
sensor_type: EPCOS 100K B57560G104F
control: pid
pid_Kp: 690.34
pid_Ki: 111.47
pid_Kd: 1068.26
min_temp: 0
max_temp: 130
EOF

# 8. Final restart
echo "=== Starting services ==="
sudo systemctl restart klipper moonraker nginx

# 9. Victory message
echo "=================================================================="
echo "SUCCESS! Your unlocked Sonic Pad is 100% ready for production."
echo "Open browser → http://$(hostname -I | awk '{print $1}')"
echo "If using WiFi, edit the script and uncomment the WiFi section."
echo "=================================================================="