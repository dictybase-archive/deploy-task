#!/usr/bin/env bash

# $1 = root of the web application folder
installer=$1-dependencies
post_install=$1-daemontool
APP_DIR=$2
PROJECT=`basename $APP_DIR`
PERL_VERSION=$3
LOCAL_LIB=$PERL_VERSION\@$PROJECT

SERVICE=$APP_DIR/service
APP_SERVICE=$SERVICE/$PROJECT'runner'
RUN_FILE=$APP_SERVICE/run




cpanm=$PERLBREW_ROOT/bin/cpanm
perlbrew=$PERLBREW_ROOT/bin/perlbrew

setup_daemontool() {
	if ! [-d $SERVICE ]; then
		echo "$SERVICE folder absent: no post setup with daemontools performed"
		exit 1
	fi

	! [ -d $APP_SERVICE ] && mkdir -p $APP_SERVICE

	if [ -e $RUN_FILE ]; then
		svc -t /service/$PROJECT
	else 
		echo -e "#!/bin/bash\n\n" > $RUN_FILE
		echo -e "$PERLBREW_ROOT/bin/perlbrew use $LOCAL_LIB\n" >> $RUN_FILE
		echo -e "cd $APP_DIR\n" >> $RUN_FILE
		
		$post_install $PROJECT $RUN_FILE

		chmod 1755 $APP_SERVICE
		chmod 755 $RUN_FILE

		ln -s $APP_SERVICE /service/$PROJECT

	fi

}

if [ -e $cpanm ]; then
	echo "------> Upgrading cpanm"
	$cpanm --self-upgrade
else
  echo "------> Installing cpanm"
  $perlbrew install-cpanm
fi

if [ $perlbrew list | grep -v $LOCAL_LIB ]; then
	$perlbrew lib create $LOCAL_LIB
fi

echo "-------> using lib $LOCAL_LIB"
$perlbrew use $LOCAL_LIB

if [ -x $installer ]; then
  $installer $cpanm $APP_DIR && setup_daemontool
fi
