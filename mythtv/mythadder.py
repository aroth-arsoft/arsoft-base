#!/usr/bin/python
# mythadder - automatically add video files on removable media to the mythvideo database upon connect/mount
# and remove them on disconnect.  Your distro should be set up to automount usb storage within 'mountWait' seconds after
# connection.
#
# requires udev and a rule like - SUBSYSTEM=="block", ENV{DEVTYPE}=="partition", RUN+="/usr/bin/python /usr/bin/mythadder.py"
# to launch it - there's a .rules file in this archive you can use
#
# requires the python mysqldb library.  on ubuntu, apt-get install python python-mysqldb.
#

#
# configuration section
#

# add your video file extensions here
extensions = [".avi",".mkv",".ts",".m2ts",".mpg",".mp4",".iso",".vob"]

# to turn off logging, use 'none'
logLevel = 'all'
logFile = '/var/log/mythtv/mythadder'

# seconds to wait for mount after udev event
mountWait  = 10 

# Don't change anything below this unless you are a real python programmer and I've done something really dumb.
# This is my python 'hello world', so be gentle.

MASCHEMA = 1001

#
# code
#

import os
import sys
import commands
import re
import time
from MythTV import MythDB, MythLog
import MySQLdb
from socket import gethostname

LOG = MythLog(module='mythadder.py', lstr=logLevel)
if logFile:
	LOG.LOGFILE = open(logFile, 'a')

def prepTable(db):
	if db.settings.NULL['mythadder.DBSchemaVer'] is None:
		# create new table
		c = db.cursor()
		c.execute("""
			CREATE TABLE IF NOT EXISTS `z_removablevideos` (
			`partitionuuid` varchar(100) NOT NULL,
			`partitionlabel` varchar(50) NOT NULL,
			`fileinode` int(11) NOT NULL,
			`intid` int(10) unsigned NOT NULL,
			`title` varchar(128) NOT NULL,
			`subtitle` text NOT NULL,
			`director` varchar(128) NOT NULL,
			`plot` text,
			`rating` varchar(128) NOT NULL,
			`inetref` varchar(255) NOT NULL,
			`year` int(10) unsigned NOT NULL,
			`userrating` float NOT NULL,
			`length` int(10) unsigned NOT NULL,
			`season` smallint(5) unsigned NOT NULL default '0',
			`episode` smallint(5) unsigned NOT NULL default '0',
			`showlevel` int(10) unsigned NOT NULL,
			`filename` text NOT NULL,
			`coverfile` text NOT NULL,
			`childid` int(11) NOT NULL default '-1',
			`browse` tinyint(1) NOT NULL default '1',
			`watched` tinyint(1) NOT NULL default '0',
			`playcommand` varchar(255) default NULL,
			`category` int(10) unsigned NOT NULL default '0',
			`trailer` text,
			`host` text NOT NULL,
			`screenshot` text,
			`banner` text,
			`fanart` text,
			`insertdate` timestamp NULL default CURRENT_TIMESTAMP,
			PRIMARY KEY  (`partitionuuid`,`fileinode`),
			KEY `director` (`director`),
			KEY `title` (`title`),
			KEY `partitionuuid` (`partitionuuid`)
			) ENGINE=MyISAM DEFAULT CHARSET=utf8;""")
		c.close()
		db.settings.NULL['mythadder.DBSchemaVer'] = MASCHEMA
	elif int(db.settings.NULL['mythadder.DBSchemaVer']) > MASCHEMA:
		LOG(LOG.IMPORTANT, "schema is too new, exit")
		# schema is too new, exit
		sys.exit(1)
	else:
		while int(db.settings.NULL['mythadder.DBSchemaVer']) < MASCHEMA:
			# if schema == some version
			# perform these tasks
			break
			
def scanDir(hostname, dirname, cursor):
	
	ret = []
	try:
		files = os.listdir(dirname)
	except Exception, e:
		files = []
		pass
	for f in files:
		fullname=os.path.join(dirname, f)
		if os.path.isdir(fullname):
			childinodes = scanDir(hostname, fullname, cursor)
			ret.extend(childinodes)
		else:
			(basename, ext) = os.path.splitext(f)
			if ext.lower() in extensions:
				thisBasename = os.path.basename(f)
				thisInode = str(os.stat(fullname).st_ino)

				LOG(LOG.IMPORTANT, "File found at inode "+thisInode, fullname)
				ret.append(thisInode)
					
				# insert each file that matches our extensions or update if it's already in the table
				sql = """
						INSERT INTO 
							z_removablevideos 
						SET partitionuuid = %s 
							,partitionlabel = %s 
							,fileinode = %s 
							,intid = 0 
							,title = %s 
							,subtitle = '' 
							,director = '' 
							,rating = '' 
							,inetref = '' 
							,year = 0 
							,userrating = 0.0 
							,showlevel = 1 
							,filename = %s 
							,coverfile = '' 
							,host = %s 
						ON DUPLICATE KEY UPDATE 
							partitionlabel = %s 
							,filename = %s;"""
				try:
					cursor.execute(sql, (uuid, label,  thisInode,  thisBasename,  fullname,  hostname, label,  fullname))
				except Exception, e:
					LOG(LOG.IMPORTANT, "Error on SQL: " + str(sql % (uuid, label,  thisInode,  thisBasename,  fullname,  hostname, label,  fullname)) + " msg: " + str(e))
	return ret

inodes = []

device = os.environ.get('DEVNAME',False)
action = os.environ.get('ACTION',False)
uuid   = os.environ.get('ID_FS_UUID',False)
label  = os.environ.get('ID_FS_LABEL',False)

if device:
	MYTHCONFDIR = os.environ.get('MYTHCONFDIR','/etc/mythtv')
	LOG(LOG.IMPORTANT, "%s %s (uid %i, gid %i, config %s)" % (device, action, os.geteuid(), os.getegid(), MYTHCONFDIR), "%s at %s" % (label, uuid))

	#
	# the drive is connected
	#
	if action == 'add':
		print("add device")
		hostname = gethostname()
		# connect to db
		try:		
			db = MythDB()
			prepTable(db)
		except Exception, e:
			LOG(LOG.IMPORTANT, e.args[0])
			print ("except " + str(e.args[0]))
			sys.exit(1)

		cursor = db.cursor()
		regex = re.compile(device)
		
		# wait a few seconds until the drive is mounted
		mount_point = None
		mount_timeout = int(time.time()+mountWait)

		while mount_point is None and mount_timeout > int(time.time()):
			mount_output = commands.getoutput('mount -v')
			for line in mount_output.split('\n'):
				if regex.match(line):
					mount_point = line.split(' type ')[0].split(' on ')[1]
					LOG(LOG.IMPORTANT, "Disk mounted at "+str(mount_point))
			if mount_point is None:
				time.sleep(1)
		print("Disk mounted at "+str(mount_point))

		if mount_point is not None:
			inodes = scanDir(hostname, mount_point, cursor)
		else:
			inodes = []

		inodeList = ','.join(inodes)
		
		# delete any rows for files that were deleted from the disk
		# there seems to be a bug in the mysql package that fails to handle the 
		# tuples for this query because of the inode list so we're letting python do the substitution here
		if len(inodes) == 0:
			sql = """
				DELETE FROM 
					z_removablevideos 
				WHERE
					partitionuuid = '%s' ;""" % (uuid)
		else:
			sql = """
				DELETE FROM 
					z_removablevideos 
				WHERE
					partitionuuid = '%s' AND
					fileinode NOT IN (%s) ;""" % (uuid,  inodeList)
		
		try:
			cursor.execute(sql)
		except Exception, e:
			LOG(LOG.IMPORTANT, "Error on SQL: " + str(sql) + " msg: " + str(e))

		# insert anything from our table that already has an id from mythtv
		sql = """
			INSERT INTO videometadata (
				intid 
				,title
				,subtitle
				,director
				,plot
				,rating
				,inetref
				,year
				,userrating
				,length
				,season
				,episode
				,showlevel
				,filename
				,coverfile
				,childid
				,browse
				,watched
				,playcommand
				,category
				,trailer
				,host
				,screenshot
				,banner
				,fanart
				,insertdate)	
			SELECT
				intid 
				,title
				,subtitle
				,director
				,plot
				,rating
				,inetref
				,year
				,userrating
				,length
				,season
				,episode
				,showlevel
				,filename
				,coverfile
				,childid
				,browse
				,watched
				,playcommand
				,category
				,trailer
				,%s
				,screenshot
				,banner
				,fanart
				,insertdate
			FROM
				z_removablevideos
			WHERE
				partitionuuid = %s AND
				intid != 0 ;""" 
		try:
			cursor.execute(sql, (hostname, uuid))
		except Exception, e:
			LOG(LOG.IMPORTANT, "Error on SQL: " + str(sql % (uuid)) + " msg: " + str(e))

		# get all our rows that have never been in mythtv before so we can insert them one at a time and capture the resulting mythtv id
		sql = """
			SELECT 				
				title
				,subtitle
				,director
				,plot
				,rating
				,inetref
				,year
				,userrating
				,length
				,season
				,episode
				,showlevel
				,filename
				,coverfile
				,childid
				,browse
				,watched
				,playcommand
				,category
				,trailer
				,host
				,screenshot
				,banner
				,fanart
				,insertdate
				,fileinode
			FROM 
				z_removablevideos 
			WHERE
				partitionuuid = %s AND
				intid = 0 ;""" 

		try:
			cursor.execute(sql,  (uuid))
			data = cursor.fetchall()
		except Exception, e:
			LOG(LOG.IMPORTANT, "Error on SQL: " + str(sql % (uuid)) + " msg: " + str(e))

		# insert one row from new videos and capture the id it gets assigned
		sql = """
			INSERT INTO videometadata (
				title
				,subtitle
				,director
				,plot
				,rating
				,inetref
				,year
				,userrating
				,length
				,season
				,episode
				,showlevel
				,filename
				,coverfile
				,childid
				,browse
				,watched
				,playcommand
				,category
				,trailer
				,host
				,screenshot
				,banner
				,fanart
				,insertdate)
			VALUES ( %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s);
			""" 
		dbcxn = db.db
		for row in data:
#			print ( str(row) )
#			raise Exception(blubb)
		
			try:
				#cursor.execute(sql, row)
				cursor.execute(sql, (row[0], row[1], row[2], row[3], row[4], row[5], row[6], row[7], row[8], row[9], row[10],
									row[11], row[12], row[13], row[14], row[15], row[16], row[17], row[18], row[19], hostname, 
									row[21], row[22], row[23], row[24].strftime("%Y-%m-%d %H:%M:%S %z") ))
				intid = int(cursor.lastrowid)
			except Exception, e:
				intid = None
				LOG(LOG.IMPORTANT, "Error on big SQL: " + str(sql) + " msg: " + str(e))

			if intid is not None:
				# update our table with the intid from mythtv so we can remove the rows when the drive is disconnected
				sql2 = """
					UPDATE z_removablevideos
					SET intid = %s
					WHERE partitionuuid = %s AND fileinode = %s
				"""
				try:
					cursor.execute(sql2, (intid,  uuid, row[25]))
				except Exception, e:
					LOG(LOG.IMPORTANT, "Error on SQL: " + str(sql2 % (intid,  uuid, row[25])) + " msg: " (str(e)))

	#
	# the drive is being removed.
	#
	if action == 'remove':
		# connect to db
		try:		
			db = MythDB()
			prepTable(db)
		except Exception, e:
			LOG(LOG.IMPORTANT, e.args[0])
			sys.exit(1)

		cursor = db.cursor()
		
		# update everything in our table to catch metadata changes done inside mythtv
		sql = """
			UPDATE 
				z_removablevideos rv,  videometadata vm
			SET
				rv.title = vm.title
				,rv.subtitle = vm.subtitle
				,rv.director = vm.director
				,rv.plot = vm.plot
				,rv.rating = vm.rating
				,rv.inetref = vm.inetref
				,rv.year = vm.year
				,rv.userrating = vm.userrating
				,rv.length = vm.length
				,rv.season = vm.season
				,rv.episode = vm.episode
				,rv.showlevel = vm.showlevel
				,rv.filename = vm.filename
				,rv.coverfile = vm.coverfile
				,rv.childid = vm.childid
				,rv.browse = vm.browse
				,rv.watched = vm.watched
				,rv.playcommand = vm.playcommand
				,rv.category = vm.category
				,rv.trailer = vm.trailer
				,rv.host = vm.host
				,rv.screenshot = vm.screenshot
				,rv.banner = vm.banner
				,rv.fanart = vm.fanart
			WHERE 
				rv.intid = vm.intid AND
				rv.partitionuuid = %s;"""
		try:
			cursor.execute(sql, uuid)
		except Exception, e:
			LOG(LOG.IMPORTANT, "Error on SQL: " + str(sql % (uuid)) + " msg: " + str(e))

		# and finally delete all the rows in mythtv that match rows in our table for the drive being removed
		sql = """
			DELETE  
				vm
			FROM
				videometadata vm, z_removablevideos rv
			WHERE 
				rv.intid = vm.intid AND
				rv.partitionuuid = %s;"""
		try:
			cursor.execute(sql, uuid)
		except MySQLdb.Error, e:
			LOG(LOG.IMPORTANT, "Error on SQL: " + str(sql % (uuid)) + " msg: " + str(e))



