FROM ablu/ubuntu-texlive-full:b1bb5e40a22e
RUN apt-get update && apt-get install -y pandoc
