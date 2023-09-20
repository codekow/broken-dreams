# import app elements
from flask import Flask

app = Flask(__name__)

# 'application' reference required for wgsi / gunicorn
# https://docs.openshift.com/container-platform/3.11/using_images/s2i_images/python.html#using-images-python-configuration

application = app


@app.route("/")
def hello():
    return "Hello World!"

# gunicorn app:app
if __name__ == "__main__":
    app.run(debug=True, port=8080, host="0.0.0.0")  # nosec