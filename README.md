# GettingStarted_Buildroot
This is a repository to host a buildroot with my own application in order to playing around with buildroot and finding out how everything comes toghether.


Note: dont forget to create / doublecheck the ssh-key
    - ssh-keygen -t ed25519 -C "deine-email@example.com"
    - copy the .pub key in your github under ssh-key
    - test your access
        - ssh -T git@github.com

steps done so far:
- donwload the zip file from https://github.com/buildroot/buildroot 
- navigate to the Gettingstarted_buildroot folder
- unpacked the zip file here (Gettingstarted_buildroot)
- create a new branch
    - git checkout -b base_buildroot
- add the changes (unzipped buildroot code) into branch and push to the github
    - git add .
    - git commit -m "add buildroot code from official buildroot reposirity"
    - git push origin base_buildroot


