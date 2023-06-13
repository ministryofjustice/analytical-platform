# Managed Elastic Search Operations

This part of the repo deals with managed elastic search. 

Our existing cluster (and also our monitoring cluster) can be accessed at:

https://cloud.elastic.co/

## Backup and restore of existing indices

In order to clear old data from the cluster, a few scripts were put together.

### Prerequisites:

* An EC2 instance running Amazon linux running in the alpha VPC
* An S3 bucket to push/pull the logs from
* Add the EC2 node to the same SG as the kubernetes nodes
* Apply the following access policy via a role to ensure that the EC2 instance can talk to the bucket:

```{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "s3:*",
            "Resource": [
            	"arn:aws:s3:::<bucketname>",
            	"arn:aws:s3:::<bucketname>/*"
            	]	
        }
    ]
}
```

On the EC2 instance install curator and elasticdump:

```
yum install python3
pip3 install -U elasticsearch-curator
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.34.0/install.sh | bash
. ~/.nvm/nvm.sh
nvm install node
npm install elasticdump -g
```

and set up the following file calling it:

```
curator.yaml
```

Curator file:
```
client:
  hosts:
    - <elasticsearch url>
  port: <port>
  url_prefix:
  use_ssl: True
  certificate:
  client_cert:
  client_key:
  ssl_no_validate: False
  username: <username>
  password: <password>
  timeout: 30
  master_only: False

logging:
  loglevel: INFO
  logfile: /home/ec2-user/curator.log
  logformat: default
  blacklist: ['elasticsearch', 'urllib3']
```

In all cases Elastic credentials can be found in the file:

```
chart-env-config/dev/webapp.yml
```

Within the analytics-platform-config repo

It is now possible to get a list of indices on the cluster:

```curator_cli --config .curator/curator.yaml show_indices```

***NOTE: USE SCREEN FOR THE BELOW OR THEY WILL TIMEOUT***

### To backup an index
```
backup.sh -u <username> -p <password> -s <url> -d <bucket> -f <newline delimited list of indices> 2>&1 > mylog.log
```

### To restore an index:
```
restore.sh -u <username> -p <password> -d <url> -s <bucket> -f <newline delimited list of indices> 2>&1 > mylog.log
```

# Auto archiving old indices
archive.sh is built on top of the other scripts above. It is installed in root's home directory and runs at 4am every day. It is currently configured to look for indices older than 7 days, archive and delete them. They can be restored using the method above.
