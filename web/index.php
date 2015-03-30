<?php
include_once('lib/config.php');
include('lib/steamid.php');
//------------------------------------------------------------------------------------------------------------+
  header("Content-Type:text/html; charset=utf-8");
//------------------------------------------------------------------------------------------------------------+

// Create connection
$con=mysqli_connect($mysql_host,$mysql_name,$mysql_pass,$mysql_db);

$getrank=0;

// Check connection
if (mysqli_connect_errno())
	{
		echo "Failed to connect to MySQLi: " . mysqli_connect_error();
	}
$result_users = mysqli_query($con,"SELECT * FROM bb_stats ORDER BY exp + 0 DESC");
?>
<!DOCTYPE html>
<html lang="en">
<head>
	<title>BrainBread Stats</title>
	<meta http-equiv='Content-Type' content='text/html; charset=utf-8' />
	<meta http-equiv='content-style-type' content='text/css' />
	<link rel='stylesheet' href='style.css' type='text/css' />
	<meta charset="utf-8" /><!--
	<script src="https://ajax.googleapis.com/ajax/libs/jquery/1.9.0/jquery.min.js"></script>-->
	<script src="ajax/steamprofile.js"></script>
	<script type="text/javascript" language="javascript" src="js/jquery.js"></script>
	<script type="text/javascript" language="javascript" src="js/jquery.dataTables.js"></script>
	<script type="text/javascript" language="javascript" src="resources/syntax/shCore.js"></script>
	<script type="text/javascript" language="javascript" src="resources/demo.js"></script>
	<link rel="stylesheet" type="text/css" href="css/jquery.dataTables.css">
	<script type="text/javascript" language="javascript" class="init">

$(document).ready(function() {
	$('#bbstats_table').dataTable( {
		"paging":   true,
		"ordering": false,
		"info":     true,
		"lengthMenu": [[10, 25, 35, 45], [10, 25, 35, 45]],
		stateSave: true,
		"language": {
            "lengthMenu": "Display _MENU_ users per page",
            "zeroRecords": "Nothing found - sorry",
            "info": "Showing page _PAGE_ of _PAGES_",
            "infoEmpty": "No users available",
            "infoFiltered": "(filtered from _MAX_ total users)"
        }
	} );
} );

	</script>
</head>
<body>
	<div style='height:30px'><br /></div>
	<center>
		<p>
			<!--
				CONTENT HERE
			-->
		</p>
	</center>
	<div style="text-align:center">
		<?php include_once('pages/stats.php'); ?>
	</div>
</body>
</html>
