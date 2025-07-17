Note: dont forget to create / doublecheck the ssh-key
- create the keys if not already availabe 
    - ssh-keygen -t ed25519 -C "deine-email@example.com"
- copy the .pub key in your github under ssh-key
- test your access
    - ssh -T git@github.com

set up the base of buildroot:
- download the zip file from https://github.com/buildroot/buildroot 
- navigate to the Gettingstarted_buildroot folder
- unpacked the zip file here (Gettingstarted_buildroot)
- create a new branch
    - git checkout -b base_buildroot
- add the changes (unzipped buildroot code) into branch and push to the github
    - git add .
    - git commit -m "add buildroot code from official buildroot reposirity"
    - git push origin base_buildroot


delete a file on git:
- git rm <yourfile>
- git commit -m " <finename> and reason for deleting"
- git push origin main

syncronize a branch xyz with currect version of main:
- git switch xyz
- git fetch origin
- git merge origin/main