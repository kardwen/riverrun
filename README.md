# Riverrun

Alpine Linux and River setup

## Installation medium

Download extended version of Alpine Linux for your architecture at <https://alpinelinux.org/downloads/>

<https://docs.alpinelinux.org/user-handbook/0.1a/Installing/setup_alpine.html>

Windows

[USBWriter](https://sourceforge.net/projects/usbwriter/) if you can't mount it under Windows use ``diskpart`` to wipe it

Linux

    dd bs=4M if=path/to/alpine.iso of=/dev/disk/by-id/usb-My_flash_drive conv=fsync oflag=direct status=progress

MacOS

<https://wiki.archlinux.org/title/USB_flash_installation_medium#In_macOS_2>

```terminal
diskutil list
diskutil unmountDisk /dev/diskX
dd if=path/to/alpine.iso of=/dev/rdiskX bs=1m status=progress
```

## Alpine Linux

login as root (no password set)
Connect to LAN

<https://docs.alpinelinux.org/user-handbook/0.1a/Installing/manual.html>

    setup-keymap ch ch

    setup-hostname alpine201
    vi /etc/hosts

``/etc/hosts``

```{text}
127.0.0.1 localhost.localdomain localhost alpine.localdomain alpine201
::1       localhost.localdomain localhost alpine.localdomain alpine201
```

    rc-service hostname restart

    setup-interfaces -a
    rc-service networking start
    rc-update add networking boot

    apk add tzdata
    install -Dm 0644 /usr/share/zoneinfo/Europe/Berlin /etc/zoneinfo/Europe/Berlin
    export TZ='Europe/Berlin'
    echo "export TZ='$TZ'" >> /etc/profile.d/timezone.sh

    setup-apkrepos

    passwd

    setup-sshd

Network Time Protocol (NTP)

    setup-ntp
    apk add chrony

Replace default config in ``/etc/chrony/chrony.conf``

    rc-service chronyd start
    rc-update add chronyd

Log-in via SSH

### Partitioning

<https://docs.alpinelinux.org/user-handbook/0.1a/Installing/manual.html#_partitioning_your_disk>
<https://wiki.alpinelinux.org/wiki/Installing_on_GPT_LVM>

    apk add gptfdisk sgdisk

    sgdisk -o /dev/sda \
        -n 1:0:+2M -t 1:ef02 -c 1:"BIOS boot partition" \
        -n 2:0:+100M -t 2:8300 -c 2:"Linux filesystem" \
        -n 3:0:0 -t 3:8e00 -c 3:"Alpine Linux"

    sgdisk --attributes=2:set:2 /dev/sda


    Number  Start (sector)    End (sector)  Size       Code  Name
    1            2048            6143   2.0 MiB     EF02  BIOS boot partition
    2            6144          210943   100.0 MiB   8300  Linux filesystem
    3          210944       250069646   119.1 GiB   8E00  Alpine Linux

I had to reboot several times because this was not working, thus to repeat the previous setup

    apk add e2fsprogs btrfs-progs
    mkfs.ext4 /dev/sda2
    mkfs.ext4 /dev/sda3

reboot

    mount /dev/sda3 /mnt
    mkdir /mnt/boot
    mount /dev/sda2 /mnt/boot

    setup-disk -m sys /mnt

    apk add syslinux
    dd bs=440 count=1 conv=notrunc if=/usr/share/syslinux/gptmbr.bin of=/dev/sda

### Configuration

    adduser -h /home/felix -s /bin/ash felix

Install ``doas``

    apk add doas 
    vi /etc/doas.conf
    adduser felix -G wheel 

``/etc/doas.conf``

```
permit persist :wheel

permit nopass :wheel cmd /usr/sbin/zzz
permit nopass :wheel cmd /sbin/poweroff
permit nopass :wheel cmd /sbin/reboot

permit nopass felix cmd zzz
```

Disallow logging in as root via SSH:

    vi /etc/ssh/sshd_config

Log-in as user via SSH:

    groups # wheel should have been added
    ssh -l felix alpine201

You can still login as root via SSH with ``su -``

Add the [community repository](https://wiki.alpinelinux.org/wiki/Repositories)

``/etc/apk/repositories``

    http://dl-cdn.alpinelinux.org/alpine/edge/main
    http://dl-cdn.alpinelinux.org/alpine/edge/community

Upgrade

    doas apk update
    doas apk upgrade --available

    apk add gcompat

### Networking

    apk add openresolv
    apk add ifupdown-ng
    apk add dhcpcd

``/etc/dhcpcd.conf``

    # https://datatracker.ietf.org/doc/html/rfc2131#section-2.2
    noarp

    background

Wi-Fi

    apk add dbus iwd
    rc-service dbus start
    rc-update add dbus boot
    rc-service iwd start
    rc-update add iwd default

<https://wiki.alpinelinux.org/wiki/Iwd>

    iwctl

    device list
    device <device> set-property Powered on
    adapter <adapter> set-property Powered on
    station <device> scan
    station <device> get-networks
    station <device> connect <SSID>
    station list

<https://github.com/pythops/impala>

``/etc/network/interfaces``

    auto lo
    iface lo inet loopback

    auto eth0
    iface eth0 inet dhcp

    auto wlan0
    iface wlan0 inet dhcp

Relogin

Network configurations can be found under ``/var/lib/iwd`` and certificates should be stored in ``/usr/local/share/ca-certificates``

### Fonts

    apk add font-terminus font-inconsolata font-dejavu font-noto font-noto-cjk font-awesome font-noto-extra
    apk add adwaita-icon-theme font-dejavu

<https://wiki.alpinelinux.org/wiki/Fonts>

### Graphic drivers (Intel Thinkpad x201s):

    apk add mesa-dri-gallium
    apk add mesa-va-gallium
    apk add libva-intel-driver

### Session

    doas apk add seatd libseat
    doas rc-service seatd start
    doas rc-update add seatd boot
    doas adduser felix seat

    doas apk add polkit
    rc-update add polkit
    rc-service polkit start

    apk add mkrundir

Edit ``~/.profile`` to add

    export XDG_RUNTIME_DIR=$(mkrundir)

    apk add turnstile
    rc-update add turnstiled
    rc-service turnstiled start

relogin

### Device manager

    doas apk add alpine-conf
    doas setup-devd udev

### River

    apk add river river-doc

Copy example init:

    install -Dm0755 /usr/share/doc/river/examples/init -t ~/.config/river

```{ash}
apk add bemenu waylock brightnessctl
apk add wlr-randr
apk add thunar thunar-archive-plugin
```

Copy the script for starting river to ``/usr/local/bin/riverrun``and execute it by typing ``riverrun``.

### Statusbar

    apk add yambar

<https://git.sr.ht/~justinesmithies/dotfiles>

    apk add nerd-fonts-all

    apk add font-awesome  # maybe

### Power Management

    apk add acpid zzz
    doas rc-update add acpid && doas rc-service acpid start

Default configuration in ``/etc/acpid/handler.sh``

    apk add tlp
    rc-update add tlp && rc-service tlp start

``/etc/tlp.conf``

Thinkpad x201 requires ``tp-smapi``
<https://github.com/linux-thinkpad/tp_smapi> for setting charge thresholds. Not tested.

Idle management:

    apk add swayidle

swayidle also needs to be configured

### Login manager

Simple login manager to automatically start River

    apk add greetd
    apk add greetd-agreety

    doas addgroup greetd wheel

    doas nvim /etc/greetd/config.toml

<https://man.sr.ht/~kennylevinsen/greetd/#how-to-set-xdg_session_typewayland>

## Notes

git

    apk add git tig

    git config --global user.name
    git config --global user.email

    apk add code-oss firefox alacritty

### Services

<https://docs.alpinelinux.org/user-handbook/0.1a/Working/openrc.html>

    rc-update show -v

deactivate middle mouse button paste?

apk add libinput
libinput list-devices
riverctl list-inputs

### Tex

apk add texlive-full
apk add biber

### Audio

    apk add pipewire
    addgroup <user> audio
    apk add wireplumber
    apk add pipewire-alsa
    apk add pipewire-jack
    apk add pipewire-pulse
    apk add xdg-desktop-portal-wlr
    apk add alsa-utils alsa-lib alsaconf
    apk add pamixer
    apk add superd

Get superd services from <https://git.sr.ht/~whynothugo/superd-services> and copy them to ``/etc/superd/services``

TODO this should be run automatically when starting the session

    exec superd

    wpctl

### System Monitoring

    apk add htop

    apk add lm-sensors lm-sensors-sensord lm-sensors-detect

    apk add i2c_tools
    doas modprobe i2c_dev
    doas i2cdetect -l

    doas sensors-detect

It is strongly advised to accept default answers when running ``sensors-detect``.
Answer yes for writing to ``/etc/modules-load.d/lm_sensors.conf``

    apk del lm-sensors-detect

    rc-update add sensord default
    rc-service sensord start

    sensors

    apk add s-tui
    s-tui

### Bluetooth

apk add bluez
apk add bluetuith
modprobe btusb
rc-update add bluetooth
rc-service bluetooth start
adduser <user> lp

bluetoothctl
bluetuith

### Other

    apk add wlsunset

does not work

```{ash}
apk add intel-ucode
apk add linux-pam

apk add lf
apk add neovim
```

<https://gnulinux.ch/alpine-linux-als-desktop>

man pages

    doas apk add mandoc man-pages mandoc-apropos docs

zsh

    apk add bash zsh

#### PDF viewer

    doas apk add zathura
    apk add zathura-cb
    apk add zathura-djvu
    apk add zathura-ps
    apk add zathura-pdf-mupdf

#### USB drives

mount usb drive

    apk add udisks2
    udisksctl mount -b /dev/sdb1
    udisksctl unmount -b /dev/sdb1

#### Firefox

Profile location can be found by entering about:profiles in the adress bar, usually located in ``~/.mozilla/firefox/``

passwords:

key4.db
logins.json

Close firefox before copying files.

More information on <https://support.mozilla.org/en-US/kb/profiles-where-firefox-stores-user-data>

    doas nvim /etc/security/faillock.conf


### Resolution and scale

```bash
yay -Sy wlr-randr
```

Run wlr-randr to find outputs

```text
wlr-randr --output <<output>> --scale 2
```

Brightness control:

brightnessctl

### Apple Remote (IR)

<https://lwn.net/Articles/759188/>









stuff TODO


### Audio

```bash
sudo pacman -Sy realtime-privileges
sudo gpasswd -a <user> realtime
sudo pacman -Sy pamixer # command line audio mixer
sudo pacman -Sy playerctl
```

```bash
sudo nvim /etc/security/limits.d/<user>.conf
```

```text
<user> soft memlock 64
<user> hard memlock 128
```

According to Mac mini (Mid 2010) - Technical Specifications <https://support.apple.com/kb/SP585?viewlocale=en_US&locale=de_DE> outputing audio via Mini DisplayPort is not possible but it should work via HDMI (max 1920x1200). Can be confirmed by:

```bash
pactl list cards
```

### other

qt5-wayland
qt6-wayland


Night light

```bash
yay -Sy wlsunset
```

File manager

```bash
sudo pacman -Sy thunar thunar-volman thunar-archive-plugin thunar-media-tags-plugin
sudo pacman -Sy gvfs sshfs gvfs-smb gvfs-afc gvfs-gphoto2 gvfs-mtp gvfs-nfs
```

Terminal file manager

```bash
sudo pacman -Sy lf
```


```bash
sudo pacman -Sy chromium
sudo pacman -Sy firefox
```

```bash
sudo pacman -Sy cava
sudo pacman -Sy neofetch
sudo pacman -Sy htop
```

p7zip

```bash
sudo pacman -Sy vlc
```

Image viewer:
ristretto



notifications mako

wallpaper

wofi launcher?

```bash
sudo pacman -Sy xdg-desktop-prtal xdg-desktop-prtal-gtk xdg-desktop-portal-wlr
```

### Games

#### Controller

```bash
yay -Sy game-devices-udev
```

8bitDo SN30 Pro
Connect in X mode (Start + X)


#### Retroarch

```bash
sudo pacman -Sy libretro-parallel-n64 libretro-bsnes
sudo pacman -Sy retroarch retroarch-assets-xmb
```

Copy ``retroarch.cfg`` to ``~/.config/retroarch/retroarch.cfg```. Settings for individual cores can only be edited, when a game ist started. To do so, set the key combination for opening the menu in the settings beforehand.

#### RMG N64

```bash
sudo pacman -Sy glfw-wayland
yay -Sy rmg
```

Start with ``RMG``

#### Ares

Nvidia Tesla does not support Vulkan, therefore only Super Nintento Entertainment System games will run smoothly with Ares. ``swiftshader-git`` is an alternative software renderer.

```bash
yay -Sy lib32-mesa
pacman -Sy vulkan-tools
yay -Sy vulkan-swrast
yay -Sy ares-emu
```

#### Wine

wine wine-mono
wine-wow64 AUR

fuseriso
fuseiso <iso> <directory>
wine <exe>

#### VM

qemu

qemu-img create -f qcow2 image_file -o nocow=on 4G

qemu-system-x86_64 -cdrom win98.iso -boot order=d,menu=on -drive file=w98.qcow2 -m 512 -device sb16 -display sdl

nvim start_windows_98

sudo chmod +x start_windows_98



### TV

https://wiki.archlinux.org/title/DVB-T

```bash
wget http://www.sundtek.de/media/sundtek_netinst.sh
sudo sh sundtek_netinst.sh

/opt/bin/mediaclient -e
sudo /opt/bin/mediaclient --start
/opt/bin/mediaclient -D DVBT

yay -Sy linuxtv-dvb-apps w_scan_cpp

w_scan_cpp -ft -c <country_code> -L > dvb.xspf
vlc dvb.xspf

dvbtraffic
```

## Notes

Nouveau driver installation
mesa


Notifications
mako

Turn displays on and off with wlopm
yay -Sy wlopm

kanshi for creating profiles
sudo pacman -Sy kanshi

https://sr.ht/~emersion/kanshi/


Wallpaper
yay -Sy swww

swayidle can be used to for example lock the screen after some time idling

Firefox
Adblock add-on <https://addons.mozilla.org/firefox/downloads/file/4201108/adblocker_ultimate-3.8.14.xpi>
Edit start page
Edit symbols


```bash
pacman -Sy gimp inkscape
pacman -Sy p7zip
pacman -Sy asciiquarium
pacman -Sy htop
pacman -Sy neovim
pacman -Sy vlc
pacman -Sy libreoffice
pacman -Sy wine
```

thunderbird


### XFCE

Install Fluent theme
<https://github.com/vinceliuice/Fluent-gtk-theme>

```bash
git clone --depth=1 https://github.com/vinceliuice/Fluent-gtk-theme.git /tmp/Fluent_theme_tmp
chmod +x /tmp/Fluent_theme_tmp/install.sh
/tmp/Fluent_theme_tmp/install.sh -i apple
```

Fluent icons

```bash
git clone --depth=1 https://github.com/vinceliuice/Fluent-icon-theme.git /tmp/Fluent_icons_tmp
chmod +x /tmp/Fluent_icons_tmp/install.sh
/tmp/Fluent_icons_tmp/install.sh -a -d /usr/share/icons/ -r
```

Apply themes:
Settings -> Appearance -> Theme
Settings -> Appearance -> Symbols
Settings -> Window Manager

Desktop settings:
Change background
Single click for activation

Add starters to desktop

Change window manager shortcuts (Super + arrow keys)

Change panel color

Add schreibtisch anzeigen to panel

Disable desktop switching
Disable window rollup
Rename desktops and change desktop switcher

```bash
pacman -Sy redshift
sudo systemctl --user --global enable redshift-gtk.service
```

Replace ~/.face with 256x256 .png profile image

### Audio

Mac sound
<https://wiki.archlinux.org/title/IMac_Aluminum#The_imac7,1_model:>

```bash
nvim /etc/modprobe.d/sound.conf
echo options snd-hda-intel model=mb31 > /etc/modprobe.d/sound.conf
```

Easy Effects

```bash
pacman -Sy easyeffects lsp-plugins
```

-> Settings -> Dark mode

Download plugins from <https://github.com/wwmm/easyeffects/wiki/Community-Presets>

```bash
curl -O --output-dir ~/.config/easyeffects/output/ "https://raw.githubusercontent.com/Digitalone1/EasyEffects-Presets/master/LoudnessEqualizer.json"
```

### System maintenance

```bash
pacman -Sy gparted
yay -Sy btrfs-assistant snapper
```

TODO Setup snapshots

TODO setup brightness control later

iMac 24 disable sleep button
