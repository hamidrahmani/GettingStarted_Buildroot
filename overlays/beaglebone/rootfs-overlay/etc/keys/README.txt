Place the public RSA key used to verify signed checksum files here as `public.pem`.

How to generate a keypair on your host:

  # generate a 2048-bit RSA private key
  openssl genpkey -algorithm RSA -out private.pem -pkeyopt rsa_keygen_bits:2048

  # extract the public key in PEM form
  openssl rsa -in private.pem -pubout -out public.pem

How to sign a checksum file (on host):

  # compute checksum for the image (example: fitImage)
  sha256sum fitImage | awk '{print $1 "  " $2}' > fitImage.sha256

  # sign the checksum file with private key
  openssl dgst -sha256 -sign private.pem -out fitImage.sha256.sig fitImage.sha256

Copy the following files into the board overlay (or directly on the board):
  - public.pem -> /etc/keys/public.pem
  - fitImage.sha256 -> /boot/fitImage.sha256
  - fitImage.sha256.sig -> /boot/fitImage.sha256.sig

The boot-time verifier will check the signature and then compare the checksum. Logs are written to /var/log/boot_verify.log.
