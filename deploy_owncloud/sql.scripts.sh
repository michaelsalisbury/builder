#!/bin/builder.sh






login='-u root --password=1qaz@WSX --table'



function setup_SQL_Usage(){
	desc Display Storage Usage

	mysql ${login} << END-OF-SQL
		USE owncloud;
		##############################################################################
		SELECT	table_schema "Data Base Name",
			sum( data_length + index_length ) / 1024 / 1024 "Data Base Size in MB"
		FROM information_schema.TABLES
		GROUP BY table_schema ;
		##############################################################################
		SELECT	table_schema "Data Base Name",
			sum( data_length + index_length ) / 1024 / 1024 "Data Base Size in MB", 
			sum( data_free )/ 1024 / 1024 "Free Space in MB"
		FROM information_schema.TABLES 
		GROUP BY table_schema ; 
		##############################################################################
		#SHOW TABLES ;
		##############################################################################
		#SHOW COLUMNS FROM information_schema.tables;
		##############################################################################
		SELECT	TABLE_NAME,
			TABLE_ROWS
		FROM information_schema.tables
		WHERE TABLE_SCHEMA = 'owncloud' ;
		##############################################################################
END-OF-SQL
}

function setup_Show_E-mail(){
	desc Users E-mail Addresses \& File/Folders

	mysql ${login} << END-OF-SQL
		USE owncloud;
		##############################################################################
		SELECT	user		"Username",
			count(*)	"Files & Folders"
		FROM oc_fscache
		GROUP BY user ;
		##############################################################################
		SELECT	u.uid		"Username",
			configvalue	"E-mail"
		FROM oc_users u
		LEFT JOIN (
			SELECT *
			FROM oc_preferences
			WHERE configkey = 'email'
			) p
		ON u.uid = p.userid
		GROUP BY u.uid;
		##############################################################################

END-OF-SQL

}
