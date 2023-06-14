# backup.sh -u <username> -p <password> -s <url> -d <bucket> -f <newline delimited list of indices to backup> 2>&1 > mylog.log
# Don't forget to use screen or this will time out

usage()
{
  echo "Usage:"
  echo ""
  echo "test.sh -s Source ELK instance"
  echo "        -d Dest bucket name"
  echo "        -u Elastic username"
  echo "        -p Elastic password"
  echo "        -f text containing list of indices"
}

# get the options
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
 esac
done
shift $((OPTIND -1))

# check variables are defined
if [[ -z $source ]] || [[ -z $destination ]] || [[ -z $user ]] || [[ -z $password ]] || [[ -z $filename ]] 
then
  usage
  exit
fi

# dump the mapping and the actual data
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

# clean up
rm ${index}.tgz
rm ${index}-mapping.json ${index}-index.json
echo " "
echo "-------------"
echo " "
echo " "
# next record
done < ${filename}