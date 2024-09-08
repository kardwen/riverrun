# Riverrun

Alpine Linux and River setup

Notes for setting up Alpine Linux with the River window compositor, work in progress


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

iwd gui: <https://github.com/pythops/impala>

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

An example configuration for setting up eduroam with iwd can be found in `/eduroam-iwd`, more on this in the Arch wiki

### Time

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

todo uefi gpt

    apk add btrfs-progs
    modprobe btrfs

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

Add the [community repository](https://wiki.alpinelinux.org/wiki/Repositories)

TODO add ``/etc/apk/repositories``

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

### Graphic drivers (Intel Thinkpad x201s):

```sh
apk add mesa-dri-gallium
apk add mesa-va-gallium
apk add libva-intel-driver
```

todo new intel graphics

```sh
apk add mesa-dri-gallium
apk add mesa-va-gallium
apk add libva-media-driver
```

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

#### USB drives

mount usb drive

```sh
apk add udisks2
udisksctl mount -b /dev/sdb1
udisksctl unmount -b /dev/sdb1
```

TODO add rules for auto mounting and video signals

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

TODO replace mkrundir (in testing repository) with pam-rundir

TODO

```sh
apk add turnstile
rc-update add turnstiled
rc-service turnstiled start
```

Relogin

```sh
apk add river river-doc
```

#### Configuration

Copy example init:

```sh
install -Dm0755 /usr/share/doc/river/examples/init -t ~/.config/river
```

or copy ``/river/init`` and adapt it,
you can exit river with Super+Shift+E

List input devices like touchpad etc:

```sh
riverctl list-inputs
```


Install alacritty as terminal emulator (Can be launched with ctrl + shift + enter)

```sh
apk add alacritty
```

Copy the script for starting river to ``/usr/local/bin/riverrun``and execute it by typing ``riverrun``.

### Statusbar

```sh
apk add yambar
```

<https://git.sr.ht/~justinesmithies/dotfiles>

    apk add nerd-fonts-all

    apk add font-awesome  # maybe

copy yambar config

### Desktop background image

```sh
apk add wbg
riverctl spawn 'wbg ~/path/to/image'
```

### Notifications

```sh
apk add mako
notify-send -t 9000 "hello world!"  # test notifications
```

### Screenshots

<https://github.com/waycrate/wayshot>

```sh
apk add wayshot
apk add wl-clipboard
```

Make a screenshot and copy it to the clipboard: Super + Shift + S

### Power Management

TODO setup automatic shutdown on low battery levels

```sh
apk add acpid zzz
rc-update add acpid
rc-service acpid start
```

Default configuration in ``/etc/acpid/handler.sh``

```sh
apk add tlp
rc-update add tlp && rc-service tlp start
```

``/etc/tlp.conf``

Thinkpad x201 requires ``tp-smapi``
<https://github.com/linux-thinkpad/tp_smapi> for setting charge thresholds. Not tested.

Idle management:

```sh
apk add swayidle
```

TODO
configure backlight dimming and standby

### Application launcher

```sh
apk add bemenu
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
wlr-randr --output <<output>> --scale 2
```

```sh
apk add wlsunset
```

todo configure

### Login manager

Simple login manager to automatically start River

```sh
apk add greetd
apk add greetd-agreety

rc-update add greetd

doas nvim /etc/greetd/config.toml
```

<https://man.sr.ht/~kennylevinsen/greetd/#how-to-set-xdg_session_typewayland>

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

TODO add configuration

filesystem support

```sh
apk add btrfs-progs dosfstools exfatprogs ntfs-3g
```

### Audio

```sh
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

#### Notes

```sh
apk add pamixer # command line audio mixer
apk add playerctl
```

```bash
pactl list cards
```

Mac sound
<https://wiki.archlinux.org/title/IMac_Aluminum#The_imac7,1_model:>

```bash
nvim /etc/modprobe.d/sound.conf
echo options snd-hda-intel model=mb31 > /etc/modprobe.d/sound.conf
```

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

## Notes

```sh
apk add intel-ucode
apk add linux-pam

apk add neovim
```

change deny configuration

```sh
doas nvim /etc/security/faillock.conf
```

<https://gnulinux.ch/alpine-linux-als-desktop>

### Add man pages

```sh
apk add mandoc man-pages mandoc-apropos docs
apk add coreutils-doc man-pages-posix
```

zsh

```zsh
apk add bash zsh
```

TODO

Turn displays on and off with wlopm

kanshi for creating profiles

https://sr.ht/~emersion/kanshi/

### Programs

TODO configure default applications

`~/.config/mimeapps.list`

```sh
gimp inkscape
p7zip
asciiquarium
neovim
vlc
libreoffice
wine
```

E-mail: aerc
todo replace with mutt

```sh
apk add aerc
```

#### PDF viewer

Zathura

```sh
doas apk add zathura
apk add zathura-cb
apk add zathura-djvu
apk add zathura-ps
apk add zathura-pdf-mupdf
```

#### Firefox

    apk add firefox

Profile location can be found by entering about:profiles in the adress bar, usually located in ``~/.mozilla/firefox/``

passwords:

key4.db
logins.json

Close firefox before copying files.

More information on <https://support.mozilla.org/en-US/kb/profiles-where-firefox-stores-user-data>

Adblock add-on
Edit start page
Edit menu bar

#### Password manager

```sh
apk add pinentry-gtk
```

todo there should be a better pinentry solution
copy ~/.gnupg/gpg-agent.conf

```sh
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
<https://apps.apple.com/de/app/pass-password-store/id1205820573>
<https://github.com/mssun/passforios>

#### Tex

```sh
apk add texlive-full
apk add biber
```sh

### git

```sh
apk add git tig

git config --global user.name <name>
git config --global user.email <e-mail>
```

https://docs.github.com/en/authentication/connecting-to-github-with-ssh/checking-for-existing-ssh-keys



#### VS Code

like VS Code, but installing plugins is more complicated

```sh
apk add code-oss
```

#### Misc

```sh
apk add chromium
```

```bash
apk add cava
```

Image viewer:
ristretto or imv
shellcheck

```sh
apk add xdg-desktop-portal xdg-desktop-portal-gtk xdg-desktop-portal-wlr
```

### Flatpak

<https://wiki.alpinelinux.org/wiki/Flatpak> with <https://flathub.org/> repository

```sh
apk add flatpak
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
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

alias `signal` defined in `~/.profile`

TODO find a good solution for sourcing .profile

#### Firefox flathub version for playing DRM media

<https://flathub.org/apps/org.mozilla.firefox>

```sh
flatpak install flathub org.mozilla.firefox
flatpak run org.mozilla.firefox
```

<https://addons.mozilla.org/en-US/firefox/addon/ublock-origin/?utm_source=addons.mozilla.org&utm_medium=referral&utm_content=search>

Note that passff will not work with the flatpak version of firefox. Your profile can be found under `~/.var/app/org.mozilla.firefox/.mozilla/firefox`.

In `about:preferences#general` check "Play DRM-controlled content"

### Games

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

### XFCE themes

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

### Services

<https://docs.alpinelinux.org/user-handbook/0.1a/Working/openrc.html>

```sh
rc-update show -v
```

apk add libinput
libinput list-devices
riverctl list-inputs

### Devices

#### Controller

```sh
yay -Sy game-devices-udev
```

8bitDo SN30 Pro
Connect in X mode (Start + X)

#### Apple Remote (IR)

should work out of the box
<https://lwn.net/Articles/759188/>
