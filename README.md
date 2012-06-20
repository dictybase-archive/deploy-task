## Getting started

Add a makefile or Build.PL declaring dependencies for your mojolicious web application

Check out this repository as a submodule inside your web application folder

    git submodule add git://github.com/dictyBase/deploy-task.git tasks

Install Rex module

    cpanm -n Rex

Add a file named Rexfile to import all deploy tasks

     use lib 'tasks/lib';
     
     # server authorization
     user 'user';
     private_key 'key';
     public_key 'pkey';
     key_auth;
     set task_folder => 'tasks';

		 # import modules
     require Tasks;

To see list of tasks available

     rex -T
     git:deploy:hooks               Install git hooks in the remote repository
     git:deploy:init                Create mojolicious deployment scripts for your web application
     git:deploy:setup               Create remote git repository and install push hooks

     ......

     echo Rexfile >> .gitignore

### Setting up the remote system
The following tasks has to be run minimally

+ git:install
+ setup:daemontools
+ perlbrew:install
+ perlbrew:install-cpanm
+ perl:install
+ perl:install-toolchain


## Deploying web application

### Quick steps

* Install git hooks

```rex -H <host> git:deploy:setup ```

* Create the local deployment scripts

```rex 'git:deploy:init'```

* Upload configuration file if any(optional)

``` 
rex -H <host> git:deploy:upload-config --config=<config_file> --remote-folder=<folder>
```

* Push to remote for deploying

```
git add deploy; 
git commit -m 'added deploy folder'
git remote add deploy ssh://user@myhost.mydomain.com/home/foo/git
git push deploy
```

### Details

Install the git hooks

```rex -H <host> git:deploy:setup```

It will create a remote git repository and install the default post recieve hook from
hooks/post-receive.template from inside __deploy__ submodule. By default, for example in case
of user __foo__ with project __zombie__ the git repository will be 

     /home/foo/git/zombie

and the deployed folder will be

     /home/foo/gitweb/zombie

The behaviour can be changed by passing parameters to the following options 

__--git-path=[${HOME}/git/<project_name>]__     Top level remote folder where the git repository will be
pushed. The actual git folder will reside in a folder below that matches the project name.

__--branch=[release]__                          The git branch which will be deployed

__--deploy-to=[${HOME}/gitweb/<project_name>]__ The top level folder where the repository will be
deployed.

__--perl-version=[perl-5.10.1]__                The perl version(with perlbrew) that will be used for deployment

__--deploy-mode=[reverse-proxy|fcgi]__          The deploy mode script which will be invoked by
after_push script

__--hook=[hooks/post-receive.template]__        The post receive hook(script) which will be
invoked after every git push


__--remote-config-folder=[$HOME/config]__       The folder from where web application's
configuration file will be copied. It is expected to contain sensitive information and
therefore excluded from keeping it in the repository.

Example

```
rex -H <host> git:deploy:setup  --git-path=/project/git  --deploy-to=/project/webapps \
     --hook=tasks/hooks/post-receive-deploy.template --branch=release \
     --remote-config-folder=/project/config --deploy-mode=fcgi
```

Create the local deployment scripts

    rex 'git:deploy:init'

It will create a **deploy** folder and copy bunch of shell and perl scripts that could be invoked
by the git post recieve hook. Then add this **deploy** folder in the repository

    git add deploy; git commit -m 'added deploy folder'

Add the remote repository in git

    git remote add deploy ssh://user@myhost.mydomain.com/home/foo/git/zombie

Now push the current branch to this remote 

    git push deploy

The post receive hook as set by __hook__ option will 

* check out the code(without git metadata) wherever the __deploy-to__ was set to
* Invoke ```after_push``` shell script in the background

The **after_push** script will load appopiate deployer script. The deployer script is
expected to have six functions defined, one for installing dependencies and other one for
creating daemontools service. Each of them will also have a after and before hooks. Then
the **after_push** script runs the following steps ...

* check for perlbrew, create local lib and install cpanm plus carton.
* install dependencies using three functions 
* __before_install_dependencies__ : generally empty, use it if neccessary
* __install_dependencies__: invoke ```carton install```
* __after_install_dependencies__: install plack and server bindings. For fcgi it uses
   FCGI::ProcManager and for reverse-proxy it uses Starman
* __before_create_daemontools_runfile__: creates the service directory
* __create_daemontools_runfile__:
* __after_create_daemontools_runfile__: symlinks to the system /service directory
* copy the config file: uses the **remote-config-folder** parameter to look for config
  file. Uses merge_config.pl script for this.

