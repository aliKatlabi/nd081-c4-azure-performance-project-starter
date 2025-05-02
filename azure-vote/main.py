from flask import Flask, request, render_template, redirect, url_for
import os
import random
import redis
import socket
import sys
import logging
from dotenv import load_dotenv
from telemetry import Telemetry
load_dotenv()

app = Flask(__name__)

telemetry = Telemetry(
    app=app
)

app.config.from_pyfile('config_file.cfg')

if ("VOTE1VALUE" in os.environ and os.environ['VOTE1VALUE']):
    button1 = os.environ['VOTE1VALUE']
else:
    button1 = app.config['VOTE1VALUE']

if ("VOTE2VALUE" in os.environ and os.environ['VOTE2VALUE']):
    button2 = os.environ['VOTE2VALUE']
else:
    button2 = app.config['VOTE2VALUE']

if ("TITLE" in os.environ and os.environ['TITLE']):
    title = os.environ['TITLE']
else:
    title = app.config['TITLE']

# Redis Connection
r = redis.Redis()

# Change title to host name to demo NLB
if app.config['SHOWHOST'] == "true":
    title = socket.gethostname()

# Init Redis
if not r.get(button1): r.set(button1,0)
if not r.get(button2): r.set(button2,0)

@app.route('/', methods=['GET', 'POST'])
def index():

    if request.method == 'GET':

        vote1 = int(r.get(button1).decode('utf-8'))
        vote2 = int(r.get(button2).decode('utf-8'))

        # Log custom event for retrieving votes
        with telemetry.tracer.span(name="GET /index - Retrieve Votes") as span:
            span.add_attribute("Cats Vote", vote1)
            span.add_attribute("Dogs Vote", vote2)

        telemetry.logger.info("Retrieve Votes", extra={
            'custom_dimensions': {
                'Cats Vote': vote1,
                'Dogs Vote': vote2
            }
        })
        
        #return render_template("index.html", value1=int(vote1), value2=int(vote2), button1=button1, button2=button2, title=title)

    elif request.method == 'POST':
        vote = request.form.get('vote')

        if vote == 'reset':

            # Reset votes
            r.set(button1, 0)
            r.set(button2, 0)
            vote1 = r.get(button1).decode('utf-8')
            vote2 = r.get(button2).decode('utf-8')

            # Log reset event
            telemetry.logger.info("Reset Votes", extra={
                'custom_dimensions': {
                    'Cats Vote': vote1,
                    'Dogs Vote': vote2
                }
            })

            return render_template("index.html", value1=int(vote1), value2=int(vote2), button1=button1, button2=button2, title=title)

        else:
            # Increment the vote count in Redis
            r.incr(vote,1)

            # Log custom event for voting
            if vote == button1:
                telemetry.logger.info("Cat Vote", extra={
                    'custom_dimensions': {
                        'Vote Type': "Cat",
                        'Total Votes': int(r.get(button1).decode('utf-8'))
                    }
                })
            elif vote == button2:
                telemetry.logger.info("Dog Vote", extra={
                    'custom_dimensions': {
                        'Vote Type': "Dog",
                        'Total Votes': int(r.get(button2).decode('utf-8'))
                    }
                })
           
            return redirect(url_for('index')) 
           
    
    
    return render_template("index.html", value1=int(vote1), value2=int(vote2), button1=button1, button2=button2, title=title)


if __name__ == "__main__":
    # TODO: Use the statement below when running locally
    
    #app.run() 
    # TODO: Use the statement below before deployment to VMSS
    app.run(host='0.0.0.0', threaded=True, debug=True) # remote
