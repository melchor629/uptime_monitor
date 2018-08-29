## Uptime monitor

Known when your network devices are connected to your home's network with a good precission in time. Everything in Docker containers, and ARM friendly. Uses [fing][1] to observe the changes and a little parser that listens for changes in a file fing edits and stores the data in an [influxdb][2] measure and some extra data into a [redis][3] database. It is available a simple page that allows you to monitor quickly the uptime.

## How it works?

Uses [fing][1] app to detect the devices available in the network and if they are connected or not. Using the right arguments, `fing` can write the scanning into a `.csv` file. And now the little [python script][5] (called `fing-parser`) comes into the game. This script listen for changes in a folder, and when a file is changed (and is a csv) stores all the information in the influxdb and redis databases.

To make it work, `fing` should start with this arguments `fing -d true -n NETWORK_IP/NETWORK_MASK -o table,csv,/fing/SOME_NAME.csv`. The `-d` argument is to force obtain the domain names of every device. If you don't want that, you can disable with a `false`. The `NETWORK_IP/NETWORK_MASK` must point to the network you want to watch. As an (typical) example, `192.168.1.0/24` would be a value for that. The `-o` thing tells fing to write to that `.csv` file (choose a wise name :).

You can listen for different networks by creating different `fing` instancies. But remember to change the name of the `.csv`s files, to avoid problems.

The python script listens for every change in the shared folder (shared between all fing instances and the script), but only acts when the change has something to do with `.csv`s. All information will be stored in the same measure in `influxdb` (retention policy must be `week_rp` and measure must be `activity`) and in the same `redis` database (with keys prefixed with `fingo:` and the MAC after). A structure for initial `influxdb` database can be found in the folder `/influxdb`.

The simple page has a fully functional dashboard to observe all information stored in the databases. It is optimized enough to sniff around, but maybe not at all for lots of devices in screen. It is a simple node.js app with an `index.html` that shows the dashboard.

```
Structure of a deployment:

┌───────┐
│ fing1 │─────────┐
└───────┘         │                                   ┌───────┐
                  │                              ┌────│ redis │─────┐
┌───────┐         │             ┌─────────────┐  │    └───────┘     │ ┌─────────┐
│ fing2 │─────────┼──fing_data──│ fing-parser │──┤                  ├─│ web app │
└───────┘         │   volume    └─────────────┘  │   ┌──────────┐   │ └─────────┘
                  │                              └───│ influxdb │───┘
┌───────┐         │                                  └──────────┘
│ fingN │─────────┘
└───────┘
```

## The docker-compose file

The repository has a `docker-compose.yaml` file that I'm using right now to deploy the system in my home. Could be a good start for a deployment in your home. For helping to build everything, a bash script called `docker.sh` is provided that allows you to build, remove, push and pull the images. Maybe the last two are not needed, but well, they are in the script just in case. See `./docker.sh --help` to know how to use it, but probably a `./docker.sh build fing fing-parser` will be enough.

The `monitor` service has some tags for a deployment in [træfik][4]. Could be useful if you have more web services in your device. Pay attention copying all labels, maybe this configuration is not suitable for you, or directly, don't work.

It is also available a configuration for a [chronograf][2] instance. Allows you to inspect the data inside an `influxdb` database quickly.

## Recommendations

As this project is intended to be run in a little computer, like a Raspberry Pi, this recommendations from me to you could be useful:

 1. Prepare the images in your computer instead in your destination. To do so:
   - You need Docker for macOS (on macOS) or (in Linux) have enabled `binfmt` and installed qemu for enable ARM code to be executed in you CPU. Some time ago, I [wrote about enabling this on Linux][6] in my blog.
   - Run `./docker.sh build fing fing-parser`.
   - Pass your images with a pipe. (uhm?) `docker image save fing | ssh pi@raspberry docker image load` and `docker image save fing-parser | ssh pi@raspberry docker image load` to send both images from your computer to the destination computer.
 2. Always have a `restart` policy distinct from `no` in the `docker-compose-yaml`. If your device resets for some reason, the containers will restart (instead of keep them stopped).
 3. Have fun
 4. Maybe I think more of them :)

  [1]: https://fing.io
  [2]: https://influxdata.com
  [3]: https://redis.io
  [4]: https://traefik.io
  [5]: https://github.com/melchor629/uptime_monitor/blob/master/fing-parser/parse.py
  [6]: https://melchor9000.me/blog/2018/7/23/multi-arch-docker
