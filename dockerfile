FROM python:3.11
WORKDIR /fapi
COPY ./requirements.txt /fapi/requirements.txt
RUN pip install --no-cache-dir --upgrade -r /fapi/requirements.txt
COPY ./src/application /fapi/application
ENV PYTHONPATH /fapi/application
CMD ["uvicorn", "application.fapi:server", "--host", "0.0.0.0", "--port", "8080"]