grid_size = 24 #pixels

max_score = -1
min_score = 1e10


calcWidth = (score) ->
    half_grid = 306 / 2
    console.log (score / max_score)
    width = (half_grid + ((score / max_score) * half_grid)).toFixed(0)
    console.log 'score', score, 'width', width
    return width

renderInstagram = (item) ->
    photo = item.data
    score = item.score

    $photo = $("""
        <div class="item photo">
            <img src="#{ photo.urls.low_resolution.url }">
            <a class="link" href="#{ photo.link }">#</a>
        </div>
    """)

    width = calcWidth(score)
    $photo.css
        'width': "#{ width }px"
    return $photo



renderTwitter = (item) ->
    score = item.score
    tweet = item.data
    text = new NOAT(tweet.text)

    $.each tweet.entities.hashtags, (i, t) ->
        text.add 'a', t.indices[0], t.indices[1],
            href: "https://twitter.com/?q=%23#{ t.text.substring(1) }"

    $.each tweet.entities.urls, (i, t) ->
        text.add 'a', t.indices[0], t.indices[1],
            href: t.url
            'data-display_url': t.display_url

    $.each tweet.entities.user_mentions, (i, t) ->
        text.add 'a', t.indices[0], t.indices[1],
            href: "https://twitter.com/#{ t.screen_name }"

    media_list = tweet.entities.media or []
    $.each media_list, (i, t) ->
        text.add 'span', t.indices[0], t.indices[1],
            'data-image': t.media_url
            'data-display_url': t.display_url

    $tweet = $("""
        <div class="item tweet">
            #{ text.toString() }
            <a class="link" href="https://twitter.com/alecperkins/status/#{ tweet.id }">#</a>
        </div>
    """)

    $tweet.find('[data-display_url]').each (i, tag) ->
        $tag = $(tag)
        $tag.text($tag.attr('data-display_url'))

    half_grid = grid_size / 2
    font_size = (half_grid + (score / max_score * half_grid)).toFixed(0)
    console.log font_size
    if font_size > grid_size
        font_size = grid_size
    $tweet.css
        'font-size': "#{ font_size }px"
        'width': "#{ calcWidth(score) }px"

    return $tweet



NOW = (new Date()).getTime()

scoreInstagram = (item) ->
    time_delta = NOW - new Date(item.date).getTime()
    score = (1/time_delta * 1e10).toFixed(2)
    score = score * (item.comments_count + (2 * item.likes_count) + 1)
    return score

scoreTwitter = (item) ->
    time_delta = NOW - new Date(item.date).getTime()
    score = (1/time_delta * 1e10).toFixed(2)
    score = score * (item.retweet_count * 2 + 1)
    return score

setMaxMin = (score) ->
    if score > max_score
        max_score = score
    else if score < min_score
        min_score = score



$content = $('.content')

items = {}



displayItems = ->
    if items.twitter? and items.instagram?
        item_list = []
        item_list.push(items.twitter...)
        item_list.push(items.instagram...)
        item_list.sort (a, b) -> b.score - a.score
        $.each item_list, (i, item) ->
            if item.type is 'instagram'
                item.html = renderInstagram(item)
            else
                item.html = renderTwitter(item)

            item.html.attr('title', item.score)
            $content.append(item.html)

$.getJSON '/data/instagram', (response) ->
    items.instagram = []
    for item in response
        score = scoreInstagram(item)
        setMaxMin(score)
        items.instagram.push
            data    : item
            score   : score
            type    : 'instagram'
    displayItems()

$.getJSON '/data/twitter', (response) ->
    items.twitter = []
    for item in response
        score = scoreTwitter(item)
        setMaxMin(score)
        items.twitter.push
            data    : item
            score   : score
            type    : 'twitter'
    displayItems()




