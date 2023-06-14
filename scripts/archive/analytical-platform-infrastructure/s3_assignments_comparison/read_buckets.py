buckets = {}

from csv import reader
with open('./s3bucket.csv', 'r') as read_obj:
    csv_reader = reader(read_obj)
    for row in csv_reader:        
        buckets[row[0]+","+row[1]] = row[2]
print(buckets)
