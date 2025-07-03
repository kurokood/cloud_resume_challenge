import boto3
import json
from datetime import datetime, timedelta

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('SiteAnalytics')

def lambda_handler(event, context):
    # Extract IP address
    ip = (
        event.get("requestContext", {}).get("http", {}).get("sourceIp") or
        event.get("headers", {}).get("X-Forwarded-For", '').split(',')[0] or
        "test-ip"
    )

    now = datetime.utcnow()
    now_str = now.isoformat()
    is_unique = False

    # Try to get existing IP record
    try:
        response = table.get_item(Key={'ip': ip})
        item = response.get('Item')
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': 'DynamoDB GetItem failed',
                'details': str(e)
            })
        }

    if item:
        last_seen_str = item.get('last_seen')
        try:
            last_seen_time = datetime.fromisoformat(last_seen_str)
        except:
            last_seen_time = now - timedelta(days=1, seconds=1)

        if now - last_seen_time > timedelta(hours=24):
            is_unique = True
    else:
        is_unique = True

    if is_unique:
        try:
            table.put_item(Item={
                'ip': ip,
                'last_seen': now_str
            })
        except Exception as e:
            return {
                'statusCode': 500,
                'body': json.dumps({
                    'error': 'DynamoDB PutItem failed',
                    'details': str(e)
                })
            }

    # Count all IPs (each represents one unique visitor in the last 24h window)
    try:
        scan = table.scan(Select='COUNT')
        total_visits = scan.get('Count', 0)
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': 'DynamoDB Scan failed',
                'details': str(e)
            })
        }

    return {
        'statusCode': 200,
        'headers': {'Access-Control-Allow-Origin': '*'},
        'body': json.dumps({
            'ip': ip,
            'new_unique_visit': is_unique,
            'timestamp': now_str,
            'total_unique_visits': total_visits
        })
    }