#!/usr/bin/env python
# https://stackoverflow.com/questions/1523427/what-is-the-common-header-format-of-python-files

import joblib
import re
from sklearn.neural_network import MLPClassifier
from sklearn.feature_extraction.text import TfidfVectorizer
from fastapi import FastAPI

app = FastAPI()

try:
    model = open('data/spam_classifier.joblib')
    model.close()
except IOError:
    exec(open("train.py").read())

model = joblib.load('data/spam_classifier.joblib')


def preprocessor(text):
    text = re.sub('<[^>]*>', '', text) # Effectively removes HTML markup tags
    emoticons = re.findall('(?::|;|=)(?:-)?(?:\)|\(|D|P)', text)
    text = re.sub('[\W]+', ' ', text.lower()) + ' '.join(emoticons).replace('-', '')
    return text

def classify_message(model, message):

	message = preprocessor(message)
	label = model.predict([message])[0]
	spam_prob = model.predict_proba([message])

	return {'label': label, 'spam_probability': spam_prob[0][1]}

@app.get('/')
def get_root():

	return {'message': 'Welcome to the spam detection API'}

@app.get('/spam')
async def detect_spam_parameters(message: str):
	return classify_message(model, message)

@app.get('/spam/{message}')
async def detect_spam_path(message: str):
	return classify_message(model, message)

# uvicorn main:app --host 0.0.0.0 --port 8080 --reload
if __name__ == "__main__":

    # Use this for debugging purposes only
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8080, log_level="debug")
