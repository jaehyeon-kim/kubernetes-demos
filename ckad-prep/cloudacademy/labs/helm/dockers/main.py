import os
from flask import Flask
app = Flask(__name__)

@app.route('/')
def index():
    appname = os.environ['APP_NAME']
    response = "%s - %s\n" %('Hello World', appname)
    return response