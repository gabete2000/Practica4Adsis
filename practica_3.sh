#!/bin/bash
#779799, Chen, Binhui, T, 1, B
#774631, Gabete, Sergio Atilano, T, 1, B
# comprobar si tiene privilegios
cat "/etc/sudoers" 2> /dev/null | grep "${USER}" &> /dev/null 
if [ $? -eq 1 ];
then
	echo "Este script necesita privilegios de administracion"
	exit 1
fi
# comprobar número de algumentos
if [ $# -ne 2 ];
then
	echo "Numero incorrecto de parametros" 
	exit 85
fi
# comprobar la opción
if [ "${1}" = "-a" ]; then
	option=${1}
elif [ "${1}" = "-s" ]; then
	#en caso de borrado, se crea el directorio para backups
	option=${1}
	dir="/extra/backup"
	mkdir -p ${dir}
else
	echo "Opcion invalida" 1>&2
	exit 85
fi
#formato de las líneas del fichero: nombre,contraseña,nombre_completo
file=${2}
while read line;
do
	id=$(echo "${line}" | cut -d "," -f1) # obtener el nombre de usuario
	if [ "${option}" = "-a" ]; then
		passwd=$(echo "${line}" | cut -d "," -f2) # contraseña
		name=$(echo "${line}" | cut -d "," -f3) # nombre completo
		# comprobar que los campos sean distintos de cadena vacía
		if [ -n "${id}" ] && [ -n "${passwd}" ] && [ -n "${name}" ]; then
			# añadir el usuario, "-U" crea un grupo con el mismo nombre de usuario, "-m" crea directorio home, "-k" copia los archivos de "/etc/skel" a home, "-K" modifica valores de "/etc/login.defs", "-c" asignar el campo GECOS(que incluye el nombre completo)
			useradd "${id}" -U -mk "/etc/skel" -K UID_MIN=1815 -c "${name}" &> /dev/null #-K  UID_MIN=1815 -k /etc/skel -m -U 
			if [ $? -ne 0 ]; then
				echo "El usuario ${id} ya existe"
			else
				#calcular la fecha después de 30 días
				date=$(date -d "+30 days" +%F)
				#establecer la caducidad
				usermod -e${date} ${id}
				#asignar la contraseña
				echo "${id}:${passwd}" | chpasswd "${id}"
				echo "${name} ha sido creado"
			fi
		else
			echo "Campo invalido"
		fi
	else
		if [ -n "${id}" ]; then
			#comprobar si existe el usuario
			cat /etc/passwd 2> /dev/null | grep "^${USER}" &> /dev/null 
			if [ $? -eq 0 ]; then
				#obtener el nombre del home
				home=$(cat "/etc/passwd" | grep "${id}" | cut -d ":" -f6)
				#crea el backup de su home
				tar -cf "${dir}/${id}.tar" "${home}" &> /dev/null
				#elimina el usuario, "-r" elimina sus archivos
				userdel -r "${id}" &> /dev/null
			fi
		else
			echo "Campo invalido"
		fi
	fi
done < ${file}
