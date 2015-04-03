CREATE TABLE IF NOT EXISTS `bb_stats` (
  `authid` varchar(32) NOT NULL,
  `name` text,
  `exp` text,
  `lvl` int(11) DEFAULT NULL,
  `skill_hp` int(11) DEFAULT NULL,
  `skill_skill` int(11) DEFAULT NULL,
  `skill_speed` int(11) DEFAULT NULL,
  `points` int(11) DEFAULT NULL,
  `autoload` int(11) DEFAULT NULL,
  `date` int(11) DEFAULT '1112214021',
  `online` varchar(50) DEFAULT 'false',
  `country` varchar(50) DEFAULT NULL,
  `kills` int(11) DEFAULT '0',
  `kills_player` int(11) DEFAULT '0',
  `gametime` int(11) DEFAULT '0',
  PRIMARY KEY (`authid`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `bb_stats_rank` (
  `lvl` int(11) NOT NULL,
  `title` text NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

INSERT INTO `bb_stats_rank` (`lvl`, `title`) VALUES
	(40, 'a survivor'),
	(-1, 'rotten'),
	(15, 'the walking corpse'),
	(25, 'infected'),
	(105, 'a zombie hunter'),
	(135, 'the protector'),
	(150, 'the final solution'),
	(80, 'a survivalist');