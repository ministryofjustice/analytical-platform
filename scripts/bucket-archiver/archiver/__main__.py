from archiver import app
import argparse

TO_ARCHIVE_TAG = "to-archive"

def main():
    arg_parser = argparse.ArgumentParser(description='Archive buckets tagged by the control panel')
    arg_parser.add_argument('--tag', type=str, help='the tag to search for')
    arg_parser.add_argument('--environment', type=str, help='the environment to search in')
    arg_parser.add_argument('--bucketToArchive', type=str, help='the bucket to archive')
    arg_parser.add_argument('--archiveBucket', type=str, help='the archive bucket')
    arg_parser.add_argument('command', type=str, help='the command to run find|single|batch')
    args = arg_parser.parse_args()

    archiver = app.Archiver()

    command = args.command
    if command == "find":
        find(archiver, args)
    elif command == "single":
        single(archiver, args)
    elif command == "batch":
        batch(archiver, args)
    else:
        print("unrecognised command: "+ command)


def find(archiver, args):
    if not args.environment:
        print("--environment must be provided")
        return
    environment = args.environment

    to_archive_tag = TO_ARCHIVE_TAG
    if args.tag:
        to_archive_tag = args.tag

    archiver.find_buckets_to_archive(to_archive_tag, environment)


def single(archiver, args):
    if not args.bucketToArchive:
        print("--bucketToArchive must be provided")
        return
    if not args.archiveBucket:
        print("--archiveBucket must be provided")
        return

    bucket_to_archive = args.bucketToArchive
    archive_bucket = args.archiveBucket
    archiver.archive_single(bucket_to_archive, archive_bucket)


def batch(archiver, args):
    if not args.environment:
        print("--environment must be provided")
        return
    if not args.archiveBucket:
        print("--archiveBucket must be provided")
        return

    archive_bucket = args.archiveBucket
    environment = args.environment
    to_archive_tag = TO_ARCHIVE_TAG
    if args.tag:
        to_archive_tag = args.tag
    archiver.archive_batch(to_archive_tag, environment, archive_bucket)


if __name__ == '__main__':
    main()
