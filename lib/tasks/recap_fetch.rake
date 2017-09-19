
namespace :recap do

  namespace :fetch do

    task :filename, [:filename] do |t, args|
      raise "recap:fetch:filename not passed filename!" unless args[:filename]
      
      sftp = get_sftp()

      # download a file or directory from the remote host
      remote_file = APP_CONFIG['recap']['sftp_path'] + '/' + args[:filename]
      local_file = '/tmp/' + args[:filename]
      sftp.download!(remote_file, local_file)
    end


    # :007 > s  = Net::SFTP.start('devops-recap.htcinc.com', 'recapftp', port: '2222', keys: ['/Users/marquis/.ssh/recapftp_rsa'] )  
    # 
    #  :004 > s.dir.foreach( '/share/recap/data-dump/prod/CUL/MarcXml') do |entry|
    #  :005 >     puts entry.longname
    #  :006?>   end
    # -rw-r--r--    1 1001     100           297 Sep 19 06:05 ExportDataDump_Full_PUL_20170918_230400.csv
    # -rw-r--r--    1 1001     100           298 Sep 19 10:16 ExportDataDump_Full_NYPL_20170919_022500.csv
    # -rw-r--r--    1 1001     100      937749743 Sep 19 06:05 PUL_20170918_230400.zip
    # -rw-r--r--    1 1001     100      1032238502 Sep 19 10:16 NYPL_20170919_022500.zip
    # drwxr-xr-x    2 1001     100          4096 Sep 19 10:16 .
    # drwxr-xr-x    3 1001     100          4096 Sep 19 06:05 ..
    #  => nil 
    # 

  end
  
end


def get_sftp()
  sftp_host = APP_CONFIG['recap']['sftp_host']
  sftp_user = APP_CONFIG['recap']['sftp_user']
  sftp_port = APP_CONFIG['recap']['sftp_port']
  sftp_keyfile = APP_CONFIG['recap']['sftp_keyfile']
  
  sftp  = Net::SFTP.start(sftp_host, sftp_user, port: sftp_port, keys: [sftp_keyfile] )  
  raise "get_sftp() failed!" unless sftp

  return sftp  
end