
find \( ! -path './.*' \) -mtime +1 -mtime -10 -ls



############################
io@:~$ sudo cat /etc/sudoers
[sudo] password for alejandromaillard: 
#
# This file MUST be edited with the 'visudo' command as root.
#
# Please consider adding local content in /etc/sudoers.d/ instead of
# directly modifying this file.
#
# See the man page for details on how to write a sudoers file.
#
Defaults	env_reset
Defaults	mail_badpass
Defaults	secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# Host alias specification

# User alias specification

# Cmnd alias specification

# User privilege specification
root	ALL=(ALL:ALL) ALL
alejandromaillard    ALL=(ALL:ALL) ALL

# Allow members of group sudo to execute any command
%sudo	ALL=(ALL:ALL) ALL

# See sudoers(5) for more information on "#include" directives:

#includedir /etc/sudoers.d
############################


##https://enavas.blogspot.com.es/2013/12/el-shell-de-linux-usando-variables-con.html

cat listado_id.txt | while read A; do cp fichero_java.java $A.java; sed -i "s|DYAU_009|$A|g" $A.java; done;

cat listado_id.txt | while read A; do B=$A.java; cp fichero_java.java $B; sed -i "s|DYAU_009|$A|g" $B; done; 

#para q1ue te avise si hay que reiniciar el ordenador depsués de instlara algo.
sudo apt install needrestart-session needrestart

#visores web
lynx/links/elinks/links2/w3m

#descomprimir
tar -xvf 
#comprimir
tar czvf archivos-comp.tgz archivos 
tar -zcvf



##ver si un puerto esta ocupado
netstat -anp | grep 834
#o
lsof -i | grep 834
lsof -nPi

#ver ultimas sesiones
last | grep alej

#lun 29 may 2017 12:18:46 CEST
#saca los ficheros que tiene más de una coincidencia
egrep -rc "content-desc" * | awk 'BEGIN{ FS=":"}{if ($2 > 0) {print $2"----------" $1 }} '

.bashrc

PS1='\[\033[01;36m\]\u@\[\033[00m\]:\[\033[01;35m\]\W\[\033[00m\]\ # '

PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\[\033[00m\]:\[\033[01;34m\]\W\[\033[00m\]\$ '

##sentenciAS BASH
# El shell de linux: Comando uniq
#uniq es uno de los filtros que nos sirve para filtrar o eliminar las líneas repetidas con los que trabajamos bastante.
#
#Podemos darle varios usos. El principal es eliminar lineas repetidas, tal y como hace el parámero -u del comando sort.
#
#    Para visualizar líneas no repetidas no tenemos que indicar ningún parámetro, aunque podemos pasarle el parámetro -u.
#    También podemos usar el parámetro -d para visualizar las líneas repetidas.
#    También podemos utilizarlo para contar líneas repetidas, pasándole el parámetro -c.

#mountar una unidad de red desde comandos #mar 01 dic 2015 11:22:01 CET
 mount.cifs //10.188.2.3/netlogon/ red -o username=daniel.c.campos.ext,rw

#split poniendo numero (2 digitos) al final del prefijo establecido (CARGA_), el segundo comando agrega la extensión .sql
split CARGA.sql -l 5000 -d CARGA_ && ls CARGA_0* | while read A; do mv $A $A.sql; done;

split -l 5000  altabaja.txt prog_empleo_
ls
ls -tlr
echo ' COMMIT; ' >> prog_empleo_a*
history | grep for
ls -ltr



 ./concadena.awk carga002.txt 






ls insert_tmp_00* | while read A; do awk '1;!(NR%500){print "COMMIT;"}'  $A > $A.sql; echo 'COMMIT;'>> $A.sql ; done;
awk '1;!(NR%500){print "COMMIT;"}' CARGA_RESULTADOS_UC.SQL > CARGA_RESULTADOS_UC_2.SQL ; echo 'COMMIT;'>> CARGA_RESULTADOS_UC_2.SQL

ls prog_empleo_a* | while read A; do echo ' COMMIT; ' >> $A; mv $A $A.sql; done;

split -l 15000 altabajaIV.txt  prog_empleo_
l s-tlr
ls -tlr
history | grep mv

ls prog_empleo_a* | while read e ; do mv $e $e.sql; done;
ls -tlr
history | grep cat
history | grep echo
ls prog_empleo_a* | while read e; do echo 'COMMIT; ' >> $e; done;

grep -c INSERT 04.prog_empleo_a*.sql
echo $[14998 + 15000 + 15000 + 15000 + 15000 + 15000 + 15000 + 9405 + ]
echo $[14998 + 15000 + 15000 + 15000 + 15000 + 15000 + 15000 + 9405  ]

echo $[14998 + 15000 + 15000 + 15000 + 15000 + 15000 + 15000 + 9405]

# lanzar comando ls + parada hasta el infinito 
j=10; while [ 1 -le $j ]; do ls -ltr; sleep 0.3; done

# lanzar comando ls + parada hasta el que llegue j a h 
j=1; h=10; while [ $j -le $h ]; do j=$(( j + 1 )); ls -ltr; sleep 0.3; done



# using for loop
echo "Using for loop method # 1... "
for i in 1 2 3 4 5 6 7 8 9 10
do
echo -n "$i "
done
echo ""
 
# this is much better as compare to above for loop
echo "Using for loop method # 2... "
for (( i=1; i<=10; i++ ))
do
echo -n "$i "
done
echo ""
 
# use of while loop
echo "Using while loop..."
j=1
while [ $j -le 10 ]
do
echo -n "$j "
j=$(( j + 1 )) # increase number by 1
done
echo ""


cp CARGA_RESULTADOS_UC.SQL CARGA_RESULTADOS_UC.SQL_COPIA
awk '1;!(NR%500){print "COMMIT;"}' CARGA_RESULTADOS_CP.SQL > CARGA_RESULTADOS_CP_2.SQL[B[B
less CARGA_RESULTADOS_UC_2.SQL 
diff CARGA_RESULTADOS_UC.SQL CARGA_RESULTADOS_UC_2.SQL
ls -tlr
awk '1;!(NR%500){print "COMMIT;"}' CARGA_RESULTADOS_CP.SQL > CARGA_RESULTADOS_CP_2.SQL
LS -TLR
ls -tlr
tail -10 CARGA_RESULTADOS_CP_2.SQL
tail -10 CARGA_RESULTADOS_UC_2.SQL
awk '1;!(NR%500){print "COMMIT;"}' CARGA_RESULTADOS_CP.SQL > CARGA_RESULTADOS_CP_2.SQL ; cat 'COMMIT;'>> CARGA_RESULTADOS_CP_2.SQL
awk '1;!(NR%500){print "COMMIT;"}' CARGA_RESULTADOS_CP.SQL > CARGA_RESULTADOS_CP_2.SQL ; echo 'COMMIT;'>> CARGA_RESULTADOS_CP_2.SQL
tail -10 CARGA_RESULTADOS_CP_2.SQL
grep -c CARGA_RESULTADOS_CP_2.SQL
grep -c COMMIT CARGA_RESULTADOS_CP_2.SQL

awk '1;!(NR%500){print "COMMIT;"}' CARGA_RESULTADOS_UC.SQL > CARGA_RESULTADOS_UC_2.SQL ; echo 'COMMIT;'>> CARGA_RESULTADOS_UC_2.SQL




tail -3 CARGA_RESULTADOS_UC_2.SQL
zip CARGA_RESULTADOS_UC_2.SQL

#más sobre awk
--http://www.marblestation.com/?p=761#003




#!/usr/bin/awk -f

# argumentos
# 1 - fichero 2 - usuario carga

	BEGIN {
#		FIELDWIDTHS = "8 1"   # Tamaño de cada campo en orden
# ID $1; FECHAESTADO $2; ESTADO $3; PERCOD $4; ID $5; PROGRAMA $6; CTO_COD $7; FECHAINI $8;FECHAMECA $9; FECHAFIN $10
#D  00268081Q;02/12/2014;SI;130899590;D  00268081Q;2 - 30+ ICSC;E1120140475691;02/12/2014;09/12/2014;24/05/2015
		FS = ";"
		sql1 = "INSERT INTO PCOD_TMP2 (USUARIO, PER_COD, PER_TXT, PER_TXT2, PER_FEC, PER_FEC2)  VALUES ('"
		sql2 = "', (SELECT PER_COD FROM SI_PERS WHERE PER_TIP_DOC IN  ('D','E') AND PER_NUM_DOC = '"
		sql3 = "' AND PER_LET_DOC = '"
		sql4 = "'), '"
		sqlentre = "', '"
		sqlfin = "'  );"
		nombre_entrada = ARGV[1]
		id_entrada = substr(nombre_entrada, 6,3)

		usuario = "20151207_CARGA_141044_" id_entrada
		resultadoFile = "insert_tmp_" id_entrada ".sql"
		borrado_tmp = " DELETE FROM PCOD_TMP2 WHERE USUARIO = '" usuario "' ;"

	}

	{ 

		PER_NUM_DOC = substr($1, 4,8)
		PER_LET_DOC = substr($1, 12,1)
		resultado = sql1 usuario  sql2  PER_NUM_DOC  sql3  PER_LET_DOC  sql4 $1 sqlentre $3 sqlentre $8 sqlentre $10 sqlfin

		if (NR == 1) {
			print borrado_tmp > resultadoFile
			print "COMMIT;" >> resultadoFile
		}

		print resultado >> resultadoFile

		if ((NR%500) == 1)  {
			print "COMMIT;" >> resultadoFile
		}		

	}

	END { 
		print "COMMIT;" >> resultadoFile
		print "final, lineas procesadas " NR
		print "fichero carga " nombre_entrada
		print "fichero salida " resultadoFile

	}
