# AP Bucket Archiver

A re-write of the original bucket archiver in python that will fix the problem with object versions preventing bucket deletion.

## Usage

### List all buckets marked to be archived

```
aws-vault exec admin-data -- python -m archiver find --environment alpha
```

The default tag to search on is `to-archive` that can be overridden with the `--tag` flag:

```
aws-vault exec admin-data -- python -m archiver find --environment alpha --tag `for-archiving`
```

### Archive a single bucket

```
aws-vault exec admin-data -- python -m archiver single --bucketToArchive dev-rajinder-test --archiveBucket alpha-archived-buckets-data
```

### Archive all buckets to within an environment

```
aws-vault exec admin-data -- python -m archiver batch --environment dev --archiveBucket alpha-archived-buckets-data
```

The default tag can also be overridden with the `--tag` flag.

## Developing

Set up your local environment first:

```
python3 -m venv ~/envs/archiver
. ~/envs/archiver/bin/activate
pip install -r requirements.txt
```

## Testing

You need localstack running for the tests to run. Then:

```
make test
```
