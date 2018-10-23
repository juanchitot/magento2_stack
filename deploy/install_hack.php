<?php
$env  = include("../app/etc/env.php");
$env['install'] =  array (
    'date' => 'Thu, 20 Oct 2016 11:42:45 +0000'
  );
$env['cache_types'] =
  array (
    'config' => 1,
    'layout' => 1,
    'block_html' => 1,
    'collections' => 1,
    'reflection' => 1,
    'db_ddl' => 1,
    'eav' => 1,
    'customer_notification' => 1,
    'full_page' => 1,
    'config_integration' => 1,
    'config_integration_api' => 1,
    'translate' => 1,
    'config_webservice' => 1,
  );

$new_config =var_export($env,true);

file_put_contents( '../app/etc/env.php','<?php return '. $new_config.';');
