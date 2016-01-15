if [ "$SLACKPKGPLUS" = "on" ];then
    # Slackpkg+ Dialog functions
    # Original functions from slackpkg modified by Marek Wodzinski (majek@mamy.to)
    #
    export DIALOG_CANCEL="1"
    export DIALOG_ERROR="126"
    export DIALOG_ESC="1"
    export DIALOG_EXTRA="3"
    export DIALOG_HELP="2"
    export DIALOG_ITEM_HELP="2"
    export DIALOG_OK="0"

    # Show the lists and asks if the user want to proceed with that action
    # Return accepted list in $SHOWLIST
    #

    if [ "$DIALOG" = "on" ] || [ "$DIALOG" = "ON" ]; then
	function showlist() {
		if [ "$ONOFF" != "off" ]; then
			ONOFF=on
		fi

		cat $TMPDIR/greylist.* >$TMPDIR/greylist
		if [ "$GREYLIST" == "off" ];then
		  >$TMPDIR/greylist
		fi
		rm -f $TMPDIR/dialog.tmp
		
		if [ "$2" = "upgrade" ]; then
			ls -1 $ROOT/var/log/packages > $TMPDIR/tmplist
			for i in $1; do
			  	TMPONOFF=$ONOFF
				BASENAME=$(cutpkg $i)
				PKGFOUND=$(grep -m1 -e "^${BASENAME}-[^-]\+-[^-]\+-[^-]\+$" $TMPDIR/tmplist)
                                REPOPOS=$(grep -m1 " $(echo $i|sed 's/\.t.z//') "  $TMPDIR/pkglist|awk '{print $1}'|sed 's/SLACKPKGPLUS_//')
				REPOPOSFULL=$(grep -m1 " $(echo $i|sed 's/\.t.z//') "  $TMPDIR/pkglist|sed 's/SLACKPKGPLUS_//'|awk '{print $0,gensub(/([0-9]+)([^0-9]*)/,"\\1 \\2_","1",$5),$6}')
				PKGVER=$(echo $i|rev|cut -f3 -d-|rev)
				ALLFOUND=$(echo $(grep " ${BASENAME} " $TMPDIR/pkglist|sed -r -e 's/SLACKPKGPLUS_//' -e 's/^([^ ]*) [^ ]* ([^ ]*) [^ ]* ([^ ]*) .*/\2-\3(\1) ,/')|sed 's/,$//')

				grep -m1 " ${BASENAME} " $TMPDIR/pkglist|grep -q -Ew -f $TMPDIR/greylist && TMPONOFF="off"
				echo "$REPOPOSFULL $i \"$REPOPOS\" $TMPONOFF \"installed: $PKGFOUND  -->  available: $ALLFOUND\"" >>$TMPDIR/dialog.tmp.1
			done
# 1         2                  3      4    5 6                                7             8   9 1011                               12-
# slackware xf86-video-nouveau 1.0.12 i586 1 xf86-video-nouveau-1.0.12-i586-1 ./slackware/x txz 1 _ xf86-video-nouveau-1.0.12-i586-1 xf86-video-nouveau-1.0.12-i586-1.txz "slackware" on "installed: xf86-video-nouveau-git_20151119_6e6d8ac-i586-1  -->  available: blacklist-1(extra) , 1.0.12-1(slackware) "

			case "$SHOWORDER" in
				"repository") SHOWORDER=1;;
				"arch")       SHOWORDER=4;;
				"package")    SHOWORDER=6;;
				"path")       SHOWORDER=7;;
				"tag")        SHOWORDER=10;;
				*)            SHOWORDER=6;;
			esac
			cat $TMPDIR/dialog.tmp.1 | awk '{print $'$SHOWORDER',$0}'|sort|cut -f13- -d" " >$TMPDIR/dialog.tmp
			HINT="--item-help"
		else
			for i in $1; do
			  	TMPONOFF=$ONOFF
                                REPOPOS=$(grep -m1 " $(echo $i|sed 's/\.t.z//') "  $TMPDIR/pkglist|awk '{print $1}'|sed 's/SLACKPKGPLUS_//')
				grep -m1 " $(echo $i|sed 's/\.t.z//') "  $TMPDIR/pkglist| grep -q -Ew -f $TMPDIR/greylist && TMPONOFF="off"
				echo "$i \"$REPOPOS\" $TMPONOFF" >>$TMPDIR/dialog.tmp
			done
			HINT=""
		fi
		# This is needed because dialog have a limit of arguments.
		# This limit is around 20k characters in slackware 10.x
		# Empiric tests on slackware 13.0 got a limit around 139k.
		# If we exceed this limit, dialog got a terrible error, to
		# avoid that, if the number of arguments is bigger than 
		# DIALOG_MAXARGS we remove the hints. If even without hints 
		# we can't got less characters than DIALOG_MAXARGS we give an 
		# error message to the user ask him to not use dialog
		if [ $(wc -c $TMPDIR/dialog.tmp | cut -f1 -d\ ) -ge $DIALOG_MAXARGS ]; then
			mv $TMPDIR/dialog.tmp $TMPDIR/dialog2.tmp
			awk '{ NF=3 ; print $0 }' $TMPDIR/dialog2.tmp > $TMPDIR/dialog.tmp
			HINT=""
		fi
		DTITLE=$2
		if [ "$DOWNLOADONLY" == "on" ];then
		  DTITLE="$DTITLE (download only)"
		fi
		cat $TMPDIR/dialog.tmp|xargs dialog --title "$DTITLE" --backtitle "slackpkg $VERSION" $HINT --checklist "Choose packages to $2:" 19 70 13 2>$TMPDIR/dialog.out
		case "$?" in
			0|123)
				dialog --clear
			;;
			1|124|125|126|127)
				dialog --clear
				echo -e "DIALOG ERROR:\n-------------" >> $TMPDIR/error.log
				cat $TMPDIR/dialog.out >> $TMPDIR/error.log
				echo -e "-------------
If you want to continue using slackpkg, disable the DIALOG option in
$CONF/slackpkg.conf and try again.

Help us to make slackpkg a better tool - report bugs to the slackpkg
developers" >> $TMPDIR/error.log
				cleanup
			;;
		esac
		SHOWLIST=$(cat $TMPDIR/dialog.out | tr -d \")
		if [ -z "$SHOWLIST" ]; then
			echo "No packages selected for $2, exiting."
			cleanup
		fi
	}
    fi
fi
