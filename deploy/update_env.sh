#!/bin/bash

 
DB_BACKUP_BUCKET="zmc-db-backups"
MEDIA_BACKUP_BUCKET="zmc-media-backups"
TEMP_DIR="/mnt/data/tmp"
DOMAIN="dev.zeromariacornejo.com"
COOKIE_DOMAIN="dev.zeromariacornejo.com"


MYSQL_USER='admin'
MYSQL_PASSWORD='wAkU7c1Mzh2#'
MYSQL_HOST='development2-db.c4okbqlrsgyg.us-east-1.rds.amazonaws.com'
MYSQL_DATABASE='shop'


function find_last_backup(){
    echo "s3://${1}/"$(aws s3 ls s3://${1}/shop/ --recursive | \
    awk -F ' ' '{print $1" "$4}' |\
     sort -t '-' -k 1.1,1.4nr -k 2.2,2.2nr -k 3.1,3.2nr |\
     head -n1 |\
     awk -F ' ' '{print $2}' 
     )  
}

function download_backup() {    
    bup_filename=$( echo $1 | tr '/' '\n' | tail -n1 )    
    aws s3 cp "$1"  "${TEMP_DIR}/"    2>&1 1> /dev/null &&  echo $TEMP_DIR"/${bup_filename}"    
}
function mysql_pipe(){
    cat - | mysql $1 --user=$MYSQL_USER --password="$MYSQL_PASSWORD" --host=$MYSQL_HOST --database=$MYSQL_DATABASE
}

function update_domain(){
    ( echo "UPDATE core_config_data SET value = 'http://${DOMAIN}/'  WHERE path = 'web/unsecure/base_url' " | mysql_pipe "-v" ) && 
    ( echo "UPDATE core_config_data SET value = 'https://${DOMAIN}/'  WHERE path = 'web/secure/base_url' " | mysql_pipe "-v" ) && 
    ( echo "UPDATE core_config_data SET value = '${COOKIE_DOMAIN}' WHERE path = 'web/cookie/cookie_domain' " | mysql_pipe "-v" )    
}

function push_db_backup(){
    zcat $1 | mysql_pipe 
}


function update_db(){

    #FIND LATEST BACKUP
    if ! { bup_file=$( find_last_backup $DB_BACKUP_BUCKET ) ; }  ; then
        echo "Can't find DB Backup file on S3"
        return 1;
    else
        echo "Founded db backup on S3: [$bup_file]";    
    fi

    echo "Downloading S3 file : $bup_file"
    if ! { local_file=$(download_backup $bup_file) ; }  ; then
        echo "Unable to dowload : $bup_file"    
        return 1;
    else
        echo "Downloaded $local_file"   
    fi  
    if ! { push_db_backup $local_file && update_domain  ; }  ;  then 
        echo "Something fail on db import"
        return 1;
    else
        rm $local_file ;
        echo "DB updated"    
    fi    

}

function update_media(){
    #FIND LATEST BACKUP
    if ! { bup_file=$(find_last_backup $MEDIA_BACKUP_BUCKET) ;  }  ; then
        echo "Can't find Media Backup file on S3"
        return 1;
    else
        echo "Founded Media backup on S3: [$bup_file]";    
    fi

    echo "Downloading S3 file : $bup_file"
    if ! { local_file=$(download_backup $bup_file) ; }  ; then
        echo "Unable to dowload : $bup_file"    
        return 1;
    else
        echo "Downloaded $local_file"   
    fi  
    if ! { cd / && sudo tar xvf $local_file  ; }  ;  then 
        echo "Something fail while decompressing [$local_file]"
        return 1;
    else
        rm $local_file ;
        echo "Media Updated"    
    fi    

}
########################################################3
update_media;
update_db;

