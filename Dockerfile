FROM ablu/ubuntu-texlive-full
RUN apt-get update && apt-get install -y pandoc python-pandocfilters python-pip wamerican
