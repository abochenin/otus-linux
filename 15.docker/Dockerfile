FROM alpine
MAINTAINER abochenin
COPY . /
#RUN echo "nameserver 11.22.33.44" > /etc/resolv.conf&& apk update && apk upgrade && apk add nginx
RUN apk update && apk upgrade && apk add nginx
RUN ln -sf /dev/stdout /var/log/nginx/access.log
RUN ln -sf /dev/stderr /var/log/nginx/error.log
RUN sed s/Welcome\ to/Welcome\ OTUS\ to/g -i /var/lib/nginx/html/index.html
COPY default.conf /etc/nginx/conf.d/default.conf
RUN mkdir /run/nginx
RUN chown nginx:nginx /run/nginx
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]

