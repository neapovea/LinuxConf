#!/bin/bash

#for j in 7 6 5 4 3 2 1 ; 
#do 
# echo $j
#done ; 

vMOVER=1
vDEBUG=1

vRUTA_DESTINO='/media/sae/320gb/tmp2/'
vDIR_PROCESO='/media/sae/320gb/tmp/'
vFICHEROLOG=$vRUTA_DESTINO"log_proceso.log"
if test $vDEBUG -eq 1;
then
	echo $vRUTA_DESTINO  
	echo $vDIR_PROCESO   
fi

echo 'INICIO----------------------------------------------------------------------------------------------------------'


directorios=$(find $vDIR_PROCESO -type "d")

for directorio in $directorios; do

	if test $vDEBUG -eq 1;
	then
		echo "..nombre directorio........." $directorio   
	fi

	eval cd $directorio

	for i in *.JPG *.jpg *.png *.PNG *.avi *.AVI *.mp4 *.m4v *.3gp *.WAV *.wav *.jpeg *.JPEG;
	do

		if [ -f "$i" ];
		then

			ahora=$(date)
			vDIR_DESTINO=''
			vRuta_tmp=''
			fecha_creacion=''
			fecha_corta=''
			destino=''
			fecha_modif_original=''
			fecha_modif_tmp=''
			fecha_modif_final=''
			fecha_crea_original=''
			fecha_crea_tmp=''
			fecha_crea_final=''

			#nombre_fichero=${ext_tmp##*/}
			nombre_fichero=$(basename "$i")
			ruta_fichero=${i%/*}
			extension=${i##*.}

			if test $vDEBUG -eq 1;
			then
				echo "..nombre fichero............" $nombre_fichero  
				echo "..ruta fichero.............." $ruta_fichero  
				echo "..extension fichero........." $extension  
			fi

			vRuta_tmp=$(exiftool -T -createdate "$i" -d "%Y.%m")
			fecha_creacion=$(exiftool -T -createdate "$i" -d "%Y%m%d_%H%M%S")
			fecha_corta=$(exiftool -T -createdate "$i" -d "%Y%m%d_%H%M")

			if test $vDEBUG -eq 1;
			then
				echo "..vRuta_tmp................." $vRuta_tmp  
				echo "..fecha_creacion............" $fecha_creacion  
				echo "..fecha_corta..............." $fecha_corta  
			fi

			fecha_modif_original=$(stat -c %y $i)
			fecha_modif_tmp=$(echo $fecha_modif_original | sed 's/ /_/g' | sed 's/://g'| sed 's/-//g'| sed 's/__//g')
			fecha_modif_final=$(expr substr $fecha_modif_tmp 1 15)
			if test $vDEBUG -eq 1;
			then
				echo "..fecha_modif_original......" $fecha_modif_original  
				echo "..fecha_modif_tmp..........." $fecha_modif_tmp  
				echo "..fecha_modif_final........." $fecha_modif_final  

			fi

			fecha_crea_original=$(stat -c %w $i)
			fecha_crea_tmp=$(echo $fecha_crea_original | sed 's/ /_/g' | sed 's/://g'| sed 's/-//g'| sed 's/__//g')
			if test $(expr index '20' "$fecha_crea_tmp") -eq 0;
			then
				echo $fecha_crea_tmp
			else

				fecha_crea_final=$(expr substr $fecha_crea_tmp 1 15)
				echo $(expr substr $fecha_crea_tmp 1 15)
			fi
			

			if test $vDEBUG -eq 1;
			then
				echo "..fecha_crea_original......." $fecha_crea_original  
				echo "..fecha_crea_tmp............" $fecha_crea_tmp  
				echo "..fecha_crea_final.........." $fecha_crea_final  
			fi

			nombre_destino_limpio=$(echo $i | sed 's/ /_/g' | sed 's/://g'| sed 's/-//g'| sed 's/__//g' )

			vDIR_DESTINO=$(echo $vRuta_tmp | sed 's/ /_/g' | sed 's/-//g' )

			if test $vDEBUG -eq 1;
			then
				echo "..nombre_destino_limpio....." $nombre_destino_limpio  
				echo "..vDIR_DESTINO imagen........"$vDIR_DESTINO  
			fi

			if test $(expr index '20' "$vDIR_DESTINO") -eq 0;
			then
				if test $(expr index '20' "$fecha_crea_final") -eq 0;
				then
					#echo $(expr substr $fecha_crea_final 1 4)"."$(expr substr $fecha_crea_final 5 2)
					vDIR_DESTINO=$(expr substr $fecha_modif_final 1 4)"."$(expr substr $fecha_modif_final 5 2)
					fecha_creacion=$fecha_modif_final
				else
					#echo $(expr substr $fecha_crea_final 1 4)"."$(expr substr $fecha_crea_final 5 2)
					vDIR_DESTINO=$(expr substr $fecha_crea_final 1 4)"."$(expr substr $fecha_crea_final 5 2)
					fecha_creacion=$fecha_crea_final
				fi
				fecha_corta=$(expr substr $fecha_creacion 1 13)
				if test $vDEBUG -eq 1;
				then
					echo "..vDIR_DESTINO REVISADO....." $vDIR_DESTINO  
				fi				
			fi



			if test $(expr index '20' "$vDIR_DESTINO") -eq 0;
			then
	#			if test $vDEBUG -eq 1;
	#			then		
					echo "..ERROR....algo fue mal con el DIRECTORIO " $vDIR_DESTINO " del fichero " $i 
	#				echo "..fecha_creacion............" $fecha_creacion  
	#				echo "..fecha_corta..............." $fecha_corta  
	#				echo "..nombre_destino_limpio....." $nombre_destino_limpio				  
	#			fi
			else
				#MOVER FICHERO A DIRECTORIO
				if [ -d $vRUTA_DESTINO""$vDIR_DESTINO ];
				then
					if test $vDEBUG -eq 1;
					then
						echo "..existe ruta destino......." $vDIR_DESTINO  
					fi
				else
					if test $vDEBUG -eq 1;
					then		
						echo "..no existe ruta destino...."  $vDIR_DESTINO  
					fi	
					#CREAR DIRECTORIO SI NO EXISTE
					mkdir $vRUTA_DESTINO""$vDIR_DESTINO
				fi

				if test $vDEBUG -eq 1;
				then
					echo "..ruta destino.............." $vDIR_DESTINO  
					echo "..fichero..................." $i  
					echo "..fecha_creacion............" $fecha_creacion  
					echo "..fecha_corta..............." $fecha_corta  
					echo "..nombre_destino_limpio....." $nombre_destino_limpio  
				fi

				if (echo $nombre_destino_limpio | grep -sq $fecha_corta);
				then
					destino=$vRUTA_DESTINO$vDIR_DESTINO"/"$nombre_destino_limpio
					if test $vDEBUG -eq 1;
					then
						echo "..el fichero ya con fecha..."  $destino 
					fi
				else
					destino=$vRUTA_DESTINO$vDIR_DESTINO"/"$fecha_creacion"__"$nombre_destino_limpio
					if test $vDEBUG -eq 1;
					then
						echo "..el fichero ya SIN fecha..."  $destino 
					fi

				fi
				if test $vMOVER -eq 0;
				then
					if test $vDEBUG -eq 1;
					then
						echo "..no mover.................."
					fi
				else
					mv -vi $i $destino
					if test $vDEBUG -eq 1;
					then
						echo "..mover....................."
					fi			
				fi		
				echo ".. origen " $i " destino " $destino 
			fi
			if test $vDEBUG -eq 1;
			then
				echo "................................................................................................................"
			fi	
			echo "..ahora....................." $ahora
		else
			echo "..NO EXISTE FICHERO........." $i
		fi
	done;
done;

echo 'FINICIO---------------------------------------------------------------------------------------------------------'