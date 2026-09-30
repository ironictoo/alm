#!/bin/bash
# Install the PsychoPy version of ALM on Linux or macOS. Run once from a terminal: ./install.sh
# Creates the Python environment, an "alm" command, and a launcher you can double-click.
set -e
menu_entry=""
cd "$(dirname "$0")"
DIR="$(pwd)"

# uv provides Python 3.10 (which PsychoPy needs) and installs the packages
if ! command -v uv >/dev/null; then
  echo "Installing uv (https://docs.astral.sh/uv/)..."
  curl -LsSf https://astral.sh/uv/install.sh | sh
  export PATH="$HOME/.local/bin:$PATH"
fi
uv venv --allow-existing --python 3.10 .venv
uv pip install --python .venv -r requirements.txt

# "alm" command
mkdir -p "$HOME/.local/bin"
cat > "$HOME/.local/bin/alm" <<EOF
#!/bin/bash
exec "$DIR/.venv/bin/python" "$DIR/alm.py" "\$@"
EOF
chmod +x "$HOME/.local/bin/alm"

# launchers open a terminal (for the "Inside the scanner?" question and the log)
# and keep it open at the end so any error can be read
if [ "$(uname)" = Darwin ]; then
  desktop="$HOME/Desktop"
else
  # applications menu ("Show Apps"): always
  mkdir -p "$HOME/.local/share/applications"
  menu_entry="$HOME/.local/share/applications/alm.desktop"
  cat > "$menu_entry" <<EOF
[Desktop Entry]
Type=Application
Name=ALM
Comment=Adaptive Language Mapping (PsychoPy version)
Exec=bash -c "$HOME/.local/bin/alm; read -rp 'Press Enter to close...'"
Terminal=true
Icon=accessories-dictionary
Categories=Science;
EOF
  desktop="$(xdg-user-dir DESKTOP 2>/dev/null || echo "$HOME/Desktop")"
fi

# desktop shortcut: only if wanted
shortcut=""
read -rp "Create a desktop shortcut? [y/N] " answer || true
if [[ "$answer" =~ ^[Yy] ]] && [ -d "$desktop" ]; then
  if [ "$(uname)" = Darwin ]; then
    shortcut="$desktop/ALM.command"
    printf '#!/bin/bash\n"%s"\nread -rp "Press Enter to close..."\n' "$HOME/.local/bin/alm" > "$shortcut"
  else
    shortcut="$desktop/ALM.desktop"
    cp "$menu_entry" "$shortcut"
    gio set "$shortcut" metadata::trusted true 2>/dev/null || true  # "Allow Launching"
  fi
  chmod +x "$shortcut"
fi

echo
echo "Installed. To run ALM:"
[ -n "$menu_entry" ] && echo "  - open \"Show Apps\" and search for ALM"
[ -n "$shortcut" ] && echo "  - double-click $shortcut"
echo "  - or type: alm   (if not found, open a new terminal or log out and back in)"
