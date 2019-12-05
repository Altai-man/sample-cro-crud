FROM croservices/cro-http:0.8.0
RUN mkdir /app
COPY . /app
WORKDIR /app
RUN apt-get update && apt-get -y install build-essential
RUN zef install --deps-only . && perl6 -c -Ilib service.p6
ENV BLOG_HOST="0.0.0.0" BLOG_PORT="10000"
EXPOSE 10000
CMD perl6 -Ilib service.p6
