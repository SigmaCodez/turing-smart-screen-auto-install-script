#!/usr/bin/env bash
set -euo pipefail

APP_DIR="/opt/turing-smart-screen-python"
SERVICE="/etc/systemd/system/turing-smart-screen-python.service"
RUNNER="/usr/local/bin/turing-smart-screen-start.sh"
USER_NAME="${SUDO_USER:-$USER}"

sudo apt update
sudo apt install -y gcc git python3-pip python3-venv python3-tk

if [[ ! -d "$APP_DIR" ]]; then
  sudo git clone https://github.com/mathoudebine/turing-smart-screen-python.git "$APP_DIR"
fi
sudo chown -R "$USER_NAME":"$USER_NAME" "$APP_DIR"

cd "$APP_DIR"
sudo -u "$USER_NAME" python3 -m venv venv
sudo -u "$USER_NAME" bash -lc "cd '$APP_DIR' && source venv/bin/activate && python3 -m pip install -r requirements.txt"

sudo usermod -a -G dialout "$USER_NAME"

sudo tee "$RUNNER" >/dev/null <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
APP_DIR="/opt/turing-smart-screen-python"
cd "$APP_DIR"
source "$APP_DIR/venv/bin/activate"
exec python3 main.py
EOF
sudo chmod +x "$RUNNER"

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
Restart=always
RestartSec=2
ProtectSystem=full
ProtectHome=read-only
PrivateTmp=true
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now turing-smart-screen-python.service

echo "Done. Tip: Run the initial configuration once:"
echo "cd $APP_DIR && source venv/bin/activate && python3 configure.py"
echo "Service status: systemctl status turing-smart-screen-python.service"
