_openTag = (t) ->
    attrs = ''
    for k, v of t.attrs
        attrs += " #{k}=\"#{v}\""
    return "<#{t.tag}#{attrs}>"

_closeTag = (t) ->
    return "</#{t.tag}>"

_addTextAnnotations = (text, annotations) ->
    ###
    Private: insert the specified annotation tags into the given text at the
    correct positions, avoiding overlapping tags (invalid HTML).

    The text is broken into segments, bounded by the start and end points of all of
    the annotations. It is then reassembled, with opening and closing tags for
    annotations inserted between the segments. Tags are closed and reopened as
    needed to prevent overlap.

    For example, given:

        text = "Duis mollis, est non commodo luctus, nisi erat porttitor ligula, \
        eget lacinia odio sem nec elit."

        annotations = [{
            'type': 'emphasis',
            'start': 5,
            'end': 30,
        },{
            'type': 'strong',
            'start': 20,
            'end': 50,
        }]

    Simply inserting the tags at the given `start` and `end` positions would
    result in invalid HTML:

        "Duis <em>mollis, est non<strong> commodo l</em>uctus, nisi erat por\
        </strong>ttitor ligula, eget lacinia odio sem nec elit."

    The correct output is:

        "Duis <em>mollis, est non<strong> commodo l</strong></em><strong>\
        uctus, nisi erat por</strong>ttitor ligula, eget lacinia odio sem nec\
         elit."

    Note that the `</strong>` tag before the `strong`'s `end`, to allow the
    `emphasis` annotation to be closed without overlapping the `<strong>`. The
    `strong` annotation is then reopened with a `<strong>` and then closed at
    its actual end.


    * content     - str content of the block
    * annotations - list of annotations (MAY be empty)
        * type  - str type of the annotation
        * start - int starting point of the annotation
        * end   - int ending point of the annotation
        * attrs - (optional) a dict of tag attributes

    Returns a unicode containing the markup of the text content, with
    annotations inserted.
    ###

    # Index annotations by their start and end positions.
    annotation_index_by_start = {}
    annotation_index_by_end = {}

    for a in annotations
        annotation_index_by_start[a['start']] ?= []
        annotation_index_by_start[a['start']].push( a )

        if a['start'] != a['end']
            annotation_index_by_end[a['end']] ?= []
            annotation_index_by_end[a['end']].push( a )


    # Find the segment boundaries of text, as bounded by opening and closing
    # tags (equivalent to the text nodes in the HTML DOM).
    segment_boundaries = []
    for k, v of annotation_index_by_start
        segment_boundaries.push(parseInt(k))
    for k, v of annotation_index_by_end
        segment_boundaries.push(parseInt(k))
    segment_boundaries.sort (a,b) -> a - b

    # Make sure the segments include the beginning and end of the text.
    if segment_boundaries.length == 0 or segment_boundaries[0] != 0
        segment_boundaries.unshift(0)
    if segment_boundaries[segment_boundaries.length-1] != text.length
        segment_boundaries.push(text.length)

    # Extract the actual text content for each segment.
    segments = []
    for i, bound of segment_boundaries[0...-1]
        start = bound
        end = segment_boundaries[parseInt(i)+1]
        if start != end
            segments.push(text.substring(start,end))

    output = ''
    open_tags = []
    i = 0

    for seg_text in segments
        tags_to_open = annotation_index_by_start[i] or []
        tags_to_close = annotation_index_by_end[i] or []

        tags_to_reopen = []
        for t in tags_to_close
            # Work back up the stack of open tags until the annotation to be
            # closed is found, closing the open tags in order and saving them
            # for reopening. (This should raise an IndexError if there aren't
            # any open tags, which should not be true at this point.)
            while open_tags.length > 0 and t['tag'] != open_tags[open_tags.length-1]['tag']
                o_tag = open_tags.pop()
                output += _closeTag(o_tag)
                tags_to_reopen.push(o_tag)

            # Close the annotation.
            output += _closeTag(t)
            open_tags.pop()

            # Reopen annotations that were closed to prevent overlap.
            while tags_to_reopen.length > 0
                o_tag = tags_to_reopen.pop()
                output += _openTag(o_tag)
                open_tags.push(o_tag)

        # Open the tags that start at this point.
        for t in tags_to_open
            output += _openTag(t)
            # Unless the tag also closes at this point, add it to the stack of
            # open tags. Otherwise, close it.
            if t['start'] != t['end']
                open_tags.push(t)
            else
                output += _closeTag(t)

        # Add the segment text content.
        output += seg_text

        i += seg_text.length

    # Close any tags that are still open (should only be any that are set to
    # end at the end of the target string).
    while open_tags.length > 0
        o_tag = open_tags.pop()
        output += _closeTag(o_tag)


    return output





class NOAT
    constructor: (text) ->
        if text.length is 0
            throw new Error('text length must be greater than zero')
        @text           = text
        @annotations    = []
        @_markup        = null

    add: (tag, start, end_or_attrs, attrs={}) ->
        if arguments.length > 4
            throw new Error("add() takes 3 or 4 arguments (#{ arguments.length } given)")

        if typeof end_or_attrs isnt 'number'
            end = start
            attrs = end_or_attrs
        else
            end = end_or_attrs

        start = parseInt(start)
        end = parseInt(end)

        @_validateRange(start, end)

        @annotations.push
            tag     : tag
            start   : start
            end     : end
            attrs   : attrs
        @_markup = null

    _applyAnnotations: ->
        @_markup = _addTextAnnotations(@text, @annotations)

    toString: ->
        if not @_markup?
            @_applyAnnotations()
        return @_markup

    _validateRange: (start, end) ->
        if start > end
            throw new Error("start (#{ start }) must be <= end (#{ end })")
        if start < 0
            throw new Error("start (#{ start }) must be >= 0")
        if end > @text.length
            throw new Error("end (#{ end }) must be <= length of text (#{ @text.length })")


window.NOAT = NOAT