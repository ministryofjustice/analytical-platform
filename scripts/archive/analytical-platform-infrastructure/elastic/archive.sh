# Elastic archive index to s3
# archive.sh -u <username> -p <password> -s <url> -d <bucket> 2>&1 > mylog.log

LOCKFILE="/tmp/elastic_archive_lockfile"
CURATORFILE="/root/curator.yaml"

# note that if you intend to run this via cron, you MUST add PATHs to elasticdump and curator_cli
# eg:
# export PATH=$PATH:/usr/local/bin
# export PATH=$PATH:/root/.nvm/versions/node/v15.14.0/bin

# is the process already running?
if [[ -f $LOCKFILE ]]
then
  echo "FATAL ERROR: Job already running or process crashed out messily"
  exit
fi

touch $LOCKFILE

# lets do belt and braces anyway
type curator_cli >/dev/null 2>&1 || { echo >&2 "I require curator_cli, but it's not in the PATH.  Aborting."; exit 1; }
type elasticdump >/dev/null 2>&1 || { echo >&2 "I require elasticdump, but it's not in the PATH.  Aborting."; exit 1; }

if [[ ! -f $CURATORFILE ]]
then
  echo "FATAL ERROR: I can't find your curator config file"
  exit
fi

usage()
{
  echo "Usage:"
  echo ""
  echo "archive.sh -s Source ELK instance"
  echo "          -d Dest bucket name"
  echo "          -u Elastic username"
  echo "          -p Elastic password"
}

# get the options
while getopts "s:d:u:p:h" opt;
do
  case ${opt} in
  h )
    usage
    exit;;
  s )
    source=$OPTARG
    ;;
  d )
    destination=$OPTARG
    ;;
  u )
    user=$OPTARG
    ;;
  p )
    password=$OPTARG
    ;;
  \? )
    usage
    exit;;
  esac
done
shift $((OPTIND -1))

# check variables are defined
if [[ -z $source ]] || [[ -z $destination ]] || [[ -z $user ]] || [[ -z $password ]] 
then
  usage
  exit
fi

# get indices older than 7 days
curator_cli --config $CURATORFILE show_indices --filter_list \
'[
    {
    "filtertype":"age",
    "source":"name",
    "direction":"older",
    "timestring":"'%Y.%m.%d'",
    "unit":"days",
    "unit_count":"7"
    }
]' > index_for_archive.$$

# loop through lines in input text
while read index
do
echo $index
echo "----------"

# get source number of docs
sourcedocs=`curl -s -u${user}:${password} https://${source}/${index}/_count | awk -F, {'print $1'} | awk -F: {'print $2'} | sed 's/\n//g' | tr -d "\n"`

#dump the mapping and the actual data
elasticdump \
  --input=https://${user}:${password}@${source}/${index} \
  --output "${index}-mapping.json" \
  --type=mapping \
  --quiet
elasticdump \
  --input=https://${user}:${password}@${source}/${index} \
  --output "${index}-index.json" \
  --quiet \
  --limit 10000

# count the number of docs which have been dumped
targetdocs=`grep -c _index ${index}-index.json`

# if they do not match, something has gone wrong exit
if [ $sourcedocs -ne $targetdocs ]
then
        echo "FATAL ERROR: ${index} Source $sourcedocs does not match downloaded docs $targetdocs"
        exit 1;
else
# if they match - log that
        echo "Index: ${index} $sourcedocs and $targetdocs match uploading."
fi

# compress and
tar -czf ${index}.tgz ${index}-mapping.json ${index}-index.json

# upload to s3 fatal error if something goes wrong
aws s3 cp ${index}.tgz s3://${destination} || { echo "FATAL ERROR: Something happened with the s3 copy of ${index}.gz."; exit 1; }

# if we're here, we can remove the index from ElasticSearch
curl -s -u${user}:${password} -X DELETE https://f58ddb963b371b72f957e6cd3660f350.eu-west-1.aws.found.io:9243/${index} || { echo "FATAL ERROR: Could not remove index from managed Elastic."; exit 1; }

# clean up
rm ${index}.tgz
rm ${index}-mapping.json ${index}-index.json

echo " "
echo "-------------"
echo " "
echo " "
# next record
done < index_for_archive.$$

rm index_for_archive.$$
rm $LOCKFILE