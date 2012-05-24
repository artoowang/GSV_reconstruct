<html>
<head>
<title>Save panoid</title>
</head>
<body>
<?php
error_reporting(E_ALL);
ini_set('display_errors', '1');

if(!array_key_exists('name', $_GET)) {
	printf('Name is not specified');
	exit();
}
$name = $_GET['name'];

if($name == '') {
	printf('Name is empty');
	exit();
}

if(array_key_exists('reset', $_GET)) {
	unlink("data/$name");
} else if(array_key_exists('panoid', $_GET) && array_key_exists('lat', $_GET) && array_key_exists('lng', $_GET)) {
	$name = $_GET['name'];
	$panoid = $_GET['panoid'];
	$lat = $_GET['lat'];
	$lng = $_GET['lng'];
	$yaw = $_GET['yaw'];
	$tilt_yaw = $_GET['tilt_yaw'];
	$tilt_pitch = $_GET['tilt_pitch'];
	$seq = $_GET['seq'];

	$fp = fopen("data/$name", 'a');
	$str = sprintf("%d\t%s\t%.6f\t%.6f\t%.6f\t%.6f\t%.6f\n", $seq, $panoid, $lat, $lng, $yaw, $tilt_yaw, $tilt_pitch);
	fwrite($fp, $str);
	fclose($fp);

	echo($str);
} else {
	printf('Invalid arguments');
}
?>
</body>
</html>
