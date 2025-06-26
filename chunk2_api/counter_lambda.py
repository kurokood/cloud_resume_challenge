import boto3
import json
from datetime import datetime

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('VisitorCounter')

def lambda_handler(event, context):
    # Extract IP
    ip = (
        event.get("requestContext", {}).get("http", {}).get("sourceIp") or
        event.get("headers", {}).get("X-Forwarded-For", '').split(',')[0] or
        "test-ip"
    )

    # Use today's date as ID
    today = datetime.utcnow().strftime('%Y-%m-%d')

    # Get today's record
    response = table.get_item(Key={'id': today})
    item = response.get('Item', {})

    count = item.get('site_count', 0)
    ip_set = set(item.get('ip_set', []))

    if ip not in ip_set:
        count += 1
        ip_set.add(ip)

        table.put_item(Item={
            'id': today,
            'site_count': count,
            'ip_set': list(ip_set)
        })

        is_unique = True
    else:
        is_unique = False

    return {
        'statusCode': 200,
        'headers': {'Access-Control-Allow-Origin': '*'},
        'body': json.dumps({
            'date': today,
            'ip': ip,
            'count': int(count),
            'new_today': is_unique
        })
    }