import asyncio
from datetime import datetime
import json
import os
import time
from urllib import request

import redis

from watchgod import awatch


class DeviceStatus:
    def __init__(self, line):
        split = line[:-1].split(';')
        self.ip_address = split[0]
        self.up = split[2] == 'up'
        try:
            self.last_change = datetime.strptime(split[3], '%Y/%m/%d %H:%M:%S')
        except:
            self.last_change = None
        self.hostname = split[4] if split[4] else None
        self.mac = split[5]
        self.hw_vendor = split[6]

    def __str__(self):
        return ('{mac}/{ip_address} {up} - {hostname} {hw_vendor} ({last_change})'
                    .format(ip_address=self.ip_address,
                            up=self.up,
                            last_change=self.last_change,
                            hostname=self.hostname,
                            mac=self.mac,
                            hw_vendor=self.hw_vendor))

    def to_iql(self):
        return 'activity,mac={} state={}'.format(self.mac, 1 if self.up else 0)


def to_influxdb(states):
    data = b'\n'.join([state.to_iql().encode('utf-8') for state in states])
    url = 'http://{}:{}/write?db={}'.format(os.environ['INFLUXDB_HOST'],
                                            os.environ['INFLUXDB_PORT'],
                                            os.environ['INFLUXDB_DB'])
    req = request.Request(url, data=data)
    _ = request.urlopen(req)


def to_redis(states):
    db = redis.StrictRedis(host=os.environ['REDIS_HOST'],
                           port=int(os.environ['REDIS_PORT']),
                           db=int(os.environ['REDIS_DB']))
    data = {}
    for state in states:
        data['fingo:{}'.format(state.mac)] = json.dumps({
            'ip': state.ip_address,
            'hostname': state.hostname,
            'hw_vendor': state.hw_vendor,
        })

    db.mset(data)
    for key in data.keys():
        db.expire(data, 4 * 7 * 24 * 60 * 60)


async def main():
  no_redis = False
  if 'REDIS_HOST' not in os.environ:
    no_redis = True
    print('Redis host not set, won\'t store in redis some metadata')

  async for changes in awatch('fing'):
    for action, file in changes:
      if '.csv' in file:
        time.sleep(0.5)
        print('Changes in {}'.format(file))
        with open(file, 'r') as ffile:
          lines = []
          for line in ffile:
            lines.append(DeviceStatus(line))
        to_influxdb(lines)
        to_redis(lines) if not no_redis else None

loop = asyncio.get_event_loop()
loop.run_until_complete(main())
