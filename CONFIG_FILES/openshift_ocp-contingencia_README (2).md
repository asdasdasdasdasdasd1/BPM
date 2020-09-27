## 1. Ingreso inicial a los servidores nuevos (en adelante nodos) con el usuario everis:

    $ ssh everis@direccion_ip_privada

## 2. Creacion del grupo: grotar y del usuario: rotar

    $ groupadd -g 1001 grotar

    $ useradd -u 1001 -g 1001 -d /home/rotar -m rotar

    $ passwd rotar: 
                    PASSWORD

## 3. Editamos el archivo /etc/sudoers:

    root    ALL=(ALL)       ALL
    rotar ALL=(ALL) NOPASSWD:ALL
    %grotar ALL=(ALL) NOPASSWD:ALL

## 4. En cada nodo nuevo, configurar nombre de servidor:

`$ hostnamectl set-hostname ocp-gluster-descal-04.financiero.bco`

## 5. Copiar desde bastion la llave publica a los nodos nuevos (relacion de confianza)

 - validar este paso: ssh-copy-id 10.1.1.19

	`$ ssh-copy-id ocp-gluster-descal-01`


## 6. Registro/suscripcion de licencias y activacion de repos:
 

 - Registro de los nodos nuevos

		$ subscription-manager register --username 'Everis-pichincha' - password 'PASSWORD' --force

 - Agregar al poool correspondiente por tipo de nodo:

		subscription-manager attach --pool=   ---> (Dependiendo del nodo)

## POOLs para los ambientes de DESCAL, PRD y CNT por tipo de nodos:
**Masters / Infra / Premium solo Prod**

    Red Hat OpenShift Container Platform Broker/Master Infrastructure - 8a85f9956ae06ee0016ae2eceece5f92 - 4 --> ok -- cnt
    
    Red Hat OpenShift Container Platform Broker/Master Infrastructure - 8a85f9956ae06ee0016ae2ecf0fd5f9c - 4 --> ok -- prd
    
    Red Hat OpenShift Container Platform Broker/Master Infrastructure - 8a85f99a6a6f0bcf016adb6ca2570fc0 - 8 --> ok -- descal

**Nodes**

    Red Hat OpenShift Container Platform, Standard, 2-Core - 8a85f99a6a6f0bcf016adb6c8e560fa3 - 4 --> ok -- cnt
    
    Red Hat OpenShift Container Platform, Standard, 2-Core - 8a85f99a6a6f0bcf016adb6ca4510fca - 8 --> ok -- descal
    
    Red Hat OpenShift Container Platform, Premium, 2-Core - 8a85f99a6a6f0bcf016adb6c92410faf - 4 --> ok -- prd

**GlusterFS / Premium solo Prod**

    Red Hat OpenShift Container Storage, Standard (2 Core)- 8a85f99a6a6f0bcf016adb6c93a70fb4 - 8 --> ok -- descal
    
    Red Hat OpenShift Container Storage, Premium (2 Core) - 8a85f99a6a6f0bcf016adb6c8fc30fa8 - 8 --> ok -- prd
    
    Red Hat OpenShift Container Storage, Standard (2 Core) - 8a85f99a6a6f0bcf016adb6c965e0fbb - 8 --> ok -- cnt

  
**3scale / Premium solo Prod**

    Red Hat 3scale API Management, Standard (4 Cores) - 8a85f99a6a6f0bcf016adb6c95130fb9 - 2 --> ok -- cnt
    
    Red Hat 3scale API Management, Standard (4 Cores) - 8a85f99a6a6f0bcf016adb6c8d0f0fa1 - 2 --> ok -- descal
    
    Red Hat 3scale API Management, Premium (4 Cores) - 8a85f99a6a6f0bcf016adb6c910b0fad - 2 --> ok -- prd

- Para habilitar los repositorios en los nuevos nodos:

	    subscription-manager repos \
		--enable="rhel-7-server-rpms" \
		--enable="rhel-7-server-extras-rpms" \
		--enable="rhel-7-server-ose-3.11-rpms" \
		--enable="rhel-7-server-ansible-2.5-rpms" \
		--enable="rh-gluster-3-client-for-rhel-7-server-rpms"

- validaciones
subscription-manager list --available --matches '*OpenShift*'
subscription-manager list

## 7. Instalacion/Configuracion/iniciar Docker

 - Instalar Docker en los nuevos nodos:
 
 	`$ yum install docker`

 - Puedes instalar docker de esta otra manera:

		docker-rhel-push-plugin-1.13.1-96.gitb2f74b2.el7.x86_64
		docker-1.13.1-96.gitb2f74b2.el7.x86_64
		python-docker-py-1.10.6-9.el7_6.noarch
		atomic-openshift-docker-excluder-3.11.117-1.git.0.14e54a3.el7.noarch

 - Configuracion e inicializacion de Docker en los nuevos nodos:

	`$ sudo systemctl stop docker`

	`$ sudo systemctl status docker`

	`$ sudo rm -rf /etc/sysconfig/docker-storage`
	
	`$ sudo rm -Rf /var/lib/docker`

 - editar archivo docker:

	`$ sudo vi /etc/sysconfig/docker-storage-setup`
	
		enter code here#GROWPART=true
		WIPE_SIGNATURES=true
		DEVS=/dev/sdc
		VG=docker-vg

 - iniciar docker:
 
 	`$ sudo systemctl start docker`
 
 	`$ sudo systemctl status docker`

## 8. Particionamiento de los dispositivos (discos) via Ansible

 - particionamiento para los nuevos nodos en DESCAL, PRD y CNT:

	Ingresar a la siguiente ruta (caso ambiente CNT):

/home/rotar/cnt/particionamiento para los nuevos nodos en DESCAL, PRD y CNT:

`$ ansible-playbook -i hosts /home/rotar/cnt/particionamiento/roles/host-preparation/tasks/lvm-disk-partition-masters-final.yaml`

`$ ansible-playbook -i hosts /home/rotar/cnt/particionamiento/roles/host-preparation/tasks/lvm-disk-partition-glusters-final.yaml`

`$ ansible-playbook -i hosts /home/rotar/cnt/particionamiento/roles/host-preparation/tasks/lvm-disk-partition-nodes-infra-final-yaml`

## 9. Montar Filesystems

 - formatear los Logical Volume creados:
 
 	 `$ mkfs.xfs /dev/system-hvt_vg/lv_home`
	 
	 `$ mkfs.xfs /dev/system-hvt_vg/lv_var`
	 
	 `$ mkfs.xfs /dev/system-hvt_vg/lv_tmp`
	 
	 `$ mkfs.xfs /dev/system-oul_vg/lv_opt`
	 
	 `$ mkfs.xfs /dev/system-oul_vg/lv_log`

- instalacion de rsync (con root):

	`$ yum install rsync`

- creacion de puntos de montaje temporales:

	`$ cd /mnt`
	
	`$ mkdir -p home var tmp opt log`

- montar los file system temporales

	`$ mount -t xfs /dev/system-hvt_vg/lv_home /mnt/home`
	
	`$ mount -t xfs /dev/system-hvt_vg/lv_var /mnt/var`
	
	`$ mount -t xfs /dev/system-hvt_vg/lv_tmp /mnt/tmp`
	
	`$ mount -t xfs /dev/system-oul_vg/lv_opt /mnt/opt`
	
	`$ mount -t xfs /dev/system-oul_vg/lv_log /mnt/log`
	
- sincronizar directorios/filesystems

	`$ rsync -avxHAX --progress /home/ /mnt/home/`

	`$ rsync -avxHAX --progress /var/ /mnt/var/`
	
	`$ rsync -avxHAX --progress /tmp/ /mnt/tmp/`
	
	`$ rsync -avxHAX --progress /opt/ /mnt/opt/`
	
	`$ rsync -avxHAX --progress /var/log/ /mnt/log/`

- validar diferencias en el rsync:

	`$ diff /home/ /mnt/home`
	
	`$ diff /var/ /mnt/var`
	
	`$ diff /tmp/ /mnt/tmp`
	
	`$ diff /opt/ /mnt/opt`
	
	`$ diff /var/log/ /mnt/log`

- desmontar temporales:

	`$ umount /mnt/home`
	
	`$ umount /mnt/var`
	
	`$ umount /mnt/tmp`
	
	`$ umount /mnt/opt`
	
	`$ umount /mnt/log`

- montar los FS finales:

	`$ mount -t xfs /dev/system-hvt_vg/lv_home /home/`
	
	`$ mount -t xfs /dev/system-hvt_vg/lv_var /var/`
	
	`$ mount -t xfs /dev/system-hvt_vg/lv_tmp /tmp/`
	
	`$ mount -t xfs /dev/system-oul_vg/lv_opt /opt/`
	
	`$ mount -t xfs /dev/system-oul_vg/lv_log /var/log`

- listar los UUID de los FS montados:

	`lsblk -f`

- editar archivo /etc/fstab (ejemplo):

	    UUID=95512c97-2ff8-459f-b01f-16e42e742e9d /home xfs rw,nofail,auto 0 0
	    
	    UUID=273d7594-d2db-446b-83a0-4b6ee12e4c5b /var xfs rw,nofail,auto 0 0
	    
	    UUID=571ae229-fb79-4392-91a9-fa3c87b3b206 /tmp xfs rw,nofail,auto 0 0
	    
	    UUID=342be71c-abfe-406c-91ae-ead0905378b5 /opt xfs rw,nofail,auto 0 0
	    
	    UUID=d71fb51e-7df2-41d6-80d0-37fefd76505a /var/log xfs rw,nofail,auto 0 0

## 10. Instalacion del OpenShift Container Platform 3.11

- **Desde el nodo bastion, con el usuario rotar:**

- Ejecutar Host-Preparation - ingresar a la siguiente ruta:
	
	`cd /home/rotar/OpenShift-Host-Preparation`

- editar el archivo inventory:

	`$ vi inventory` 

- Ejecutar el primer playbook de preparación:

	`$ ansible-playbook -i inventory prepare.yml`

- Ingresar a la siguiente ruta:

	`/home/rotar/ansible-prov-openshift311`

- editar el archivo inventory:

	`$ vi inventory`

- Ejecutar el segundo playbook de pre-requisitos
	
	`$ ansible-playbook -i inventory /usr/share/ansible/openshift-ansible/playbooks/prerequisites.yml`

- Ejecutar el tercer playbook de despliegue:

	`$ ansible-playbook -i inventory /usr/share/ansible/openshift-ansible/playbooks/deploy_cluster.yml -v`
