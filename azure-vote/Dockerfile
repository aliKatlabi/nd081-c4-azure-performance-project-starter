# Pull the base image
FROM tiangolo/uwsgi-nginx-flask:python3.10
# Install depndencies 
RUN pip install redis
RUN pip install opencensus
RUN pip install opencensus-ext-azure
RUN pip install opencensus-ext-flask
RUN pip install opencensus-ext-logging
RUN pip install flask
RUN pip install dotenv
RUN pip install gunicorn
# Copy the content of the current directory to the /app of the container
ADD . /app
#CMD ["gunicorn", "-w", "4", "-b", "0.0.0.0:80", "main:app", "--log-level", "debug"]