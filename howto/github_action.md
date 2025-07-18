upload the binary to "github releases"

Manuelly:
- navigate to tag --> release
- click on release tab --> select Draft new release
- create a new tag e.g. bv1.0
- add title and description
- attach the binary
    - note: binary not larger that 2GB and foramt should be zip, tar, .....
    - tar -czvf zImage.tar.gz zImage
- click on publish release


Automatically:
use github actions to automate process:
- create a release.yml file and save under .github/workflows/release.yml as below
------------------------------------------------------------------------------------
name: BuildTestRelease

on:                                         # define the trigger that triggers the workflow
  push:
    tags:
      - 'v*'                                # Triggers on version tags like v1.0.0

jobs:
  build:
    name: qemu buildroot image
    runs-on: ubuntu-latest                  # tells github to use latest ubuntu environment to build

    steps:
      - name: Checkout code
        uses: actions/checkout@v4           # user github built-in features to clone my code into github runner

      - name: Set up build environment
        run: sudo apt-get update && sudo apt-get install -y build-essential     # install everything that github needs to have inroder to build the code

      - name: Build binary
        run: |
          make                              # tells github which command needs to be use for building the code
      - name: prepare release files

        run: |
          mkdir -p dist
          cp output/images/zImage dist/
          cp output/images/rootfs.ext2 dist/
          cp output/images/versatile-pb.dtb dist/
          cp start-qemu.sh dist/

      - name: Generate checksum
        run: |
          cd dist
          sha256sum * > checksums.sha256    # generate the checksum to verify the binary and put into release
   
      - name: Upload Release Assets
        uses: softprops/action-gh-release@v2    # user github built-in features to create a release and upload the files
        with:
          files: |
            dist/zImage
            dist/rootfs.ext2
            dist/versatile-pb.dtb
            dist/start-qemu.sh
            dist/checksums.sha256

        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }} 

------------------------------------------------------------------------------------