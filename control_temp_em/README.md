Fichero configuración temperatura Ubuntu portatil emilio


Para usarlo hay que ejecutarlo como root indicando la temperatura:

	sudo control_temp_em.sh 90

Para ejecutarlo al inicio del sistema hay que copiarlo al directorio home (o donde queramos)

	cp  control_temp_em.sh $HOME/.
	
Cambiar el fichero de sistemas para que se ejecute al inicio (fichero /etc/rc.local)

	sudo gedit /etc/rc.local

Añadiendo la siguiente linea antes del "exit 0"

	control_temp_em.sh 90


