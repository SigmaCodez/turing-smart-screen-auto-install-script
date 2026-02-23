# Turing Smart Screen – systemd Autostart (turing-smart-screen-python)

This repository provides a small, ready-to-use setup to run **turing-smart-screen-python** automatically at boot using **systemd**.

- systemd service: `/etc/systemd/system/turing-smart-screen-python.service`
- one-step installer: `install.sh`
- restart behavior: `Restart=on-failure` (restart only if the app crashes)

> This repo does **not** include the upstream project source code. It installs it into `/opt/turing-smart-screen-python`.

## Requirements

- Debian / Ubuntu / Raspberry Pi OS (or compatible)
- systemd
- Internet connection (for `git clone` and `pip`)
- Turing Smart Screen connected via USB (typically `/dev/ttyACM0`)

## Quick start

```bash
git clone https://github.com/SigmaCodez/turing-smart-screen-auto-install-script.git
cd turing-smart-screen-auto-install-script
chmod +x install.sh
sudo ./install.sh
```

Run the initial upstream configuration (GUI):

```bash
cd /opt/turing-smart-screen-python
source venv/bin/activate
python3 configure.py
```

Check service & logs:

```bash
systemctl status turing-smart-screen-python.service
journalctl -u turing-smart-screen-python.service -f
```

## What `install.sh` does

- installs required packages (`gcc`, `git`, `python3-venv`, `python3-tk`, …)
- clones the upstream repo to `/opt/turing-smart-screen-python` (if missing)
- creates a Python venv and installs dependencies
- adds your user to the `dialout` group (USB serial access)
- installs the start script to `/usr/local/bin/turing-smart-screen-start.sh`
- installs the systemd unit to `/etc/systemd/system/`
- enables and starts the service

## Uninstall

```bash
sudo systemctl disable --now turing-smart-screen-python.service
sudo rm -f /etc/systemd/system/turing-smart-screen-python.service
sudo rm -f /usr/local/bin/turing-smart-screen-start.sh
sudo systemctl daemon-reload

# optional:
sudo rm -rf /opt/turing-smart-screen-python
```

## Credits (Upstream)

All display logic and hardware support are provided by the upstream project:

**turing-smart-screen-python** by **mathoudebine** (Mathieu D.)  
https://github.com/mathoudebine/turing-smart-screen-python

This repository is only a convenience wrapper (installer + systemd autostart).  
If you find it useful, please consider starring/supporting the upstream repo.

