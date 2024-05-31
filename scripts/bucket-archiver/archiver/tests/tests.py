from cmath import exp
from .context import archiver

import unittest
import boto3
from botocore.exceptions import ClientError

class BasicTestSuite(unittest.TestCase):
    """Basic test cases."""

    endpoint_url = "http://localhost.localstack.cloud:4566"

    client = boto3.client("s3", endpoint_url=endpoint_url)
    s3 = boto3.resource("s3", endpoint_url=endpoint_url)

    def test_list_buckets_to_archive(self):

        buckets = [
            { 'name' : 'no-tag', 'tags': [] },
            { 'name' : 'tag-is-false', 'tags': [{ 'Key': 'toArchive', 'Value': 'false'}] },
            { 'name' : 'tag-is-not-true', 'tags': [{ 'Key': 'toArchive', 'Value': 'x'}] },
            { 'name' : 'tag-true', 'tags': [{ 'Key': 'toArchive', 'Value': 'true'}] },
            { 'name' : 'tag-also-true', 'tags': [{ 'Key': 'toArchive', 'Value': 'true'}] }
        ]

        a = archiver.app.Archiver(endpoint_url=self.endpoint_url)

        self.create_buckets(buckets)

        expected = ['arn:aws:s3:::tag-true', 'arn:aws:s3:::tag-also-true']
        actual = a._list_archive_tagged_buckets(to_archive_tag="toArchive", resources_per_page=1)

        self.delete_buckets(buckets)

        expected.sort()
        actual.sort()
        assert actual == expected


    def test_map_bucket_name_to_bucket_arn(self):
        input = [
            "arn:aws:s3:::alpha-r-training-session",
            "arn:aws:s3:::dev-rajinder-test",
            "arn:aws:s3:::alpha-data-discovery-tool",
            "arn:aws:s3:::alpha-app-legalaiddatatool",
            "arn:aws:s3:::alpha-my-fishy-cheese",
            "arn:aws:s3:::alpha-glenn-christmas-test",
            "arn:aws:s3:::local-specialisation-2019",
            "arn:aws:s3:::alpha-app-ccmbpt-app-directory",
            "arn:aws:s3:::alpha-analytical-platform-basics-to-delete",
            "arn:aws:s3:::local-yikangmao-testing-s3",
            "arn:aws:s3:::alpha-app-commuter-interventions",
            "arn:aws:s3:::alpha-labourforcesurvey",
            "arn:aws:s3:::alpha-clink-prison-lookup-data",
            "arn:aws:s3:::alpha-reoffending-pnc-2000",
            "arn:aws:s3:::alpha-my-testing-bucket",
            "arn:aws:s3:::dev-louise-test-data"
        ]

        expected = [
            "arn:aws:s3:::dev-rajinder-test",
            "arn:aws:s3:::dev-louise-test-data"
        ]

        a = archiver.app.Archiver(endpoint_url=self.endpoint_url)

        actual = a._filter_arns_for_environment("dev", input)

        expected.sort()
        actual.sort()

        assert actual == expected


    def test__map_bucket_name_to_bucket_arn(self):
        input = [
            "arn:aws:s3:::alpha-r-training-session",
            "arn:aws:s3:::alpha-data-discovery-tool"
        ]

        expected = [
            { 'name': "alpha-r-training-session", "arn": "arn:aws:s3:::alpha-r-training-session" },
            { 'name': "alpha-data-discovery-tool", "arn": "arn:aws:s3:::alpha-data-discovery-tool" }
        ]

        a = archiver.app.Archiver(endpoint_url=self.endpoint_url)

        actual = a._map_bucket_name_to_bucket_arn(input)

        assert actual == expected


    def test_move_objects_to_archive_bucket(self):
        self.create_bucket('source')
        self.create_bucket('destination')
        objects = [
            { 'key': 't/e/s/t/1', 'body': 'test message 1' },
            { 'key': 't/e/s/t/2', 'body': 'test message 2' },
            { 'key': 't/e/s/t/3', 'body': 'test message 3' },
            { 'key': 't/e/s/t/4', 'body': 'test message 4' }
        ]
        self.create_objects('source', objects)

        a = archiver.app.Archiver(endpoint_url=self.endpoint_url)
        a._copy_objects_to_archive_bucket('source', 'destination')

        for obj in objects:
            key = 'source/' + obj['key']
            actual = self.get_object('destination', key)
            expected = obj['body']
            assert actual == expected

        self.delete_bucket('source')
        self.delete_bucket('destination')


    def test_delete_object_versions_from_bucket(self):
        self.create_bucket('source')
        objects = [
            { 'key': 't/e/s/t/1', 'body': 'test message 1' },
            { 'key': 't/e/s/t/2', 'body': 'test message 2' },
            { 'key': 't/e/s/t/3', 'body': 'test message 3' },
            { 'key': 't/e/s/t/4', 'body': 'test message 4' }
        ]
        self.create_objects('source', objects)

        a = archiver.app.Archiver(endpoint_url=self.endpoint_url)
        a._delete_bucket('source')

        exists = True

        try:
            self.s3.meta.client.head_bucket(Bucket='source')
        except ClientError as error:
          error_code = int(error.response['Error']['Code'])
          if error_code == 404:
            exists = False

        assert not exists


    def create_buckets(self, buckets):
        """Creates all buckets in the list"""

        for bucket in buckets:
            self.create_bucket(bucket_name=bucket['name'], tags=bucket['tags'])


    def create_bucket(self, bucket_name, tags=[]):
        """Creates a bucket with some tags"""

        self.s3.Bucket(bucket_name).create()
        if tags:
            self.s3.BucketTagging(bucket_name).put(Tagging={'TagSet': tags})


    def create_objects(self, bucket_name, objects):
        """Creates multiple objects in a bucket"""

        for obj in objects:
            self.create_object(bucket_name, obj['key'], bytes(obj['body'], 'utf-8'))


    def create_object(self, bucket_name, key, body):
        """Creates an object with the given body"""
        self.s3.Object(bucket_name, key).put(Body = body)


    def get_object(self, bucket_name, key):
        """Gets an object and reads its contents as a string"""
        obj = self.s3.Object(bucket_name, key)
        file_content = obj.get()['Body'].read().decode('utf-8')
        return file_content


    def delete_buckets(self, buckets):
        """Deletes all buckets in the list"""

        for bucket in buckets:
            self.delete_bucket(bucket_name=bucket['name'])


    def delete_bucket(self, bucket_name):
        """Deletes a single bucket"""
        bucket = self.s3.Bucket(bucket_name)
        bucket.object_versions.delete()
        bucket.delete()


if __name__ == '__main__':
    unittest.main()
