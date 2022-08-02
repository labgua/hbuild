echo "HBuild for Apache"
echo "LABGUA SOFTWARE 2022"

### carica l'environment
cd "$(dirname "$0")"
. .env

## custom defined functions
hb_info(){
	echo "Questo script permette di effettuare deploy  di progetti symfony su semplici servizi di hosting condiviso"
	echo "List Actions"
	echo "> info: informazioni sullo script"
	echo "> clear: cancella i file costruiti in fase di build"
	echo "> : esegui script"
	echo ""
	echo "Info Variabili"
	echo "HB_WORKING_DIR:$HB_WORKING_DIR"
	
	cd "$HB_WORKING_DIR"
	echo "     --->(PWD):$PWD"
}

substitute() {
	echo "> substitute $1 : $2 -> $3"
	#sed 's/$2/$3/g' $1 
	while IFS= read -r line; do
		printf '%s\n' "${line/$2/$3}" >> newfile
	done < $1
	rm $1
	mv newfile $1
}


copypublic() {
	echo "> copy file from public"
	cp public/.htaccess .
	cp -r public/* .
}

sethtaccess() {
	echo "> set .htaccess in root folder"
	
	securefile .htaccess
	
	files_in_public=($(lsarray public/))
	files_in_root=($(lsarray .))

	for fr in "${files_in_root[@]}"; do
		if ! array_contains files_in_public "$fr"; then
			echo "  * $fr not found in public/ --> SECURE"
			secure "$fr"
		else
			echo "  * $fr found in public/ --> NOT SECURE"
		fi
	done
}

secure(){
	if [[ -d $1 ]]; then
		echo "    securing directory $1 .."
		securedir $1
	elif [[ -e $1 ]]; then
		echo "    securing file $1 .."
		securefile $1
	else
		echo "    whois $1 ?"
	fi
}

## invocare con ($(lsarray $1))
lsarray(){
    ls $1 -A
}

#https://github.com/DevelopersToolbox/bash-snippets/blob/master/src/array-contains/array-contains.sh
function array_contains()
{
    local -n haystack=$1
    local needle=$2

    for i in "${haystack[@]}"; do
        if [[ $i == "${needle}" ]]; then
            return 0 #found 
        fi
    done

    return 1 #notfound 
}

##  Sicurezza per directory
securedir(){
	#RewriteRule "DIR/(.*)$" "-" [F]
	NEWRULE='RewriteRule "'
	NEWRULE+="$1"
	NEWRULE+='/(.*)$" "-" [F]'
	sed -i "/RewriteEngine On/ a $NEWRULE" .htaccess
}


## Sicurezza per file
securefile(){
	#RewriteRule "^FILE" "-" [F]
	NEWRULE='RewriteRule "^'
	NEWRULE+="$1"
	NEWRULE+='" "-" [F]'
	sed -i "/RewriteEngine On/ a $NEWRULE" .htaccess
}

# actions ----------------------------------------------------------------------

function action_build(){
	copypublic
	substitute index.php "dirname(__DIR__).'/vendor/autoload_runtime.php'" "'vendor/autoload_runtime.php'"
	sethtaccess
}

function action_clear(){
	#rm .htaccess
	files_in_public=($(lsarray public/))

	for fp in "${files_in_public[@]}"; do
		echo ">> rm -rf $fp"
		rm -rf $fp
	done	
}

#----------------------------------------------------------------------------------


### spostati nella working dir
cd "$HB_WORKING_DIR"

if [[ $# -ge 1 ]]; then
	
	choose=$1

	case "$choose" in
		info)
			hb_info
			;;
		clear)
			echo "CLEAR"
			echo "WORKING IN DIR:$PWD"
			action_clear
			;;
		*)
			echo "Action $1 not valid"
	esac
else
	echo "BUILD"
	echo "WORKING IN DIR:$PWD"
	action_build
fi

