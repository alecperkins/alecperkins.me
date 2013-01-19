import json, os
from flask import Flask, jsonify, make_response, render_template

from fetchers import fetchInstagram, fetchTwitter


app = Flask(__name__,
    template_folder = 'ui',
    static_folder   = 'ui',
    static_url_path = '/static',
)

def jsonResponse(data):
    data_string = json.dumps(data)
    response = make_response(data_string)
    response.headers['Content-Type'] = 'application/json'
    return response


@app.route('/')
def hello():
    return render_template('index.html')

@app.route('/data/instagram')
def instagramData():
    data = fetchInstagram()
    return jsonResponse(data)

@app.route('/data/twitter')
def twitterData():
    data = fetchTwitter()
    return jsonResponse(data)


if __name__ == '__main__':
    # Bind to PORT if defined, otherwise default to 5000.
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=False)
