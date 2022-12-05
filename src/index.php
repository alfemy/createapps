<html>
<head>

</head>
<body>
    <h1>To create apps click to:</h1>
    <p><a href="create.php">Create</a></p>

<?php

// Print environment variables APPS_TYPE and APPS_COUNT, if they are set. also print OAUTH2_PROXY

if (getenv('APPS_TYPE')) {
    echo "<p>APPS_TYPE: " . getenv('APPS_TYPE') . "</p>";
}
if (getenv('APPS_COUNT')) {
    echo "<p>APPS_COUNT: " . getenv('APPS_COUNT') . "</p>";
}

if (getenv('OAUTH2_PROXY')) {
    echo "<p>OAUTH2_PROXY: " . getenv('OAUTH2_PROXY') . "</p>";
}
?>


</body>
</html>





