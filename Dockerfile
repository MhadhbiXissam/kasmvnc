from ubuntu:22.04
env HOME /root
env DEBIAN_FRONTEND=noninteractive
env force_color_prompt=yes
env color_prompt=yes
env PS1='\[\e]0;\u@\h: \w\a\]${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
ENV PATH="/root/.local/bin/:${PATH}"
##################################################
#             Configure tzdata                   #
##################################################
# Set keyboard configuration to AZERTY (French)
run <<EOF
echo -n '
# KEYBOARD CONFIGURATION FILE
# Consult the keyboard(5) manual page.
XKBMODEL="pc105"
XKBLAYOUT="fr"
XKBVARIANT="azerty"
XKBOPTIONS=""
BACKSPACE="guess"
' > /etc/default/keyboard
EOF
# Set locale and language to English (US)
RUN apt-get update && apt-get install -y locales
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
RUN locale-gen
RUN update-locale LANG=en_US.UTF-8
# Set geographic zone to Europe/Paris
RUN apt-get install -y tzdata
RUN echo 'Europe/Paris' > /etc/timezone
RUN dpkg-reconfigure -f noninteractive tzdata
RUN apt-get update
RUN apt-get install -y --no-install-recommends software-properties-common kbd
run echo "export PS1=\"$PS1\"" >> /root/.bashrc 

##################################################
#              Setup Python                      #
##################################################
run apt install -y python-is-python3 python3-pip 
run /usr/bin/pip install virtualenv
run python -m virtualenv /opt/base
ENV PATH="/opt/base/bin:${PATH}"

##################################################
#                install linux                   #
##################################################
run apt install -y tree lsof sudo nano unzip   

##################################################
#           install kasmvnc                      #
##################################################
env VNC_USER="root"
env VNC_PW="123456"
env VNC_PORT 6080
env DISPLAY=:1
RUN apt-get update && apt install -y x11-apps wget libgomp1 libgbm1 libgl1 libpixman-1-0 libunwind8 libxcursor1 libxfixes3 libxfont2 libxrandr2 libxshmfence1 libxtst6 x11-xkb-utils xkb-data whois 
run wget http://ftp.de.debian.org/debian/pool/main/libw/libwebp/libwebp7_1.2.4-0.2+deb12u1_amd64.deb 
run dpkg -i libwebp7_1.2.4-0.2+deb12u1_amd64.deb 
run apt-get install -f && rm libwebp7_1.2.4-0.2+deb12u1_amd64.deb  
run apt --fix-broken install
run apt install -y xauth libwebp7 ssl-cert libswitch-perl libyaml-tiny-perl  libdatetime-timezone-perl liblist-moreutils-perl libhash-merge-simple-perl
run wget https://github.com/kasmtech/KasmVNC/releases/download/v1.3.0/kasmvncserver_bookworm_1.3.0_amd64.deb
run dpkg -i kasmvncserver_bookworm_1.3.0_amd64.deb 
run apt --fix-broken install
run rm kasmvncserver_bookworm_1.3.0_amd64.deb
run VNC_DIR="/root/.vnc" && mkdir -p "$VNC_DIR" && touch "$VNC_DIR/.de-was-selected"
RUN <<EOF
vnc_directory="$HOME/.vnc"
# delete old instalation : 
if [ -d $vnc_directory ]; then
  rm -rf $vnc_directory
  mkdir -p $vnc_directory
else
  mkdir -p $vnc_directory
fi
# prevenet tty from asking set up default desktop env 
touch $vnc_directory/.de-was-selected
SALT='$5$kasm$'
hashed_pw=$(mkpasswd -m descrypt "$VNC_PW" "$SALT")
passwd_file=$HOME/.kasmpasswd
echo "$VNC_USER:$hashed_pw:ow" > $passwd_file
chmod 600 $passwd_file
openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -keyout $vnc_directory/self.pem -out $vnc_directory/self.pem -subj /C=US/ST=VA/L=None/O=None/OU=DoFu/CN=kasm/emailAddress=none@none.none
echo -n "
network:
	protocol: http
	interface: 0.0.0.0
	websocket_port: $VNC_PORT
	use_ipv4: true
	use_ipv6: true
	udp:
		public_ip: auto
		port: auto
		stun_server: auto
	ssl:
		pem_certificate: $passwd_file
		pem_key: $passwd_file
		require_ssl: false

logging:
	log_writer_name: all
	log_dest: logfile
	level: 1
" > /root/.vnc/kasmvnc.yaml
EOF

##################################################
#           install code-server                  #
##################################################
expose 8000
run apt install -y curl 
env VSCODE_SETTINGS '{"workbench.colorTheme": "Monokai Pro", "workbench.iconTheme": "Monokai Pro Icons", "window.customTitleBarVisibility": "auto", "workbench.sideBar.location": "left", "files.autoSave": "afterDelay", "window.commandCenter": false, "workbench.layoutControl.enabled": false, "workbench.activityBar.location": "top", "workbench.panel.alignment": "justify", "python.defaultInterpreterPath": "/opt/base/bin/python", "jupyter.jupyterServerType": "local", "python.terminal.activateEnvInCurrentTerminal": true}'
run curl -fsSL https://code-server.dev/install.sh | sh
run code-server --install-extension monokai.theme-monokai-pro-vscode
run code-server --install-extension ms-python.python 
run code-server --install-extension ms-python.debugpy
run code-server --install-extension nimsaem.nimvscode
run mkdir -p /root/.config/code-server
run mkdir -p /root/.local/share/code-server/User
run mkdir -p $HOME/workspace
run echo $VSCODE_SETTINGS > /root/.local/share/code-server/User/settings.json





##################################################
#                startup script                  #
##################################################
run <<EOF
echo -n '#!/bin/bash
set -euo pipefail
code-server --bind-addr 0.0.0.0:8000  --auth none /root/workspace & 
' > /root/.vnc/xstartup && chmod 700 /root/.vnc/xstartup 
EOF



##################################################
#              entrypoint script                 #
##################################################
run <<EOF
echo -n '#!/bin/bash
set -euo pipefail
vncserver
tail -f /root/.vnc/*.log
' > /entrypoint.sh  && chmod +x /entrypoint.sh
EOF
entrypoint ["/entrypoint.sh"]