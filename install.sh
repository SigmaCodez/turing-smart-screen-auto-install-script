#!/usr/bin/env bash
set -euo pipefail

APP_DIR="/opt/turing-smart-screen-python"
SERVICE="/etc/systemd/system/turing-smart-screen-python.service"
RUNNER="/usr/local/bin/turing-smart-screen-start.sh"
USER_NAME="${SUDO_USER:-$USER}"
TURING_VERSION="3.10.0"

echo "[1/8] Installing required packages..."
sudo apt update
sudo apt install -y gcc git python3-pip python3-venv python3-tk libusb-1.0-0

echo "[2/8] Installing turing-smart-screen-python release ${TURING_VERSION}..."
if [[ ! -d "$APP_DIR/.git" ]]; then
  sudo rm -rf "$APP_DIR"
  sudo git clone --branch "$TURING_VERSION" --depth 1 https://github.com/mathoudebine/turing-smart-screen-python.git "$APP_DIR"
else
  cd "$APP_DIR"
  sudo git fetch --tags --force
  sudo git reset --hard
  sudo git clean -fd
  sudo git checkout "$TURING_VERSION"
  sudo git reset --hard "$TURING_VERSION"
fi

echo "[3/8] Applying configure.py compatibility patch..."
# Upstream v3.10.0 can reference SIZE_2_8_ROUND_USB without defining it.
# Define it as an alias for SIZE_2_8_INCH_NEWREV if needed.
if grep -q "SIZE_2_8_ROUND_USB" "$APP_DIR/configure.py" && ! grep -q "^SIZE_2_8_ROUND_USB =" "$APP_DIR/configure.py"; then
  sudo sed -i '/^SIZE_2_8_INCH_NEWREV =/a SIZE_2_8_ROUND_USB = SIZE_2_8_INCH_NEWREV' "$APP_DIR/configure.py"
fi

echo "[4/8] Setting ownership..."
sudo chown -R "$USER_NAME":"$USER_NAME" "$APP_DIR"

echo "[5/8] Creating Python virtual environment and installing dependencies..."
cd "$APP_DIR"
sudo -u "$USER_NAME" rm -rf venv
sudo -u "$USER_NAME" python3 -m venv venv
sudo -u "$USER_NAME" bash -lc "cd '$APP_DIR' && source venv/bin/activate && python3 -m pip install --upgrade pip && python3 -m pip install -r requirements.txt"

echo "[6/8] Adding user to dialout group for USB serial access..."
sudo usermod -a -G dialout "$USER_NAME"

echo "[7/8] Installing start script..."
sudo tee "$RUNNER" >/dev/null <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

APP_DIR="/opt/turing-smart-screen-python"

cd "$APP_DIR"
source "$APP_DIR/venv/bin/activate"
exec python3 main.py
EOF
sudo chmod +x "$RUNNER"

echo "[8/8] Installing and enabling systemd service..."
sudo tee "$SERVICE" >/dev/null <<EOF
[Unit]
Description=Turing Smart Screen Python
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=$USER_NAME
WorkingDirectory=$APP_DIR
ExecStart=$RUNNER
Restart=on-failure
ProtectSystem=full
ProtectHome=read-only
PrivateTmp=true
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now turing-smart-screen-python.service

echo
echo "Done. Installed turing-smart-screen-python release $TURING_VERSION."
echo
echo "Run the initial configuration once:"
echo "cd $APP_DIR && source venv/bin/activate && python3 configure.py"
echo
echo "Service status:"
echo "systemctl status turing-smart-screen-python.service"
echo
echo "Note: Log out and back in or reboot if dialout group access was just added."
