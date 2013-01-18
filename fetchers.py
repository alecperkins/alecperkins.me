import requests, json
import oauth2

import secrets



def fetchTwitter():
    url = 'https://api.twitter.com/1.1/statuses/user_timeline.json?include_entities=true&screen_name=alecperkins&include_rts=false&exclude_replies=true&count=200'
    consumer = oauth2.Consumer(key=secrets.TWITTER_CONSUMER_KEY, secret=secrets.TWITTER_CONSUMER_SECRET)
    token = oauth2.Token(key=secrets.TWITTER_ACCESS_TOKEN, secret=secrets.TWITTER_ACCESS_TOKEN_SECRET)
    client = oauth2.Client(consumer, token)
    response, content = client.request(url, method='GET')
    if response['status'] != '200':
        return []

    result = []
    for tweet in json.loads(content):
        result.append({
            'id'                        : tweet['id_str'],
            'entities'                  : tweet['entities'],
            'text'                      : tweet['text'],
            'date'                      : tweet['created_at'],
            'in_reply_to_status_id'     : tweet['in_reply_to_status_id'],
            'in_reply_to_screen_name'   : tweet['in_reply_to_screen_name'],
            'retweet_count'             : tweet['retweet_count'],
        })
    return result



def fetchInstagram():
    url = 'https://api.instagram.com/v1/users/self/media/recent?access_token=%s' % (secrets.INSTAGRAM_ACCESS_TOKEN,)
    response = requests.get(url)
    if response.status_code != 200:
        return []

    result = []
    for photo in json.loads(response.content)['data']:
        caption_text = photo.get('caption')
        if caption_text:
            caption_text = caption_text.get('text')
        result.append({
            'id'                : photo['id'],
            'urls'              : photo['images'],
            'link'              : photo['link'],
            'caption'           : caption_text,
            'date'              : int(photo['created_time']) * 1000,
            'likes_count'       : photo['likes']['count'],
            'comments_count'    : photo['comments']['count'],
        })

    return result


