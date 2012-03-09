

## Getting started

Add a makefile or Build.PL declaring dependencies for your mojolicious web application

Check out this repository as a submodule inside your web application folder
    git submodule add git://..... tasks

Install Rex module
    cpanm Rex
Add a file named Rexfile to import all deploy tasks
Add the following lines in your Rexfile
     
     use lib 'tasks/lib';
     
     # server authorization
     user 'user';
     private_key 'key';
     public_key 'pkey';
     key_auth;
     set task_folder 'tasks';

		 # import module
     require git:deploy;

See list of tasks available
     rex -T
     git:deploy:hooks               Install git hooks in the remote repository
     git:deploy:init                Create mojolicious deployment scripts for your web application
     git:deploy:setup               Create remote git repository and install push hooks

Install the git hooks
    rex -H 'myhost.mydomain.com' git:deploy:setup 
  It will create a remote git repository and install the default post recieve hook from
  hooks/post-receive.template from inside the submodule. By default, for example for user
  **foo** the git repository will be 
     /home/foo/git
  and the deployed folder will be
     /home/foo/gitweb

Create the local deployment scripts(optional)
    rex 'git:init'
  It will create a **deploy** folder and copy bunch of shell scripts that could be invoked
  by the git post recieve hook.
  Add this **deploy** folder in the repository
    git add deploy; git commit -m 'added deploy folder'

Add the remote repository in git
   git remote add deploy ssh://user@myhost.mydomain.com/home/foo/git

Now push the current branch to this remote and it will check out the code in
/home/foo/gitweb
   git push deploy
    

