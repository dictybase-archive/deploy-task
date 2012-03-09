#!/bin/sh

# insert the startup command for deployment in the run file inside the service directory

PROJECT=$1
RUN_FILE=$2
LOCAL_LIB=$3
APP_DIR=$4

echo -e "#!/bin/sh\nexec 2>1&\n" > $RUN_FILE
echo "export HOME=$HOME" >> $RUN_FILE
echo -e "cd $APP_DIR\n" >> $RUN_FILE
echo "source ${PERLBREW_ROOT}/etc/bashrc" >> $RUN_FILE
echo "perlbrew use $LOCAL_LIB" >> $RUN_FILE
echo  "export MOJO_MODE=production" >> $RUN_FILE
echo  "exec setuidgid $USER plackup -p 9800 -E production -r -R templates -s Starman --workers 10 script/$PROJECT" >> $RUN_FILE

