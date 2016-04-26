#!/bin/ksh
#*******************************************************************************
#** Program         :  common_funcs.sh
#**
#** Original Author :  Thiru
#**
#** Description     :  This script autoloads the common functions
#**
#** Revision History:  Please do not stray from the example provided.
#**
#** Modfied    User
#** Date       ID       Description
#** MM/DD/YYYY CUID
#** ---------- -------- ------------------------------------------------
#** 04/30/2003 bthirup    Initial Checkin
#** 10/22/2004 vewalke  Added upd_mkdm_job_control
#** 07/13/2006 mmuruga  Added create_partition function
#*****************************************************************************
#-----------------------------------------------------------------
# Function to evaluate the contents of a variable
#-----------------------------------------------------------------
autoload send_mail
autoload send_file_mail
autoload check_variables
autoload get_crdm_flex_env
autoload run_sql
autoload get_db_value
autoload upd_crdm_flex_env
autoload build_all
autoload nuke_all
autoload analyze_index
autoload analyze_partition_index
autoload analyze_partition_table
autoload analyze_table
autoload get_db_value
autoload truncate_partition
autoload truncate_table
autoload upd_mkdm_job_control
autoload count_recs
autoload create_partition
autoload get_mkdm_job_control




