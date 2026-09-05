#!/bin/bash
PCID="0000:05:00.6"

echo "🔄 1. Mematikan layanan audio agar tidak mengunci device..."
systemctl --user stop wireplumber pipewire pipewire-pulse

echo "🔌 2. Mencabut Audio Device secara Virtual..."
sudo sh -c "echo 1 > /sys/bus/pci/devices/$PCID/remove"

sleep 2

echo "🔋 3. Mencolok Audio Device kembali (Rescan)..."
sudo sh -c "echo 1 > /sys/bus/pci/rescan"

sleep 3

echo "🔄 4. Menyalakan kembali PipeWire..."
systemctl --user start pipewire pipewire-pulse wireplumber

sleep 2

echo "🎚️ 5. Menormalkan semua Mic Boost dan Capture ke nilai aman..."
# Melakukan iterasi ke seluruh card ALSA yang aktif secara otomatis tanpa hardcode -c 2
for card in /proc/asound/card[0-9]*; do
    if [ -d "$card" ]; then
        card_id=$(basename "$card" | tr -d 'card')
        
        # Turunkan semua jenis boost yang ada menjadi 0%
        amixer -c "$card_id" set "Headset Mic Boost" 0 2>/dev/null || true
        amixer -c "$card_id" set "Internal Mic Boost" 0 2>/dev/null || true
        amixer -c "$card_id" set "Mic Boost" 0 2>/dev/null || true
        
        # Atur capture utama ke level aman (misal 50%)
        amixer -c "$card_id" set "Capture" 50 2>/dev/null || true
    fi
done

echo "✅ Selesai! Semua mic boost dinormalkan, bebas noise, dan siap digunakan."
