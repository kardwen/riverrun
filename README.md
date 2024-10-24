# Riverrun

Alpine Linux and River setup notes

## Introduction

Riverrun provides a setup guide for configuring Alpine Linux with the River window compositor. 
Mostly personal notes and some scripting, work in progress

In every subdirectory is a file called `locations` that contains paths for the directory contents.
The script `sync-files` is a preliminary solution for syncing files, do **not** blindly run it.

TODO Split in different branches for different devices

## Installation medium

Download extended version of Alpine Linux for your architecture at <https://alpinelinux.org/downloads/>

<https://docs.alpinelinux.org/user-handbook/0.1a/Installing/setup_alpine.html>

### Windows

[USBWriter](https://sourceforge.net/projects/usbwriter/)

If you can't mount it under Windows use ``diskpart`` to wipe it (if diskpart complains, boot a Linux live distro and use fdisk or try a proprietary partition manager for Windows)

### Linux

```sh
dd bs=4M if=path/to/alpine.iso of=/dev/disk/by-id/usb-My_flash_drive conv=fsync oflag=direct status=progress
```

### MacOS

<https://wiki.archlinux.org/title/USB_flash_installation_medium#In_macOS_2>

```terminal
diskutil list
diskutil unmountDisk /dev/diskX
dd if=path/to/alpine.iso of=/dev/rdiskX bs=1m status=progress
```

## Alpine Linux Installation

Note that the partitioning step currently requires to reboot several times which means that all configuration is lost. Until this issue is resolved it is a good idea to skip setup steps that are not stricly necessary to avoid having to repeat steps frequently.

Login as root (no password set)

<https://docs.alpinelinux.org/user-handbook/0.1a/Installing/manual.html>

### Keyboard layout

```sh
    setup-keymap ch ch

    setup-hostname alpine201
    vi /etc/hosts
```

### Set hostname

``/etc/hosts``

```text
127.0.0.1 localhost.localdomain localhost alpine.localdomain alpine201
::1       localhost.localdomain localhost alpine.localdomain alpine201
```

```sh
rc-service hostname restart
```

### Networking

Netwoking can be set up with ``setup-interfaces`` either for a LAN connection or wireless with wpa_supplicant.

```sh
setup-interfaces
rc-service networking start
rc-update add networking boot
```

Advanced setup can be done once a connection has been established.

```sh
apk add openresolv
apk add ifupdown-ng
apk add dhcpcd
rc-update add dhcpcd
```

copy dhcpcd config to ``/etc/dhcpcd.conf``

<https://datatracker.ietf.org/doc/html/rfc2131#section-2.2>

#### Wi-Fi

When you need to configure wlan with `iwd` you first have to use wpa_supplicant because iwd is not included. Also remember to remove its service and to delete the old configuration in `/etc/wpa_supplicant` after installing iwd.

```
rc-update del wpa_supplicant boot
```

```sh
apk add dbus iwd
rc-service dbus start
rc-update add dbus boot
rc-service iwd start
rc-update add iwd default
```

<https://wiki.alpinelinux.org/wiki/Iwd>

```sh
iwctl

device list
device <device> set-property Powered on
adapter <adapter> set-property Powered on
station <device> scan
station <device> get-networks
station <device> connect <SSID>
station list
```

Troubleshooting

```sh
apk add pciutils
lspci -k # list devices
ip link # list interfaces
dmesg | grep ipw2200
```

lspci -k should list your wifi interface and a kernel driver for it below

#### IBM Thinkpad x40

https://wiki.archlinux.org/title/Network_configuration/Wireless
https://wireless.wiki.kernel.org/en/users/drivers
https://wireless.wiki.kernel.org/en/users/drivers/ipw2200

it seems that the driver is not loaded correctly, solution:

https://gitlab.alpinelinux.org/alpine/aports/-/issues/8873

    curl -L -o /lib/firmware/ipw2200-bss.fw 'https://github.com/Jolicloud/linux-firmware/blob/master/ipw2200-bss.fw?raw=true'

ipw2200 does not work together with `iwd` or `iw` and can be configured with `wireless-tools` instead:

    apk add wireless-tools
    iwconfig eth1
    iwconfig eth1 power on # power saving setting
    iwlist eth1 scan
    iwconfig eth1 essid <your_essid> key s:<your_key>

iwd gui: [Impala](https://github.com/pythops/impala)

``/etc/network/interfaces``

```text
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp

auto wlan0
iface wlan0 inet dhcp
```

Relogin

Network configurations can be found under ``/var/lib/iwd`` and certificates should be stored in ``/usr/local/share/ca-certificates``

An example configuration for setting up eduroam with iwd can be found in `./eduroam-iwd`, more on this in the Arch wiki

### Time settings

```sh
apk add tzdata
install -Dm 0644 /usr/share/zoneinfo/Europe/Berlin /etc/zoneinfo/Europe/Berlin
export TZ='Europe/Berlin'
echo "export TZ='$TZ'" >> /etc/profile.d/timezone.sh

setup-apkrepos

passwd

setup-sshd
```

(allow root)

Network Time Protocol (NTP)

```sh
apk add chrony
```

Replace default config in ``/etc/chrony/chrony.conf``

```sh
rc-service chronyd start
rc-update add chronyd
```

Log-in via SSH

```sh
ssh root@alpine201
```

### Partitioning

Instructions for using a GPT partioning scheme on a BIOS system

<https://docs.alpinelinux.org/user-handbook/0.1a/Installing/manual.html#_partitioning_your_disk>
<https://wiki.alpinelinux.org/wiki/Installing_on_GPT_LVM>

The following command will delete everything on ``/dev/sda``, so make sure to replace it with the correct drive!

```sh
apk add gptfdisk sgdisk

sgdisk -o /dev/sda \
    -n 1:0:+2M -t 1:ef02 -c 1:"BIOS boot partition" \
    -n 2:0:+100M -t 2:8300 -c 2:"Linux filesystem" \
    -n 3:0:0 -t 3:8300 -c 3:"Alpine Linux"

sgdisk --attributes=2:set:2 /dev/sda
```

Partition table:

```text
Number  Start (sector)    End (sector)  Size       Code  Name
1            2048            6143   2.0 MiB     EF02  BIOS boot partition
2            6144          210943   100.0 MiB   8300  Linux filesystem
3          210944       250069646   119.1 GiB   8E00  Alpine Linux
```

I had to reboot several times because this was not working, thus to repeat the previous setup

```sh
apk add e2fsprogs
mkfs.ext4 /dev/sda2
mkfs.ext4 /dev/sda3
```

reboot

```sh
mount /dev/sda3 /mnt
mkdir /mnt/boot
mount /dev/sda2 /mnt/boot

setup-disk -m sys /mnt

apk add syslinux
dd bs=440 count=1 conv=notrunc if=/usr/share/syslinux/gptmbr.bin of=/dev/sda
```

TODO Add instructions for uefi gpt

```sh
apk add btrfs-progs
modprobe btrfs
```

TODO Evaluate zfs filesystem and [zfsbootmenu](https://docs.zfsbootmenu.org/en/v2.3.x/)

### Configuration

```sh
adduser -h /home/felix -s /bin/ash felix
```

Install ``doas``, serves the same purpose as ``sudo``

```sh
apk add doas 
vi /etc/doas.conf
adduser felix wheel 
```

Copy ``/etc/doas.conf``

Disallow logging in as root via SSH:

```sh
vi /etc/ssh/sshd_config
```

Log-in as user via SSH:

```sh
groups # wheel should have been added
ssh -l felix alpine201
```

You can still login as root via SSH with ``su -``

Add the [community repository](https://wiki.alpinelinux.org/wiki/Repositories) to ``/etc/apk/repositories``

```text
http://dl-cdn.alpinelinux.org/alpine/edge/main
http://dl-cdn.alpinelinux.org/alpine/edge/community
```

Upgrade

```sh
apk update
apk upgrade --available
```

```sh
apk add gcompat
```

### Fonts

```sh
apk add font-terminus font-inconsolata font-dejavu font-noto font-noto-cjk font-awesome font-noto-extra
apk add adwaita-icon-theme font-dejavu
```

<https://wiki.alpinelinux.org/wiki/Fonts>

### Graphic drivers

#### Intel Thinkpad x201s

```sh
apk add mesa-dri-gallium
apk add mesa-va-gallium
apk add libva-intel-driver
```

```sh
apk add mesa-dri-gallium
apk add mesa-va-gallium
apk add libva-media-driver
```

<https://wiki.alpinelinux.org/wiki/Intel_Video>

## River

### Session

```sh
apk add seatd libseat
rc-service seatd start
rc-update add seatd boot
adduser felix seat

apk add polkit
rc-update add polkit
rc-service polkit start

apk add mkrundir
```

```sh
apk add turnstile
rc-update add turnstiled
rc-service turnstiled start
```

Relogin

```sh
apk add river river-doc
```

Copy example init:

```sh
install -Dm0755 /usr/share/doc/river/examples/init -t ~/.config/river
```

You can also find my init script under `./river/init`, note that it uses a German keyboard layout and remaps Caps Lock to Esc.
You can exit river with Super+Shift+E or switch to a different tty with Strg+Alt+F1

List input devices like touchpad etc:

```sh
riverctl list-inputs
```

Install foot as terminal emulator (Can be launched with ctrl + shift + enter)

```sh
apk add foot
```

Copy the script under ``./riverrun/riverrun`` for starting river to ``/usr/local/bin/riverrun``and execute it by typing ``riverrun``.

### Statusbar

```sh
apk add yambar
```

TODO Replace yambar

<https://git.sr.ht/~justinesmithies/dotfiles>

```
apk add nerd-fonts-all
apk add font-awesome  # maybe
```

Copy yambar config

### Wallpaper

```sh
apk add wbg
riverctl spawn 'wbg ~/path/to/image'
```

### Notifications

[mako](https://github.com/emersion/mako) for displaying notifications, [fyi](https://codeberg.org/dnkl/fyi) for sending

```sh
apk add mako
notify-send -t 9000 "hello world!"  # test notifications
apk add fyi
```

### Screenshots

[wayshot](https://github.com/waycrate/wayshot)

```sh
apk add wayshot
apk add wl-clipboard
```

Make a screenshot and copy it to the clipboard: Super + Shift + S

### Power Management

TODO Setup automatic shutdown on low battery levels

```sh
apk add acpid zzz
rc-update add acpid
rc-service acpid start
```

Default configuration is located in ``/etc/acpid/handler.sh``

```sh
apk add tlp
rc-update add tlp && rc-service tlp start
```

``/etc/tlp.conf``

TODO Thinkpad x201 requires ``tp-smapi``
<https://github.com/linux-thinkpad/tp_smapi> for setting charge thresholds.

Idle management:

```sh
apk add swayidle
```

TODO Configure backlight dimming and standby

### Application launcher

[tofi](https://github.com/philj56/tofi)

```sh
apk add tofi
```

Str + R starts `tofi` to search for desktop entries

### Desktop entries

Application entries are located in `/usr/share/applications`, `/usr/local/share/applications` or `~/.local/share/applications (<https://wiki.archlinux.org/title/Desktop_entries#Application_entry>)

### Default applications

Add `~/.config/mimeapps.list`

```sh
xdg-mime query default image/png
xdg-open some-image.png
```

### Resolution and scale

```sh
addgroup <user> audio
```

```sh
apk add waylock brightnessctl
rc-update add brightnessctl
apk add wlr-randr
```

Run ``wlr-randr`` to find outputs

```text
wlr-randr --output <output> --on --preferred --scale 1
```

```sh
apk add wlopm kanshi
```

Turn displays on and off with wlopm

kanshi for creating profiles

TODO Add kanshi configurations

[kanshi](https://sr.ht/~emersion/kanshi/)

### Day/night screen adjustments

```sh
apk add wlsunset
wlsunset -L 8 -l 52
pkill -f wlsunset
```

The alias `night` is defined for `zsh`

Dark mode switching

```sh
gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita'
gsettings set org.gnome.desktop.interface color-scheme 'default'
```

### Login manager

Simple login manager to automatically start River

```sh
apk add greetd
apk add greetd-agreety

rc-update add greetd

doas nvim /etc/greetd/config.toml
```

<https://man.sr.ht/~kennylevinsen/greetd/#how-to-set-xdg_session_typewayland>

### Device manager

```sh
apk add --quiet eudev udev-init-scripts udev-init-scripts-openrc
rc-update add --quiet udev sysinit
rc-update add --quiet udev-trigger sysinit
rc-update add --quiet udev-settle sysinit
rc-update add --quiet udev-postmount default
rc-service --ifstopped udev start
rc-service --ifstopped udev-trigger start
rc-service --ifstopped udev-settle start
rc-service --ifstopped udev-postmount start
```

TODO Add rules for auto mounting

### Thunderbolt

<https://wiki.archlinux.org/title/Thunderbolt#Automatically_connect_any_device>

#### USB drives

Mount usb drive

```sh
apk add udisks2
udisksctl mount -b /dev/sdb1
udisksctl unmount -b /dev/sdb1
```

### Filesystem support

```sh
apk add btrfs-progs dosfstools exfatprogs ntfs-3g
```

### Fingerprint reader

TODO Add configuration

<https://wiki.archlinux.org/title/Fprint>

```
lsusb
apk add fprintd
```

### File manager

Thunar and plugins

```sh
apk add thunar thunar-archive-plugin
apk add thunar-volman thunar-media-tags-plugin
apk add font-manager-thunar
apk add gvfs sshfs gvfs-smb gvfs-afc gvfs-gphoto2 gvfs-mtp gvfs-nfs
```

Terminal file manager

```sh
apk add lf
```

TODO Complete lf configuration

### Audio

```sh
apk add superd
apk add pipewire
addgroup <user> audio
apk add wireplumber
apk add pipewire-pulse
apk add pipewire-alsa
apk add pipewire-jack
apk add xdg-desktop-portal-wlr
apk add alsa-utils alsa-lib alsaconf
apk add pamixer
apk add pavucontrol
apk add pipewire-spa-bluez
apk add bluez-alsa
```

[superd](https://sr.ht/~craftyguy/superd/) is a process supervisor that can be used with openRC because openRC does not have the concept of user services.

Get superd services from <https://git.sr.ht/~whynothugo/superd-services> and copy them to ``/etc/superd/services``

Started in riverrun

```sh
wpctl status
```

Realtime sheduling

```sh
apk add rtkit
addgroup <user> rtkit
```

Audio visualizer

[cava](https://github.com/karlstav/cava)

```sh
apk add cava
```

[mpv](https://github.com/mpv-player/mpv)

```sh
apk add mpv
```

### Keymaps

The keyboard layout is set with `riverctl` in the River init file. For debugging `xkbcli` is a useful tool.

```sh
apk add xkbcli
xkbcli interactive-wayland
```

#### Notes

```sh
apk add pamixer # command line audio mixer
apk add playerctl
```

```sh
pactl list cards
```

Mac sound
<https://wiki.archlinux.org/title/IMac_Aluminum#The_imac7,1_model:>

```sh
nvim /etc/modprobe.d/sound.conf
echo options snd-hda-intel model=mb31 > /etc/modprobe.d/sound.conf
```

TODO Reevaluate for Alpine

Easy Effects

```sh
apk add easyeffects lsp-plugins
```

-> Settings -> Dark mode

Download plugins from <https://github.com/wwmm/easyeffects/wiki/Community-Presets>

```sh
curl -O --output-dir ~/.config/easyeffects/output/ "https://raw.githubusercontent.com/Digitalone1/EasyEffects-Presets/master/LoudnessEqualizer.json"
```

### System Monitoring

```sh
apk add htop

apk add lm-sensors lm-sensors-sensord lm-sensors-detect

apk add i2c_tools
doas modprobe i2c_dev
doas i2cdetect -l

doas sensors-detect
```

It is strongly advised to accept default answers when running ``sensors-detect``.
Answer yes for writing to ``/etc/modules-load.d/lm_sensors.conf``

```sh
apk del lm-sensors-detect

rc-update add sensord default
rc-service sensord start

sensors

apk add s-tui
s-tui
```

### Bluetooth

```sh
apk add bluez pipewire-spa-bluez
apk add bluetuith
modprobe btusb
rc-update add bluetooth
rc-service bluetooth start
adduser <user> lp

bluetoothctl
bluetuith
```

## Programs

Change the maximum number of failed login attemps (deny)

```sh
doas nvim /etc/security/faillock.conf
```

<https://gnulinux.ch/alpine-linux-als-desktop>

```sh
apk add intel-ucode
apk add linux-pam
```

### Editor

Neovim

```sh
apk add neovim
```

<https://github.com/folke/lazy.nvim>

Run `nvim` and enter `:Tutor` for a tutorial

### man pages

```sh
apk add mandoc man-pages mandoc-apropos docs
apk add coreutils-doc man-pages-posix
```

### Terminal emulator and alternative shell

bash

```sh
apk add bash
```

zsh

```sh
apk add zsh
apk add zsh-completions
apk add alpine-zsh-config
apk add zsh-syntax-highlighting
```
<https://zsh.sourceforge.io/Guide/zshguide02.html>

Copy `.zshrc`

`zsh` is set as default shell for foot in its ini file.

<https://wiki.alpinelinux.org/wiki/How_to_get_regular_stuff_working>

```sh
apk add coreutils
```

### PDF viewer

Zathura

```sh
doas apk add zathura
apk add zathura-cb
apk add zathura-djvu
apk add zathura-ps
apk add zathura-pdf-mupdf
```

### Firefox

```sh
apk add firefox
```

Profile location can be found by entering about:profiles in the adress bar

Adblock add-on
Edit start page
Edit menu bar

### Password manager

Copy `~/.gnupg/gpg-agent.conf`

[wayprompt](https://git.sr.ht/~leon_plickat/wayprompt), needs to be build from source, configuration file is included

```sh
gpgconf --reload gpg-agent
gpg --generate-key-full
```

https://www.passwordstore.org/

```sh
apk add pass qtpass
pass init <email>
```

Install Firefox extension passff
<https://addons.mozilla.org/de/firefox/addon/passff/>
<https://codeberg.org/PassFF/passff>

```sh
apk add passff-host
```

iOS App pass

<https://github.com/mssun/passforios>
<https://apps.apple.com/de/app/pass-password-store/id1205820573>

One-time-password

<https://github.com/tadfisher/pass-otp>

```sh
apk add pass pass-otp
apk add zbar
apk add imagemagick
zbarimg qr.png
```

### VPN

OpenConnect

```sh
apk add openconnect
modprobe vhost-net
doas sh -c 'printf "vhost-net\n" > /etc/modules-load.d/vhost-net.conf'
```

An example for connecting to a VPN can be found in `./scripts/uni-vpn`

### Tex

```sh
apk add texlive-full
apk add biber
```sh

### git

```sh
apk add git lazygit tig

git config --global user.name <name>
git config --global user.email <e-mail>
```

https://docs.github.com/en/authentication/connecting-to-github-with-ssh/checking-for-existing-ssh-keys

### VS Code

Code OSS, like VS Code, but installing plugins is more complicated

```sh
apk add code-oss
```

### Misc

```sh
gimp inkscape
p7zip
asciiquarium
vlc
libreoffice
shellcheck
```

E-mail: aerc

```sh
apk add aerc
apk add w3m dante
```

```sh
apk add chromium
```

Image viewer:

[imv](https://git.sr.ht/~exec64/imv/)
[timg](https://github.com/hzeller/timg)

```sh
apk add imv
apk add timg
```

```sh
apk add xdg-desktop-portal xdg-desktop-portal-gtk xdg-desktop-portal-wlr
```

Additional editor Mousepad
```sh
apk add mousepad
```

### Flatpak

<https://wiki.alpinelinux.org/wiki/Flatpak> with <https://flathub.org/> repository

```sh
apk add flatpak
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
```

Updating:

```sh
doas flatpak update
```

#### Signal Desktop Messenger

<https://flathub.org/apps/org.signal.Signal>

```sh
flatpak install flathub org.signal.Signal
```

can be run with

```sh
flatpak run org.signal.Signal
```

alias `signal` defined in `~/.zshrc`

#### Firefox flathub version for playing DRM media

<https://flathub.org/apps/org.mozilla.firefox>

```sh
flatpak install flathub org.mozilla.firefox
flatpak run org.mozilla.firefox
```

<https://addons.mozilla.org/en-US/firefox/addon/ublock-origin/?utm_source=addons.mozilla.org&utm_medium=referral&utm_content=search>

Note that passff will not work with the flatpak version of firefox. Your profile can be found under `~/.var/app/org.mozilla.firefox/.mozilla/firefox`.

In `about:preferences#general` check "Play DRM-controlled content"

You can edit the name displayed by the app launcher by editing the desktop entry to distinguish it from the normal Firefox version. When copied to `$XDG_DATA_HOME/applications` it will take precedence over the original Flatpak desktop entry.

```sh
mkdir ~/.local/share/applications
cp /var/lib/flatpak/exports/share/applications/org.mozilla.firefox.desktop ~/.local/share/applications
nvim ~/.local/share/applications/org.mozilla.firefox.desktop
```

### Games

TODO Rewrite for Alpine

#### Retroarch

```sh
sudo pacman -Sy libretro-parallel-n64 libretro-bsnes
sudo pacman -Sy retroarch retroarch-assets-xmb
```

Copy ``retroarch.cfg`` to ``~/.config/retroarch/retroarch.cfg```. Settings for individual cores can only be edited, when a game ist started. To do so, set the key combination for opening the menu in the settings beforehand.

#### RMG N64

```sh
sudo pacman -Sy glfw-wayland
yay -Sy rmg
```

Start with ``RMG``

#### Ares

Nvidia Tesla does not support Vulkan, therefore only Super Nintento Entertainment System games will run smoothly with Ares. ``swiftshader-git`` is an alternative software renderer.

```sh
yay -Sy lib32-mesa
pacman -Sy vulkan-tools
yay -Sy vulkan-swrast
yay -Sy ares-emu
```

### VM

qemu

qemu-img create -f qcow2 image_file -o nocow=on 4G

qemu-system-x86_64 -cdrom win98.iso -boot order=d,menu=on -drive file=w98.qcow2 -m 512 -device sb16 -display sdl

nvim start_windows_98

sudo chmod +x start_windows_98

### XFCE themes

TODO Rewrite for Alpine and River

Fluent theme
<https://github.com/vinceliuice/Fluent-gtk-theme>

Fluent icons
<https://github.com/vinceliuice/Fluent-icon-theme.git>

## Devices

TODO Rewrite for Alpine

### Controller

```sh
yay -Sy game-devices-udev
```

8bitDo SN30 Pro
Connect in X mode (Start + X)

### Apple Remote (IR)

should work out of the box
<https://lwn.net/Articles/759188/>

#### Printing

<https://wiki.alpinelinux.org/wiki/Printer_Setup>

### TV

TODO Rewrite for Alpine

https://wiki.archlinux.org/title/DVB-T

```sh
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

## Tips and tricks

<https://docs.alpinelinux.org/user-handbook/0.1a/Working/openrc.html>

```sh
rc-update show -v
```

```sh
apk add libinput
libinput list-devices
riverctl list-inputs
```
