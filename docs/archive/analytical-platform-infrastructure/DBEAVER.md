<!-- markdownlint-disable -->
# Using DBeaver with Redshift

Steps for using DBeaver with dev_mi_alpha redshift. 

1. Install DBeaver 
```
brew install --cask dbeaver-community
```
2. Download ssh private key for dev bastion and copy into .ssh folder as a name like  `bastion-key` and chmod 600 the file. 

3. Config ssh tunnel for DBeaver to access dev_mi_alpha redshift. set `.ssh/config` to 
```
Host bastion-redshift-dev
  HostName bastion.dev.mojanalytics.xyz
  User ubuntu
  IdentityFile ~/.ssh/bastion-key
  LocalForward localhost:6439 dev-mi-alpha.ckln43tik0qy.eu-west-1.redshift.amazonaws.com:5439
```
where `~/.ssh/bastion-key` is the bastion key from step 2.

4. Create a new terminal session and run
```
  ssh bastion-redshift-dev
```
**NOTE:** if you have run before with a different ssh key you will need to remove the known_hosts file. 

5. Run DBeaver app and create a new redshift connection: 
```
host: 127.0.0.1   port: 6439
authentication: database native 
user:  master 
password  password of redshift cluster 
```
6. Test the connection you should see it connect 
and see default table space pg_default 
and schemas catalog_history and public. 

7. To be able to access AWS resources with redshift (ie copy from S3 tables) edit the connection and set the user role field to `arn:aws:iam::593291632749:role/dev-mi-alpha-redshift`. Alternatively you can put `iam_role 'arn:aws:iam::593291632749:role/dev-mi-alpha-redshift';` on the SQL copy statement. 