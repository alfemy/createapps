<html>
<head>
</head>
<body>
    <h1>Apps are creating</h1>
    <p><a href="log.txt">Check logs</a></p>
</html>
<?php
exec('nohup /usr/local/bin/createApps.sh > /var/www/html/log.txt 2>&1 &');
