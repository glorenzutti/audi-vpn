#!/bin/bash
# Esto es un script que hay que correr al momento de dar de alta un equipo para el trabajo remoto. Realiza las siguientes tareas:
# 1. Se trae el git del repositorio del script
# 2. Instala en anydesk
# 3. Configura la red para que funcione la VPN
# 4. Evita que se actualice el openvpn y el kernel
# 5. Configura el SUDO para que el usuario pueda configurar la vpn y conectarse
# 6. Configura el CRON para que se actualice el script de conexión a la VPN
# PENDIENTE:
# 1. Agregar modulo kernel placa wifi y sonido

USUARIO=audired

if [ test ! -d /home/$USUARIO ]; then
	echo "no encuentro el home del usuario $USUARIO!"
	exit 1
fi	

if [[ $EUID -ne 0 ]]; then
	echo "Ejecutar como root"
	exit 1
fi

test ! -x /usr/bin/git && apt install git


install_anydesk(){
        apt install libgtkglext1 libpangox-1.0-0
        wget https://download.anydesk.com/linux/anydesk_6.2.0-1_amd64.deb
        dpkg -i anydesk_6.2.0-1_amd64.deb
        sudo dpkg -i anydesk_6.2.0-1_amd64.deb
        rm anydesk_6.2.0-1_amd64.deb
}

edit_sysctl(){
	SYSCTL="/etc/sysctl.conf"
        grep -qxF 'net.ipv6.conf.all.disable_ipv6=1' $SYSCTL || echo 'net.ipv6.conf.all.disable_ipv6=1' | sudo tee $SYSCTL
        grep -qxF 'net.ipv6.conf.default.disable_ipv6=1' $SYSCTL || echo 'net.ipv6.conf.default.disable_ipv6=1' | sudo tee $SYSCTL
        grep -qxF 'net.ipv6.conf.lo.disable_ipv6=1' $SYSCTL || echo 'net.ipv6.conf.lo.disable_ipv6=1' | sudo tee $SYSCTL
        sudo sysctl -p
}

hold_packages(){
	apt-mark hold linux-image-5.13.0-44-generic
	apt-mark hold openvpn
}

config_sudo(){
	mv /home/$USUARIO/audi-vpn/audired-sudoers /etc/sudoers.d/
}

config_cron(){
	echo "git clone https://github.com/glorenzutti/audi-vpn" > /etc/cron.hourly/audi-vpn
	chmod 755 /etc/cron.hourly/audi-vpn
}

if [ -x /usr/bin/git ]; then
	cd /home/$USUARIO/
	git clone https://github.com/glorenzutti/audi-vpn
	install_anydesk
	edit_sysctl
	hold_packages
	config_sudo
	config_cron
fi
