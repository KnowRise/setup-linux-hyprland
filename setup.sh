#!/bin/bash

# ==========================================
# 0. ML4W DOTFILES INSTALLER
# ==========================================
echo "[+] Installing ML4W Dotfiles..."
bash <(curl -s https://ml4w.com/os/stable)

# ==========================================
# 1. SYSTEM UTILITIES & DUAL-BOOT SETUP
# ==========================================
echo "[+] Configuring system utilities and GRUB OS-prober..."
sudo pacman -S --noconfirm os-prober ntfs-3g
sudo sed -i 's/#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/g' /etc/default/grub
sudo grub-mkconfig -o /boot/grub/grub.cfg

# Enable Multilib Repository in Pacman
echo "[+] Enabling multilib repository..."
sudo sed -i "/\[multilib\]/,/Include/"s/^#// /etc/pacman.conf
sudo pacman -Syu --noconfirm

# Install Xenlism GRUB Theme
if [ -f "xenlism-grub-arch-4k.tar.xz" ]; then
    echo "[+] Installing Xenlism GRUB theme..."
    tar -xf xenlism-grub-arch-4k.tar.xz
    cd xenlism-grub-arch-4k
    sudo ./install.sh
    cd ..
else
    echo "[!] Xenlism GRUB archive not found, skipping theme installation."
fi

# ==========================================
# 2. AUR HELPER & PACKAGE MANAGERS (YAY)
# ==========================================
echo "[+] Installing YAY AUR helper..."
sudo pacman -S --needed --noconfirm git base-devel
if [ ! -d "yay" ]; then
    git clone https://aur.archlinux.org/yay.git
fi
cd yay && makepkg -si --noconfirm && cd ..

echo "[+] Installing packages via pacman and yay..."
yay -S --noconfirm aria2 visual-studio-code-bin

# ==========================================
# 3. MULTIMEDIA, UTILITIES & PLAYERS
# ==========================================
echo "[+] Setting up MPV and media tools..."
sudo pacman -S --noconfirm mpv xclip

# Setup MPV Config from remote repository (menggunakan HTTPS agar tidak perlu setup SSH key git terlebih dahulu)
if [ -d "$HOME/.config/mpv" ]; then
    rm -rf "$HOME/.config/mpv"
fi
git clone https://github.com/noelsimbolon/mpv-config.git ~/mpv-config-temp
mkdir -p ~/.config/mpv
cp -r ~/mpv-config-temp/* ~/.config/mpv/
rm -rf ~/mpv-config-temp

# ==========================================
# 4. GAMING & MULTIMEDIA
# ==========================================
echo "[+] Installing Steam and Lutris..."
sudo pacman -S --noconfirm steam lutris

# Force Wayland/X11 driver for Steam (Global Replacement)
mkdir -p ~/.local/share/applications
cp /usr/share/applications/steam.desktop ~/.local/share/applications/
sed -i 's|Exec=/usr/bin/steam|Exec=env SDL_VIDEODRIVER=wayland,x11 /usr/bin/steam|g' ~/.local/share/applications/steam.desktop

# ==========================================
# 5. SYSTEM SNAPSHOTS & BACKUPS (SNAPPER)
# ==========================================
echo "[+] Configuring Snapper retention limits..."
sudo sed -i 's/TIMELINE_LIMIT_HOURLY="[0-9]*"/TIMELINE_LIMIT_HOURLY="3"/g' /etc/snapper/configs/home
sudo sed -i 's/TIMELINE_LIMIT_DAILY="[0-9]*"/TIMELINE_LIMIT_DAILY="3"/g' /etc/snapper/configs/home
sudo sed -i 's/TIMELINE_LIMIT_WEEKLY="[0-9]*"/TIMELINE_LIMIT_WEEKLY="0"/g' /etc/snapper/configs/home
sudo sed -i 's/TIMELINE_LIMIT_MONTHLY="[0-9]*"/TIMELINE_LIMIT_MONTHLY="0"/g' /etc/snapper/configs/home
sudo sed -i 's/TIMELINE_LIMIT_QUARTERLY="[0-9]*"/TIMELINE_LIMIT_QUARTERLY="0"/g' /etc/snapper/configs/home
sudo sed -i 's/TIMELINE_LIMIT_YEARLY="[0-9]*"/TIMELINE_LIMIT_YEARLY="0"/g' /etc/snapper/configs/home

sudo sed -i 's/TIMELINE_LIMIT_HOURLY="[0-9]*"/TIMELINE_LIMIT_HOURLY="3"/g' /etc/snapper/configs/root
sudo sed -i 's/TIMELINE_LIMIT_DAILY="[0-9]*"/TIMELINE_LIMIT_DAILY="3"/g' /etc/snapper/configs/root
sudo sed -i 's/TIMELINE_LIMIT_WEEKLY="[0-9]*"/TIMELINE_LIMIT_WEEKLY="0"/g' /etc/snapper/configs/root
sudo sed -i 's/TIMELINE_LIMIT_MONTHLY="[0-9]*"/TIMELINE_LIMIT_MONTHLY="0"/g' /etc/snapper/configs/root
sudo sed -i 's/TIMELINE_LIMIT_QUARTERLY="[0-9]*"/TIMELINE_LIMIT_QUARTERLY="0"/g' /etc/snapper/configs/root
sudo sed -i 's/TIMELINE_LIMIT_YEARLY="[0-9]*"/TIMELINE_LIMIT_YEARLY="0"/g' /etc/snapper/configs/root

echo "[+] Automatically cleaning old snapper snapshots..."
for cfg in home root; do
    echo "[*] Cleaning snapshots for config: $cfg"
    # Mengambil ID snapshot dengan aman dari format tabel Snapper (mengabaikan garis batas dan ID 0)
    old_snapshots=$(sudo snapper -c "$cfg" list | tr -d '[:blank:]' | awk -F'|' 'NR>2 {print $2}' | grep -E '^[0-9]+$' | grep -v '^0$')
    if [ -n "$old_snapshots" ]; then
        for id in $old_snapshots; do
            echo "Deleting snapshot ID $id in $cfg..."
            sudo snapper -c "$cfg" delete "$id"
        done
    else
        echo "No old snapshots found to delete for $cfg."
    fi
done

# Btrfs maintenance / balance stabilization
echo "[+] Running btrfs balance and maintenance stabilization..."
sudo btrfs balance start -dusage=50 -dusage=85 /home
sudo btrfs balance start -dusage=50 -dusage=85 /

# ==========================================
# 6. RICE & ENVIRONMENT CUSTOMIZATION
# ==========================================
echo "[+] Applying custom configurations and ricing..."

# Fastfetch Custom Config
git clone https://github.com/douglasodev/fastfetch-custom-arch-linux.git ~/fastfetch-temp
mkdir -p ~/.config/fastfetch
cp ~/fastfetch-temp/config.jsonc ~/.config/fastfetch/config.jsonc
rm -rf ~/fastfetch-temp

# Wallpaper Setup & Application
mkdir -p ~/.config/ml4w/wallpapers
cp images/cute-anime.jpg ~/.config/ml4w/wallpapers/
~/.config/ml4w/scripts/ml4w-wallpaper ~/.config/ml4w/wallpapers/cute-anime.jpg

# Waybar Status Bar Settings
mkdir -p ~/.config/ml4w/settings
cat << 'EOF' > ~/.config/ml4w/settings/statusbar.json
{
    "bar": {
        "enabled": false,
        "alwaysExpanded": false,
        "autohide": false
    }
}
EOF

# Force Waybar Theme to Minimal
echo "/ml4w-minimal;/ml4w-minimal/config" > ~/.config/ml4w/settings/waybar-theme.sh

# Apply Custom Arch Linux Logo and Style for Waybar
mkdir -p ~/.config/waybar/assets
cp images/archlinux.webp ~/.config/waybar/assets/
mkdir -p ~/.config/waybar/themes/ml4w-minimal
cp configs/style.css ~/.config/waybar/themes/ml4w-minimal/style.css

# Apply Custom Keybindings Configuration
mkdir -p ~/.config/hypr/conf/keybindings
cp configs/default.lua ~/.config/hypr/conf/keybindings/default.lua

# ==========================================
# 7. TERMINAL ENHANCEMENTS (ZSH PLUGINS)
# ==========================================
echo "[+] Installing Zsh plugins..."
sudo pacman -S --noconfirm zsh-autosuggestions zsh-syntax-highlighting

# Register plugins safely to ~/.zshrc_custom
touch ~/.zshrc_custom
if ! grep -q "zsh-autosuggestions.zsh" ~/.zshrc_custom; then
    echo "source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" >> ~/.zshrc_custom
fi
if ! grep -q "zsh-syntax-highlighting.zsh" ~/.zshrc_custom; then
    echo "source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >> ~/.zshrc_custom
fi

# Mapping Ctrl + Left / Right Arrow untuk lompat per kata
if ! grep -q "backward-word" ~/.zshrc_custom; then
    cat << 'EOF' >> ~/.zshrc_custom

# Keybindings for Ctrl + Arrow navigation
bindkey '^[[1;5D' backward-word
bindkey '^[[1;5C' forward-word
bindkey '\e[1;5D' backward-word
bindkey '\e[1;5C' forward-word
EOF
    echo "[+] Zsh word navigation keybindings added."
fi

# Pastikan direktori config kitty ada
mkdir -p ~/.config/kitty

# Paksa kitty agar secara default selalu membuka zsh
if [ ! -f ~/.config/kitty/custom.conf ] || ! grep -q "shell zsh" ~/.config/kitty/custom.conf; then
    echo "shell zsh" >> ~/.config/kitty/custom.conf
    echo "[+] Kitty default shell configured to Zsh."
fi

# ==========================================
# 8. SYSTEM DEFAULT SHELL CONFIGURATION
# ==========================================
echo "[+] Configuring Zsh as the system default shell..."
if ! grep -Fxq "$(which zsh)" /etc/shells; then
    echo "$(which zsh)" | sudo tee -a /etc/shells
fi
sudo usermod -s "$(which zsh)" "$USER"

# ==========================================
# 9. SDDM NIER-AUTOMATA THEME INSTALLATION
# ==========================================
echo "[+] Installing and configuring NieR-Automata SDDM theme..."

if [ -f "nier-automata.tar.gz" ]; then
    sudo mkdir -p /usr/share/sddm/themes/nier-automata
    sudo tar -xzf nier-automata.tar.gz -C /usr/share/sddm/themes/nier-automata --strip-components=1
elif [ -d "nier-automata" ]; then
    sudo mkdir -p /usr/share/sddm/themes/nier-automata
    sudo cp -r nier-automata/* /usr/share/sddm/themes/nier-automata/
fi

sudo mkdir -p /etc/sddm.conf.d
sudo bash -c 'cat << 'EOF' > /etc/sddm.conf.d/theme.conf
[Theme]
Current=nier-automata
EOF'

sudo systemctl enable sddm.service
echo "[✓] SDDM theme nier-automata successfully configured!"

echo "[✓] Setup completed successfully! Please restart your terminal or reload Zsh."
