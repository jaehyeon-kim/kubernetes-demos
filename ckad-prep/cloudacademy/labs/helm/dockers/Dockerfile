FROM python:3

RUN pip install flask

RUN mkdir -p /corp/app
WORKDIR /corp/app
COPY main.py .
ENV FLASK_APP=/corp/app/main.py

ENV APP_NAME=CloudAcademy.DevOps.K8s

CMD ["flask", "run", "--host=0.0.0.0"]