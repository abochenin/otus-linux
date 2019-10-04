# Домашнее задание 
Создайте свой кастомный образ nginx на базе alpine. После запуска nginx должен
отдавать кастомную страницу (достаточно изменить дефолтную страницу nginx)
Определите разницу между контейнером и образом
Вывод опишите в домашнем задании.
Ответьте на вопрос: Можно ли в контейнере собрать ядро?
Собранный образ необходимо запушить в docker hub и дать ссылку на ваш
репозиторий.

Команды которые могут понадобиться:
```bash
docker ps
docker ps -a
docker run -d -p port:port container_name
docker stop container_name
docker logs container_name - вывод логов контейнеров
docker inspect container_name - информация по запущенному контейнеру
docker build -t dockerhub_login/reponame:ver
docker push/pull
docker exec -it container_name bash
```

Что должно быть Dockerfile:
```bash
FROM image name
RUN apt update -y && apt upgrade -y
COPY или ADD filename /path/in/image
EXPOSE portopenning
CMD or ENTRYPOINT or both
#не забываем про разницу между COPY и ADD
#or - одна из опций на выбор
```
---


## Описание
Полезная команда для разбора какого-либо image из докерхаба, например nginx
```bash
docker history -H --no-trunc --format "{{.ID}} {{.CreatedAt}} {{.Size}} \t{{.CreatedBy}} {{.Comment}}" nginx
```

или в сокращенном варианте, и обратной сортировке

```bash
$ docker history -H --no-trunc --format "{{.CreatedBy}} " nginx|tac

/bin/sh -c #(nop) ADD file:1901172d26545609083e48b9bfaf2cb46674f37af0902ad5a32e2420301225de in /
/bin/sh -c #(nop)  CMD ["bash"]
/bin/sh -c #(nop)  LABEL maintainer=NGINX Docker Maintainers <docker-maint@nginx.com>
/bin/sh -c #(nop)  ENV NGINX_VERSION=1.17.4
/bin/sh -c #(nop)  ENV NJS_VERSION=0.3.5
/bin/sh -c #(nop)  ENV PKG_RELEASE=1~buster
/bin/sh -c set -x     && addgroup --system --gid 101 nginx     && adduser --system --disabled-login --ingroup nginx --no-create-home --home /nonexistent --gecos "nginx user" --shell /bin/false --uid 101 nginx     && apt-get update     && apt-get install --no-install-recommends --no-install-suggests -y gnupg1 ca-certificates     &&     NGINX_GPGKEY=573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62;     found='';     for server in         ha.pool.sks-keyservers.net         hkp://keyserver.ubuntu.com:80         hkp://p80.pool.sks-keyservers.net:80         pgp.mit.edu     ; do         echo "Fetching GPG key $NGINX_GPGKEY from $server";         apt-key adv --keyserver "$server" --keyserver-options timeout=10 --recv-keys "$NGINX_GPGKEY" && found=yes && break;     done;     test -z "$found" && echo >&2 "error: failed to fetch GPG key $NGINX_GPGKEY" && exit 1;     apt-get remove --purge --auto-remove -y gnupg1 && rm -rf /var/lib/apt/lists/*     && dpkgArch="$(dpkg --print-architecture)"     && nginxPackages="         nginx=${NGINX_VERSION}-${PKG_RELEASE}         nginx-module-xslt=${NGINX_VERSION}-${PKG_RELEASE}         nginx-module-geoip=${NGINX_VERSION}-${PKG_RELEASE}         nginx-module-image-filter=${NGINX_VERSION}-${PKG_RELEASE}         nginx-module-njs=${NGINX_VERSION}.${NJS_VERSION}-${PKG_RELEASE}     "     && case "$dpkgArch" in         amd64|i386)             echo "deb https://nginx.org/packages/mainline/debian/ buster nginx" >> /etc/apt/sources.list.d/nginx.list             && apt-get update             ;;         *)             echo "deb-src https://nginx.org/packages/mainline/debian/ buster nginx" >> /etc/apt/sources.list.d/nginx.list                         && tempDir="$(mktemp -d)"             && chmod 777 "$tempDir"                         && savedAptMark="$(apt-mark showmanual)"                         && apt-get update             && apt-get build-dep -y $nginxPackages             && (                 cd "$tempDir"                 && DEB_BUILD_OPTIONS="nocheck parallel=$(nproc)"                     apt-get source --compile $nginxPackages             )                         && apt-mark showmanual | xargs apt-mark auto > /dev/null             && { [ -z "$savedAptMark" ] || apt-mark manual $savedAptMark; }                         && ls -lAFh "$tempDir"             && ( cd "$tempDir" && dpkg-scanpackages . > Packages )             && grep '^Package: ' "$tempDir/Packages"             && echo "deb [ trusted=yes ] file://$tempDir ./" > /etc/apt/sources.list.d/temp.list             && apt-get -o Acquire::GzipIndexes=false update             ;;     esac         && apt-get install --no-install-recommends --no-install-suggests -y                         $nginxPackages                         gettext-base     && apt-get remove --purge --auto-remove -y ca-certificates && rm -rf /var/lib/apt/lists/* /etc/apt/sources.list.d/nginx.list         && if [ -n "$tempDir" ]; then         apt-get purge -y --auto-remove         && rm -rf "$tempDir" /etc/apt/sources.list.d/temp.list;     fi
/bin/sh -c ln -sf /dev/stdout /var/log/nginx/access.log     && ln -sf /dev/stderr /var/log/nginx/error.log
/bin/sh -c #(nop)  EXPOSE 80
/bin/sh -c #(nop)  STOPSIGNAL SIGTERM
/bin/sh -c #(nop)  CMD ["nginx" "-g" "daemon off;"]
```

Делаем для alpine аналогично

```bash
ln -sf /dev/stdout /var/log/nginx/access.log
ln -sf /dev/stderr /var/log/nginx/error.log
EXPOSE 80
CMD ["nginx" "-g" "daemon off;"]
```

Итоговый Dockerfile после многочисленных тестовых попыток
```bash
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
```

Наткнулся на необычное (для меня, только начинающего изучать докер) поведение. В моем окружении корпоративный 
файрвол ограничивает доступ к публичным DNS серверам 8.8.4.4 и т.п. Поскольку в контейнере по умолчанию используется как раз гугловый
днс, я пытался изменить его разными способами, вставляя в dockerfile команды
```bash
RUN echo "nameserver 11.22.33.44" > /etc/resolv.conf
или COPY nameserver /etc/resolv.conf
```
Но оказывается, эти изменения действуют только на данном шаге, а на следующем - содержимое файла /etc/resolv.conf 
опять сброшено на умолчательное. Для меня это было не очевидно... Пришлось соединять команды в одну строку.

Позднее нашел в документации объяснение подобного поведения https://docs.docker.com/v17.09/engine/userguide/networking/configure-dns/

Собираем образ
```bash
docker build  -t abochenin/otus:0.7 .
```

Отправляем образ в хранилище
```bash
$ docker login
$ docker push abochenin/otus:0.7
```

## Проверки
Запуск контейнера
```bash
$ docker run -it -p 80:80 abochenin/otus:0.7
```

В браузере или в другой консоли пытаемся обратиться к localhost
```bash
$ curl localhost 
<!DOCTYPE html>
<html>
<head>
<title>Welcome OTUS to nginx!</title>
```

При этом в консоли, где запущен контейнер, видны сообщения из access.log
```bash
$ docker run -it -p 80:80 abochenin/otus:0.7
172.17.0.1 - - [04/Oct/2019:13:36:31 +0000] "GET / HTTP/1.1" 200 622 "-" "Mozilla/5.0 (X11; Linux x86_64; rv:60.0) Gecko/20100101 Firefox/60.0" "-"
172.17.0.1 - - [04/Oct/2019:13:36:46 +0000] "GET / HTTP/1.1" 200 622 "-" "curl/7.64.0-DEV" "-"
```

Вопрос: Определите разницу между контейнером и образом

Образ - это шаблон (файл), а контейнеры - конкретные экземпляры (процессы) на основе образа

Вопрос:Можно ли в контейнере собрать ядро?

Собрать можно, но установить ядро - думаю, не выйдет, т.к. все контейнеры работают под упралением докер-демона и на едином ядре хост-системы.
