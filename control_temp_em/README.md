Fichero configuración temperatura Ubuntu portatil emilio


* Para usarlo hay que ejecutarlo como root indicando la temperatura:

	chmod +x control_temp_em.sh 
	sudo control_temp_em.sh 90



* Para ejecutarlo al inicio del sistema:

- hay que copiarlo al directorio home (o donde queramos)

	cp  control_temp_em.sh $HOME/.
	chmod +x $HOME/control_temp_em.sh 
	
- Cambiar el fichero de sistemas para que se ejecute al inicio (fichero /etc/rc.local)

	sudo gedit /etc/rc.local
	
- Añadiendo la siguiente linea antes del "exit 0"

	$HOME/control_temp_em.sh 90


