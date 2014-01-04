$my_full_name = "Test User"
$my_email = "test@spam-medin.name"
$oracle_password = 'oracle'

include oracle_db::server
include oracle_db::swap
include oracle_db::xe
include oracle_jdev::install
include oracle_jdev::hr_schema
 
package { "git": ensure => present }
package { "build-essential": ensure => present }
package { "ubuntu-desktop": ensure => present }

group { "oracle":
	ensure		=> present,
}

exec{"restart-lightdm":
	command => "/etc/init.d/lightdm restart; /usr/bin/touch /etc/puppet/.lightdm",
	creates => "/etc/puppet/.lightdm",
	subscribe => Package['ubuntu-desktop'],
}

user { "oracle":
	ensure		=> present,
	comment		=> "$my_full_name",
	gid			=> "oracle",
	groups		=> ["admin", "sudo", "dba"],
	membership	=> minimum,
	shell		=> "/bin/bash",
	home		=> "/u01/app/oracle",
	# So that we let Oracle installer create the group
	require		=> Service["oracle-xe"],
}

exec { "set-oracle-password":
	command	=> [ "/bin/echo -e \"$oracle_password\\n$oracle_password\\n\" | /usr/bin/passwd oracle && /usr/bin/passwd -u oracle" ],
	unless	=> "/usr/bin/passwd -S oracle|awk '{print $2}'|grep 'oracle P'",
	require	=> User[oracle],
}

exec { "oracle homedir":
	command	=> "/bin/cp -R /etc/skel /home/$name; /bin/chown -R $name:$group /home/$name",
	creates	=> "/u01/app/oracle",
	require	=> User[oracle],
}

exec { "apt-update":
    command => "/usr/bin/apt-get update"
}
Exec["apt-update"]	-> Package <| |>

# Configure Git
exec { "setup-git-username":
	command		=> "/usr/bin/git config --global user.name '$my_full_name'",
	unless		=> "/usr/bin/git config --global --get user.name|/bin/grep '$my_full_name'",
	environment	=> "HOME=/u01/app/oracle",
	user		=> "oracle"
}

exec { "setup-git-email":
	command		=> "/usr/bin/git config --global user.email '$my_email'",
	unless		=> "/usr/bin/git config --global --get user.email|/bin/grep '$my_email'",
	environment => "HOME=/u01/app/oracle",
	user		=> "oracle"
}

exec { "add-swedish-layout":
	command	=> "/usr/bin/dbus-launch --exit-with-session gsettings set org.gnome.libgnomekbd.keyboard layouts \"['se', 'us']\"",
	unless	=> "/usr/bin/dbus-launch --exit-with-session gsettings get org.gnome.libgnomekbd.keyboard layouts|/bin/grep se",
	user		=> "oracle"
}
