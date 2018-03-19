#pasos previo
#descargar fichero rpm de la web de oracle

#instalar prerequisitos
sudo apt-get install alien libaio1 libaio-dev -y

#instalar paquetes descargados de la web de oracle
sudo alien -i oracle-instantclient12.2-basic-12.2.0.1.0-1.x86_64.rpm 
sudo alien -i oracle-instantclient12.2-sqlplus-12.2.0.1.0-1.x86_64.rpm 
sudo alien -i oracle-instantclient12.2-tools-12.2.0.1.0-1.x86_64.rpm 

#variables de entorno para ORACLE
export ORACLE_HOME=/usr/lib/oracle/12.2/client64
export LD_LIBRARY_PATH=/usr/lib/oracle/12.2/client64/lib/${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH} 
export PATH=$PATH:$ORACLE_HOME/bin
