
# kasmvnc
kasmvnc ubuntu based image (port = 6080), and code-server (port = 8000)

## Build and run  : 
```bash
git clone https://github.com/MhadhbiXissam/kasmvnc.git
cd kasmvnc
make
```
* for vnc open browser on [http://localhost:6080](http://localhost:6080)(pass=123456,user=root)
* for code-server open browser on [http://localhost:8000/](http://localhost:8000)

## pull image and run already build : 
```bash
docker run -it --rm -p 6080:6080 -p 8000:8000 --name ubuntu_vnc mhadhbixissam/ubuntu:vnc
```

## Build on top on this image  : 
```dockerfile
from mhadhbixissam/ubuntu:vnc

run apt update 
#overide or modify xstartuyp here 
##################################################
#                startup script                  #
##################################################
run <<EOF
echo -n '#!/bin/bash
set -euo pipefail
code-server --bind-addr 0.0.0.0:8000  --auth none /root/workspace & 
' > /root/.vnc/xstartup && chmod 700 /root/.vnc/xstartup 
EOF

```
