#!/usr/bin/env bash

DB=""
FUNCTION="NULL"
KEY="NULL"
VALUE="NULL"
ARG="NULL"
STATE=0



_readFunction() {
   case "$FUNCTION" in
	"put") _put;;
	"del") _delete;;
	"select") _select;;
	"flush") _flush;;
    esac

}

_put() {
    grep -q -e "^$KEY=.*" "$DB"
    #$? is used to find the return value of the last executed command.
    #if 0, it exists, if not => 1
    if [ $? = 0 ]
    then
    #regex to find the key to update
	sed -i "$DB" -e "s/^$KEY=.*/$KEY=$VALUE/g"
    else
    #just have to create the key
	echo "$KEY=$VALUE" >> "$DB"
    fi
}

_delete() {
 if [ "$VALUE" = "NULL" ]
    then #sed -i = insert -e = expression (if multiple)
	sed -i "$DB" -e "s/^$KEY=.*/$KEY=/g"
    else
	sed -i "$DB" -e "/^$KEY=$VALUE/d"
    fi
}

_select() {
echo "select"
}

_flush(){
echo -n "" > "$DB"
}
_readKeyName() {
    #if -f wasn't used
    if [ -z "$DB" ]
    then
	DB="sh.db"
    fi
    echo "$KEY" | grep -q -e "^$.*"
    if [ $? = 0 ]
    then
	KEY=$( echo "$KEY" | cut -d"$" -f2- )
	grep -q -e"^$KEY=.*" "$DB"
	if [ $? = 0 ]
	then
	    KEY=$( grep -e "^$KEY=" "$DB" | cut -d'=' -f2- )
	else
	    echo "No such key : any $KEY on the DB." >&2
	exit 1
	fi
    fi

    echo "$VALUE" | grep -q -e"^$.*"
    if [ $? = 0 ]
    then
	VALUE=$( echo "$VALUE" | cut -d"$" -f2- )
	grep -q -e"^$VALUE=.*" "$DB"
	if [ $? = 0 ]
	then
	    VALUE=$( grep -e "^$VALUE=" "$DB" | cut -d'=' -f2- )
	else
	    echo "No such key : any key have this value : $VALUE ." >&2
	    exit 1
	fi
    fi
}

_readKeyValue() {
    if [ ! -e "$DB" ] && [ "$FUNCTION" != "put" ]
    then
	echo "No base found : file $DB doesn't exist." >&2
	exit 1
    fi
    if [ "$FUNCTION" = "none" ]
    then
	echo "No action selected" >&2
	exit 1
    elif [ "$FUNCTION" = "put" ]
    then
	if [ ! -e "$DB" ]
	then
	    echo -n "" > "$DB"
	fi
	if [ "$KEY" = "NULL" ] || [ "$VALUE" = "NULL" ]
	then
	    echo KEY = "$KEY" -- VALUE = "$VALUE"
	    echo "Syntax error: USAGE - put (<clef> | $<clef>) (<valeur> | $<clef>)" >&2
	    exit 1
	fi
    elif [ "$FUNCTION" = "del" ]
    then
	if [ "$KEY" = "NULL" ]
	then
	    echo "Syntax error: USAGE - del (<clef> | $<clef>) [<valeur> | $<clef>] | select [<expr> | $<clef>]" >&2
	    exit 1
	fi
    fi
}

_readArgs(){
if [ -z "$1" ]
    then
	echo "Syntax error: USAGE - bdsh.sh [-k] [-f <db_file>] (put (<clef> | $<clef>) (<valeur> | $<clef>) | del (<clef> | $<clef>) [<valeur> | $<clef>] | select [<expr> | $<clef>] | flush)" >&2
	exit 1
    fi
}

_index() {
    for var in "$@";do
        if [ "$ARG" = "database" ]
        then
        ARG="NULL"
        DB="$var"
        continue
        elif [ "$ARG" = "key" ]
        then
        if [ "$FUNCTION" = "select" ] 
        then
            ARG="NULL"
        else
            ARG="value"
        fi
        KEY="$var"
        continue
        elif [ "$ARG" = "value" ]
        then
            ARG="NULL"
            VALUE="$var"
        continue
        fi
        if [ "$var" = "-k" ]
        then
        STATE=1
        elif [ "$var" = "put" ]
        then
        FUNCTION="put"
        ARG="key"
        elif [ "$var" = "del" ]
        then
        FUNCTION="del"
        ARG="key"
        elif [ "$var" = "select" ]
        then
        FUNCTION="select"
        ARG="key"
        elif [ "$var" = "-f" ]
        then
        ARG="database"
        elif [ "$var" = "flush" ]
        then
        FUNCTION="flush"
        else
        echo "ERROR: Unknown arguments $var" >&2
        exit 1
        fi
    done
}
_readArgs "$1"
_index "$@"
_readKeyValue
_readKeyName
_readFunction


