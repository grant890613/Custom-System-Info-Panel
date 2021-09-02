#!/bin/bash

OK=0
CANCEL=1
ESC=255

Menu(){
	
	trap "trap_ctrlc" 2
	
	while :
	do {
		
		Selection=$(dialog --cancel-label "Exit"\
			--menu "System Info Panel" 80 80 5 \
			1 "LOGIN RANK"\
			2 "PORT INFO"\
			3 "MOUNTPOINT INFO"\
			4 "SAVE SYSTEM INFO"\
			5 "LOAD SYSTEM INFO"\
			2>&1 > /dev/tty)
	
	result=$?
	if [ $result -eq $OK ]; then
		Select $Selection
	elif [ $result -eq $CANCEL ];then
		Exit
	elif [ $result -eq $ESC ];then
		echo "Esc pressed" >&2
		exit 1
	fi
	echo $?
	} done
}

Select(){
	Choice=$1

	case $Choice in
		1)
			LoginRank
			;;

		2)
			PortInfo
			;;

		3)
			MountpointInfo
			;;

		4)
			SaveSystemInfo
			;;

		5)
			LoadSystemInfo	
			;;

			
	esac
}



LoginRank(){
	#use column 2 sort
	last | awk '{num[$1]++} END {for(i in num){printf "%-10s %-10d\n",i,num[i]}}' | sort -k2 -n -r | \
	while read -r line
	do
		c=$[ c + 1 ]
		array[c]=$line
		#echo "${array[c]}"
		if [ $c -eq 5 ];then
			dialog --stdout --title "LOGIN RANK" --msgbox \
			"Rank Name       Times\n
			1    ${array[1]}\n
			2    ${array[2]}\n
			3    ${array[3]}\n
			4    ${array[4]}\n
			5    ${array[5]}"   20 50
			break
		fi
	done

}

PortInfo(){
	while true;
	do
		info=$(sockstat -4 -l | awk 'NR>1 {printf "%-20s%4s_%-10s\n",$3,$5,$6}')
		ch=$(dialog --stdout --menu "PORT INFO(PID and Port)" 50 70 20 $info)
		if [ $? -ne 0 ];then
			break
		fi
		port_com=$(ps -u -j -p $ch | awk 'NR==2 {print $11}' | cut -f1 -d:)
		
		touch AAAA
		true >AAAA
		ps -u -j -p $ch | awk 'NR==2 {print "USER: "$1"\nPID: "$2"\nPPID: "$13"\nSTAT: "$8"\n%CPU: "$3"\n%MEM: " $4}' | while read -r line
		do
	        	echo "$line" >> AAAA
		done
		let c=0
		while read -r line
		do
			c=$[ c + 1 ]
			arr[c]=$line
		done < AAAA
		rm AAAA

		dialog --title "Process Status: $ch" --msgbox "${arr[1]}\n${arr[2]}\n${arr[3]}\n${arr[4]}\n${arr[5]}\n${arr[6]}\nCOMMAND: $port_com" 30 50
	done

}

MountpointInfo(){

	while true;
	do
		#-h (kb mb g) -T disk type
		mount_info=$(df -h -T -t nfs,zfs | awk 'NR>1 {printf "%-40s%-30s\n",$1,$7}')
		ch_info=$(dialog --stdout --menu "MOUNTPOINT INFO" 50 70 20 $mount_info)

		if [ $? -ne 0 ];then
			break
		fi
	        mp=$(df -h -T $ch_info | awk 'NR==2 {printf "Filesystem: %s\nType: %s\nSize: %s\nUsed: %s\nAvail: %s\nCapacity: %s\nMounted_on: %s",$1,$2,$3,$4,$5,$6,$7}')
	        dialog --title "$ch_info" --msgbox "$mp" 20 40
	done
}

SaveSystemInfo(){
	while true;
	do
		s_route=$(dialog --stdout --title "Save to file" --inputbox "Enter the path:" 10 50)
		
		if [ $? -ne 0 ];then
			break
		fi

		check=$(echo "$s_route" | grep "^/")	
		if [ $check ]; then
			f_name=$(echo $s_route | awk -F'/' '{print $NF}')
			f_route=$(echo $s_route | awk -F'/' '{for(i=1;i<NF;++i){printf "%s/",$i}}')
		else
			s_route=$(echo "$(getent passwd "$USER" | cut -d: -f6)/$s_route")
			f_name=$(echo $s_route | awk -F'/' '{print $NF}')
			f_route=$(echo $s_route | awk -F'/' '{for(i=1;i<NF;++i){printf "%s/",$i}}')
		fi
		
		
		#f_name=$(echo $s_route | awk -F'/' '{print $NF}')
		#f_route=$(echo $s_route | awk -F'/' '{for(i=1;i<NF;++i){printf "%s/",$i}}')


		exist=$(test -d $f_route && echo "true" || echo "false")


		if [ $exist == "false" ];then
			dialog --stdout --title "Directory not found" --msgbox "$f_route not found!" 10 50
			continue
		fi


		touch temp

		        md=$(date)
			m0=$(echo " This system report is generated on $md")
			ms=$(echo "================================================================")
			m1=$(sysctl kern.hostname | cut -f2 -d:)
			m2=$(sysctl kern.ostype | cut -f2 -d:)
			m3=$(sysctl kern.osrelease | cut -f2 -d:)
			m4=$(sysctl hw.machine | cut -f2 -d:)
			m5=$(sysctl hw.model | cut -f2 -d:)
			m6=$(sysctl hw.ncpu | cut -f2 -d:)
			t=$(sysctl hw.physmem | cut -f2 -d:)
			m7=$(echo "scale=2;$t/1073741824" | bc)
			u=$(sysctl hw.usermem | cut -f2 -d:)
			m8=$(echo "scale=2;($u)*100/$t" | bc)
			m9=$(w | awk 'NR>2 {print $1}' | uniq -c | awk 'END {print NR}')	
		
		total_msg=$(echo "$m0\n
	        $ms\n
	        Hostname:$m1\n
	        OS Name:$m2\n
	        OS Release Version:$m3\n
	        OS Architecture:$m4\n
	        Processor Model:$m5\n
	        Number of Processor Cores:$m6\n
	        Total Physical Memory: $m7 GB\n
	        Free Memory (%): $m8\n
	        Total logged in users : $m9\n")

	        echo "$m0" >> temp
	        echo "$ms" >> temp
	        echo "Hostname:$m1" >> temp
	        echo "OS Name:$m2" >> temp
	        echo "OS Release Version:$m3" >> temp
	        echo "OS Architecture:$m4" >> temp
	        echo "Processor Model:$m5" >> temp
	        echo "Number of Processor Cores:$m6" >> temp
	        echo "Total Physical Memory: $m7 GB" >> temp
	        echo "Free Memory (%): $m8" >> temp
		echo "Total logged in users : $m9" >>temp
		echo "Yes">>temp

		mv temp $s_route


		result=$?
		if [ $result -ne 0 ];then
			dialog --stdout --title "Permission Denied" --msgbox "No write permission to $s_route" 10 50
			continue
		fi


		dialog --stdout --title "System Info" --msgbox "$total_msg\n\n The output file is saved to $s_route" 50 80
	        break	
		
	done
}

LoadSystemInfo(){
	#!/bin/bash

	while true;
	do
		s_route=$(dialog --stdout --title "Load from file" --inputbox "Enter the path:" 10 50)
			
		if [ $? -ne 0 ];then
			break
		fi

		check=$(echo "$s_route" | grep "^/")	
		if [ $check ]; then
			f_name=$(echo $s_route | awk -F'/' '{print $NF}')
			f_route=$(echo $s_route | awk -F'/' '{for(i=1;i<NF;++i){printf "%s/",$i}}')
		else
			s_route=$(echo "$(getent passwd "$USER" | cut -d: -f6)/$s_route")
			f_name=$(echo $s_route | awk -F'/' '{print $NF}')
			f_route=$(echo $s_route | awk -F'/' '{for(i=1;i<NF;++i){printf "%s/",$i}}')

		fi
		

		exist=$(test -f $s_route && echo "true" || echo "false")

		if [ $exist == "false" ];then
			dialog --stdout --title "File not found" --msgbox "$s_route not found!" 10 50
			continue
		fi
		

		msg=$(cat $s_route)
		result=$?
		
		if [ $result -ne 0 ];then
			dialog --stdout --title "Permission Denied" --msgbox "No read permission to $s_route" 10 50
			continue
		fi
		msg=$(cat $s_route | sed '$d')

		check=$(tail -n 1 $s_route)
		if [ "$check" != "Yes" ];then
			dialog --stdout --title "File not valid" --msgbox "The file is not generate by this program," 10 50
			continue
		fi

		title=$(echo $s_route | awk -F'/' '{print $NF}')
		dialog --stdout --title "$title" --msgbox "$msg" 50 80
	
		break
	done
}

trap_ctrlc ()
{
	# perform cleanup here
	echo "Ctrl + C pressed"
	exit 2
}


trap_esc ()
{
	# perform cleanup here
	echo "Esc pressed"
	exit 1
}



Exit(){
	clear
	echo "Exit"
	exit 0
}

Menu


