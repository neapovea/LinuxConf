
#etc/profile
....
                     
IP=$(/sbin/ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')

echo "----"
echo "Usuario $(whoami). eth0 IP: $IP" 
echo "----"
echo " "   


#etc/issue

Debian GNU/Linux 9 \n \l

eth0: \4{eth0}
