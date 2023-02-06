#!/usr/bin/env bash

################################################
#
# Issue: SafetyNet reports displaying HTTP 404
#        errors after upgrade.
#
# Last modified: 2/05/2023 C.E.
#
#################################################

# Steps this program performs

# Step 1. Make sure the user is running the program as root, if not, let the user know they need root privileges and exit the script.

# Step 2. Check if the "SafetyNetReportUI.war" file exists in the "/opt/apache-tomcat-*/webapps/" directory, 
#         if it does, let the user know and exit the script.

# Step 2a. Check if apache tomcat is installed in the "/opt" directory, if found,
#          then update the "PATH_TO_APACHE_TOMCAT_DIRECTORY" variable with the path.

# Step 2b. Check the entire system for apache tomcat, starting from the root directory "/", if tomcat is found, 
#          update the "PATH_TO_APACHE_TOMCAT_DIRECTORY" variable with the path. Otherwise, exit the script.

# Step 3. Check the "/opt/SafetyNetReportUI.war" directory for the file, if it exists, copy it to the "apache-tomcat-*/webapps/"
#         directory found in step 2.

# Step 3a. If the file is not found in the "/opt/SafetyNetReportUI.war" direct path, search the entire "/opt" directory,
#          if found, copy it to the tomcat directory found in step 2.

# Step 3b. If step 3a fails, search the entire system starting from root "/" for the "SafetyNetReportUI.war" file, if found,
#          copy it to the tomcat directory found in step 2, else exit the script as the file does not exist.

# Step 4. Check if apache tomcat is running.

######################### Variable Assignments BEGIN #########################

# Variable "PATH_TO_APACHE_TOMCAT_DIRECTORY" holds the absolute
# path to the "/opt/apache-tomcat-*/webapps/" directory.
PATH_TO_APACHE_TOMCAT_DIRECTORY='/opt/apache-tomcat-*/webapps/'

# Variable "SAFETYNET_REPORT_UI_WAR_FILE" holds "SafetyNetReportUI.war" file name.
SAFETYNET_REPORT_UI_WAR_FILE='SafetyNetReportUI.war'

LOCATE_APACHE='*apache-tomcat-*'
OPT_DIRECTORY='/opt'
ROOT_DIRECTORY='/'
FILE='f'
DIRECTORY='d'

######################### Variable Assignments END ###########################


######################### Functions Begin ####################################

# Exit the script completely
exit_Script()
{
	exit 1
}

search()
{

	local DIRECTORY_TO_SEARCH="${1}"  # Take the directory or file to search for as the first parameter.
	local FILE_TYPE="${2}"  # Take the file type i.e. directory (d) or file (f) as the second parameter.
	local WHAT_TO_SEARCH_FOR="${3}"  # Take what to search for as the 3rd parameter - could be file name or directory name.
	local UPDATE_PATH="${4}"  # Take if a variable should be updated as the 4th parameter.

	case "${UPDATE_PATH}" in
		search_only)  # Perform a search only, do not update variables with a new file or directory path.
			if find ${DIRECTORY_TO_SEARCH} -type ${FILE_TYPE} -iname ${WHAT_TO_SEARCH_FOR} 2>/dev/null | grep -q ^
			then
				 return 0  # True - successful
			else
				return 1   # False - failed
			fi
		;;
		update_apache_path)  #  Update the path to apache variable with the newly found directory location.
			PATH_TO_APACHE_TOMCAT_DIRECTORY=$(find ${DIRECTORY_TO_SEARCH} -type ${FILE_TYPE} -iname ${WHAT_TO_SEARCH_FOR} 2>/dev/null)
			return 0
		;;
		update_safetynet_report_file_path)  # Update safetynet report file path variable with the newly found file path.
			SAFETYNET_REPORT_UI_WAR_FILE=$(find ${DIRECTORY_TO_SEARCH} -type ${FILE_TYPE} -iname ${WHAT_TO_SEARCH_FOR} 2>/dev/null)
			return 0
		;;
	esac
}

copy_SafetyNet_Report_To_Apache_Directory()
{
	local DEFAULT_PATH="${1}"  # Take whether or not to search default file/directory paths as the only parameter.
	
	if [[ "${DEFAULT_PATH}" = 'default_location' ]]
	then
		cp -p /opt/${SAFETYNET_REPORT_UI_WAR_FILE} ${PATH_TO_APACHE_TOMCAT_DIRECTORY}/webapps/
	else
		cp -p ${SAFETYNET_REPORT_UI_WAR_FILE} ${PATH_TO_APACHE_TOMCAT_DIRECTORY}/webapps/
	fi
}

check_If_User_Is_Root()
{
	# Step 1.
	# If the script is not executed with root privileges, exit the script with exit status 1
	if [[ "${UID}" -ne 0 ]] # If the users ID is not equal to zero i.e. the user is not root
	then
	   echo "Root privileges are needed to execute this script."
	   echo "Run the script with sudo permissions or as root user"
	   exit_Script # End the script with exit code 1
	fi
}

locate_Apache_Directory()
{
	# Step 2.
	# Check if the "SafetyNetReportUI.war" file exists 
	# in the "/opt/apache-tomcat-*/webapps/" directory
	if search ${PATH_TO_APACHE_TOMCAT_DIRECTORY} ${FILE} ${SAFETYNET_REPORT_UI_WAR_FILE} 'search_only'
	then
	   echo "\"${SAFETYNET_REPORT_UI_WAR_FILE}\" exists in the \"${PATH_TO_APACHE_TOMCAT_DIRECTORY}\" directory"
	   exit_Script # End the script with exit code 1
	# Step 2a.
	else
	    # Check if apache tomcat is installed in the "/opt" directory
	    if search ${OPT_DIRECTORY} ${DIRECTORY} ${LOCATE_APACHE} 'search_only'
	    # If apache tomcat is found in the "/opt" directory, then update the "PATH_TO_APACHE_TOMCAT_DIRECTORY" variable with the path
	    then 
		search ${OPT_DIRECTORY} ${DIRECTORY} ${LOCATE_APACHE} 'update_apache_path'
		echo "Apache Tomcat is installed in the \"${PATH_TO_APACHE_TOMCAT_DIRECTORY}\" directory."
	    # Step 2b.
	    # Else check the entire system starting from the root directory "/" for apache tomcat
	    else 
		# If apache tomcat was found somewhere else on the system
		if search ${ROOT_DIRECTORY} ${DIRECTORY} ${LOCATE_APACHE} 'search_only'
		# Then update the "PATH_TO_APACHE_TOMCAT_DIRECTORY" variable with the correct path
		then 
		    search ${ROOT_DIRECTORY} ${DIRECTORY} ${LOCATE_APACHE} 'update_apache_path'
		    echo "Apache Tomcat is installed in the \"${PATH_TO_APACHE_TOMCAT_DIRECTORY}\" directory."
		# Else apache is not installed on the server exit script
		else 
		    echo "\"Apache Tomcat\" is not installed on this server"
		    exit_Script
		fi
	    fi
	fi
}

locate_SafetyNetReportUI_File()
{
	# Step 3. 
	# Check if "/opt/SafetyNetReportUI.war" exists
	if [[ -f "${OPT_DIRECTORY}/${SAFETYNET_REPORT_UI_WAR_FILE}" ]]
	then
	    echo "Copying \"/opt/${SAFETYNET_REPORT_UI_WAR_FILE}\" to the \"${PATH_TO_APACHE_TOMCAT_DIRECTORY}/webapps/\" directory."
	    copy_SafetyNet_Report_To_Apache_Directory 'default_location'
	else
	    echo "Searching the \"/opt\" directory"
	    if search ${OPT_DIRECTORY} ${FILE} ${SAFETYNET_REPORT_UI_WAR_FILE} 'search_only'
	    then
		echo "Copying \"${SAFETYNET_REPORT_UI_WAR_FILE}\" to the \"${PATH_TO_APACHE_TOMCAT_DIRECTORY}/webapps/\" directory."
		search ${OPT_DIRECTORY} ${FILE} ${SAFETYNET_REPORT_UI_WAR_FILE} 'update_safetynet_report_file_path'
		copy_SafetyNet_Report_To_Apache_Directory 'other_location'
	    else
		echo "Searching the entire system for the \"${SAFETYNET_REPORT_UI_WAR_FILE}\" file."
		if search ${ROOT_DIRECTORY} ${FILE} ${SAFETYNET_REPORT_UI_WAR_FILE} 'search_only'
		then
		    echo "Copying \"${SAFETYNET_REPORT_UI_WAR_FILE}\" to the \"${PATH_TO_APACHE_TOMCAT_DIRECTORY}/webapps/\" directory."
		    search ${ROOT_DIRECTORY} ${FILE} ${SAFETYNET_REPORT_UI_WAR_FILE} 'update_safetynet_report_file_path'
		    copy_SafetyNet_Report_To_Apache_Directory 'other_location'
		else
		    echo "File does not exist on system"
		    exit_Script
		fi
	    fi 
	fi
}

make_Sure_Apache_Services_Are_Running()
{
	# Step 4
	# Check if tomcat is running
	if [[ $(ps -ef | grep tomca[t] | wc -l) -gt 0 ]]
	then
	   echo 'Apache Tomcat is running'
	else
	    echo "Apache Tomcat is not running"
	    echo "Starting Apache server"
	    sudo systemctl start httpd.service # Start apache server
	fi
}

######################### Functions End ######################################


######################### Main Begin ######################################### 

check_If_User_Is_Root

locate_Apache_Directory

locate_SafetyNetReportUI_File

make_Sure_Apache_Services_Are_Running

######################### Main End ########################################### 
