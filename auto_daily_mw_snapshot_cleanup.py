from datetime import datetime, timedelta, timezone

import boto3

class Ec2Instances(object):
    
    def __init__(self, region):
        print("region "+ region)
        self.ec2 = boto3.client('ec2', region_name=region)
        
    def delete_snapshots(self, older_days=14):
        delete_snapshots_num = 0
        snapshots = self.get_nimesa_created_snapshots()
        for snapshot in snapshots['Snapshots']:
            fmt_start_time = snapshot['StartTime']
            print("Cutoff time " + str(self.get_delete_data(older_days)))
            if (fmt_start_time < self.get_delete_data(older_days)):
                print("delete snapshot " + str(snapshot['SnapshotId']))
                self.delete_snapshot(snapshot['SnapshotId'])
                delete_snapshots_num+1
        return delete_snapshots_num
                
    def get_nimesa_created_snapshots(self):
        snapshots = self.ec2.describe_snapshots(Filters=[{'Name': 'tag:CreatedBy', 'Values': ['MaintenanceWindow']}])
        print("filtered snapshots " + str(snapshots))
        return snapshots

    def get_delete_data(self, older_days):
        delete_time = datetime.now(tz=timezone.utc) - timedelta(days=older_days)
        return delete_time;

    def delete_snapshot(self, snapshot_id):
        self.ec2.delete_snapshot(SnapshotId=snapshot_id)
            
def lambda_handler(event, context):
    print("event " + str(event))
    print("context " + str(context))
    ec2_reg = boto3.client('ec2')
    region_name = "eu-west-1"
    instances = Ec2Instances(region_name)
    deleted_counts = instances.delete_snapshots(14)
    print("deleted_counts for region "+ str(region_name) +" is " + str(deleted_counts))
    return 'completed'