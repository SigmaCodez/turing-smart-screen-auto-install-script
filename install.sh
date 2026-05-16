#!/usr/bin/env bash
set -euo pipefail

APP_DIR="/opt/turing-smart-screen-python"
SERVICE="/etc/systemd/system/turing-smart-screen-python.service"
RUNNER="/usr/local/bin/turing-smart-screen-start.sh"

# The user account the service should run under (the invoking user when using sudo)
USER_NAME="${SUDO_USER:-$USER}"

echo "[1/7] Installing required packages..."
apt update
apt install -y gcc git python3-pip python3-venv python3-tk zip

echo "[2/7] Cloning upstream repository (if needed)..."
if [[ ! -d "$APP_DIR" ]]; then
  git clone https://github.com/mathoudebine/turing-smart-screen-python.git "$APP_DIR"
fi

echo "[3/7] Setting ownership for ${APP_DIR}..."
chown -R "$USER_NAME":"$USER_NAME" "$APP_DIR"

echo "[4/7] Creating virtual environment & installing dependencies..."
sudo -u "$USER_NAME" python3 -m venv "$APP_DIR/venv"
sudo -u "$USER_NAME" bash -lc "cd '$APP_DIR' && source venv/bin/activate && python3 -m pip install -r requirements.txt"

echo "[5/7] Adding user to dialout group (USB serial access)..."
usermod -a -G dialout "$USER_NAME" || true

echo "[6/7] Installing start script to ${RUNNER}..."
cat > "$RUNNER" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

APP_DIR="/opt/turing-smart-screen-python"

cd "$APP_DIR"
source "$APP_DIR/venv/bin/activate"
exec python3 main.py
EOF
chmod 0755 "$RUNNER"

echo "[7/7] Installing and enabling systemd service..."
tmp_service="$(mktemp)"
sed "s/^User=.*/User=${USER_NAME}/" "$(dirname "$0")/turing-smart-screen-python.service" > "$tmp_service"
install -m 0644 "$tmp_service" "$SERVICE"
rm -f "$tmp_service"

systemctl daemon-reload
systemctl enable --now turing-smart-screen-python.service

echo
echo "Installation complete."
echo "Next: run the upstream configuration GUI once:"
echo "  cd $APP_DIR && source venv/bin/activate && python3 configure.py"
echo
echo "NOTE: If you were just added to the dialout group, log out and back in (or reboot)."
