#
# Table structure for table 'USER_PROFILE'
#
CREATE TABLE USER_PROFILE (
  UID smallint(5) unsigned DEFAULT '0' NOT NULL auto_increment,
  NAME varchar(25) DEFAULT '' NOT NULL,
  PASS varchar(13) DEFAULT '' NOT NULL,
  EMAIL varchar(40) DEFAULT '' NOT NULL,
  PRIMARY KEY (UID)
);
