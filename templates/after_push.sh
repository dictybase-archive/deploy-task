#!/bin/sh

# $1 = root of the web application folder
installer=$1-dependencies
post_install=$1-daemontool
APP_DIR=$2
PROJECT=`basename $APP_DIR`
PERL_VERSION=$3
LOCAL_LIB=$PERL_VERSION\@$PROJECT
SERVICE=$APP_DIR/service
APP_SERVICE=$SERVICE/${PROJECT}runner
RUN_FILE=$APP_SERVICE/run
ENCRYPT_CONFIG_FOLDER=$4
PASSWD=$5
cpanm=$PERLBREW_ROOT/bin/cpanm
perlbrew=$PERLBREW_ROOT/bin/perlbrew

setup_daemontool() {
	! [ -d $APP_SERVICE ] && mkdir -p $APP_SERVICE
	if ! [ -e $RUN_FILE ];then 
		cd $APP_DIR
		deploy/$post_install $PROJECT $RUN_FILE $LOCAL_LIB $APP_DIR

		chmod 1755 $APP_SERVICE
		chmod 755 $RUN_FILE
		ln -s $APP_SERVICE /service/$PROJECT
	fi

}

copy_encrypted_config() {
	if ! [ -z "$MOJO_MODE" ]; then
	    MOJO_MODE='production'
	fi

	encrypt_config=${ENC_CONFIG_FOLDER}/${PROJECT}/${MOJO_MODE}.crypt
	plain_config=${ENC_CONFIG_FOLDER}/${PROJECT}/${MOJO_MODE}.yml
	sample_config=${APP_DIR}/config/sample.yml

	if [ -e "$encrypt_config" ]; then
     gpg --yes --passphrase $PASSWD --output $plain_config $encrypt_config	   
     
     if [ -e "$sample_config" ]; then
        running_perl=`which perl`
        $running_perl ${APP_DIR}/deploy/merge_config.pl $plain_config $sample_config $MOJO_MODE
     fi

     rm $plain_config
	fi
}

if [ -e $cpanm ]; then
	echo "------> Upgrading cpanm"
	$cpanm --self-upgrade
else
  echo "------> Installing cpanm"
  $perlbrew install-cpanm
fi

if ! [ `$perlbrew list | grep $PROJECT` ]; then
	$perlbrew lib create $LOCAL_LIB
fi

echo "-------> using lib $LOCAL_LIB"
export PERLBREW_ROOT=$PERLBREW_ROOT
export PERLBREW_HOME=$PERLBREW_HOME
source $PERLBREW_ROOT/etc/bashrc
perlbrew use $LOCAL_LIB

cd $APP_DIR
if [ -x deploy/$installer ]; then
  deploy/$installer cpanm $APP_DIR  && copy_encrypted_config && setup_daemontool
fi
