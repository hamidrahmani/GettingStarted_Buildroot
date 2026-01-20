# restrict acces on bbb from web
following solutions are possible
- whitelist approach
- user access control 
- dedicated unprivileged user
- hard‑map requests to a executables
- authentication (HTTP, mTLS, IP allowlist)
- add CSRF protection 
- file system & process sandboxing

## whitelist approach
The .allow file approach is a directory‑level whitelisting mechanism. Only CGI scripts, commands, or subfolders that are explicitly listed in a .allow file inside that directory are permitted to run.

### steps
- add .allow file inside main folder "whitelistcmd/" and mention the define subfolders.
- add .allow file required subfolder "whitelistcmd/01-power-mgnt/" and mention the define executables.
- adjust the job_run.cgi file to recognize folder/subfolder

## user access control
### steps 
- creeate S20-htpasswd
- create www/whitelistcmd/guard.sh
- change the lighttpd.conf as in current commit
- create S20-htpasswd to provide usernames and initial passwords
- change the passwirds later on 
    - htpasswd etc/lighttpd/webusers.htpasswd maintainer
    - htpasswd etc/lighttpd/webusers.htpasswd homer
    - etc/init.d/S50lighttpd restart


 