#!/bin/bash

# This script will set gnome/KDE/shell proxy configuration for each SSID
# Version: 1.62
#
# Current script maintainer:
# - Julien Blitte            <julien.blitte at gmail.com>
#
# Authors and main contributors:
# - Berend Deschouwer        <berend.deschouwer at ucs-software.co.za>
# - Emerson Esteves          <ensss at users.sourceforge.net>
# - Ivan Gusev               <ivgergus at gmail.com>
# - Jean-Baptiste Masurel    <jbmasurel at gmail.com>
# - Julien Blitte            <julien.blitte at gmail.com>
# - Milos Pejovic            <pejovic at gmail.com>
# - Sergiy S. Kolesnikov     <kolesnik at fim.uni-passau.de>
# - Taylor Braun-Jones       <taylor@braun-jones.org>
# - Tom Herrmann             <mail at herrmann-tom.de>
# - Ulrik Stervbo            <ulrik.stervbo at gmail.com>
# - etc.

# neapovea@gmail.com preliminar changes to:
# changes to configure proxy in apt of debian
# changes to configure .bashrc on user directory
# changes to configure firefox, (comment, no are funtional)
# changes to configure proxy in subversion app.
# changes to configure proxy in docker app.
# include config to JetBrains IDE (need config idea.properties to set path of IDE and put this in /home/user/.PATH_APP),
#  In my case this path are: IntelliJIdea, PyCharm, AndroidStudio, IdeaIC, DataGrip


#
# To install this file, place it in directory (with +x mod):
# /etc/NetworkManager/dispatcher.d
#
# For each new SSID, after a first connection, complete the genreated file
# /etc/proxydriver.d/<ssid_name>.conf and then re-connect to AP, proxy is now set!
#

conf_dir='/etc/proxydriver.d'
log_tag='proxydriver'
running_device='/var/run/proxydriver.device'
proxy_env='/etc/environment'
apt_proxy='/etc/apt/apt.conf.d/01proxy'
svn_proxy=''
docker_proxy='/etc/init.d/docker'

firefox_profile=''



logger -p user.debug -t $log_tag "script called: $*"

# vpn disconnection handling
if [ "$2" == "up" ]
then
	echo "$1" > "$running_device"
elif [ "$2" == "vpn-down" ]
then
	set -- `cat "$running_device"` "up"
fi

if [ "$2" == "up" -o "$2" == "vpn-up" ]
then
	logger -p user.notice -t $log_tag "interface '$1' now up, will try to setup proxy configuration..."

	[ -d "$conf_dir" ] || mkdir --parents "$conf_dir"
	
	# Get the nmcli 'protocol'
	nmcli_protocol='undetected'
	if ! type -P nmcli &>/dev/null
	then
		# nmcli seems not installed or runnable
		mcli_protocol=0
	elif nmcli con status &> /dev/null
	then
		# probably nmcli prior to 0.9.10.0
		nmcli_protocol=1
	elif nmcli con show &> /dev/null
	then
		# probably nmcli 0.9.10.0 or higher
		nmcli_protocol=2
	else
		#nmcli is installed but I do not know how to communicate with it
		logger -p user.notice -t $log_tag "I don't understand nmcli version `nmcli --version` language"
		nmcli_protocol=-1
	fi
	logger -p user.notice -t $log_tag "nmcli protocol: $nmcli_protocol"

	case $nmcli_protocol in
	0)
		# try ESSID if nmcli is not installed
		logger -p user.notice -t $log_tag "nmcli not detected, will use essid"

		networkID=`iwgetid --scheme`
		[ $? -ne 0 ] && networkID='default'
	;;
	1)
		# retrieve connection/vpn name
		networkID=`nmcli -t -f name,devices,vpn con status | \
			awk -F':' "BEGIN { device=\"$1\"; event=\"$2\" } \
			event == \"up\" && \\$2 == device && \\$3 == \"no\" { print \\$1 } \
			event == \"vpn-up\" && \\$3 == \"yes\" { print \"vpn_\" \\$1 }"`
	;;
	2)
		# retrieve connection/vpn name
		# It appears a line with tun0:tun0:generic is created when I connect to VPN. No idea how to get rid of it
		networkID=`nmcli -t -f name,device,type con show --active | \
			awk -F':' "BEGIN { device=\"$1\"; event=\"$2\" } \
			event == \"up\" && \\$2 == device && \\$3 != \"vpn\" { print \\$1 } \
			event == \"vpn-up\" && \\$3 == \"vpn\" { print \"vpn_\" \\$1 }"`
	;;
	esac
	
	# we did not get solve network name
	[ -z "$networkID" ] && networkID='default'
	
	# strip out anything hostile to the file system
	networkID=`echo "$networkID" | tr -c '[:alnum:]-' '_' | sed 's/.$/\n/'`

	conf="$conf_dir/$networkID.conf"

	logger -p user.notice -t $log_tag "using configuration file '$conf'"

	if [ ! -e "$conf" ]
	then
		logger -p user.notice -t $log_tag "configuration file empty! generating skeleton..."

		touch "$conf"

		cat <<EOF > "$conf"
# configuration file for proxydriver
# file auto-generated, please complete me!

# ignore completly connection to this network
# (configuration from previous connection is preserved)
#skip='true'

# proxy active or not
enabled='false'

# proxy configuration is given by HTTP proxy auto-config (PAC)
# if used, remove comment char '#' at begin of the line
# autoconfig_url=''

# main proxy settings
# if not HTTP proxy auto-config
proxy='proxy.domain.com'
port=8080

# use same proxy for all protocols
same='true'

# protocols other than http
# if not proxy auto-config and if same is set to 'false'
https_proxy='proxy.domain.com'
https_port=8080
ftp_proxy='proxy.domain.com'
ftp_port=8080
socks_proxy='proxy.domain.com'
socks_port=8080

# authentication for Gnome
# for KDE, it is detected automaticaly
auth='false'
login='admin'
pass='pass'

# ignore-list
ignorelist='localhost,127.0.0.0/8,10.0.0.0/8,192.168.0.0/16,172.16.0.0/12'

EOF

		chown root:dip "$conf"
		chmod 0664 "$conf"

	fi

	# read configfile
	source "$conf"

	if [ "$skip" == 'true' -o "$skip" == '1' -o "$skip" == 'yes' ]
	then
		logger -p user.notice -t $log_tag "this configuration will be ignored."
		exit
	fi

	# select mode using enabled value
	if [ "$enabled" == 'true' -o "$enabled" == '1' -o "$enabled" == 'yes' ]
	then
		enabled='true'              # gnome enable
		kde_mode='1'                # kde fixed proxy
		if [ -n "$autoconfig_url" ]
		then
			gnome_mode='auto'   # gnome autoconfig
			kde_mode='2'        # kde autoconfig
		else
			gnome_mode='manual' # gnome manual
		fi
	else
		enabled='false'
		kde_mode='0'                # kde disabled
		gnome_mode='none'           # gnome disabled
	fi
	#kde_mode> 0: No proxy - 1: Manual - 2: Config url - 3: Automatic (DHCP?) - 4: Use env variables
	#gnome_mode> 'none': No proxy - 'manual': Manual - 'auto': Config url

	if [ "$same" == 'true' -o "$same" == '1' -o "$same" == 'yes' -o -z "$same" ]
	then
		same='true'
		https_proxy="$proxy"
		https_port="$port"
		ftp_proxy="$proxy"
		ftp_port="$port"
		socks_proxy="$proxy"
		socks_port="$port"
	fi

	if [ "$auth" == 'true' -o "$auth" == '1' -o "$auth" == 'yes' ]
	then	
		auth='true'
		shell_auth="$login:$pass@"
	else
		auth='false'
		login=''
		pass=''
		shell_auth=''
	fi

	ignorelist=`echo $ignorelist | sed 's/^\[\(.*\)\]$/\1/'`
	
	# gnome2 needs [localhost,127.0.0.0/8]
	# gnome3 needs ['localhost','127.0.0.0/8']
	# neither works with the other's settings
	quoted_ignorelist=`echo $ignorelist | sed "s/[^,]\+/'\0'/g"`
	gnome2_ignorelist="[${ignorelist}]"
	gnome3_ignorelist="[${quoted_ignorelist}]"
	
	# Gnome likes *.example.com; kde likes .example.com:
	kde_ignorelist=`echo "${ignorelist}" | sed -e 's/\*\./\./g'`

	# setup system environment variables
	logger -p user.notice -t $log_tag "update system variable environment configuration file " $proxy_env
	sed -i '/^\(https\?_proxy\|HTTPS\?_PROXY\|ftp_proxy\|FTP_PROXY\|all_proxy\|ALL_PROXY\|socks_proxy\|SOCKS_PROXY\|no_proxy\|NO_PROXY\)=/d' "$proxy_env"

	if [ "$enabled" == 'true' -a -z "$autoconfig_url" ]
	then
		echo "http_proxy='http://${shell_auth}${proxy}:${port}/'" >> "$proxy_env"
		echo "HTTP_PROXY='http://${shell_auth}${proxy}:${port}/'" >> "$proxy_env"
		echo "https_proxy='http://${shell_auth}${https_proxy}:${https_port}/'" >> "$proxy_env"
		echo "HTTPS_PROXY='http://${shell_auth}${https_proxy}:${https_port}/'" >> "$proxy_env"
		echo "ftp_proxy='http://${shell_auth}${ftp_proxy}:${ftp_port}/'" >> "$proxy_env"
		echo "FTP_PROXY='http://${shell_auth}${ftp_proxy}:${ftp_port}/'" >> "$proxy_env"
		echo "all_proxy='http://${shell_auth}${proxy}:${port}/'" >> "$proxy_env"
		echo "ALL_PROXY='http://${shell_auth}${proxy}:${port}/'" >> "$proxy_env"
		echo "socks_proxy='http://${shell_auth}${socks_proxy}:${socks_port}/'" >> "$proxy_env"
		echo "SOCKS_PROXY='http://${shell_auth}${socks_proxy}:${socks_port}/'" >> "$proxy_env"
	 	echo "no_proxy='${ignorelist}'" >> "$proxy_env"
	 	echo "NO_PROXY='${ignorelist}'" >> "$proxy_env"
	fi

	if [ "$enabled" == 'false' ]
	then
		unset http_proxy
		unset HTTP_PROXY
		unset https_proxy
		unset HTTPS_PROXY
		unset ftp_proxy
		unset FTP_PROXY
		unset all_proxy
		unset ALL_PROXY
		unset socks_proxy
		unset SOCKS_PROXY
	 	unset no_proxy
	 	unset NO_PROXY
	fi

	#docker
	logger -p user.notice -t $log_tag "update docker configuration to set proxy"
	if [ -f "$docker_proxy" ]; then

		mkdir -p /etc/systemd/system/docker.service.d
		
		docker_proxy_file='/etc/systemd/system/docker.service.d/http-proxy.conf'

		if [ -f "$docker_proxy_file" ]; then
			sed -i '/[Service]/d' "$docker_proxy_file"
			sed -i '/\(HTTPS\?_PROXY\|no_proxy\|NO_PROXY\)=/d' "$docker_proxy_file"
		fi

		if [ "$enabled" == 'true' -a -z "$autoconfig_url" ]
		then
			echo "[Service]" >> "$docker_proxy_file"
			echo 'Environment="HTTP_PROXY=http://'${shell_auth}${proxy}:${port}'/" "HTTPS_PROXY=http://'${shell_auth}${https_proxy}:${https_port}/'"' >> "$docker_proxy_file"			
		fi


		
#/etc/systemd/system/docker.service.d/http-proxy.conf
# [Service]
# Environment="HTTP_PROXY=http://proxy.example.com:80/"
# Or, if you are behind an HTTPS proxy server, create a file called /etc/systemd/system/docker.service.d/https-proxy.conf that adds the HTTPS_PROXY environment variable:
# [Service]
# Environment="HTTPS_PROXY=https://proxy.example.com:443/"
# If you have internal Docker registries that you need to contact without proxying you can specify them via the NO_PROXY environment variable:
# [Service]    
# Environment="HTTP_PROXY=http://proxy.example.com:80/" "NO_PROXY=localhost,127.0.0.1,docker-registry.somecorporation.com"
# Or, if you are behind an HTTPS proxy server:
# [Service]    
# Environment="HTTPS_PROXY=https://proxy.example.com:443/" "NO_PROXY=localhost,127.0.0.1,docker-registry.somecorporation.com"


	fi

	#apt
	logger -p user.notice -t $log_tag "update apt configuration to set proxy"
	if [ -f "$apt_proxy" ]
	then
		sed -i '/Acquire::http::Proxy/d' "$apt_proxy"
	fi

	if [ "$enabled" == 'true' ]
	then
		#Acquire::http::Proxy "http://proxy.sc.sas.junta-andalucia.es:8080";
		echo 'Acquire::http::Proxy "http://'${shell_auth}${proxy}:${port}'";' >> "$apt_proxy"
	fi


# io@:~$ git config --global -l
# git config --global http.proxy http://proxyuser:proxypwd@proxy.server.com:8080


	# wait if no users are logged in (up to 5 minutes)
	connect_timer=0
	while [ -z "$(users)" -a $connect_timer -lt 300 ]
	do
		let connect_timer=connect_timer+10
		sleep 10
	done
	
	# a user just logged in; give some time to settle things down
	if [ $connect_timer -gt 0 -a $connect_timer -lt 300 ]
	then
		sleep 15
	fi

	machineid=$(dbus-uuidgen --get)
	for user in `users | tr ' ' '\n' | sort --unique`
	do
		logger -p user.notice -t $log_tag "setting configuration for '$user'"


		#git
#		logger -p user.notice -t $log_tag "update git configuration to set proxy"
#		git_proxy=/home/$user/.gitconfig
#		if [ -f "$git_proxy" ]
#		then
#		fi
# 		git config --global http.proxy http://proxyuser:proxypwd@proxy.server.com:8080
# 		git config --global --unset http.proxy
# 		git config --global --get http.proxy

# [http]
# 	proxy = http://proxyuser:proxypwd@proxy.server.com:8080

		ficheroProxySettingJetBrains='proxy.settings.xml'

# configure app to have config dir in /home/user/xxxx and put config dirs names in for loop 
		for tblTMP in "IntelliJIdea" "PyCharm" "AndroidStudio" "IdeaIC" "DataGrip"
		do

			logger -p user.notice -t $log_tag 'update '$tblTMP' configuration to set proxy'

			rutaConfigruacionJetBrains=/home/$user/.$tblTMP/config/options/

			ficheroProxyTmp=$rutaConfigruacionJetBrains$ficheroProxySettingJetBrains
			
#			echo $ficheroProxyTmp

			if [ -d "$rutaConfigruacionJetBrains" ]
			then
				if [ -f "$ficheroProxyTmp" ]
				then
					rm $ficheroProxyTmp
				fi
				if [ "$enabled" == 'true' ]
				then
					echo '<application>' >> "$ficheroProxyTmp"
					echo '  <component name="HttpConfigurable">' >> "$ficheroProxyTmp"
					echo '    <option name="USE_HTTP_PROXY" value="true" />' >> "$ficheroProxyTmp"
					echo '    <option name="PROXY_HOST" value="'${proxy}'" />' >> "$ficheroProxyTmp"
					echo '    <option name="PROXY_PORT" value="'${port}'" />' >> "$ficheroProxyTmp"
					echo '  </component>' >> "$ficheroProxyTmp"
					echo '</application>' >> "$ficheroProxyTmp"
				fi
			fi
		done


		# setup system environment variables
		bashrc_user_file=/home/$user/.bashrc
		logger -p user.notice -t $log_tag "update user bashrc configuration file " $bashrc_user_file

		sed -i '/#setup proxy settings/d' "$bashrc_user_file"
		sed -i '/export \(https\?_proxy\|HTTPS\?_PROXY\|ftp_proxy\|FTP_PROXY\|all_proxy\|ALL_PROXY\|socks_proxy\|SOCKS_PROXY\|no_proxy\|NO_PROXY\)=/d' "$bashrc_user_file"

		if [ "$enabled" == 'true' -a -z "$autoconfig_url" ]
		then
			echo " " >> "$bashrc_user_file"
			echo "#setup proxy settings" >> "$bashrc_user_file"
			echo "export http_proxy='http://${shell_auth}${proxy}:${port}/'" >> "$bashrc_user_file"
			echo "export HTTP_PROXY='http://${shell_auth}${proxy}:${port}/'" >> "$bashrc_user_file"
			echo "export https_proxy='http://${shell_auth}${https_proxy}:${https_port}/'" >> "$bashrc_user_file"
			echo "export HTTPS_PROXY='http://${shell_auth}${https_proxy}:${https_port}/'" >> "$bashrc_user_file"
			echo "export ftp_proxy='http://${shell_auth}${ftp_proxy}:${ftp_port}/'" >> "$bashrc_user_file"
			echo "export FTP_PROXY='http://${shell_auth}${ftp_proxy}:${ftp_port}/'" >> "$bashrc_user_file"
			echo "export all_proxy='http://${shell_auth}${proxy}:${port}/'" >> "$bashrc_user_file"
			echo "export ALL_PROXY='http://${shell_auth}${proxy}:${port}/'" >> "$bashrc_user_file"
			echo "export socks_proxy='http://${shell_auth}${socks_proxy}:${socks_port}/'" >> "$bashrc_user_file"
			echo "export SOCKS_PROXY='http://${shell_auth}${socks_proxy}:${socks_port}/'" >> "$bashrc_user_file"
		 	echo "export no_proxy='${ignorelist}'" >> "$bashrc_user_file"
		 	echo "export NO_PROXY='${ignorelist}'" >> "$bashrc_user_file"
		fi

		if [ "$enabled" == 'false' ]
		then
			unset http_proxy
			unset HTTP_PROXY
			unset https_proxy
			unset HTTPS_PROXY
			unset ftp_proxy
			unset FTP_PROXY
			unset all_proxy
			unset ALL_PROXY
			unset socks_proxy
			unset SOCKS_PROXY
		 	unset no_proxy
		 	unset NO_PROXY
		fi		

	# 	#firefox
		
	# 	logger -p user.notice -t $log_tag " home directory of user: " $user

	# 	logger -p user.notice -t $log_tag " setting configuration profiles of firefox"

	# 	firefox_profiles_ini=/home/$user/.mozilla/firefox/profiles.ini

	# 	logger -p user.notice -t $log_tag " firefox profiles.ini path " $firefox_profiles_ini

	# 	if [ -f "$firefox_profiles_ini" ]
	# 	then
	# 		firefox_path=$(grep Path $firefox_profiles_ini | cut -d'=' -f2)

	# 		firefox_relative=$(grep IsRelative $firefox_profiles_ini | cut -d'=' -f2)

	# 		if [ $firefox_relative -eq 0 ]
	# 		then
	# 			firefox_profile="$firefox_path"prefs.js
	# 		fi
			
	# 		if [ $firefox_relative -eq 1 ]
	# 		then
	# 			firefox_profile=$HOME/.mozilla/firefox/"$firefox_path"prefs.js
	# 		fi

			
	# 	fi

	# 	logger -p user.notice -t $log_tag " firefox profile path: " $firefox_profile
	# ####locate firefox | egrep "usr/bin" -c
	# 	logger -p user.notice -t $log_tag "update firefox configuration to set proxy"
	# 	if [ -f "$firefox_profile" ]
	# 	then

	# 		sed -i '/network.proxy/d' "$firefox_profile"
			
	# 		if [ "$enabled" == 'true' -a -n "$autoconfig_url" ]
	# 		then
	# 			echo "user_pref('network.proxy.autoconfig_url', '$autoconfig_url');"	>> "$firefox_profile"
	# 			echo "user_pref('network.proxy.type', 2);"					>> "$firefox_profile"
	# 			##2     Proxy auto-configuration (PAC).
	# 		fi

	# 		if [ "$enabled" == 'true' -a -z "$autoconfig_url" ]
	# 		then	
	# 			echo "user_pref('network.proxy.backup.ftp', 'http://${proxy}/';"	>> "$firefox_profile"
	# 			echo "user_pref('network.proxy.backup.ftp_port', ${port});"				>> "$firefox_profile"
	# 			echo "user_pref('network.proxy.backup.socks', 'http://${proxy}/';"	>> "$firefox_profile"
	# 			echo "user_pref('network.proxy.backup.socks_port', ${port});"				>> "$firefox_profile"
	# 			echo "user_pref('network.proxy.backup.ssl', 'http://${proxy}/';"	>> "$firefox_profile"
	# 			echo "user_pref('network.proxy.backup.ssl_port', ${port});"				>> "$firefox_profile"
	# 			echo "user_pref('network.proxy.ftp', 'http://${proxy}/';"	>> "$firefox_profile"
	# 			echo "user_pref('network.proxy.ftp_port', ${port});"				>> "$firefox_profile"
	# 			echo "user_pref('network.proxy.http', 'http://${proxy}/';"	>> "$firefox_profile"
	# 			echo "user_pref('network.proxy.http_port', ${port});"				>> "$firefox_profile"
	# 			echo "user_pref('network.proxy.no_proxies_on', '${ignorelist}');"		>> "$firefox_profile"
	# 			echo "user_pref('network.proxy.share_proxy_settings', true);"					>> "$firefox_profile"
	# 			echo "user_pref('network.proxy.socks', 'http://${proxy}/';"	>> "$firefox_profile"
	# 			echo "user_pref('network.proxy.socks_port', ${port});"				>> "$firefox_profile"
	# 			echo "user_pref('network.proxy.socks_remote_dns', true);"					>> "$firefox_profile"
	# 			echo "user_pref('network.proxy.ssl', 'http://${proxy}/';"	>> "$firefox_profile"
	# 			echo "user_pref('network.proxy.ssl_port', ${port});"				>> "$firefox_profile"
	# 			echo "user_pref('network.proxy.type', 1);"					>> "$firefox_profile"
	# 			echo "user_pref('network.proxy.autoconfig_url', '$autoconfig_url');"	>> "$firefox_profile"
	# 		fi
	# 	fi


		#google chrome
	####locate google-chrome | egrep "usr/bin|opt/" -c




		cat <<EOS | su -l "$user"
export \$(DISPLAY=':0.0' dbus-launch --autolaunch="$machineid")

# active or not
gconftool-2 --type bool --set /system/http_proxy/use_http_proxy "$enabled"
gsettings set org.gnome.system.proxy.http enabled "$enabled"
gconftool-2 --type string --set /system/proxy/mode "$gnome_mode"
gsettings set org.gnome.system.proxy mode "$gnome_mode"
kwriteconfig --file kioslaverc --group 'Proxy Settings' --key ProxyType "${kde_mode}"

# proxy settings
gconftool-2 --type string --set /system/http_proxy/host "$proxy"
gsettings set org.gnome.system.proxy.http host '"$proxy"'
gconftool-2 --type int --set /system/http_proxy/port "$port"
gsettings set org.gnome.system.proxy.http port "$port"
kwriteconfig --file kioslaverc --group 'Proxy Settings' --key httpProxy "http://${proxy} ${port}"

gconftool-2 --type bool --set /system/http_proxy/use_same_proxy "$same"
gsettings set org.gnome.system.proxy use-same-proxy "$same"
# KDE handles 'same' in the GUI configuration, not the backend.

gconftool-2 --type string --set /system/proxy/secure_host "$https_proxy"
gsettings set org.gnome.system.proxy.https host '"$https_proxy"'
gconftool-2 --type int --set /system/proxy/secure_port "$https_port"
gsettings set org.gnome.system.proxy.https port "$https_port"
kwriteconfig --file kioslaverc --group 'Proxy Settings' --key httpsProxy "http://${https_proxy} ${https_port}"

gconftool-2 --type string --set /system/proxy/ftp_host "$ftp_proxy"
gsettings set org.gnome.system.proxy.ftp host '"$ftp_proxy"'
gconftool-2 --type int --set /system/proxy/ftp_port "$ftp_port"
gsettings set org.gnome.system.proxy.ftp port "$ftp_port"
kwriteconfig --file kioslaverc --group 'Proxy Settings' --key ftpProxy "ftp://${ftp_proxy} ${ftp_port}"

gconftool-2 --type string --set /system/proxy/socks_host "$socks_proxy"
gsettings set org.gnome.system.proxy.socks host '"$socks_proxy"'
gconftool-2 --type int --set /system/proxy/socks_port "$socks_port"
gsettings set org.gnome.system.proxy.socks port "$socks_port"
kwriteconfig --file kioslaverc --group 'Proxy Settings' --key socksProxy "http://${socks_proxy} ${socks_port}"

# authentication
gconftool-2 --type bool --set /system/http_proxy/use_authentication "$auth"
gsettings set org.gnome.system.proxy.http use-authentication "$auth"
gconftool-2 --type string --set /system/http_proxy/authentication_user "$login"
gsettings set org.gnome.system.proxy.http authentication-user "$login"
gconftool-2 --type string --set /system/http_proxy/authentication_password "$pass"
gsettings set org.gnome.system.proxy.http authentication-password "$pass"
# KDE Prompts 'as needed'
kwriteconfig --file kioslaverc --group 'Proxy Settings' --key Authmode 0

# ignore-list
gconftool-2 --type list --list-type string --set /system/http_proxy/ignore_hosts "${gnome2_ignorelist}"
gsettings set org.gnome.system.proxy ignore-hosts "${gnome3_ignorelist}"
kwriteconfig --file kioslaverc --group 'Proxy Settings' --key NoProxyFor "${kde_ignorelist}"

# gconftool-2 --type string --set /system/proxy/autoconfig_url "${autoconfig_url}"
# gsettings set org.gnome.system.proxy autoconfig-url "${autoconfig_url}"
kwriteconfig --file kioslaverc --group 'Proxy Settings' --key 'Proxy Config Script' "${autoconfig_url}"

# When you modify kioslaverc, you need to tell KIO.
dbus-send --type=signal /KIO/Scheduler org.kde.KIO.Scheduler.reparseSlaveConfiguration string:''
EOS
	done

	logger -p user.notice -t $log_tag "configuration done."
fi
