# s2i Seldon Example
YOLOv7 packaged with Seldon Core, for deployment on OpenShift cluster

## Quickstart
```
python -m venv venv
. ./venv/bin/activate

pip install -U pip
pip install -r requirements.txt

bash .s2i/bin/run
```

## Dumped Links

- https://github.com/carlmes/yolov7_seldon.git

* Blog: [Building Machine Learning Services in Kubernetes](https://www.makeartwithpython.com/blog/building-ml-services-on-kubernetes/)

* [MLOps Model Serving Tutorial - Seldon Core](https://www.youtube.com/watch?v=L746MuYzX1c)

* https://github.com/yinondn/seldon-core-tutorial/blob/main/quickstart.md - This tutorial shows to run ML model serving at scale on AWS using Seldon Core.

* https://docs.seldon.io/projects/seldon-core/en/latest/tutorials/openshift_s2i.html - Using Openshift Source-to-Image to facilitate Machine Learning Deployment 
  * https://github.com/SeldonIO/seldon-core/tree/master/wrappers/s2i
  * https://github.com/WongKinYiu/yolov7/blob/main/models/yolo.py

* https://www.fuzzylabs.ai/blog-post/serving-models-with-seldon-core - Serving models with Seldon Core
  * https://github.com/fuzzylabs/seldon-example

* https://github.com/strangiato/Iris_seldon/tree/main/iris-seldon-service - Example from Trevor

* https://github.com/openshift/source-to-image

* https://github.com/SeldonIO/seldon-core/issues/3019