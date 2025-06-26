import boto3
import json
from decimal import Decimal

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('VisitorCounter')

def lambda_handler(event, context):
    # Get client IP address
    ip = event.get("requestContext", {}).get("http", {}).get("sourceIp")

    if not ip:
        return {
            'statusCode': 400,
            'body': json.dumps({'error': 'Could not determine IP'})
        }

    # Get current record
    response = table.get_item(Key={'id': 'main'})
    item = response.get('Item', {})
    
    # Use fallback if attributes are missing
    count = item.get('site_count', 0)
    ip_set = set(item.get('ip_set', []))  # Convert to set for fast lookup

    if ip in ip_set:
        # Already counted
        return {
            'statusCode': 200,
            'body': json.dumps({'message': 'IP already counted', 'counted': False, 'count': int(count)})
        }

    # New IP: increment count and update ip_set
    count += 1
    ip_set.add(ip)

    table.update_item(
        Key={'id': 'main'},
        UpdateExpression='SET site_count = :count, ip_set = :ips',
        ExpressionAttributeValues={
            ':count': count,
            ':ips': list(ip_set)  # Convert set back to list for DynamoDB
        }
    )

    return {
        'statusCode': 200,
        'headers': {'Access-Control-Allow-Origin': '*'},
        'body': json.dumps({'message': 'Unique visitor counted', 'counted': True, 'count': int(count)})
    }