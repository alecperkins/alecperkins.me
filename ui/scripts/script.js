// Generated by CoffeeScript 1.4.0
(function() {
  var $content, NOW, assembleItems, calcWidth, displayItems, grid_size, item_list, items, max_score, min_score, renderInstagram, renderTwitter, resize_timeout, scoreInstagram, scoreTwitter, selectColor, setMaxMin;

  grid_size = 24;

  max_score = -1;

  min_score = 1e10;

  calcWidth = function(score) {
    var half_grid, width;
    half_grid = 306 / 2;
    width = parseInt(half_grid + ((score / max_score) * half_grid));
    return width;
  };

  renderInstagram = function(item) {
    var $photo, photo, score, width;
    photo = item.data;
    score = item.score;
    $photo = $("<div class=\"item photo\">\n    <img src=\"" + photo.urls.low_resolution.url + "\">\n    <a class=\"link\" href=\"" + photo.link + "\">#</a>\n</div>");
    width = calcWidth(score);
    $photo.css({
      'width': "" + width + "px",
      opacity: 0
    });
    return [$photo, width];
  };

  selectColor = function(date) {
    var blend_percent, color, color_index, colors, dc, hours, opacity, prev_color, prev_color_index;
    colors = [[255, 87, 56], [255, 212, 0], [117, 219, 137]];
    hours = (new Date(date)).getHours();
    if (hours < 0) {
      hours = 24 + hours;
    }
    color_index = hours % 3;
    color = colors[color_index];
    blend_percent = (hours / 3) / 8;
    prev_color_index = color_index - 1;
    if (prev_color_index < 0) {
      prev_color_index = 2;
    }
    prev_color = colors[prev_color_index];
    dc = [];
    $.each(color, function(i, channel) {
      var c_delta;
      c_delta = prev_color[i] - channel;
      return dc[i] = channel + c_delta - parseInt(c_delta * blend_percent);
    });
    opacity = 0.2;
    return "rgba(" + dc[0] + "," + dc[1] + "," + dc[2] + "," + opacity + ")";
  };

  renderTwitter = function(item) {
    var $tweet, font_size, half_grid, media_list, score, text, tweet, width;
    score = item.score;
    tweet = item.data;
    text = new NOAT(tweet.text);
    $.each(tweet.entities.hashtags, function(i, t) {
      return text.add('a', t.indices[0], t.indices[1], {
        href: "https://twitter.com/?q=%23" + (t.text.substring(1))
      });
    });
    $.each(tweet.entities.urls, function(i, t) {
      return text.add('a', t.indices[0], t.indices[1], {
        href: t.url,
        'data-display_url': t.display_url
      });
    });
    $.each(tweet.entities.user_mentions, function(i, t) {
      return text.add('a', t.indices[0], t.indices[1], {
        href: "https://twitter.com/" + t.screen_name
      });
    });
    media_list = tweet.entities.media || [];
    $.each(media_list, function(i, t) {
      return text.add('span', t.indices[0], t.indices[1], {
        'data-image': t.media_url,
        'data-display_url': t.display_url
      });
    });
    $tweet = $("<div class=\"item tweet\">\n    <p>" + (text.toString()) + "</p>\n    <a class=\"link\" href=\"https://twitter.com/alecperkins/status/" + tweet.id + "\">#</a>\n</div>");
    $tweet.find('[data-display_url]').each(function(i, tag) {
      var $tag;
      $tag = $(tag);
      return $tag.text($tag.attr('data-display_url'));
    });
    half_grid = grid_size / 2;
    font_size = (half_grid + (score / max_score * half_grid)).toFixed(0) - 2;
    if (font_size > grid_size) {
      font_size = grid_size;
    }
    width = calcWidth(score);
    item.font_size = font_size;
    $tweet.css({
      'font-size': "" + font_size + "px",
      'width': "" + width + "px",
      'background-color': selectColor(item.data.date),
      'opacity': 0
    });
    return [$tweet, width];
  };

  NOW = (new Date()).getTime();

  scoreInstagram = function(item) {
    var score, time_delta;
    time_delta = NOW - new Date(item.date).getTime();
    score = (1 / time_delta * 1e10).toFixed(2);
    score = score * (item.comments_count + (2 * item.likes_count) + 1);
    return score;
  };

  scoreTwitter = function(item) {
    var score, time_delta;
    time_delta = NOW - new Date(item.date).getTime();
    score = (1 / time_delta * 1e10).toFixed(2);
    score = score * (item.retweet_count * 2 + 1);
    return score;
  };

  setMaxMin = function(score) {
    if (score > max_score) {
      return max_score = score;
    } else if (score < min_score) {
      return min_score = score;
    }
  };

  $content = $('.content');

  items = {};

  item_list = [];

  assembleItems = function() {
    if ((items.twitter != null) && (items.instagram != null)) {
      item_list.push.apply(item_list, items.twitter);
      item_list.push.apply(item_list, items.instagram);
      item_list.sort(function(a, b) {
        return b.score - a.score;
      });
      return displayItems();
    }
  };

  displayItems = function() {
    var all_rows, body_width, max_row_width, new_row, padding, row_width;
    $content.empty();
    body_width = $('body').width();
    new_row = [];
    row_width = 0;
    all_rows = [];
    max_row_width = 0;
    padding = 24;
    $.each(item_list, function(i, item) {
      var _ref, _ref1;
      if (item.type === 'instagram') {
        _ref = renderInstagram(item), item.html = _ref[0], item.width = _ref[1];
      } else {
        _ref1 = renderTwitter(item), item.html = _ref1[0], item.width = _ref1[1];
      }
      item.html.attr('title', item.score);
      if (row_width + item.width < body_width) {
        new_row.push(item);
        return row_width += item.width;
      } else {
        if (row_width > max_row_width) {
          max_row_width = row_width;
        }
        new_row.width = row_width;
        all_rows.push(new_row);
        row_width = item.width;
        return new_row = [item];
      }
    });
    return $.each(all_rows, function(i, row) {
      var $row, delta, item, min_width, per_item_delta, _fn, _i, _len;
      $row = $('<div class="row"></div>');
      delta = max_row_width - row.width;
      per_item_delta = delta / row.length;
      $row.css({
        width: "" + max_row_width + "px"
      });
      min_width = 1e9;
      $content.append($row);
      _fn = function() {
        var item_width;
        item_width = item.width + per_item_delta;
        item.html.css({
          width: item_width
        });
        $row.append(item.html);
        if (item_width < min_width) {
          return min_width = item_width;
        }
      };
      for (_i = 0, _len = row.length; _i < _len; _i++) {
        item = row[_i];
        _fn();
      }
      $row.css({
        height: min_width
      });
      return $.each(row, function(j, item) {
        var height_delta, item_height, new_height;
        item_height = item.html.height();
        height_delta = min_width - item_height;
        if (item.type === 'twitter') {
          new_height = item_height + height_delta;
          item.html.css({
            height: new_height
          });
        } else {
          if (height_delta > 0) {
            height_delta = 0;
          }
          item.html.children('img').css({
            top: height_delta / 2
          });
        }
        $row.append(item.html);
        return setTimeout(function() {
          return item.html.css({
            opacity: 1
          });
        }, 100 * j * i);
      });
    });
  };

  resize_timeout = null;

  $(window).on('resize', function() {
    if (!resize_timeout) {
      return resize_timeout = setTimeout(function() {
        displayItems();
        return resize_timeout = null;
      }, 1000);
    }
  });

  $.getJSON('/data/instagram', function(response) {
    var item, score, _i, _len;
    items.instagram = [];
    for (_i = 0, _len = response.length; _i < _len; _i++) {
      item = response[_i];
      score = scoreInstagram(item);
      setMaxMin(score);
      items.instagram.push({
        data: item,
        score: score,
        type: 'instagram'
      });
    }
    return assembleItems();
  });

  $.getJSON('/data/twitter', function(response) {
    var item, score, _i, _len;
    items.twitter = [];
    for (_i = 0, _len = response.length; _i < _len; _i++) {
      item = response[_i];
      score = scoreTwitter(item);
      setMaxMin(score);
      items.twitter.push({
        data: item,
        score: score,
        type: 'twitter'
      });
    }
    return assembleItems();
  });

}).call(this);
