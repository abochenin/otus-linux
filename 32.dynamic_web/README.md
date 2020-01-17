## Домашнее задание 32.dynamicweb
Собрать стенд с 3мя проектами на выбор
Варианты стенда
nginx + php-fpm (laravel/wordpress) + python (flask/django) + js(react/angular)
nginx + java (tomcat/jetty/netty) + go + ruby
можно свои комбинации

Реализации на выбор
- на хостовой системе через конфиги в /etc
- деплой через docker-compose

## Развертываем инфраструктуру

```bash
$ vagrant up
...
PLAY RECAP *********************************************************************
dweb                       : ok=25   changed=20   unreachable=0    failed=0 
```

## Проверки

Приложение java

```bash
$ curl http://192.168.11.100/tomcat/sample/
<html>
<head>
<title>Sample "Hello, World" Application</title>
</head>
<body bgcolor=white>

<table border="0">
<tr>
<td>
<img src="images/tomcat.gif">
</td>
<td>
<h1>Sample "Hello, World" Application</h1>
<p>This is the home page for a sample application used to illustrate the
source directory organization of a web application utilizing the principles
outlined in the Application Developer's Guide.
</td>
</tr>
</table>

<p>To prove that they work, you can execute either of the following links:
<ul>
<li>To a <a href="hello.jsp">JSP page</a>.
<li>To a <a href="hello">servlet</a>.
</ul>

</body>
</html>
```

Приложение на ruby

```bash
$ curl  http://192.168.11.100/ruby/
Hello Otus from Ruby!
```

Приложение на Golang

```bash
$ curl  http://192.168.11.100/golang/
Hello Otus from Go!
```

