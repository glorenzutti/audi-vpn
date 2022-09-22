#!/bin/bash

flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

flatpak install --user org.freedesktop.Platforma//21.08 -y --noninteractive
flatpak install --user org.freedesktop.Platform.openh264//2.3.0 -y --noninteractive
flatpak install --user flathub org.remmina.Remmina -y --noninteractive

#flatpak run --user org.remmina.Remmina
