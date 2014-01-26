class oracle_jdev::config {
	$group			= "dba"
	$mdwHome		= "/u01/app/oracle/product/12.12/jdeveloper"
	$oraInventory	= "/u01/app/oracle/oraInventory"
	$hrPassword 	= "manager"
}

class oracle_jdev::install inherits oracle_jdev::config { 
	
	include oracle_jdev::config

	file { "silent_jdeveloper.xml":
		path    => "/tmp/silent.xml",
		ensure  => present,
		replace => 'yes',
		content => template("oracle_jdev/silent_jdeveloper_1212.xml.erb"),
	}
	
	 file { "/etc/oraInst.loc":
		ensure	=> present,
		content	=> template("oracle_jdev/oraInst.loc.erb"),
		group	=> "dba",
		mode	=> 0664,
		require	=> Service["oracle-xe"],
	 }
	 file { "/usr/share/applications/jdeveloper.desktop":
		ensure	=> present,
		content	=> template("oracle_jdev/jdeveloper.desktop.erb"),
		require	=> Package["ubuntu-desktop"],
	 }
	 file { "/usr/share/pixmaps/jdeveloper.png":
		ensure	=> present,
		source	=> "puppet:///modules/oracle_jdev/jdeveloper.png",
	 }
	 file { ["/u01/app/oracle/product/12.12", "/u01/app/oracle/product/12.12/jdeveloper"]:
		ensure  => directory,
		owner	=> "oracle",
		group	=> "dba",
	}

	exec { "installjdev":
		command	=> "/etc/puppet/files/jdev_suite_121200_linux64.bin -silent -responseFile /tmp/silent.xml -invPtrLoc /etc/oraInst.loc -ignoreSysPrereqs",
		user	=> "oracle",
		require	=> [File["/etc/oraInst.loc"], File["/u01/app/oracle/product/12.12/jdeveloper"]],
		creates	=> "/u01/app/oracle/product/12.12/jdeveloper/jdeveloper/",
		timeout	=> 0,
	}

}

class oracle_jdev::hr_schema inherits oracle_jdev::config {

	include oracle_jdev::config

	file { ["/u01/app/oracle/.jdeveloper", 
			"/u01/app/oracle/.jdeveloper/system12.1.2.0.40.66.68", 
			"/u01/app/oracle/.jdeveloper/system12.1.2.0.40.66.68/o.jdeveloper.rescat2.model", 
			"/u01/app/oracle/.jdeveloper/system12.1.2.0.40.66.68/o.jdeveloper.rescat2.model/connections"]:
		ensure  => directory,
		owner	=> "oracle",
		group	=> "dba",
		require	=> Service["oracle-xe"],
	}
	file { "/u01/app/oracle/.jdeveloper/system12.1.2.0.40.66.68/o.jdeveloper.rescat2.model/connections/connections.xml":
		ensure	=> present,
		content	=> template("oracle_jdev/connections.xml.erb"),
		owner	=> "oracle",
		group	=> "dba",
		require	=> Service["oracle-xe"],
	}
	file { "/u01/app/oracle/scripts":
		ensure  => directory,
		owner	=> "oracle",
		group	=> "dba",
		require	=> Service["oracle-xe"],
	}
	 file { "/u01/app/oracle/scripts/unlock_hr.sql":
		ensure	=> present,
		content	=> template("oracle_jdev/unlock_hr.sql.erb"),
		owner	=> "oracle",
		group	=> "dba",
		require	=> Service["oracle-xe"],
	}
	 file { "/u01/app/oracle/scripts/exit.sql":
		ensure	=> present,
		source	=> "puppet:///modules/oracle_jdev/exit.sql",
		owner	=> "oracle",
		group	=> "dba",
		require	=> Service["oracle-xe"],
	}
	exec { "unlock_hr":
		command		=> "/u01/app/oracle/product/11.2.0/xe/bin/sqlplus -S -L \"sys/$hrPassword as sysdba\" @/u01/app/oracle/scripts/unlock_hr.sql",
		user		=> "oracle",
		logoutput => true,
		environment	=> ["ORACLE_HOME=/u01/app/oracle/product/11.2.0/xe", "ORACLE_SID=XE", "ORACLE_BASE=/u01/app/oracle"
],
		require		=> [File["/u01/app/oracle/scripts/unlock_hr.sql"], File["/u01/app/oracle/scripts/exit.sql"], Service["oracle-xe"]],
		unless		=> "/u01/app/oracle/product/11.2.0/xe/bin/sqlplus -S -L hr/$hrPassword @/u01/app/oracle/scripts/exit.sql",
	}

}