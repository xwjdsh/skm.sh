#! /bin/bash

set -e

readonly COLOR='\033[0;35m'
readonly NC='\033[0m'
readonly SKM_DIR=${SKM_DIR:-$HOME/.skm}

main() {
	if [ $# -eq 0 ]; then
		select_and_use_key
		exit 0
	fi

	case "$1" in
		ls)
			get_keys
			;;
		use)
			if [ -z "$2" ]; then
				select_and_use_key
			else
				use_key $2
			fi
			;;
		new)
			if [ -z "$2" ]; then
				echo "key name required"
				exit 1
			fi
			create_key $2
			;;
		init)
			init
			;;
		-h|--help)
			echo_usage
			;;
		*)
			echo_usage
			exit 1
			;;
	esac
}

current_key(){
	cmd='readlink'
	if [[ $OSTYPE != 'darwin'* ]]; then
		cmd="${cmd} -f"
	fi
	basename $(dirname $($cmd ~/.ssh/id_rsa))
}

get_keys(){
	keys=( $(find $SKM_DIR -mindepth 1 -type d -exec basename {} \;) )
	ck=$(current_key)
	keys=( "${keys[@]/$ck}" )
	echo -e "$(with_color $ck) ${keys[*]}" | xargs | tr ' ' '\n'
}

select_and_use_key(){
	select_key=$(get_keys | fzf --ansi --layout=reverse --prompt "select key:")
	if [ -n $select_key ];then
		use_key $select_key
	fi
}

use_key(){
	key=$1
	key_dir=$SKM_DIR/$key
	if [ ! -d $key_dir ]; then
		echo "directory [$key_dir] not exists" 
		exit 1
	fi
	if [ ! -e $key_dir/id_rsa ];then
		echo "file [$key_dir/id_rsa] not exists" 
		exit 1
	fi
	if [ ! -e $key_dir/id_rsa.pub ];then
		echo "file [$key_dir/id_rsa.pub] not exists" 
		exit 1
	fi

	rsa_file="$HOME/.ssh/id_rsa"
	if [ ! -L $rsa_file ] && [ -e $rsa_file ];then
		echo "file [$rsa_file] is not a symbolic link file" 
		exit 1
	fi

	rsa_pub_file="$HOME/.ssh/id_rsa.pub"
	if [ ! -L $rsa_pub_file ] && [ -e $rsa_pub_file ];then
		echo "file [$rsa_pub_file] is not a symbolic link file" 
		exit 1
	fi

	rm -f ~/.ssh/id_rsa
	rm -f ~/.ssh/id_rsa.pub
	ln -s $key_dir/id_rsa ~/.ssh/id_rsa
	ln -s $key_dir/id_rsa.pub ~/.ssh/id_rsa.pub
	hook=$key_dir/hook
	if [ -e $hook ]; then
		source $hook
	fi
	get_keys
}

create_key(){
	key=$1
	key_dir=$SKM_DIR/$key
	if [ -d $key_dir ];then
		echo "directory [$key_dir] already exists"
		exit 1
	fi
	mkdir -p $key_dir
	ssh-keygen -f $key_dir/id_rsa
}

with_color(){
	echo "$COLOR$1$NC"
}

init(){
	default_key_dir=$SKM_DIR/default
	if [ -d $default_key_dir ];then
		echo "directory [$default_key_dir] already exists" 
		exit 1
	fi

	rsa_file="$HOME/.ssh/id_rsa"
	if [ -L $rsa_file ] && [ -e $rsa_file ];then
		echo "file [$rsa_file] is a symbolic link file" 
		exit 1
	fi

	rsa_pub_file="$HOME/.ssh/id_rsa.pub"
	if [ -L $rsa_pub_file ] && [ -e $rsa_pub_file ];then
		echo "file [$rsa_pub_file] is a symbolic link file" 
		exit 1
	fi

	mkdir -p $default_key_dir
	mv $rsa_file $default_key_dir
	mv $rsa_pub_file $default_key_dir
	use_key "default"
}

echo_usage(){
	echo '
NAME:
   skm.sh - Manage your ssh keys.

USAGE:
   skm.sh [global options] command [command options] [arguments...]

COMMANDS:
   init       Move current SSH key to 
   new        Create new SSH key
   ls         Show keys
   use        Switch SSH key

GLOBAL OPTIONS:
   --help, -h                show help (default: false)
	'
}

main "${@}"
