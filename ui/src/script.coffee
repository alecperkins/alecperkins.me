grid_size = 24 #pixels

max_score = -1
min_score = 1e10




calcWidth = (score) ->
    half_grid = 306 / 2
    width = parseInt(half_grid + ((score / max_score) * half_grid))
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
        opacity: 0
    return [$photo, width]

# shade bg of twitter post based on time of day (in EST)

selectColor = (date) ->
    colors = [
        [255,87,56]
        [255,212,0]
        [117,219,137]
    ]
    # hours = (new Date(date)).getUTCHours() -  5
    hours = (new Date(date)).getHours()
    if hours < 0
        hours = 24 + hours

    color_index = hours % 3
    color = colors[color_index]

    blend_percent = (hours / 3) / 8
    prev_color_index = color_index - 1
    if prev_color_index < 0
        prev_color_index = 2
    prev_color = colors[prev_color_index]

    dc = []
    $.each color, (i, channel) ->
        c_delta = prev_color[i] - channel
        dc[i] = channel + c_delta - parseInt(c_delta * blend_percent)

    opacity = 0.2
    return "rgba(#{dc[0]},#{dc[1]},#{dc[2]},#{opacity})"

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
            <p>#{ text.toString() }</p>
            <a class="link" href="https://twitter.com/alecperkins/status/#{ tweet.id }">#</a>
        </div>
    """)

    $tweet.find('[data-display_url]').each (i, tag) ->
        $tag = $(tag)
        $tag.text($tag.attr('data-display_url'))

    half_grid = grid_size / 2
    font_size = (half_grid + (score / max_score * half_grid)).toFixed(0) - 2

    if font_size > grid_size
        font_size = grid_size
    width = calcWidth(score)
    item.font_size = font_size
    $tweet.css
        'font-size': "#{ font_size }px"
        'width': "#{ width }px"
        'background-color': selectColor(item.data.date)
        'opacity': 0

    return [$tweet, width]



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
item_list = []


assembleItems = ->
    if items.twitter? and items.instagram?
        item_list.push(items.twitter...)
        item_list.push(items.instagram...)
        item_list.sort (a, b) -> b.score - a.score
        displayItems()

displayItems = ->
    $content.empty()
    body_width = $('body').width()
    new_row = []
    row_width = 0
    all_rows = []
    max_row_width = 0

    padding = 24

    $.each item_list, (i, item) ->
        if item.type is 'instagram'
            [item.html, item.width] = renderInstagram(item)
        else
            [item.html, item.width] = renderTwitter(item)

        item.html.attr('title', item.score)
        # console.log item.width

        if row_width + item.width < body_width
            new_row.push(item)
            row_width += item.width
        else
            # console.log row_width
            if row_width > max_row_width
                max_row_width = row_width
            new_row.width = row_width
            all_rows.push(new_row)
            row_width = item.width
            new_row = [item]


    $.each all_rows, (i, row) ->
        $row = $('<div class="row"></div>')
        delta = max_row_width - row.width
        per_item_delta = delta / row.length
        # console.log 'max_row_width',max_row_width, 'row.width',row.width, 'delta',delta, 'row.length',row.length, 'per_item_delta', per_item_delta
        $row.css
            width: "#{ max_row_width }px"

        min_width = 1e9
        $content.append($row)

        for item in row
            do ->
                item_width = item.width + per_item_delta
                item.html.css
                    width: item_width
                $row.append(item.html)
                if item_width < min_width
                    min_width = item_width

        # truncate row height to smallest photo height (width since square)
        $row.css
            height: min_width

        $.each row, (j, item) ->
            item_height = item.html.height()
            height_delta = min_width - item_height
            if item.type is 'twitter'
                new_height = item_height + height_delta
                item.html.css
                    height: new_height
                    # 'font-size': item.font_size * (item_height / new_height)
                # $child_p = item.html.find('p')
                # child_height = $child_p.height()
                # $child_p.css
                #     'margin-top': (item.html.height() - child_height) / 5
            else
                # Vertically center photos
                item.html.children().css
                    'margin-top': (height_delta / 2)

            $row.append(item.html)

            setTimeout ->
                item.html.css
                    opacity: 1
            , 100 * j * i



resize_timeout = null
$(window).on 'resize', ->
    if not resize_timeout
        resize_timeout = setTimeout ->
            displayItems()
            resize_timeout = null
        , 1000


$.getJSON '/data/instagram', (response) ->
    items.instagram = []
    for item in response
        score = scoreInstagram(item)
        setMaxMin(score)
        items.instagram.push
            data    : item
            score   : score
            type    : 'instagram'
    assembleItems()

$.getJSON '/data/twitter', (response) ->
    items.twitter = []
    for item in response
        score = scoreTwitter(item)
        setMaxMin(score)
        items.twitter.push
            data    : item
            score   : score
            type    : 'twitter'
    assembleItems()




