# API for that backend

## First: Environment variables

To connect to redis and influxdb, you must ensure that this variables are ok for you, and all set:

 - `REDIS_HOST` = `redis`
 - `REDIS_PORT` = `6379`
 - `REDIS_DB` = `0`
 - `INFLUXDB_HOST` (not set)
 - `INFLUXDB_PORT` (not set)
 - `INFLUXDB_DB` (not set)

## GET /

Shows you the `/static/index.html` file :)

## GET /hosts

Returns the list of hosts available in the redis database. The format is the following:

```json
{
    "hosts": [
        {
            "ip": "string", //The IP of the device
            "hostname": "string or null", //Hostname if it has
            "hw_vendor": "string or null", //Hardware vendor from the MAC address (it's a guess)
            "mac": "string" //MAC address
        },
        ...
    ]
}
```

## GET /values/:mac

Gets a list of points for the activity of the device/NIC identified by the given `mac`, from now to `pastTime`. It is possible to change some parameters of the results to give more precise plots.

**Parameters:**

 - `pastTime`: Time in seconds for the oldest value in the series. By default is 24 hours.
 - `fill`: If any value is not present, fill with this function. Available functions are:
   - `previous`: Fills with the previous value.
   - `null`: Don't fill, just return null for that value.
   - `0`: Sets as off when some value are not present (default).
 - `time`: How to group data in the series. Every point will be (if not set in the default value) a mean of the On and Off values grouped by the time specified (distance between them in time will be that `time`). Valid values are:
   - `1`: 1 minute (default, no grouping)
   - `2`: 5 minutes
   - `3`: 10 minutes
   - `4`: 30 minutes

**Return format:**

```json
{
    "results": [
        {
            "statement_id": 0,
            "series": [
                {
                    "name": "string",
                    "columns": ["time", "state"],
                    "values": [ //The values are here
                        [ "time", 1 or 0 ],
                        ...
                    ]
                }
            ]
        }
    ]
}
```