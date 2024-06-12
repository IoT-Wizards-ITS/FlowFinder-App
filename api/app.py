from flask import Flask, jsonify, request
from openrouteservice import client
from shapely.geometry import LineString, mapping
from shapely.ops import cascaded_union
import requests
from coordinates import avoid_streets  # Assuming this contains the avoid_streets list

app = Flask(__name__)

@app.route('/api/route', methods=['GET'])
def getRoutes():
    api_key = '5b3ce3597851110001cf6248d1d99433d43043488ae5ba0031daaa27'
    ors = client.Client(key=api_key)

    lat1 = request.args.get('lat1', type=float, default=-7.2731657)
    long1 = request.args.get('long1', type=float, default=112.7836309)
    lat2 = request.args.get('lat2', type=float, default=-7.2776391)
    long2 = request.args.get('long2', type=float, default=112.7881034)

    # Fetch avoid streets data
    res = requests.get('http://103.127.137.208/api/avoid_streets')
    if res.status_code == 200:
        avoid_streets_added = res.json().get('avoid_streets', [])
    else:
        avoid_streets_added = []

    coordinates = [[long1, lat1], [long2, lat2]]

    normal_direction_params = {
        'coordinates': coordinates,
        'profile': 'driving-car',
        'format_out': 'geojson',
        'preference': 'recommended',
        'instructions': 'true',
        'instructions_format': 'text',
        'language': 'en',
    }

    regular_route = ors.directions(**normal_direction_params)

    if not avoid_streets_added:
        return jsonify({
            'regular_route': regular_route
        })
    else:
        buffer = []
        for coord in avoid_streets_added:
            coords = coord['coords']
            route_buffer = LineString(coords).buffer(0.0005)
            simp_geom = route_buffer.simplify(0.005)
            buffer.append(simp_geom)
        union = cascaded_union(buffer)

        flood_request = {
            'coordinates': coordinates,
            'profile': 'driving-car',
            'format_out': 'geojson',
            'preference': 'recommended',
            'instructions': 'true',
            'instructions_format': 'text',
            'language': 'en',
            'options': {'avoid_polygons': mapping(union)}
        }

        flood_route = ors.directions(**flood_request)

    return jsonify({
        'regular_route': regular_route,
        'flood_route': flood_route,
        'avoid_streets': avoid_streets_added
    })

@app.route('/api/avoid_streets', methods=['GET'])
def getAvoidedStreets():
    response = requests.get('https://flowfinder-be-dot-protel-e376b.et.r.appspot.com/gsmData')
    if response.status_code != 200:
        return jsonify({
            'message': 'Failed to get GSM data'
        }), 500

    gsm_data = response.json()

    if gsm_data['status'] != 'success':
        return jsonify({
            'message': 'Invalid response from external API'
        }), 500

    avoid_streets_to_add = []
    parsed_data = gsm_data['data']['parsedData']['parsedData']

    for sensors_data in parsed_data:
        for ids in avoid_streets:
            if (int(ids['id']) == int(sensors_data['id'])) and (sensors_data['level'] >= 3):
                avoid_streets_to_add.append({
                    'name': ids['name'],
                    'id': ids['id'],
                    'coords': ids['coords']
                })

    return jsonify({
        'avoid_streets': avoid_streets_to_add
    })

@app.route('/api/test', methods=['GET'])
def test():
    return jsonify({
        'message': 'Hello World'
    })

@app.route('/', methods=['GET'])
def home():
    return '<h2 style="text-align:center"> Flask app is running properly </h2>'

if __name__ == '__main__':
    app.run(debug=True)
