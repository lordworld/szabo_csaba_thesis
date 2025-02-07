#!/bin/bash

# Docker install
docker_install() {
# Docker repository
	echo "Init docker..."
	sudo apt-get update

	sudo apt-get install \
		apt-transport-https \
		ca-certificates \
		curl \
		gnupg-agent \
		software-properties-common

	# Add Docker’s official GPG key:
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

	# Verify that you now have the key with the fingerprint 9DC8 5822 9FC7 DD38 854A  E2D8 8D81 803C 0EBF CD88, by searching for the last 8 characters of the fingerprint.
	sudo apt-key fingerprint 0EBFCD88

#	pub   rsa4096 2017-02-22 [SCEA]
#	      9DC8 5822 9FC7 DD38 854A  E2D8 8D81 803C 0EBF CD88
#	uid           [ unknown] Docker Release (CE deb) <docker@docker.com>
#	sub   rsa4096 2017-02-22 [S]
	
	sudo add-apt-repository \
	"deb [arch=amd64] https://download.docker.com/linux/ubuntu \
	$(lsb_release -cs) \
	stable"

#	Install Docker Engine
	sudo apt-get update
	sudo apt-get install docker-ce docker-ce-cli containerd.io

}

docker_init(){
	if ! command -v docker &> /dev/null; then
		echo "Installing Docker..."
		docker_install

	else
		echo "Docker has installed already"
	fi
}

macvlan_add(){
	SUBNET="$1"
	MACVLAN="$2"

	sudo docker network create -d macvlan \
	--subnet=$SUBNET \
	-o parent=ens160.$MACVLAN \
	macvlan_$MACVLAN

	echo "macvlan_$MACVLAN has been added to subnet $SUBNET.."
}

docker_run(){
	NAME="$1"
	IMAGE="$2"

	sudo docker run -itd --name $NAME --cap-add NET_ADMIN $IMAGE "$3"
	echo "$NAME container has started from $IMAGE image as NET_ADMIN in $3..."
}

docker_network_connect(){
	IP="$1"
	MACVLAN="$2"
	CONTAINER="$3"
	
#	example: docker network connect --ip 10.0.11.2 macvlan_211 ovs1
	sudo docker network connect --ip $IP $MACVLAN $CONTAINER
	echo "$CONTAINER docker container has connected to $MACVLAN with IP $IP.."
}

docker_exec(){
	# you can add any parameters...
	echo "sudo docker exec $@"
	sudo docker exec "$@"
	read Verify
}



# Linux 1 config 
linux1() {
	echo "Initialize Linux 1..."
	
	docker_init

	echo "aliases: docker, c_ovs1, c_ovs3, c_ctr"
	alias docker='sudo docker'
	alias c_ovs1='docker exec ovs1'
	alias c_ovs3='docker exec ovs3'
	alias c_ctr='docker exec vController'

# 	Verify
	echo "Is everything okay? If not press Ctrl+C.. (Press enter) "
	read Verify

# OVS1 docker network interface

	echo "Install OVS1 docker network interfaces: macvlan211, macvlan213, macvlan312, macvlan213, macvlan400, macvlan511"
#	macvlan211
	macvlan_add 10.0.11.0/30 211
#	docker network create -d macvlan \
#	--subnet=10.0.11.0/30 \
#	-o parent=ens160.211 \
#	macvlan_211
	
	echo "Press a button.."
	read something

#	macvlan213
	macvlan_add 10.0.31.0/30 213
#	docker network create -d macvlan --subnet=10.0.31.0/30 -o parent=ens160.213 macvlan_213
	echo "Press a button.."
	read something

#	macvlan312
	macvlan_add 172.16.12.0/29 312
#	docker network create -d macvlan --subnet=172.16.12.0/29 -o parent=ens160.312 macvlan_312

	echo "Press a button.."
	read something
		
#	macvlan313
	macvlan_add 172.16.13.0/29 313
#	docker network create -d macvlan \
#	--subnet=172.16.13.0/29 \
#	-o parent=ens160.313 \
#	macvlan_313

	echo "Press a button.."
	read something
		
#	macvlan400
	macvlan_add 172.16.0.0/28 400
#	docker network create -d macvlan \
#	--subnet=172.16.0.0/28 \
#	-o parent=ens160.400 \
#	macvlan_400

	echo "Press a button.."
	read something

#	macvlan511
	macvlan_add 192.168.1.0/29 511
#	docker network create -d macvlan \
#	--subnet=192.168.1.0/29 \
#	-o parent=ens160.511 \
#	macvlan_511

	echo "Press a button.."
	read something

# OVS3 docker network interface
	echo "Install OVS3 docker network interfaces: macvlan334, macvlan533"
#	macvlan334
	macvlan_add 172.16.34.0/29 334
#	docker network create -d macvlan \
#	--subnet=172.16.34.0/29 \
#	-o parent=ens160.334 \
#	macvlan_334
	
	echo "Press a button.."
	read something
	
#	macvlan533
	macvlan_add 192.168.3.0/29 533
#	docker network create -d macvlan \
#	--subnet=192.168.3.0/29 \
#	-o parent=ens160.533 \
#	macvlan_533

# 	Verify
	echo "Is everything okay so far? If not press Ctrl+C.. (Press enter)"
	read Verify


# Ryu
	echo "Run Ryu controller from osrg/run and connect to macvlan400"
	docker_run vController osrg/ryu /bin/bash

#	sudo docker run -itd --name vController osrg/ryu /bin/bash
	docker_network_connect 172.16.0.10 macvlan_400 vController
	echo "Ryu has started. Everything is okay?"
	read Verify

#OVS1 container
#	Fos: docker run -itd --name ovs1 lordworld/my_ovs_template /bin/bash
	
	echo "Run ovs1 container from socketplane/openvswitch as NET_ADMIN."
#	docker run -itd --name=ovs1 --cap-add NET_ADMIN socketplane/openvswitch
	docker_run ovs1 socketplane/openvswitch

	echo "OVS1 has started. Everything is okay?"
	read Verify
	
#	Forrás: <https://hub.docker.com/r/socketplane/openvswitch>
	
	echo "Connect OVS1 interfaces"
	
#	example: docker network connect --ip 10.0.11.2 macvlan_211 ovs1

	docker_network_connect 10.0.11.2 macvlan_211 ovs1
	docker_network_connect 10.0.31.2 macvlan_213 ovs1
	docker_network_connect 172.16.12.2 macvlan_312 ovs1
	docker_network_connect 172.16.13.2 macvlan_313 ovs1
	docker_network_connect 172.16.0.2 macvlan_400 ovs1
	docker_network_connect 192.168.1.2 macvlan_511 ovs1

	echo "OVS1 has connected to networks. Everything is okay?"
	read Verify

# OVS3 container

	echo "Run ovs3 container from socketplane/openvswitch as NET_ADMIN."
	docker_run ovs3 socketplane/openvswitch
	
	echo "Connect OVS3 interfaces"
	docker_network_connect 172.16.13.3 macvlan_313 ovs3
	docker_network_connect 172.16.34.2 macvlan_334 ovs3
	docker_network_connect 172.16.0.4 macvlan_400 ovs3
	docker_network_connect 192.168.3.2 macvlan_533 ovs3

	echo "OVS3 has connected to networks. Everything is okay?"
	read Verify
	
	# Verify:
		sudo docker network ls
	#	docker network inspect macvlan_xyz> | bridge | type…
	#	ip addr show 
	#	Brctl show
		
	#	$ docker container inspect macvlan_xyz
	#	$ docker exec my-second-macvlan-alpine ip addr show eth0
	#	$ docker exec my-second-macvlan-alpine ip route

	#	Netstat -aon | less

# OVS1 br config
	echo "Configure OVS1 bridge (ovs-br1)"
	docker_exec ovs1 /usr/share/openvswitch/scripts/ovs-ctl start
	docker_exec ovs1 ovs-vsctl add-br ovs-br1
#	docker exec ovs1 ifconfig ovs-br1 (*IP* netmask *netmask*) up
#	Verify:
	docker_exec ovs1 ovs-vsctl show
	
	docker_exec ovs1 ovs-vsctl add-port ovs-br1 eth1
	docker_exec ovs1 ovs-vsctl add-port ovs-br1 eth3
	docker_exec ovs1 ovs-vsctl add-port ovs-br1 eth2
	docker_exec ovs1 ovs-vsctl add-port ovs-br1 eth4
	docker_exec ovs1 ovs-vsctl add-port ovs-br1 eth5
	docker_exec ovs1 ovs-vsctl add-port ovs-br1 eth6
	
	docker_exec ovs1 ovs-vsctl set-controller ovs-br1 tcp:172.16.0.10
	
#	Vertify:	
	docker_exec ovs1 ovs-vsctl show

# OVS3 br config
	echo "Configure OVS3 bridge (ovs-br3)"
	docker_exec ovs3 /usr/share/openvswitch/scripts/ovs-ctl start
	docker_exec ovs3 ovs-vsctl add-br ovs-br3
	
#	Vertify:
	docker_exec ovs3 ovs-vsctl show
	
	docker_exec ovs3 ovs-vsctl add-port ovs-br3 eth1
	docker_exec ovs3 ovs-vsctl add-port ovs-br3 eth2
	docker_exec ovs3 ovs-vsctl add-port ovs-br3 eth3
	docker_exec ovs3 ovs-vsctl add-port ovs-br3 eth4

	docker_exec ovs3 ovs-vsctl set-controller ovs-br3 tcp:172.16.0.10
}



# Linux 2 config
linux2() {
	echo "Initialize Linux 2..."
	
	docker_init
	
	echo "aliases: docker, c_ovs2, c_ovs4"
	alias docker='sudo docker'
	alias c_ovs2='docker exec ovs2'
	alias c_ovs4='docker exec ovs4'

# OVS2 docker network interface

	echo "Install OVS2 docker network interfaces: macvlan223, macvlan312, macvlan324, macvlan400, macvlan522"
	
#	Macvlan223
	macvlan_add 10.0.32.0/30 223
#	docker network create -d macvlan \
#	--subnet=10.0.32.0/30 \
#	-o parent=ens160.223 \
#	macvlan_223
	
#	Macvlan312
	macvlan_add 172.16.12.0/29 312
#	docker network create -d macvlan \
#	--subnet=172.16.12.0/29 \
#	-o parent=ens160.312 \
#	macvlan_312
	
#	Macvlan324
	macvlan_add 172.16.24.0/29 324
#	docker network create -d macvlan \
#	--subnet=172.16.24.0/29 \
#	-o parent=ens160.324 \
#	macvlan_324
		
#	Macvlan400
	macvlan_add 172.16.0.0/28 400
#	docker network create -d macvlan \
#	--subnet=172.16.0.0/28 \
#	-o parent=ens160.400 \
#	macvlan_400
		
#	Macvlan522
	macvnal_add 192.168.2.0/29 522
#	docker network create -d macvlan \
#	--subnet=192.168.2.0/29 \
#	-o parent=ens160.522 \
#	macvlan_522

	echo "macvlans for ovs2 has added. Everything is okay?"
	read Verify
	
# OVS4 docker network interface
	echo "Install OVS4 docker network interfaces: macvlan334, macvlan544"
#	macvlan334
	macvlan_add 172.16.34.0/29 334
#	docker network create -d macvlan \
#	--subnet=172.16.34.0/29 \
#	-o parent=ens160.334 \
#	macvlan_334
	
#	Macvlan544
	macvlan_add 192.168.4.0/29 544
#	docker network create -d macvlan \
#	--subnet=192.168.4.0/29 \
#	-o parent=ens160.544 \
#	macvlan_544

	echo "macvlans for ovs4 has added. Everything is okay?"
	read Verify

#OVS2 container
	
	echo "Run ovs2 container from socketplane/openvswitch as NET_ADMIN."
#	docker run -itd --name=ovs2 --cap-add NET_ADMIN socketplane/openvswitch
	docker_run ovs2 socketplane/openvswitch
	
	echo "Connect OVS2 interfaces"
	
	docker_network_connect 10.0.32.2 macvlan_223 ovs2
	docker_network_connect 172.16.12.3 macvlan_312 ovs2
	docker_network_connect 172.16.24.2 macvlan_324 ovs2
	docker_network_connect 172.16.0.3 macvlan_400 ovs2
	docker_network_connect 192.168.2.2 macvlan_511 ovs2

# OVS4 container

	echo "Run ovs4 container from socketplane/openvswitch as NET_ADMIN and connect interfaces"
#	docker run -itd --name=ovs4 --cap-add NET_ADMIN socketplane/openvswitch
	docker_run ovs4 socketplane/openvswitch
	
	echo "Connect OVS4 interfaces"
	docker_network_connect 172.16.24.3 macvlan_324 ovs4
	docker_network_connect 172.16.34.3 macvlan_334 ovs4
	docker_network_connect 172.16.0.5 macvlan_400 ovs4
	docker_network_connect 192.168.4.2 macvlan_544 ovs4
	


# OVS2 br config
	echo "Configure OVS2 bridge (ovs-br1)"
	docker_exec ovs2 /usr/share/openvswitch/scripts/ovs-ctl start
	docker_exec ovs2 ovs-vsctl add-br ovs-br1
#	docker exec ovs2 ifconfig ovs-br1 (*IP* netmask *netmask*) up
#	Vertify:       
	docker_exec ovs2 ovs-vsctl show
				   
	docker_exec ovs2 ovs-vsctl add-port ovs-br2 eth1
	docker_exec ovs2 ovs-vsctl add-port ovs-br2 eth3
	docker_exec ovs2 ovs-vsctl add-port ovs-br2 eth2
	docker_exec ovs2 ovs-vsctl add-port ovs-br2 eth4
	docker_exec ovs2 ovs-vsctl add-port ovs-br2 eth5
	docker_exec ovs2 ovs-vsctl add-port ovs-br2 eth6
				   
	docker_exec ovs2 ovs-vsctl set-controller ovs-br2 tcp:172.16.0.10
	
#	Vertify:	
	docker_exec ovs1 ovs-vsctl show

# OVS4 br config
	echo "Configure OVS4 bridge (ovs-br4)"
	docker_exec ovs4 /usr/share/openvswitch/scripts/ovs-ctl start
	docker_exec ovs4 ovs-vsctl add-br ovs-br3
	
#	Vertify:
	docker_exec ovs4 ovs-vsctl show
	
	docker_exec ovs4 ovs-vsctl add-port ovs-br4 eth1
	docker_exec ovs4 ovs-vsctl add-port ovs-br4 eth2
	docker_exec ovs4 ovs-vsctl add-port ovs-br4 eth3
	docker_exec ovs4 ovs-vsctl add-port ovs-br4 eth4

	docker_exec ovs1 ovs-vsctl set-controller ovs-br4 tcp:172.16.0.10
}

usage() {
    cat << EOF
${UTIL}: Helps my diploma project to execute configs easier
usage: ${UTIL} COMMAND

Commands:
  linux1			configure my Linux 1
					Details: ...
  linux2			configure my Linux 2
 
Options:
  -h, --help        display this help message.
EOF
}

case $1 in
	"linux1")
		shift
		linux1
		exit 0
		;;
	"linux2")
		shift
		linux2
		exit 0
		;;	
	-h | --help)
		shift
		usage
		exit 0
		;;	
    *)
        echo >&2 "$UTIL: unknown command \"$1\" (use --help for help)"
        exit 1
        ;;
esac