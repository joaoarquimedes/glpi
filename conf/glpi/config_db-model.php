<?php
class DB extends DBmysql {
  public $dbhost     = 'database';
  public $dbuser     = 'glpi';
  public $dbpassword = '************';
  public $dbdefault  = 'glpi';
  public $allow_myisam = false;
  public $allow_datetime = false;
  public $use_timezones = true;
  public $use_utf8mb4 = true;
  public $allow_signed_keys = false;
}
