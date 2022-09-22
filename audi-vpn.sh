#!/bin/bash

#CONFIG
OVPN_ETC="/etc/openvpn"
OVPN_CNF="$OVPN_ETC/client/audired.ovpn"
OVPN_CREDENTIALS="$OVPN_ETC/credentials"
RDP_SERVER="172.17.0.221"
REMMINA=/usr/bin/remmina
REMMINA_CNF=$HOME/.local/share/remmina/audi.remmina

#FUNCIONES
ask_root_pass(){
	zenity --info --title="Permiso para configurar la computadora" --width=250 --ok-label="Aceptar" --text="Te vamos a solicitar la contraseña que usaste para ingresar en la computadora. Esto nos va a permitir configurar todo para que puedas conectarte a la VPN de Audired"	

while true; do
	while [ ! $ROOT_PASS ]; do
		ROOT_PASS=$(zenity --password --title="Contraseña" --width=250 --ok-label="Aceptar" --cancel-label="Cancelar" --text="Introducí la contraseña de la computadora:")
	done

	echo $ROOT_PASS |sudo -S true
	if sudo -n true ; then
		break
	else
		zenity --info --window-icon=error --title="Permiso para configurar la computadora" --width=250 --ok-label="Aceptar" --text="La contraseña que ingresaste no funcionó"
		ROOT_PASS=$(zenity --password --title="Contraseña" --width=250 --ok-label="Aceptar" --cancel-label="Cancelar" --text="Introducí la contraseña de la computadora:")
	fi
done
}

ask_continue(){
zenity --question --title="Configuración VPN AudiRED - Confirmación" --width=250 --text="Necesitamos tu usuario y contraseña de la VPN. ¿Seguro querés continuar?:" --window-icon="question" --ok-label="Aceptar" --cancel-label="Cancelar"

	if [ $? -eq 1 ]; then
		exit 0
	fi
}

ask_user(){
user=$(zenity --entry --title="Conexión VPN AudiRED - Usuario" --width=250 --ok-label="Aceptar" --cancel-label="Cancelar" --text="¿Cuál es tu nombre de usuario de la VPN?")
}

ask_pass(){
pass=$(zenity --password --title="Conexión VPN AudiRED - Contraseña" --width=250 --ok-label="Aceptar" --cancel-label="Cancelar" --text="Introduce la contraseña de la VPN:")
}

ask_select_config(){
zenity --question --title="Configuración VPN AudiRED - Configuracion" --width=250 --text="Te vamos a pedir la configuración de la VPN. ¿Seguro querés continuar?:" --window-icon="question" --ok-label="Aceptar" --cancel-label="Cancelar"

	if [ $? -eq 1 ]; then
		exit 0
	fi
}

add_config(){
file=$(zenity --file-selection --title="Configuración VPN AudiRED" --height=200 --width=100 --text="Selecciona el archivo de configuración (*.ovpn)" --file-filter="*.ovpn")
}

config_remmina(){
	echo "$user\n$pass" | $REMMINA --update-profile $REMMINA_CNF --set-option username --set-option resolution_mode=2 --set-option password --set-option server=$RDP_SERVER
}

runconfig(){
while [ -z $user -a -z $pass ]; do
	ask_continue
	ask_user
	ask_pass
done

echo -e "$user\n$pass" | sudo tee $OVPN_CREDENTIALS

while [ ! $file ]; do
	ask_select_config
	add_config
done

sudo sed -i 's/auth-user-pass/auth-user-pass \/etc\/openvpn\/credentials/g' /etc/openvpn/credentials

config_remmina
}

run_vpn(){
	sudo service openvpn stop audired
	sudo service openvpn start audired
}

check_vpn(){
	netcat -z $RDP_SERVER 3389

	if [ $? ! -eq 0 ]; then
		echo "no contesta la vpn o el servidor rdp"
		exit 0
	fi
}

run_rdp(){
	echo $REMMINA -c $REMMINA_CNF
}


display_connect(){
if [ -e $OVPN ]; then
	zenity --question --title="Conexión VPN AudiRED" --width=250 --text="Elegí una opción:" --window-icon="question" --ok-label="Iniciar conexión VPN" --cancel-label="Cancelar"

	if [ $? -eq 0 ]; then
		run_vpn
		check_vpn
		run_rdp
	else
		exit 0
	fi
fi
}

display_connect_or_config(){
	zenity --question --title="Conexión VPN AudiRED" --width=250 --text="Elegí una opción:" --ok-label="Iniciar conexión VPN" --cancel-label="Volver a configurar VPN"

	if [ $? -eq 0 ]; then
		display_connect
	else
		runconfig
	fi
}


#Base del codigo
while [ ! $ROOT_PASS ]; do
	ask_root_pass
done

while [ ! -e $OVPN_CNF -a ! -e $OVPN_CREDENTIALS ]; do
	runconfig
done

if [ -e $OVPN ]; then
	display_connect_or_config
fi
