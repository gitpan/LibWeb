#
# Table structure for table 'USER_LOG'
#
CREATE TABLE USER_LOG (
  UID smallint(5) unsigned DEFAULT '0' NOT NULL auto_increment,
  NUM_LOGIN_ATTEMPT tinyint(4) DEFAULT '0' NOT NULL,
  LAST_LOGIN varchar(30) DEFAULT '' NOT NULL,
  IP varchar(15) DEFAULT '' NOT NULL,
  HOST varchar(50) DEFAULT '' NOT NULL,
  PRIMARY KEY (UID)
);
