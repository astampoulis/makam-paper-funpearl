FROM ablu/ubuntu-texlive-full
RUN apt-get update && apt-get install -y pandoc wamerican
