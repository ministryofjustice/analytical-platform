import boto3


class Archiver:

    def __init__(self, endpoint_url=""):
        """
        Performs archiving of buckets that are tagged by the control panel
        Arguments:
            endpoint_url: The endpoint to use for the boto clients (e.g. for localstack)
        """
        if endpoint_url:
            self.client = boto3.client("s3", endpoint_url=endpoint_url)
            self.s3 = boto3.resource("s3", endpoint_url=endpoint_url)
            self.restag = boto3.client('resourcegroupstaggingapi', endpoint_url=endpoint_url)
        else:
            self.client = boto3.client("s3")
            self.s3 = boto3.resource("s3")
            self.restag = boto3.client('resourcegroupstaggingapi')

    def find_buckets_to_archive(self, to_archive_tag, environment):
        to_archive = self._list_buckets_to_archive(to_archive_tag, environment)

        for bucket in to_archive:
            print(bucket)


    def archive_single(self, bucket_to_archive, archive_bucket):
        self._copy_objects_to_archive_bucket(bucket_to_archive, archive_bucket)
        self._delete_bucket(bucket_to_archive)
        pass


    def archive_batch(self, to_archive_tag, environment, archive_bucket):
        to_archive = self._list_buckets_to_archive(to_archive_tag, environment)

        for bucket in to_archive:
            self.archive_single(bucket['name'], archive_bucket)


    def _list_buckets_to_archive(self,to_archive_tag, environment):
        """
        Generates a list of names and ARNs of buckets to archive
        Arguments:
            to_archive_tag: the tag that indicates the bucket needs to be archived
            environment: the environment to scan for archiving
        Returns:
            A list of bucket dicts containing the names and ARNs to be archived
        """
        arns = self._list_archive_tagged_buckets(to_archive_tag)
        to_archive = self._filter_arns_for_environment(environment, arns)
        mapped = self._map_bucket_name_to_bucket_arn(to_archive)
        return mapped


    def _archive_bucket():
        # _move_objects_to_archive_bucket
        # _delete_object_versions_from_bucket
        # _delete_bucket
        pass


    def _list_archive_tagged_buckets(self, to_archive_tag, resources_per_page=50):
        """
        Lists bucket ARNs for buckets that are tagged to be archived
        Arguments:
            to_archive_tag: the tag that indicates the bucket needs to be archived
            resources_per_page: number of resources per page on the api (included for testing)
        Returns:
            A list of bucket arns all of which are tagged to be archived
        """

        resource_type_filters = ['s3']
        resource_type_filters = []
        tag_filters = [{'Key': to_archive_tag, 'Values': ['true']}]

        bucket_arns = []
        response = self.restag.get_resources(
            TagFilters=tag_filters,
            ResourceTypeFilters=resource_type_filters,
            ResourcesPerPage=resources_per_page)

        arns = [ resource['ResourceARN'] for resource in  response['ResourceTagMappingList']]
        bucket_arns = bucket_arns + arns

        while 'PaginationToken' in response and response['PaginationToken']:
            token = response['PaginationToken']
            response = self.restag.get_resources(
                TagFilters=tag_filters,
                ResourceTypeFilters=resource_type_filters,
                ResourcesPerPage=resources_per_page,
                PaginationToken=token)

            arns = [ resource['ResourceARN'] for resource in  response['ResourceTagMappingList']]
            bucket_arns = bucket_arns + arns
        return bucket_arns


    def _map_bucket_name_to_bucket_arn(self, arns):
        """
        Creates a dict of a bucket's name and ARN from the ARN
        Arguments:
            arns: the list of ARNs to filter
        Returns:
            the list of dicts
        """

        arns = [{'name': arn.replace('arn:aws:s3:::',"",1), 'arn': arn} for arn in arns]
        return arns


    def _filter_arns_for_environment(self, environment, arns):
        """
        Removes s3 bucket ARNs that are not in the specified environment
        Arguments:
            environment: the environment to filter on
            arns: the list of ARNs to filter
        Returns:
            the filtered list of ARNs
        """

        prefix = 'arn:aws:s3:::' + environment
        filtered = filter(lambda arn: arn.startswith(prefix), arns)
        return list(filtered)


    def _copy_objects_to_archive_bucket(self, source, destination):
        """
        Copy s3 objects from ${source}/... to ${destination}/${source}/key
        Arguments:
            source: the source bucket
            destination: the destination bucket
        """

        objects = self.s3.Bucket(source).objects.all()
        dest = self.s3.Bucket(destination)

        for obj in objects:
            new_key = '/'.join([obj.bucket_name, obj.key])
            copy_source = {
                'Bucket': obj.bucket_name,
                'Key': obj.key
            }
            print(f"Copying {source}/{obj.key} to {destination}/{new_key}")
            dest.copy(copy_source, new_key)


    def _delete_object_versions_from_bucket():
        # s3 = boto3.resource('s3')
        # bucket = s3.Bucket('your-bucket-name')
        # bucket.object_versions.all().delete()
        pass


    def _delete_bucket(self, bucket_name):
        """
        Deletes a single bucket and all items within it
        Arguments:
            bucket_name: the bucket to be deleted
        """
        print(f"Deleting {bucket_name}")
        bucket = self.s3.Bucket(bucket_name)
        bucket.object_versions.delete()
        bucket.delete()
