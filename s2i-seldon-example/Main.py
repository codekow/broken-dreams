import os
import pandas as pd
import torch

model_name = os.environ.get("MODEL_NAME", "Main")

import sys

sys.path.insert(0, "./data")


class Main:
    def __init__(self):
        self.model_name = "Main"
        print("**** Calling init ****")

        print(f"**** Loading model = {model_name} ****")
        # load the model from disk
        self.model = torch.load("data/" + model_name, map_location=torch.device("cpu"))

    def predict(self, X, features_names):
        df = pd.DataFrame(data=X, columns=features_names)

        pred = self.model.predict(df)
        print(f"Returning prediction: {pred}")
        return pred

    def metrics(self):
        return [
            {
                "type": "COUNTER",
                "key": "mycounter",
                "value": 1,
            },  # a counter which will increase by the given value
            {
                "type": "GAUGE",
                "key": "mygauge",
                "value": 100,
            },  # a gauge which will be set to given value
            {
                "type": "TIMER",
                "key": "mytimer",
                "value": 20.2,
            },  # a timer which will add sum and count metrics - assumed millisecs
        ]
