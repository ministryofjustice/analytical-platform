# Elastic restore index from s3
# restore.sh -u <username> -p <password> -d <url> -s <bucket> -f <newline delimited list of indices> 2>&1 > mylog.log
# Don't forget to run using screen or it will time out
# get the options

usage()
{
  echo "Usage:"
  echo ""
  echo "test.sh -s Source ELK instance"
  echo "        -d Dest bucket name"
  echo "        -u Elastic username"
  echo "        -p Elastic password"
  echo "        -f text containing list of indices to be restored"
}


while getopts "s:d:u:p:f:h" opt;
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
  f )
    filename=$OPTARG
    ;;
  \? )
    usage
    exit;;
  esac
done
shift $((OPTIND -1))

# check variables are defined
if [[ -z $source ]] || [[ -z $destination ]] || [[ -z $user ]] || [[ -z $password ]] || [[ -z $filename ]]
then
  usage
  exit
fi

# loop through lines in input text
while read index
do

# upload to s3 fatal error if something goes wrong
aws s3 cp s3://${source}/${index}.tgz ${index}.tgz  || { echo "FATAL ERROR: Something happened with the s3 copy of ${index}.gz."; exit 1; }


echo "Processing ${index}"
echo "----------"
tar -xvf ${index}.tgz

#dump the mapping and the actual data
elasticdump \
  --input ${index}-mapping.json \
  --output https://${user}:${password}@${destination}/${index} \
  --type=mapping \
  --quiet
elasticdump \
  --input "${index}-index.json" \
  --output https://${user}:${password}@${destination}/${index} \
  --quiet \
  --limit 10000

# get source number of restored docs
targetdocs=`curl -s -u${user}:${password} https://${destination}/${index}/_count | awk -F, {'print $1'} | awk -F: {'print $2'} | sed 's/\n//g' | tr -d "\n"`


# count the number of source docs which have been dumped
sourcedocs=`grep -c _index ${index}-index.json`

# if they do not match, something has gone wrong exit
if [ $sourcedocs -ne $targetdocs ]
then
        echo "FATAL ERROR: ${index} Source $sourcedocs does not match restored docs $targetdocs"
        exit 1;
else
# if they match - log that
        echo "Index: ${index} $sourcedocs and $targetdocs match - restore completed."
fi

# clean up
rm ${index}.tgz
rm ${index}-mapping.json ${index}-index.json
echo " "
echo "-------------"
echo " "
echo " "
# next record
done < ${filename}