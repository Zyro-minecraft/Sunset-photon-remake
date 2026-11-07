#!/usr/bin/env bash
# Headless in-game test: Forge 1.20.1 + Oculus on Mesa llvmpipe (Xvfb), local vanilla server with frozen sunset.
# Needs network access to Mojang / Forge / Modrinth hosts. Usage: tools/ingame-test.sh   then  tools/ingame-test.sh shot out.png "~ ~ ~ 90 -3"
set -e
MC=${MC:-/root/mc}; REPO=$(cd "$(dirname "$0")/.." && pwd)
if [ "${1:-}" = shot ]; then
  echo "tp Wanderer $3" > $MC/server/cmd.fifo; sleep 12; DISPLAY=:99 import -window root "$2"; exit; fi
if [ "${1:-}" = reload ]; then
  rm -rf $MC/shaderpacks/EternalSunset/shaders && cp -r $REPO/shaders $MC/shaderpacks/EternalSunset/
  DISPLAY=:99 xdotool key --window "$(DISPLAY=:99 xdotool search --name Minecraft | head -1)" r; exit; fi
apt-get install -y mesa-utils xdotool imagemagick xvfb >/dev/null; pip install -q portablemc
mkdir -p $MC/{mods,shaderpacks/EternalSunset,config,server}; cd $MC
portablemc --main-dir $MC start forge:1.20.1 --dry >/dev/null
curl -sSLo mods/oculus.jar https://cdn.modrinth.com/data/GchcoXML/versions/iQ1SwGc3/oculus-mc1.20.1-1.8.0.jar
curl -sSLo mods/embeddium.jar "https://cdn.modrinth.com/data/sk9rgfiA/versions/UTbfe5d1/embeddium-0.3.31%2Bmc1.20.1.jar"
cp -r $REPO/shaders shaderpacks/EternalSunset/   # Oculus rejects symlinked packs
printf 'enableShaders=true\nshaderPack=EternalSunset\n' > config/oculus.properties
printf 'onboardAccessibility:false\ntutorialStep:none\njoinedFirstServer:true\nskipMultiplayerWarning:true\npauseOnLostFocus:false\nrenderDistance:6\nmaxFps:30\nnarrator:0\nsoundCategory_master:0.0\n' > options.txt
U=$(curl -s https://piston-meta.mojang.com/mc/game/version_manifest_v2.json | python3 -c "import json,sys;print([v['url'] for v in json.load(sys.stdin)['versions'] if v['id']=='1.20.1'][0])")
curl -sSLo server/server.jar "$(curl -s $U | python3 -c "import json,sys;print(json.load(sys.stdin)['downloads']['server']['url'])")"
cd server; echo eula=true > eula.txt
printf 'online-mode=false\nlevel-seed=-4172144997902289642\ngamemode=creative\ndifficulty=peaceful\nview-distance=6\n' > server.properties
rm -f cmd.fifo; mkfifo cmd.fifo; (tail -f cmd.fifo | java -Xmx2G -jar server.jar nogui > server.log 2>&1 &)
until grep -q 'Done (' server.log; do sleep 3; done
for c in "gamerule doDaylightCycle false" "time set 12600" "gamerule doWeatherCycle false" "weather clear"; do echo "$c" > cmd.fifo; done
(Xvfb :99 -screen 0 1280x720x24 >/dev/null 2>&1 &); sleep 1; cd $MC
DISPLAY=:99 nohup portablemc --main-dir $MC start forge:1.20.1 -u Wanderer --resolution 1280x720 --join-server 127.0.0.1 --jvm-arg=-Xmx4G > client.out 2>&1 &
until grep -q 'Wanderer joined' server/server.log; do sleep 5; done; sleep 20
DISPLAY=:99 xdotool key --window "$(DISPLAY=:99 xdotool search --name Minecraft | head -1)" F1
echo "ready: client log $MC/client.out"
